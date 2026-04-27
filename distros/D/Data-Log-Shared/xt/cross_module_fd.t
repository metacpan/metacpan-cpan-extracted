use strict;
use warnings;
use Test::More;

use Data::Log::Shared;

my $b = Data::Log::Shared->new_memfd("xm", 4096);
my $fd = $b->memfd;

sub try_reject {
    my ($class, $ctor, @args) = @_;
    SKIP: {
        skip "$class->$ctor not available", 2 unless $class->can($ctor);
        my $r = eval { $class->$ctor(@args) };
        my $err = $@;
        ok !$r, "$class\->$ctor rejects foreign fd";
        like $err || '', qr/invalid|magic|incompatible|too small/i, "meaningful error";
    }
}

SKIP: { eval { require Data::Pool::Shared; 1 } or skip "Pool not installed", 2;
    try_reject("Data::Pool::Shared::I64", "new_from_fd", $fd);
}
SKIP: { eval { require Data::Queue::Shared; Data::Queue::Shared->import; 1 } or skip "Queue not installed", 2;
    try_reject("Data::Queue::Shared::Int", "new_from_fd", $fd);
}

done_testing;
