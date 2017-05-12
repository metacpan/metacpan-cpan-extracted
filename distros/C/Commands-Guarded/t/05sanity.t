use Test;
BEGIN { plan tests => 3 };
use Commands::Guarded qw(:step verbose);

verbose(0);

my $var = 0;

eval {
   step shouldFail =>
     ensure { $var == 0 }
       using { $var = 0 }
	 sanity { $var == 1 }
	   ;
};

ok($@);

$var = 1;

eval {
   step shouldNotFail =>
     ensure { $var == 0 }
       using { $var = 0 }
	 sanity { 1 == 1 }
	   ;
};

ok(not $@);

$var = 0;

eval {
   step shouldFailOnSecondTry =>
     ensure { $var == 1 }
       using { $var = 1 }
	 sanity { $var == 0 }
};

ok($@);
