#!perl

use strict;
use warnings;
use Config::Validator qw(expand_size);
use Test::More tests => 25;

my $validator = Config::Validator->new({ type => "size" });

sub test ($;$) {
    my($string, $value) = @_;
    my($size);

    $@ = "";
    eval { $validator->validate($string) };
    if (defined($value)) {
        is($@, "", "valid $string");
        $size = expand_size($string);
        cmp_ok($size, '==', $value, "expand_size($string)");
    } else {
        ok($@, "invalid $string");
    }
}

test("0", 0);
test("1", 1);
test("12345", 12345);
test("0B", 0);
test("1b", 1);
test("12345B", 12345);
test("1kb", 1024);
test("2MB", 2 * 1024 * 1024);
test("3gB", 3 * 1024 * 1024 * 1024);
test("0.5KB", 512);

test(".1");
test("1.1");
test("1.1b");
test("1pb");
test("1 kb");
