use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test;

# SQLite grew INSERT ... RETURNING in libsqlite 3.35 (2021-03-12). Declaring the
# insert_returning capability is what lets DBIO::Storage::DBI::insert pick up
# autoincrement and retrieve_on_insert values straight off the INSERT instead of
# paying for a last_insert_id() plus a follow-up SELECT. Both halves matter, so
# both are pinned here: the version gate has to answer correctly for whatever
# libsqlite we are linked against, and the two code paths have to agree on the
# resulting row -- one statement with RETURNING, more than one without.

my $schema  = DBIO::SQLite::Test->init_schema( no_populate => 1 );
my $storage = $schema->storage;

my $server_info = $storage->_server_info;
my $server_version = $server_info->{normalized_dbms_version};
my $server_has_returning = ( $server_version >= '3.035' ) ? 1 : 0;

note "libsqlite $server_info->{dbms_version} (normalized $server_version)";

is (
  $storage->_use_insert_returning,
  $server_has_returning,
  'insert_returning capability matches the linked libsqlite (RETURNING needs 3.35)',
);

ok (
  ! $storage->_use_insert_returning_bound,
  'insert_returning_bound stays undeclared - SQLite hands the values back as an '
. 'ordinary result set, not through RETURNING ... INTO binds',
);

my $rs = $schema->resultset('Artist');

# rank carries a DB-side DEFAULT of 13. Asking for it back on insert exercises
# the retrieve_on_insert half of the retrieval; the autoinc PK exercises the other.
$rs->result_source->add_columns( '+rank' => { retrieve_on_insert => 1 } );

sub create_traced_artist {
  my $name = shift;

  my @sql;
  $storage->debugcb( sub { push @sql, $_[1] } );
  $storage->debug(1);

  my $artist = eval { $rs->create({ name => $name }) };
  my $err = $@;

  $storage->debug(0);
  $storage->debugcb(undef);

  die $err if $err;

  return ($artist, \@sql);
}

SKIP: {
  skip "libsqlite $server_info->{dbms_version} has no RETURNING support (needs 3.35)", 4
    unless $server_has_returning;

  $storage->_use_insert_returning(1);

  my ($artist, $sql) = create_traced_artist('with-returning');

  is (scalar @$sql, 1, 'insert with RETURNING is a single round-trip')
    or diag explain $sql;
  like ($sql->[0], qr/^INSERT INTO .+\bRETURNING\b/, 'RETURNING clause emitted on the INSERT');
  ok (defined $artist->artistid, 'autoincrement PK came back from RETURNING');
  is ($artist->rank, 13, 'retrieve_on_insert column came back from RETURNING');
}

# The last_insert_id + follow-up SELECT fallback must keep working: it is forced
# here, and it is the only path available on libsqlite older than 3.35.
{
  $storage->_use_insert_returning(0);

  my ($artist, $sql) = create_traced_artist('without-returning');

  cmp_ok (scalar @$sql, '>', 1, 'insert without RETURNING needs a follow-up query')
    or diag explain $sql;
  unlike (join("\n", @$sql), qr/\bRETURNING\b/, 'no RETURNING clause while the capability is off');
  ok (defined $artist->artistid, 'autoincrement PK came back via last_insert_id');
  is ($artist->rank, 13, 'retrieve_on_insert column came back via the follow-up SELECT');
}

done_testing;
