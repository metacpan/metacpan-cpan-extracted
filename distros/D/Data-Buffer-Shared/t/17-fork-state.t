use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Select;
use POSIX qw(_exit);
use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

my $dir = tempdir(CLEANUP => 1);
my @cases = (
    [I64 => set_slice => sub { $_[0]->set_slice(0, 7, 7) }],
    [I64 => fill      => sub { $_[0]->fill(7); 1 }],
    [I64 => clear     => sub { $_[0]->clear; 1 }],
    [I64 => set_raw   => sub { $_[0]->set_raw(0, pack('q<', 7)) }],
    [I64 => slice     => sub { my @v = $_[0]->slice(0, 1); $v[0] == 9 }],
    [I64 => get_raw   => sub { unpack('q<', $_[0]->get_raw(0, 8)) == 9 }],
    [F64 => fill      => sub { $_[0]->fill(7); 1 }],
    [Str => set       => sub { $_[0]->set(0, 'child') }],
    [Str => set_slice => sub { $_[0]->set_slice(0, 'child') }],
    [Str => fill      => sub { $_[0]->fill('child'); 1 }],
    [Str => get       => sub { $_[0]->get(0) eq 'after' }],
    [Str => slice     => sub { my @v = $_[0]->slice(0, 1); $v[0] eq 'after' }],
);

for my $case (@cases) {
    my ($type, $op, $code) = @$case;
    my $class = "Data::Buffer::Shared::$type";
    my $buf = $class->new_anon(2, $type eq 'Str' ? (16) : ());
    $buf->fill($type eq 'Str' ? 'before' : 1);
    $buf->lock_wr;
    pipe(my $ready_r, my $ready_w) or die "pipe: $!";
    pipe(my $done_r, my $done_w) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        close $ready_r;
        close $done_r;
        syswrite($ready_w, '1') == 1 or _exit(2);
        my $ok = eval { $code->($buf) };
        syswrite($done_w, $ok ? '1' : '0');
        _exit($ok ? 0 : 1);
    }
    close $ready_w;
    close $done_w;
    sysread($ready_r, my $ready, 1) == 1 or die 'child did not start';
    my $done = IO::Select->new($done_r);
    ok(!$done->can_read(0.15), "$type $op waits for the parent's write lock");
    $buf->set(0, $type eq 'Str' ? 'after' : 9);
    $buf->unlock_wr;
    my $finished = $done->can_read(5);
    my $result = '';
    sysread($done_r, $result, 1) if $finished;
    kill 'KILL', $pid unless $finished;
    waitpid($pid, 0);
    ok($finished && $result eq '1' && $? == 0, "$type $op completes after the parent unlocks");
}

# A child claiming its own reader slot must forget inherited local read depth.
{
    my $path = "$dir/read-depth";
    my $buf = Data::Buffer::Shared::I64->new($path, 2);
    $buf->lock_rd;
    pipe(my $ready_r, my $ready_w) or die "pipe: $!";
    pipe(my $release_r, my $release_w) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        close $ready_r;
        close $release_w;
        $buf->lock_rd;
        $buf->unlock_rd;
        undef $buf;
        syswrite($ready_w, '1');
        sysread($release_r, my $release, 1);
        _exit(0);
    }
    close $ready_w;
    close $release_r;
    sysread($ready_r, my $ready, 1) == 1 or die 'child did not finish';
    open my $fh, '<:raw', $path or die "open: $!";
    seek($fh, 128, 0) or die "seek: $!";
    read($fh, my $slots, 1024 * 16) == 1024 * 16 or die "read: $!";
    my ($parent_depth, $child_depth) = (0, 0);
    for my $i (0 .. 1023) {
        my ($owner, $depth) = unpack('V2', substr($slots, $i * 16, 8));
        $parent_depth += $depth if $owner == $$;
        $child_depth += $depth if $owner == $pid;
    }
    is($parent_depth, 1, "the parent's read lock survives child cleanup");
    is($child_depth, 0, 'child cleanup leaves no phantom read depth');
    $buf->unlock_rd;
    syswrite($release_w, '1');
    waitpid($pid, 0);
    is($?, 0, 'reader child exits cleanly');
}

done_testing;
