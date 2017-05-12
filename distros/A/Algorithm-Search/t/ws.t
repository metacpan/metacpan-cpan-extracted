#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
#word search
use Test::More tests => 1;

  package words;

  our %word_list;
  our $tree = {};

my $count = 0;
#  my $dictionary = "/Users/arthurgoldstein/downloads/TWL06.txt";
  my $dictionary = "t/wsdict";
  my $fh;
  open $fh, "<", $dictionary;
  while (my $word = <$fh>) {
    $word = uc $word;
    $word =~ s/[^A-Z]//g;
    $word_list{$word}=1;
    my @letters = split //,$word;
    my $add_to_tree = $tree;
    foreach my $letter (@letters) {
#print STDERR "Letter $letter\n";
      $add_to_tree->{$letter} = $add_to_tree->{$letter} || {};
      $add_to_tree = $add_to_tree->{$letter};
    }
#print STDERR "end of word $word\n";
  }
  close $fh;
#use Data::Dumper;
#print STDERR Dumper($tree)."\n";
#print STDERR "is AD a word?  ";
#print STDERR $word_list{'AD'};
#print STDERR "\n";

#exit;
#  print STDERR "Word count ".scalar(keys %word_list);
  sub new {return bless {}}

  sub set_position {
    my $self = shift;
    my ($row, $column, $board) = @_;
#print STDERR "board is $board\n";
    $self->{row} = $row;
    $self->{column} = $column;
    $self->{tree} = $tree;
    my @rows = split (" ", $board);
    my $row_count = 0;
    foreach my $row_in (@rows) {
      my $column_count = 0;
      foreach my $letter (split (//,$row_in)) {
        $self->{board}->[$row_count]->[$column_count++] = $letter;
      }
      $self->{max_column} = $column_count-1;
      $row_count++;
    }
    $self->{max_row} = $row_count-1;
#print STDERR "max row set to ".$self->{max_row}."\n";
#print STDERR "row is $row and col is $column\n";
    my $letter = $self->{board}->[$self->{row}]->[$self->{column}];
    $self->{chosen}->[$self->{row}]->[$self->{column}]++;
    $self->{tree} = $self->{tree}->{$letter};
    $self->{word} = $letter;
  }

  sub value {
    my $self = shift;
    return $self->{row}.' '.$self->{column};
  }

  sub move {
    my $self = shift;
    my $direction = shift;
    if ($direction eq 'U' || $direction eq 'UL' || $direction eq 'UR') {
      if ($self->{row} == 0) {
#print STDERR "cannot move up\n";
         return}
      $self->{row}--;
    }
    if ($direction eq 'D' || $direction eq 'DL' || $direction eq 'DR') {
      if ($self->{row} == $self->{max_row}) {
#print STDERR "cannot move down\n";
         return}
      $self->{row}++;
    }
    if ($direction eq 'L' || $direction eq 'UL' || $direction eq 'DL') {
      if ($self->{column} == 0) {
#print STDERR "cannot move left\n";
         return}
      $self->{column}--;
    }
    if ($direction eq 'R' || $direction eq 'UR' || $direction eq 'DR') {
      if ($self->{column} == $self->{max_column}) {
#print STDERR "cannot move right\n";
         return}
      $self->{column}++;
    }

    if ($self->{chosen}->[$self->{row}]->[$self->{column}]++) {
#print STDERR "already chosen\n";
      return;
    }

    my $letter = $self->{board}->[$self->{row}]->[$self->{column}];
#print STDERR "looking at letter $letter\n";
#print STDERR "row is ".$self->{row}."\n";
##print STDERR "col is ".$self->{column}."\n";

#print STDERR "Current word is ".$self->{word}."\n";
    if (!defined $self->{tree}->{$letter}) {
#print STDERR "no letter tree\n";
      return;
    }

    $self->{tree} = $self->{tree}->{$letter};
    $self->{word} .= $letter;

    return 0;
  }

  sub is_solution {
    my $self = shift;

    if ($word_list{$self->{word}}) {
      return 1;
    }
    return 0;
  }

  sub distance_to_final_state {
    my $self = shift;

    if ($word_list{$self->{word}}) {
#print STDERR "Found word ".$self->{word}."\n";
      return 0;
    }
    return 1;
  }

  sub copy {
    my $self = shift;
    my $copy = $self->new;
    $copy->{tree} = $self->{tree};
    $copy->{word} = $self->{word};
    $copy->{column} = $self->{column};
    $copy->{row} = $self->{row};
    $copy->{max_row} = $self->{max_row};
    $copy->{max_column} = $self->{max_column};
    $copy->{board} = $self->{board};
    for my $i (0..$self->{max_row}) {
      for my $j (0..$self->{max_column}) {
        $copy->{chosen}->[$i]->[$j] = $self->{chosen}->[$i]->[$j];
      }
    }

    return $copy;
  }

  sub next_moves {
    my $self = shift;
    return ('UL','U','R','D','L','UR','DR','DL');
  }


  package main;
  my @solutions;
  my $sol_count;
  use Algorithm::Search;

  my $board =
"TEA
SEA
ART";
  my @rows = split /\n/,$board;
  my $columns = length($rows[0])-1;

  my %words_found;
  my $puzzle_search = new Algorithm::Search();
  for my $i (0..$#rows) {
    for my $j (0..$columns) {
      my $puzzle = new words;
      $puzzle->set_position($i,$j,$board);
      $puzzle_search->search({search_this=>$puzzle,
       max_steps=>3000,
       solutions_to_find=>0,
       distance_can_increase=>1,
       no_value_function => 1,
       search_type => 'bfs'
      });

      foreach my $sol ($puzzle_search->solutions) {
        $words_found{$sol->{word}} = 1;
      }
#  print STDERR "steps taken ".$puzzle_search->steps."\n";
    }
  }

#  print STDERR "Words found ".join("\n",sort keys %words_found)."\n\n";
is(join("\n",sort keys %words_found)."\n",
"ARE
AREA
ART
ASEA
AT
ATE
EAR
EARS
EASE
EAST
EAT
EATER
EATERS
ERA
ERAS
ERASE
ERST
ESTER
RATE
RATES
RESEAT
RESET
REST
SEA
SEAR
SEAT
SEE
SEER
SERA
SET
STEER
STET
TAR
TARS
TEA
TEAR
TEARS
TEAS
TEASE
TEE
TEES
TERSE
TEST
TREE
TREES
TSAR
", "Words found");

