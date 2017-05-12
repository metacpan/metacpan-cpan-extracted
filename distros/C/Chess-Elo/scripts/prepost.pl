use strict;
use Chess::Elo qw(:all);

my $rating = 1450;
my @wld    = qw(1 0.5 0);

my @opponent = qw(1000 1600 1800 1200 1425 1700);

print "initial: ", $rating;

for my $opponent (@opponent) {
  my $result = $wld[rand(@wld)] ;

  print "\n\n";
  printf "result versus %d-rated: %.1f ", $opponent, $result;
  my ($new, undef) = elo($rating, $result, $opponent);
  
  printf "delta rating: %.2f -> %.2f\n", $rating, $new;
  $rating = $new;
}


