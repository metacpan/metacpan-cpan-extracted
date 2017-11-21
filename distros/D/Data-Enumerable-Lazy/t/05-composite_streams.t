#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Enumerable::Lazy;

{
  my $i = 0;

  my $stream = Data::Enumerable::Lazy->new({
    on_has_next => sub { $i < 10 },
    on_next => sub {
      my $j = 1;
      $i++;
      shift->yield(Data::Enumerable::Lazy->new({
        on_has_next => sub { $j <= 10 },
        on_next => sub { shift->yield($i * ($j++)) },
      }))
    },
    is_finite => 1,
  });

  is_deeply $stream->to_list, [map { my $i = $_; map { $_ * $i} 1..10  } 1..10]
}

{
  my $mult_table = Data::Enumerable::Lazy->from_list(1..10)->continue({
    on_next => sub {
      my ($self, $i) = @_;
      $self->yield(Data::Enumerable::Lazy->from_list(1..10)->continue({
        on_next => sub {
          $_[0]->yield( $_[1] * $i )
        }, 
      }));
    },
  });
  is_deeply $mult_table->to_list, [map { my $i = $_; map { $_ * $i} 1..10  } 1..10]
}

{
  my $i = 0 ;

  my $stream = Data::Enumerable::Lazy->new({
    on_has_next => sub { 1 },
    on_next => sub {
      Data::Enumerable::Lazy->new({
        on_has_next => sub { 1 },
        on_next => sub {
          Data::Enumerable::Lazy->new({
            on_has_next => sub { $i == 0 },
            on_next => sub { shift->yield($i++) }
          })
        }
      })
    },
  });

  is_deeply $stream->next, 0;
}

done_testing;
