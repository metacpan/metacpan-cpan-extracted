use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
is($obj->author_url, undef, 'Get author URL (undef - default).');

# Test.
$obj = Data::HTML::Footer->new(
	'author_url' => 'https://skim.cz',
);
is($obj->author_url, 'https://skim.cz', 'Get author URL (https://skim.cz).');
