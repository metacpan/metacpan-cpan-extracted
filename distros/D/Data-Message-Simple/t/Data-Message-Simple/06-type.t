use strict;
use warnings;

use Data::Message::Simple;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Simple->new(
	'text' => 'This is message.',
);
is($obj->type, 'info', 'Get default type (info).');

# Test.
$obj = Data::Message::Simple->new(
	'lang' => 'en',
	'text' => 'This is message.',
	'type' => 'error',
);
is($obj->type, 'error', 'Get explicit type (error).');

# Test.
$obj = Data::Message::Simple->new(
	'text' => 'This is message.',
	'type' => undef,
);
is($obj->type, 'info', 'Get default type (info).');
