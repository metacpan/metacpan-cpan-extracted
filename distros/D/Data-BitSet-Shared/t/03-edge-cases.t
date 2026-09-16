use strict;
use warnings;
use Test::More;

use Data::BitSet::Shared;

# Capacity 1
{
    my $b = Data::BitSet::Shared->new_memfd("e1", 1);
    is $b->capacity, 1, "capacity=1";
    $b->set(0);
    ok $b->test(0), "bit 0 set";
    eval { $b->set(1) };
    like $@, qr/out of range|overflow|bit/i, "set out-of-range croaks";
}

# Capacity exactly at word boundary
{
    my $b = Data::BitSet::Shared->new_memfd("e2", 64);
    $b->set($_) for 0..63;
    is $b->count, 64, "fully-set 64-bit word";
    ok !$b->test(63) == 0, "last bit set";
}

# Capacity 65 (spans words)
{
    my $b = Data::BitSet::Shared->new_memfd("e3", 65);
    $b->set(63);
    $b->set(64);
    is $b->count, 2, "bits across word boundary";
}

# Double set / double clear is idempotent
{
    my $b = Data::BitSet::Shared->new_memfd("e4", 16);
    is $b->set(5), 0, "first set returns 0 (old value)";
    is $b->set(5), 1, "second set returns 1";
    is $b->clear(5), 1, "first clear returns 1";
    is $b->clear(5), 0, "second clear returns 0";
}

# Empty bitset
{
    my $b = Data::BitSet::Shared->new_memfd("e5", 64);
    is $b->count, 0, "empty count=0";
    ok !$b->any, "any=false on empty";
}

# Padding bits in the last word do not affect count/any/none
{
    use File::Temp qw(tempfile);
    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;
    my $b = Data::BitSet::Shared->new($filename, 10);
    is $b->count, 0, "initial count=0";
    # Poke a padding bit (bit 15) directly into the file
    open my $f, '+<:raw', $filename or die $!;
    seek $f, 128, 0; # data_off = 128
    my $w;
    read $f, $w, 8;
    my $val = unpack('Q', $w);
    $val |= (1 << 15); # bit 15 >= cap (10)
    seek $f, 128, 0;
    print $f pack('Q', $val);
    close $f;
    # Re-open and verify count / any ignore the padding bit
    my $b2 = Data::BitSet::Shared->new($filename, 10);
    is $b2->count, 0, "count ignores padding bits beyond capacity";
    ok !$b2->any, "any ignores padding bits beyond capacity";
    ok $b2->none, "none ignores padding bits beyond capacity";
}

done_testing;
