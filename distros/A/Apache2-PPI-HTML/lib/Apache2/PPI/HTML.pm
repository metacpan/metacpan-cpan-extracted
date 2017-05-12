package Apache2::PPI::HTML;

=pod

=head1 NAME

Apache2::PPI::HTML - Apache 2 interface to PPI::HTML

=head1 DESCRIPTION

L<PPI::HTML> is a HTML syntax highlighter for Perl source code. Because
it is based on L<PPI> it can correctly parse just about anything you can
possibly throw at it, and then flexibly generate a HTML version based on
any arbitrary colour scheme you wish, or use a standalone CSS file for
it's style information.

This initial version is primarily intended to serve as a highlighting
service to a AJAX-based syntax highlighter.

The handler recieves a chunk of Perl source code from the browser in
the CGI C<'code'> parameter, and a second C<'ajax'> param determines if
the highlighter is running in AJAX mode.

In AJAX mode, the fragment of formatted HTML is handed back straight up,
without any surrounding body or headers or the other parts of the HTML
wrapper.

With AJAX mode off, it returns a complete HTML document.

With this initial version, you may have some difficulties getting CSS
actually working.

We recommend you wait for the next release, which will support a range
of pre-packaged colour schemes being created for L<PPI::HTML>.

=cut

use 5.006;
use strict;
use warnings;
use PPI;
use PPI::HTML;
use CGI;
use Apache2::RequestRec ();
use Apache2::RequestIO  ();
use Apache2::Const -compile => qw( OK SERVER_ERROR );

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub handler {
	# The request object
	my $r = shift;

	# Long-winded way of getting the user's data...
	my $cgi  = CGI->new( $r );
	my $data = $cgi->param('code');

	# Turn the user's data into HTML
	my $document = PPI::Document->new( \$data )
		or return Apache2::Const::OK;

	my $highlight;
	if ( $cgi->param('ajax') ) {
		$highlight = PPI::HTML->new();	
	} else {
		$highlight = PPI::HTML->new( page => 1 );
	}

	my $html = $highlight->html( $document )
		or return Apache2::Const::SERVER_ERROR;

	# Return to the user
	$r->content_type('text/html');
	$r->print( $html );
	return Apache2::Const::OK;
}

1;

=pod

=head1 TO DO

- Add support for L<PPI::HTML> 0.06 colour schemes.

- Add support for acting as a content filter.

If you like the idea of this module, and would like to volunteer
to help maintain or improve it, your assistance you be greatly
welcomed.

Inquiries via the L<PPI> dicussion mailing list, located on the
SourceForge website. L<http://sourceforge.net/projects/parseperl>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-PPI-HTML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Written by Pete Sergeant (in about 3 minutes) :)

=head1 COPYRIGHT

Copyright 2005 - 2008 Pete Sergeant, Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
