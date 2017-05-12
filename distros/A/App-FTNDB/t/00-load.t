#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'App::FTNDB' );
    use_ok( 'App::FTNDB::Nodelist' );
    use_ok( 'App::FTNDB::Command::create' );
    use_ok( 'App::FTNDB::Command::drop' );
}

diag( "Testing FTN DB Application $App::FTNDB::VERSION, Perl $], $^X" );
