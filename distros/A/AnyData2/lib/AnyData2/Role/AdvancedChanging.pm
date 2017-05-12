package AnyData2::Role::AdvancedChanging;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;

=head1 NAME

AnyData2::Role::AdvancedChanging - provides role for in-place changing capabilities

=cut

our $VERSION = '0.002';

=head1 METHODS

In fact, this role doesn't export anything. It's intended for C<< ->DOES() >>
and documenting the reasonable methods one should implement when doing
C<AnyData2::Role::AdvancedChanging>.

=head2 insert_new_row

Defines if a format can easily insert a new row without need to seek
or truncate. This capability is provided by defining the class method
C<insert_new_row>.

=head2 delete_one_row

Defines whether the format can delete one single row by it's content or not.

=head2 delete_current_row

Defines whether a table can delete the current traversed row or not.

=head2 update_one_row

Defines whether the format is able to update one single row. This
capability is used for backward compatibility and might have
(depending on table implementation) several limitations. Please
carefully study the documentation of the format or ask the author of
the format, if this information is not provided.

=head2 update_current_row

Defines if the format is able to update the currently touched row.

=head2 update_specific_row

Defines if the format is able to update one single row.

=head1 LICENSE AND COPYRIGHT

Copyright 2015,2016 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
