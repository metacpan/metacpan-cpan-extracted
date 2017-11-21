use strict;
use warnings;
use feature 'say';
use feature 'state';
use AnyEvent::ProcessPool;
use AnyEvent::ProcessPool::Pipeline;
use Benchmark ':all';

my $pool = AnyEvent::ProcessPool->new(workers => 10);

sub fib {
  my $acc = 0;
  my @stack = @_;
  while (defined(my $i = pop @stack)) {
    if ($i < 2) {
      $acc += $i;
    } else {
      push @stack, $i - 1, $i - 2;
    }
  }

  return $acc;
}

sub ifib {
  map { fib $_ } @_;
}

sub afib {
  state $fib = \&fib;
  return
    sort { $a >= $b }
    map  { $_->recv }
    map  { my $i = $_; $pool->async(sub{ $fib->($i) }) }
    @_;
}

my @f = afib(1..30); say "@f";

timethese(10, {
  'iterative' => sub{ ifib(1 .. 30) },
  'pooled'    => sub{ afib(1 .. 30) },
});
