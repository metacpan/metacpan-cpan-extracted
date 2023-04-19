#! perl

use Test2::V0;
use File::Slurper qw(read_text);

SKIP: {
    skip "Not testing via CPAN" unless $ENV{AUTOMATED_TESTING};

    my $log = read_text( "config.log" );
    ok( $log, "show config.log" ) and diag( $log );
}

done_testing;
