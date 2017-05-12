#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 12;

my $loaded = 1;

  package fifteen;

  sub new {return bless {}}
  sub set_position {my $self = shift;
    my $string = shift;
    my @lines = split /\n/, $string;
    my $row = 0;
    foreach my $line (@lines) {
      my @numbers = split /\s+/, $line;
      $self->{board}->[$row] = \@numbers;
      foreach my $count (0..$#numbers) {
        if ($numbers[$count] == 0) {
          $self->{zero_at} = [$row, $count];
        }
      }
      $row++;
    }
  }
  sub value {
    my $self = shift;
    my $value;
    foreach my $row (@{$self->{board}}) {
      $value .= join(' ', @$row)."\n";
    }
    $value .= "zero: ".$self->{zero_at}->[0].$self->{zero_at}->[1];
    return $value;
  }

  sub move {
    my $self = shift;
    my $move = shift;
    $self->{board}->[$self->{zero_at}->[0]]->[$self->{zero_at}->[1]] =
     $self->{board}->[$move->[0]]->[$move->[1]];
    $self->{board}->[$move->[0]]->[$move->[1]] = 0;
    $self->{zero_at} = $move;
    my ($cost, $commit) = $self->distance_to_final_state;
    return $cost;
  }
  sub lock {
    my $self = shift;
    my $count = 1;
    my $number_locked = 20000;
    if ($self->{board}->[0]->[0] == 1) {
      $self->{locked}->[0]->[0] = 1;
      $number_locked = $number_locked - 100;
    }
    else {
      for my $i (0..3) {
        for my $j (0..3) {
          if (($self->{board}->[$i]->[$j]) == 1) {
            return $number_locked + $i + $j;
          }
        }
      }
    }
    if ($self->{board}->[0]->[1] == 2) {
      $self->{locked}->[0]->[1] = 1;
      $number_locked = $number_locked - 100;
    }
    else {
      for my $i (0..3) {
        for my $j (0..3) {
          if (($self->{board}->[$i]->[$j]) == 2) {
            return $number_locked + $i;
          }
        }
      }
    }
    if (($self->{board}->[0]->[2] == 3) && ($self->{board}->[0]->[3] == 4)) {
      $self->{locked}->[0]->[2] = 1;
      $self->{locked}->[0]->[3] = 1;
      $number_locked = $number_locked - 200;
    }
    else {
      for my $i (0..3) {
        for my $j (0..3) {
          if (($self->{board}->[$i]->[$j]) == 3) {
            return $number_locked + $i;
          }
        }
      }
    }
    if ($self->{board}->[1]->[0] == 5) {
      $self->{locked}->[1]->[0] = 1;
      $number_locked = $number_locked - 100;
    }
    else {
      for my $i (1..3) {
        for my $j (0..3) {
          if (($self->{board}->[$i]->[$j]) == 5) {
            return $number_locked + $i + $j;
          }
        }
      }
    }
    if ($self->{board}->[1]->[1] == 6) {
      $self->{locked}->[1]->[1] = 1;
      $number_locked = $number_locked - 100;
    }
    else {
      for my $i (1..3) {
        for my $j (0..3) {
          if (($self->{board}->[$i]->[$j]) == 6) {
            return $number_locked + $i;
          }
        }
      }
    }
    if (($self->{board}->[1]->[2] == 7) && ($self->{board}->[1]->[3] == 8)) {
      $self->{locked}->[1]->[2] = 1;
      $self->{locked}->[1]->[3] = 1;
      $number_locked = $number_locked - 200;
    }
    else {
      for my $i (1..3) {
        for my $j (0..3) {
          if (($self->{board}->[$i]->[$j]) == 7) {
            return $number_locked + $i;
          }
        }
      }
    }
  }
  sub copy {
    my $self = shift;
    my $copy = $self->new;
    $copy->{board} = [];
    foreach my $row (@{$self->{board}}) {
      push @{$copy->{board}}, [@$row];
    }
    $copy->{zero_at} = [@{$self->{zero_at}}];
    return $copy;
   }
