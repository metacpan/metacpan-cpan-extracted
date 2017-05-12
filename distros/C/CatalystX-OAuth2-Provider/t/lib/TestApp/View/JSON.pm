package TestApp::View::JSON;

use strict;
use Moose;
use JSON::XS ();

extends 'Catalyst::View::JSON';


__PACKAGE__->config( expose_stash => qr/[^current_view]/ );

my $encoder = JSON::XS->new
                      ->utf8
                      ->pretty(0)
                      ->indent(0)
                      ->allow_blessed(1)
                      ->convert_blessed(1);

sub encode_json {
    my( $self, $c, $data ) = @_;
    $encoder->encode( $data );
}

=head1 NAME
=cut

1;
