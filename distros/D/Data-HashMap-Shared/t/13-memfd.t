use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# new_memfd + new_from_fd round-trip (II variant)
{
    my $m = Data::HashMap::Shared::II->new_memfd("mtest", 100);
    ok $m, 'II new_memfd created';
    ok $m->memfd >= 0, 'memfd accessor returns non-negative fd';
    ok !defined $m->path, 'memfd has no path';

    $m->put(1, 42);
    $m->put(2, 99);

    my $fd = POSIX::dup($m->memfd);
    my $m2 = Data::HashMap::Shared::II->new_from_fd($fd);
    is $m2->size, 2, 'new_from_fd sees existing entries';
    is $m2->get(1), 42;
    is $m2->get(2), 99;
    POSIX::close($fd);
}

# SS variant (has arena) — ensure arena survives the reopen
{
    my $m = Data::HashMap::Shared::SS->new_memfd("mss", 64);
    $m->put("hello", "world");
    my $fd = POSIX::dup($m->memfd);
    my $m2 = Data::HashMap::Shared::SS->new_from_fd($fd);
    is $m2->get("hello"), "world", 'SS memfd: arena survives reopen';
    POSIX::close($fd);
}

# Fork inherits the mapping via shared mmap
{
    my $m = Data::HashMap::Shared::II->new_memfd("mfork", 100);
    $m->put(7, 7);
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $m->put(8, 8);
        _exit(0);
    }
    waitpid $pid, 0;
    is $m->size, 2, 'child write visible in parent (shared mmap)';
}

# Reject a garbage fd
{
    pipe my ($r, $w) or die;
    my $m = eval { Data::HashMap::Shared::II->new_from_fd(fileno($r)) };
    ok !$m, 'random fd rejected';
    like $@, qr/too small|magic|fstat/i, 'error names validation failure';
    close $r; close $w;
}

# sync() msync on memfd-backed map
{
    my $m = Data::HashMap::Shared::II->new_memfd("sync_hm", 16);
    $m->put(1, 1);
    eval { $m->sync };
    ok !$@, 'sync on memfd-backed map';
}

done_testing;
