use Test::More;
use Data::Crumbr;
use File::Spec::Functions qw< splitpath catpath >;
my ($v, $d) = splitpath(__FILE__);
my $data = do(catpath($v, $d, 'data.pl'));

can_ok(__PACKAGE__, 'crumbr');

my $crumbr = crumbr(profile => 'JSON');
isa_ok($crumbr, 'CODE');

my $encoded = $crumbr->($data);
ok($encoded, 'got some data');

my $expected = '{"array":["what"]}
{"array":["ever"]}
{"array":[{"empty":[]}]}
{"array":[{"inner":"part"}]}
{"false":false}
{"four":"4.0"}
{"hash":{"ar":[1]}}
{"hash":{"ar":[2]}}
{"hash":{"ar":[3]}}
{"hash":{"something":"funny \u263A \u263B"}}
{"hash":{"with \u265C":{}}}
{"one":"1"}
{"three":3.1}
{"true":true}
{"two":2}';

is($encoded, $expected, 'data as expected');

done_testing();
