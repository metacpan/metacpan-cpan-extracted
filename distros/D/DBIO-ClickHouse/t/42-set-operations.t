use strict;
use warnings;

use Test::More;
use Test::Exception;

# ClickHouse spellings for DBIO::ResultSet's six set operations, through
# DBIO::ClickHouse::Storage::_set_operation_keyword (ADR 0039).
#
# The engine fact this file encodes is not "ClickHouse uses a different word".
# It is that ClickHouse resolves a *bare* UNION / INTERSECT / EXCEPT from a
# session setting instead of giving it the ANSI meaning:
#
#   union_default_mode      ships as the empty string -> a bare UNION throws
#                           (changed to throw in ClickHouse 21.1)
#   intersect_default_mode  ships as 'ALL' -> a bare INTERSECT keeps duplicates
#   except_default_mode     ships as 'ALL' -> a bare EXCEPT keeps duplicates
#
# So core's ANSI keyword is a hard error for one operation and a silently
# larger result set for two, and the fix is a spelling, not a refusal --
# ClickHouse has all six operators. That is why every assertion below is about
# the exact token emitted: a test that only checked "some SQL came out" could
# not fail when the DISTINCT went missing again, which is the whole defect.
#
# Offline. The keyword is a static class fact by contract (ADR 0039 section 7),
# so none of this needs a server -- which is just as well, DBD::MariaDB does
# not connect to a stock ClickHouse (karr k15).

use DBIO::Test ':DiffSQL';
use DBIO::ClickHouse::Storage;
use DBIO::Storage::DBI ();

# --- the hook itself, on the class -----------------------------------------
#
# Read off DBIO::ClickHouse::Storage directly and not off a storage built by
# init_schema: that one is a hybrid with core's fake storage in its MRO, so an
# answer coming from the base would be indistinguishable from ours.

my %EXPECTED = (
  union         => 'UNION DISTINCT',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT DISTINCT',
  intersect_all => 'INTERSECT ALL',
  except        => 'EXCEPT DISTINCT',
  except_all    => 'EXCEPT ALL',
);

for my $op (sort keys %EXPECTED) {
  is(DBIO::ClickHouse::Storage->_set_operation_keyword($op), $EXPECTED{$op},
    "_set_operation_keyword('$op') is $EXPECTED{$op}");
}

# The values alone do not say where they came from, and that is the part that
# can rot: an override that stopped calling next::method would still answer
# 'UNION ALL' by luck, and an override that grew a fourth entry would still
# answer 'UNION DISTINCT'. So compare against the base map directly -- exactly
# three operations must differ from it, and exactly three must be it.

for my $op (qw( union intersect except )) {
  isnt(DBIO::ClickHouse::Storage->_set_operation_keyword($op),
       DBIO::Storage::DBI->_set_operation_keyword($op),
    "$op is spelled differently here than core's ANSI base");
}

for my $op (qw( union_all intersect_all except_all )) {
  is(DBIO::ClickHouse::Storage->_set_operation_keyword($op),
     DBIO::Storage::DBI->_set_operation_keyword($op),
    "$op is core's base keyword, reached through next::method");
}

# An unknown operation is a core programming error, not an engine fact, so it
# must fall through to core's throw rather than being swallowed here.
throws_ok { DBIO::ClickHouse::Storage->_set_operation_keyword('minus_all') }
  qr/Unknown set operation/,
  'an unknown operation falls through to core, which throws';

throws_ok { DBIO::ClickHouse::Storage->_set_operation_keyword(undef) }
  qr/Unknown set operation/,
  '... and so does undef';

# --- and the statement a caller actually gets -------------------------------
#
# The hook returning the right string is only half of it: the keyword has to
# land between the two operands. This is the half that would catch core
# changing how _set_operation composes the query.

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::ClickHouse::Storage',
  no_deploy    => 1,
);

my $artist = $schema->resultset('Artist');
my $COLS   = '`me`.`artistid`, `me`.`name`, `me`.`rank`, `me`.`charfield`';

my $NAME = { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 };

for my $op (sort keys %EXPECTED) {
  my $keyword = $EXPECTED{$op};

  my $left  = $artist->search_rs({ name => 'a' });
  my $right = $artist->search_rs({ name => 'b' });

  is_same_sql_bind(
    $left->$op($right)->as_query,
    "( SELECT $COLS FROM ("
    . "SELECT $COLS FROM `artist` `me` WHERE ( `name` = ? )"
    . " $keyword "
    . "SELECT $COLS FROM `artist` `me` WHERE ( `name` = ? )"
    . ") `me` )",
    [ [ $NAME => 'a' ], [ $NAME => 'b' ] ],
    "\$rs->$op emits $keyword between the operands",
  );
}

# is_same_sql_bind normalises whitespace, and the difference between UNION and
# UNION DISTINCT is a token, not spacing -- but a normaliser that ever learned
# to treat the two as equivalent would hide exactly this bug. So pin the raw
# string for the three that changed, and pin the negative too: no bare keyword
# survives anywhere in the statement.
for my $op (qw( union intersect except )) {
  my $left  = $artist->search_rs({ name => 'a' });
  my $right = $artist->search_rs({ name => 'b' });

  my ($sql) = @{ ${ $left->$op($right)->as_query } };
  my ($bare) = $EXPECTED{$op} =~ /^(\w+)/;

  like $sql, qr/\Q$EXPECTED{$op}\E/,
    "\$rs->$op renders the literal '$EXPECTED{$op}'";
  unlike $sql, qr/\b\Q$bare\E(?!\s+(?:ALL|DISTINCT)\b)/,
    "... and never a bare $bare, which ClickHouse resolves from a session setting";
}

done_testing;
