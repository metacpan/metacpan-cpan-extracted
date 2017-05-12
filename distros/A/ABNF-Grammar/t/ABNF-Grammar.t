use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('ABNF::Grammar', qw(Grammar)) };

my $grammar = eval { Grammar->new("t/data/test.abnf", qw(token pair expr)) };
isa_ok(
	$grammar,
	"ABNF::Grammar",
	"Create test grammar"
);

ok(
	!eval {
		Grammar->new("t/data/test.abnf", qw(token pair expr lol))
	},
	"Cant create with unexisted command"
);

my $token = eval { $grammar->rule("expr") };
ok(
	$token,
	"Get token rule"
);

ok(
	!eval {
		eval { $grammar->rule("DIGIT") }
	},
	"Cant get unexisted rule"
);

ok(
   $grammar->rules(),
   "Get all rules"
);

ok(
	$grammar->hasCommand("expr"),
	"Is command on command good"
);

ok(
	!$grammar->hasCommand("lol"),
	"Is command on non-command bad"
);

eval{
	$grammar->replaceBasicRule("CRLF", {
		class => "Rule",
		name => "CRLF",
		value => {
			class => "Literal",
			value => "\n"
		}
	})
};

ok(!$@, "Ok replace");

eval{
	$grammar->replaceBasicRule("CRLF", {
		class => "Rule",
		name => "CRLFAA",
		value => {
			class => "Literal",
			value => "\n"
		}
	})
};

ok($@, "Cant replace with name != rule");

eval{
	$grammar->replaceBasicRule("CRLFAA", {
		class => "Rule",
		name => "CRLFAA",
		value => {
			class => "Literal",
			value => "\n"
		}
	})
};

ok($@, "Cant replace unexisted rule");

eval{
	$grammar->replaceRule("noop", {
		class => "Rule",
		name => "noop",
		value => {
			class => "Literal",
			value => "\n"
		}
	})
};

ok(!$@, "Ok replace");

eval{
	$grammar->replaceRule("noop", {
		class => "Rule",
		name => "noopaa",
		value => {
			class => "Literal",
			value => "\n"
		}
	})
};

ok($@, "Cant replace with name != rule");

eval{
	$grammar->replaceRule("noopaa", {
		class => "Rule",
		name => "noopaa",
		value => {
			class => "Literal",
			value => "\n"
		}
	})
};

ok($@, "Cant replace unexisted rule");