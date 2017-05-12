## todo: write some tests.

use Test;
BEGIN { plan tests => 3 };
use Algorithm::Evolve;
use Algorithm::Evolve::Util qw/:str :arr/;
ok(1);

my $ok;
###################################################
# make sure fixed pt mutation always changes bits #
###################################################

$ok = 1;
my $strlen = 100;
for (1 .. 100) {
	my $mutations = int (rand($strlen/2)) + 1;
	my $str       = str_random($strlen, ['a'..'z']);
	my $str2      = str_mutate($str, $mutations, ['a'..'z']);
	$ok = 0 unless ($mutations + str_agreement($str, $str2) == $strlen);
}
ok($ok);



$ok = 1;
my $strlen = 100;
for (1 .. 100) {
	my $mutations = int (rand($strlen/2)) + 1;
	my $str       = arr_random($strlen, ['a'..'z']);
	my $str2      = arr_mutate($str, $mutations, ['a'..'z']);
	$ok = 0 unless ($mutations + arr_agreement($str, $str2) == $strlen);
}
ok($ok);
	


