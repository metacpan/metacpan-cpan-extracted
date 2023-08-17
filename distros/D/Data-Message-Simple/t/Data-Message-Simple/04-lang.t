use strict;
use warnings;

use Data::Message::Simple;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Simple->new(
	'text' => 'This is message.',
);
is($obj->lang, undef, 'Get default language (undef).');

# Test.
$obj = Data::Message::Simple->new(
	'lang' => 'en',
	'text' => 'This is message.',
	'type' => 'error',
);
is($obj->lang, 'en', 'Get explicit language (en).');
