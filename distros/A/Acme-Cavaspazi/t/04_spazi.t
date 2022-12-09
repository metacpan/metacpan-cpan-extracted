use strict;
use warnings;
use Test::More;
use Data::Dumper;
use_ok 'Acme::Cavaspazi';

my $string = "this is a stiring";

my $cavaspazi = cavaspazi($string);
ok( ($cavaspazi !~/ /), "cavaspazi($string) does not contain spaces: " . $cavaspazi );

my @spazi = ("cava spazi", "altri spazi");
my @nospazi = cavaspazi(@spazi);

for my $item (@nospazi) {
    ok($item !~/ /, "Item has no spaces: <$item>");
}

ok( (scalar @spazi == scalar @nospazi), "Same items in input/output");
done_testing();
