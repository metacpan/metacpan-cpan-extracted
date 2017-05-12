use Test;
BEGIN { plan tests => 1 };
use Commands::Guarded qw(:step verbose);

verbose(0);

my $var = 0;

eval {
   step nullOp =>
     ensure { $var == 1 }
       using {
	  $var = 0	; # shouldn't work
       };
};

ok($@);
