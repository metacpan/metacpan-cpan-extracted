=head1 NAME

Coro::Handle - non-blocking I/O with a blocking interface.

=head1 SYNOPSIS

 use Coro::Handle;

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements IO-handles in a coroutine-compatible way, that is,
other coroutines can run while reads or writes block on the handle.

It does so by using L<AnyEvent|AnyEvent> to wait for readable/writable
data, allowing other coroutines to run while one coroutine waits for I/O.

Coro::Handle does NOT inherit from IO::Handle but uses tied objects.

If at all possible, you should I<always> prefer method calls on the handle object over invoking
tied methods, i.e.:

   $fh->print ($str);         # NOT print $fh $str;
   my $line = $fh->readline;  # NOT my $line = <$fh>;

The reason is that perl recurses within the interpreter when invoking tie
magic, forcing the (temporary) allocation of a (big) stack. If you have
lots of socket connections and they happen to wait in e.g. <$fh>, then
they would all have a costly C coroutine associated with them.

=over 4

=cut

package Coro::Handle;

use common::sense;

use Carp ();
use Errno qw(EAGAIN EINTR EINPROGRESS);

use AnyEvent::Util qw(WSAEWOULDBLOCK WSAEINPROGRESS);
use AnyEvent::Socket ();

use base 'Exporter';

our $VERSION = 6.513;
our @EXPORT = qw(unblock);

=item $fh = new_from_fh Coro::Handle $fhandle [, arg => value...]

Create a new non-blocking io-handle using the given
perl-filehandle. Returns C<undef> if no filehandle is given. The only
other supported argument is "timeout", which sets a timeout for each
operation.

=cut

sub new_from_fh {
   my $class = shift;
   my $fh = shift or return;
   my $self = do { local *Coro::Handle };

   tie *$self, 'Coro::Handle::FH', fh => $fh, @_;

   bless \$self, ref $class ? ref $class : $class
}

=item $fh = unblock $fh

This is a convenience function that just calls C<new_from_fh> on the
given filehandle. Use it to replace a normal perl filehandle by a
non-(coroutine-)blocking equivalent.

=cut

sub unblock($) {
   new_from_fh Coro::Handle $_[0]
}

=item $fh->writable, $fh->readable

Wait until the filehandle is readable or writable (and return true) or
until an error condition happens (and return false).

=cut

sub readable	{ Coro::Handle::FH::readable (tied *${$_[0]}) }
sub writable	{ Coro::Handle::FH::writable (tied *${$_[0]}) }

=item $fh->readline ([$terminator])

Similar to the builtin of the same name, but allows you to specify the
input record separator in a coroutine-safe manner (i.e. not using a global
variable). Paragraph mode is not supported, use "\n\n" to achieve the same
effect.

=cut

sub readline	{ tied(*${+shift})->READLINE (@_) }

=item $fh->autoflush ([...])

Always returns true, arguments are being ignored (exists for compatibility
only). Might change in the future.

=cut

sub autoflush	{ !0 }

=item $fh->fileno, $fh->close, $fh->read, $fh->sysread, $fh->syswrite, $fh->print, $fh->printf

