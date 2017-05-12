package Apache::Syntax::Highlight::Perl;

require 5.005;
use strict;
use vars qw($VERSION);
$VERSION = '1.01';

use mod_perl;
use constant MP2 => ($mod_perl::VERSION >= 1.99);

use Syntax::Highlight::Perl;
use IO::File;

my $can_cache;
my %stat;
BEGIN {
	# Tests mod_perl version and uses the appropriate components
	if (MP2) {
		require Apache::Const;
		Apache::Const->import(-compile => qw(DECLINED OK));
		require Apache::RequestRec;
		require Apache::RequestIO;
		require Apache::RequestUtil;
	}
	else {
		require Apache::Constants;
		Apache::Constants->import(qw(DECLINED OK));
	}

	# Test caching necessaries modules
	eval { require Digest::MD5; Digest::MD5->can('md5_hex') };
	$can_cache = $@ ? 0 : 1;
}

my %default_styles = (
	'Comment_Normal'    => 'color:#006699;font-style:italic;',
	'Comment_POD'       => 'color:#001144;font-style:italic;',
	'Directive'         => 'color:#339999;font-style:italic;',
	'Label'             => 'color:#993399;font-style:italic;',
	'Quote'             => 'color:#0000aa;',
	'String'            => 'color:#0000aa;',
	'Subroutine'        => 'color:#998800;',
	'Variable_Scalar'   => 'color:#008800;',
	'Variable_Array'    => 'color:#ff7700;',
	'Variable_Hash'     => 'color:#8800ff;',
	'Variable_Typeglob' => 'color:#ff0033;',
	'Whitespace'        => '',
	'Character'         => 'color:#880000;',
	'Keyword'           => 'color:#000000;',
	'Builtin_Operator'  => 'color:#330000;',
	'Builtin_Function'  => 'color:#000011;',
	'Operator'          => 'color:#000000;',
	'Bareword'          => 'color:#33AA33;',
	'Package'           => 'color:#990000;',
	'Number'            => 'color:#ff00ff;',
	'Symbol'            => 'color:#000000;',
	'CodeTerm'          => 'color:#000000;',
	'DATA'              => 'color:#000000;',
	'LineNumber'        => 'color:#CCCCCC;'
);

sub handler {
	my $r = shift;
	my $str;  # buffered output
	my $mtime;
	my $have_to_cache = 0;
	
	return (MP2 ? Apache::DECLINED : Apache::Constants::DECLINED) if $r->args =~ /download/i;

	my $sln = ($r->dir_config('HighlightShowLineNumbers') =~ /^on$/i || $r->args =~ /ShowLineNumbers/i) ? 1 : 0;
	my $key = $r->filename . $sln;
	my $debug = $r->dir_config('HighlightDebug') eq 'On' ? 1 : 0;
		
	# Cache feature
	if ( $can_cache && $r->dir_config('HighlightCache') =~ /^on$/i ) {
		$mtime = (stat $r->filename)[9];
		# File needs to be processed
		if ( ! defined $stat{$key} || $mtime > $stat{$key} ) {
			$stat{$key} = $mtime;
			$have_to_cache = 1;
			print STDERR "[$$] We have to cache!\n" if $debug;
		}
		# We have already in cache
		else {
			$str = get_cache( file => $key, dir => $r->dir_config('HighlightCacheDir') || '/tmp', debug => $debug );
		}
		use Data::Dumper;
		print STDERR ("[$$] " . $r->filename . "\n" . Dumper(\%stat)) if $debug;
	}

	# When we must highlight?
	if ( $have_to_cache || ! $str ) {
	
		print STDERR "[$$] Generating highlight...\n" if $debug;

		my $formatter = new Syntax::Highlight::Perl;
	
		# Open file to highlight
		my $fh = new IO::File($r->filename);
	
		# Escapes HTML
		$formatter->define_substitution('<' => '&lt;', '>' => '&gt;', '&' => '&amp;'); 

		# Install the formats 
		if ( $r->dir_config('HighlightCSS') ) {
			foreach (keys %default_styles) {
				$formatter->set_format($_, [ "<span class=\"$_\">",'</span>' ] );
			}
			$str = '<LINK HREF="' . $r->dir_config('HighlightCSS') . '" REL="stylesheet" TYPE="text/css"><PRE>';
		}
		else {
			while ( my($type,$style) = each %default_styles ) {
				$formatter->set_format($type, [ "<span style=\"$style\">",'</span>' ] );
				$str = '<PRE style="font-size:10pt;color:#333366;">';
			}
		}
		my @lines = $formatter->format_string(<$fh>);
		undef $fh;

		# Adds line numbers
		if ( $sln ) {
			my $line_number = 1;
			my $max_space = length($formatter->line_count) + 1;
			@lines = map { '&nbsp;' x ($max_space - length($line_number)) . '<span class="LineNumber">' . $line_number++ . '</span>&nbsp;' . $_ } @lines;
		}
		$str .= join('',@lines) . '</PRE>';
	}

	if ( $have_to_cache ) {
		put_cache( file => $key, content => $str, dir => $r->dir_config('HighlightCacheDir') || '/tmp', debug => $debug );
	}

	# Output code to client
	$r->content_type('text/html');
	MP2 ? 1 : $r->send_http_header;
	$r->print($str);
	return MP2 ? Apache::OK : Apache::Constants::OK;
}

