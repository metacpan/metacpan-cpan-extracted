#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
#Games Magazine, July 2008 page 28
use Test::More tests => 22;

  package pearls_of_wisdom;

#our $xx = 0;
  sub new {my $self = {moves => 1, row => 0, column => 0};
   $self->{value}->[0]->[0] = 1; return bless $self}
  sub set_rules {
    my $self = shift;
    my $parameters = shift;
    $self->{max_row} = $parameters->{max_row};
    $self->{max_column} = $parameters->{max_column};
    $self->{in_moves} = $parameters->{in_moves};
    $self->{fixed_value} = $parameters->{fixed_value};
  }

  sub move {
    my $self = shift;
    my $move = shift;

#$xx++;
#print STDERR "Considering move $move, current row ".$self->{row};
#print STDERR " current column ".$self->{column};
#print STDERR " $xx move number ".$self->{moves};
#print STDERR "\n";
    if ($move eq 'U') {
#print STDERR "considering U move\n";
      if ($self->{row} == 0) { return}
      else {
        $self->{value}->[$self->{row}]->[$self->{column}] .= 'U';
        $self->{row}--;
      };
    }
    elsif ($move eq 'D') {
      if ($self->{row} == $self->{max_row}) { return}
      else {
        $self->{value}->[$self->{row}]->[$self->{column}] .= 'D';
        $self->{row}++
      };
    }
    elsif ($move eq 'L') {
      if ($self->{column} == 0) { return}
      else {
        $self->{value}->[$self->{row}]->[$self->{column}] .= 'L';
        $self->{column}--;
      };
    }
    elsif ($move eq 'R') {
      if ($self->{column} == $self->{max_column}) { return}
      else {
        $self->{value}->[$self->{row}]->[$self->{column}] .= 'R';
        $self->{column}++
      };
    }
#print STDERR "did not max out move\n";

    if (defined $self->{in_moves}->[$self->{row}]->[$self->{column}]) {
      $self->{out_moves}->[$self->{row}]->[$self->{column}] =
       $self->{in_moves}->[$self->{row}]->[$self->{column}]->{$move} || [];
#print STDERR "set moves out ".join("..",@{$self->{out_moves}->[$self->{row}]->[$self->{column}]})."\n";
    }

    if (defined $self->{value}->[$self->{row}]->[$self->{column}]) {
      return
    }

    my $value = ($self->{moves} + 1) %3;
    if ($value == 0) {$value = 3};

    if (defined $self->{fixed_value}->[$self->{row}]->[$self->{column}]
     && $value != $self->{fixed_value}->[$self->{row}]->[$self->{column}]) {
#print STDERR "rejecting bad value\n";
      return;
    }

    $self->{moves}++;

    $self->{value}->[$self->{row}]->[$self->{column}] = $move.$value;
    return 0;
  }

  sub copy {
    my $self = shift;
    my $copy = $self->new;
    $copy->{max_row} = $self->{max_row};
    $copy->{max_column} = $self->{max_column};
    $copy->{in_moves} = $self->{in_moves};
    $copy->{fixed_value} = $self->{fixed_value};

    $copy->{moves} = $self->{moves};
    $copy->{row} = $self->{row};
    $copy->{column} = $self->{column};
    for my $i (0..$self->{max_row}) {
      for my $j (0..$self->{max_column}) {
        $copy->{value}->[$i]->[$j] = $self->{value}->[$i]->[$j];
      }
    }

    return $copy;
  }
  sub distance_to_final_state {
    my $self = shift;
    return ($self->{max_row}+1) * ($self->{max_column}+1) - $self->{moves};
  }
  sub is_solution {
    my $self = shift;
    if ($self->distance_to_final_state > 0) { return 0};
    return 1;
  }

  sub next_moves {
    my $self = shift;

    if (defined $self->{out_moves}->[$self->{row}]->[$self->{column}]) {
#  print STDERR "have out moves \n";
      return @{$self->{out_moves}->[$self->{row}]->[$self->{column}]};
    }
    return ('U','D','L','R');
  }

  sub board_out {
    my $self = shift;
    my $bo = '';
    for my $i (0..$self->{max_row}) {
      for my $j (0..$self->{max_column}) {
        if (defined $self->{value}->[$i]->[$j]) {
          $bo .= $self->{value}->[$i]->[$j]." ";
        }
        else {
          $bo .= "X0X ";
        }
      }
      $bo .= "\n";
    }
    return $bo;
  }

  package main;
  use Algorithm::Search;
  my $puzzle = new pearls_of_wisdom;
  my $in_moves = [];
  my $fixed_value = [];
  $in_moves->[0][1] = {'R'=>['R','D'], 'L'=>['L'], 'U'=>['L']};
  $in_moves->[1][1] = {'R'=>['R'], 'L'=>['L','D','U'], 'U'=>['R'], 'D'=>['R']};
  $in_moves->[1][2] = {'R'=>['D'], 'U'=>['L']};
  $in_moves->[2][2] = {'R'=>['U'], 'U'=>['U'], 'L'=>['U'], 'D'=>['L','R','D']};
  $fixed_value->[1][2] = 3;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  my $puzzle_search = new Algorithm::Search();
  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>1000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