Work like their function equivalents (except read, which works like
sysread. You should not use the read function with Coro::Handle's, it will
work but it's not efficient).

=cut

sub read	{ Coro::Handle::FH::READ   (tied *${$_[0]}, $_[1], $_[2], $_[3]) }
sub sysread	{ Coro::Handle::FH::READ   (tied *${$_[0]}, $_[1], $_[2], $_[3]) }
sub syswrite	{ Coro::Handle::FH::WRITE  (tied *${$_[0]}, $_[1], $_[2], $_[3]) }
sub print	{ Coro::Handle::FH::WRITE  (tied *${+shift}, join "", @_) }
sub printf	{ Coro::Handle::FH::PRINTF (tied *${+shift}, @_) }
sub fileno	{ Coro::Handle::FH::FILENO (tied *${$_[0]}) }
sub close	{ Coro::Handle::FH::CLOSE  (tied *${$_[0]}) }
sub blocking    { !0 } # this handler always blocks the caller

sub partial     {
   my $obj = tied *${$_[0]};

   my $retval = $obj->[8];
   $obj->[8] = $_[1] if @_ > 1;
   $retval
}

=item connect, listen, bind, getsockopt, setsockopt,
send, recv, peername, sockname, shutdown, peerport, peerhost

Do the same thing as the perl builtins or IO::Socket methods (but return
true on EINPROGRESS). Remember that these must be method calls.

=cut

sub connect	{ connect     tied(*${$_[0]})->[0], $_[1] or $! == EINPROGRESS or $! == EAGAIN or $! == WSAEWOULDBLOCK }
sub bind	{ bind        tied(*${$_[0]})->[0], $_[1] }
sub listen	{ listen      tied(*${$_[0]})->[0], $_[1] }
sub getsockopt	{ getsockopt  tied(*${$_[0]})->[0], $_[1], $_[2] }
sub setsockopt	{ setsockopt  tied(*${$_[0]})->[0], $_[1], $_[2], $_[3] }
sub send	{ send        tied(*${$_[0]})->[0], $_[1], $_[2], @_ > 2 ? $_[3] : () }
sub recv	{ recv        tied(*${$_[0]})->[0], $_[1], $_[2], @_ > 2 ? $_[3] : () }
sub sockname	{ getsockname tied(*${$_[0]})->[0] }
sub peername	{ getpeername tied(*${$_[0]})->[0] }
sub shutdown	{ shutdown    tied(*${$_[0]})->[0], $_[1] }

=item peeraddr, peerhost, peerport

Return the peer host (as numericla IP address) and peer port (as integer).

=cut

sub peeraddr {
   (AnyEvent::Socket::unpack_sockaddr getpeername tied(*${$_[0]})->[0])[1]
}

sub peerport {
   (AnyEvent::Socket::unpack_sockaddr getpeername tied(*${$_[0]})->[0])[0]
}

sub peerhost {
   AnyEvent::Socket::format_address &peeraddr
}

=item ($fh, $peername) = $listen_fh->accept

In scalar context, returns the newly accepted socket (or undef) and in
list context return the ($fh, $peername) pair (or nothing).

=cut

sub accept {
   my ($peername, $fh);
   while () {
      $peername = accept $fh, tied(*${$_[0]})->[0]
         and return wantarray 
                    ? ($_[0]->new_from_fh($fh), $peername)
                    :  $_[0]->new_from_fh($fh);

      return if $! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK;

      $_[0]->readable or return;
   }
}

=item $fh->timeout ([...])

The optional argument sets the new timeout (in seconds) for this
handle. Returns the current (new) value.

C<0> is a valid timeout, use C<undef> to disable the timeout.

=cut

sub timeout {
   my $self = tied *${$_[0]};
   if (@_ > 1) {
      $self->[2] = $_[1];
      $self->[5]->timeout ($_[1]) if $self->[5];
      $self->[6]->timeout ($_[1]) if $self->[6];
   }
   $self->[2]
}

=item $fh->fh

Returns the "real" (non-blocking) filehandle. Use this if you want to
do operations on the file handle you cannot do using the Coro::Handle
interface.

=item $fh->rbuf

Returns the current contents of the read buffer (this is an lvalue, so you
can change the read buffer if you like).

You can use this function to implement your own optimized reader when neither
readline nor sysread are viable candidates, like this:

  # first get the _real_ non-blocking filehandle
  # and fetch a reference to the read buffer
  my $nb_fh = $fh->fh;
  my $buf = \$fh->rbuf;

  while () {
     # now use buffer contents, modifying
     # if necessary to reflect the removed data

     last if $$buf ne ""; # we have leftover data

     # read another buffer full of data
     $fh->readable or die "end of file";
     sysread $nb_fh, $$buf, 8192;
  }

=cut

sub fh {
   (tied *${$_[0]})->[0];
}

sub rbuf : lvalue {
   (tied *${$_[0]})->[3];
}

sub DESTROY {
   # nop
}

our $AUTOLOAD;

sub AUTOLOAD {
   my $self = tied *${$_[0]};

   (my $func = $AUTOLOAD) =~ s/^(.*):://;

   my $forward = UNIVERSAL::can $self->[7], $func;

   $forward or
      die "Can't locate object method \"$func\" via package \"" . (ref $self) . "\"";

   goto &$forward;
}

package Coro::Handle::FH;

use common::sense;

use Carp 'croak';
use Errno qw(EAGAIN EINTR);

use AnyEvent::Util qw(WSAEWOULDBLOCK);

use Coro::AnyEvent;

# formerly a hash, but we are speed-critical, so try
# to be faster even if it hurts.
#
# 0 FH
# 1 desc
# 2 timeout
# 3 rb
# 4 wb # unused
# 5 read watcher, if Coro::Event|EV used
# 6 write watcher, if Coro::Event|EV used
# 7 forward class
# 8 blocking

sub TIEHANDLE {
   my ($class, %arg) = @_;

   my $self = bless [], $class;
   $self->[0] = $arg{fh};
   $self->[1] = $arg{desc};
   $self->[2] = $arg{timeout};
   $self->[3] = "";
   $self->[4] = "";
   $self->[5] = undef; # work around changes in 5.20, which requires initialisation
   $self->[6] = undef; # work around changes in 5.20, which requires initialisation
   $self->[7] = $arg{forward_class};
   $self->[8] = $arg{partial};

   AnyEvent::Util::fh_nonblocking $self->[0], 1;

   $self
}

sub cleanup {
   # gets overriden for Coro::Event
   @{$_[0]} = ();
}

sub OPEN {
   &cleanup;
   my $self = shift;
   my $r = @_ == 2 ? open $self->[0], $_[0], $_[1]
                   : open $self->[0], $_[0], $_[1], $_[2];

   if ($r) {
      fcntl $self->[0], &Fcntl::F_SETFL, &Fcntl::O_NONBLOCK
         or croak "fcntl(O_NONBLOCK): $!";
   }

   $r
}

sub PRINT {
   WRITE (shift, join "", @_)
}

sub PRINTF {
   WRITE (shift, sprintf shift, @_)
}

sub GETC {
   my $buf;
   READ ($_[0], $buf, 1);
   $buf
}

sub BINMODE {
   binmode $_[0][0];
}

sub TELL {
   Carp::croak "Coro::Handle's don't support tell()";
}

sub SEEK {
   Carp::croak "Coro::Handle's don't support seek()";
}

sub EOF {
   Carp::croak "Coro::Handle's don't support eof()";
}

sub CLOSE {
   my $fh = $_[0][0];
   &cleanup;
   close $fh
}

sub DESTROY {
   &cleanup;
}

sub FILENO {
   fileno $_[0][0]
}

# seems to be called for stringification (how weird), at least
# when DumpValue::dumpValue is used to print this.
sub FETCH {
   "$_[0]<$_[0][1]>"
}

sub _readable_anyevent {
   my $cb = Coro::rouse_cb;

   my $w = AE::io $_[0][0], 0, sub { $cb->(1) };
   my $t = (defined $_[0][2]) && AE::timer $_[0][2], 0, sub { $cb->(0) };

   Coro::rouse_wait
}

sub _writable_anyevent {
   my $cb = Coro::rouse_cb;

   my $w = AE::io $_[0][0], 1, sub { $cb->(1) };
   my $t = (defined $_[0][2]) && AE::timer $_[0][2], 0, sub { $cb->(0) };

   Coro::rouse_wait
}

sub _readable_coro {
   ($_[0][5] ||= "Coro::Event"->io (
      fd      => $_[0][0],
      desc    => "fh $_[0][1] read watcher",
      timeout => $_[0][2],
      poll    => &Event::Watcher::R + &Event::Watcher::E + &Event::Watcher::T,
   ))->next->[4] & &Event::Watcher::R
}

sub _writable_coro {
   ($_[0][6] ||= "Coro::Event"->io (
      fd      => $_[0][0],
      desc    => "fh $_[0][1] write watcher",
      timeout => $_[0][2],
      poll    => &Event::Watcher::W + &Event::Watcher::E + &Event::Watcher::T,
   ))->next->[4] & &Event::Watcher::W
}

#sub _readable_ev {
#   &EV::READ  == Coro::EV::timed_io_once (fileno $_[0][0], &EV::READ , $_[0][2])
#}
#
#sub _writable_ev {
#   &EV::WRITE == Coro::EV::timed_io_once (fileno $_[0][0], &EV::WRITE, $_[0][2])
#}

# decide on event model at runtime
for my $rw (qw(readable writable)) {
   *$rw = sub {
      AnyEvent::detect;
      if ($AnyEvent::MODEL eq "AnyEvent::Impl::Event" and eval { require Coro::Event }) {
         *$rw = \&{"_$rw\_coro"};
         *cleanup = sub {
            eval {
               $_[0][5]->cancel if $_[0][5];
               $_[0][6]->cancel if $_[0][6];
            };
            @{$_[0]} = ();
         };

      } elsif ($AnyEvent::MODEL eq "AnyEvent::Impl::EV" and eval { require Coro::EV }) {
         *$rw = \&{"Coro::EV::_$rw\_ev"};
         return &$rw; # Coro 5.0+ doesn't support goto &SLF, and this line is executed once only

      } else {
         *$rw = \&{"_$rw\_anyevent"};
      }
      goto &$rw
   };
};

sub WRITE {
   my $len = defined $_[2] ? $_[2] : length $_[1];
   my $ofs = $_[3];
   my $res;

   while () {
      my $r = syswrite ($_[0][0], $_[1], $len, $ofs);
      if (defined $r) {
         $len -= $r;
         $ofs += $r;
         $res += $r;
         last unless $len;
      } elsif ($! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
         last;
      }
      last unless &writable;
   }

   $res
}

sub READ {
   my $len = $_[2];
   my $ofs = $_[3];
   my $res;

   # first deplete the read buffer
   if (length $_[0][3]) {
      my $l = length $_[0][3];
      if ($l <= $len) {
         substr ($_[1], $ofs) = $_[0][3]; $_[0][3] = "";
         $len -= $l;
         $ofs += $l;
         $res += $l;
         return $res unless $len;
      } else {
         substr ($_[1], $ofs) = substr ($_[0][3], 0, $len);
         substr ($_[0][3], 0, $len) = "";
         return $len;
      }
   }

   while() {
      my $r = sysread $_[0][0], $_[1], $len, $ofs;
      if (defined $r) {
         $len -= $r;
         $ofs += $r;
         $res += $r;
         last unless $len && $r;
      } elsif ($! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
         last;
      }
      last if $_[0][8] || !&readable;
   }

   $res
}

sub READLINE {
   my $irs = @_ > 1 ? $_[1] : $/;
   my ($ofs, $len, $pos);
   my $bufsize = 1020;

   while () {
      if (length $irs) {
         $pos = index $_[0][3], $irs, $ofs < 0 ? 0 : $ofs;

         return substr $_[0][3], 0, $pos + length $irs, ""
            if $pos >= 0;

         $ofs = (length $_[0][3]) - (length $irs);
      } elsif (defined $irs) {
         $pos = index $_[0][3], "\n\n", $ofs < 1 ? 1 : $ofs;

         if ($pos >= 0) {
            my $res = substr $_[0][3], 0, $pos + 2, "";
            $res =~ s/\A\n+//;
            return $res;
         }

         $ofs = (length $_[0][3]) - 1;
      }

      $len = $bufsize - length $_[0][3];
      $len = $bufsize *= 2 if $len < $bufsize * 0.5;
      $len = sysread $_[0][0], $_[0][3], $len, length $_[0][3];

      unless ($len) {
         if (defined $len) {
            # EOF
            return undef unless length $_[0][3];

            $_[0][3] =~ s/\A\n+//
               if ! length $irs && defined $irs;

            return delete $_[0][3];
         } elsif (($! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) || !&readable) {
            return length $_[0][3] ? delete $_[0][3] : undef;
         }
      }
   }
}

1;

=back

=head1 BUGS

 - Perl's IO-Handle model is THE bug.

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

