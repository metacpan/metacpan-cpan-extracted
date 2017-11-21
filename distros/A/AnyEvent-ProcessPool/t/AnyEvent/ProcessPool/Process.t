use Test2::Bundle::Extended;
use AnyEvent::ProcessPool::Process;
use AnyEvent::ProcessPool::Task;
use AnyEvent;

bail_out 'OS unsupported' if $^O eq 'MSWin32';

subtest is_running => sub{
  ok my $proc = AnyEvent::ProcessPool::Process->new, 'ctor';

  ok !$proc->is_running, '!is_running';
  ok !$proc->pid, '!pid';

  $proc->await;

  ok $proc->is_running, 'is_running';
  ok $proc->pid, 'pid';
};

subtest run => sub{
  my $proc = AnyEvent::ProcessPool::Process->new;
  ok my $async = $proc->run(AnyEvent::ProcessPool::Task->new(sub{42})), 'run';
  ok my $task = $async->recv, 'recv task';
  ok $task->done, 'done';
  ok !$task->failed, '!failed';
  is $task->result, 42, 'result';
};

subtest fail => sub{
  my $proc = AnyEvent::ProcessPool::Process->new;
  ok my $async = $proc->run(AnyEvent::ProcessPool::Task->new(sub{die "fnord"})), 'run';
  ok my $task = $async->recv, 'recv task';
  ok $task->done, 'done';
  ok $task->failed, '!failed';
  like $task->result, qr/fnord/, 'result';
};

subtest limit => sub{
  my $proc = AnyEvent::ProcessPool::Process->new(limit => 1);

  $proc->await;
  my $pid1 = $proc->pid;
  $proc->run(AnyEvent::ProcessPool::Task->new(sub{}))->recv; # block for result

  $proc->await;
  my $pid2 = $proc->pid;
  isnt $pid1, $pid2, 'new process after limit exceeded';
  is $proc->run(AnyEvent::ProcessPool::Task->new(sub{"fnord"}))->recv->result, 'fnord', 'functions after worker replacement';
};

subtest 'implicit run' => sub{
  my $proc = AnyEvent::ProcessPool::Process->new;
  ok !$proc->is_running, '!is_running before call to run';
  my $async = $proc->run(AnyEvent::ProcessPool::Task->new(sub{ 42 }));
  ok $proc->is_running, 'is_running after call to run';
  is $async->recv->result, 42, 'expected result';
};

subtest 'includes' => sub{
  subtest 'without' => sub{
    my $proc = AnyEvent::ProcessPool::Process->new;
    my $async = $proc->run(AnyEvent::ProcessPool::Task->new('TestModule'));
    ok my $task = $async->recv, 'result';
    ok $task->done, 'done';
    ok $task->failed, 'failed';
    like $task->result, qr/TestModule/, 'expected error message';
  };

  subtest 'with' => sub{
    my $proc = AnyEvent::ProcessPool::Process->new(include => ['t/some/libs']);
    my $async = $proc->run(AnyEvent::ProcessPool::Task->new('TestModule'));
    ok my $task = $async->recv, 'result';
    ok $task->done, 'done';
    ok !$task->failed, '!failed';
    is $task->result, 'bar', 'expected result';
  };
};

done_testing;
