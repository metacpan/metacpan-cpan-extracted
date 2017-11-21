use strict;
use warnings;
use Time::HiRes;
use AnyEvent;
use Argon::Simple;
use Argon::Log;

log_level 'note';

sub client ($) {
  my $batch = shift;

  Argon {
    remote 'localhost:8000', keyfile => 'scratch/key', retry => 1;

    my @batch;

    foreach my $i (0 .. $batch - 1) {
      send { Time::HiRes::sleep(rand(0.5)); $_[0] * 2 } $i, sub {
        my $reply = shift;
        $batch[$i] = eval { $reply->denied ? '-' : $reply->result };
        log_error $@ if $@;
      };
    }

    sync;

    join ', ', map { defined $_ ? $_ : 'undef' } @batch;
  };
}

sub fork_clients ($$) {
  my ($count, $batch) = @_;
  my @pids;

  foreach my $i (1 .. $count) {
    my $pid = fork;
    if ($pid) {
      push @pids, $pid;
    } else {
      log_note 'result: [%s]', client $batch;
      exit 0;
    }
  }

  return @pids;
}

my ($clients, $batch, $time) = @ARGV;
$clients //= 1;
$batch   //= 1;

if ($time) {
  my $start = time;
  while (time - $start < $time) {
    my @pids = fork_clients $clients, $batch;
    waitpid $_, 0 foreach @pids;
  }
}
else {
  my @pids = fork_clients $clients, $batch;
  waitpid $_, 0 foreach @pids;
}
