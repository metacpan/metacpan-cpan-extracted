#!perl -T

use Test::More tests => 10;

BEGIN {
    use_ok( 'App::Standby::Cmd::Command::bootstrap' ) || print "Bail out!
";
    use_ok( 'App::Standby::Cmd::Command' ) || print "Bail out!
";
    use_ok( 'App::Standby::Service::HTTP' ) || print "Bail out!
";
    use_ok( 'App::Standby::Service::MS' ) || print "Bail out!
";
    use_ok( 'App::Standby::Service::Pingdom' ) || print "Bail out!
";
    use_ok( 'App::Standby::Cmd' ) || print "Bail out!
";
    use_ok( 'App::Standby::DB' ) || print "Bail out!
";
    use_ok( 'App::Standby::Frontend' ) || print "Bail out!
";
    use_ok( 'App::Standby::Group' ) || print "Bail out!
";
    use_ok( 'App::Standby::Service' ) || print "Bail out!
";
}

diag( "Testing App::Standby $App::Standby::VERSION, Perl $], $^X" );
