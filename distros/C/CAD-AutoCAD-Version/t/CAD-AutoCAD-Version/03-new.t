use strict;
use warnings;

use CAD::AutoCAD::Version;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	CAD::AutoCAD::Version->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	CAD::AutoCAD::Version->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = CAD::AutoCAD::Version->new;
isa_ok($obj, 'CAD::AutoCAD::Version');
