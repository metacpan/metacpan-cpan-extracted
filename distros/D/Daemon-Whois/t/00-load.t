#!perl -T

#use Test::More tests => 1;
use Test::More 'no_plan';

BEGIN {
    SKIP: {
        if ( !eval { require Daemon::whois; 1 } ) {
            skip( 'You probably need to be root to test this.', 1);
        } else {
            use_ok( 'Daemon::Whois' ) || print "Bail out!  ";
        }
    }

}

diag( "Testing Daemon::Whois $Daemon::Whois::VERSION, Perl $], $^X" );
