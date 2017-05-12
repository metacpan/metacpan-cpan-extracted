#!/usr/bin/perl -w

use Test::More tests => 3;

BEGIN { use_ok('DCOP') };
my $dcop = DCOP->new( user => "$ENV{USER}" );
ok( defined $dcop, "new() defined the object" );
isa_ok( $dcop, 'DCOP' );
