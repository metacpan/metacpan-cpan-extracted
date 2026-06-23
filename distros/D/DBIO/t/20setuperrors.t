use warnings;
use strict;

use Test::More;
use Test::Exception;

use DBIO::Test;

throws_ok (
  sub {
    package BuggyTable;
    use base 'DBIO::Core';

    __PACKAGE__->table('buggy_table');
    __PACKAGE__->columns( qw/this doesnt work as expected/ );
  },
  qr/\bcolumns\(\) is a read-only/,
  'columns() error when apparently misused',
);

done_testing;
