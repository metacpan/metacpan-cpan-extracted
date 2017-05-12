use Test;
BEGIN { plan tests => 1 };
use Commands::Guarded qw(:step verbose);

verbose(0);

my @nums = (1..10);

my $step = step doForeachTest =>
  ensure { $nums[$_[0]] % 2 }
  using { $nums[$_[0]]++ }
  ;

$step->do_foreach(0..$#nums);

foreach (@nums) {
   ok(0) unless $_ % 2;
}

ok(1)
