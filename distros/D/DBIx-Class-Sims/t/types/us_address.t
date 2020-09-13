# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing like );

use lib 't/lib';
use types qw(types_test);

types_test us_address => {
  tests => [
    [ { data_type => 'varchar' }, qr/^(?:\d{1,5} \w+ [\w.]+)|(?:P\.?O\.? Box \d+)$/, '1 Main Street' ],
  ],
 };

done_testing;
