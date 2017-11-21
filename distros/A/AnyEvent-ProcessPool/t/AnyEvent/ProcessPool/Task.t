use Test2::Bundle::Extended;
use AnyEvent::ProcessPool::Task;

bail_out 'OS unsupported' if $^O eq 'MSWin32';

subtest 'execute' => sub{
  subtest 'positive path' => sub{
    ok my $task = AnyEvent::ProcessPool::Task->new(sub{ 42 }), 'ctor';
    is $task->execute, 1, 'execute';
    is $task->result, 42, 'result';
    ok $task->done, 'done';
    ok !$task->failed, '!failed';
  };

  subtest 'negative path' => sub{
    ok my $task = AnyEvent::ProcessPool::Task->new(sub{ die "failed" }), 'ctor';
    is $task->execute, 0, 'execute';
    ok $task->done, 'done';
    ok $task->failed, 'failed';
    like $task->result, qr/failed/, 'result';
  };

  subtest 'task class' => sub{
    local @INC = ('t/some/libs', @INC);
    ok my $task = AnyEvent::ProcessPool::Task->new('TestModule'), 'ctor';
    is $task->execute, 1, 'execute';
    ok $task->done, 'done';
    ok !$task->failed, '!failed' or diag $task->result;
  };
};

subtest 'serialization' => sub{
  ok my $task = AnyEvent::ProcessPool::Task->new(sub{ 42 }), 'ctor';
  ok $task->execute, 'execute';

  ok my $line = $task->encode, 'encode';
  is scalar(split(qr/[\r\n]/, $line)), 1, 'no line breaks';

  ok my $decoded = AnyEvent::ProcessPool::Task->decode($line), 'decode';
  is $decoded->result, 42, 'result';
};

done_testing;
