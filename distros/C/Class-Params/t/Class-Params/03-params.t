# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Params qw(params);
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 18;
use Test::NoWarnings;

# Test.
my $self = {};
my $def_hr = {};
eval {
	params($self, $def_hr, ['foo', 'bar']);
};
is($EVAL_ERROR, "Unknown parameter 'foo'.\n", "Unknown parameter 'foo'.");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'SCALAR', 0],
};
params($self, $def_hr, ['foo', 'bar']);
is_deeply(
	$self,
	{
		'_foo' => 'bar',
	},
	"Right check for parameter 'foo' (SCALAR).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'SCALAR', 1],
	'bar' => ['_bar', undef, 'SCALAR', 0],
};
eval {
	params($self, $def_hr, ['bar', 'baz']);
};
is($EVAL_ERROR, "Parameter 'foo' is required.\n",
	"Parameter 'foo' is required (SCALAR).");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'SCALAR', 1],
};
params($self, $def_hr, ['foo', 'bar']);
is_deeply(
	$self,
	{
		'_foo' => 'bar',
	},
	"Right check for required parameter 'foo' (SCALAR).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'HASH', 0],
};
eval {
	params($self, $def_hr, ['foo', 'bar']);
};
is($EVAL_ERROR, "Bad parameter 'foo' type.\n",
	"Bad parameter 'foo' type (HASH).");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'HASH', 0],
};
params($self, $def_hr, ['foo', {'xxx' => 'yyy'}]);
is_deeply(
	$self,
	{
		'_foo' => {
			'xxx' => 'yyy',
		},
	},
	"Right check for parameter 'foo' (HASH).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'ARRAY', 0],
};
eval {
	params($self, $def_hr, ['foo', 'bar']);
};
is($EVAL_ERROR, "Bad parameter 'foo' type.\n",
	"Bad parameter 'foo' type (ARRAY).");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, 'ARRAY', 0],
};
params($self, $def_hr, ['foo', ['xxx', 'yyy']]);
is_deeply(
	$self,
	{
		'_foo' => ['xxx', 'yyy'],
	},
	"Right check for parameter 'foo' (ARRAY).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, ['SCALAR', 'ARRAY'], 0],
};
params($self, $def_hr, ['foo', 'bar']);
is_deeply(
	$self,
	{
		'_foo' => 'bar',
	},
	"Right check for parameter 'foo' with multiple types (SCALAR).",
);
params($self, $def_hr, ['foo', ['xxx', 'yyy']]);
is_deeply(
	$self,
	{
		'_foo' => ['xxx', 'yyy'],
	},
	"Right check for parameter 'foo' with multiple types (ARRAY).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', undef, ['SCALAR', 'ARRAY'], 0],
};
eval {
	params($self, $def_hr, ['foo', {}]);
};
is($EVAL_ERROR, "Bad parameter 'foo' type.\n",
	"Bad parameter 'foo' type with multiple types.");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', 'Moo', 'Moo', 0],
};
eval {
	params($self, $def_hr, ['foo', 'bar']);
};
is($EVAL_ERROR, "Bad parameter 'foo' type.\n",
	"Bad parameter 'foo' type (Class).");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', 'Moo', 'Moo', 0],
};
my $moo = bless {}, 'Moo';
params($self, $def_hr, ['foo', $moo]);
is_deeply(
	$self,
	{
		'_foo' => $moo,
	},
	"Right check for 'foo' type (Moo class).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', 'Moo', ['Moo', 'ARRAY'], 0],
};
params($self, $def_hr, ['foo', $moo]);
is_deeply(
	$self,
	{
		'_foo' => $moo,
	},
	"Right check for 'foo' type (Moo class).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', 'Moo', ['Moo', 'ARRAY'], 0],
};
params($self, $def_hr, ['foo', [$moo, $moo]]);
is_deeply(
	$self,
	{
		'_foo' => [$moo, $moo],
	},
	"Right check for 'foo' type (Moo class).",
);

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', 'Moo', ['Moo', 'ARRAY'], 0],
};
eval {
	params($self, $def_hr, ['foo', [$moo, 'foo']]);
};
is($EVAL_ERROR, "Bad parameter 'foo' class.\n",
	"Bad parameter 'foo' class (SCALAR).");
clean();

# Test.
$self = {};
$def_hr = {
	'foo' => ['_foo', 'Moo', ['Moo', 'ARRAY'], 0],
};
my $baz = bless {}, 'Baz';
eval {
	params($self, $def_hr, ['foo', [$moo, $baz]]);
};
is($EVAL_ERROR, "Bad parameter 'foo' class.\n",
	"Bad parameter 'foo' class (Different Class).");
clean();
