use strict;
use warnings;
use AnyEvent;
use Argon::Client;
use Argon::Constants ':commands';
use Argon::Log;
use Argon;

$AnyEvent::Log::FILTER->level('note');
$Argon::ALLOW_EVAL = 1;

sub fnord { Time::HiRes::sleep(rand(0.5)); $_[0] * 2 }

sub async {
  my $batch = shift;
  my $conn = AnyEvent->condvar;

  my $client = Argon::Client->new(
    host    => 'localhost',
    port    => 8000,
    keyfile => 'scratch/key',
    ready   => $conn,
    retry   => 1,
  );

  $conn->recv;
  my $done = 0;
  my $fail = 0;
  my @async;

  push @async, $client->async(\&fnord, $_)
    foreach 1 .. $batch;

  foreach (@async) {
    my $result = eval { $_ };

    if (my $error = $@) {
      log_debug $error;
      ++$fail;
    } else {
      ++$done;
    }
  }

  return ($done, $fail);
}

sub client {
  my $batch = shift;

  my $conn = AnyEvent->condvar;

  my $client = Argon::Client->new(
    host    => 'localhost',
    port    => 8000,
    keyfile => 'scratch/key',
    ready   => $conn,
    retry   => 1,
  );

  $conn->recv;

  my $cv = AnyEvent->condvar;
  my $done = 0;
  my $fail = 0;

  foreach my $i (1 .. $batch) {
    $cv->begin;

    $client->process(
      \&fnord,
      [$i],
      sub {
        my $reply  = shift;
        my $result = eval { $reply->result };

        if (my $error = $@) {
          log_debug $error;
          ++$fail;
        } else {
          ++$done;
        }

        $cv->end;
      }
    );
  }

  $cv->recv;
  return ($done, $fail);
}

sub fork_clients {
  my ($count, $batch) = @_;
  my @pids;

  foreach my $i (1 .. $count) {
    my $pid = fork;
    if ($pid) {
      push @pids, $pid;
    }
    else {
      #my ($done, $fail) = client($batch);
      my ($done, $fail) = async($batch);
      $done = $done ? sprintf('%2d', $done) : ' -';
      $fail = $fail ? sprintf('%2d', $fail) : ' -';
      log_note 'done: %s, fail: %s', $done, $fail;
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
