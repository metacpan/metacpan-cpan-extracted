# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing like );

use lib 't/lib';
use types qw(types_test);

types_test us_name => {
  tests => [
    [ { data_type => 'varchar'}, qr/^\w+ (?:\w\. )?[\w']+(?: \w+)?(?: .+)?$/, 'Aidan A. Jones Jr' ],
  ],
};

done_testing;
