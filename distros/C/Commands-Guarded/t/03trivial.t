use Test;
BEGIN { plan tests => 1 };
use Commands::Guarded qw(:step verbose);

verbose(0);

my $var = 0;

step trivial =>
  ensure { $var == 1 }
  using {
     $var = 1;
  }
  ;

ok($var);
