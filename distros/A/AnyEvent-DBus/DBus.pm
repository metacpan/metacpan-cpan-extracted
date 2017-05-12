=head1 NAME

AnyEvent::DBus - adapt Net::DBus to AnyEvent

=head1 SYNOPSIS

   use AnyEvent::DBus;

   # now use the Net::DBus API, preferably the non-blocking variants:

   use Net::DBus::Annotation qw(:call);

   $bus->get_object (...)
       ->Method (dbus_call_async, $arg1, ...)
       ->set_notify (sub {
          my @data = $_[0]->get_result
          ...
       });

   $bus->get_connection->send (...);

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

Loading this module will install the necessary magic to seamlessly
integrate L<Net::DBus> into L<AnyEvent>. It does this by quite brutally
hacking L<Net::DBus::Reactor> so that all dbus connections created after
loading this module will automatically be managed by this module.

Note that a) a lot inside Net::DBus is still blocking b) if you call a
method that blocks, you again block your process (basically anything
but calls to the Net::DBus::Binding::Connection objects block, but see
Net::DBus::Annoation, specifically dbus_call_async) c) the underlying
libdbus is often blocking itself, even with infinite timeouts and d) this
module only implements the minimum API required to make Net::DBus work -
Net::DBus unfortunately has no nice hooking API.

However, unlike L<Net::DBus::Reactor>, this module should be fully
non-blocking as long as you only use non-blocking APIs (Net::DBus::Reactor
blocks on writes). It should also be faster, but Net::DBus is such a
morass so unneeded method calls that speed won't matter much...

=head2 EXAMPLE

Here is a simple example. Both work with AnyEvent::DBus and do the same
thing, but only the second is actually non-blocking.

Example 1: list registered named, blocking version.

   use AnyEvent::DBus;

   my $conn = Net::DBus->find;
   my $bus  = $conn->get_bus_object;

   for my $name (@{ $bus->ListNames }) {
      print "  $name\n";
   }

Example 1: list registered named, somewhat non-blocking version.

   use AnyEvent;
   use AnyEvent::DBus;
   use Net::DBus::Annotation qw(:call);

   my $conn = Net::DBus->find; # always blocks :/
   my $bus  = $conn->get_bus_object;

   my $quit = AE::cv;

   # the trick here is to prepend dbus_call_async to any method
   # arguments and then to call the set_notify method on the
   # returned Net::DBus::AsyncReply object

   $bus->ListNames (dbus_call_async)->set_notify (sub {
      for my $name (@{ $_[0]->get_result }) {
         print "  $name\n";
      }
      $quit->send;
   });

   $quit->recv;

=cut

package AnyEvent::DBus;

use common::sense;

use AnyEvent ();
use Net::DBus ();
use Net::DBus::Binding::Watch ();

our $VERSION = '0.31';

# yup, Net::DBus checks by using exists on %INC...
$INC{'Net/DBus/Reactor.pm'} = undef;

# claim we are the main reactor mainloop
*Net::DBus::Reactor::main = sub { __PACKAGE__ };

our $I = 0;
our %O; # watchers and timers, unfortunately, dbus only supports attaching integers...

sub watch_off {
   delete $O{$_[1]->get_data};
}

sub io_toggle {
   my ($con, $w) = @_;

   my $id = $w->get_data;
   my $f  = $w->get_flags;
   my $fd = $w->get_fileno;
   my $on = $w->is_enabled;

   $f & Net::DBus::Binding::Watch::READABLE ()
      and
         $O{$id}[0] = $on && AE::io $fd, 0, sub {
            $w->handle (Net::DBus::Binding::Watch::READABLE ());
            $con->dispatch;
         };

   $f & Net::DBus::Binding::Watch::WRITABLE ()
      and
         $O{$id}[1] = $on && AE::io $fd, 1, sub {
            $w->handle (Net::DBus::Binding::Watch::WRITABLE ());
            $con->dispatch;
         };
}

sub io_on {
   my ($con, $w) = @_;

   my $id = ++$I;
   $w->set_data ($id);

   &io_toggle;
}

sub timeout_toggle {
   my ($con, $w) = @_;

   my $id = $w->get_data;
   my $i  = $w->get_interval * 0.001;

   $O{$id} = $w->is_enabled && AE::timer $i, $i, sub {
      $w->handle;
      $con->dispatch;
   };
}

sub timeout_on {
   my ($con, $w) = @_;
   my $id = ++$I;
   $w->set_data ($id);
   
   &timeout_toggle;
}

sub manage {
   my (undef, $con) = @_;

   $con->set_watch_callbacks (\&io_on, \&watch_off, \&io_toggle);
#      if $con->can ("set_watch_callbacks");

   $con->set_timeout_callbacks (\&timeout_on, \&watch_off, \&timeout_toggle);
#      if $con->can ("set_timeout_callbacks");

   $con->dispatch; # for good measure
}

=head1 SEE ALSO

L<AnyEvent>, L<Net::DBus>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1
