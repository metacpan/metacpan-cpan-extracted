#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package CPS::Future;

use strict;
use warnings;

our $VERSION = '0.18';

use base qw( Future );

=head1 NAME

C<CPS::Future> - compatibility wrapper around L<Future>

=head1 DESCRIPTION

This module provides a compatibility wrapper around L<Future>. The code it
used to contain was renamed to move it out of the C<CPS> distribution.
Existing code that refers to C<CPS::Future> should be changed to use C<Future>
instead.

=cut

=head2 $future->( @result )

This subclass overloads the calling operator, so simply invoking the future
object itself as if it were a C<CODE> reference is equivalent to calling the
C<done> method. This makes it simple to pass as a callback function to other
code.

It turns out however, that this behaviour is too subtle and can lead to bugs
when futures are accidentally used as plain C<CODE> references. See the
C<done_cb> method instead. This overload behaviour will be removed in a later
version.

=cut

use overload '&{}' => 'done_cb',
             fallback => 1;

0x55AA;
