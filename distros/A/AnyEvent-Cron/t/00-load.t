#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::Cron' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::Cron $AnyEvent::Cron::VERSION, Perl $], $^X" );
