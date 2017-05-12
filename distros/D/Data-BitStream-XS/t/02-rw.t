#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 1;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

$v->write(2, 3);
$v->rewind_for_read;
my $value = $v->read(2);
is($value, 3, 'wrote 3 in 2 bits, read it back');
