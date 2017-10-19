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
    is_deeply($c1, bless(do{\(my $o = join(""))}, "Local::C1"));

    $c1->foo(1.2);
    is_deeply($c1, bless(do{\(my $o = join("", chr(0), pack("f", 1.2)))}, "Local::C1"));
    ok(abs($c1->foo - 1.2) < 1e-7);

    $c1->bar(34);
    is_deeply($c1, bless(do{\(my $o = join("", chr(0), pack("f", 1.2), chr(1), pack("c", 34)))}, "Local::C1"));
    is($c1->bar, 34);

    $c1->foo(5.6);
    ok(abs($c1->foo - 5.6) < 1e-7);
    is_deeply($c1, bless(do{\(my $o = join("", chr(0), pack("f", 5.6), chr(1), pack("c", 34)))}, "Local::C1"));

    $c1->bar(78);
    is($c1->bar, 78);
    is_deeply($c1, bless(do{\(my $o = join("", chr(0), pack("f", 5.6), chr(1), pack("c", 78)))}, "Local::C1"));

    $c1->foo(undef);
    is_deeply($c1->foo, undef);
    is_deeply($c1, bless(do{\(my $o = join("", chr(1), pack("c", 78)))}, "Local::C1"));

    $c1->bar(undef);
    is_deeply($c1->bar, undef);
    is_deeply($c1, bless(do{\(my $o = join(""))}, "Local::C1"));
};

#subtest "set attributes in constructor" => sub {
#    my $c2 = Local::C2->spawn(foo=>1.2, bar=>34);
#    is_deeply($c2, bless(do{\(my $o = pack("cf", 34, 1.2))}, "Local::C2"));
#};

subtest "subclass" => sub {
    my $c3 = Local::C3->new;
    $c3->bar(34);
    $c3->foo(1.2);
    $c3->baz("A");
    is_deeply($c3, bless(do{\(my $o = join("", chr(1), pack("c", 34), chr(0), pack("f", 1.2), chr(2), pack("A2", "A")))}, "Local::C3"));
};

done_testing;
