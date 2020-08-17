use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Raw->new(
	'skip_comments' => 1,
);
$obj->put(
	['i', 'target', 'code'],
);
my $ret = $obj->flush;
is($ret, '');

# Test.
$obj = CSS::Struct::Output::Raw->new(
	'skip_comments' => 0,
);
$obj->put(
	['i', 'target', 'code'],
);
$ret = $obj->flush;
is($ret, '/*targetcode*/');
