use strict;
use warnings;

use Test::More;

use File::Temp ();
use FindBin ();
use POSIX ();

use DBIO::Util qw(file_path mkpath slurp_file write_file);

# maint/capped-test is the wrapper every suite in the family is run through, on
# a shared host. It is trusted to do one thing: a run that goes wrong is ended
# by the kernel at its memory cap and the host stays up. This file holds it to
# that -- including the half it was missing until karr k323, where a runaway
# run was not ended at the cap but paged out, because RAM was capped and swap
# was not. And it holds it to the promise that makes the wrapper safe to trust:
# when the cap is not in force the command is NOT started, and the exit is 99.
#
# Every memory limit in here is 64M and the one process that eats memory stops
# by itself at four times that, so this test cannot hurt the host it runs on
# even where the wrapper fails it.

my $capped = file_path($FindBin::Bin, '..', '..', 'maint', 'capped-test');

plan skip_all => 'maint/capped-test is a repository tool and not part of the shipped dist'
  unless -f $capped;

my %tool;
for my $name (qw(timeout systemd-run)) {
  ($tool{$name}) = grep { -x } map { "$_/$name" } split /:/, $ENV{PATH} // '';
}
plan skip_all => 'no timeout(1) in PATH to bound the runs with'
  unless $tool{timeout};
plan skip_all => 'no systemd-run in PATH: nothing can be capped on this host'
  unless $tool{'systemd-run'};
plan skip_all => 'no user systemd session (XDG_RUNTIME_DIR unset)'
  unless $ENV{XDG_RUNTIME_DIR};

my $controllers = "/sys/fs/cgroup/user.slice/user-$<.slice/cgroup.controllers";
plan skip_all => "the memory cgroup controller is not delegated to user-$<.slice"
  unless -r $controllers and slurp_file($controllers) =~ /\bmemory\b/;

my $tmp = File::Temp->newdir;

# run(\%env, @command): the command with %env laid over the environment (an
# undef value removes the variable), its exit status and what it wrote.
sub run {
  my ($env, @command) = @_;
  my ($out, $err) = map { file_path($tmp, $_) } qw(stdout stderr);

  my $pid = fork // die "fork: $!";
  if (!$pid) {
    for my $name (keys %$env) {
      defined $env->{$name} ? ($ENV{$name} = $env->{$name}) : delete $ENV{$name};
    }
    open STDOUT, '>', $out or POSIX::_exit(126);
    open STDERR, '>', $err or POSIX::_exit(126);
    { no warnings 'exec'; exec { $command[0] } @command }
    POSIX::_exit(126);
  }
  waitpid $pid, 0;

  return {
    exit   => ($? & 127) ? 128 + ($? & 127) : $? >> 8,
    stdout => scalar(slurp_file($out)) // '',
    stderr => scalar(slurp_file($err)) // '',
  };
}

sub capped {
  my ($env, @command) = @_;
  return run({ DBIO_TEST_MEMMAX => '64M', %$env }, $tool{timeout}, 60, $^X, $capped, @command);
}

plan skip_all => 'the user systemd manager starts no scope here'
  unless run({}, $tool{timeout}, 30, $tool{'systemd-run'}, qw(--user --scope --quiet true))->{exit} == 0;

# What the wrapped command is in most cases below: proof that it was started.
my @ran = ($^X, '-e', 'print "RAN\n"');

sub refused_ok {
  my ($got, $why, $name) = @_;
  subtest $name => sub {
    is $got->{exit}, 99, 'exit 99, the one status that means "not capped, not run"';
    unlike $got->{stdout}, qr/RAN/, 'the command was not started';
    like $got->{stderr}, qr/REFUSING to start/, 'and the refusal is announced';
    like $got->{stderr}, $why, 'with the reason';
  } or diag "exit $got->{exit}\n$got->{stderr}";
}