#  print STDERR "board 1 is\n".$puzzle_search->last_object->board_out."\n\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1D 
L2D L1L U3L D2D 
D3D U1R R2U D3D 
D1 L3U L2L D1L 
",
"board 1 bfs");


  $in_moves = [];
  $fixed_value = [];
  $in_moves->[2][1] = {U=>['U'],D=>['D']};
  $in_moves->[1][1] = {U=>['L','R','U'],D=>['D'],L=>['D'],R=>['D']};
  $in_moves->[3][1] = {D=>['L','R'],L=>['U'],R=>['U']};
  $fixed_value->[2][2] = 3;
  $fixed_value->[3][3] = 2;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>3000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 2 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1D L1 L3L U2L 
D2D U1R R2D U1U 
D3D U3U D3D U3U 
D1R R2U D1R R2U 
",
"board 2 bfs");



  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {D=>['R'],U=>['R'],L=>['U','D']};
  $in_moves->[1][1] = {L=>['L'],R=>['R']};
  $in_moves->[2][1] = {L=>['D','L'],R=>['R'],U=>['R']};
  $in_moves->[1][2] = {L=>['L'],R=>['U','D','R'],D=>['L'],U=>['L']};
  $in_moves->[2][2] = {L=>['L'],R=>['R','U','D'],U=>['L'],D=>['L']};
  $fixed_value->[1][1] = 2;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>3000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 3 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3D U1 
L3D L2L D1L U3U 
D1D U1R R2D U2U 
D2R R3U D3R R1U 
",
"board 3 bfs");



  $in_moves = [];
  $fixed_value = [];
  $in_moves->[0][1] = {L=>['L','D'],R=>['R'],U=>['R']};
  $in_moves->[1][0] = {L=>['D'],D=>['D'],U=>['R']};
  $in_moves->[2][0] = {U=>['U'],D=>['D']};
  $in_moves->[3][0] = {D=>['R'],L=>['U']};
  $in_moves->[3][2] = {D=>['R'],L=>['U']};
  $in_moves->[3][3] = {D=>['L'],R=>['U']};
  $in_moves->[2][2] = {D=>['D'],R=>['D'],L=>['D'],U=>['R','L','U']};
  $fixed_value->[2][0] = 3;
  $fixed_value->[3][2] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 4 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1D L1 L3L U2L 
D2D U1R R2D U1U 
D3D U3U D3D U3U 
D1R R2U D1R R2U 
",
"board 4 bfs");



#puzzle 5
  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][3] = {L=>['L','D','U'],R=>['R'],U=>['R'],D=>['R']};
  $in_moves->[1][4] = {R=>['U','D'],U=>['L'],D=>['L']};
  $in_moves->[3][2] = {R=>['D'],L=>['D'],D=>['D'],U=>['L','R','U']};
  $in_moves->[4][2] = {R=>[],L=>[],D=>[],U=>[]};
  $fixed_value->[0][3] = 2;
  $fixed_value->[2][0] = 3;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>200000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "puzzle 5 steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 5 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1D U3R R1R R2R R3D 
D2D L2U U1L L2D D1L 
D3D U2R R3U D3R R1D 
D1D U1U L3D U2L D2D 
D2R R3U D1 L1U D3L 
",
"board 5 bfs");



  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {U=>['R'],D=>['R'], L=>['D','U']};
  $in_moves->[1][1] = {R=>['R'],L=>['L']};
  $in_moves->[1][2] = {R=>['U','D','R'],L=>['L'],D=>['L'],U=>['L']};
  $in_moves->[2][1] = {R=>['D'],L=>['D'],U=>['L','R']};
  $in_moves->[3][1] = {R=>['U'],L=>['U'],U=>['U'],D=>['R','L','D']};
  $in_moves->[4][3] = {R=>['R'],D=>['R']};
  $in_moves->[4][4] = {};
  $fixed_value->[1][1] = 1;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 6 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "distance 6 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1R R2D 
