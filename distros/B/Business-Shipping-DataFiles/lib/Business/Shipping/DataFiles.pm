package Business::Shipping::DataFiles;

use warnings;
use strict;

=head1 NAME

Business::Shipping::DataFiles - Offline rate tables for Business::Shipping 

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

1;

__END__

=head1 SYNOPSIS

To use any of the Business::Shipping offline cost estimation methods, this 
module is required.  It installs all of the rate tables that Business::Shipping
relies on.  It is stored in a separate module because it is updated less 
frequently than Business::Shipping.

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See LICENSE for more info.

=cut
