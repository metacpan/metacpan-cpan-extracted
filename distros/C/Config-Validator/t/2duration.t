#!perl

use strict;
use warnings;
use Config::Validator qw(expand_duration);
use Test::More tests => 24;

my $validator = Config::Validator->new({ type => "duration" });

sub test ($;$) {
    my($string, $value) = @_;
    my($duration);

    $@ = "";
    eval { $validator->validate($string) };
    if (defined($value)) {
        is($@, "", "valid $string");
        $duration = expand_duration($string);
        cmp_ok($duration, '==', $value, "expand_duration($string)");
    } else {
        ok($@, "invalid $string");
    }
}

test("0", 0);
test("1", 1);
test("12345", 12345);
test("0s", 0);
test("1s", 1);
test("12345s", 12345);
test("1m", 60);
test("1h1m", 3660);
test("1m1h", 3660);
test("1d1ms", 86400.001);

test(".1");
test("1.1");
test("1m1");
test("1h 2m");
