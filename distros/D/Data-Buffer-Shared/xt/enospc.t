use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Simulate ENOSPC by setting RLIMIT_FSIZE to a small value and asking for
# a buffer larger than that. Verify clean failure with no partial mmap.
# Skip if unsupported.

eval { require BSD::Resource };
plan skip_all => "BSD::Resource required" if $@;

use Data::Buffer::Shared::I64;

$SIG{XFSZ} = 'IGNORE';   # don't terminate when we hit the limit
BSD::Resource::setrlimit(BSD::Resource::RLIMIT_FSIZE(), 4096, 4096)
    or plan skip_all => "can't setrlimit FSIZE";

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/toobig.shm";

# Asking for 1M I64 = 8MB, well past the 4KB limit
my $b = eval { Data::Buffer::Shared::I64->new($path, 1_000_000) };
my $err = $@;
ok !defined($b), 'creation failed (expected)';
like $err, qr/(ftruncate|mmap|truncate|File too large|size)/i, 'error mentions size/ftruncate/mmap';
ok !-s $path || -s $path <= 4096, 'no partial file larger than limit';

done_testing;
