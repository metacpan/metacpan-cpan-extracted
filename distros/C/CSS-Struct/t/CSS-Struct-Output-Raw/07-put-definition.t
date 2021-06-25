use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Raw->new;
$obj->put(
	['s', 'body'],
	['d', 'attr', 'value'],
	['e'],
);
my $ret = $obj->flush;
is($ret, 'body{attr:value;}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{attr1:value1;attr2:value2;}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['s', 'div'],
	['d', 'attr1', 'value1'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body,div{attr1:value1;attr2:value2;}');