sub get_cache {
	my %args = @_;
	$args{'key'} ||= Digest::MD5->md5_hex($args{'file'});
	return undef if ! $args{'file'};
	print STDERR "[$$] Opening file: $args{'dir'}/$args{'key'}\n" if $args{'debug'};	
	my $fh = new IO::File("$args{'dir'}/$args{'key'}");
	my $slurp = do { local $/; <$fh> };
	return $slurp;
}				

sub put_cache {
	my %args = @_;
	return 0 if ( $args{'dir'} !~ /^\/tmp/ );
	$args{'key'} ||= Digest::MD5->md5_hex($args{'file'});
	return 0 if ( ! $args{'key'} || ! $args{'content'} );
	print STDERR "[$$] Writing file: $args{'dir'}/$args{'key'}\n" if $args{'debug'};
	my $fh;
	if ( open($fh,">$args{'dir'}/$args{'key'}") ) {
		flock($fh,2) if $^O !~ /win32/i;
		print $fh $args{'content'};
		flock($fh,8) if $^O !~ /win32/i;
		close($fh);
		return 1;
	}
	return 0;
}				

1;
__END__

=pod

=head1 NAME

Apache::Syntax::Highlight::Perl - mod_perl 1.0/2.0 extension to 
highlight Perl code

=head1 SYNOPSIS

In F<httpd.conf> (mod_perl 1):

   PerlModule Apache::Syntax::Highlight::Perl

   <FilesMatch "\.((p|P)(l|L|m|M)|t)$">
      SetHandler perl-script
      PerlHandler Apache::Syntax::Highlight::Perl
      PerlSetVar HighlightShowLineNumbers On
      PerlSetVar HighlightCSS http://path.to/highlight.css
   </FilesMatch>

In F<httpd.conf> (mod_perl 2):

   PerlModule Apache2
   PerlModule Apache::Syntax::Highlight::Perl

   <FilesMatch "\.((p|P)(l|L|m|M)|t)$">
      SetHandler perl-script
      PerlResponseHandler Apache::Syntax::Highlight::Perl
      PerlSetVar HighlightShowLineNumbers On
      PerlSetVar HighlightCSS http://path.to/highlight.css
   </FilesMatch>

=head1 DESCRIPTION

Apache::Syntax::Highlight::Perl is a mod_perl (1.0 and 2.0) module that
provides syntax highlighting for Perl code. This module is a wrapper around
L<Syntax::Highlight::Perl|Syntax::Highlight::Perl>.

=head1 MOD_PERL 2 COMPATIBILITY

Apache::Syntax::Highlight::Perl is fully compatible with both mod_perl
generations 1.0 and 2.0.

If you have mod_perl 1.0 and 2.0 installed on the same system and the two uses
the same per libraries directory, to use mod_perl 2.0 version make sure to load
first C<Apache2> module which will perform the necessary adjustements to
C<@INC>:

   PerlModule Apache2
   PerlModule Apache::Syntax::Highlight::Perl

Of course, notice that if you use mod_perl 2.0, there is no need to pre-load
the L<Apache::compat|Apache::compat> compatibility layer.

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
better.

Prerequisites:

=over 4

=item * mod_perl 1 or 2 (of course)

=item * Syntax::Highlight::Perl >= 1.00

=back 

Installation as usual:

   % perl Makefile.PL
   % make
   % make test
   % su
     Password: *******
   % make install

=head1 CONFIGURATION

In order to enable Perl file syntax highlighting you could modify I<httpd.conf>
or I<.htaccess> files.

