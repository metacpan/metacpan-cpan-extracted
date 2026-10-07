use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# The croaks carry strerror in the process's locale, and "$!" is always English.
$ENV{LC_ALL} = 'C';
POSIX::setlocale(POSIX::LC_ALL(), 'C');

# DATA_HASHMAP_SHARED_SPARSE=0 allocates the whole segment at creation.  Only
# tmpfs is sure to show that in st_blocks: a compressing filesystem stores the
# no-fallocate fallback's zero bytes as holes.

plan skip_all => 'Linux only' unless $^O eq 'linux';
plan skip_all => 'no writable /dev/shm' unless -d '/dev/shm' && -w '/dev/shm';
my $dir = tempdir(DIR => '/dev/shm', CLEANUP => 1);

sub allocated { (stat $_[0])[12] * 512 }
sub open_fds  { opendir my $d, '/proc/self/fd' or return -1; scalar grep !/^\./, readdir $d }
sub zero_file { my ($p, $size) = @_; open my $fh, '>', $p or die "$p: $!"; truncate $fh, $size or die $!; close $fh }

Data::HashMap::Shared::SS->new("$dir/sparse", 1000);
my $size = -s "$dir/sparse";
cmp_ok allocated("$dir/sparse"), '<', $size / 2, 'by default the segment is sparse';

my $memfd = Data::HashMap::Shared::SS->new_memfd('sparse', 1000);
my $mf = '/proc/self/fd/' . $memfd->memfd;
cmp_ok allocated($mf), '<', (-s $mf) / 2, 'so is a memfd';

# a file an interrupted create left behind: all zero and full size
zero_file("$dir/left", $size);
my $adopted = Data::HashMap::Shared::SS->new("$dir/left", 1000);
ok $adopted->put(k => 'v'), 'a file left by an interrupted create is recreated';
cmp_ok allocated("$dir/left"), '<', $size / 2, '...without allocating it to check that it is blank';

{
    local $ENV{DATA_HASHMAP_SHARED_SPARSE} = 0;

    my $m = Data::HashMap::Shared::SS->new("$dir/full", 1000);
    cmp_ok allocated("$dir/full"), '>=', -s "$dir/full", 'SPARSE=0 allocates every block';
    ok $m->put(k => 'v') && $m->get('k') eq 'v', 'the reserved map works';

    my $rm = Data::HashMap::Shared::SS->new_memfd('full', 1000);
    my $rf = '/proc/self/fd/' . $rm->memfd;
    cmp_ok allocated($rf), '>=', -s $rf, '...and every block of a memfd';

    zero_file("$dir/left2", $size);
    Data::HashMap::Shared::SS->new("$dir/left2", 1000);
    cmp_ok allocated("$dir/left2"), '>=', $size, '...and of a recreated interrupted create';

    my $fds = open_fds();
    my $set = Data::HashMap::Shared::II->new_sharded("$dir/set", 4, 1000);
    my @short = grep { allocated("$dir/set.$_") < -s "$dir/set.$_" } 0 .. 3;
    is "@short", '', 'every shard of a new set is allocated';
    is open_fds(), $fds, 'the shard descriptors held during creation are closed';

    # a shard still locked by its creator would block this attach forever
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        alarm 10;
        my $again = Data::HashMap::Shared::II->new_sharded("$dir/set", 4, 1000);
        POSIX::_exit($again->put(1, 1) ? 0 : 1);
    }
    waitpid $pid, 0;
    is $?, 0, 'another process attaches the set: its shard locks were released';
    is $set->get(1), 1, '...and writes to it';

    # one descriptor per created shard: a low limit refuses the set
    my $child = "$dir/emfile.pl";
    open my $fh, '>', $child or die $!;
    print $fh 'use Data::HashMap::Shared::II; ',
        'print eval { Data::HashMap::Shared::II->new_sharded($ARGV[0], 64, 100) } ? "created" : $@;';
    close $fh;
    my $emfile = do { local $! = POSIX::EMFILE(); "$!" };
    my $out = `sh -c 'ulimit -n 24 && exec "\$@"' sh $^X @{[ map "-I$_", @INC ]} $child $dir/em 2>&1`;
    like $out, qr/\Q$emfile\E/, 'SPARSE=0 new_sharded past ulimit -n croaks';
    my @made = glob "$dir/em.*";
    cmp_ok scalar @made, '>', 1, '...after creating some of the shards';
    my @kept = grep { allocated($_) > 0 } @made;
    is "@kept", '', '...and leaves those empty';
}
my $em = Data::HashMap::Shared::II->new_sharded("$dir/em", 64, 100);
ok $em->put(1, 1), 'and the set is created afresh by the next open';

done_testing;
