use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;
lives_ok (sub {
  DBIO::SQLite::Test->init_schema()->resultset('Artist')->find({artistid => 1 })->update({name => 'anon test'});
}, 'Schema object not lost in chaining');

done_testing;
