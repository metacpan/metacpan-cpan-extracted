#!/usr/bin/perl
use strict;
use Config::Terse;
use Data::Dumper;

my $cfg = terse_config_load( 'try.cfg', ORDERED => 1, MAIN => '*' );

print Dumper( $cfg );
