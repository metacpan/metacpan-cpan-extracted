#!/usr/bin/env perl
use strict;
use warnings;
use Cwd ();
use File::Basename 'dirname';
use File::Spec;
use File::Temp 'tempfile';
use Test::More;
use Data::Dumper;

plan skip_all => 'TEST_ON_PROCESS_END=1' unless $ENV{TEST_ON_PROCESS_END};
plan skip_all => $@ unless my $cwd = eval { dirname(Cwd::abs_path($0)) };

my $script = File::Spec->catfile($cwd, qw(bin on-process-end.pl));
plan skip_all => 'Cannot execute on-process-end.pl' unless -x $script;

my ($tmp_fh, $tmp_path) = tempfile;
close $tmp_fh;
$ENV{ON_PROCESS_END_FILE} = $tmp_path;

my ($f_pid, $o_pid, $proc);
$proc  = run(sub { $_[0]{read} = 1 });
$f_pid = delete $proc->{f_pid};
is_deeply(
  $proc,
  {USR2 => 1, mode => 'destroy', pid => "$f_pid/$f_pid", ppid => "$$/$$", signal => 'none'},
  'on_process_end destroy will be called on normal exit'
);

$proc  = run(sub { kill 9, $_[0]{f_pid} });
$f_pid = delete $proc->{f_pid};
is_deeply($proc, {}, 'on_process_end destroy will not be called on kill 9');

$proc  = run(sub { kill 9, $_[0]{f_pid}; $_[0]{read} = 1 }, 'fork');
$f_pid = delete $proc->{f_pid};
$o_pid = $f_pid + 1;
is_deeply(
  $proc,
  {USR2 => 1, mode => 'fork', pid => "$f_pid/$o_pid", ppid => "$$/1", signal => 'pipe'},
  'on_process_end fork will be called on kill 9'
);

$proc  = run(sub { kill 9, $_[0]{f_pid}; $_[0]{read} = 1 }, 'double_fork');
$f_pid = delete $proc->{f_pid};
$o_pid = $f_pid + 2;
is_deeply(
  $proc,
  {USR2 => 1, mode => 'double_fork', pid => "$f_pid/$o_pid", ppid => "$$/1", signal => 'parent'},
  'on_process_end double_fork will be called on kill 9'
);

note 'ON_PROCESS_EARLY=1';
local $ENV{ON_PROCESS_EARLY} = 1;
$proc  = run(sub { $_[0]{read} = 1 });
$f_pid = delete $proc->{f_pid};
is_deeply(
  $proc,
  {USR2 => 1, mode => 'destroy', pid => "$f_pid/$f_pid", ppid => "$$/$$", signal => 'none'},
  'on_process_end destroy was called early'
);

$proc  = run(sub { $_[0]{read} = 1 }, 'fork');
$f_pid = delete $proc->{f_pid};
$o_pid = $f_pid + 1;
is_deeply(
  $proc,
  {USR2 => 1, mode => 'fork', pid => "$f_pid/$o_pid", ppid => "$$/$f_pid", signal => 'pipe'},
  'on_process_end fork was called early'
);

$proc  = run(sub { $_[0]{read} = 1 }, 'double_fork');
$f_pid = delete $proc->{f_pid};
$o_pid = $f_pid + 2;
is_deeply(
  $proc,
  {USR2 => 1, mode => 'double_fork', pid => "$f_pid/$o_pid", ppid => "$$/1", signal => 'TERM'},
  'on_process_end double_fork was called early'
);

done_testing;

sub run {
  my ($code, @argv) = @_;
  truncate $tmp_path, 0 or die $!;

  my $f_pid = fork;
  unless ($f_pid) {
    local $ENV{PERL5LIB} = join ':', @INC;
    exec $^X => $script, @argv;
    exit $!;
  }

  my %info = (f_pid => $f_pid);
  local $SIG{USR1} = sub { $info{USR1}++ };
  local $SIG{USR2} = sub { $info{USR2}++ };
  1 until $info{USR1};
  note "[$$] Running $script @argv == $f_pid";

  $code->(\%info);
  waitpid $f_pid, 0;

  if ($info{read}) {
    1 until -s $tmp_path;
    open my $FH, '<', $tmp_path or die $!;
    while (my $info = <$FH>) {
      $info{$1} = $2 while $info and $info =~ m!(\w+)=(\S+)!g;
    }
  }

  #local $Data::Dumper::Sortkeys = 1; warn Dumper(\%info);
  delete $info{$_} for qw(USR1 read);
  return \%info;
}
