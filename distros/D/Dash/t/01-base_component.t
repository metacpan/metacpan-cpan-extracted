#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Dash::BaseComponent;

my $base = Dash::BaseComponent->new();

isa_ok( $base, 'Dash::BaseComponent' );

can_ok( $base, qw(DashNamespace TO_JSON) );

my $undefined_namespace = 'no_namespace';
is( $base->DashNamespace(), $undefined_namespace );

is_deeply( $base->TO_JSON,
           { type      => 'BaseComponent',
             namespace => $undefined_namespace,
             props     => { children => undef }
           },
           'Hash representation match that expected by dash_renderer.js'
);

