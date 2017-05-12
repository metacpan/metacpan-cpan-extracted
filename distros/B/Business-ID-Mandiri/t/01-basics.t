#!perl

use strict;
use warnings;
use Test::More 0.98;

use Business::ID::Mandiri qw(parse_mandiri_account);

my @tests = (
    {args=>{account=>''}                , status=>400, name=>'length 1'},
    {args=>{account=>'123'}             , status=>400, name=>'length 2'},
    {args=>{account=>'13000022381141'}  , status=>400, name=>'length 3'},

    {args=>{account=>'1300002238114'}   , status=>200, res=>{
        branch_code=>'130',
        account=>'1300002238114',
        account_f=>'130.0002238114',
    }, name=>'ok 1'},
    {args=>{account=>'130 0002238114'}  , status=>200, name=>'ok 2 (nondigits ignored)'},
);

for my $t (@tests) {
    subtest $t->{name} => sub {
        my $res = parse_mandiri_account(%{$t->{args}});
        is($res->[0], $t->{status}, 'status');
        if ($t->{res}) {
            is_deeply($res->[2], $t->{res}, 'res') or diag explain $res;
        }
    };
}

done_testing;
