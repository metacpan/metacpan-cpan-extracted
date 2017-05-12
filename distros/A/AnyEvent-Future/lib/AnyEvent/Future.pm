#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package AnyEvent::Future;

use strict;
use warnings;

our $VERSION = '0.03';

use base qw( Future );
Future->VERSION( '0.05' ); # to respect subclassing

use Exporter 'import';
our @EXPORT_OK = qw(
   as_future
   as_future_cb
);

use AnyEvent;

=head1 NAME

C<AnyEvent::Future> - use L<Future> with L<AnyEvent>

=head1 SYNOPSIS

 use AnyEvent;
 use AnyEvent::Future;

 my $future = AnyEvent::Future->new;

 some_async_function( ..., cb => sub { $future->done( @_ ) } );

 print Future->await_any(
    $future,
    AnyEvent::Future->new_timeout( after => 10 ),
 )->get;

Or

 use AnyEvent::Future qw( as_future_cb );

 print Future->await_any(
    as_future_cb {
       some_async_function( ..., cb => shift )
    },
    AnyEvent::Future->new_timeout( after => 10 ),
 )->get;

=head1 DESCRIPTION

This subclass of L<Future> integrates with L<AnyEvent>, allowing the C<await>
method to block until the future is ready. It allows C<AnyEvent>-using code to
be written that returns C<Future> instances, so that it can make full use of
C<Future>'s abilities, including L<Future::Utils>, and also that modules using
it can provide a C<Future>-based asynchronous interface of their own.

For a full description on how to use Futures, see the L<Future> documentation.

=cut

# Forward
sub as_future(&);

=head1 CONSTRUCTORS

=cut

=head2 $f = AnyEvent::Future->new

Returns a new leaf future instance, which will allow waiting for its result to
be made available, using the C<await> method.

=cut

=head2 $f = AnyEvent::Future->new_delay( @args )

=head2 $f = AnyEvent::Future->new_timeout( @args )

Returns a new leaf future instance that will become ready at the time given by
the arguments, which will be passed to the C<< AnyEvent->timer >> method.

C<new_delay> returns a future that will complete successfully at the alotted
time, whereas C<new_timeout> returns a future that will fail with the message
C<Timeout>.

=cut

sub new_delay
{
   shift;
   my %args = @_;

   as_future {
      my $f = shift;
      AnyEvent->timer( %args, cb => sub { $f->done } );
   };
}

sub new_timeout
{
   shift;
   my %args = @_;

   as_future {
      my $f = shift;
      AnyEvent->timer( %args, cb => sub { $f->fail( "Timeout" ) } );
   };
}

=head2 $f = AnyEvent::Future->from_cv( $cv )

Returns a new leaf future instance that will become ready when the given
L<AnyEvent::CondVar> instance is ready. The success or failure result of the
future will be the result passed to the condvar's C<send> or C<croak> method.

=cut

sub from_cv
{
   my $class = shift;
   my ( $cv ) = @_;

   my $f = $class->new;

   my $was_cb = $cv->cb;

   $cv->cb( sub {
      my ( $cv ) = @_;
      my @result;
      eval { @result = $cv->recv; 1 } and $f->done( @result ) or
         $f->fail( $@ );

      $was_cb->( @_ ) if $was_cb;
   });

   return $f;
}

=head1 METHODS

=cut

=head2 $cv = $f->as_cv

Returns a new C<AnyEvent::CondVar> instance that wraps the given future; it
will complete with success or failure when the future does.

Note that because C<< AnyEvent::CondVar->croak >> takes only a single string
message for the argument, any subsequent failure semantics are lost from the
Future. To capture these as well, you may wish to use an C<on_fail> callback
or the C<failure> method, to obtain them.

=cut

sub as_cv
{
   my $self = shift;

   my $cv = AnyEvent->condvar;

   $self->on_done( sub { $cv->send( @_ ) } );
   $self->on_fail( sub { $cv->croak( $_[0] ) } );

   return $cv;
}

sub await
{
   my $self = shift;

   my $cv = AnyEvent->condvar;
   $self->on_ready( sub { $cv->send } );

   $cv->recv;
}

=head1 UTILITY FUNCTIONS

The following utility functions are exported as a convenience.

=cut

=head2 $f = as_future { CODE }

