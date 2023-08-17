use strict;
use warnings;

use Data::HTML::A;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::A->new;
is($obj->url, undef, 'Get URL (undef).');

# Test.
$obj = Data::HTML::A->new(
	'url' => 'https://example.com',
);
is($obj->url, 'https://example.com', 'Get URL (https://example.com).');
