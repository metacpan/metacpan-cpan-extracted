package t::Acme::Spinodal::Utils;

use strict;
use warnings;
use v5.12;

use Data::Dumper;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'Acme::Spinodal::Utils' ) || print "Bail out!\n";
}

diag("Testing Util $Acme::Spinodal::Utils::VERSION, Perl $], $^X");

ok( defined &Acme::Spinodal::Utils::sum, '&Acme::Spinodal::Utils::sum is defined' );

{    # sum tests
    { # No args
    my $total;
        eval { $total = Acme::Spinodal::Utils::sum() };
        my $err = $@;
        is( $total, 0, "Checking that the total is zero when no args are given." );
        is( $err, '', "Checking no error was returned.")
    }
    
    { # Expected total
    my $total;
        eval { $total = Acme::Spinodal::Utils::sum( qw(1 2 3 4) ) };
        my $err = $@;
        is( $total, 10, "Checking that the correct total is returned." );
        is( $err, '', "Checking no error was returned.")
    }
    
    { # Strange args
        throws_ok { Acme::Spinodal::Utils::sum( qw( 1 2 3 Blarg!) ) } qr/does not appear to be a valid number!/, 'Checking an error was returned.';
    }
    
    { # some more intersting numbers
    my $total;
        eval { $total = Acme::Spinodal::Utils::sum( qw( 5 -273.15 3.141592 12321 0 -12.34e56) ) };
        my $err = $@;
        is( $total, -1.234e+57, "Checking that the correct total is returned." );
        is( $err, '', "Checking no error was returned.")
    }
}


done_testing();