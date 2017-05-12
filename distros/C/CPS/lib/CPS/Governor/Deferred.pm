#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package CPS::Governor::Deferred;

use strict;
use warnings;

use base qw( CPS::Governor );

our $VERSION = '0.18';

=head1 NAME

C<CPS::Governor::Deferred> - iterate at some later point

=head1 SYNOPSIS

 use CPS qw( gkforeach );
 use CPS::Governor::Deferred;

 my $gov = CPS::Governor::Deferred->new;

 gkforeach( $gov, [ 1 .. 10 ],
    sub { 
       my ( $item, $knext ) = @_;

       print "A$item ";
       goto &$knext;
    },
    sub {},
 );

 gkforeach( $gov, [ 1 .. 10 ],
    sub {
       my ( $item, $knext ) = @_;

       print "B$item ";
       goto &$knext;
    },
    sub {},
 );

 $gov->flush;

=head1 DESCRIPTION

This L<CPS::Governor> allows the functions using it to delay their iteration
until some later point when the containing program invokes it. This allows two
main advantages:

=over 4

=item *

CPU-intensive operations may be split apart and mixed with other IO operations

=item *

Multiple control functions may be executed in pseudo-parallel, interleaving
iterations of each giving a kind of concurrency

=back

These are achieved by having the governor store a list of code references that
need to be invoked, rather than invoking them immediately. These references
can then be invoked later, perhaps by using an idle watcher in an event
framework.

Because each code reference hasn't yet been invoked by the time the C<again>
method is called, the original caller is free to store more pending references
with the governor. This allows multiple control functions to be interleaved,
as in the C<A> and C<B> example above.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $gov = CPS::Governor::Deferred->new( %args )

Returns a new instance of a C<CPS::Governor::Deferred> object. Requires no
parameters but may take any of the following to adjust its default behaviour:

=over 8

=item defer_after => INT

If given some positive number, C<$n> then the first C<$n-1> invocations of the
C<again> method will in fact be executed immediately. Thereafter they will be
enqueued in the normal mechanism. This gives the effect that longrunning loops
will be executed in batches of C<$n>.

If not supplied then every invocation of C<again> will use the queueing
mechanism.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{defer_after} = $args{defer_after} || 0;

   return $self;
}

sub again
{
   my $self = shift;

   if( $self->{defer_after} and ++$self->{count} < $self->{defer_after} ) {
      my $code = shift;
      # args still in @_

      goto &$code;
   }

   $self->later( @_ );
}

sub later
{
   my $self = shift;

   push @{ $self->{queue} }, [ @_ ];
}

=head1 METHODS

=cut

=head2 $pending = $gov->is_pending

Returns true if at least one code reference has been stored that hasn't yet
been invoked.

=cut

sub is_pending
{
   my $self = shift;

   return $self->{queue} && @{ $self->{queue} } > 0;
}

=head2 $gov->prod

Invokes all of the currently-stored code references, in the order they were
stored. If any new references are stored by these, they will not yet be
invoked, but will be available for the next time this method is called.

=cut

sub prod
{
   my $self = shift;

   $self->{count} = 0;

   my $queue = $self->{queue};
   $self->{queue} = [];

   foreach my $item ( @$queue ) {
      my ( $code, @args  ) = @$item;
      $code->( @args );
   }
}

=head2 $gov->flush

Repeatedly calls C<prod> until no more code references are pending.

=cut

sub flush
{
   my $self = shift;

   $self->prod while $self->is_pending;
}

=head1 SUBCLASS METHODS

The following methods are used internally to implement the functionality,
which may be useful to implementors of subclasses.

=cut

=head2 $gov->later( $code, @args )

Used to enqueue the C<$code> ref to be invoked later with the given C<@args>,
once it is determined this should be deferred (rather than being invoked
immediately in the case of the first few invocations when C<defer_after> is
set).

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
