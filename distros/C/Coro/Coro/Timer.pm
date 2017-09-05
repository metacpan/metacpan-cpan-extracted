=head1 NAME

Coro::Timer - timers and timeouts, independent of any event loop

=head1 SYNOPSIS

 # This package is mostly obsoleted by Coro::AnyEvent.

 use Coro::Timer qw(timeout);
 # nothing exported by default

=head1 DESCRIPTION

This package has been mostly obsoleted by L<Coro::AnyEvent>, the only
really useful function left in here is C<timeout>.

=over 4

=cut

package Coro::Timer;

use common::sense;

use Carp ();
use base Exporter::;

use Coro ();
use Coro::AnyEvent ();

our $VERSION = 6.514;
our @EXPORT_OK = qw(timeout sleep);

# compatibility with older programs
*sleep = \&Coro::AnyEvent::sleep;

=item $flag = timeout $seconds

This function will wake up the current coroutine after $seconds seconds
and sets $flag to true (it is false initially).  If $flag goes out
of scope earlier then nothing happens.

This is used by Coro itself to implement the C<timed_down>, C<timed_wait>
etc. primitives. It is used like this:

   sub timed_wait {
      my $timeout = Coro::Timer::timeout 60;

      while (condition false) {
         Coro::schedule; # wait until woken up or timeout
         return 0 if $timeout; # timed out
      }

      return 1; # condition satisfied
   }

=cut

sub timeout($) {
   my $current = $Coro::current;
   my $timeout;

   bless [
      \$timeout,
      (AE::timer $_[0], 0, sub {
         $timeout = 1;
         $current->ready;
      }),
   ], "Coro::Timer::Timeout";
}

package Coro::Timer::Timeout;

sub bool { ${ $_[0][0] } }

use overload 'bool' => \&bool, '0+' => \&bool;

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

