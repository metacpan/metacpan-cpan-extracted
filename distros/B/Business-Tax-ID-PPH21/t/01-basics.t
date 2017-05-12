#!perl

use strict;
use warnings;
use Test::More 0.98;

use Business::Tax::ID::PPH21 qw(calc_pph21_op);

# XXX test get_pph21_op_rates
# XXX test get_pph21_op_ptkp

subtest calc_pph21_op => sub {
    is_deeply(calc_pph21_op(year=>2015, tp_status=>'TK/0', net_income=> 35_000_000), [200, "OK",           0]);
    is_deeply(calc_pph21_op(year=>2015, tp_status=>'K/2' , net_income=>420_000_000), [200, "OK",  63_750_000]);
    is_deeply(calc_pph21_op(year=>2015, tp_status=>'K/1' , net_income=>700_000_000), [200, "OK", 142_400_000]);
};

DONE_TESTING:
done_testing;
