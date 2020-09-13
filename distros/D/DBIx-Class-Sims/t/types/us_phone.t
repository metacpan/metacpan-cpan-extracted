# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing like );

use lib 't/lib';
use types qw(types_test);

types_test us_phone => {
  tests => [
    [ { data_type => 'varchar'}, qr/^\d{3}-\d{4}$/, '000-0000' ],
    [ { data_type => 'varchar', size => 6 }, qr/^$/ ],
    [ { data_type => 'varchar', size => 7 }, qr/^\d{7}$/, '0000000' ],
    [ { data_type => 'varchar', size => 8 }, qr/^\d{3}-\d{4}$/, '000-0000' ],
    [ { data_type => 'varchar', size => 9 }, qr/^\d{3}-\d{4}$/, '000-0000' ],
    [ { data_type => 'varchar', size => 10 }, qr/^\d{10}$/, '0000000000' ],
    [ { data_type => 'varchar', size => 11 }, qr/^\d{10}$/, '0000000000' ],
    [ { data_type => 'varchar', size => 12 }, qr/^\d{3}-\d{3}-\d{4}$/, '000-000-0000' ],
    [ { data_type => 'varchar', size => 13 }, qr/^\(\d{3}\)\d{3}-\d{4}$/, '(000)000-0000' ],
    [ { data_type => 'varchar', size => 14 }, qr/^\(\d{3}\) \d{3}-\d{4}$/, '(000) 000-0000' ],
    [ { data_type => 'varchar', size => 15 }, qr/^\(\d{3}\) \d{3}-\d{4}$/, '(000) 000-0000' ],
  ],
};

done_testing;
