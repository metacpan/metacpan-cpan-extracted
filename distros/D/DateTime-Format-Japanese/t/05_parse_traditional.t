#!perl
use strict;
use Test::More (tests => 57);
BEGIN
{
    use_ok("DateTime::Format::Japanese::Traditional");
}

my @params = (
    [
        "平成十六年睦月三日",
        [ 78, 20, 1, 3, 1, 1 ],
    ],
    [
        "平成十六年睦月三日子の刻",
        [ 78, 20, 1, 3, 10, 1 ],
    ],
    [
        "平成十六年睦月三日子三つ刻",
        [ 78, 20, 1, 3, 10, 3 ],
    ],
    [
        "平成16年1月3日卯の刻",
        [ 78, 20, 1, 3, 1, 1 ],
    ],
    [
        "平成16年1月3日卯3つ刻",
        [ 78, 20, 1, 3, 1, 3 ],
    ],
    [
        "旧暦平成16年1月3日卯3つ刻",
        [ 78, 20, 1, 3, 1, 3 ],
    ],
    [
        "旧暦平成１６年１月３日卯の刻",
        [ 78, 20, 1, 3, 1, 1 ],
    ],
    [
        "旧暦平成１６年睦月３日子の刻",
        [ 78, 20, 1, 3, 10, 1 ],
    ]
);

my $dt;
my $p = DateTime::Format::Japanese::Traditional->new();
foreach my $param (@params) {
    $dt = eval { $p->parse_datetime($param->[0]) };
    ok($dt);

    SKIP:{
        skip("parse_datetime raised exception or didn't return a DateTime object: $@", 1) if !$dt;
        is($dt->cycle,        $param->[1]->[0], $param->[0] . " cycle");
        is($dt->cycle_year,   $param->[1]->[1], $param->[0] . " cycle_year");
        is($dt->month,        $param->[1]->[2], $param->[0] . " month");
        is($dt->day,          $param->[1]->[3], $param->[0] . " day");
        is($dt->hour,         $param->[1]->[4], $param->[0] . " hour");
        is($dt->hour_quarter, $param->[1]->[5], $param->[0] . " hour_quarter");
    }
}




