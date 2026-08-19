#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: the daemon really pledges and unveils.
#
# A pledge violation kills the process. Thus a correctly pledged
# daemon and a completely unpledged one both satisfy "the daemon is
# alive and its trace shows no violation". That check is a null
# test. The syscall itself is observable. This file traces the
# daemon from exec with ktrace(1). It asserts that the daemon calls
# pledge(2) with exactly the production promise set. It asserts that
# the daemon calls unveil(2) for the inventory and then locks the
# view. It asserts that startup still succeeds in the configurations
# that worked before the sandbox existed. If you remove the pledge
# or unveil call from bin/openhapd, the corresponding syscall is
# absent from the trace.
#
# The Fugu repository's sandbox test proves the enforcement
# semantics: a violation aborts, and a path outside the view is
# unreachable. No operator-supplied read path exists to probe
# enforcement through the running daemon itself. Thus this file
# deliberately makes no such probe. The trace proves the daemon's
# participation. The unit tier proves the kernel's.
#
# The inventory itself lives in bin/openhapd, beside the pledge
# policy. A script is not loadable, so no unit test can call the
# builder. This file holds that coverage instead, and it holds it
# better: the trace shows the rows the kernel really got.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

my $config_file = '/etc/openhapd.conf';
my $trace       = "/tmp/openhapd-ktrace-$$";
my $daemon      = -x '/usr/local/bin/openhapd'
    ? '/usr/local/bin/openhapd'
    : '/usr/local/sbin/openhapd';

# The traced instance needs the HAP port. Stop the rc daemon first.
system('rcctl stop openhapd >/dev/null 2>&1');
sleep 1;

# Run the daemon in the foreground under ktrace. The -i flag follows
# any children. There must be none, and the test asserts that below.
# Invoke perl on the script directly. The daemon's #!/usr/bin/env
# shebang would put env in the trace. env pledges "stdio exec"
# itself, and that would poison the promise assertions below.
my $pid = fork // die "fork: $!";
if ($pid == 0) {
	exec 'ktrace', '-i', '-f', $trace, $^X, $daemon, '-f', '-c',
	    $config_file;
	die "exec ktrace: $!";
}

ok($env->wait_for_hap_port, 'traced daemon serves HAP')
    or diag 'daemon did not open the HAP port under ktrace';

# No child processes while it runs. This is phase 2's contract. It
# keeps proc/exec out of the promise set.
chomp(my $children = `pgrep -P $pid 2>/dev/null`);
is($children, '', 'traced daemon has no child processes');

kill 'TERM', $pid;
waitpid $pid, 0;

my $kdump = `kdump -f $trace 2>&1`;
ok(length $kdump, 'kdump produced a trace');

# kdump folds long string records at the screen width with a
# backslash-newline-tab continuation. The 49-byte promise string
# folds mid-word. Thus the assertions must see joined lines.
$kdump =~ s/\\\n\t//g;

# The pledge syscall must have exactly the production set as its
# promise-string argument. An empty string, a typo, or a stray
# "proc exec" all fail here. The kernel ktraces the copied-in
# promise string as a structure record. kdump renders the record as
# STRU promise="..." (sys/kern/kern_pledge.c parsepledges,
# usr.bin/kdump/ktrstruct.c). OpenBSD::Pledge dedupes and sorts the
# promises before the syscall. Thus the on-the-wire string is the
# sorted form of the production set.
my $promises = join ' ',
    sort qw(stdio rpath wpath cpath fattr inet dns unix);
like($kdump, qr/CALL\s+pledge\(/, 'pledge(2) is called');
like($kdump, qr/STRU\s+promise="\Q$promises\E"/,
     'the promise string is exactly the production set');
unlike($kdump, qr/STRU\s+promise="[^"]*\b(?:proc|exec)\b[^"]*"/,
       'no promise set in the trace grants proc, exec or prot_exec');

# The unveil syscalls: the daemon really builds a view, and a final
# unveil(2) with both arguments NULL locks it. The permission
# strings appear as STRU flags= records. db_path's rwc is unique to
# unveil. A NAMI is not, because any open(2) also leaves one.
my @unveils = $kdump =~ /CALL\s+unveil\(([^)]*)\)/g;
cmp_ok(scalar @unveils, '>=', 3,
       'unveil(2) called for the inventory');