L2D L1L L3L U2L D3D 
D3D U2R R3D U1U D1D 
D1D U1U D1D L3U D2L 
D2R R3U D2R R3R R1 
",
"board 6 bfs");




  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {U=>['R'],D=>['D'], L=>['D']};
  $in_moves->[2][0] = {U=>['U'],D=>['D']};
  $in_moves->[3][0] = {L=>['U'],D=>['R', 'D'],U=>['U']};
  $in_moves->[2][1] = {L=>['D'],D=>['D'],U=>['U','R']};
  $in_moves->[3][1] = {L=>['U'],U=>['U'],R=>['U'],D=>['L','R','D']};
  $in_moves->[2][4] = {R=>['D'],D=>['D'],U=>['L','U']};
  $in_moves->[3][4] = {D=>['D'],U=>['U']};
  $in_moves->[4][4] = {D=>['L'],R=>['U']};
  $fixed_value->[1][3] = 1;
  $fixed_value->[2][0] = 1;
  $fixed_value->[3][4] = 1;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'bfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 7 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "distance 7 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1R R2D 
U2R R3R R1D L1D D3L 
U1U L3D D2L D2R R3D 
U3U D1 L2D U1L D1D 
L2U L1L D3L L3U D2L 
",
"board 7 bfs");






#TAKESTOOLONG#
#TAKESTOOLONG#  $in_moves = [];
#TAKESTOOLONG#  $fixed_value = [];
#TAKESTOOLONG#  $in_moves->[1][4] = {L=>['U'],D=>['R']};
#TAKESTOOLONG#  $in_moves->[0][4] = {L=>['D'],R=>['D'], U=>['L','R']};
#TAKESTOOLONG#  $in_moves->[1][5] = {D=>['R'],U=>['R'], R=>['U','D']};
#TAKESTOOLONG#  $in_moves->[4][1] = {U=>['U'],D=>['D']};
#TAKESTOOLONG#  $in_moves->[3][1] = {U=>['U','L','R'],D=>['D'],L=>['D'],R=>['D']};
#TAKESTOOLONG#  $in_moves->[5][1] = {D=>['L','R'],L=>['U'],R=>['U']};
#TAKESTOOLONG#  $in_moves->[3][4] = {U=>['L'],R=>['D']};
#TAKESTOOLONG#  $in_moves->[3][3] = {U=>['R'],D=>['R'],R=>['R'],L=>['U','D','L']};
#TAKESTOOLONG#  $in_moves->[4][4] = {U=>['U'],D=>['R','L','D'],R=>['U'],L=>['U']};
#TAKESTOOLONG#  $fixed_value->[3][4] = 3;
#TAKESTOOLONG#  $fixed_value->[4][1] = 3;
#TAKESTOOLONG#  $puzzle->set_rules({
#TAKESTOOLONG#    max_row => 5,
#TAKESTOOLONG#    max_column => 5,
#TAKESTOOLONG#    in_moves => $in_moves,
#TAKESTOOLONG#    fixed_value => $fixed_value,
#TAKESTOOLONG#  });
#TAKESTOOLONG#
#TAKESTOOLONG#  $puzzle_search->search({search_this=>$puzzle,
#TAKESTOOLONG#   max_steps=>300000,
#TAKESTOOLONG#   solutions_to_find=>1,
#TAKESTOOLONG#   no_value_function => 1,
#TAKESTOOLONG#   search_type => 'bfs'
#TAKESTOOLONG#  });
#TAKESTOOLONG##  print STDERR "search done found :\n";
#TAKESTOOLONG#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#TAKESTOOLONG#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#TAKESTOOLONG#  use Data::Dumper;
#TAKESTOOLONG##  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#TAKESTOOLONG#  print STDERR "board 8 is\n".$puzzle_search->last_object->board_out."\n\n";
#TAKESTOOLONG#  print STDERR "distance 8 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#TAKESTOOLONG##  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
#TAKESTOOLONG#  is ($puzzle_search->last_object->board_out,
#TAKESTOOLONG#"1R R2R R3D U2R R3D U3 
#TAKESTOOLONG#L3D L2L D1L U1U D1R R2U 
#TAKESTOOLONG#D1D U2R R3D L3U L2L U1L 
#TAKESTOOLONG#D2D U1U D1R R2R R3D U3U 
#TAKESTOOLONG#D3D U3U L3D L2L D1L U2U 
#TAKESTOOLONG#D1R R2U D1R R2R R3R R1U 
#TAKESTOOLONG#",
#TAKESTOOLONG#"board 8 bfs");
#TAKESTOOLONG#






