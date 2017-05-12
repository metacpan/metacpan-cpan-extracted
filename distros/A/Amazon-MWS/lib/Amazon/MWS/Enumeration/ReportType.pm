package Amazon::MWS::Enumeration::ReportType;

use strict;
use warnings;

use base qw(Amazon::MWS::Enumeration);

__PACKAGE__->define qw(
    _GET_FLAT_FILE_OPEN_LISTINGS_DATA_
    _GET_MERCHANT_LISTINGS_DATA_
    _GET_MERCHANT_LISTINGS_DATA_LITE_
    _GET_MERCHANT_LISTINGS_DATA_LITER_
    _GET_MERCHANT_CANCELLED_LISTINGS_DATA_
    _GET_NEMO_MERCHANT_LISTINGS_DATA_
    _GET_AFN_INVENTORY_DATA_
    _GET_FLAT_FILE_ACTIONABLE_ORDER_DATA_
    _GET_ORDERS_DATA_
    _GET_FLAT_FILE_ORDER_REPORT_DATA_
    _GET_FLAT_FILE_ORDERS_DATA_
    _GET_CONVERGED_FLAT_FILE_ORDER_REPORT_DATA_
);

1;

__END__

=head1 NAME

Amazon::MWS::Enumeration::ReportType

=head1 CONSTANTS

=over 4

=item _GET_FLAT_FILE_OPEN_LISTINGS_DATA_

=item _GET_MERCHANT_LISTINGS_DATA_

=item _GET_MERCHANT_LISTINGS_DATA_LITE_

=item _GET_MERCHANT_LISTINGS_DATA_LITER_

=item _GET_MERCHANT_CANCELLED_LISTINGS_DATA_

=item _GET_NEMO_MERCHANT_LISTINGS_DATA_

=item _GET_AFN_INVENTORY_DATA_

=item _GET_FLAT_FILE_ACTIONABLE_ORDER_DATA_

=item _GET_ORDERS_DATA_

=item _GET_FLAT_FILE_ORDER_REPORT_DATA_

=item _GET_FLAT_FILE_ORDERS_DATA_

=item _GET_CONVERGED_FLAT_FILE_ORDER_REPORT_DATA_

=back

=head1 SEE ALSO

L<Amazon::MWS::Enumeration>

=head1 AUTHOR

Paul Driver C<< frodwith@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Plain Black Corporation L<http://plainblack.com>.
All rights reserved

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See L<perlartistic>.