like($kdump, qr/STRU\s+flags="rwc"/,
     'the state directory is unveiled read-write-create');
like($kdump, qr/CALL\s+unveil\(0,0\)/, 'the view is locked');
is($unveils[-1], '0,0', 'the lock is the last unveil call');

# The inventory grants no execute permission anywhere. The promise
# set withholds exec, so a row that granted x would contradict the
# pledge in the same source file.
unlike($kdump, qr/STRU\s+flags="[^"]*x[^"]*"/,
       'no unveil row grants execute permission');

# The library tree is read-only. The daemon loads Net::MQTT::Simple
# late, on the reconnect path, and must never write there.
like($kdump, qr/STRU\s+flags="r"/,
     'a read-only row is in the view');

# pledge comes after the lock. This closes the ordering that the
# call site promises.
my ($lock_pos, $pledge_pos) = (-1, -1);
while ($kdump =~ /CALL\s+unveil\(0,0\)/g) { $lock_pos   = $-[0] }
while ($kdump =~ /CALL\s+pledge\(/g)      { $pledge_pos = $-[0] }
cmp_ok($lock_pos, '>=', 0, 'lock found in trace');
cmp_ok($pledge_pos, '>', $lock_pos, 'pledge applied after the lock');

unlink $trace;

# Permanent negative control: the identical trace pipeline over a
# perl process that deliberately does not pledge or unveil must show
# neither syscall. This control proves that the positive assertions
# above can fail. Plan 005 required that demonstration. The control
# needs no test-only daemon override, which plan 005 forbids. If
# bin/openhapd dropped the pledge or unveil call, its trace would
# look exactly like this one, and the assertions above would go red.
# The control also pins the detector itself: a kdump format drift
# that made the regexes match ambient records would fail here.
# ktrace(1) itself calls neither syscall. Thus any such record in
# this trace is a defect.
my $neg_trace = "/tmp/openhapd-negctl-$$";
system('ktrace', '-i', '-f', $neg_trace, $^X, '-e', 'exit 0');
my $neg = `kdump -f $neg_trace 2>&1`;
$neg =~ s/\\\n\t//g;
ok(length $neg, 'negative-control trace produced');
like($neg, qr/CALL\s+exit\(/,
     'the control traced real syscalls');
unlike($neg, qr/CALL\s+pledge\(/,
       'no pledge syscall without a pledge call');
unlike($neg, qr/STRU\s+promise=/,
       'no promise record without a pledge call');
unlike($neg, qr/CALL\s+unveil\(/,
       'no unveil syscall without an unveil call');
unlink $neg_trace;

# Startup still succeeds in every configuration that worked before
# the sandbox. A missing config file must be an optional unveil
# entry, never a refusal to boot.
my $absent_conf = "/tmp/absent-openhapd-$$.conf";
$pid = fork // die "fork: $!";
if ($pid == 0) {
	open STDOUT, '>', '/dev/null';
	open STDERR, '>', '/dev/null';
	exec $daemon, '-f', '-c', $absent_conf;
	die "exec: $!";
}
ok($env->wait_for_hap_port, 'daemon serves with no config file at all');
kill 'TERM', $pid;
waitpid $pid, 0;

# Startup also succeeds with -f on a host that has no daemon log
# file. The log row is optional, and -f never creates the file. The
# rc daemon holds its own fd. Thus the test can safely remove the
# file underneath it. rcctl start recreates the file below.
unlink '/var/log/openhapd.log';
$pid = fork // die "fork: $!";
if ($pid == 0) {
	open STDOUT, '>', '/dev/null';
	open STDERR, '>', '/dev/null';
	exec $daemon, '-f', '-c', $config_file;
	die "exec: $!";
}
ok($env->wait_for_hap_port,
   'daemon serves in -f mode with no /var/log/openhapd.log');
kill 'TERM', $pid;
waitpid $pid, 0;

# Restore the shared daemon for the files that run after this one
system('rcctl start openhapd >/dev/null 2>&1');
$env->wait_for_hap_port or die "daemon not serving after restore\n";

$env->teardown;
done_testing();