our $full_count= 0;
  sub is_solution {
    my $self = shift;
    foreach my $i (0..3) {
      foreach my $j (0..3) {
        if ($self->{board}->[$i]->[$j]) {
          if (($j+1) + ($i*4) != $self->{board}->[$i]->[$j]) {
            return 0;
          }
        }
      }
    }
    return 1;
  }

  sub commit_level {
    my $self = shift;
    return $self->lock;
  }

  sub distance_to_final_state {
    my $self = shift;
    my $not_correct = 0;
    my $distance = 0;
    my $new_distance = 0;
    $self->{number_locked} = $self->lock;
    my @number_cost = (0);
    foreach my $i (0..3) {
      foreach my $j (0..3) {
        my $number = ($j+1) + ($i*4);
        if ($self->{board}->[$i]->[$j]) {
          $col = ($self->{board}->[$i]->[$j] - 1) % 4;
          $row = int(($self->{board}->[$i]->[$j] - 1) / 4);
          $number_cost[$self->{board}->[$i]->[$j]] =
           (abs($col - $j) + abs($row-$i));
          if (($j+1) + ($i*4) != $self->{board}->[$i]->[$j]) {
             $not_correct++;
             $distance += ($j+1) + ($i*4);
          }
        }
      }
    }
    my $count = 0;
    for my $i (1..15) {
      if ($number_cost[$i]) {
        $new_distance += $number_cost[$i];
        if (++$count == 2) {last};
      }
    }
#print STDERR $self->value."\n";
#print STDERR "nc ".join (" ",@number_cost)."\n";
#print STDERR "nd $new_distance\n";
#print STDERR "end \n";
#if ($full_count++ == 8) {exit};
#print STDERR "nd $new_distance and d $distance\n";
#print "NC is $not_correct\n";
    return ($not_correct,$self->{number_locked});
  }

  sub next_moves {
    my $self = shift;
    my @moves;
    if ($self->{zero_at}->[0] > 0) {
      if (!(
       $self->{locked}->[$self->{zero_at}->[0]-1]->[$self->{zero_at}->[1]]
       ))
      {
        push @moves, [$self->{zero_at}->[0]-1,$self->{zero_at}->[1]];
      }
    }
    if ($self->{zero_at}->[0] < 3) {
      push @moves, [$self->{zero_at}->[0]+1,$self->{zero_at}->[1]];
    }
    if ($self->{zero_at}->[1] > 0) {
      if (!(
       $self->{locked}->[$self->{zero_at}->[0]]->[$self->{zero_at}->[1]-1]
       ))
      {
        push @moves, [$self->{zero_at}->[0],$self->{zero_at}->[1]-1];
      }
    }
    if ($self->{zero_at}->[1] < 3) {
      push @moves, [$self->{zero_at}->[0],$self->{zero_at}->[1]+1];
    }
    return @moves;
  }

  package main;
  use Algorithm::Search;
  my $puzzle = new fifteen;

  $puzzle->set_position(
'1 2 3 4
5 6 7 8
9 10 11 12
13 14 15 0');

#  print "pvalue is ".$puzzle->value."\n";

  if (!($puzzle->distance_to_final_state)) {
#    print "s1 in final\n";
  }
  else {
#    print "s1 not in final\n";
  }

  $puzzle->set_position(
'1 2 3 4
5 6 7 8
9 10 11 12
13 14 0 15');

#  print "pvalue is ".$puzzle->value."\n";
  if (!($puzzle->distance_to_final_state)) {
#    print "s2 in final\n";
  }
  else {
#    print "s2 not in final\n";
  }

  my $fifteen_search = new Algorithm::Search();
  $fifteen_search->search({search_this=>$puzzle,
   solutions_to_find=>1,
   search_type => 'bfs',
  });
#  print "Solution found :\n";
  is_deeply ($fifteen_search->path,
   [
          [
            3,
            3
          ]
        ], 'one move problem');

#  $puzzle->set_position(
#'10 12 7 3
#5 13 8 4
#9 11 2 0
#15 14 1 6');
#
#  my ($ic,undef) = $puzzle->distance_to_final_state;
##  print STDERR "pvalue is ".$puzzle->value."\n";
#  $fifteen_search->search({search_this=>$puzzle,
#   solutions_to_find=>1,
#   search_type => 'cost',
#   initial_cost => $ic,
#   do_not_repeat_values => 1,
##   stop_search => sub {
##     my $self = shift;
##     my $steps = shift;
##     if ($steps % 5000 == 0) {
##   print STDERR "steps is $steps and self is ".$self->value."\n";
##     }
##   return 0;
##   },
#   max_steps => 200000
#  });
#  print "NSolution found :\n";
##  use Data::Dumper;
##  print STDERR Dumper($fifteen_search->path)."\n";
#  is_deeply($fifteen_search->path,
#      [
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            1,
#            0
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            0,
#            0
#          ],
#          [
#            1,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            1,
#            1
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            0,
#            2
#          ],
#          [
#            0,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            1,
#            2
#          ],
#          [
#            1,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            0
#          ],
#          [
#            2,
#            0
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            3
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            3,
#            2
#          ],
#          [
#            3,
#            1
#          ],
#          [
#            2,
#            1
#          ],
#          [
#            2,
#            2
#          ],
#          [
#            2,
#            3
#          ],
#          [
#            3,
#            3
#          ]
#        ], 'xharder problem');

  $puzzle->set_position(
'1 14 10 4
5 0 6 8
9 11 2 12
13 7 3 15');

#  print "pvalue is ".$puzzle->value."\n";
  if (!($puzzle->distance_to_final_state)) {
#    print "s2 in final\n";
  }
  else {
#    print "s2 not in final\n";
  }

#  $fifteen_search->search({search_this=>$puzzle,
#   max_steps => 200000,
#   solutions_to_find=>1,
#   search_type => 'bfs',
#   do_not_repeat_values => 1,
##   stop_search => sub {
##     my $self = shift;
##     my $steps = shift;
##     if ($steps % 5000 == 0) {
##   print STDERR "steps is $steps and self is ".$self->value."\n";
##   print STDERR " distance, commit ".join(" ", $self->distance_to_final_state)."\n";
##     }
##   return 0;
##   },
#  });
#  is($fifteen_search->{steps}, 25211, 'number of steps');

  $fifteen_search->search({search_this=>$puzzle,
   max_steps => 20000,
   solutions_to_find=>1,
   search_type => 'bfs',
   do_not_repeat_values => 1,
  });
  is($fifteen_search->{steps}, 20000, 'number of steps 2');

  $fifteen_search->continue_search({additional_steps => 2000});
  is($fifteen_search->{steps}, 22000, 'number of steps 3');

  is($fifteen_search->{search_completed},0,'search not completed yet');

  $fifteen_search->continue_search({additional_steps => 310});
  is($fifteen_search->{steps}, 22310, 'number of steps 4');

  is($fifteen_search->{search_completed},0,'search not completed ');

  $fifteen_search->continue_search({additional_steps => 2});
  is($fifteen_search->{steps}, 22312, 'number of steps 5');

  $fifteen_search->continue_search({additional_steps =>2898});
  is($fifteen_search->{steps}, 25210, 'number of steps 6');

  is($fifteen_search->{search_completed},0,'search still not completed ');

  $fifteen_search->continue_search({additional_steps =>2});
  is($fifteen_search->{steps}, 25211, 'number of steps 7');

  is($fifteen_search->{search_completed},1,'search completed ');

#  use Data::Dumper;
#  print STDERR Dumper($fifteen_search->path)."\n";
  is_deeply ( $fifteen_search->path,
       [
          [
            1,
            2
          ],
          [
            2,
            2
          ],
          [
            2,
            1
          ],
          [
            1,
            1
          ],
          [
            0,
            1
          ],
          [
            0,
            2
          ],
          [
            1,
            2
          ],
          [
            1,
            1
          ],
          [
            0,
            1
          ],
          [
            0,
            2
          ],
          [
            1,
            2
          ],
          [
            2,
            2
          ],
          [
            3,
            2
          ],
          [
            3,
            1
          ],
          [
            2,
            1
          ],
          [
            1,
            1
          ],
          [
            1,
            2
          ],
          [
            2,
            2
          ],
          [
            2,
            3
          ],
          [
            1,
            3
          ],
          [
            0,
            3
          ],
          [
            0,
            2
          ],
          [
            1,
            2
          ],
          [
            2,
            2
          ],
          [
            2,
            3
          ],
          [
            1,
            3
          ],
          [
            0,
            3
          ],
          [
            0,
            2
          ],
          [
            1,
            2
          ],
          [
            1,
            3
          ],
          [
            2,
            3
          ],
          [
            2,
            2
          ],
          [
            1,
            2
          ],
          [
            0,
            2
          ],
          [
            0,
            3
          ],
          [
            1,
            3
          ],
          [
            2,
            3
          ],
          [
            2,
            2
          ],
          [
            2,
            1
          ],
          [
            3,
            1
          ],
          [
            3,
            2
          ],
          [
            2,
            2
          ],
          [
            1,
            2
          ],
          [
            1,
            1
          ],
          [
            2,
            1
          ],
          [
            3,
            1
          ],
          [
            3,
            2
          ],
          [
            2,
            2
          ],
          [
            2,
            1
          ],
          [
            3,
            1
          ],
          [
            3,
            2
          ],
          [
            3,
            3
          ],
          [
            2,
            3
          ],
          [
            1,
            3
          ],
          [
            1,
            2
          ],
          [
            2,
            2
          ],
          [
            3,
            2
          ],
          [
            3,
            3
          ],
          [
            2,
            3
          ],
          [
            1,
            3
          ],
          [
            1,
            2
          ],
          [
            2,
            2
          ],
          [
            2,
            3
          ],
          [
            3,
            3
          ],
          [
            3,
            2
          ],
          [
            2,
            2
          ],
          [
            1,
            2
          ],
          [
            1,
            3
          ],
          [
            2,
            3
          ],
          [
            2,
            2
          ],
          [
            3,
            2
          ],
          [
            3,
            1
          ],
          [
            2,
            1
          ],
          [
            2,
            2
          ],
          [
            3,
            2
          ],
          [
            3,
            3
          ],
          [
            2,
            3
          ],
          [
            2,
            2
          ],
          [
            2,
            1
          ],
          [
            3,
            1
          ],
          [
            3,
            2
          ],
          [
            3,
            3
          ]
        ],
       'correct search path'
  );
