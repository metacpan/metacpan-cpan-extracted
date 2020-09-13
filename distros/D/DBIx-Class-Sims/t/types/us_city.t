# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';
use types qw(types_test);

types_test us_city => {
  tests => [
    [ { data_type => 'varchar' }, qr/^[\w\s]+$/, 'Ithaca' ],
  ],
};

done_testing;
