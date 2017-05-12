use Test;
BEGIN { plan tests => 3 };
use Commands::Guarded qw(:step verbose);

verbose(0);

my $ran = 0;
my $var = 0;

step assertTrue =>
    ensure { $ran = 1; $var == 0 }
    ;

ok($var == 0);
ok($ran == 1);

$ran = 0;

eval {
    step assertFalse =>
        ensure { $ran = 1; $var == 1}
            ;
};

ok($@);
