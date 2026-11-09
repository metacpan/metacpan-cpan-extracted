use strict;
use warnings;

use Test::More;
use DBI ();
use DBIO::SQLite::Test;

# karr k62. The two limits named in the POD of DBIO::SQLite::Storage
# ("Binds without a column"): a bind that belongs to no column is typed by the
# spelling of its value, and against an expression without affinity that is
# wrong for a canonical integer string that is meant as text, and for a
# non-integer that is meant as a number. The way out is the type at the bind,
# and this file holds that it works: if a typed bind were rebound by the
# storage, the typed cases below turn into the untyped ones and fail.

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

my $artists = $schema->resultset('Artist');

$artists->create({ name => '99999', rank => 2 });

# --- limit 1: canonical integer string, text expression ---

is $artists->search({ name => '99999' })->count, 1,
  'reference: the column itself matches, its TEXT affinity turns the integer back';

is $artists->search(\[ 'lower(name) = ?', '99999' ])->count, 0,
  'untyped: lower(name) = ? with a canonical integer string is bound as INTEGER (the documented limit)';

is $artists->search(\[ 'lower(name) = ?', [ { sqlt_datatype => 'varchar' } => '99999' ] ])->count, 1,
  'sqlt_datatype => varchar at the bind: lower(name) = ? finds the row';

# --- limit 2: non-integer, numeric expression ---

# populate_schema: artistid 1, 2, 3, plus the row created above
my %attrs = ( group_by => 'me.artistid' );

is $artists->search(undef, {
  %attrs, having => \[ 'AVG(me.artistid) > ?', 1.5 ],
})->count, 0,
  'untyped: AVG(x) > ? with 1.5 is bound as text and never true (the documented limit)';

is $artists->search(undef, {
  %attrs,
  having => \[ 'AVG(me.artistid) > ?', [ { dbd_attrs => DBI::SQL_REAL() } => 1.5 ] ],
})->count, 3,
  'dbd_attrs => SQL_REAL at the bind: AVG(x) > ? counts the groups above 1.5';

done_testing;
