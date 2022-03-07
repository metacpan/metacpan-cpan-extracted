use 5.006;
use strict;
use warnings;

use IPC::Shareable;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Async::Event::Interval' ) || print "Bail out!\n";
}

diag( "Testing Async::Event::Interval $Async::Event::Interval::VERSION, Perl $], $^X" );

my $segs = IPC::Shareable::ipcs();

print "Starting with $segs segments\n";

# Store existing segments in a shared hash to test against
# at conclusion of test suite run

tie my %store, 'IPC::Shareable', {key => 'async_tests', create => 1};

$store{segs} = $segs;

