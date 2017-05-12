use strict;
use warnings;
use Test::More;
use Chess::960;

my %pos;
for (0 .. 959) {
  my $pos  = Chess::960->generate_position($_);
  my $rank = join q{}, @{ $pos->{rank} };


  if ($pos{$rank}) {
    fail("position $_ ($rank) duplicates $pos{$rank}");
  } else {
    pass("position $_ ($rank) is not a duplicate");
  }
}

done_testing;
