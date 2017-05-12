package Amazon::MWS::Enumeration::ReportProcessingStatus;

use strict;
use warnings;

use base qw(Amazon::MWS::Enumeration);

__PACKAGE__->define qw(
    _SUBMITTED_
    _IN_PROGRESS_
    _CANCELLED_
    _DONE_
    _DONE_NO_DATA_
);

1;

__END__

=head1 NAME

Amazon::MWS::Enumeration::ReportProcessingStatus

=head1 CONSTANTS

=over 4

=item _SUBMITTED_

=item _IN_PROGRESS_

=item _CANCELLED_

=item _DONE_

=item _DONE_NO_DATA_

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
