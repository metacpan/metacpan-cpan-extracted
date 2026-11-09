use strict;
use warnings;
use Test::More;

# LIVE counterpart of t/109 for karr k98: a row whose values carry TAB, LF,
# CR, backslash and the characters \N arrives as exactly one row with
# identical values, and undef arrives as NULL.
#
# WHY live: only the server's COPY parser decides how the bytes of the stream
# split into rows and columns and what \N and \\N mean.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
LiveServer->require_server;
my %ci = LiveServer->conninfo;

alarm 120;

sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 20, "TIMEOUT awaiting $what\n");
}

sub run_raw {
  my ($storage, $sql) = @_;
  my $f = $storage->pool->acquire->then(sub {
    my $pg = shift;
    my $rf = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $rf->fail($err) : $rf->done;
    });
    return $rf;
  });
  return await_guarded($f, "run_raw: $sql")->get;
}

my $table = 'dbio_copy_in_escaping_live';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage, "CREATE TABLE $table (id int PRIMARY KEY, name text, role text, note text)");

my @sent = (
  [ 1, "Miles Davis\tJazz\nMallory\tAdmin", 'user', undef ],
  [ 2, "cr\rlf\n", "tab\t", "back\\slash" ],
  [ 3, '\\N', '\\', "it\\N" ],
  [ 4, '', undef, 'plain' ],
);

await_guarded(
  $storage->copy_in($table, [qw( id name role note )], sub {
    my ($put) = @_;
    $put->($_) for @sent;
  }),
  'copy_in of values with special bytes',
)->get;

my @rows = await_guarded(
  $storage->select_async($table, [qw( id name role note )], {}, { order_by => 'id' }),
  'select after copy_in',
)->get;

is scalar(@rows), scalar(@sent), 'one table row per row written';
is_deeply [ sort { $a->[0] <=> $b->[0] } @rows ], \@sent,
  'every value arrives as given: TAB, LF, CR, backslash, \\N and the empty string; undef is NULL';

run_raw($storage, "DROP TABLE IF EXISTS $table");
$storage->disconnect;

done_testing;
