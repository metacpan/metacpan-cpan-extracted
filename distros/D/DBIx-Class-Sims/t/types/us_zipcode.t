# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing );

use lib 't/lib';
use types qw(types_test);

types_test us_zipcode => {
  tests => [
    [ { data_type => 'varchar' }, qr/^\d{5}-\d{4}$/, '00000-0000' ],
    [ { data_type => 'varchar', size => 9 }, qr/^\d{9}$/, '000000000' ],
    [ { data_type => 'varchar', size => 10 }, qr/^\d{5}-\d{4}$/, '00000-0000' ],
    [ { data_type => 'varchar', size => 12 }, qr/^\d{5}-\d{4}$/, '00000-0000' ],
    [ { data_type => 'varchar', size => 8 }, qr/^\d{5}$/, '00000' ],
    [ { data_type => 'varchar', size => 7 }, qr/^\d{5}$/, '00000' ],
    [ { data_type => 'varchar', size => 6 }, qr/^\d{5}$/, '00000' ],
    [ { data_type => 'varchar', size => 5 }, qr/^\d{5}$/, '00000' ],
    [ { data_type => 'varchar', size => 4 }, qr/^$/ ],
    [ { data_type => 'varchar', size => 3 }, qr/^$/ ],
    [ { data_type => 'varchar', size => 2 }, qr/^$/ ],
    [ { data_type => 'varchar', size => 1 }, qr/^$/ ],
    [ { data_type => 'int' }, qr/^\d{1,5}$/, '0' ],
  ],
};

done_testing;
