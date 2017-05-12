#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Algorithm::BIT::XS') };

my $bit = Algorithm::BIT::XS->new(100);
is $bit->query(5), 0;
$bit->update(4, 2);
$bit->update(5, 3);
is $bit->query(3), 0;
is $bit->query(4), 2;
is $bit->query(5), 5;
is $bit->query(6), 5;

$bit->update(5, -3);
is $bit->query(5), 2;

$bit->update(17, 50);
is $bit->query(25), 52;
is $bit->get(25), 0;

$bit->set(17, 30);
is $bit->query(25), 32;
is $bit->get(17), 30;

$bit->clear;
$bit->set(16,10);
is $bit->query(15), 0;
is $bit->query(16), 10;
