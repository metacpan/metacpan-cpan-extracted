use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 26;
use ABNF::Grammar qw(Grammar);
use ABNF::Validator qw(Validator);
BEGIN {
	use_ok('ABNF::Generator::Honest', qw(Honest));
};

my $grammar = Grammar->new("t/data/test.abnf", qw(token pair expr noop minus));
$grammar->replaceBasicRule("CRLF", {
	class => "Rule",
	name => "CRLF",
	value => {
		class => "Literal",
		value => "\n"
	}
});
my $valid = Validator->new($grammar);
my $honest = eval { Honest->new($grammar, $valid) };

ok($honest, "Create Honest validator");

eval { $honest->generate("lol") };
ok($@, "Ok no rule");

for ( 1 .. 20 ) {
	my $str = $honest->generate("expr");
	1 while $str =~ s@[\+\-\*\/]\s\d+\s\d+@0@g;
	like($str, qr/^\d+$/, "Generated str is ok");
}

is($honest->withoutArguments("noop", "\n"), "noop\n", "Without arguments for noop");
is($honest->withoutArguments("minus", "\n"), "", "Without arguments for minus");

eval { $honest->withoutArguments("lol") };
ok($@, "Ok no rule");