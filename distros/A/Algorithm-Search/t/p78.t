#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
#Games Magazine, July 2008 page 78
use Test::More tests => 2;

  package sum_product;

  our $known_max = 0;
  our $max_at;

  sub new {return bless {product => 1, sum => 0}}

  sub value {
    my $self = shift;
    return join("..",sort keys %{$self->{values}});
  }

  sub move {
    my $self = shift;
    my $number = shift;

    if ($self->{values}) {
      $self->{values} .= "..$number";
    }
    else {
      $self->{values} .= $number;
    }
    $self->{max} = $number;
    $self->{sum} += $number;
    $self->{product} *= $number;
    if ($self->{sum} == 32)  {
      if ($self->{product} > $known_max) {
        $known_max = $self->{product};
        $max_at = $self->{values};
      }
    }

    return 1;
  }

  sub copy {
    my $self = shift;
    my $copy = $self->new;
    $copy->{sum} = $self->{sum};
    $copy->{product} = $self->{product};
    $copy->{max} = $self->{max};
    $copy->{values} = $self->{values};

    return $copy;
  }

  sub next_moves {
    my $self = shift;
    $self->{max} = $self->{max} || 0;
    $self->{sum} = $self->{sum} || 0;
    return ($self->{max}+1..(32-$self->{sum}));
  }

#  sub distance_to_final_state {
#    return 1;
#  }


  package main;
  my @solutions;
  my $sol_count;
  use Algorithm::Search;
  my $puzzle = new sum_product;

  my $puzzle_search = new Algorithm::Search();
  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>30000,
   solutions_to_find=>0,
   no_value_function => 1,
   search_type => 'bfs'
  });

  is ($sum_product::known_max, 13440);
  is ($sum_product::max_at, '2..4..5..6..7..8');
#  print STDERR $sum_product::known_max."\n";
#  print STDERR $sum_product::max_at."\n";
