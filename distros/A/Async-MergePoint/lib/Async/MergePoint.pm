#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2011 -- leonerd@leonerd.org.uk

package Async::MergePoint;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;

=head1 NAME

C<Async::MergePoint> - resynchronise diverged control flow

=head1 SYNOPSIS

 use Async::MergePoint;

 my $merge = Async::MergePoint->new(
    needs => [ "leaves", "water" ],
 );

 my $water;
 Kettle->boil(
    on_boiled => sub { $water = shift; $merge->done( "water" ); }
 );

 my $tea_leaves;
 Cupboard->get_tea_leaves(
    on_fetched => sub { $tea_leaves = shift; $merge->done( "leaves" ); }
 );

 $merge->close(
    on_finished => sub {
       # Make tea using $water and $tea_leaves
    }
 );

=head1 DESCRIPTION

Often in program logic, multiple different steps need to be taken that are
independent of each other, but their total result is needed before the next
step can be taken. In synchonous code, the usual approach is to do them
sequentially. 

An asynchronous or event-based program could do this, but if each step
involves some IO idle time, better overall performance can often be gained by
running the steps in parallel. A C<Async::MergePoint> object can then be used
to wait for all of the steps to complete, before passing the combined result
of each step on to the next stage.

A merge point maintains a set of outstanding operations it is waiting on;
these are arbitrary string values provided at the object's construction. Each
time the C<done()> method is called, the named item is marked as being
complete. When all of the required items are so marked, the C<on_finished>
continuation is invoked.

For use cases where code may be split across several different lexical scopes,
it may not be convenient or possible to share a lexical variable, to pass on
the result of some asynchronous operation. In these cases, when an item is
marked as complete a value can also be provided which contains the results of
that step. The C<on_finished> callback is passed a hash (in list form, rather
than by reference) of the collected item values.

This module was originally part of the L<IO::Async> distribution, but was
removed under the inspiration of Pedro Melo's L<Async::Hooks> distribution,
because it doesn't itself contain anything IO-specific.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $merge = Async::MergePoint->new( %params )

This function returns a new instance of a C<Async::MergePoint> object. The
C<%params> hash takes the following keys:

=over 8

=item needs => ARRAY

Optional. An array containing unique item names to wait on. The order of this
array is not significant.

=item on_finished => CODE

Optional. CODE reference to the continuation for when the merge point becomes
ready. If provided, will be passed to the C<close> method.

=back

=cut

sub new
{
   my $class = shift;
   my ( %params ) = @_;

   my $self = bless {
      needs => {},
      items => {},
   }, $class;

   if( $params{needs} ) {
      ref $params{needs} eq 'ARRAY' or croak "Expected 'needs' to be an ARRAY ref";
      $self->needs( @{ $params{needs} } );
   }

   if( $params{on_finished} ) {
      $self->close( on_finished => $params{on_finished} );
   }

   return $self;
}

=head1 METHODS

=cut

=head2 $merge->close( %params )

Allows an C<on_finished> continuation to be set if one was not provided to the
constructor.

=over 8

=item on_finished => CODE

CODE reference to the continuation for when the merge point becomes ready.

=back

The C<on_finished> continuation will be called when every key in the C<needs>
list has been notified by the C<done()> method. It will be called as

 $on_finished->( %items )

where the C<%items> hash will contain the item names that were waited on, and
the values passed to the C<done()> method for each one. Note that this is
passed as a list, not as a HASH reference.

While this feature can be used to pass data from the component parts back up
into the continuation, it may be more direct to use normal lexical variables
instead. This method allows the continuation to be placed after the blocks of
code that execute the component parts, so it reads downwards, and may make it
more readable.

=cut

sub close
{
   my $self = shift;
   my %params = @_;

   ref $params{on_finished} eq 'CODE' or croak "Expected 'on_finished' to be a CODE ref";

   $self->{on_finished} and croak "Already have an 'on_finished', can't set another";
   
   $self->{on_finished} = $params{on_finished};

   if( !keys %{ $self->{needs} } ) {
      # Execute it now
      $self->{on_finished}->( %{$self->{items}} );
   }
}

=head2 $merge->needs( @keys )

When called on an open MergePoint (i.e. one that does not yet have an
C<on_finished> continuation), this method adds extra key names to the set of
outstanding names. The order of this list is not significant.

This method throws an exception if the MergePoint is already closed.

=cut

sub needs
{
   my $self = shift;

   $self->{on_finished} and croak "Cannot add extra keys to a closed MergePoint";

   foreach my $key ( @_ ) {
      $self->{needs}{$key} and croak "Already need '$key'";
      $self->{needs}{$key}++;
   }
}

=head2 $merge->done( $item, $value )

This method informs the merge point that the C<$item> is now ready, and
passes it a value to store, to be passed into the C<on_finished> continuation.
If this call gives the final remaining item being waited for, the
C<on_finished> continuation is called within it, and the method will not
return until it has completed.

=cut

sub done
{
   my $self = shift;
   my ( $item, $value ) = @_;

   exists $self->{needs}->{$item} or croak "$self does not need $item";

   delete $self->{needs}->{$item};
   $self->{items}->{$item} = $value;

   if( !keys %{ $self->{needs} } and $self->{on_finished} ) {
      $self->{on_finished}->( %{$self->{items}} );
   }
}

=head1 EXAMPLES

=head2 Asynchronous Plugins

Consider a program using C<Module::Pluggable> to provide a plugin architecture
to respond to events, where sometimes the response to an event may require
asynchronous work. A C<MergePoint> object can be used to coordinate the
responses from the plugins to this event.

 my $merge = Async::MergePoint->new();

 foreach my $plugin ( $self->plugins ) {
    $plugin->handle_event( "event", $merge, @args );
 }

 $merge->close( on_finished => sub {
    my %results = @_;
    print "All plugins have recognised $event\n";
 } );

Each plugin that wishes to handle the event can use its own package name, for
example, as its unique key name for the MergePoint. A plugin handling the
event synchonously could perform something such as:

 sub handle_event
 {
    my ( $event, $merge, @args ) = @_;
    ....
    $merge->needs( __PACKAGE__ );
    $merge->done( __PACKAGE__ => $result );
 }

Whereas, to handle the event asynchronously the plugin can instead perform:

 sub handle_event
 {
    my ( $event, $merge, @args ) = @_;
    ....
    $merge->needs( __PACKAGE__ );

    sometime_later( sub {
       $merge->done( __PACKAGE__ => $result );
    } );
 }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
