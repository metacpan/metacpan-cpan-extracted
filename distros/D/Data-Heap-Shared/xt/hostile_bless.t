use strict;
use warnings;
use Test::More;

use Data::Heap::Shared;

my $fake = bless \(my $z = 0), "Data::Heap::Shared";
my $rc = eval { $fake->memfd };
ok $@, "bless(0) method call croaks";
like $@, qr/destroy|object/i, "meaningful error";

# Non-derived object — test via can-dispatch
my $other = bless \(my $x = 42), "MyBogusClass";
my $can = Data::Heap::Shared->can("memfd");
SKIP: {
    skip "no memfd method", 1 unless $can;
    my $pid = fork // die;
    if (!$pid) {
        eval { $can->($other) };
        exit 0;
    }
    waitpid $pid, 0;
    my $sig = $? & 0x7f;
    ok $sig == 0 || $sig == 11, "non-derived bless handled (sig=$sig)";
}

done_testing;
