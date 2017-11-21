use Test2::Bundle::Extended;
use AnyEvent::ProcessPool;
use AnyEvent;

bail_out 'OS unsupported' if $^O eq 'MSWin32';

subtest 'basics' => sub{
  ok my $pool = AnyEvent::ProcessPool->new(limit => 2), 'ctor';
  ok $pool->{workers} >= 1, 'workers defalt value is set';
  ok my $async = $pool->async(sub{ shift }, 42), 'async';
  is $async->recv, 42, 'result';
};

subtest 'errors' => sub{
  ok my $pool = AnyEvent::ProcessPool->new(limit => 2), 'ctor';
  ok my $cv = $pool->async(sub{ die "fnord" }), 'async';
  like dies{ $cv->recv }, qr/fnord/, 'dies with expected error';
};

subtest 'queue' => sub{
  ok my $pool = AnyEvent::ProcessPool->new(limit => 4, workers => 2), 'ctor';

  my @seq = 0 .. 10;
  my %async;

  foreach my $i (@seq) {
    $async{$i} = $pool->async(sub{ shift }, $i);
  }

  foreach my $i (keys %async) {
    is $async{$i}->recv, $i, "result $i";
  }
};

done_testing;
