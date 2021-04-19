package Test::Art::World;
use List::Util qw/any/;
use Moo;

sub is_artist_creator {
  my ( $self, $artist, $art ) = @_;
  my $bool = any { $_ eq $artist->name } map { $_->name } @{ $art->creator };
  return $bool;
}

1;
