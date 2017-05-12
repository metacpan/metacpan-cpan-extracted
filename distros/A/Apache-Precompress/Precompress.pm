package Apache::Precompress;

use 5.006;
use strict;
use warnings;

use Compress::Zlib 1.0;
use Apache::Log;
use Apache::Constants ':response';
use vars qw($VERSION);

$VERSION = sprintf '%d.%d', q$Revision: 0.1 $ =~ /: (\d+).(\d+)/;

sub handler 
{
	my $r = shift;
	my $buffer;

	if (lc($r->dir_config('Filter')) eq 'on')
	{
        $r = $r->filter_register;
    }

	if(-d $r->filename())
	{
		# Redirect to the directory index - bit of a hack atm
		$r->uri($r->uri() . '/index.html');
		$r->headers_out->set(Location => $r->uri);
		return REDIRECT;
	}
	
	# Quick file check
	unless(-e $r->filename . '.gz')
	{
		error($r->log,"Cannot open " . $r->filename . ".gz\n");
		return NOT_FOUND;
	}

	
	if (
		$r->dir_config->get('SSI') 
	|| 
		!defined($r->header_in('Accept-Encoding'))
	||
		$r->header_in('Accept-Encoding') eq ""
	||
		$r->header_in('Accept-Encoding') !~ /gzip/
	)
	{
		$r->send_http_header;
		
		my $gz = gzopen($r->filename() . '.gz', "rb") 
            or return error($r->log,"Cannot open " . $r->filename . ".gz: $gzerrno\n");
				
		while($gz->gzread($buffer,4096) > 0)
		{
			$r->print($buffer);
		}
		
		if($gzerrno != Z_STREAM_END)
		{
        	return error($r->log,"Error reading from " . $r->filename . ".gz: $gzerrno\n");
		}
        $gz->gzclose();
		undef $gz;
	} 
	else
	{
		$r->content_encoding('gzip');
		$r->send_http_header;
		open(FILE, $r->filename . '.gz') || return NOT_FOUND;
		binmode(FILE);
		while( read(FILE, $buffer, 4096) > 0)
		{
			$r->print($buffer);
		}
		close(FILE);
  	}
	
  return OK;
}

sub error
{
	my $handle = shift;
	my $msg = shift;
	$handle->error($msg);
	return SERVER_ERROR;
}


1;
__END__

=head1 NAME

Apache::Preompress - Deliver already compressed files or decompress on the fly

=head1 SYNOPSIS

  PerlModule Apache::Precompress
  
  	# Handle regular files, ie index.html.gz
  	# Incoming request would be index.html
	<Directory "your-docroot/compressdfilesdir">
		SetHandler perl-script
		PerlHandler Apache::Precompress
	</Directory>

  	# Handle files by given extension .gzhtml
	<FilesMatch "\.gzhtml$">
		SetHandler perl-script
		PerlHandler Apache::Precompress
	</FilesMatch>

	# You want to use SSI but your templates are compressed
	AddHandler server-parsed .html
	<FilesMatch "\.shtml$">
		Options +Includes
		PerlSetVar  SSI  1
	</FilesMatch>

	# You have a compressed web page and a mix of compressed
	# and uncompressed templates. You'll need Apache::Filter
	# and Apache::SSI
	PerlModule Apache::Filter
	PerlModule Apache::Precompress
	PerlModule Apache::SSI
	<FilesMatch "\.html$">  # or whatever
		SetHandler perl-script
		PerlSetVar Filter On
		PerlSetVar  SSI  1
		PerlHandler Apache::Precompress Apache::SSI
	</FilesMatch>
	
=head1 DESCRIPTION

This module lets you send pre-compressed files as though they were
not. For those clients that do not support compressed content, the
file is de-compressed on the fly.

This module overcomes the overhead of having to compress data on the
fly by keeping the data compressed on disk at all times. The driving
force behind this approach was that I couldn't afford to upgrade my
ISP account to have more disk space. The effective savings on bandwidth
are also quite handy.

This module handles SSI very well. If you just want compressed templates
then you won't need Apache::Filter or Apache::SSI. However, if you want
compressed templates or pages (or both!) then, provided they are installed,
simply follow the example configuration above. Do note, however, that
the savings in bandwidth will be lost as this will be sent uncompressed
down the pipe. This is a todo but will probably involve Apache::Compress
(or something).

Otherwise you will have a normal page with garbled content intermingled 
within it.

=head1 Note

The intent of this module is to hide the fact that the content has been
precompressed from the client. At no time should the client expect to
call a file by anything other than its normal extension. Additionally,
the content should not link to other content other than in the normal
way, ie:

	<a href="/compressed/test.html">Valid</a>
	
	and not
	
	<a href="/compressed/test.html.gz">Invalid</a>

=head1 TO DO

The SSI handling requires the setting of a variable as otherwise
we end up with compressed content within the middle of an uncompressed
page. We should be to tell if we are called via ssi by some other means. 

Also, support for Apache::SSI would be useful.

=head1 AUTHOR

Simon Proctor, www.simonproctor.com

Based on the work of Apache::Compress

=head1 COPYRIGHT

Copyright (C) 2002 Simon Proctor.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself. 

=head1 THANKS TO

belg4mit for valuable feedback

=cut

