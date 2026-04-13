use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Log::Shared;

my $log = Data::Log::Shared->new(undef, 4096);
ok $log, 'created';
is $log->entry_count, 0;
is $log->tail_offset, 0;
is $log->data_size, 4096;
ok $log->available > 0;

# append
my $off1 = $log->append("hello");
ok defined $off1, 'append returned offset';
is $off1, 0, 'first entry at offset 0';
is $log->entry_count, 1;

my $off2 = $log->append("world");
ok defined $off2;
is $log->entry_count, 2;

my $off3 = $log->append("third entry here");
is $log->entry_count, 3;

# read_entry
my ($data, $next) = $log->read_entry(0);
is $data, "hello", 'read first entry';
ok $next > 0;

($data, $next) = $log->read_entry($next);
is $data, "world", 'read second entry';

($data, $next) = $log->read_entry($next);
is $data, "third entry here", 'read third entry';

# read past end
my @r = $log->read_entry($next);
is scalar @r, 0, 'read past end returns empty list';

# each_entry
my @entries;
$log->each_entry(sub { push @entries, $_[0] });
is_deeply \@entries, ["hello", "world", "third entry here"], 'each_entry';

# each_entry from offset
@entries = ();
$log->each_entry(sub { push @entries, $_[0] }, $off2);
is_deeply \@entries, ["world", "third entry here"], 'each_entry from offset';

# fill log to capacity
$log->reset;
is $log->entry_count, 0, 'reset';
is $log->tail_offset, 0;

my $n = 0;
while (defined $log->append("x" x 100)) { $n++ }
ok $n > 0, "appended $n entries before full";
ok !defined $log->append("x" x 100), 'append fails when no room';

# empty string rejected
eval { $log->append("") };
like $@, qr/empty/, 'empty append croaks';

# cross-process
$log->reset;
$log->append("from parent");

my $pid = fork // die;
if ($pid == 0) {
    my ($d) = $log->read_entry(0);
    _exit($d eq "from parent" ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'child read parent entry';

# concurrent append
$log->reset;
my @pids;
for my $w (1..4) {
    my $p = fork // die;
    if ($p == 0) {
        for (1..50) {
            $log->append(sprintf "worker=%d seq=%d", $w, $_);
        }
        _exit(0);
    }
    push @pids, $p;
}
waitpid($_, 0) for @pids;
is $log->entry_count, 200, '4 workers x 50 = 200 entries';

# all entries readable
my $count = 0;
$log->each_entry(sub { $count++ });
is $count, 200, 'all 200 entries readable';

# wait_for with timeout
$log->reset;
my $t0 = time;
ok !$log->wait_for(0, 0.1), 'wait_for timeout (no entries)';
ok time - $t0 < 2;

# wait_for wakeup
$pid = fork // die;
if ($pid == 0) {
    select(undef, undef, undef, 0.05);
    $log->append("wakeup");
    _exit(0);
}
ok $log->wait_for(0, 2.0), 'wait_for woke on append';
is $log->entry_count, 1;
waitpid($pid, 0);

# stats
my $s = $log->stats;
ok ref $s eq 'HASH';
ok $s->{appends} > 0;
ok exists $s->{data_size};
ok exists $s->{tail};
ok exists $s->{count};
ok exists $s->{available};

# --- file-backed persistence ---

my $path = tmpnam() . '.shm';
{
    my $fl = Data::Log::Shared->new($path, 4096);
    $fl->append("persist1");
    $fl->append("persist2");
    is $fl->path, $path;
}
{
    my $fl = Data::Log::Shared->new($path, 4096);
    is $fl->entry_count, 2, 'file persistence';
    my ($d) = $fl->read_entry(0);
    is $d, "persist1", 'persisted data';
}
unlink $path;

# --- memfd / new_from_fd ---

my $ml = Data::Log::Shared->new_memfd("test_log", 4096);
ok $ml, 'memfd created';
my $mfd = $ml->memfd;
ok $mfd >= 0;
$ml->append("via memfd");

my $ml2 = Data::Log::Shared->new_from_fd($mfd);
my ($md) = $ml2->read_entry(0);
is $md, "via memfd", 'data via new_from_fd';

# --- eventfd ---

my $el = Data::Log::Shared->new(undef, 1024);
my $efd = $el->eventfd;
ok $efd >= 0, 'eventfd';
ok $el->notify;
my $ec = $el->eventfd_consume;
is $ec, 1, 'eventfd_consume';

# --- sync / unlink ---

my $upath = tmpnam() . '.shm';
my $ul = Data::Log::Shared->new($upath, 1024);
$ul->append("test");
eval { $ul->sync };
ok !$@, 'sync ok';
$ul->unlink;
ok !-f $upath, 'unlink removed file';

# --- binary data ---

$log->reset;
my $bin = "a\x00b\x00c\xff\xfe";
my $boff = $log->append($bin);
ok defined $boff;
my ($bd) = $log->read_entry($boff);
is $bd, $bin, 'binary data preserved';

# --- truncate ---

$log->reset;
my $off1t = $log->append("entry one");
my $off2t = $log->append("entry two");
my $off3t = $log->append("entry three");
is $log->entry_count, 3;
is $log->truncation, 0, 'truncation starts at 0';

# truncate past first entry — first becomes unreadable
$log->truncate($off2t);
is $log->truncation, $off2t, 'truncation advanced';

# read_entry on truncated offset returns nothing
my @tr = $log->read_entry($off1t);
is scalar @tr, 0, 'truncated entry unreadable';

# entries at/after truncation still readable
my ($td2) = $log->read_entry($off2t);
is $td2, "entry two", 'entry at truncation readable';
my ($td3) = $log->read_entry($off3t);
is $td3, "entry three", 'entry after truncation readable';

# each_entry skips truncated entries
my @tent;
$log->each_entry(sub { push @tent, $_[0] }, 0);
is_deeply \@tent, ["entry two", "entry three"], 'each_entry skips truncated';

# truncation can only advance, not retreat
$log->truncate(0);
is $log->truncation, $off2t, 'truncation cannot retreat';

# truncate all — log appears empty to readers
$log->truncate($log->tail_offset);
@tent = ();
$log->each_entry(sub { push @tent, $_[0] });
is scalar @tent, 0, 'fully truncated = no readable entries';

# but space is NOT reclaimed — append still works until log fills
ok defined $log->append("after truncate"), 'append after truncate works';
is $log->entry_count, 4, 'entry_count includes truncated';

# cross-process truncate
$log->reset;
$log->append("before");
my $mid = $log->append("middle");
$log->append("after");

$pid = fork // die;
if ($pid == 0) {
    $log->truncate($mid);
    _exit(0);
}
waitpid($pid, 0);
is $log->truncation, $mid, 'cross-process truncate';
my @post;
$log->each_entry(sub { push @post, $_[0] }, 0);
is_deeply \@post, ["middle", "after"], 'cross-process truncate visible';

done_testing;
