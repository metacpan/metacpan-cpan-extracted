#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use POSIX qw(floor);

use Data::Enumerable::Lazy;
use Data::Dumper qw(Dumper);

{

  # Prime number generator

  my $prime_num_stream = Data::Enumerable::Lazy->new({
    on_has_next => sub { 1 },
    on_next => sub {
      my $self = shift;
      my $next = $self->{_prev_} // 1;
      LOOKUP: while (1) {
        $next++;
        foreach (2..floor(sqrt($next))) {
          ($next % $_ == 0) and next LOOKUP;
        }
        last LOOKUP;
      }
      $self->{_prev_} = $next;
      $self->yield($next);
    },
  });

  my $list = $prime_num_stream->take(1000);
  is $list->[1000 - 1], 7919;
}

{
  # Fibonacci numbers

  my $fib_stream = Data::Enumerable::Lazy->new({
    on_has_next => sub { 1 },
    on_next => sub {
      my ($self) = @_;
      my ($a, $b) = @{ $self->{_fib_} // [0, 1] };
      $self->yield( ($self->{_fib_} = [$b, $a + $b])->[0] );
    },
  });

  is_deeply $fib_stream->take(10), [1, 1, 2, 3, 5, 8, 13, 21, 34, 55];
}

{
  # Pascal triangle

  my $pascal_stream = Data::Enumerable::Lazy->new({
    on_has_next => sub { 1 },
    on_next => sub {
      my ($self) = @_;
      my $ix = $self->{_pascal_ix_} // 0;
      my @prev_row = @{ $self->{_pascal_row_} // [] };
      $self->{_pascal_row_} = [
        map {
          $_ == 0 || $_ == ($ix) ? 1 : $prev_row[$_ - 1] + $prev_row[$_]
        } 0 .. $ix
      ];
      $self->{_pascal_ix_}++;
      $self->yield(sprintf('%i: %s', $ix, join(' ', @{ $self->{_pascal_row_} })));
    },
  });

#diag join("\n", @{ $pascal_stream->take(10) });
}

done_testing;
