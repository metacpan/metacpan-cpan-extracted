#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use_ok( "Commandable" );

use_ok( "Commandable::Command" );

use_ok( "Commandable::Finder::MethodAttributes" );
use_ok( "Commandable::Finder::Packages" );
use_ok( "Commandable::Finder::SubAttributes" );

done_testing;
