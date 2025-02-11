#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;

use SudokuGenerator;
use SudokuSolver;
use SudokuType;

sub HELP_MESSAGE {
  my $script = $0;
  $script =~ s|^.*/||;
  print<<HELP

Usage: $script -[options|f:format] <input>

Option flags are:
 -h print help
 -l input has 1 puzzle per line
 -v print solution underneath the puzzle, not side by side
 -s print solutions only, not the puzzle

Output format options (-f) are:
  'preserve' (default):  stick to the input format
  'oneline':             all cell values concatenated
  'compact':             cells only, omitting regions
  'default':             vanilla 9x9

HELP
;
  exit(1);
}

my %format_names = (
  'default'  => 'DEFAULT',
  'oneline'  => 'ONELINE',
  'compact'  => 'COMPACT',
  'preserve' => 'PRESERVE'
);

my $opt_format = 'PRESERVE';
my $opt_one_sudoku_per_line = 0;
my $opt_side_by_side = 1;
my $opt_print_solved_only = 0;

my %opts;
getopts('f:hlsv', \%opts)
  or HELP_MESSAGE();

if ($opts{'h'}) {
  HELP_MESSAGE();
}

if ($opts{'l'}) {
  $opt_one_sudoku_per_line = 1;
}

if ($opts{'s'}) {
  $opt_print_solved_only = 1;
}

if ($opts{'v'}) {
  $opt_side_by_side = 0;
}

if ($opts{'f'}) {
  if (exists $format_names{$opts{'f'}}) {
    $opt_format = $format_names{$opts{'f'}};
  } else {
    print "Invalid argument for -f '$opts{'f'}'";
    HELP_MESSAGE();
  }
}

my $generator = SudokuGenerator->new();
my $input = '';
my $first = 1;

while (my $line = <STDIN>) {
  chomp $line;

  if ($line ne '') {
    $input .= $line;
    if (!$opt_one_sudoku_per_line) {
      $input .= "\n";
      next unless eof(STDIN);
    }
  }

  $input or next;

  eval {
    my $type = SudokuType::guess($input);

    my $format;
    if ($opt_format eq 'PRESERVE') {
      $format = SudokuFormat->new($type, $input);
    } elsif ($opt_format eq 'COMPACT') {
      $format = SudokuFormat->compact($type);
    } elsif ($opt_format eq 'ONELINE') {
      $format = SudokuFormat->oneline($type);
    } else {
      $format = SudokuFormat->new($type);
    }

    if (!$first && $opt_format ne 'ONELINE') {
      print "\n";
    }
    $first = 0;

    my $sudoku = Sudoku->new($type, $input);
    if ($sudoku->is_empty()) {
      $sudoku = $generator->generate($type);
    }

    my $solved = SudokuSolver::solve($sudoku);
    if (!$opt_print_solved_only && $opt_side_by_side) {
      print_side_by_side($sudoku->to_string_format($format), $solved->to_string_format($format));

    } else {
      if (!$opt_print_solved_only) {
        print $sudoku->to_string_format($format);
        if ($opt_format ne 'ONELINE') {
          print "\n";
        }
      }
      print $solved->to_string_format($format);
    }
  };

  if ($@) {
    print STDERR "\nERROR! $@\n";
    print STDERR $input, "\n";
  }

  $input = '';
}

sub print_side_by_side {
  my ($left, $right) = @_;

  my @ls = split("\n", $left);
  my @rs = split("\n", $right);
  my $max_left = 0;
  foreach my $l (@ls) {
    $max_left = length($l) if length($l) > $max_left;
  }

  my $max_lines = scalar(@ls) > scalar(@rs) ? scalar(@ls) : scalar(@rs);
  for (my $y = 0; $y < $max_lines; $y++) {
    my $pos = 0;
    if ($y < scalar(@ls)) {
      print $ls[$y];
      $pos = length($ls[$y]);
    }
    if ($y < scalar(@rs)) {
      print ' ' x (4 + $max_left - $pos);
      print $rs[$y];
    }
    print "\n";
  }
}

