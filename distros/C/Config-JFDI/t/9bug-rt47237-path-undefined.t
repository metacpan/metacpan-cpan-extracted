#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use Config::JFDI;

my $config = Config::JFDI->new( name => '' );
warning_is { $config->_path_to } undef;

done_testing;
