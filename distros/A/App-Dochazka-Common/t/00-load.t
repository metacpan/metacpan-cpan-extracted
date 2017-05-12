#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'App::Dochazka::Common' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Activity' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Employee' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Interval' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Lock' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Privhistory' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Schedhistory' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Schedintvls' ) || print "Bail out!\n";
    use_ok( 'App::Dochazka::Common::Model::Schedule' ) || print "Bail out!\n";
}

done_testing;

