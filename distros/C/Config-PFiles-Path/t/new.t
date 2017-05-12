#!perl

use Test::More tests => 1;

use strict;
use warnings;

use Config::PFiles::Path;

eval { Config::PFiles::Path->new( 'a;b;c' ) };
ok( $@, "bad input" );
