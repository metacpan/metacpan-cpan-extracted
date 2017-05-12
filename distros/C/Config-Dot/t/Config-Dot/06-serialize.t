# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $c = Config::Dot->new(
	'config' => {
		'key' => 'value',
	},
);
is($c->serialize, 'key=value', 'Serialize simple key, value pair.');

# Test.
$c = Config::Dot->new(
	'config' => {
		'key' => {
			'subkey' => 'value',
		},
	},
);
my $right_ret = <<'END';
key.subkey=value
END
chomp $right_ret;
is($c->serialize, $right_ret, 'Serialize key with subkey.');

# Test.
$c = Config::Dot->new(
	'config' => {
		'key' => "Foo\nBar",
	},
);
eval {
	$c->serialize;
};
is($EVAL_ERROR, "Unsupported stay with newline in value.\n",
	'Unsupported stay with newline in value.');
clean();
