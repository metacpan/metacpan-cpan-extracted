package Apache::VimColor;

use strict;
use warnings;
use vars (qw($VERSION));

use Apache::Const (qw(:common));
use Apache::RequestRec;
use Apache::RequestIO;
use Apache::RequestUtil;
use Apache::Response;
use Apache::Log;
use Apache::Server;
use File::Basename (qw(basename));
use Text::VimColor;

$VERSION = '2.31';

=head1 NAME

B<Apache::VimColor> - Apache mod_perl Handler for syntax highlighting in HTML.

=head1 DESCRIPTION

This apache handler converts text files in syntax highlighted HTML output using
L<Text::VimColor|Text::VimColor>. If allowed by the configuration the visitor
can also download the text-file without syntax highlighting.

Since Text::VimColor isn't the fastest module this version can use
L<Cache::Cache|Cache::Cache> to cache the parsed files. Also the I<ETag> and
I<LastModified> HTTP headers are set to help browsers and proxy servers to
cache the URL.

=head1 SYNOPSIS

This module requires B<mod_perl2> (see L<http://perl.apache.org/>) and
B<Text::VimColor>.

The apache configuration neccessary might look a bit like this:

  # in httpd.conf (or any other apache configuration file)
  <Location /source>
    SetHandler		perl-script
    PerlHandler		Apache::VimColor

    # Below here is optional
    PerlSetVar  AllowDownload  "True"
    PerlSetVar  CacheType      "File"
    PerlSetVar  CacheSize      1048576 # 1 MByte
    PerlSetVar  CacheExpire    7200    # 2 hours
    PerlSetVar  StyleSheet     "http://domain.com/stylesheet.css"
    PerlSetVar  TabSize        8
    PerlSetVar  LineNumbers    "True"
  </Location>

For a complete list of all options and descriptions see L<below|/"CONFIGURATION DIRECTIVES">.

=cut

our $Position = 0;
our $Cache = {};

return (1);

sub escape_html ($)
{
	$_ = shift;

	s/\&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/"/&quot;/g;

	s#\n#<br />\n#sg;
	s/(  +)/'&nbsp;' x length ($1)/ge;

	return ($_);
}

sub escape_tabs ($$)
{
	my $value   = shift;
	my $tabstop = shift;
	my $retval = '';

	$value =~ s/\r//g;

	while ($value =~ s/^([^\n\t]*)([\n\t])//s)
	{
		$retval .= $1;
		$Position += length ($1);

		if ($2 eq "\n")
		{
			$retval .= "\n";
			$Position = 0;
		}
		else
		{
			my $num =  $tabstop - ($Position % $tabstop);
			$retval .= ' 'x$num;
			$Position += $num;
		}
	}

	$retval .= $value;
	$Position += length ($value);

	return ($retval);
}

=head1 CONFIGURATION DIRECTIVES

All features of the this PerlHandler can be set in the apache configuration
using the I<PerlSetVar> directive. For example:

    PerlSetVar	AllowDownload	true	# inside <Files>, <Location>, ...
					# apache directives

=over 4

=cut

sub get_config ($)
{
	my $req = shift;
	my $options =
	{
		allow_dl	=> 0,
		cssfile		=> '',
		tabstop		=> 8
	};

=item AllowDownload

Setting this option to B<true> will allow plaintext downloads of the files. A
link will be included in the output. The default is not to allow downloads.

=cut

	if ($req->dir_config ('AllowDownload'))
	{
		my $conf = lc ($req->dir_config ('AllowDownload'));

		if (($conf eq 'on') or ($conf eq 'true')
				or ($conf eq 'yes'))
		{
			$options->{'allow_dl'} = 1;
		}
	}

=item CacheType

Selects the caching method to use. Depending on your choices a
L<Cache::Cache|Cache::Cache> module will be loaded and used. The default is not
to use any caching. I<CacheType> can be one of:

    Memory
    SharedMemory
    File

Although the default is not to use caching, if I<CacheSize> is given and
I<CacheType> is not, then B<Memory> is being used. Obviously these values
correspond to the B<Cache::*Cache> modules.

The modules are loaded at runtime. If errors occur they are logged to Apache's
errorlog.

=item CacheSize

Sets the maximum size of the cache in bytes. If I<CacheSize> is non-zero the
B<Cache::SizeAware*Cache> variants will be used. 

=item CacheExpire

I<CacheExpire> sets the expiration time. The value must be given in seconds.
Defaults to 3600 seconds (one hour). See L<Cache::Cache> for details.

=cut

	if ($req->dir_config ('CacheType') or $req->dir_config ('CacheSize'))
	{
		my $cid = $req->server ()->server_hostname () . ':' . $req->location ();
		my $cache;

		if (defined ($Cache->{$cid}))
		{
			$cache = $Cache->{$cid};
		}
		else
		{
			my $type = 'File';
			my $size = 0;
			my $expr = 3600;
			my $cmd;

			if ($req->dir_config ('CacheType'))
			{
				my $tmp = lc ($req->dir_config ('CacheType'));

				if ($tmp =~ m/((?:shared)?memory|file)/)
				{
					if ($1 eq 'sharedmemory') { $type = 'SharedMemory'; }
					elsif ($1 eq 'memory')    { $type = 'Memory'; }
				}
				else
				{
					$req->warn (qq(CacheType "$tmp" is not valid. Will use "File".));
				}
			}

			if ($req->dir_config ('CacheSize'))
			{
				my $tmp = $req->dir_config ('CacheSize');
				$tmp =~ s/\D//g;

				$size = $tmp if ($tmp);
			}

			if ($req->dir_config ('CacheExpire'))
			{
				my $tmp = $req->dir_config ('CacheExpire');
				$tmp =~ s/\D//g;

				$expr = $tmp if ($tmp);
			}
			
			if ($size)
			{
				$type = "SizeAware$type";
			}
			$type .= 'Cache';

			$cmd = "require Cache::$type; \$cache = Cache::$type->new ({ namespace => 'Apache::VimColor', default_expires_in => $expr";
			if ($size)
			{
				$cmd .= ", max_size => $size";
			}
			$cmd .= ' });';

			eval ($cmd);

			if ($@)
			{
				$req->log ()->error (qq(Loading Cache::$type filed: $@"));
				$cache = undef; # just to make sure ;)
			}

			$Cache->{$cid} = $cache if (defined ($cache));
		}

		$options->{'cache'} = $cache;
	}

=item TabStop

Sets the width of one tab symbol. The default is eight spaces.

=cut

	if ($req->dir_config ('TabStop'))
	{
		my $tmp = $req->dir_config ('TabStop');
		$tmp =~ s/\D//g;
		$options->{'tabstop'} = $tmp if ($tmp);
	}

=item StyleSheet

If you want to include a custom stylesheet you can set this option. The string
will be included in the html-output as-is, you will have to take care of
relative filenames yourself.

All highlighted text is withing a C<span>-tag with one of the following
classes:

    Comment
    Constant
    Error
    Identifier
    PreProc
    Special
    Statement
    Todo
    Type
    Underlined

=cut

	if ($req->dir_config ('StyleSheet'))
	{
		$options->{'cssfile'} = $req->dir_config ('StyleSheet');
	}

	return ($options);
}

sub handler
{
	my $req = shift;
	my $filename = $req->filename ();
	my $filename_without_path = basename ($filename);
	my $options = get_config ($req);
	my $download = 0;
	my $mtime;
	my $vim;
	my $cache_entry;
	my $elems;
	my $output = '';

	if (!-e $filename or -z $filename)
	{
		return (NOT_FOUND);
	}

	if (!-r $filename)
	{
		return (FORBIDDEN);
	}

	$mtime = (stat ($filename))[9] or return (SERVER_ERROR);

	if ($req->args ())
	{
		my %args = $req->args ();

		if (exists ($args{'download'})
				and ($options->{'allow_dl'}))
		{
			$download = 1;
		}
	}

	# Set up header
	$req->content_type ($download ? 'text/perl-script' : 'text/html');
	$req->set_last_modified ($mtime);
	$req->set_etag ();

	if ($req->header_only ())
	{
		return (OK);
	}

	# User wished to download. This is already checked against the
	# `AllowDownload' option.
	if ($download)
	{
		return ($req->sendfile ($filename));
	}

	$req->print (<<HEADER);
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
        "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
	<head>
		<title>$filename_without_path</title>
HEADER
	$req->print ($options->{'cssfile'} ? qq(\t\t<link rel="stylesheet" type="text/css" href=") . $options->{'cssfile'} . qq(" />\n) : <<HEADER);
		<style type="text/css">
		<!--
		a { color: inherit; background-color: transparent; }
		body { background-color: black; color: white; }
		div.fixed { border: 1px solid silver; font-family: monospace; padding: 1ex; }
		div.notice { color: silver; background-color: inherit; font-size: smaller; text-align: right; }
		h1 { font-size: medium; }
		span.linenumber { white-space: pre; color: yellow; background-color: transparent; }
		
		span.Comment { color: blue; background-color: transparent; }
		span.Constant { color: red; background-color: transparent; }
		span.Identifier { color: aqua; background-color: transparent; }
		span.Statement { color: yellow; background-color: transparent; }
		span.PreProc { color: fuchsia; background-color: transparent; }
		span.Type { color: lime; background-color: transparent; }
		span.Special { color: fuchsia; background-color: transparent; }
		span.Underlined { color: fuchsia; background-color: transparent; text-decoration: underline; }
		span.Error { background-color: red; color: white; font-weight: bold; }
		span.Todo { background-color: yellow; color: black; }
		-->
		</style>
HEADER
	$req->print (<<HEADER);
	</head>

	<body>
HEADER
	$req->print (qq(\t\t<h1>Source of <code>$filename_without_path</code>)
	. ($options->{'allow_dl'} ? ' (<a href="' . $req->uri () . '?download">download</a>)' : '') . "</h1>\n");

	$req->print (qq(\t\t<div class="fixed">\n));

	if (defined ($options->{'cache'}))
	{
		$cache_entry = $options->{'cache'}->get ($filename);

		if (defined ($cache_entry))
		{
			if ($cache_entry->[0] != $mtime)
			{
				$cache_entry->[0] = $mtime;
				$cache_entry->[1] = [];
			}

			$elems = $cache_entry->[1];
		}
		else
		{
			$cache_entry = [$mtime, []];
			$elems = $cache_entry->[1];
		}
	}
	else
	{
		$elems = [];
	}

	# $elems may have been loaded from the cache
	if (scalar (@$elems) == 0)
	{
		my $tmp;

		# This is slow, therefore the caching.
		$vim = new Text::VimColor (file => $filename);
		$tmp = $vim->marked ();

		# For loop to prevent aliasing.
		for (my $i = 0; $i < scalar (@$tmp); $i++)
		{
			push (@$elems, [$tmp->[$i][0], $tmp->[$i][1]]);
		}

		if (defined ($options->{'cache'}))
		{
			$options->{'cache'}->set ($filename, $cache_entry);
		}
	}

	# For loop to prevent aliasing.
	for (my $i = 0; $i < scalar (@$elems); $i++)
	{
		my $type  = $elems->[$i][0];
		my $value = $elems->[$i][1];

		$value = escape_tabs ($value, $options->{'tabstop'});
		$value = escape_html ($value);

		if ($type)
		{
			$output .= qq(<span class="$type">$value</span>);
		}
		else
		{
			$output .= $value;
		}
	}

=item LineNumbers

Sets wether or not line numbers will be displayed. The Default is not to
display line numbers.

=back

=cut
	if ($req->dir_config ('LineNumbers') and ($req->dir_config ('LineNumbers') =~ m/^(yes|on|true)$/i))
	{
		my $linenumber = 1;
		$output =~ s#^#sprintf (q(<span class="linenumber">%7u </span>), $linenumber++)#gem;
	}
	$req->print ($output);

	$req->print ("\t\t</div>\n");
	$req->print (<<FOOTER);
		<div class="notice">
			Generated with <a href="http://search.cpan.org/perldoc?Apache%3A%3AVimColor">Apache::VimColor $VERSION</a>
			by <a href="http://verplant.org/">Florian octo Forster</a>
		</div>
	</body>
</html>
FOOTER

	return (OK);
}

=head1 SEE ALSO

L<perl(1)>, L<mod_perl(3)>, L<Apache(3)>, L<Text::VimColor|Text::VimColor>,
L<Cache::Cache>

=head1 AUTHOR

  Florian octo Forster
  octo(at)verplant.org
  http://verplant.org/

=head1 COPYRIGHT

Copyright (c) 2005 Florian Forster.

All rights reserved. This package is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
