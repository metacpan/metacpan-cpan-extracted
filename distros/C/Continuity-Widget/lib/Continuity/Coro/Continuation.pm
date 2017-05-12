package Continuity::Coro::Continuation;

use strict;
use Coro;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(continuation yield);

our @yieldstack;

sub continuation (&) {
  my $code = shift;
  my $prev = new Coro::State;
  my $coro = Coro::State->new(sub {
    yield();
    $code->();
  });
  push @yieldstack, [$coro, $prev];
  $prev->transfer($coro);
  return sub {
    push @yieldstack, [$coro, $prev, @_];
    $prev->transfer($coro);
  };
}

sub yield {
  my ($coro, $prev) = @{pop @yieldstack};
  $coro->transfer($prev);
}

1;

