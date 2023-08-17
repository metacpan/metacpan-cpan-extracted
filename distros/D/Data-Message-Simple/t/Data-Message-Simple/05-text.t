use strict;
use warnings;

use Data::Message::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Simple->new(
	'text' => 'This is message.',
);
is($obj->text, 'This is message.', 'Get text (This is message.).');
