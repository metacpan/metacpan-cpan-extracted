use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Raw->new;
$obj->put(
	['a', '@import', 'file.css'],
);
my $ret = $obj->flush;
is($ret, '@import "file.css";');
