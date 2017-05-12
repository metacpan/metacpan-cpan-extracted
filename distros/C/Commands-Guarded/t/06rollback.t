use Test;
BEGIN { plan tests => 2 };
use Commands::Guarded qw(:step verbose);

verbose(0);

my $var = 1;

step makeVarZero =>
  ensure { $var == 0 }
  using { $var = 0 }
  rollback { $var = 1 };

ok($var == 0);

eval {
   step failForRollback =>
     ensure { 1 == 0 }
       using { 1 }
	 ;
};

ok($var == 1);
