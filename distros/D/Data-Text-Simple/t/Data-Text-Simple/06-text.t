use strict;
use warnings;

use Data::Text::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Text::Simple->new(
	'lang' => 'en',
	'text' => 'This is text.',
);
is($obj->text, 'This is text.', 'Get text (This is text.).');
