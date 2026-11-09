use strict;
use warnings;
use Test::More;

# LIVE: the ev transport quotes as its connection says (karr k88, from
# dbio-postgresql k121, maintainer's decision 2026-10-16), against a real
# PostgreSQL. The offline half, t/102-sql-maker-quoting.t, compares the SQL of
# the two makers; this file asks the SERVER what the transport's SQL means.
#
# The table is created lower case. A source named in upper case finds it only
# when the name goes out unquoted -- PostgreSQL folds an unquoted name to lower
# case, and takes a quoted one as written. So:
#
#   - nothing said: the transport quotes, "K88_..." names no table, the
#     statement fails with the server's "does not exist" -- as the sync
#     storage's statement does;
#   - quote_names => 0: the transport writes the names unquoted, the server
#     folds them, the row comes back. Until karr k88 the transport quoted
#     here too and the statement failed, while the sync storage's ran.
#
# The second case needs a DBIO::PostgreSQL whose sync storage leaves quoting
# off (dbio-postgresql k121, bf640c4): on an older one the sync maker quotes,
# and so -- following it -- does the transport; skipped there, with the reason.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;

alarm 120;

my $TABLE = "k88_quote_$$";
my $dbh   = LiveServer->control_dbh(application_name => "${TABLE}_control");
$dbh->do("CREATE TABLE $TABLE (col integer)");
$dbh->do("INSERT INTO $TABLE (col) VALUES (42)");

my ($UPPER_TABLE, $UPPER_COL) = (uc $TABLE, 'COL');

sub select_upper {
  my ($h) = @_;
  my $f = GuardedWait->until_ready(
    $h->async->select_async($UPPER_TABLE, [ $UPPER_COL ], {}),
    15, 'the select over the transport did not settle in 15s',
  );
  return $f->is_done ? [ done => [ $f->get ] ] : [ failed => scalar $f->failure ];
}

{
  my $h = DBIO::PostgreSQL::EV::TestHarness->new;
  my $got = select_upper($h);
  is $got->[0], 'failed', 'nothing said: the transport quotes the upper-case names';
  like "$got->[1]", qr/does not exist/, '... and the server finds no such relation';
  $h->disconnect;
}

SKIP: {
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { quote_names => 0 });
  skip 'the installed DBIO::PostgreSQL quotes with quote_names => 0 -- needs dbio-postgresql k121 (bf640c4)', 3
    if $h->sync_storage->sql_maker->_quote_chars;

  my $got = select_upper($h);
  is $got->[0], 'done', 'quote_names => 0: the transport writes the names unquoted'
    or diag "it failed: $got->[1]";
  is_deeply $got->[1], [ [ 42 ] ], '... and the server folds them onto the table';

  my $sync = $h->sync_storage->dbh_do(sub {
    my (undef, $sync_dbh) = @_;
    my ($sql) = $h->sync_storage->sql_maker->select($UPPER_TABLE, [ $UPPER_COL ], {});
    $sync_dbh->selectall_arrayref($sql);
  });
  is_deeply $sync, [ [ 42 ] ], '... as the sync storage of the same connection does';
  $h->disconnect;
}

$dbh->do("DROP TABLE $TABLE");

done_testing;
