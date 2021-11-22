use strict;
use warnings;

use Commons::Link;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Commons::Link->new(
	'utf-8' => 0,
);
my $ret = $obj->mw_user_link('Skim');
is($ret, 'https://commons.wikimedia.org/wiki/User:Skim',
	'Link defined by user name.');

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->mw_user_link('User:Skim');
is($ret, 'https://commons.wikimedia.org/wiki/User:Skim',
	"Link defined by user name with 'User:' prefix.");
