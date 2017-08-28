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

my $c1 = Local::C1->new;
#is_deeply($c1, bless([undef, undef], "Local::C1"));

$c1->foo(1980);
$c1->bar(12);
is_deeply($c1, bless([1980, 12], "Local::C1"));

my $c2 = Local::C2->spawn;

$c2->foo(1981);
$c2->bar(11);
is_deeply($c2, bless([1981, 11], "Local::C2"));

subtest "set attributes in constructor" => sub {
    my $c1 = Local::C1->new(foo => 10, bar => 20);
    is_deeply($c1, bless([10, 20], "Local::C1"));
    dies_ok { Local::C1->new(qux=>1) } 'unknown attribute specified -> dies';
};

subtest "subclass" => sub {
    my $c3 = Local::C3->new;
    $c3->foo(1981);
    $c3->bar(11);
    $c3->baz("a");
    is_deeply($c3, bless([1981, 11, "a"], "Local::C3"));

    subtest "set attributes in constructor" => sub {
        my $c3 = Local::C3->new(foo => 10, bar => 20, baz => 30);
        is_deeply($c3, bless([10, 20, 30], "Local::C3"));
        dies_ok { Local::C3->new(qux=>1) } 'unknown attribute specified -> dies';
    };
};

done_testing;
