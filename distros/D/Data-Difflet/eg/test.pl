#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use Test::More;
use Test::Deep;
use Test::Difflet qw/is_deeply/;

is_deeply( { "foo" => [ 1, 2, 3 ] }, { "foo" => [ 4, 2, 3 ] } );
is_deeply( { "foo" => [ 1, 2, 3 ] }, { "foo" => [ 1, 2, 3 ] } );

difflet_is_deeply( { "foo" => [ 1, 2, 3 ] }, { "foo" => [ 4, 2, 3 ] } );

done_testing;