# A systemd-run stand-in, first in PATH. What it does is chosen per run through
# CAPPED_TEST_FAKE.
my $fake_bin = file_path($tmp, 'bin');
mkpath($fake_bin);
my $systemd_run = $tool{'systemd-run'};
write_file(file_path($fake_bin, 'systemd-run'), <<"FAKE");
#!$^X
use strict;
use warnings;
my \$real = '$systemd_run';
my \$mode = \$ENV{CAPPED_TEST_FAKE} // '';
if (\$mode eq 'fail') {
  print STDERR "Failed to start transient scope unit: stand-in says no\\n";
  exit 1;
}
if (\$mode eq 'no-scope') {
  # takes every property, starts the command where it stands
  shift \@ARGV while \@ARGV and \$ARGV[0] =~ /^--/;
  splice \@ARGV, 0, 2 while \@ARGV and \$ARGV[0] eq '-p';
  exec { \$ARGV[0] } \@ARGV;
}
# drop:NAME -- a real scope, but property NAME never reaches systemd
my (\$drop) = \$mode =~ /^drop:(.+)/ or die "stand-in systemd-run: no mode";
my \@args;
while (\@ARGV) {
  my \$arg = shift \@ARGV;
  if (\$arg eq '-p' and \$ARGV[0] =~ /^\\Q\$drop\\E=/) { shift \@ARGV; next }
  push \@args, \$arg;
}
exec { \$real } \$real, \@args;
FAKE
chmod 0755, file_path($fake_bin, 'systemd-run') or die "chmod: $!";

my %fake = (PATH => "$fake_bin:$ENV{PATH}");

# ------------------------------------------------ the cap cannot be established

my $empty = file_path($tmp, 'empty');
mkpath($empty);

refused_ok(
  capped({ PATH => $empty }, @ran),
  qr/systemd-run is not in PATH/,
  'no systemd-run',
);

refused_ok(
  capped({ XDG_RUNTIME_DIR => undef }, @ran),
  qr/no user systemd session/,
  'no user systemd session',
);

# systemd takes "infinity" for MemoryMax, and a scope with that limit is an
# uncapped run with the wrapper's name on it.
refused_ok(
  capped({ DBIO_TEST_MEMMAX => 'infinity' }, @ran),
  qr/DBIO_TEST_MEMMAX=infinity is not a size/,
  'a limit that is none',
);

# From outside, a systemd-run that failed is an exit 1 -- which is also what
# prove says after a failed test. It must not come out as one.
refused_ok(
  capped({ %fake, CAPPED_TEST_FAKE => 'fail' }, @ran),
  qr/systemd-run did not start the run \(exit 1\)/,
  'systemd-run fails',
);

# ------------------------------- the cap was asked for, taken, and is not there

# The failure the read-back exists for: systemd-run accepts every -p and the
# limit is not in force. Checking what was passed proves nothing here; only the
# cgroup the command would run in can tell.
refused_ok(
  capped({ %fake, CAPPED_TEST_FAKE => 'no-scope' }, @ran),
  qr/systemd-run did not put the run into dbio-capped-test-\d+\.scope/,
  'the run is in no scope of its own',
);

refused_ok(
  capped({ %fake, CAPPED_TEST_FAKE => 'drop:MemoryMax' }, @ran),
  qr/memory\.max of dbio-capped-test-\d+\.scope is max, not 67108864/,
  'a scope without the RAM limit',
);

# The k323 incident, as a scope: RAM capped, swap open.
refused_ok(
  capped({ %fake, CAPPED_TEST_FAKE => 'drop:MemorySwapMax' }, @ran),
  qr/memory\.swap\.max of dbio-capped-test-\d+\.scope is max, not 0/,
  'a scope without the swap limit',
);

# The CPU half of the promise, read back from cpu.max like the memory half.
# What cpu.max then says depends on the host: where the cpu controller is on
# for the scope anyway it reads "max 100000"; where only a CPUQuota would have
# turned it on there is no cpu.max in the scope at all. Both are a quota that
# is not in force, and both are refused.
refused_ok(
  capped({ %fake, CAPPED_TEST_FAKE => 'drop:CPUQuota' }, @ran),
  qr/cpu\.max of dbio-capped-test-\d+\.scope is (?:max 100000|not readable), not 200000 100000/,
  'a scope without the CPU quota',
);

