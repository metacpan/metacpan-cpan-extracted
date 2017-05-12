=head1 NAME

Coro::AIO - truly asynchronous file and directory I/O

=head1 SYNOPSIS

   use Coro::AIO;

   # can now use any of the aio requests your IO::AIO module supports.

   # read 1MB of /etc/passwd, without blocking other coroutines
   my $fh = aio_open "/etc/passwd", O_RDONLY, 0
      or die "/etc/passwd: $!";
   aio_read $fh, 0, 1_000_000, my $buf, 0
      or die "aio_read: $!";
   aio_close $fh;

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements a thin wrapper around L<IO::AIO>. All of
the functions that expect a callback are being wrapped by this module.

The API is exactly the same as that of the corresponding IO::AIO
routines, except that you have to specify I<all> arguments, even the
ones optional in IO::AIO, I<except> the callback argument. Instead of
calling a callback, the routines return the values normally passed to the
callback. Everything else, including C<$!> and perls stat cache, are set
as expected after these functions return.

You can mix calls to C<IO::AIO> functions with calls to this module. You
I<must not>, however, call these routines from within IO::AIO callbacks,
as this causes a deadlock. Start a coro inside the callback instead.

This module also loads L<AnyEvent::AIO> to integrate into the event loop
in use, so please refer to its (and L<AnyEvent>'s) documentation on how it
selects an appropriate event module.

All other functions exported by default by IO::AIO (e.g. C<aioreq_pri>)
will be exported by default by Coro::AIO, too.

Functions that can be optionally imported from IO::AIO can be imported
from Coro::AIO or can be called directly, e.g. C<Coro::AIO::nreqs>.

You cannot specify priorities with C<aioreq_pri> if your coroutine has a
non-zero priority, as this module overwrites the request priority with the
current coroutine priority in that case.

For your convenience, here are the changed function signatures for most
of the requests, for documentation of these functions please have a look
at L<IO::AIO|the IO::AIO manual>. Note that requests added by newer
versions of L<IO::AIO> will be automatically wrapped as well.

=over 4

=cut

package Coro::AIO;

use common::sense;

use IO::AIO 3.1 ();
use AnyEvent::AIO ();

use Coro ();
use Coro::AnyEvent ();

use base Exporter::;

our $VERSION = 6.511;

our @EXPORT    = (@IO::AIO::EXPORT, qw(aio_wait));
our @EXPORT_OK = @IO::AIO::EXPORT_OK;
our $AUTOLOAD;

{
   my @reqs = @IO::AIO::AIO_REQ ? @IO::AIO::AIO_REQ : @IO::AIO::EXPORT;
   my %reqs = map +($_ => 1), @reqs;

   eval
      join "",
         map "sub $_(" . (prototype "IO::AIO::$_") . ");",
            grep !$reqs{$_},
                @IO::AIO::EXPORT, @EXPORT_OK;

   for my $sub (@reqs) {
      push @EXPORT, $sub;

      my $iosub = "IO::AIO::$sub";
      my $proto = prototype $iosub;

      $proto =~ s/;//g; # we do not support optional arguments
      $proto =~ s/^(\$*)\$$/$1/ or die "$iosub($proto): unable to remove callback slot from prototype";

      _register "Coro::AIO::$sub", $proto, \&{$iosub};
   }

   _register "Coro::AIO::aio_wait", '$', \&IO::AIO::REQ::cb;
}

sub AUTOLOAD {
   (my $func = $AUTOLOAD) =~ s/^.*:://;
   *$AUTOLOAD = \&{"IO::AIO::$func"};
   goto &$AUTOLOAD;
}

=item @results = aio_wait $req

This is not originally an IO::AIO request: what it does is to wait for
C<$req> to finish and return the results. This is most useful with
C<aio_group> requests.

Is currently implemented by replacing the C<$req> callback (and is very
much like a wrapper around C<< $req->cb () >>).

=item $fh = aio_open $pathname, $flags, $mode

=item $status = aio_close $fh

=item $retval = aio_read  $fh,$offset,$length, $data,$dataoffset

=item $retval = aio_write $fh,$offset,$length, $data,$dataoffset

=item $retval = aio_sendfile $out_fh, $in_fh, $in_offset, $length

=item $retval = aio_readahead $fh,$offset,$length

=item $status = aio_stat $fh_or_path
      
=item $status = aio_lstat $fh

=item $status = aio_unlink $pathname

=item $status = aio_rmdir $pathname

=item $entries = aio_readdir $pathname

=item ($dirs, $nondirs) = aio_scandir $path, $maxreq

=item $status = aio_fsync $fh

=item $status = aio_fdatasync $fh

=item ... = aio_xxx ...

Any additional aio requests follow the same scheme: same parameters except
you must not specify a callback but instead get the callback arguments as
return values.

=back

=head1 SEE ALSO

L<Coro::Socket> and L<Coro::Handle> for non-blocking socket operation.

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

1
