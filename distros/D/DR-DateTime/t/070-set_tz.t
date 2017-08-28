#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 4;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
}

my $now = time;

for my $t (new DR::DateTime $now, '+0300') {
    isa_ok $t => DR::DateTime::, 'instance created';

    my $h = $t->hour;

    $t->set_tz(4);
    is $t->tz, '+0400', 'new time zone was set';
    is $t->hour, (24 + $h + 1) % 24, 'hours';

}