refused_ok(
  capped({ DBIO_TEST_CPUQUOTA => 'infinity' }, @ran),
  qr/DBIO_TEST_CPUQUOTA=infinity is not a percentage/,
  'a CPU quota that is none',
);

# ------------------------------------------------------ the cap is established

my $own_cgroup = q{open my $fh, '<', '/proc/self/cgroup' or die $!;}
               . q{my ($cgroup) = map { /^0::(\S+)/ ? $1 : () } <$fh>;};

my $limits = capped({}, $^X, '-e', $own_cgroup . <<'PERL');
for my $knob (qw(memory.max memory.swap.max)) {
  open my $in, '<', "/sys/fs/cgroup$cgroup/$knob" or die "$knob: $!";
  print "$knob=", scalar <$in>;
}
PERL

subtest 'both limits are in force where the command runs' => sub {
  my $got = $limits;
  is $got->{exit}, 0, 'the command ran';
  like $got->{stdout}, qr/^memory\.max=67108864$/m, 'RAM is capped at the 64M asked for';
  like $got->{stdout}, qr/^memory\.swap\.max=0$/m, 'and swap at 0';
  like $got->{stderr}, qr/^capped-test: MemoryMax=64M MemorySwapMax=0 /m,
    'the announcement names both';
} or diag "exit $limits->{exit}\n$limits->{stdout}$limits->{stderr}";

# k295: a run of a few milliseconds used to end in "peak (unknown)", because the
# only source was a journal line systemd writes when it tears the scope down.
subtest 'even an instant run reports its peak' => sub {
  my $got = capped({}, $^X, '-e', '1');
  is $got->{exit}, 0, 'the command ran';
  like $got->{stderr}, qr/^capped-test: peak \d+(?:\.\d)?[BKMG] of 64M allowed$/m,
    'and the peak is a figure, not (unknown)';
};

subtest 'the exit status of the command comes through unchanged' => sub {
  my $got = capped({}, $^X, '-e', 'exit 3');
  is $got->{exit}, 3, 'exit 3 stays 3';
  like $got->{stderr}, qr/the run failed \(exit 3\)/, 'reported as a failure';
  unlike $got->{stderr}, qr/hit the 64M cap/, 'and not as a kill at the cap';
};

# The point of the whole wrapper. The process writes to every page it takes, in
# 4M steps, and reports after each step how much of its cgroup is in swap. Left
# alone it stops at 256M and exits 0 -- which is what it did before k323, most
# of it paged out.
my $eater = capped({}, $^X, '-e', $own_cgroup . <<'PERL');
$0 = 'capped-selftest';   # the name the kernel's OOM report will carry
$| = 1;
my @held;
for (1 .. 64) {
  push @held, 'x' x (4 * 1024 * 1024);
  open my $in, '<', "/sys/fs/cgroup$cgroup/memory.swap.current" or die $!;
  print 'held=', 4 * @held, 'M swap=', scalar <$in>;
}
print "SURVIVED\n";
PERL

subtest 'a run that eats memory is killed at the cap, with nothing in swap' => sub {
  my $got = $eater;
  is $got->{exit}, 137, 'it ends by SIGKILL';
  unlike $got->{stdout}, qr/SURVIVED/, 'before it gets past the cap';

  my @swap = $got->{stdout} =~ /swap=(\d+)/g;
  cmp_ok scalar @swap, '>', 0, 'it got as far as taking memory';
  is_deeply [ grep { $_ != 0 } @swap ], [], 'and at no step was any of it in swap';

  like $got->{stderr}, qr/was KILLED -- it hit the 64M cap/, 'the wrapper says what happened';
} or diag "exit $eater->{exit}\n$eater->{stdout}$eater->{stderr}";

done_testing;
