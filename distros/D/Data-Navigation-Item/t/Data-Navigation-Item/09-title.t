use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
is($obj->title, 'Title', 'Get title (Title).');
