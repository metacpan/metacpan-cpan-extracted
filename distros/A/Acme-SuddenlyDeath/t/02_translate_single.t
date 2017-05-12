use strict;
use utf8;
use Acme::SuddenlyDeath;
use Test::More;

my $got;
my $expect;

subtest "sudden_death_single" => sub {
    $got = sudden_death_single("突然の死");
    $expect = '＿人人人人人＿＞ 突然の死 ＜￣^Y^Y^Y^Y^￣';
    is($got, $expect, 'JP');

    $got = sudden_death_single("suddenly death");
    $expect = '＿人人人人人人人人＿＞ suddenly death ＜￣^Y^Y^Y^Y^Y^Y^Y^￣';
    is($got, $expect, 'EN');

    $got = sudden_death_single("突然の death");
    $expect = '＿人人人人人人人＿＞ 突然の death ＜￣^Y^Y^Y^Y^Y^Y^￣';
    is($got, $expect, 'JP/EN');

    $got = sudden_death_single("突然の\ndeath");
    $expect = "＿人人人人＿＞ 突然の ＜＞  death ＜￣^Y^Y^Y^￣";
    is($got, $expect, 'JP/EN + BR');
};

done_testing;
