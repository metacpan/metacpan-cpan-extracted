use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Data::Intern::Shared;

my $dir = tempdir(CLEANUP => 1);
my $capacity = 1280;

for my $partial (0, 1) {
    for my $first (qw(count intern)) {
        my $path = "$dir/$partial-$first.intern";
        {
            my $in = Data::Intern::Shared->new($path, $capacity, 65536);
            $in->intern("old-$_") for 0 .. $capacity - 1;
        }
        my $pid = fork // die "fork: $!";
        _exit(0) unless $pid;
        waitpid($pid, 0) == $pid or die "waitpid: $!";

        # Model a dead writer before or partway through clearing the hash.
        open my $fh, '+<', $path or die "open: $!";
        binmode $fh;
        read($fh, my $header, 256) == 256 or die "read header: $!";
        substr($header, 28, 4, pack('L<', 1));
        substr($header, 72, 4, pack('L<', 0x80000000 | $pid));
        if ($partial) {
            my $hash_off = unpack('Q<', substr($header, 48, 8));
            my $slots = unpack('L<', substr($header, 12, 4));
            seek($fh, $hash_off, 0) or die "seek hash: $!";
            print {$fh} "\0" x ($slots * 2) or die "write hash: $!";
        }
        seek($fh, 0, 0) or die "seek header: $!";
        print {$fh} $header or die "write header: $!";
        close $fh or die "close: $!";

        subtest "interrupted clear, partial=$partial, first=$first" => sub {
            my $in = Data::Intern::Shared->new($path, $capacity, 65536);
            if ($first eq 'count') {
                is $in->count, 0, 'reader recovers the empty table';
                is $in->arena_used, 0, 'reader recovers the empty arena';
            } else {
                is $in->intern('new-0'), 0, 'writer recovers before assigning an id';
            }
            my $dense = 1;
            for my $i (0 .. $capacity - 1) {
                my $id = $in->intern("new-$i");
                $dense = 0 unless defined($id) && $id == $i;
            }
            ok $dense, 'refill assigns every id exactly once';
            is $in->count, $capacity, 'refill reaches full capacity';
            my $roundtrip = 1;
            for my $i (0 .. $capacity - 1) {
                my $id = $in->id_of("new-$i");
                $roundtrip = 0 unless defined($id) && $id == $i
                    && $in->string($i) eq "new-$i";
            }
            ok $roundtrip, 'every refilled key remains reachable';
            ok !$in->exists('old-1279'), 'cleared keys stay absent';
            $in->clear;
            is $in->count, 0, 'another clear succeeds';
            is $in->intern('final'), 0, 'ids restart after another clear';
        };
    }
}

done_testing;
