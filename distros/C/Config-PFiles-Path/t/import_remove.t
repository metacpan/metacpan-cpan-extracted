#!perl

use Test::More tests => 1;

BEGIN { $ENV{PFILES} = 'a;b' };

use Config::PFiles::Path remove => 'RW';

is( $ENV{PFILES}, ';b', "import remove" );
