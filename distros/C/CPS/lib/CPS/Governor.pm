#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk

package CPS::Governor;

use strict;
use warnings;

use Carp;

our $VERSION = '0.18';

=head1 NAME

C<CPS::Governor> - control the iteration of the C<CPS> functions

=head1 DESCRIPTION

Objects based on this abstract class are used by the C<gk*> variants of the
L<CPS> functions, to control their behavior. These objects are expected to
provide a method, C<again>, which the functions will use to re-invoke
iterations of loops, and so on. By providing a different implementation of
this method, governor objects can provide such behaviours as rate-limiting,
asynchronisation or parallelism, and integration with event-based IO
frameworks.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $gov = CPS::Governor->new

Must be called on a subclass which implements the C<again> method. Returns a
new instance of a governor object in that class.

=cut

sub new
{
   my $class = shift;
   $class->can( "again" ) or croak "Expected to be class that can ->again";
   return bless {}, $class;
}

# We're using this internally in gkpar() but not documenting it currently.
# Details are still experimental.
sub enter
{
   my $self = shift;
   $self->again( @_ );
}

=head1 SUBCLASS METHODS

Because this is an abstract class, instances of it can only be constructed on
a subclass which implements the following methods:

=cut

=head2 $gov->again( $code, @args )

Execute the function given in the C<CODE> reference C<$code>, passing in the
arguments C<@args>. If this is going to be executed immediately, it should
be invoked using a tail-call directly by the C<again> method, so that the
stack does not grow arbitrarily. This can be achieved by, for example:

 @_ = @args;
 goto &$code;

Alternatively, the L<Sub::Call::Tail> may be used to apply syntactic sugar,
allowing you to write instead:

 use Sub::Call::Tail;
 ...
 tail $code->( @args );

=cut

=head1 EXAMPLES

=head2 A Governor With A Time Delay

Consider the following subclass, which implements a C<CPS::Governor> subclass
that calls C<sleep()> between every invocation.

 package Governor::Sleep

 use base qw( CPS::Governor );

 sub new
 {
    my $class = shift;
    my ( $delay ) = @_;

    my $self = $class->SUPER::new;
    $self->{delay} = $delay;

    return $self;
 }

 sub again
 {
    my $self = shift;
    my $code = shift;

    sleep $self->{delay};

    # @args are still in @_
    goto &$code;
 }

=cut

=head1 SEE ALSO

=over 4

=item *

L<Sub::Call::Tail> - Tail calls for subroutines and methods

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
