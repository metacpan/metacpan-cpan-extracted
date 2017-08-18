#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 9;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
}

my ($t4, $t3);
my $now = time;
{

    local $DR::DateTime::Defaults::TZFORCE = '+0400';
    $t4 = new DR::DateTime $now;
    isa_ok $t4 => DR::DateTime::;
    is $t4->tz, '+0400', 'forced timezone';
    is $t4->epoch, $now, 'epoch';
}

{
    local $DR::DateTime::Defaults::TZFORCE = '+0300';
    $t3 = new DR::DateTime $now;
    isa_ok $t3 => DR::DateTime::;
    is $t3->tz, '+0300', 'forced timezone';
    is $t3->epoch, $now, 'epoch';
}

is $t3->epoch, $t4->epoch, 'epoch are equal';
is $t3->hour, (24 + $t4->hour - 1) % 24, 'hours';
