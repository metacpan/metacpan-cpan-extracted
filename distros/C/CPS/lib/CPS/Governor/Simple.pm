#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package CPS::Governor::Simple;

use strict;
use warnings;

use base qw( CPS::Governor );

our $VERSION = '0.18';

=head1 NAME

C<CPS::Governor::Simple> - iterate immediately as fast as possible

=head1 SYNOPSIS

 use CPS qw( gkforeach );
 use CPS::Governor::Simple;

 my $gov = CPS::Governor::Simple->new;

 gkforeach( $gov, [ 1 .. 10 ],
    sub { 
       my ( $item, $knext ) = @_;

       print "$item\n";
       goto &$knext;
    },
    sub {},
 );

=head1 DESCRIPTION

This L<CPS::Governor> allows the functions using it to run as fast as
possible. It invokes its continuations immediately using a tailcall, so as not
to let the stack grow arbitrarily.

Its constructor takes no special arguments, and it provides no other methods
beyond those of C<CPS::Governor>.

=cut

sub again
{
   my $self = shift;
   my $code = shift;

   goto &$code; # intentionally leave @_ alone
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
