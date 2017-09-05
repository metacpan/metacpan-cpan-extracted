#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Local::C1;
use Local::C2;
use Local::C3;

subtest "getter & setter" => sub {
    my $c1 = Local::C1->new;
    $c1->foo(1.2);
    $c1->bar(34);
    is_deeply($c1, bless(do{\(my $o = pack("cf", 34, 1.2))}, "Local::C1"));
    ok(abs($c1->foo - 1.2) < 1e-7);
    is($c1->bar, 34);
    $c1->foo(5.6);
    $c1->bar(78);
    ok(abs($c1->foo - 5.6) < 1e-7);
    is($c1->bar, 78);
};

subtest "set attributes in constructor" => sub {
    my $c2 = Local::C2->spawn(foo=>1.2, bar=>34);
    is_deeply($c2, bless(do{\(my $o = pack("cf", 34, 1.2))}, "Local::C2"));
};

subtest "subclass" => sub {
    my $c3 = Local::C3->new(foo => 1.2, bar=>34, baz=>"A");
    is_deeply($c3, bless(do{\(my $o = pack("cA2f", 34, "A", 1.2))}, "Local::C3"));
};

done_testing;
