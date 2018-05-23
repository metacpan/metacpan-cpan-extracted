#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;

my $n = time;
my $t = BSON::Time->new($n);
isa_ok( $t, 'BSON::Time' );
is( $t->value, $n * 1000 );

sleep 1;
my $t2 = BSON::Time->new;
isa_ok( $t2, 'BSON::Time' );
ok( $t2->value );
isnt( $t2->value, $t->value );

my $t3 = BSON::Time->new($n);
is( $t3, $t );

my $try = eval { $t = BSON::Time->new('abcde'); 1 };
isnt($try, 1, 'Dies ok');

