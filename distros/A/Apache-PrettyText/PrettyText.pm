#!/usr/bin/perl
## Emacs: -*- tab-width: 4; -*-

use strict;

package Apache::PrettyText;

use vars qw($VERSION);				$VERSION = '1.08';

=pod

=head1 NAME

Apache::PrettyText - Simple mod_perl PerlHandler for text files

=head1 SYNOPSIS

	## In httpd.conf:
	<Perl>
	use Apache::PrettyText;
	</ Perl> ## <-- Omit the space if you copy this example.

	<Files ~ "\.txt$">
	SetHandler perl-script
	PerlHandler Apache::PrettyText
	</Files>

To modify your Apache server to dynamically format .txt files so they
look nicer in the client's browser, put the following directives into
httpd.conf, or in any VirtualHost section and restart the server.

Optional: Insert a <Perl> section that changes
$Apache::PrettyText::TabWidth to your site's standard or set to 0 to
disable detabbing.  If you don't set it, the default is 4.

	## In httpd.conf:
	<Perl>
	$Apache::PrettyText::TabWidth = 4;  
	</ Perl> ## <-- Omit the space if you copy this example.

You must be using mod_perl. See http://perl.apache.org for details.

=head1 DESCRIPTION

This is a simple Apache handler written in Perl that converts text
files on the fly into a basic HTML format:

=over 4

=item *

surrounded by <PRE> tags

=item  *

tabs converted to spaces (optional)

=item  *

white background

=item  *

hilited URLs

=item  *

first line of text file = <TITLE>

=back

Also serves as a good template to help you write your own simple

handler.  I wrote this as an exercise because I found no good
examples.

=head1 INSTALLATION

Using CPAN module:

	perl -MCPAN -e 'install Apache::PrettyText'

Or manually:

	tar xzvf Apache-PrettyText*gz
	cd Apache-PrettyText-1.??
	perl Makefile.PL
	make
	make test
	make install

If you're reading this in pod or man, it's already installed.  If
you're reading the source code in PrettyText.pm, you can copy this
file under the name "PrettyText.pm" into this location:

	/usr/lib/perl5/site_perl/Apache/

... or its equivalent on your computer.


A helpful tip: you can include the entire contents of the
PrettyText.pm file or of your own version of it into a <Perl> section
within httpd.conf.  This can be very helpful if you'd like to use this
module as a template for your own.

To syntax-check your code under those circumstances, use:

	perl -cx httpd.conf

... which will read just the perl code between #!...perl and __END__
in the httpd.conf file.

=head1 AUTHOR

Chris Thorman <chthorman@cpan.org>

Copyright (c) 1995-2002 Chris Thorman.  All rights reserved.  

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Apache(3), mod_perl, http://perl.apache.org/src/contrib

The Apache::PrettyText home page:

	http://christhorman.com/projects/perl/Apache-PrettyText/

The implementation in PrettyText.pm.

=head1 THANKS

Thanks to Vivek Khera, Doug MacEachern, Jeffrey William Baker for
suggestions and corrections.

=cut {};

## use Apache::Constants ':common'; ## for OK (200) and NOT_FOUND (304)
use constant OK			=> 200;
use constant NOT_FOUND	=> 304;

sub handler
{
    my ($r) = @_;
	my $Status = NOT_FOUND;

	## Get a unique file handle; register a routine to guarantee it
	## gets closed.

	my $fh = $r->gensym; 
	$r->register_cleanup(sub {close $fh}); 

	## Open the requested file.
	my $FileName = $r->filename;
	$r->log_error("Apache::PrettyText: $FileName not found."), goto done
		unless ((-f $FileName) && (-r $FileName) && (open $fh, "<$FileName"));
	
	## Read entire file into memory.
    local $/;    undef $/;
	my $contents = <$fh>;

	## Tab width for de-tabbing; 0 means don't detab.  Override the
	## default setting of 4 by setting $Apache::PrettyText::TabWidth
	## in httpd.conf.

	my $TW = $Apache::PrettyText::TabWidth;
    $TW = 4 unless defined($TW);

    ## Detab

	$contents =~ s{^(.*)}
	{my $X=$1;
	 while($X=~s/^(.*?)\t/$1.' 'x($TW-length($1)%$TW)/e){}; $X
	 }meg if $TW > 1;

	## Quote <, > and & characters, allowing HTML markups to appear as
	## such.

	$contents =~ s/&/&amp;/g;
	$contents =~ s/</&lt;/g;
	$contents =~ s/>/&gt;/g;

	## Make URLS into links
	$contents =~ s{\b((s?https?|ftp|gopher|news|telnet|wais|mailto):
					  (//[-a-zA-Z0-9_\.]+:[0-9]*)?
					  [-a-zA-Z0-9_=?#\$@~`%&:;*+|\/\.,]*
					   [-a-zA-Z0-9_=#\$@~`%&:;*+|\/])}
						{<A HREF="$1">$1</A>}igx;
						
	## Fix any A HREFs to unquote the quoted stuff...						
	$contents =~ s{(A HREF=")(.*?)(">.*?</A>)}{my ($x,$y,$z)=($1,$2,$3); 
										 $y=~s{&gt;}{>}g; 
										 $y=~s{&lt;}{<}g; 
										 $y=~s{&amp;}{&}g; 
										 "$x$y$z"}eigx;
						
	&$Apache::PrettyText::TextCleanHook(\$contents) if ref($Apache::PrettyText::TextCleanHook) eq 'CODE';

	## Wrap in a simple HTML page

    my ($title) = ($contents =~ /(\w.*)/);
    $contents = "<HTML><HEAD><TITLE>$title</TITLE></HEAD>
                 <BODY BGCOLOR=white><PRE>\n$contents\n</PRE></BODY></HTML>";

    $r->content_type("text/html");
    $r->send_http_header;
    $r->print($contents);
	$Status = OK;
	
  done:
	return $Status;
}

1;


