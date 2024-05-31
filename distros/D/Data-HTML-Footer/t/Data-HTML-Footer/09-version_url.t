use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
is($obj->version_url, undef, 'Get author URL (undef - default).');

# Test.
$obj = Data::HTML::Footer->new(
	'version_url' => '/changes',
);
is($obj->version_url, '/changes', 'Get version URL (/changes).');
