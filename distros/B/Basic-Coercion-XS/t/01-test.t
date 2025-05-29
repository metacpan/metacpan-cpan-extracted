use Test::More;

use Basic::Coercion::XS qw/StrToArray/;

my $type = StrToArray(by => '-\(\d+\)-');
my $arrayref = $type->("this-(100)-is-(200)-a-(300)-string");
is_deeply(
	$arrayref,
	[qw/this is a string/]
);

$type = StrToArray();
$arrayref = $type->("a b\tc\nd");
is_deeply($arrayref, [qw(a b c d)], 'split by whitespace');

$type = StrToArray(by => ',');
$arrayref = $type->("a,b,c");
is_deeply($arrayref, [qw(a b c)], 'split by comma');

$type = StrToArray(by => '\\d+');
$arrayref = $type->("foo123bar456baz");
is_deeply($arrayref, [qw(foo bar baz)], 'split by digit sequence');

$type = StrToArray();
$arrayref = $type->("α β\tγ");
is_deeply($arrayref, [qw(α β γ)], 'split unicode by whitespace');

ok(1);

done_testing();
