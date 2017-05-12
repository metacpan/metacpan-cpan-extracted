package Business::Shipping::UPS_Offline::Package;

=head1 NAME

Business::Shipping::UPS_Offline::Package

=head1 METHODS

=over 4

=cut

use Any::Moose;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::Package';

__PACKAGE__->meta()->make_immutable();

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
