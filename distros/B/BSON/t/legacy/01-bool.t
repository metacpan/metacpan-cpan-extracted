#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;

ok(BSON::Bool->new(1));
ok(!BSON::Bool->new(0));
ok(BSON::Bool->true);
ok(!BSON::Bool->false);

my $t = BSON::Bool->true;
my $f = BSON::Bool->false;

ok( $t && !$f );
