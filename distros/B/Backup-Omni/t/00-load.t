#!perl -T

use Test::More tests => 11;

BEGIN {
    use_ok( 'Backup::Omni::Base' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Class' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Constants' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Exception' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Restore::Filesystem::Single' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Session::Filesystem' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Session::Messages' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Session::Monitor' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Session::Results' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni::Utils' ) || print "Bail out!\n";
    use_ok( 'Backup::Omni' ) || print "Bail out!\n";
}

diag( "Testing Backup::Omni $Backup::Omni::VERSION, Perl $], $^X" );
