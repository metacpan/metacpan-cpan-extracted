# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing like );

use lib 't/lib';
use types qw(types_test);

types_test us_ssntin => {
  tests => [
    [ { data_type => 'varchar' }, qr/^(?:\d{3}-\d{2}-\d{4})|(?:\d{2}-\d{7})$/, '000-00-0000' ],
  ],
};

done_testing;
