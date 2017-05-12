#!perl
use warnings;
use strict;
use Test::Bot::BasicBot::Pluggable::Store;

use File::Temp qw(tempdir);
my $tmpdir = tempdir( CLEANUP => 1 );

store_ok( 'Storable', { dir => $tmpdir } );
