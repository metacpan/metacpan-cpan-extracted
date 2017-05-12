# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot::Array;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $c = Config::Dot::Array->new(
	'config' => {
		'key' => 'value',
	},
);
is($c->serialize, 'key=value', 'Serialize simple key, value pair.');

# Test.
$c = Config::Dot::Array->new(
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
$c = Config::Dot::Array->new(
	'config' => {
		'key' => ['value1', 'value2'],
	},
);
$right_ret = <<'END';
key=value1
key=value2
END
chomp $right_ret;
is($c->serialize, $right_ret, 'Serialize key with two values.');
