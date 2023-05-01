#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Commandable;

require Commandable::Command;

require Commandable::Finder::MethodAttributes;
require Commandable::Finder::Packages;
require Commandable::Finder::SubAttributes;

pass( "Modules loaded" );
done_testing;
