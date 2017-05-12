#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
#Games Magazine, July 2008 page 54
use Test::More tests => 6;

  package easy_as_one_two_three;

#our $xx = 0;
  sub new {return bless {count => 0}}
  sub set_rules {
    my $self = shift;
    my $parameters = shift;
    $self->{max_row} = $parameters->{max_row};
    $self->{max_column} = $parameters->{max_column};
    $self->{start} = $parameters->{start};
    $self->{position} = $parameters->{start};
    $self->{final} = $parameters->{final};
    $self->{not_allowed} = $parameters->{not_allowed};
    $self->{not_allowed_count} = 0;
    $self->{final_count} = 0;
    for my $i (0..$self->{max_row}) {
      for my $j (0..$self->{max_column}) {
        if ($self->{not_allowed}->[$i]->[$j]) {
          $self->{not_allowed_count}++;
        }
        else {
          $self->{final_count}++;
        }
      }
    }
    $self->{final_count} -= 1; #start 

  }

  sub move {
    my $self = shift;
    my $direction = shift;
    my $length = ++$self->{count} % 3;
    if ($length == 0) {$length = 3};
    my $row = $self->{position}->[0];
    my $column = $self->{position}->[1];

    if ($direction eq 'U' || $direction eq 'UL' || $direction eq 'UR') {
      if ($row - $length < 0) {return}
      else {$row -= $length}
    }
    if ($direction eq 'D' || $direction eq 'DL' || $direction eq 'DR') {
      if ($row + $length > $self->{max_row}) {return}
      else {$row += $length}
    }
    if ($direction eq 'L' || $direction eq 'DL' || $direction eq 'UL') {
      if ($column - $length < 0) {return}
      else {$column -= $length}
    }
    if ($direction eq 'R' || $direction eq 'DR' || $direction eq 'UR') {
      if ($column + $length > $self->{max_column}) {return}
      else {$column += $length}
    }

    if ($self->{value}->[$row]->[$column]) {
      return;
    }

    if (($self->{start}->[0]== $row) && ($self->{start}->[1] == $column)) {
      return;
    }

    if ($self->{not_allowed}->[$row]->[$column]) {
      return;
    }

    $self->{position} = [$row, $column];
    if (($self->{final}->[0]== $row) && ($self->{final}->[1] == $column)) {
      if ($self->{final_count} == $self->{count}) {return 1}
      return;
    }
    else {
      $self->{value}->[$row]->[$column] = $self->{count};
    }

    return 1;
  }

  sub copy {
    my $self = shift;
    my $copy = $self->new;
    $copy->{max_row} = $self->{max_row};
    $copy->{max_column} = $self->{max_column};
    $copy->{start} = $self->{start};
    $copy->{final} = $self->{final};
    $copy->{final_count} = $self->{final_count};
    $copy->{count} = $self->{count};
    $copy->{position} = $self->{position};
    $copy->{not_allowed} = $self->{not_allowed};
    $copy->{not_allowed_count} = $self->{not_allowed_count};

    for my $i (0..$self->{max_row}) {
      for my $j (0..$self->{max_column}) {
        $copy->{value}->[$i]->[$j] = $self->{value}->[$i]->[$j];
      }
    }

    return $copy;
  }

  sub is_solution {
    my $self = shift;
    if (($self->{position}->[0] == $self->{final}->[0])
     && ($self->{position}->[1] == $self->{final}->[1])) {
      return 1;
    }
    return 0;
  }

  sub next_moves {
    my $self = shift;

    return ('U','UL','UR','D','DL','DR','L','R');
  }

  sub board_out {
    my $self = shift;
    my $bo = '';
    for my $i (0..$self->{max_row}) {
      for my $j (0..$self->{max_column}) {
        if ($self->{value}->[$i]->[$j]) {
          $bo .= $self->{value}->[$i]->[$j]." ";
        }
        elsif (($self->{start}->[0]== $i) && ($self->{start}->[1] == $j)) {
          $bo .= "S ";
        }
        elsif (($self->{final}->[0]== $i) && ($self->{final}->[1] == $j)) {
          $bo .= "F ";
        }
        elsif ($self->{not_allowed}->[$i]->[$j]) {
          $bo .= "X ";
        }
        else {
          $bo .= "? ";
        }
      }
      $bo .= "\n";
    }
    return $bo;
  }

  package main;
  my @solutions;
  my $sol_count;
  use Algorithm::Search;
  my $puzzle = new easy_as_one_two_three;
  my $not_allowed;
  $not_allowed = [];
  $not_allowed->[2][2] = 1;
  $not_allowed->[3][0] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    start => [0,0],
    final => [2,1],
    not_allowed => $not_allowed,
  });

  my $puzzle_search = new Algorithm::Search();
  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>30000,
   solutions_to_find=>0,
   search_type => 'bfs'
  });
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
  @solutions = $puzzle_search->solutions;
