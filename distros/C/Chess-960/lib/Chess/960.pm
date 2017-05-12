use 5.12.0;
use warnings;
package Chess::960;
# ABSTRACT: a Chess960 starting position generator
$Chess::960::VERSION = '0.002';
use Carp ();

# =head1 OVERVIEW
#
# L<Chess960|https://en.wikipedia.org/wiki/Chess960> is a chess variant invented
# by Bobby Fischer, designed to somewhat reduce the value of memorization to
# play, while retaining key properties of the game such as castling and one
# bishop per color.
#
# Chess::960 generates random starting positions for a Chess960 game.
#
#   use Chess::960;
#
#   my $fen = Chess::960->new->fen; # Forsyth-Edwards notation of position
#
#   my $pos = Chess::960->new->generate_position; # simple data structure
#
#   my $pos = Chess::960->new->generate_position(123); # get position by number
#
# =cut

my @BRIGHT = qw(1 3 5 7);
my @DARK   = qw(0 2 4 6);

my @KNIGHTS = (
  [ 0, 1 ],
  [ 0, 2 ],
  [ 0, 3 ],
  [ 0, 4 ],
  [ 1, 2 ],
  [ 1, 3 ],
  [ 1, 4 ],
  [ 2, 3 ],
  [ 2, 4 ],
  [ 3, 4 ],
);

# =method new
#
# The constructor for Chess::960 does not, at present, take any argument.  In the
# future, it may take arguments to pick different mappings between positions
# and numbers.
#
# =cut

sub new {
  my ($class) = @_;
  bless {} => $class;
}

# =method generate_position
#
#   my $pos = $c960->generate_position($num);
#
# This returns a starting description, described by a hash.  If C<$num> is not
# provided, a random position will be returned.  If a value for C<$num> that
# isn't an integer between 0 and 959 is provided, an exception will be raised.
#
# Position 518 in the default mapping is the traditional chess starting position.
#
# The returned hashref has two entries:
#
#   number - the number of the generated position
#   rank   - an eight-element arrayref giving the pieces' positions
#            elements are characters in [BQNRK]
#
# =cut

sub generate_position {
  my ($self, $num) = @_;
  $num //= int rand 960;

  Carp::confess("starting position number must be between 0 and 959")
    unless defined $num && $num =~ /\A[0-9]{1,3}\z/ && $num >= 0 && $num <= 959;

  my $b1 = $num % 4;
  my $b2 = int( $num / 4 ) % 4;

  my $k  = int( $num / 96 );
  my $q  = ($num / 16) % 6;

  my @rank = (undef) x 8;
  $rank[ $BRIGHT[ $b1 ] ] = 'B';
  $rank[ $DARK[   $b2 ] ] = 'B';

  my @empty;

  @empty = grep { ! $rank[$_] } keys @rank;
  $rank[ $empty[ $q ] ] = 'Q';

  @empty = grep { ! $rank[$_] } keys @rank;
  @rank[ @empty[ @{ $KNIGHTS[$k] } ] ] = qw(N N);

  @empty = grep { ! $rank[$_] } keys @rank;
  @rank[ @empty ] = qw(R K R);

  return { number => $num, rank => \@rank };
}

# =method fen
#
# This method returns a
# L<FEN|https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation>-format
# string describing the complete starting position of the board.  For example:
#
#   rnbbqkrn/pppppppp/8/8/8/8/PPPPPPPP/RNBBQKRN w KQkq - 0 1
#
# =cut

sub fen {
  my ($self, $num) = @_;

  my $pos  = $self->generate_position($num);
  my $rank = join q{}, @{ $pos->{rank} };
  my $fen = sprintf "%s/%s/8/8/8/8/%s/%s w KQkq - 0 1",
    lc $rank,
    'p' x 8,
    'P' x 8,
    $rank;

  return $fen;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chess::960 - a Chess960 starting position generator

=head1 VERSION

version 0.002

=head1 OVERVIEW

L<Chess960|https://en.wikipedia.org/wiki/Chess960> is a chess variant invented
by Bobby Fischer, designed to somewhat reduce the value of memorization to
play, while retaining key properties of the game such as castling and one
bishop per color.

Chess::960 generates random starting positions for a Chess960 game.

  use Chess::960;

  my $fen = Chess::960->new->fen; # Forsyth-Edwards notation of position

  my $pos = Chess::960->new->generate_position; # simple data structure

  my $pos = Chess::960->new->generate_position(123); # get position by number

=head1 METHODS

=head2 new

The constructor for Chess::960 does not, at present, take any argument.  In the
future, it may take arguments to pick different mappings between positions
and numbers.

=head2 generate_position

  my $pos = $c960->generate_position($num);

This returns a starting description, described by a hash.  If C<$num> is not
provided, a random position will be returned.  If a value for C<$num> that
isn't an integer between 0 and 959 is provided, an exception will be raised.

Position 518 in the default mapping is the traditional chess starting position.

The returned hashref has two entries:

  number - the number of the generated position
  rank   - an eight-element arrayref giving the pieces' positions
           elements are characters in [BQNRK]

=head2 fen

This method returns a
L<FEN|https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation>-format
string describing the complete starting position of the board.  For example:

  rnbbqkrn/pppppppp/8/8/8/8/PPPPPPPP/RNBBQKRN w KQkq - 0 1

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
