use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new;
$obj->put(
	['r', 'raw'],
);
my $ret = $obj->flush;
is($ret, 'raw');
