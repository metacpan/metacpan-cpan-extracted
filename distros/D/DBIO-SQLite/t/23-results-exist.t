use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;

# ADR 0037 -- the boolean-valued EXISTS query. results_exist and its two
# siblings ask the engine one yes/no question instead of counting rows or
# fetching one; core builds the inner subquery and hands it to the storage,
# which renders the whole statement. The capability is the driver's assertion
# that the rendering it ships is one this engine accepts, and core defaults it
# to 0 -- so a driver that never declares it makes results_exist throw rather
# than degrade silently to has_rows. This one never declared it.
#
# Both halves are pinned here: that the capability is declared, unconditionally
# (SQLite has no version left to gate on -- see the storage class), and that the
# statement it promises round-trips against the engine, standalone and as a
# correlated subquery. A declaration nobody executes would be exactly the
# unchecked claim the default-0 exists to prevent.

my $schema  = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );
my $storage = $schema->storage;
my $rs      = $schema->resultset('CD');

my $server_info = $storage->_server_info;
note "libsqlite $server_info->{dbms_version} "
   . "(normalized $server_info->{normalized_dbms_version})";

# ---------------------------------------------------------------- capability

is (
  $storage->_use_supports_exists_query,
  1,
  'supports_exists_query is declared -- core refuses results_exist outright '
. 'without it, and never falls back to has_rows on its own',
);

is (
  $storage->_determine_supports_supports_exists_query,
  1,
  'and it is declared unconditionally: CASE arrived in libsqlite 2.4.4 and '
. 'EXISTS in 3.1.0, both below the 3.6.0 DBD::SQLite needs before it will '
. 'build against an external libsqlite at all',
);

is (
  $storage->_supports_supports_exists_query,
  1,
  'and the declaration is in the _determine_ slot, so both query paths agree '
. '-- ADR 0037 section 2 names __PACKAGE__->_use_supports_exists_query(1) and '
. 'the rest of the family took it, which leaves get_dbms_capability answering '
. '0 on a storage that does support the query (karr k27)',
);

# ------------------------------------------------------------------ SQL shape

is (
  $storage->_exists_value_sql('(SELECT 42 FROM "cd")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "cd") THEN 1 ELSE 0 END',
  'the rendering seam is inherited, not overridden -- SQLite accepts a '
. 'FROM-less SELECT, so the statement needs none of the dummy tables Oracle, '
. 'DB2 and Firebird have to append',
);

# ------------------------------------------------------------- live round-trips

ok ($rs->results_exist, 'results_exist is true for a populated resultset');

ok (
  ! $rs->search({ cdid => -1 })->results_exist,
  'and false for one that matches nothing',
);

ok (
  $rs->results_exist({ title => { -like => '%Spoon%' } }),
  'a condition passed to results_exist reaches the inner subquery, bind and all',
);

ok (
  ! $rs->results_exist({ title => { -like => '%no such title%' } }),
  '... and answers false when that condition matches nothing',
);

{
  # The point of the capability is the *shape* of the query: one statement that
  # asks the engine for a boolean. A regression that quietly answered through a
  # count or a fetch would still return true/false above, which is why the
  # statement itself is inspected.
  my @sql;
  $storage->debugcb( sub { push @sql, $_[1] } );
  $storage->debug(1);

  $rs->results_exist;

  $storage->debug(0);
  $storage->debugcb(undef);

  is (scalar @sql, 1, 'results_exist is a single round-trip')
    or diag explain \@sql;
  like (
    $sql[0],
    qr/\QSELECT CASE WHEN EXISTS\E.*\QTHEN 1 ELSE 0 END\E/,
    'the statement that ran is the EXISTS query',
  );
  unlike ($sql[0], qr/\bCOUNT\s*\(/i, '... and not a count in disguise');
}

{
  # results_exist_as_query is the fragment form, and a select-list position is
  # where an engine that dislikes the rendering says so. The extra artist makes
  # the column discriminating: with every artist owning a CD, a subquery stuck
  # at 1 would look correct.
  $schema->resultset('Artist')->create({ name => 'No Records' });

  my $artist_rs = $schema->resultset('Artist');
  my $with_flag = $artist_rs->search(undef, {
    '+columns' => { has_cds => $artist_rs->correlate('cds')->results_exist_as_query },
  });

  my %by_name = map { $_->{name} => $_->{has_cds} } $with_flag->hri->all;

  is (
    $by_name{'No Records'},
    0,
    'the fragment works as a correlated subquery: the artist without CDs gets 0',
  );
  is (
    $by_name{'Caterwauler McCrae'},
    1,
    '... and an artist with CDs gets 1, so the subquery really correlates',
  );
}

# ------------------------- what an undeclared driver looks like (this one, until
# ------------------------- the declaration above)

{
  $storage->_use_supports_exists_query(0);

  throws_ok
    { $rs->results_exist }
    qr/\Qdoes not declare the supports_exists_query capability\E/,
    'with the capability withdrawn, results_exist throws instead of quietly '
  . 'answering through a different query shape -- the caller is told to use '
  . 'has_rows',
  ;

  throws_ok
    { $rs->results_exist_as_query }
    qr/\Qdoes not declare the supports_exists_query capability\E/,
    '... and the fragment form throws on the same check, before any SQL is built',
  ;

  $storage->_use_supports_exists_query(undef);
}

ok (
  $rs->results_exist,
  'clearing the forced value hands the question back to the driver '
. 'declaration: the force above really took the capability away, and the '
. 'undef gives it back instead of pinning core\'s default 0 for the life of '
. 'this storage. Since core k137 / ADR 0041 that holds for either declaration '
. 'form -- a per-storage force and a class-level _use_ declaration are two '
. 'physically different slots (the instance hash vs the $Class::__cag_<field> '
. 'package variable), and set_use_dbms_capability now deletes the instance '
. 'slot on undef rather than leaving a tombstone that get_inherited, which '
. 'reads an instance with exists() and not defined(), would take for a value',
);

done_testing;
