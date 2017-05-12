#!/usr/bin/perl -w

use Test::More tests => 3;

BEGIN { use_ok('DCOP::Amarok') };
my $amarok = DCOP::Amarok->new( user => "$ENV{USER}" );

ok( defined $amarok, "new() defined the object" );
isa_ok( $amarok, 'DCOP::Amarok' );
