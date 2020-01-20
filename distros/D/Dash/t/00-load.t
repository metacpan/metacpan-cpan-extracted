#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

BEGIN {
    use_ok('Dash');
    use_ok('Dash::BaseComponent');
}

my $app = Dash->new;

isa_ok( $app, 'Dash' );
