#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;

use Config::ZOMG;

my $config = Config::ZOMG->new( name => '' );
warning_is { $config->_path_to } undef;

done_testing;
