=head1 NAME

Coro::BDB - truly asynchronous bdb access

=head1 SYNOPSIS

   use Coro::BDB;
   use BDB;

   # can now use any of the bdb requests

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

This module implements a thin wrapper around the L<BDB> module: Each BDB
request that could block and doesn't get passed a callback will normally
block all coroutines. after loading this module, this will no longer be
the case (it provides a suitable sync prepare callback).

It will also register an AnyEvent watcher as soon as AnyEvent chooses an
event loop.

The AnyEvent watcher can be disabled by executing C<undef
$Coro::BDB::WATCHER>. Please notify the author of when and why you think
this was necessary.

This module does not export anything (unlike L<Coro::AIO>), as BDB already
supports leaving out the callback. (Unfortunately, it ties a C context
to each coroutine executing such a callback, so in the future, it might
export more efficient wrappers).

=over 4

=cut

package Coro::BDB;

use common::sense;

use BDB ();
use AnyEvent::BDB ();

use Coro ();
use Coro::AnyEvent ();

use base Exporter::;

our $VERSION = 6.513;
our $WATCHER;

BDB::set_sync_prepare {
   my $cb = Coro::rouse_cb;
   (
      sub { $cb->($!) },
      sub { $! = Coro::rouse_wait },
   )
};

=back

=head1 SEE ALSO

L<BDB> of course.

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

1
