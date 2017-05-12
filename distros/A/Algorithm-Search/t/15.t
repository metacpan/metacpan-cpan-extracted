#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 9;

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
  sub is_solution {
    my $self = shift;
    foreach my $i (0..3) {
      foreach my $j (0..3) {
        if (($self->{board}->[$i]->[$j]) &&
         (($j+1) + ($i*4) != $self->{board}->[$i]->[$j])) {
          return 0;
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
    $self->{number_locked} = $self->lock;
    foreach my $i (0..3) {
      foreach my $j (0..3) {
        if (($self->{board}->[$i]->[$j]) &&
         (($j+1) + ($i*4) != $self->{board}->[$i]->[$j])) {
          return (1 + $self->{number_locked}, 1 + $self->{number_locked});
        }
      }
    }
    return (0,0);
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
   search_type => 'bfs'
  });
#  print "Solution found :\n";
#  use Data::Dumper;
#  print Dumper($fifteen_search->path)."\n";
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
#  print "pvalue is ".$puzzle->value."\n";
#  $fifteen_search->search({search_this=>$puzzle,
#   solutions_to_find=>1,
#   search_type => 'bfs',
#   do_not_repeat_values => 1,
#   max_steps => 200000
#  });
#  print "NSolution found :\n";
#  use Data::Dumper;
#  print Dumper($fifteen_search->path)."\n";
#  is_deeply($fifteen_search->path,
#   [
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
#            1,
#            1
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
#            3
#          ],
#          [
#            3,
#            3
#          ]
#        ], 'harder problem');

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
#   max_steps => 40000,
#   solutions_to_find=>1,
#   search_type => 'bfs',
#   do_not_repeat_values => 1,
#  });
#  is($fifteen_search->{steps}, 25211, 'number of steps');
#
#  $fifteen_search->search({search_this=>$puzzle,
#   max_steps => 40000,
#   solutions_to_find=>1,
#   search_type => 'bfs',
#   do_not_repeat_values => 1,
#  });
#  is($fifteen_search->{steps}, 25211, 'number of steps a second time');

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

  $fifteen_search->continue_search({additional_steps => 3210});
  is($fifteen_search->{steps}, 25210, 'number of steps 4');

  is($fifteen_search->{search_completed},0,'search not completed ');

  $fifteen_search->continue_search({additional_steps => 2});
  is($fifteen_search->{steps}, 25211, 'number of steps 5');

  is($fifteen_search->{search_completed},1,'search completed ');

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
