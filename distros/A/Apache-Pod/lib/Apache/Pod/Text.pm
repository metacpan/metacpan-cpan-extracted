package Apache::Pod::Text;

=head1 NAME

Apache::Pod::Text - mod_perl handler to convert Pod to plain text

=head1 VERSION

Version 0.22

=cut

use strict;
use vars qw( $VERSION );

$VERSION = '0.22';

=head1 SYNOPSIS

A simple mod_perl handler to easily convert Pod to Text.

=head1 CONFIGURATION

See L<Apache::Pod::HTML> for configuration details.

=cut

use Apache::Pod;
use Apache::Constants;
use Pod::Simple::Text;

sub handler {
    my $r = shift;

    my $str;
    my $file = Apache::Pod::getpod( $r );

    my $parser = Pod::Simple::Text->new;
    $parser->complain_stderr(1);
    $parser->output_string( \$str );
    $parser->parse_file( $file );

    $r->content_type('text/plain');
    $r->send_http_header;
    $r->print( $str );

    return OK;
}

=head1 AUTHOR

Andy Lester C<< <andy@petdance.com> >>, adapted from Apache::Perldoc by
Rich Bowen C<< <rbowen@ApacheAdmin.com> >>

=head1 LICENSE

This package is licensed under the same terms as Perl itself.

=cut

1;
