use strict;
use warnings;

use Business::UDC;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Business::UDC->new('0/9');
is($obj->error, undef, 'Get error (no error).');

# Test.
$obj = Business::UDC->new('bad');
is($obj->error, "Alphabetical specification 'bad' cannot appear standalone.",
	'Get error (Alphabetical specification \'bad\' cannot appear standalone.).');
# TODO Check error parameters

# Test.
$obj = Business::UDC->new;
is($obj->error, 'No input provided.', 'No input provided.');

# Test.
$obj = Business::UDC->new('');
is($obj->error, 'Empty input.', 'Empty input.');
