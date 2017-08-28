#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 24;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
}

my $now = time;

my $t1 = new DR::DateTime $now;
my $t2 = new DR::DateTime $now - 3600;

cmp_ok $t1, '>', $t2, 'overload <=>';
cmp_ok $t1, 'ge', $t2, 'overload cmp';
cmp_ok $t1, '>', $now - 3600, 'cmp with numeric';
ok !!$t1, 'overload bool';
is int $t1, $t1->epoch, 'overload int';
is int $t2, $t2->epoch, 'overload int';
is "$t1" => $t1->strftime('%F %T%z'), 'overload ""';

cmp_ok $t1, 'ge', $t2->strftime('%F %T%z'), 'cmp with string';

for my $t3 (3600 + $t1) {
    isa_ok $t3 => DR::DateTime::, 'sum NUM and DateTime';
    is $t3->tz, $t1->tz, 'tz';
    is $t3->epoch, $t1->epoch + 3600, 'epoch';
}

for my $t3 ($t1 + 3601) {
    isa_ok $t3 => DR::DateTime::, 'sum NUM and DateTime';
    is $t3->tz, $t1->tz, 'tz';
    is $t3->epoch, $t1->epoch + 3601, 'epoch';
}

for my $t4 ($t1 - 3600) {
    isa_ok $t4 => DR::DateTime::, 'sum NUM and DateTime';
    is $t4->tz, $t1->tz, 'tz';
    is $t4->epoch, $t1->epoch - 3600, 'epoch';
}

for my $t5 ($t1 - $t2) {
    ok !ref $t5, 'delta time is a scalar';
    is $t5, $t1->epoch - $t2->epoch, 'value';
}

for my $t6 ($now + 3600 - $t1) {
    ok !ref $t6, 'delta time is a scalar';
    is $t6, 3600 + $now - $t1->epoch, 'value';
}

for my $t7 (-$t2) {
    ok !ref $t7, '- time == scalar';
    is $t7, -($t2->fepoch), 'value';
}
