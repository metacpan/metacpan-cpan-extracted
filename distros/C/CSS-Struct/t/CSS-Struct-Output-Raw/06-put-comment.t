use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Raw->new(
	'skip_comments' => 1,
);
$obj->put(
	['c', 'comment'],
);
my $ret = $obj->flush;
is($ret, '');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment'],
	['s', 'body'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment1'],
	['c', 'comment2'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['c', 'comment'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{attr1:value1;attr2:value2;}');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body,div{}');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['e'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{}div{}');

# Test.
$obj = CSS::Struct::Output::Raw->new(
	'skip_comments' => 0,
);
$obj->put(
	['c', 'comment'],
);
$ret = $obj->flush;
is($ret, '/*comment*/');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment'],
	['s', 'body'],
	['e'],
);
$ret = $obj->flush;
is($ret, '/*comment*/body{}');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['e'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
is($ret, '/*comment1*/body{}/*comment2*/div{}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{/*comment*/}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment1'],
	['c', 'comment2'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{/*comment1*//*comment2*/}');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['c', 'comment'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
is($ret, 'body{attr1:value1;/*comment*/attr2:value2;}');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
is($ret, '/*comment1*/body,/*comment2*/div{}');
