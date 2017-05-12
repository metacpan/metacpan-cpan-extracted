package Catalyst::Helper::View::GD::Barcode::QRcode;

use strict;

=head1 NAME

Catalyst::Helper::View::GD::Barcode::QRcode - Helper for GD::Barcode::QRcode Views


=head1 SYNOPSIS

    script/create.pl view MyQRcode GD::Barcode::QRcode


=head1 DESCRIPTION

Helper for GD::Barcode::QRcode Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

F<Catalyst>, F<Catalyst::View::GD::Barcode::QRcode>, F<GD::Barcode::QRcode>.


=head1 AUTHOR

Hideo Kimura C<< <<hide@hide-k.net>> >>


=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::GD::Barcode::QRcode';

=head1 NAME

[% class %] - Catalyst GD::Barcode::QRcode View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst GD::Barcode::QRcode View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

