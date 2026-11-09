use strict;
use warnings;
use Test::More;

# Offline unit test for DBIO::ClickHouse::SQLMaker.
#
# No DBI, no DSN, no server — the SQLMaker is instantiated directly. The
# storage normally applies the backtick quote_char (via sql_quote_char), so we
# pass quote_char/name_sep here explicitly, mirroring how core unit-tests the
# maker offline (t/sqlmaker/parenthesized_where.t).

use DBIO::ClickHouse::SQLMaker;

my $sm = DBIO::ClickHouse::SQLMaker->new(quote_char => '`', name_sep => '.');
isa_ok $sm, 'DBIO::ClickHouse::SQLMaker';
isa_ok $sm, 'DBIO::SQLMaker';

# Backtick identifier quoting on a simple SELECT.
{
  my ($sql) = $sm->select('artist', ['id'], { name => 'foo' });
  like $sql, qr/\bFROM\s+`artist`/, 'table identifier is backtick-quoted';
  like $sql, qr/`id`/,              'column identifier is backtick-quoted';
  unlike $sql, qr/"artist"/,        'no double-quote quoting leaks in';
}

# ClickHouse has no SELECT ... FOR UPDATE: _lock_select is disabled, so even an
# explicit { for => 'update' } must not emit a locking clause.
{
  my ($sql) = $sm->select('artist', '*', {}, { for => 'update' });
  unlike $sql, qr/FOR\s+UPDATE/i, 'no FOR UPDATE clause emitted';
  unlike $sql, qr/\bFOR\b/i,      'no bare FOR lock clause emitted';
}

done_testing;
