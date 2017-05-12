use strict;
use warnings;

BEGIN {
    if ( $ENV{NO_NETWORK_TESTING} ) {
        print "1..0 # SKIP: Network acess required for this test\n";
        exit 0;
    }
}

use Test::More;
use Time::HiRes qw( gettimeofday tv_interval );

use CPAN::Testers::TailLog;

sub timeit {
    my $start  = [gettimeofday];
    my $result = $_[0]->();
    return tv_interval( $start, [gettimeofday] );
}

my $client = CPAN::Testers::TailLog->new();

my $result;
my $first  = timeit( sub { $result = $client->get_all() } );
my $second = timeit( sub { $result = $client->get_all() } );

note "First: $first\n";
note "Second: $second\n";
cmp_ok( $first, ">=", $second, "First pass should be the slowest" );

done_testing;
