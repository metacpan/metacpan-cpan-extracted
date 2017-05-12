#!perl

use Test::More tests => 1;

BEGIN { $ENV{PFILES} = 'a;b' };

use Config::PFiles::Path append => RW => 'c';

is( $ENV{PFILES}, 'a:c;b', "import append" );
