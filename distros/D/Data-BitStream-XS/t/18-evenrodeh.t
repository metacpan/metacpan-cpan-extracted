#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 1;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

$v->put_evenrodeh(0 .. 257);
$v->rewind_for_read;
is_deeply( [$v->get_evenrodeh(-1)], [0 .. 257], 'evenrodeh 0-257');
