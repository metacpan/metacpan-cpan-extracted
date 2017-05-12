#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 2;

use Attribute::Util qw(Alias);
ok( $INC{"Attribute/Alias.pm"},    "Alias loaded.");
ok(! $INC{"Attribute/Memoize.pm"}, "Memoize NOT loaded.");
