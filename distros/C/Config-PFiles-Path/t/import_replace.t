#!perl

use Test::More tests => 1;

BEGIN { $ENV{PFILES} = 'a;b' };

use Config::PFiles::Path replace => RW => 'c';

is( $ENV{PFILES}, 'c;b', "import replace" );
