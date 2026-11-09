use strict;
use warnings;
use Test::More;

# LIVE check: a process that ends with statements in flight is silent on STDERR.
#
# WHY: when a program exits, Perl frees its data in no fixed order and EV::Pg
# calls back every statement that was still waiting ("cancel"). By then the
# closure's connection, Future or storage can already be gone. A callback whose
# connection or Future no longer lives has nothing to deliver and must return
# quietly; before, the program printed "Use of uninitialized value $key" (the
# delivery mark of a connection that is undef) and "EV::Pg: exception in
# callback during cancel: Can't call method ... on an undefined value".
#
# Two shapes, each in a child perl whose STDERR is captured:
#   statement  a query (pg_sleep) in flight at the end, all handles dropped
#   reset      a borrow just ended, so DISCARD ALL of the reset is in flight,
#              beside statements in flight on the other connections

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

use File::Temp ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

alarm 120;

my $PREAMBLE = <<'PERL';
use strict; use warnings;
use DBIO::PostgreSQL::EV::TestHarness; use EV;
my $h = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 3 });
my $a = $h->async;
my @f;
PERL

my %CHILD = (
  statement => <<'PERL',
my $f = $a->_query_async('SELECT pg_sleep(30)', []);
{ my $t = EV::timer(0.3, 0, sub { EV::break() }); EV::run(); }
undef $f; undef $a; undef $h;
PERL
  reset => <<'PERL',
my $x = $a->_query_async('SELECT 1', []);
$x->on_done(sub { EV::break() });
push @f, $a->_query_async('SELECT pg_sleep(30)', []) for 1 .. 2;
EV::run();
undef @f; undef $x; undef $a; undef $h;
PERL
);

my @inc = map { "-I$_" } grep { !ref } @INC;

for my $case (qw( statement reset )) {
  my $file = File::Temp->new(SUFFIX => '.pl');
  print {$file} $PREAMBLE, $CHILD{$case};
  close $file;

  # one run is not enough: the order of the freeing varies
  my @err;
  for my $run (1 .. 5) {
    my $out = qx{"$^X" @{[ map { qq{"$_"} } @inc ]} "$file" 2>&1};
    push @err, $out if length $out;
  }
  is scalar(@err), 0, "$case: a process ending with statements in flight is silent on STDERR"
    or diag $err[0];
}

done_testing;
