#!perl -T

use Test::More tests => 2;

BEGIN {
    chdir('t') if -d 't';
    use_ok( 'App::Dusage' );
    require_ok( '../script/dusage' );
}

diag( "Testing App::Dusage $VERSION, Perl $], $^X" );
