use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

# stats() exposes header fields on every variant
{
    my $b = Data::Buffer::Shared::I64->new_anon(8);
    my $s = $b->stats;
    is ref($s), 'HASH', 'stats returns hashref';
    is $s->{capacity}, 8, 'stats.capacity';
    is $s->{elem_size}, 8, 'stats.elem_size (I64 = 8 bytes)';
    ok $s->{mmap_size} > 0, 'stats.mmap_size';
    ok defined $s->{variant_id}, 'stats.variant_id';
    ok defined $s->{recoveries}, 'stats.recoveries';
}

{
    my $b = Data::Buffer::Shared::F64->new_anon(4);
    my $s = $b->stats;
    is $s->{capacity}, 4;
    is $s->{elem_size}, 8, 'F64 elem_size';
}

# sync() on file-backed
{
    my $dir = tempdir(CLEANUP => 1);
    my $path = "$dir/buf.shm";
    my $b = Data::Buffer::Shared::I64->new($path, 16);
    $b->set(0, 42);
    eval { $b->sync };
    ok !$@, 'sync on file-backed does not croak';
    $b->unlink;
    ok !-e $path, 'unlink removed file';
}

# sync() on anonymous — msync on MAP_ANONYMOUS is a no-op but must not error
{
    my $b = Data::Buffer::Shared::I64->new_anon(4);
    eval { $b->sync };
    ok !$@, 'sync on anonymous is harmless';
}

# sync() on memfd
{
    my $b = Data::Buffer::Shared::I64->new_memfd("sync_test", 4);
    eval { $b->sync };
    ok !$@, 'sync on memfd-backed ok';
}

# memfd alias for fd()
{
    my $b = Data::Buffer::Shared::I64->new_memfd("alias_test", 4);
    is $b->memfd, $b->fd, 'memfd() is an alias for fd() on all variants';
}

done_testing;
