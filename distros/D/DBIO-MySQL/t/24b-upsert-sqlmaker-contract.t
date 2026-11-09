use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::MySQL::SQLMaker;

# karr #45 -- replaces the dead Source-branch test from karr #44.
#
# Commit 46d5baa taught DBIO::MySQL::SQLMaker::insert to recognise a
# ResultSource handed to it directly (ref $table ...) and to recreate the
# _mysql_upsert_plan identity_column decision inside the maker. That branch is
# unreachable on every real call path: both the core async runner
# (DBIO::Storage::Async::_run_crud) and the ev backend
# (DBIO::MySQL::EV::Storage::_run_crud_pinned) reduce the source to a plain
# table-name string via ->name BEFORE calling sql_maker->insert, and the sync
# driver's insert goes through _mysql_upsert_plan anyway. And even if it were
# reachable, $table->source_name is the schema moniker ("Artist"), not the
# table name ("artist") -- on a case-sensitive server that INSERT points at a
# table that does not exist.
#
# This file pins the contract instead (ADR 0036 section 4, as it is wired in
# production): the SQLMaker takes a plain table-name string and RENDERS the
# on_conflict structure it is handed. The identity_column decision belongs to
# the storage (_mysql_upsert_plan, or the ev backend's delegation to it) --
# never to the maker. A structure without identity_column stays without it (no
# silent inference), a structure carrying it renders the idiom.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MySQL::Storage',
);

my $maker = DBIO::MySQL::SQLMaker->new(
  bindtype   => 'columns',
  quote_char => '`',
  name_sep   => '.',
);

# --- the production call shape ---------------------------------------------

# The structure _mysql_upsert_plan hands down for an AUTO_INCREMENT primary
# key (Case 1): the conflict set carries identity_column. The maker renders it.
{
  my ($sql) = $maker->insert(
    'artist',
    { name => 'x' },
    { on_conflict => {
        target          => 'any',
        action          => 'update',
        set             => { name => { -attempted => 'name' } },
        identity_column => 'artistid',
    } }
  );

  like $sql, qr/`artistid` = LAST_INSERT_ID\(`artistid`\)$/,
    'a planned identity_column is rendered verbatim';
}

# The structure core's upsert_async hands the backend has NO identity_column
# (the sync driver's _mysql_upsert_plan adds it; the async paths reach that
# plan through the storage, not through the maker). The maker must not infer
# one -- it has no Source and no server facts, and the decision is the
# storage's. So the raw structure renders without the idiom.
{
  my ($sql) = $maker->insert(
    'artist',
    { name => 'x' },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { name => { -attempted => 'name' } },
    } }
  );

  unlike $sql, qr/LAST_INSERT_ID/,
    'no identity_column handed in => no idiom (the maker does not decide)';
}

# The storage-shaped equivalents of the negative cases, one level up: a
# caller-supplied AUTO_INCREMENT value and a PK in the conflict set both make
# _mysql_upsert_plan leave identity_column OUT of the structure, and the maker
# renders exactly what it is given -- no idiom. (The decisions themselves are
# pinned in t/24-upsert-mysql.t section 4; what belongs here is that the maker
# does not second-guess them.)
{
  my ($sql) = $maker->insert(
    'artist',
    { artistid => 7, name => 'x' },
    { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { name => { -attempted => 'name' } },
    } }
  );

  unlike $sql, qr/LAST_INSERT_ID/,
    'a supplied primary key suppresses the idiom (no key in the structure)';
}

# --- the removed Source branch ----------------------------------------------

# The old branch reduced $table->source_name -- the MONIKER ("Artist") -- and
# produced an INSERT INTO `Artist` that no case-sensitive server has. That
# path is gone: a ResultSource is not a supported argument to sql_maker->insert
# (the callers unwrap to ->name themselves). What the base does with a blessed
# table is not this maker's concern; the assertions that matter are that the
# moniker never reaches the SQL and that no identity is inferred either.
{
  my $artist = $schema->source('Artist');
  my $sql = eval { ( $maker->insert( $artist, { name => 'x' }, { on_conflict => {
        target => 'any',
        action => 'update',
        set    => { name => { -attempted => 'name' } },
    } } ) )[0] };

  if (defined $sql) {
    unlike $sql, qr/INSERT INTO `Artist`/,
      'a blessed Source is not reduced via source_name (the moniker never hits the SQL)';
    unlike $sql, qr/LAST_INSERT_ID/,
      'and no identity is inferred for a Source either';
  }
  else {
    pass 'a blessed Source is outside the maker contract (base refuses it)';
    diag "sql_maker->insert(\$source, ...): $@" if $@;
  }
}

done_testing;
