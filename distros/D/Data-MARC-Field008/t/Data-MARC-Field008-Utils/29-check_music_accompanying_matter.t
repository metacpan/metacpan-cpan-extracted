use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_music_accompanying_matter);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'ab    ',
};
my $ret = check_music_accompanying_matter($self, 'key');
is($ret, undef, 'Right music accompanying matter is present (ab    ).');

# Test.
$self = {
	'key' => '      ',
};
$ret = check_music_accompanying_matter($self, 'key');
is($ret, undef, 'Right music accompanying matter form is present (      ).');

# Test.
$self = {
	'key' => '||||||',
};
$ret = check_music_accompanying_matter($self, 'key');
is($ret, undef, 'Right music accompanying matter form is present (||||||).');

# Test.
$self = {};
eval {
	check_music_accompanying_matter($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_music_accompanying_matter($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_music_accompanying_matter($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'xx    ',
};
eval {
	check_music_accompanying_matter($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' contains bad music accompanying matter character.\n",
	"Parameter 'key' contains bad music accompanying matter character (xx    ).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_music_accompanying_matter($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
