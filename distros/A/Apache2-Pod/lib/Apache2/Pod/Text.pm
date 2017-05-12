package Apache2::Pod::Text;

=head1 NAME

Apache2::Pod::Text - mod_perl handler to convert Pod to plain text

=head1 VERSION

Version 0.27

=cut

use strict;
use vars qw( $VERSION );

$VERSION = '0.27';

=head1 SYNOPSIS

A simple mod_perl handler to easily convert Pod to Text.

=head1 CONFIGURATION

You can replace Apache2::Pod::HTML with Apache2::Pod::Text as your 
C<PerlHandler> in your apache configuration if you wish to use the
text rendering of your pod documentation instead of HTML.
See L<Apache2::Pod::HTML> for configuration details.  

=cut

use Apache2::Pod;
use Apache2::Const -compile => qw( OK );
use Pod::Simple::Text;

sub handler {
	my $r = shift;

	my $str;
	my $file = Apache2::Pod::getpodfile( $r );
	my $fun = undef;
	my $parser = Pod::Simple::Text->new;
	$parser->complain_stderr(1);
	$parser->output_string( \$str );
	if ( $file ) {
		if ( $file =~ /^-f<([^>]*)>::(.*)$/ ) {
			$fun = $1;
			$file = $2;
		}
		if ( $fun ) {
			my $document = Apache2::Pod::getpodfuncdoc( $file, $fun );
			$parser->parse_string_document( $document );
		}
		else {
			$parser->parse_file( $file );
		}
	}
	else {
		my $modstr = Apache2::Pod::resolve_modname( $r ) || $r->filename || '';
		my $document = sprintf "=item %1\$s\n\nNo documentation found for \"%1\$s\".\n", $modstr;
		$parser->parse_string_document( $document );
	}
	$r->content_type('text/plain');
	$r->print( $str );
	
	return Apache2::Const::OK;
}

=head1 SEE ALSO

L<Apache2::Pod>,
L<Apache2::Pod::HTML>

=head1 AUTHOR

Theron Lewis C<< <theron at theronlewis dot com> >>

=head1 HISTORY

Adapteded from Andy Lester's C<< <andy at petdance dot com> >> Apache::Pod
package which was adapted from 
Apache2::Perldoc by Rich Bowen C<< <rbowen@ApacheAdmin.com> >>

=head1 ACKNOWLEDGEMENTS

Thanks also to
Pete Krawczyk,
Kjetil Skotheim,
Kate Yoak
and
Chris Eade
for contributions.

=head1 LICENSE

This package is licensed under the same terms as Perl itself.

=cut

1;
