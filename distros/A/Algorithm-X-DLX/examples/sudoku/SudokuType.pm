package SudokuType;

use strict;
use warnings;

use Carp;
use List::Util qw(first);
use POSIX qw(floor);

use SudokuFormat;

sub new {
  my ($class, @args) = @_;
  
  my $type;
  if (@args == 0) {
    # The standard 9x9 Sudoku.
    return new($class, 9);
  } elsif (@args == 1 && ref($args[0]) eq 'ARRAY') {
    # Sudoku with arbitrarily-shaped regions.
    $type = {n_ => isqrt(scalar @{$args[0]}), region_ => normalize_regions($args[0])};
  } elsif (@args == 1) {
    my $n = $args[0];
    # NxN version of the 9x9.
    return new($class, isqrt($n), isqrt($n));
  } elsif (@args == 2) {
    # Sudoku with rectangle-shaped regions.
    return new($class, box_regions($args[0], $args[1]));
  } else {
    croak "Invalid arguments";
  }
  bless $type, $class;
  if ($type->n() < 1) {
    croak "Sudoku must have non-zero size";
  }
  return $type;
}

sub from_size {
    my ($size) = @_;
    return new(__PACKAGE__, isqrt($size));
}

sub guess {
  my ($str) = @_;

  my @lines;
  my $line = '';
  my $cells = 0;
  my $size = SudokuFormat::count_cells($str);
  my $n = isqrt($size);
  
  foreach my $c (split //, $str) {
    if ($c eq "\n") {
      if ($cells != 0 && $cells != $n) {
        return from_size($size);
      }
      push @lines, $line;
      $cells = 0;
      $line = '';
      next;
  }
    if (SudokuFormat::is_valid_cell($c)) {
      $cells++;
    }
    if ($cells > $n) {
      push @lines, $line;
      $line = '';
      $cells %= $n;
    }
    $line .= $c;
  }
  push @lines, $line;
  my @region;
  my $next_id = 1;

  my $find_region;
  $find_region = sub {
    my ($id, $x, $y) = @_;

    return 0 if $x < 0 || $y < 0 || $y >= scalar(@lines) || $x >= length($lines[$y]);

    $region[$y][$x] = 0 unless defined $region[$y][$x];
    return 0 if $region[$y][$x] != 0;

    my $c = substr($lines[$y], $x, 1);
    return 0 if !SudokuFormat::is_valid_cell($c) && $c ne ' ';

    $region[$y][$x] = $id;
    my $region_size = 1;
    $region_size += $find_region->($id, $x, $y - 1);
    $region_size += $find_region->($id, $x, $y + 1);
    $region_size += $find_region->($id, $x - 1, $y);
    $region_size += $find_region->($id, $x + 1, $y);
    return $region_size;
  };

  for my $y (0 .. $#lines) {
    for my $x (0 .. length($lines[$y]) - 1) {
      if (!SudokuFormat::is_valid_cell(substr($lines[$y], $x, 1))) {
        next;
      }
      my $region_size = $find_region->($next_id, $x, $y);
      $next_id++ if $region_size > 0;
    }
  }

  my %region_size;
  my @final_regions;
  my $total_size = 0;

  for my $y (0 .. $#lines) {
    for my $x (0 .. length($lines[$y]) - 1) {
      if (SudokuFormat::is_valid_cell(substr($lines[$y], $x, 1))) {
        $total_size++;
        $region_size{$region[$y][$x]}++;
        push @final_regions, $region[$y][$x];
      }
    }
  }
#print "\%region_size = ", Dumper(\%region_size);
#print "guess(): \$total_size = $total_size, \$size = $size\n";
  croak "Total size mismatch" if $total_size != $size;
#print "guess(): \$n = $n, \@final_regions = (@final_regions)\n";
#print Dumper(\%region_size);
  for my $p (values %region_size) {
    return from_size($size) if $p != $n;
#      croak "Region has wrong size" if $p != $n;
  }

  return new(__PACKAGE__, \@final_regions);
}

sub n {
  my ($self) = @_;
  return $self->{n_};
}

sub size {
  my ($self) = @_;
  return $self->{n_} * $self->{n_};
}

sub region {
  my ($self, $pos) = @_;
  croak "Position out of bounds" if $pos >= $self->size();
  return $self->{region_}->[$pos];
}

sub region_xy {
  my ($self, $x, $y) = @_;
  return $self->{region_}[$y * $self->{n_} + $x];
}

sub is_equal {
  my ($self, $other) = @_;
  return $self->{n_} == $other->{n_} && $self->{region_} eq $other->{region_};
}

sub box_regions {
  my ($w, $h) = @_;
  my @regions;
  my $n = $w * $h;

  # Creates an array of length size(), holding zero based region indexes (0-8) for the standard 3x3 box regions.
  for my $y (0 .. $n - 1) {
    for my $x (0 .. $n - 1) {
        push @regions, floor($y / $h) * $h + floor($x / $w);
    }
  }
  return \@regions;
}

# This function renumerates the given region values in ascending order, beginning with 0.
sub normalize_regions {
  my ($regions) = @_;
  my %ids;
  my %areas;
  my $n = isqrt(scalar @$regions);

  for my $id (@$regions) {
    if (!exists $ids{$id}) {
      $ids{$id} = scalar keys %ids;
    }
    croak "Region has wrong size" if ++$areas{$id} > $n;
  }

  croak "Too many regions" if scalar keys %ids != $n;

  for my $id (@$regions) {
    # In Perl, this overwrites the cell value in $regions array!
    $id = $ids{$id};
  }
  return $regions;
}

sub isqrt {
  my $n = shift;
  my $k = 0;
  $k++ while ($k + 1) * ($k + 1) <= $n;
  croak "Not a square" if $k * $k != $n;
  return $k;
}

1;

