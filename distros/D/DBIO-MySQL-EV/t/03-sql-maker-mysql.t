use strict;
use warnings;
use Test::More;

use DBIO::MySQL::EV::Storage;

# Regression: the async storage must route SQL generation through the
# MySQL-specific SQLMaker, not the base DBIO::SQLMaker. Wiring the base
# maker silently loses MySQL's SQL dialect — most visibly pagination,
# which must emit MySQL's `LIMIT offset, rows` instead of the standard
# `LIMIT rows OFFSET offset`.  See karr #7.

my $storage = DBIO::MySQL::EV::Storage->new(undef);
my $sm = $storage->sql_maker;

isa_ok $sm, 'DBIO::MySQL::SQLMaker',
  'sql_maker is the MySQL-specific maker, not the base DBIO::SQLMaker';

# Backtick quoting still applies.
my ($sql) = $sm->select('artist', ['name'], { id => 1 });
like $sql, qr/`name`.*`artist`/i, 'backtick quoting active';

# MySQL pagination dialect: LIMIT offset, rows (offset-first, comma form).
my ($limit_sql) = $sm->select('artist', ['name'], undef, undef, 10, 20);
like $limit_sql, qr/LIMIT \s* \?,\s*\?/xi,
  'pagination emits MySQL LIMIT ?, ? form';
unlike $limit_sql, qr/OFFSET/i,
  'pagination does not emit standard LIMIT ? OFFSET ?';

done_testing;
