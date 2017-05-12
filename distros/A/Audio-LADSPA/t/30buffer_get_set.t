#!/usr/bin/perl -w

use Test::More tests => 14; 
use strict;
BEGIN {
    use_ok('Audio::LADSPA::Buffer');
}

my $buff1;
ok($buff1 = Audio::LADSPA::Buffer->new(1),"size 1 buffer");

ok($buff1->isa("Audio::LADSPA::Buffer"),"package name");

my $buff10;
ok($buff10 = Audio::LADSPA::Buffer->new(10),"size 10 buffer");


eval {$buff1->set_1(10)};
ok(!$@,"set 1");

$buff1->set_1(20);
ok(1,"set_1 # 2");

is($buff1->filled,1,"filled()");

is($buff1->get_1(),20,"get_1");

$buff1->set_1(30);


eval { $buff1->set_list(1,2) };
ok($@ =~ /size/ ,"Range checking 1");

$buff10->set_list(1,2,3,4,5,6,7,8,9,10);
ok(1, "Set 10");

is($buff10->filled,10,"filled() 10");
my @list = $buff10->get_list();
is(scalar @list,10,"get 10 items");

my $last = 0;
for (@list) {
    last unless $_ == $last + 1;
    $last = $_;
}
is($last,10,"10 items values");

eval { $buff10->set_list(1,2,3,4,5,6,7,8,9,10,11) };
ok($@ =~ /size/, "Range checking 10");



