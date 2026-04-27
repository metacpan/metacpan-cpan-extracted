use strict;
use warnings;
use Test::More;

# Cross-module fd rejection: each module's new_from_fd must reject fds
# from OTHER shared modules in the family (magic mismatch), not segfault.

use Data::Pool::Shared;

my $pool = Data::Pool::Shared::I64->new_memfd("xm-pool", 8);
my $pool_fd = $pool->memfd;

sub try_reject {
    my ($class, $ctor, @args) = @_;
    SKIP: {
        skip "$class->$ctor not available (XS not loaded from this build dir)", 2
            unless $class->can($ctor);
        my $r = eval { $class->$ctor(@args) };
        my $err = $@;
        ok !$r, "$class\->$ctor rejects foreign fd";
        like $err || '', qr/invalid|magic|incompatible|too small/i,
            "$class: meaningful error: " .
            (length($err // '') > 80 ? substr($err,0,80).'...' : ($err // '(none)'));
    }
}

SKIP: { eval { require Data::Queue::Shared; 1 } or skip "Queue not installed", 2;
    try_reject("Data::Queue::Shared::Int", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::Deque::Shared; 1 } or skip "Deque not installed", 2;
    try_reject("Data::Deque::Shared::Int", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::Stack::Shared; 1 } or skip "Stack not installed", 2;
    try_reject("Data::Stack::Shared::Int", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::Graph::Shared; Data::Graph::Shared->import; 1 }
        or skip "Graph not installed", 2;
    try_reject("Data::Graph::Shared", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::Buffer::Shared::I64; 1 } or skip "Buffer not installed", 2;
    try_reject("Data::Buffer::Shared::I64", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::HashMap::Shared; Data::HashMap::Shared->import;
              require Data::HashMap::Shared::II; 1 }
        or skip "HashMap not installed", 2;
    try_reject("Data::HashMap::Shared::II", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::PubSub::Shared::Int; 1 } or skip "PubSub not installed", 2;
    try_reject("Data::PubSub::Shared::Int", "new_from_fd", $pool_fd);
}
SKIP: { eval { require Data::ReqRep::Shared; 1 } or skip "ReqRep not installed", 2;
    try_reject("Data::ReqRep::Shared", "new_from_fd", $pool_fd);
}

# Reverse: variant mismatch within Pool family itself
my $raw_pool = Data::Pool::Shared->new_memfd("xm-raw", 4, 8);
my $raw_fd = $raw_pool->memfd;
try_reject("Data::Pool::Shared::I64", "new_from_fd", $raw_fd);

done_testing;
