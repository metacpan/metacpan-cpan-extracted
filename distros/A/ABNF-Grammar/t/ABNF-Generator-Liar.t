use strict;
use warnings;

use Test::More tests => 29;
use ABNF::Grammar qw(Grammar);
use ABNF::Validator qw(Validator);
BEGIN {
	use_ok('ABNF::Generator::Liar', qw(Liar))
};
my $grammar = eval { Grammar->new("t/data/test.abnf", qw(token pair expr minus noop)) };
$grammar->replaceBasicRule("CRLF", {
	class => "Rule",
	name => "CRLF",
	value => {
		class => "Literal",
		value => "\n"
	}
});
my $valid = Validator->new($grammar);
my $liar = Liar->new($grammar, $valid);

ok($liar, "Create Liar validator");

eval { $liar->generate("lol") };
ok($@, "Ok no rule");

for ( 1 .. 20 ) {
	my $str = $liar->generate("minus");
	1 while $str =~ s@[\+\-\*\/]\s\d+\s\d+@0@g;
	unlike($str, qr/^\d+$/, "Generated str isn't ok");
}

is($liar->withoutArguments("noop", "\n"), "", "Without arguments for noop");
like($liar->withoutArguments("minus", "\n"), qr/^-\s*\n$/, "Without arguments for minus");

eval { $liar->withoutArguments("lol") };
ok($@, "Ok no rule");

ok(!$liar->hasCommand($liar->unExistedCommand()), "Ok unexisted command");

ok(length($liar->endlessCommand("minus", "\n")) > 1024, "Ok long rule");

eval { $liar->endlessCommand("noopasa", "\n") };
ok($@, "Ok no rule");