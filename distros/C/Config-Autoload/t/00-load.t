#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Config::Autoload' ) || print "Bail out!
";
}

diag( "Testing Config::Autoload $Config::Autoload::VERSION, Perl $], $^X" );
