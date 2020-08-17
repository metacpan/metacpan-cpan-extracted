use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new(
	'skip_bad_types' => 1,
);
$obj->put(
	['x', 'bad selector'],
);
my $ret = $obj->flush;
is($ret, '');
