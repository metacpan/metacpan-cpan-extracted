#!perl
use strict;
use warnings;
use Test::More;

# apt-get install libmoo-perl
use_ok('Moo');

# will be needed in my tests:
use_ok('Test::Compile');
use_ok('Test::More');
use_ok( 'Config::IniFiles' => "3.000003" );
use_ok( 'Log::Log4perl'    => '1.54' );
use_ok( 'Moo'              => '2.004000' );
use_ok( 'Params::Validate' => '1.30' );

done_testing();

