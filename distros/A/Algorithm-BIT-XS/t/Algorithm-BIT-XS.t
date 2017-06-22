#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 24;
BEGIN { use_ok('Algorithm::BIT::XS') };
BEGIN { use_ok('Algorithm::BIT2D::XS') };

my $bit = Algorithm::BIT::XS->new(25);
ok !eval{$bit->query(26); 1}, 'query(26) fails';
ok !eval{$bit->update(26, 5); 1}, 'update(26, 5) fails';
is $bit->query(5), 0;
$bit->update(4, 2);
$bit->update(5, 3);
is $bit->query(3), 0;
is $bit->query(4), 2;
is $bit->query(5), 5;
is $bit->query(6), 5;
is $bit->query(0), 0;

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


my $bit2d = Algorithm::BIT2D::XS->new(10, 5);
ok !eval{$bit2d->query(11, 5); 1}, 'query(11, 5) fails';
ok !eval{$bit2d->query(10, 6); 1}, 'query(10, 6) fails';
ok !eval{$bit2d->update(11, 5, 2); 1}, 'update(11, 5, 2) fails';
ok !eval{$bit2d->update(10, 6, 2); 1}, 'update(10, 6, 2) fails';
is $bit2d->query(5, 5), 0;
$bit2d->update(4, 4, 2);
$bit2d->update(5, 1, 3);
is $bit2d->query(5, 5), 5;
is $bit2d->query(5, 2), 3;
