=head1 NAME

AnyEvent::BDB - truly asynchronous berkeley db access

=head1 SYNOPSIS

   use AnyEvent::BDB;
   use BDB;

   # can now use any of the requests your BDB module supports
   # as long as you use an event loop supported by AnyEvent.

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

Loading this module will install the necessary magic to seamlessly
integrate L<BDB> into L<AnyEvent>, i.e. you no longer need to concern
yourself with calling C<BDB::poll_cb> or any of that stuff (you still
can, but this module will do it in case you don't).

The AnyEvent watcher can be disabled by executing C<undef
$AnyEvent::BDB::WATCHER>. Please notify the author of when and why you
think this was necessary.

=cut

package AnyEvent::BDB;

use strict;
no warnings;

use AnyEvent ();
use BDB ();

use base Exporter::;

our $VERSION = '1.1';
our $WATCHER;

my $guard = AnyEvent::post_detect {
   $WATCHER = AnyEvent->io (fh => BDB::poll_fileno, poll => 'r', cb => \&BDB::poll_cb);
};
$WATCHER ||= $guard;

BDB::_on_next_submit \&AnyEvent::detect;

=head1 SEE ALSO

L<AnyEvent>, L<Coro::BDB> (for a more natural syntax).

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