##
##
##  $in_moves = [];
##  $fixed_value = [];
##  $in_moves->[1][1] = {L=>['D'],U=>['R']};
##  $in_moves->[1][2] = {L=>['L'],U=>['L'], D=>['L'], R=>['U','D','R']};
##  $in_moves->[2][1] = {D=>['R','L','D'],U=>['U'], R=>['U'],L=>['U']};
##  $in_moves->[1][4] = {R=>['U'],D=>['L']};
##  $in_moves->[1][3] = {R=>['R'],D=>['R'],U=>['R'],L=>['U','D','L']};
##  $in_moves->[0][4] = {R=>['D'],L=>['D'],U=>['R','L']};
##  $in_moves->[4][3] = {R=>['R'],L=>['L']};
##  $in_moves->[4][2] = {R=>['R'],U=>['R'],D=>['R'],L=>['L','U','D']};
##  $in_moves->[4][4] = {L=>['L'],U=>['L'],D=>['L'],R=>['R','U','D']};
##  $fixed_value->[1][1] = 1;
##  $fixed_value->[1][4] = 3;
##  $fixed_value->[4][3] = 1;
##  $puzzle->set_rules({
##    max_row => 5,
##    max_column => 5,
##    in_moves => $in_moves,
##    fixed_value => $fixed_value,
##  });
##
##  $puzzle_search->search({search_this=>$puzzle,
##   max_steps=>300000,
##   solutions_to_find=>1,
##   no_value_function => 1,
##   search_type => 'bfs'
##  });
###  print STDERR "search done found :\n";
###  print STDERR "steps taken ".$puzzle_search->steps."\n";
###  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
##  use Data::Dumper;
###  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
###  print STDERR "board 9 is\n".$puzzle_search->last_object->board_out."\n\n";
###  print STDERR "distance 9 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
###  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
##  is ($puzzle_search->last_object->board_out,
##"1R R2R R3R R1D U1R R2D 
##U3 L1D U3L D2R R3U D3D 
##U2U D2D U2U L2D U1L D1D 
##L1U D3L L1U D3L U3U D2D 
##U1R R2R R3R R1R R2U D3D 
##L3U L2L L1L L3L L2L D1L 
##", "board 9 bfs");
##

#  print STDERR "dfs\n";

  $in_moves = [];
  $fixed_value = [];
  $in_moves->[0][1] = {'R'=>['R','D'], 'L'=>['L'], 'U'=>['L']};
  $in_moves->[1][1] = {'R'=>['R'], 'L'=>['L','D','U'], 'U'=>['R'], 'D'=>['R']};
  $in_moves->[1][2] = {'R'=>['D'], 'U'=>['L']};
  $in_moves->[2][2] = {'R'=>['U'], 'U'=>['U'], 'L'=>['U'], 'D'=>['L','R','D']};
  $fixed_value->[1][2] = 3;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>1000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
#  print STDERR "board 1 is\n".$puzzle_search->last_object->board_out."\n\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1D 
L2D L1L U3L D2D 
D3D U1R R2U D3D 
D1 L3U L2L D1L 
",
"board 1 dfs");


  $in_moves = [];
  $fixed_value = [];
  $in_moves->[2][1] = {U=>['U'],D=>['D']};
  $in_moves->[1][1] = {U=>['L','R','U'],D=>['D'],L=>['D'],R=>['D']};
  $in_moves->[3][1] = {D=>['L','R'],L=>['U'],R=>['U']};
  $fixed_value->[2][2] = 3;
  $fixed_value->[3][3] = 2;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>3000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 2 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1D L1 L3L U2L 
D2D U1R R2D U1U 
D3D U3U D3D U3U 
D1R R2U D1R R2U 
",
"board 2 dfs");


  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {D=>['R'],U=>['R'],L=>['U','D']};
  $in_moves->[1][1] = {L=>['L'],R=>['R']};
  $in_moves->[2][1] = {L=>['D','L'],R=>['R'],U=>['R']};
  $in_moves->[1][2] = {L=>['L'],R=>['U','D','R'],D=>['L'],U=>['L']};
  $in_moves->[2][2] = {L=>['L'],R=>['R','U','D'],U=>['L'],D=>['L']};
  $fixed_value->[1][1] = 2;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>3000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 3 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3D U1 
L3D L2L D1L U3U 
D1D U1R R2D U2U 
D2R R3U D3R R1U 
",
"board 3 dfs");



  $in_moves = [];
  $fixed_value = [];
  $in_moves->[0][1] = {L=>['L','D'],R=>['R'],U=>['R']};
  $in_moves->[1][0] = {L=>['D'],D=>['D'],U=>['R']};
  $in_moves->[2][0] = {U=>['U'],D=>['D']};
  $in_moves->[3][0] = {D=>['R'],L=>['U']};
  $in_moves->[3][2] = {D=>['R'],L=>['U']};
  $in_moves->[3][3] = {D=>['L'],R=>['U']};
  $in_moves->[2][2] = {D=>['D'],R=>['D'],L=>['D'],U=>['R','L','U']};
  $fixed_value->[2][0] = 3;
  $fixed_value->[3][2] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 4 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1D L1 L3L U2L 
