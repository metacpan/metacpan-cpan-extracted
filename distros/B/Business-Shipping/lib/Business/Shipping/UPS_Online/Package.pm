package Business::Shipping::UPS_Online::Package;

=head1 NAME

Business::Shipping::UPS_Online::Package

=head1 METHODS

=over 4

=cut

use Any::Moose;
use Business::Shipping::Package;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::Package';

=item * packaging

UPS_Online-only attribute.

=item * signature_type

  UPS_Online-only attrbute.

  If not set, then DeliveryConfirmation/DCISType will not be sent to UPS.

  Possible values:

  1 - No signature required.
  2 - Signature required.
  3 - Adult signature required.

  Only valid for US domestic shipments.

=item * insured_currency_type

  UPS_Online-only attribute
  
  Used in conjunction with insured_value.

=item * insured_value
  
  UPS_Online-only attribute
 
=cut

has 'packaging' => (
    is      => 'rw',
    isa     => 'Str',
    default => '02',
);

has 'signature_type'        => (is => 'rw');
has 'insured_currency_type' => (is => 'rw');
has 'insured_value'         => (is => 'rw');

# NOTE: Causes "Unsupported packaging requested." error.
#__PACKAGE__->meta()->make_immutable();

1;

__END__

=back

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
