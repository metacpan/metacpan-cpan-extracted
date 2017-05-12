#!/usr/bin/perl -w

# This is a null test to shut up cpantesters

use strict;
use Test::More tests => 1;

# Check their perl version
ok( $] > 5.005, 'Perl version is new enough' );

1;