D2D U1R R2D U1U 
D3D U3U D3D U3U 
D1R R2U D1R R2U 
",
"board 4 dfs");



#puzzle 5
  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][3] = {L=>['L','D','U'],R=>['R'],U=>['R'],D=>['R']};
  $in_moves->[1][4] = {R=>['U','D'],U=>['L'],D=>['L']};
  $in_moves->[3][2] = {R=>['D'],L=>['D'],D=>['D'],U=>['L','R','U']};
  $in_moves->[4][2] = {R=>[],L=>[],D=>[],U=>[]};
  $fixed_value->[0][3] = 2;
  $fixed_value->[2][0] = 3;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>200000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "puzzle 5 steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 5 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1D U3R R1R R2R R3D 
D2D L2U U1L L2D D1L 
D3D U2R R3U D3R R1D 
D1D U1U L3D U2L D2D 
D2R R3U D1 L1U D3L 
",
"board 5 dfs");



  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {U=>['R'],D=>['R'], L=>['D','U']};
  $in_moves->[1][1] = {R=>['R'],L=>['L']};
  $in_moves->[1][2] = {R=>['U','D','R'],L=>['L'],D=>['L'],U=>['L']};
  $in_moves->[2][1] = {R=>['D'],L=>['D'],U=>['L','R']};
  $in_moves->[3][1] = {R=>['U'],L=>['U'],U=>['U'],D=>['R','L','D']};
  $in_moves->[4][3] = {R=>['R'],D=>['R']};
  $in_moves->[4][4] = {};
  $fixed_value->[1][1] = 1;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 6 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "distance 6 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1R R2D 
L2D L1L L3L U2L D3D 
D3D U2R R3D U1U D1D 
D1D U1U D1D L3U D2L 
D2R R3U D2R R3R R1 
",
"board 6 dfs");





  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {U=>['R'],D=>['D'], L=>['D']};
  $in_moves->[2][0] = {U=>['U'],D=>['D']};
  $in_moves->[3][0] = {L=>['U'],D=>['R', 'D'],U=>['U']};
  $in_moves->[2][1] = {L=>['D'],D=>['D'],U=>['U','R']};
  $in_moves->[3][1] = {L=>['U'],U=>['U'],R=>['U'],D=>['L','R','D']};
  $in_moves->[2][4] = {R=>['D'],D=>['D'],U=>['L','U']};
  $in_moves->[3][4] = {D=>['D'],U=>['U']};
  $in_moves->[4][4] = {D=>['L'],R=>['U']};
  $fixed_value->[1][3] = 1;
  $fixed_value->[2][0] = 1;
  $fixed_value->[3][4] = 1;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 7 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "distance 7 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1R R2D 
U2R R3R R1D L1D D3L 
U1U L3D D2L D2R R3D 
U3U D1 L2D U1L D1D 
L2U L1L D3L L3U D2L 
",
"board 7 dfs");





