package NPieces;

use strict;
use warnings;

use Algorithm::X::DLX;
use Algorithm::X::ExactCoverProblem;
use Carp;

use constant { None => 0, Knight => 1, Queen => 2 };

sub new {
  my ($class, %args) = @_;

  my $self = bless {
    width_    => $args{width}   || 0,
    height_   => $args{height}  || 0,
    knights_  => $args{knights} || 0,
    queens_   => $args{queens}  || 0,
    problem_  => undef,
    row_data_ => [],
    iterator_ => undef
  }, $class;

  return $self->_initialize();
}

sub _initialize {
  my ($self) = @_;

  # Columns
  #   P*A: (x,y) attacked by piece i?
  #   P*A: placing piece i at (x,y) ok?
  #   P: piece i used?
  #
  # Total: (2A+1)P
  # Secondary: 2AP
  my $A = $self->{width_}   * $self->{height_};
  my $P = $self->{knights_} + $self->{queens_};

  $self->{problem_}  = Algorithm::X::ExactCoverProblem->new((2 * $A + 1) * $P, undef, 2 * $A * $P);

  for (my $yx = 0; $yx < $A; $yx++) {

    my $x = $yx % $self->{width_};
    my $y = int($yx / $self->{width_});

    for (my $p = 0; $p < $P; $p++) {
      my $piece = ($p < $self->{knights_}) ? Knight : Queen;
      push @{$self->{row_data_}}, { piece => $piece, x => $x, y => $y };

      my @columns;
      push @columns, map { col_attack($A, $p, $_) } @{$self->attacks($piece, $x, $y)};
      push @columns, col_piece($P, $A, $p);
      push @columns, col_put($P, $A, $p, $yx);

      for (my $p2 = 0; $p2 < $P; $p2++) {
        push @columns, col_attack($A, $p2, $yx) if ($p2 != $p);
      }

      if ($p > 0 && ($p - 1 < $self->{knights_}) == ($piece == Knight)) {
        push @columns, map { col_put($P, $A, $p - 1, $_) } ($yx + 1 .. $A - 1);
      }

      @columns = sort { $a <=> $b } @columns;
      $self->{problem_}->add_row(\@columns);
    }
  }

  $self->{iterator_} = Algorithm::X::DLX->new($self->{problem_})->get_solver();

  return $self;
}

sub size {
  my ($self, $width, $height) = @_;

  $width  = 0 unless defined $width;
  $height = $width unless defined $height;

  return NPieces->new(
    width   => $width, 
    height  => $height, 
    knights => $self->{knights_}, 
    queens  => $self->{queens_}
  );
}

sub knights {
  my ($self, $n) = @_;

  return NPieces->new(
    width   => $self->{width_},
    height  => $self->{height_},
    knights => ($n || 0),
    queens  => $self->{queens_}
  );
}

sub queens {
  my ($self, $n) = @_;

  return NPieces->new(
    width   => $self->{width_},
    height  => $self->{height_},
    knights => $self->{knights_},
    queens  => ($n || 0)
  );
}

sub count_solutions {
  my ($self) = @_;

  return Algorithm::X::DLX->new($self->{problem_})->count_solutions();
}

sub next_solution {
  my ($self) = @_;

  my $used_rows = $self->{iterator_}()
    or return undef;

  my @solution = map { [(None) x $self->{width_}] } (1 .. $self->{height_});
  foreach my $i (@$used_rows) {
    my %data = %{$self->{row_data_}->[$i]};
    $solution[$data{y}][$data{x}] = $data{piece};
  }

  return \@solution;
}

sub attacks {
  my ($self, $piece, $x0, $y0) = @_;

  my %points = (($y0 * $self->{width_} + $x0) => undef);

  for (my $y = 0; $y < $self->{height_}; $y++) {
    for (my $x = 0; $x < $self->{width_}; $x++) {
      if ($self->is_attack($piece, int($x0), int($y0), int($x), int($y))) {
        # Using hash keys to ensure uniqueness 
        $points{($y * int($self->{width_}) + int($x))} = undef;
      }
    }
  }
  return [keys %points];
}

sub is_attack {
  my ($self, $piece_type, $x1, $y1, $x2, $y2) = @_;

  if ($piece_type == Knight) {
    return (($x1 - $x2)**2 + ($y1 - $y2)**2 == 5);

  } elsif ($piece_type == Queen) {
    return ($x1 == $x2 || $y1 == $y2 || $y1 - $x1 == $y2 - $x2 || $y1 + $x1 == $y2 + $x2);

  } else {
    croak "NPieces::is_attack(): Unknown piece";
  }
}

# Helper functions to calculate column indices
sub col_attack { $_[0] * $_[1] + $_[2] }
sub col_put    { ($_[0] + $_[2]) * $_[1] + $_[3] }
sub col_piece  { 2 * $_[0] * $_[1] + $_[2] }

# Usage example: 
# my NPieces_obj = NPieces->new(width=>8,height=>8)->knights(10)->queens(10);
# my solutions_count = NPieces_obj->count_solutions();
# my all_solutions_ref = NPieces_obj->find_solutions();
#   OR while (my next_solution_ref = NPieces_obj->next_solution()) {

1;

