
use POE;
use strict;
use warnings;
use Test::More tests => 1 + 3 + 8;

BEGIN {
  use_ok('Cantella::Worker::Manager::Prefork');
}

{
  package TestPreforkWorkerClass;
  use Moose;
  with 'Cantella::Worker::Role::Worker';
  has work_pile => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub{ [1..5] },
    required => 1
  );
  has toggle => ( is => 'rw', isa => 'Bool', required => 1, default => sub {0});

  sub get_work {
    my $self = shift;
    $self->toggle( ! $self->toggle );
    if( $self->toggle ){
      return shift @{ $self->work_pile }
    } else {
      return;
    }
  }

  sub work {
    my ($self,$work) = @_;
    print STDOUT "===DOING ${work}===\n";
  }
}

{ ###TEST old-Age

  my (@debug_messages, @error_messages, @notice_messages);
  my $manager = Cantella::Worker::Manager::Prefork->new(
    logger => [
      [ Array => ( array => \@debug_messages,  min_level => 'debug', max_level=> 'debug') ],
      [ Array => ( array => \@error_messages,  min_level => 'warning') ],
      [ Array => ( array => \@notice_messages, min_level => 'notice', max_level => 'notice') ],
    ],
    workers => 3,
    worker_class => 'TestPreforkWorkerClass',
    max_worker_age => 3,
    close_on_call => 0,
    worker_args => {
      interval => 1,
      logger => [
        [ Screen => (newline => 1, min_level => 'debug') ],
      ],
    },
    worker_stderr_log_level => 'notice',
    worker_stdout_log_level => 'info',
  );

  POE::Session->create(
    inline_states => {
      _start => sub {
        $poe_kernel->delay('finish_tests' => 5.5);
      },
      finish_tests => sub {
        $poe_kernel->signal($poe_kernel, 'TERM');
      },
    },
  );

  $manager->start;
  is_deeply(\@error_messages, [], 'no warning or error messages');
  @debug_messages = map { $_->{message} } @debug_messages;
  @notice_messages = map { $_->{message} } @notice_messages;
  my @spawns = grep { /spawning wheel \d+ as pid: \d+/ } @debug_messages;
  my @retirees = grep { /retiring wheel \d+ due to old age/ } @debug_messages;
  my @sig_chlds = grep { /SIGCHLD for pid \d+ with exit code: \d/ } @debug_messages;
#  my @fh_close = grep { /close for wheel \d+/ } @debug_messages;

  my @wids = map { /spawning wheel (\d+) as pid: \d+/ } @spawns;
  my @pids = map { /spawning wheel \d+ as pid: (\d+)/ } @spawns;

  is_deeply(
    [ sort @sig_chlds ],
    [ sort map { "SIGCHLD for pid $_ with exit code: 0" } @pids ],
    'SIGCHLDs'
  );
#   is_deeply(
#     [ sort @fh_close ],
#     [ sort map { "close for wheel $_" } @wids ],
#     'close'
#   );
  is_deeply(
    [ sort @retirees ],
    [ sort map { "retiring wheel $_ due to old age" } @wids[0,1,2] ],
    'retirees',
  );

}

{ ###TEST pause - resume

  my (@debug_messages, @error_messages, @notice_messages, @info_messages);
  my $manager = Cantella::Worker::Manager::Prefork->new(
    logger => [
      [ Array => ( array => \@debug_messages,  min_level => 'debug', max_level=> 'debug') ],
      [ Array => ( array => \@info_messages, min_level => 'info', max_level => 'info') ],
      [ Array => ( array => \@notice_messages, min_level => 'notice', max_level => 'notice') ],
      [ Array => ( array => \@error_messages,  min_level => 'warning') ],
    ],
    workers => 3,
    worker_class => 'TestPreforkWorkerClass',
    close_on_call => 0,
    worker_args => {
      interval => 1.5,
      logger => [
        [ Screen => (newline => 1, min_level => 'debug') ],
      ],
    },
    worker_stderr_log_level => 'notice',
    worker_stdout_log_level => 'info',
  );

  POE::Session->create(
    inline_states => {
      _start => sub {
        $poe_kernel->delay('pause_tests' => 1);
      },
      pause_tests => sub {
        $poe_kernel->signal($poe_kernel, 'USR1');
        $poe_kernel->delay('resume_tests' => 3);
      },
      resume_tests => sub {
        $poe_kernel->signal($poe_kernel, 'USR2');
        $poe_kernel->delay('finish_tests' => 2);
      },

      finish_tests => sub {
        $poe_kernel->signal($poe_kernel, 'TERM');
      },
    },
  );

  $manager->start;
  is_deeply(\@error_messages, [], 'no warning or error messages');
  @info_messages = map { $_->{message} } @info_messages;
  @debug_messages = map { $_->{message} } @debug_messages;
  @notice_messages = map { $_->{message} } @notice_messages;
  my @spawns = grep { /spawning wheel \d+ as pid: \d+/ } @debug_messages;
  my @retirees = grep { /retiring wheel \d+ due to old age/ } @debug_messages;
  my @sig_chlds = grep { /SIGCHLD for pid \d+ with exit code: \d/ } @debug_messages;

  my @paused = grep{ /worker \d+ STDERR: 'pausing worker \d+'/ } @notice_messages;
  my @resumed = grep{ /worker \d+ STDERR: 'resuming worker \d+'/ } @notice_messages;
  my @shutdown = grep {/worker \d+ STDERR: 'shutting down worker with pid \d+'/} @notice_messages;

  is_deeply(\@retirees, [], 'no retirees');
  is(scalar(@spawns), 3, 'only three workers');

  my @wids = map { /spawning wheel (\d+) as pid: \d+/ } @spawns;
  my @pids = map { /spawning wheel \d+ as pid: (\d+)/ } @spawns;

  is_deeply(
    [ sort @sig_chlds ],
    [ sort map { "SIGCHLD for pid $_ with exit code: 0" } @pids ],
    'SIGCHLDs'
  );
  is_deeply(
    [ sort @paused ],
    [ sort map { "worker $_ STDERR: 'pausing worker $_'" } @pids[0,1,2] ],
    'paused',
  );
  is_deeply(
    [ sort @resumed ],
    [ sort map { "worker $_ STDERR: 'resuming worker $_'" } @pids[0,1,2] ],
    'resumed',
  );
  is_deeply(
    [sort @shutdown ],
    [ sort map { "worker $_ STDERR: 'shutting down worker with pid $_'" } @pids ],
    'shutdown',
  );

  my @work_done = grep { /worker \d+ STDOUT: '===DOING \d==='/ } @info_messages;
  is_deeply(
    [ sort @work_done],
    [
      sort map { "worker $_->[0] STDOUT: '===DOING $_->[1]==='" }
        map { [$_,1], [$_,2], [$_, 3]  } @pids
      ],
    'work done',
  );
}

__END__