#TAKESTOOLONG#
#TAKESTOOLONG#
#TAKESTOOLONG#  $in_moves = [];
#TAKESTOOLONG#  $fixed_value = [];
#TAKESTOOLONG#  $in_moves->[1][4] = {L=>['U'],D=>['R']};
#TAKESTOOLONG#  $in_moves->[0][4] = {L=>['D'],R=>['D'], U=>['L','R']};
#TAKESTOOLONG#  $in_moves->[1][5] = {D=>['R'],U=>['R'], R=>['U','D']};
#TAKESTOOLONG#  $in_moves->[4][1] = {U=>['U'],D=>['D']};
#TAKESTOOLONG#  $in_moves->[3][1] = {U=>['U','L','R'],D=>['D'],L=>['D'],R=>['D']};
#TAKESTOOLONG#  $in_moves->[5][1] = {D=>['L','R'],L=>['U'],R=>['U']};
#TAKESTOOLONG#  $in_moves->[3][4] = {U=>['L'],R=>['D']};
#TAKESTOOLONG#  $in_moves->[3][3] = {U=>['R'],D=>['R'],R=>['R'],L=>['U','D','L']};
#TAKESTOOLONG#  $in_moves->[4][4] = {U=>['U'],D=>['R','L','D'],R=>['U'],L=>['U']};
#TAKESTOOLONG#  $fixed_value->[3][4] = 3;
#TAKESTOOLONG#  $fixed_value->[4][1] = 3;
#TAKESTOOLONG#  $puzzle->set_rules({
#TAKESTOOLONG#    max_row => 5,
#TAKESTOOLONG#    max_column => 5,
#TAKESTOOLONG#    in_moves => $in_moves,
#TAKESTOOLONG#    fixed_value => $fixed_value,
#TAKESTOOLONG#  });
#TAKESTOOLONG#
#TAKESTOOLONG#  $puzzle_search->search({search_this=>$puzzle,
#TAKESTOOLONG#   max_steps=>300000,
#TAKESTOOLONG#   solutions_to_find=>1,
#TAKESTOOLONG#   no_value_function => 1,
#TAKESTOOLONG#   search_type => 'dfs'
#TAKESTOOLONG#  });
#TAKESTOOLONG##  print STDERR "search done found :\n";
#TAKESTOOLONG#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#TAKESTOOLONG#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#TAKESTOOLONG#  use Data::Dumper;
#TAKESTOOLONG##  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#TAKESTOOLONG#  print STDERR "board 8 is\n".$puzzle_search->last_object->board_out."\n\n";
#TAKESTOOLONG#  print STDERR "distance 8 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#TAKESTOOLONG##  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
#TAKESTOOLONG#  is ($puzzle_search->last_object->board_out,
#TAKESTOOLONG#"1R R2R R3D U2R R3D U3 
#TAKESTOOLONG#L3D L2L D1L U1U D1R R2U 
#TAKESTOOLONG#D1D U2R R3D L3U L2L U1L 
#TAKESTOOLONG#D2D U1U D1R R2R R3D U3U 
#TAKESTOOLONG#D3D U3U L3D L2L D1L U2U 
#TAKESTOOLONG#D1R R2U D1R R2R R3R R1U 
#TAKESTOOLONG#",
#TAKESTOOLONG#"board 8 dfs");
#TAKESTOOLONG#
#TAKESTOOLONG#







  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][1] = {L=>['D'],U=>['R']};
  $in_moves->[1][2] = {L=>['L'],U=>['L'], D=>['L'], R=>['U','D','R']};
  $in_moves->[2][1] = {D=>['R','L','D'],U=>['U'], R=>['U'],L=>['U']};
  $in_moves->[1][4] = {R=>['U'],D=>['L']};
  $in_moves->[1][3] = {R=>['R'],D=>['R'],U=>['R'],L=>['U','D','L']};
  $in_moves->[0][4] = {R=>['D'],L=>['D'],U=>['R','L']};
  $in_moves->[4][3] = {R=>['R'],L=>['L']};
  $in_moves->[4][2] = {R=>['R'],U=>['R'],D=>['R'],L=>['L','U','D']};
  $in_moves->[4][4] = {L=>['L'],U=>['L'],D=>['L'],R=>['R','U','D']};
  $fixed_value->[1][1] = 1;
  $fixed_value->[1][4] = 3;
  $fixed_value->[4][3] = 1;
  $puzzle->set_rules({
    max_row => 5,
    max_column => 5,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>300000,
   solutions_to_find=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 9 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "distance 9 is\n".$puzzle_search->last_object->distance_to_final_state."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
  is ($puzzle_search->last_object->board_out,
"1R R2R R3R R1D U1R R2D 
U3 L1D U3L D2R R3U D3D 
U2U D2D U2U L2D U1L D1D 
L1U D3L L1U D3L U3U D2D 
U1R R2R R3R R1R R2U D3D 
L3U L2L L1L L3L L2L D1L 
", "board 9 dfs");




#print STDERR "look for multiple\n";


  $in_moves = [];
  $fixed_value = [];
  $in_moves->[0][1] = {'R'=>['R','D'], 'L'=>['L'], 'U'=>['L']};
  $in_moves->[1][1] = {'R'=>['R'], 'L'=>['L','D','U'], 'U'=>['R'], 'D'=>['R']};
  $in_moves->[1][2] = {'R'=>['D'], 'U'=>['L']};
  $in_moves->[2][2] = {'R'=>['U'], 'U'=>['U'], 'L'=>['U'], 'D'=>['L','R','D']};
  $fixed_value->[1][2] = 3;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>1000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "Path: ".Dumper($puzzle_search->path)."\n";
#  print STDERR "board 1 is\n".$puzzle_search->last_object->board_out."\n\n";
  is (scalar($puzzle_search->paths), 1, "board 1 solutions");

  $in_moves = [];
  $fixed_value = [];
  $in_moves->[2][1] = {U=>['U'],D=>['D']};
  $in_moves->[1][1] = {U=>['L','R','U'],D=>['D'],L=>['D'],R=>['D']};
  $in_moves->[3][1] = {D=>['L','R'],L=>['U'],R=>['U']};
  $fixed_value->[2][2] = 3;
  $fixed_value->[3][3] = 2;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>3000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 2 is\n".$puzzle_search->last_object->board_out."\n\n";
#  print STDERR "board 2\n";
  is (scalar($puzzle_search->paths), 1, "board 2 solutions");


  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {D=>['R'],U=>['R'],L=>['U','D']};
  $in_moves->[1][1] = {L=>['L'],R=>['R']};
  $in_moves->[2][1] = {L=>['D','L'],R=>['R'],U=>['R']};
  $in_moves->[1][2] = {L=>['L'],R=>['U','D','R'],D=>['L'],U=>['L']};
  $in_moves->[2][2] = {L=>['L'],R=>['R','U','D'],U=>['L'],D=>['L']};
  $fixed_value->[1][1] = 2;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>3000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 3\n";
  is (scalar($puzzle_search->paths), 1, "board 3 solutions");



  $in_moves = [];
  $fixed_value = [];
  $in_moves->[0][1] = {L=>['L','D'],R=>['R'],U=>['R']};
  $in_moves->[1][0] = {L=>['D'],D=>['D'],U=>['R']};
  $in_moves->[2][0] = {U=>['U'],D=>['D']};
  $in_moves->[3][0] = {D=>['R'],L=>['U']};
  $in_moves->[3][2] = {D=>['R'],L=>['U']};
  $in_moves->[3][3] = {D=>['L'],R=>['U']};
  $in_moves->[2][2] = {D=>['D'],R=>['D'],L=>['D'],U=>['R','L','U']};
  $fixed_value->[2][0] = 3;
  $fixed_value->[3][2] = 1;
  $puzzle->set_rules({
    max_row => 3,
    max_column => 3,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 4\n";
  is (scalar($puzzle_search->paths), 1, "board 4 solutions");




#puzzle 5
  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][3] = {L=>['L','D','U'],R=>['R'],U=>['R'],D=>['R']};
  $in_moves->[1][4] = {R=>['U','D'],U=>['L'],D=>['L']};
  $in_moves->[3][2] = {R=>['D'],L=>['D'],D=>['D'],U=>['L','R','U']};
  $in_moves->[4][2] = {R=>[],L=>[],D=>[],U=>[]};
  $fixed_value->[0][3] = 2;
  $fixed_value->[2][0] = 3;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>200000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "puzzle 5 steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 5\n";
  is (scalar($puzzle_search->paths), 1, "board 5 solutions");




  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {U=>['R'],D=>['R'], L=>['D','U']};
  $in_moves->[1][1] = {R=>['R'],L=>['L']};
  $in_moves->[1][2] = {R=>['U','D','R'],L=>['L'],D=>['L'],U=>['L']};
  $in_moves->[2][1] = {R=>['D'],L=>['D'],U=>['L','R']};
  $in_moves->[3][1] = {R=>['U'],L=>['U'],U=>['U'],D=>['R','L','D']};
  $in_moves->[4][3] = {R=>['R'],D=>['R']};
  $in_moves->[4][4] = {};
  $fixed_value->[1][1] = 1;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 6\n";
  is (scalar($puzzle_search->paths), 1, "board 6 solutions");





  $in_moves = [];
  $fixed_value = [];
  $in_moves->[1][0] = {U=>['R'],D=>['D'], L=>['D']};
  $in_moves->[2][0] = {U=>['U'],D=>['D']};
  $in_moves->[3][0] = {L=>['U'],D=>['R', 'D'],U=>['U']};
  $in_moves->[2][1] = {L=>['D'],D=>['D'],U=>['U','R']};
  $in_moves->[3][1] = {L=>['U'],U=>['U'],R=>['U'],D=>['L','R','D']};
  $in_moves->[2][4] = {R=>['D'],D=>['D'],U=>['L','U']};
  $in_moves->[3][4] = {D=>['D'],U=>['U']};
  $in_moves->[4][4] = {D=>['L'],R=>['U']};
  $fixed_value->[1][3] = 1;
  $fixed_value->[2][0] = 1;
  $fixed_value->[3][4] = 1;
  $puzzle->set_rules({
    max_row => 4,
    max_column => 4,
    in_moves => $in_moves,
    fixed_value => $fixed_value,
  });

  $puzzle_search->search({search_this=>$puzzle,
   max_steps=>10000,
   solutions_to_find=>2,
   preserve_solutions=>1,
   no_value_function => 1,
   search_type => 'dfs'
  });
#  print STDERR "search done found :\n";
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#  use Data::Dumper;
#  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#  print STDERR "board 7\n";
  is (scalar($puzzle_search->paths), 1, "board 7 solutions");





#TAKESTOOLONG#
#TAKESTOOLONG#
#TAKESTOOLONG#  $in_moves = [];
#TAKESTOOLONG#  $fixed_value = [];
#TAKESTOOLONG#  $in_moves->[1][4] = {L=>['U'],D=>['R']};
#TAKESTOOLONG#  $in_moves->[0][4] = {L=>['D'],R=>['D'], U=>['L','R']};
#TAKESTOOLONG#  $in_moves->[1][5] = {D=>['R'],U=>['R'], R=>['U','D']};
#TAKESTOOLONG#  $in_moves->[4][1] = {U=>['U'],D=>['D']};
#TAKESTOOLONG#  $in_moves->[3][1] = {U=>['U','L','R'],D=>['D'],L=>['D'],R=>['D']};
#TAKESTOOLONG#  $in_moves->[5][1] = {D=>['L','R'],L=>['U'],R=>['U']};
#TAKESTOOLONG#  $in_moves->[3][4] = {U=>['L'],R=>['D']};
#TAKESTOOLONG#  $in_moves->[3][3] = {U=>['R'],D=>['R'],R=>['R'],L=>['U','D','L']};
#TAKESTOOLONG#  $in_moves->[4][4] = {U=>['U'],D=>['R','L','D'],R=>['U'],L=>['U']};
#TAKESTOOLONG#  $fixed_value->[3][4] = 3;
#TAKESTOOLONG#  $fixed_value->[4][1] = 3;
#TAKESTOOLONG#  $puzzle->set_rules({
#TAKESTOOLONG#    max_row => 5,
#TAKESTOOLONG#    max_column => 5,
#TAKESTOOLONG#    in_moves => $in_moves,
#TAKESTOOLONG#    fixed_value => $fixed_value,
#TAKESTOOLONG#  });
#TAKESTOOLONG#
#TAKESTOOLONG#  $puzzle_search->search({search_this=>$puzzle,
#TAKESTOOLONG#   max_steps=>300000,
#TAKESTOOLONG#   solutions_to_find=>2,
#TAKESTOOLONG#   preserve_solutions=>1,
#TAKESTOOLONG#   no_value_function => 1,
#TAKESTOOLONG#   search_type => 'dfs'
#TAKESTOOLONG#  });
#TAKESTOOLONG##  print STDERR "search done found :\n";
#TAKESTOOLONG#  print STDERR "steps taken ".$puzzle_search->steps."\n";
#TAKESTOOLONG#  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
#TAKESTOOLONG#  use Data::Dumper;
#TAKESTOOLONG##  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
#TAKESTOOLONG#  print STDERR "board 8\n";
#TAKESTOOLONG#  is (scalar($puzzle_search->paths), 1, "board 8 solutions");
#TAKESTOOLONG#
#TAKESTOOLONG#




##
##
##
##
##  $in_moves = [];
##  $fixed_value = [];
##  $in_moves->[1][1] = {L=>['D'],U=>['R']};
##  $in_moves->[1][2] = {L=>['L'],U=>['L'], D=>['L'], R=>['U','D','R']};
##  $in_moves->[2][1] = {D=>['R','L','D'],U=>['U'], R=>['U'],L=>['U']};
##  $in_moves->[1][4] = {R=>['U'],D=>['L']};
##  $in_moves->[1][3] = {R=>['R'],D=>['R'],U=>['R'],L=>['U','D','L']};
##  $in_moves->[0][4] = {R=>['D'],L=>['D'],U=>['R','L']};
##  $in_moves->[4][3] = {R=>['R'],L=>['L']};
##  $in_moves->[4][2] = {R=>['R'],U=>['R'],D=>['R'],L=>['L','U','D']};
##  $in_moves->[4][4] = {L=>['L'],U=>['L'],D=>['L'],R=>['R','U','D']};
##  $fixed_value->[1][1] = 1;
##  $fixed_value->[1][4] = 3;
##  $fixed_value->[4][3] = 1;
##  $puzzle->set_rules({
##    max_row => 5,
##    max_column => 5,
##    in_moves => $in_moves,
##    fixed_value => $fixed_value,
##  });
##
##  $puzzle_search->search({search_this=>$puzzle,
##   max_steps=>300000,
##   solutions_to_find=>2,
##   preserve_solutions=>1,
##   no_value_function => 1,
##   search_type => 'dfs'
##  });
###  print STDERR "search done found :\n";
###  print STDERR "steps taken ".$puzzle_search->steps."\n";
###  print STDERR "lo moves ".$puzzle_search->last_object->{moves}."\n";
##  use Data::Dumper;
###  print STDERR "lo is ".Dumper($puzzle_search->last_object)."\n";
###  print STDERR "board 9\n";
##  is (scalar($puzzle_search->paths), 1, "board 9 solutions");
##



