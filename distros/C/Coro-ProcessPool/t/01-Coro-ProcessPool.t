use Test2;
use Test2::Bundle::Extended;
use Coro;
use Coro::ProcessPool;

bail_out 'OS unsupported' if $^O eq 'MSWin32';

my $PROCS = 2;
my $REQS  = 3;  # not evenly divisible by $COUNT
my $COUNT = 11; # not evenly divisible by $PROCS

sub double { $_[0] * 2 }
sub pid { $$ }

subtest 'life cycle' => sub{
  ok my $pool = Coro::ProcessPool->new, 'new';
  ok $pool->{max_procs} > 0, 'max_procs defaults correctly';
  $pool->join;
};

subtest 'defer' => sub{
  my $pool = Coro::ProcessPool->new(max_procs => $PROCS);
  my %result;

  ok $result{$_} = $pool->defer(\&double, $_), "defer $_"
    for 1 .. $COUNT;

  # Use keys(%hash) to randomize the order of resolution
  is $result{$_}->recv, $_ * 2, "resolve $_"
    for keys %result;

  $pool->join;
};

subtest 'errors' => sub{
  my $pool = Coro::ProcessPool->new(max_procs => $PROCS);
  ok my $cv = $pool->defer(sub{ die 'some error' }), 'defer';
  like dies{ $cv->recv }, qr/some error/, 'error rethrown at appropriate time';
};

subtest 'max_reqs' => sub{
  my $pool = Coro::ProcessPool->new(
    max_procs => $PROCS,
    max_reqs  => $REQS,
  );

  my %count;
  my %result;

  $result{$_} = $pool->defer(\&pid, $_)
    for 1 .. $COUNT;

  foreach (keys %result) {
    my $pid = $result{$_}->recv;
    $count{$pid} ||= 0;
    ++$count{$pid};
  }

  # Use keys(%hash) to randomize the order of resolution
  foreach (keys %count) {
    ok $count{$_} <= 3, "pid $$ used no more than 3 times";
  }

  $pool->join;
};

subtest 'process' => sub{
  my $pool = Coro::ProcessPool->new(
    max_procs => $PROCS,
    max_reqs  => $REQS,
  );

  for (1 .. $COUNT) {
    is $pool->process(\&double, $_), $_ * 2, "process $_";
  }

  $pool->join;
};

subtest 'map' => sub{
  my $pool = Coro::ProcessPool->new(
    max_procs => $PROCS,
    max_reqs  => $REQS,
  );

  my @result = $pool->map(\&double, 1 .. $COUNT);
  is \@result, [map { double($_) } 1 .. $COUNT], 'expected result';

  $pool->join;
};

subtest 'two pools' => sub{
  my $pool1 = Coro::ProcessPool->new(max_procs => $PROCS, max_reqs  => $REQS);
  my $pool2 = Coro::ProcessPool->new(max_procs => $PROCS);

  foreach my $i (1 .. $COUNT) {
    if ($i % 2 == 0) {
      my $result = $pool1->process(\&double, $i);
      is $result, $i * 2, 'expected result (pool 1)';
    } else {
      my $result = $pool2->process(\&double, $i);
      is $result, $i * 2, 'expected result (pool 2)';
    }
  }

  $pool2->join;
  $pool1->join;
};

SKIP: {
  skip('enable with CORO_PROCESSPOOL_ENABLE_EXPENSIVE_TESTS=1', 1)
    unless $ENV{CORO_PROCESSPOOL_ENABLE_EXPENSIVE_TESTS};

  subtest 'large tasks' => sub {
    my $pool = Coro::ProcessPool->new(max_procs => 4);
    my $size = 100_000;

    my $f = sub {
      my $data = $_[0];
      my $res  = [ map{ $_ * 2 } @$data ];
      return $res;
    };

    my %pending;
    my %expected;

    foreach my $i (1 .. $COUNT) {
      my $data = [ ($i) x $size ];
      $expected{$i} = [ ($i * 2) x $size ];
      $pending{$i}  = $pool->defer($f, $data);
    }

    foreach my $i (keys %pending) {
      is $pending{$i}->recv, $expected{$i}, 'expected result';
    }

    $pool->join;
  };
};

done_testing;
