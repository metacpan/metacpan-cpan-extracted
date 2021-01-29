use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new(
	'skip_comments' => 1,
);
$obj->put(
	['i', 'target', 'code'],
);
my $ret = $obj->flush;
is($ret, '', 'XXX Skip instruction (as comment).');

# Test.
$obj = CSS::Struct::Output::Indent->new(
	'skip_comments' => 0,
);
$obj->put(
	['i', 'target', 'code'],
);
$ret = $obj->flush;
is($ret, "/* targetcode */", 'XXX Instruction (as comment).');
