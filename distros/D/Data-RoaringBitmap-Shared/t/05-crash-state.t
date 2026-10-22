use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::RoaringBitmap::Shared;

my $dir = tempdir(CLEANUP => 1);
my $dead = fork // die "fork: $!";
_exit(0) unless $dead;
waitpid($dead, 0);

sub patch {
    my ($fh, $off, $bytes) = @_;
    sysseek($fh, $off, 0) == $off or die "seek: $!";
    syswrite($fh, $bytes) == length($bytes) or die "write: $!";
}

# clear's memset can be interrupted after the offset, before the type is zeroed.
for my $dense (0, 1) {
    for my $prefix (4, 8, 12) {
        my $path = "$dir/clear-$dense-$prefix.rb";
        {
            my $bm = Data::RoaringBitmap::Shared->new($path, 4);
            $bm->add_many($dense ? [0 .. 5000] : [1, 3]);
            $bm->add(65541);
        }
        open my $fh, '+<:raw', $path or die $!;
        sysseek($fh, 56, 0) == 56 or die $!;
        sysread($fh, my $offset, 8) == 8 or die $!;
        patch($fh, unpack('Q<', $offset), "\0" x $prefix);
        patch($fh, 72, pack('V', 0x80000000 | $dead));
        close $fh or die $!;

        my $bm = Data::RoaringBitmap::Shared->new($path, 4);
        is $bm->cardinality, 1, "partial clear ($dense/$prefix): recount";
        is_deeply $bm->to_array, [65541], 'only the untouched bucket survives';
        is $bm->stats->{buckets_used}, 1, 'cleared bucket is unpublished';
        is $bm->min, 65541, 'min ignores the cleared bucket';
        is $bm->add(7), 1, 'cleared bucket can be allocated again';
        is $bm->add(131081), 1, 'all remaining capacity is reusable';
        ok !eval { $bm->add(196609); 1 }, 'full pool refuses a new bucket';
        like $@, qr/exhausted/, 'capacity failure is reported';
        is_deeply $bm->to_array, [7, 65541, 131081], 'no sentinel slot becomes a container';
        is $bm->remove(7), 1, 'recovered bucket can be removed';
        is $bm->add(196609), 1, 'freed slot is reused';
        is_deeply $bm->to_array, [65541, 131081, 196609], 'reused slots stay independent';
        undef $bm;
        unlink $path or die $!;
    }
}

# A partial slot index can still name a live slot; the clear marker must win.
for my $stage (qw(before partial erased reset)) {
    my $path = "$dir/marked-$stage.rb";
    {
        my $bm = Data::RoaringBitmap::Shared->new($path, 260);
        $bm->add_many([map { ($_ << 16) | 7 } 0 .. 256]);
    }
    open my $fh, '+<:raw', $path or die $!;
    sysseek($fh, 56, 0) == 56 or die $!;
    sysread($fh, my $offset, 8) == 8 or die $!;
    my $buckets = unpack('Q<', $offset);
    patch($fh, 100, pack('V', 65537));
    patch($fh, $buckets + 256 * 16, "\0") if $stage eq 'partial';
    patch($fh, $buckets, "\0" x (65536 * 16)) if $stage eq 'erased' || $stage eq 'reset';
    patch($fh, 12, pack('V', 1)) if $stage eq 'reset';
    patch($fh, 72, pack('V', 0x80000000 | $dead));
    close $fh or die $!;

    my $bm = Data::RoaringBitmap::Shared->new($path, 260);
    is $bm->cardinality, 0, "$stage: interrupted clear is completed";
    is_deeply $bm->to_array, [], 'no old bucket survives the marked clear';
    is $bm->stats->{buckets_used}, 0, 'all cleared buckets are unpublished';
    is $bm->stats->{containers_used}, 1, 'clear resets the high-water mark';
    my @values = map { ($_ << 16) | 9 } 0 .. 258;
    is $bm->add_many(\@values), 259, 'all usable slots can be allocated';
    is_deeply $bm->to_array, \@values, 'new containers do not alias old slots';
    ok !eval { $bm->add((259 << 16) | 9); 1 }, 'full pool still rejects allocation';
    like $@, qr/exhausted/, 'pool exhaustion is reported';
    undef $bm;
    unlink $path or die $!;
}

done_testing;
