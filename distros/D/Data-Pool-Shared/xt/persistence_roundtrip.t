use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Digest::SHA qw(sha256_hex);

# Byte-identity: create file-backed pool, populate state, destroy handle,
# checksum raw file. Reopen, compare bit-for-bit. Catches header fields
# that drift after close (e.g. process-local timestamps mistakenly in mmap).

use Data::Pool::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pool');
close $fh;

# Populate
{
    my $p = Data::Pool::Shared::I64->new($path, 16);
    for my $i (0..5) {
        my $s = $p->alloc;
        $p->set($s, $i * 1000);
    }
    $p->sync;
}
# Handle destroyed

my $sz = -s $path;
ok $sz > 0, "file exists ($sz bytes)";

open(my $fh1, '<', $path) or die;
binmode $fh1;
my $raw1 = do { local $/; <$fh1> };
close $fh1;
my $sha1 = sha256_hex($raw1);
diag "checksum after first close: $sha1";

# Reopen without modification, sync, close; checksum must match.
{
    my $p = Data::Pool::Shared::I64->new($path, 16);
    $p->sync;
}

open(my $fh2, '<', $path) or die;
binmode $fh2;
my $raw2 = do { local $/; <$fh2> };
close $fh2;
my $sha2 = sha256_hex($raw2);

is $sha2, $sha1, "byte-identical after read-only reopen+sync";

# Verify data contents on third reopen
{
    my $p = Data::Pool::Shared::I64->new($path, 16);
    is $p->used, 6, "used count persisted";
    my @vals;
    for my $s (0..15) {
        push @vals, $p->get($s) if $p->is_allocated($s);
    }
    is_deeply [sort { $a <=> $b } @vals], [0,1000,2000,3000,4000,5000],
        "values persisted exactly";
}

done_testing;
