use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 11;
use ABNF::Grammar qw(Grammar);

BEGIN {
	use_ok('ABNF::Validator', qw(Validator));
};

my $grammar = Grammar->new("t/data/test.abnf", qw(token pair expr minus noop));
$grammar->replaceBasicRule("CRLF", {
	class => "Rule",
	name => "CRLF",
	value => {
		class => "Literal",
		value => "\n"
	}
});
my $valid = eval { Validator->new($grammar) };

ok($valid, "Create new object on ABNF::Grammar");

ok($valid->validate("noop", "noop\n"), "Ok noop");

ok($valid->validate("expr", "- 1 5"), "Ok valid");

ok(!$valid->validate("expr", "1 + 5"), "Ok invalid");

eval { $valid->validate("lol", "1 + 5") };

ok($@, "Ok no rule");

ok($valid->validateArguments("minus", "1 5"), "Ok valid arguments");

ok(!$valid->validateArguments("minus", "1 + 5"), "Ok invalid arguments");

eval { $valid->validateArguments("lol", "1 + 5") };

ok($@, "Ok no rule");

ok($valid->validateCommand("expr"), "Ok command");

ok(!$valid->validateCommand("lol"), "Ok not a command");