Returns a new leaf future instance, which is also passed in to the block of
code. The code is called in scalar context, and its return value is stored on
the future. This will be deleted if the future is cancelled.

 $w = CODE->( $f )

This utility is provided for the common case of wanting to wrap an C<AnyEvent>
function which will want to receive a callback function to inform of
completion, and which will return a watcher object reference that needs to be
stored somewhere.

=cut

sub as_future(&)
{
   my ( $code ) = @_;

   my $f = AnyEvent::Future->new;

   $f->{w} = $code->( $f );
   $f->on_cancel( sub { undef shift->{w} } );

   return $f;
}

=head2 $f = as_future_cb { CODE }

A futher shortcut to C<as_future>, where the code is passed two callback
functions for C<done> and C<fail> directly, avoiding boilerplate in the common
case for creating these closures capturing the future variable. In many cases
this can reduce the code block to a single line.

 $w = CODE->( $done_cb, $fail_cb )

=cut

sub as_future_cb(&)
{
   my ( $code ) = @_;

   &as_future( sub {
      my $f = shift;
      $code->( $f->done_cb, $f->fail_cb );
   });
}

=head1 EXAMPLES

=head2 Wrapping watcher-style C<AnyEvent> functions

The C<as_future_cb> utility provides an excellent wrapper to take the common
style of C<AnyEvent> function that returns a watcher object and takes a
completion callback, and turn it into a C<Future> that can be used or combined
with other C<Future>-based code. For example, the L<AnyEvent::HTTP> function
called C<http_get> performs in this style.

 use AnyEvent::Future qw( as_future_cb );
 use AnyEvent::HTTP qw( http_get );

 my $url = ...;

 my $f = as_future_cb {
    my ( $done_cb ) = @_;

    http_get $url, $done_cb;
 };

This could of course be easily wrapped by a convenient function to return
futures:

 sub http_get_future
 {
    my @args = @_;

    as_future_cb {
       my ( $done_cb ) = @_;

       http_get @args, $done_cb;
    }
 }

=head2 Using C<Future>s as enhanced C<CondVar>s

While at first glance it may appear that a C<Future> instance is much like an
L<AnyEvent::CondVar>, the greater set of convergence methods (such as
C<needs_all> or C<needs_any>), and the various utility functions (in
L<Future::Utils>) makes it possible to write the same style of code in a more
concise or powerful way.

For example, rather than using the C<CondVar> C<begin> and C<end> methods, a
set of C<CondVar>-returning functions can be converted into C<Futures>,
combined using C<needs_all>, and converted back to a C<CondVar> again:

 my $cv = Future->needs_all(
    Future::AnyEvent->from_cv( FUNC1() ),
    Future::AnyEvent->from_cv( FUNC2() ),
    ...
 )->as_cv;

 my @results = $cv->recv;

This would become yet more useful if, instead of functions that return
C<CondVars>, we were operating on functions that return C<Future>s directly.
Because the C<needs_all> will cancel any still-pending futures the moment one
of them failed, we get a nice neat cancellation of outstanding work if one of
them fails, in a way that would be much harder without the C<Future>s. For
example, using the C<http_get_future> function from above:

 my $cv = Future->needs_all(
    http_get_future( "http://url-1" ),
    http_get_future( "http://url-2" ),
    http_get_future( "https://url-third/secret" ),
 )->as_cv;

 my @results = $cv->recv;

In this case, the moment any of the HTTP GET functions fails, the ones that
are still pending are all cancelled (by dropping their cancellation watcher
object) and the overall C<recv> call throws an exception.

Of course, there is no need to convert the outermost C<Future> into a
C<CondVar>; the full set of waiting semantics are implemented on these
instances, so instead you may simply call C<get> on it to achieve the same
effect:

 my $f = Future->needs_all(
    http_get_future( "http://url-1" ),
    ...
 );

 my @results = $f->get;

This has other side advantages, such as the list-valued semantics of failures
that can provide additional information besides just the error message, and
propagation of cancellation requests.

=cut

=head1 TODO

=over 4

=item *

Consider whether or not it would be considered "evil" to inject a new method
into L<AnyEvent::CondVar>; namely by doing

 sub AnyEvent::CondVar::as_future { AnyEvent::Future->from_cv( shift ) }

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
