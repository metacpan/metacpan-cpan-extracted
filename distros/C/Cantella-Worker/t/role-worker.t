
use strict;
use warnings;

my $paused = 0;
{
  package TestCantellaWorker;
  use POE;
  use Moose;

  with 'Cantella::Worker::Role::Worker';
  my $empty_polls = 0;
  my @work_stack = ( 1 .. 5);

  sub BUILD {
    POE::Session->create(
      inline_states => {
        test_resume => sub {
          my($kernel, $heap) = @_[KERNEL, HEAP];
          $paused = 0;
          $poe_kernel->signal($poe_kernel, 'USR2');
        },
        _start => sub { $poe_kernel->alias_set('test') },
      },
    );
  }

  sub get_work {
    my $self = shift;
    if ( @work_stack ) {
      my $value = shift @work_stack;
      if ( $value == 2 ) {
        $paused = 1;
        $poe_kernel->signal($poe_kernel, 'USR1');
        $poe_kernel->post($self->alias, 'poll');
        $poe_kernel->post($self->alias, 'poll');
        $poe_kernel->post($self->alias, 'poll');
        $poe_kernel->post('test', 'test_resume');
        return;
      }
      return $value;
    } else {
      $poe_kernel->signal($poe_kernel, 'TERM') if ++$empty_polls == 3;
      return;
    }
  }

  sub work {
    my ($self, $args) = @_;
    return if $paused; #don't do work if paused
    $self->logger->debug("working on: $args");
  }
}


use Test::More tests => 4;
use Test::Exception;
use Log::Dispatch;

my(@debug_messages, @info_messages, @error_messages);
my $logger = Log::Dispatch->new(
  outputs => [
    [ Array => ( min_level => 'debug', max_level => 'debug', array => \@debug_messages) ],
    [ Array => ( min_level => 'info', max_level => 'info', array => \@info_messages) ],
    [ Array => ( min_level => 'warning', max_level => 'error', array => \@error_messages) ],
  ]
);

lives_ok {
  my $worker = TestCantellaWorker->new( logger => $logger, interval => 2 );
  $worker->start;
} 'instantiate and run work';

is_deeply(\@error_messages, [], 'no error messages');
@info_messages = map {$_->{message}} @info_messages;
is_deeply(
  \@info_messages,
  [
    "pausing worker ${$}",
    "resuming worker ${$}",
    "shutting down worker with pid ${$}",
  ],
  'info messages'
);

@debug_messages = map {$_->{message}} @debug_messages;
is_deeply(
  \@debug_messages,
  [map { "working on: $_" } (1, 3, 4, 5)],
  'all work done'
);
