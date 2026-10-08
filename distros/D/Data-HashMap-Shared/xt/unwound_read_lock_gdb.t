use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Basename qw(dirname);

# Perl's pending-signals croak can leave a call from inside its C read section
# with the read lock still counted in the handle's slot (gdb makes that state by
# returning from get_with_ttl before the unlock). The handle must give the lock
# back at its next lock call behind a writer, and when destroyed, or every
# writer waits until the process exits.

plan skip_all => 'set CRASH_GDB=1 to run' unless $ENV{CRASH_GDB};
my $gdb = `which gdb 2>/dev/null`; chomp $gdb;
plan skip_all => 'gdb not found' unless $gdb && -x $gdb;
plan skip_all => 'needs the dist root' unless -f 'shm_generic.h' && -f 'MANIFEST';
my $probe = `$gdb -batch -ex run --args /bin/true 2>&1`;
plan skip_all => 'gdb cannot run a process here (ptrace denied?)'
    unless $probe =~ /exited normally/;

my ($line, $in);
{
    open my $f, '<', 'shm_generic.h' or die $!;
    while (<$f>) {
        $in ||= /^static int SHM_FN\(get_with_ttl\)/;
        if ($in && /shm_lru_mark\(h, idx\);/) { $line = $.; last }
    }
}
ok $line, 'located the line inside the read section of get_with_ttl'
    or BAIL_OUT('no such line in shm_generic.h');

# An unoptimised build in a scratch copy: get_with_ttl keeps a frame of its own
# to return from.
my $dir = tempdir(CLEANUP => 1);
my $bld = "$dir/build";
{
    open my $m, '<', 'MANIFEST' or die $!;
    while (<$m>) {
        my ($f) = split ' ';
        next unless defined $f && -f $f && $f !~ m{^(t|xt|eg|bench)/};
        make_path(dirname("$bld/$f"));
        copy($f, "$bld/$f") or die "copy $f: $!";
    }
}
my $out = `cd $bld && $^X Makefile.PL 2>&1 && make OPTIMIZE='-O0 -g' 2>&1`;
is $?, 0, '-O0 -g build' or BAIL_OUT("build failed:\n$out");
my @inc = ("-I$bld/blib/lib", "-I$bld/blib/arch");

my $script = "$dir/unwound.pl";
open my $s, '>', $script or die $!;
print $s <<'EOF';
use strict; use warnings;
use Time::HiRes ();
use Data::HashMap::Shared::II;
my ($path, $then) = @ARGV;
my $m = Data::HashMap::Shared::II->new($path, 64, 0, 3600);
$m->put(1, 1);
my $ppid = getppid();                   # gdb arms the breakpoint here
my @got = $m->get_with_ttl(1);          # and returns from inside its read section
sub writer {
    my $pid = fork // die "fork: $!";
    return $pid if $pid;
    my $ok = Data::HashMap::Shared::II->new($path, 64, 0, 3600)->put(3, 3);
    require POSIX;
    POSIX::_exit($ok ? 0 : 1);
}
if ($then eq 'write') {
    $m->put(2, 2) or die 'put';
} else {
    my $w = writer();
    Time::HiRes::sleep(0.3);            # the writer is waiting for the readers to drain
    if    ($then eq 'read')  { $m->ttl_remaining(1) }
    elsif ($then eq 'queue') { $m->put(2, 2) or die 'put' }
    else                     { undef $m }
    waitpid $w, 0;
    die "writer: $?" if $?;
}
print "done\n";
EOF
close $s;

for my $then (qw(write read queue destroy)) {
    my $cmds = "$dir/$then.gdb";
    open my $g, '>', $cmds or die $!;
    print $g "set pagination off\nset confirm off\nset breakpoint pending on\n",
             "catch syscall getppid\nrun\ndelete 1\nbreak shm_generic.h:$line\ncontinue\n",
             "delete 2\nreturn 0\ncontinue\nquit\n";
    close $g;
    my $log = `ulimit -v 1500000; timeout 30 $gdb -batch -x $cmds --args $^X @inc $script $dir/$then.shm $then 2>&1`;
    like $log, qr/Breakpoint 2[,.]/, "$then: gdb returned from inside the read section";
    like $log, qr/^done$/m,
        { write   => 'a write through the handle that left its read lock behind completes',
          read    => 'a read through it lets the writer waiting on that lock in',
          queue   => 'a write through it, behind that writer, lets it in too',
          destroy => 'destroying it lets the writer waiting on that lock in' }->{$then}
        or diag $log;
}
done_testing;
