#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;

use Config::ZOMG;

warning_is { Config::ZOMG->new( local_suffix => 'local' ) } undef;
warning_like { Config::ZOMG->new( file => 'xyzzy',local_suffix => 'local' ) } qr/will be ignored if 'file' is given, use 'path' instead/;

done_testing;
