#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Config::ZOMG::Source::Loader;

sub file_extension ($) { Config::ZOMG::Source::Loader::file_extension shift }

is( file_extension 'test.conf', 'conf' );
is( file_extension '...', undef );
is( file_extension '../.', undef );
is( file_extension '.../.', undef );
is( file_extension 't/assets/order/..', undef );
is( file_extension 't/assets/dir.cnf', undef );

done_testing;