=head1 DIRECTIVES

You can control the behaviour of this module by configuring the following
variables with C<PerlSetVar> directive  in the I<httpd.conf> (or I<.htaccess>
files)

=over 4

=item C<HighlightCSS> string

This single directive sets the URL (or URI) of the custom CCS file.

   PerlSetVar HighlightCSS /highlight/perl.css

It can be placed in server config, <VirtualHost>, <Directory>, <Location>,
<Files> and F<.htaccess> context.  

The CSS file is used to define styles for all the syntactical elements that
L<Syntax::Highlight::Perl|Syntax::Highlight::Perl> currently recognizes.

For each style there is a correspondant syntactical element. The elements are:

=over 4

=item Comment_Normal 

Default is C<{color:#006699;font-style:italic;}>

=item Comment_POD 

Default is C<{color:#001144;font-family:garamond,serif;font-size:11pt;font-style:italic;}>

=item Directive 

Default is C<{color:#339999;font-style:italic;}>

=item Label

Default is C<{color:#993399;font-style:italic;}>

=item Quote 

Default is C<{color:#0000aa;}>

=item String

Default is C<{color:#0000aa;}>

=item Subroutine 

Default is C<{color:#998800;}>

=item Variable_Scalar

Default is C<{color:#008800;}>

=item Variable_Array 

Default is C<{color:#ff7700;}>

=item Variable_Hash 

Default is C<{color:#8800ff;}>

=item Variable_Typeglob 

Default is C<{color:#ff0033;}>

=item Whitespace

Not yet used

=item Character

Default is C<{color:#880000;}>

=item Keyword 

Default is C<{color:#000000; font-weight:bold;}>

=item Builtin_Function 

Default is C<{color:#000000; font-weight:bold;}>

=item Builtin_Operator 

Default is C<{color:#000000; font-weight:bold;}>

=item Operator

Default is C<{color:#000000;}>

=item Bareword 

Default is C<{color:#33AA33;}>

=item Package

Default is C<{color:#990000;}>

=item Number

Default is C<{color:#ff00ff;}>

=item Symbol

Default is C<{color:#000000;}>

=item CodeTerm 

Default is C<{color:#AA0000;}>

=item DATA

Default is C<{color:#CCCCCC;}>

=item LineNumber 

This style hasn't a correspondant syntactical element but is used to display
line numbers to the right of the code. Default is C<{color:#CCCCCC;}>

=back

See C<FORMAT TYPES> section of
L<Syntax::Highlight::Perl|Syntax::Highlight::Perl> POD for more informations
about elements currently recognized.

=item C<HighlightShowLineNumbers> On|Off

This single directive displays line numbers to the right of the text

   PerlSetVar HighlightShowLineNumbers On

It can be placed in server config, <VirtualHost>, <Directory>, <Location>,
<Files> and F<.htaccess> context. The default value is C<Off>.

=item C<HighlightCache> On|Off

This directive enables a very simple cache layer of already and unchanged
highlighted files:

   PerlSetVar HighlightCache On

Default is C<Off>.

=item C<HighlightCacheDir> string

This directive sets cache directory 

   PerlSetVar HighlightCacheDir /tmp/highlight

Default is C</tmp>.

=back

=head1 RUN TIME CONFIGURATION

In addition, you can control the module behaviour at run time by adding
some values via the query string. In particular:

=over 4

=item download

Forces the module to exit with DECLINED status, for example by allowing
users to download the file (according to Apache configuration):

   http://myhost.com/myproject/sample.pl?download

=item showlinenumbers

Forces showing of code line numbers. For example:

   http://myhost.com/myproject/sample.pl?showlinenumbers

=back

=head1 BUGS 

Please submit bugs to CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache%3A%3ASyntax%3A%3AHighlight%3A%3APerl
or by email at bug-apache-syntax-highlight-perl@rt.cpan.org

Patches are welcome and I'll update the module if any problems will be found.

=head1 VERSION

Version 1.01

=head1 TODO

=over 4

=item *

Use of Cache::Cache:: family in order to cache highlighted files.

back

=head1 SEE ALSO

L<Syntax::Highlight::Perl|Syntax::Highlight::Perl>, L<Apache|Apache>,
L<IO::FIle|IO::File>, perl

=head1 AUTHOR

Enrico Sorcinelli, E<lt>enrico@sorcinelli.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Enrico Sorcinelli

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.2 or, at your option,
any later version of Perl 5 you may have available.

=cut
