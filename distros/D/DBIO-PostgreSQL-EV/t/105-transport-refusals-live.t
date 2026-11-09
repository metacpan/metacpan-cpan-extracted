use strict;
use warnings;
use Test::More;

# LIVE: a refusal of the transport's own names the caller's place also where
# the real EV loop reached it (karr k88, maintainer's decision 2026-10-16),
# against a real PostgreSQL. The offline half, t/103-transport-refusals.t,
# holds every refusal against a fake EV::Pg, whose callbacks run from the
# test's own calls; here EV::Pg runs them from inside EV::run, from XS.
#
#   1. A channel name the rule refuses: core subscribes it once the real
#      listen connection is up, in EV::Pg's on_connect, inside the EV loop a
#      ->get runs. The listen Future fails with core's words around the
#      refusal, and the place inside them is the line of that ->get -- not
#      DBIO's Future, not core's listen machinery, not this library.
#   2. A statement issued in a callback of the caller's that the loop runs --
#      a then on a statement that came back from the server -- and refused
#      there: the place is the line in that callback.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use DBIO::Storage::Async ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

LiveServer->require_server;

alarm 120;

sub refused {
  my ($err, $line, $name, %opt) = @_;
  if ($opt{wrapped}) {
    ok defined $err && !ref $err, "$name: core's failure text, around the refusal";
  }
  else {
    isa_ok $err, 'DBIO::Exception', "$name: the refusal";
  }
  my $text = defined $err ? "$err" : '';
  like $text, qr/ at \Q${\ __FILE__}\E line $line\n\z/,
    "$name: ... naming the caller's place: this file, line $line";
  unlike $text, qr/\.pm\b/, "$name: ... and no library file";
}

my $h     = DBIO::PostgreSQL::EV::TestHarness->new;
my $async = $h->async;

SKIP: {
  skip 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)', 4
    unless DBIO::Storage::Async->can('listen_alive');

  $async->on_listen_error(sub { });
  my $listen = $async->listen(('x' x 64) => sub { });
  my $line = __LINE__; my $ok = eval { $listen->get; 1 };
  my $err = $ok ? undef : $@;
  ok !$ok, 'listen on a channel name the rule refuses fails, inside the EV loop';
  like $err // '', qr/LISTEN on channel 'x{64}' failed: \S+ LISTEN channel name 'x{64}' is 64 bytes long; /,
    q{... in core's words around the refusal};
  refused($err, $line, 'the refusal reached in a callback of the transport', wrapped => 1);
}

{
  my $line;
  my $f = $async->_query_async('SELECT 1', [])->then(sub {
    $line = __LINE__; $async->_query_async(q{SELECT $1, ?}, [ 1 ]);
  });
  my $ok  = eval { $f->get; 1 };
  my $err = $ok ? undef : $@;
  ok !$ok, 'a statement mixing $N and ?, issued in a then the EV loop runs: refused';
  like "$err", qr/mixes \$N and \?/, '... with the refusal';
  refused($err, $line, 'the refusal reached in a callback of the caller');
}

$h->disconnect;

done_testing;
