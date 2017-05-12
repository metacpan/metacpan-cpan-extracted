#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 2;

BEGIN {
    use_ok('Bat::Interpreter');
}

my $interpreter = Bat::Interpreter->new;

isa_ok( $interpreter, 'Bat::Interpreter' );
