#!perl

use Test::More tests => 1;

BEGIN { $ENV{PFILES} = 'a;b' };

use Config::PFiles::Path prepend => RW => 'c';

is( $ENV{PFILES}, 'c:a;b', "import prepend" );
