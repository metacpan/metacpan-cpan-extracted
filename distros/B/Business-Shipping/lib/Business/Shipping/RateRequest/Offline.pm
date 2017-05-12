package Business::Shipping::RateRequest::Offline;

=head1 NAME

Business::Shipping::RateRequest::Offline - Abstract class for cost calculation.

=head1 DESCRIPTION

This doesn't have very much to it.  It just disables the cache feature, and has
a few miscellaneous functions.

=head1 METHODS

=over 4

=cut

use Any::Moose;
use Business::Shipping::RateRequest;
use Business::Shipping::Shipment;
use Business::Shipping::Package;
use Business::Shipping::Logging;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::RateRequest';

__PACKAGE__->meta()->make_immutable();

=item * perform_action()

For compatibility with parent class

=cut

sub perform_action { }

=item * cache()

Cache always disabled for Offline lookups: they are so fast already, the disk I/O
of a running a cache is not worth it.

=cut

sub cache { return 0; }

=item * make_three( $zip )

 $zip   Input to shorten/lengthen.  Usually a zip code.
 
Shorten to three digits.  If the input doesn't have leading zeros, add them.

=cut

sub make_three {
    my ($self, $zip) = @_;
    return unless $zip;
    trace('( ' . ($zip ? $zip : 'undef') . ' )');

    $zip = substr($zip, 0, 3);
    while (length($zip) < 3) {
        $zip = "0$zip";
    }

    return $zip;
}

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