#  $sol_count = 0;
#  foreach my $sol (@solutions) {
#    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
#    print STDERR "ps-$sol_count board 1 is\n".$sol->board_out."\n\n";
#    $sol_count++;
#  }
  is ($solutions[0]->board_out,
"S 1 9 6 
12 10 7 11 
3 F X 2 
X 4 8 5 
", "board 1");




#
#  $not_allowed = [];
#  $not_allowed->[2][1] = 1;
#  $puzzle->set_rules({
#    max_row => 3,
#    max_column => 3,
#    start => [1,0],
#    final => [3,0],
#    not_allowed => $not_allowed,
#  });
#
#  $puzzle_search = new Algorithm::Search();
#  $puzzle_search->search({search_this=>$puzzle,
#   max_steps=>30000,
#   solutions_to_find=>0,
#   search_type => 'bfs'
#  });
##  print STDERR "steps taken ".$puzzle_search->steps."\n";
##  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
#  @solutions = $puzzle_search->solutions;
##  $sol_count = 0;
##  foreach my $sol (@solutions) {
##    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
##    print STDERR "ps-$sol_count board 2 is\n".$sol->board_out."\n\n";
##    $sol_count++;
##  }
#  is ($solutions[0]->board_out,
#"4 3 5 12 
#S 1 13 10 
#8 X 7 9 
#F 2 6 11 
#", "board 2");
#






  $not_allowed = [];
  $not_allowed->[2][1] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    start => [1,0],
    final => [1,1],
    not_allowed => $not_allowed,
  });

  $puzzle_search = new Algorithm::Search();
  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>0,
   search_type => 'bfs'
  });
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
  @solutions = $puzzle_search->solutions;
#  $sol_count = 0;
#  foreach my $sol (@solutions) {
#    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
#    print STDERR "ps-$sol_count board 3 is\n".$sol->board_out."\n\n";
#    $sol_count++;
#  }
  is ($solutions[0]->board_out,
"1 9 5 12 
S F 10 13 
2 X 4 3 
11 8 6 7 
", "board 3");





  $not_allowed = [];
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    start => [1,1],
    final => [2,3],
    not_allowed => $not_allowed,
  });

  $puzzle_search = new Algorithm::Search();
  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>30000,
   solutions_to_find=>0,
   search_type => 'bfs'
  });
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
  @solutions = $puzzle_search->solutions;
#  $sol_count = 0;
#  foreach my $sol (@solutions) {
#    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
#    print STDERR "ps-$sol_count board 4 is\n".$sol->board_out."\n\n";
#    $sol_count++;
#  }
  is ($solutions[0]->board_out,
"5 2 13 12 
8 S 10 9 
14 1 4 F 
11 3 7 6 
", "board 4");




  $not_allowed = [];
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    start => [1,1],
    final => [3,3],
    not_allowed => $not_allowed,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>30000,
   solutions_to_find=>0,
   search_type => 'bfs'
  });
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
  @solutions = $puzzle_search->solutions;
#  $sol_count = 0;
#  foreach my $sol (@solutions) {
#    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
#    print STDERR "ps-$sol_count board 5 is\n".$sol->board_out."\n\n";
#    $sol_count++;
#  }
  is ($solutions[0]->board_out,
"14 8 3 4 
11 S 1 12 
6 7 13 5 
10 9 2 F 
", "board 5");




  $not_allowed = [];
  $not_allowed->[0][0] = 1;
  $not_allowed->[0][4] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 4,
    start => [3,1],
    final => [3,2],
    not_allowed => $not_allowed,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>30000,
   solutions_to_find=>0,
   search_type => 'bfs'
  });
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
  @solutions = $puzzle_search->solutions;
#  $sol_count = 0;
#  foreach my $sol (@solutions) {
#    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
#    print STDERR "ps-$sol_count board 6 is\n".$sol->board_out."\n\n";
#    $sol_count++;
#  }
  is ($solutions[0]->board_out,
"X 10 4 11 X 
2 9 16 3 8 
5 15 13 6 14 
1 S F 12 7 
", "board 6");




  $not_allowed = [];
  $not_allowed->[3][0] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 4,
    start => [1,1],
    final => [3,4],
    not_allowed => $not_allowed,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>20000,
   solutions_to_find=>1,
   search_type => 'dfs'
  });
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
  @solutions = $puzzle_search->solutions;
#  $sol_count = 0;
#  foreach my $sol (@solutions) {
#    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
#    print STDERR "ps-$sol_count board 7 is\n".$sol->board_out."\n\n";
#    $sol_count++;
#  }
  is ($solutions[0]->board_out,
"14 11 9 10 17 
2 S 1 3 7 
13 5 16 4 6 
X 12 8 15 F 
", "board 7");



#
#  $not_allowed = [];
#  $not_allowed->[4][0] = 1;
#  $puzzle->set_rules({
#    max_row => 4,
#    max_column => 4,
#    start => [1,2],
#    final => [2,0],
#    not_allowed => $not_allowed,
#  });
#
#  $puzzle_search->search({search_this=>$puzzle,
#   max_steps=>50000,
#   solutions_to_find=>1,
#   search_type => 'dfs'
#  });
##  print STDERR "steps taken ".$puzzle_search->steps."\n";
##  print STDERR "ps Number of solutions: ".$puzzle_search->{solutions_found}."\n";
#  @solutions = $puzzle_search->solutions;
##  $sol_count = 0;
##  foreach my $sol (@solutions) {
##    print STDERR "ps-$sol_count lo count ".$sol->{count}."\n";
##    print STDERR "ps-$sol_count board 8 is\n".$sol->board_out."\n\n";
##    $sol_count++;
##  }
#  is ($solutions[0]->board_out,
#"22 21 4 3 20 
#8 18 S 1 15 
#F 6 19 16 5 
#7 12 10 2 11 
#X 17 13 9 14 
#", "board 8");

