use 5.006;
use strict;
use warnings;

use Test::More;

my $segs;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
    $segs = `ipcs -m | wc -l`;
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

    use_ok( 'Async::Event::Interval' ) || print "Bail out!\n";
}

use Async::Event::Interval;
use IPC::Shareable;

diag( "Testing Async::Event::Interval $Async::Event::Interval::VERSION, Perl $], $^X" );

print "Starting with $segs segments\n";

# Store existing segments in a shared hash to test against
# at conclusion of test suite run

tie my %store, 'IPC::Shareable', {key => 'async_tests', create => 1};

$store{segs} = $segs;

warn "Segs After: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

my $e = Async::Event::Interval->new(0, sub {});

done_testing;