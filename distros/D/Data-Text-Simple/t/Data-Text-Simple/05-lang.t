use strict;
use warnings;

use Data::Text::Simple;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Text::Simple->new(
	'text' => 'This is text.',
);
is($obj->lang, undef, 'Get language (undef - default).');

# Test.
$obj = Data::Text::Simple->new(
	'lang' => 'en',
	'text' => 'This is text.',
);
is($obj->lang, 'en', 'Get language (en).');
