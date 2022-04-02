use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

open my $fh, '<', '/tmp/ipc_shareable_ipc_count' or die "Can't open tmp file: $!";

my $start_segs = <$fh>;

close $fh;

is unlink('/tmp/ipc_shareable_ipc_count'), 1, "Removed temp file ok";

my $segs = `ipcs -m | wc -l`;

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

is $segs, $start_segs, "Started and ended test suite with $start_segs ok";

done_testing();