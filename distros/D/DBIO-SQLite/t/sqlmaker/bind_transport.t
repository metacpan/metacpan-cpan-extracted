use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema();

my $rs = $schema->resultset('CD')->search({ -and => [
  'me.artist' => { '!=', '666' },
  'me.artist' => { '!=', \[ '?', [ _ne => 'bar' ] ] },
]});

# bogus sql query: make sure the composed binds (subquery column, free select,
# group_by, having, order_by, limit/offset) are accepted by SQLite
my $complex_rs = $rs->search({}, {
  '+columns' => { cnt => $rs->count_rs->as_query },
  '+select' => \[ 'me.artist + ?', [ _add => 1 ] ], # free select
  group_by => ['me.cdid', \[ 'me.artist - ?', [ _sub => 2 ] ] ],
  having => \[ 'me.artist < ?', [ _lt => 3 ] ],
  order_by => \[ 'me.artist * ? ', [ _mu => 4 ] ],
  rows => 1,
  page => 3,
});

# see if we get anything back at all
isa_ok ($complex_rs->next, 'DBIO::Row');

undef $schema;

done_testing;
