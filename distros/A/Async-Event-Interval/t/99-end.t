use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
    use_ok( 'Async::Event::Interval' ) || print "Bail out!\n";
}

use IPC::Shareable;

if (! $ENV{CI_TESTING}) {
    done_testing();
    exit;
}

tie my %store, 'IPC::Shareable', { key => 'async_tests', destroy => 1 };

my $start_segs = $store{segs};

IPC::Shareable::clean_up_all;

open my $fh, '>', '/tmp/ipc_shareable_ipc_count' or die "Can't open tmp file: $!";

print $fh $start_segs;

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();