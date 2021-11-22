use strict;
use warnings;

use Commons::Link;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Commons::Link->new(
	'utf-8' => 0,
);
my $ret = $obj->mw_link('Michal from Czechia.jpg');
is($ret, 'https://commons.wikimedia.org/wiki/Michal%20from%20Czechia.jpg',
	'Link defined by image name.');

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->mw_link('File:Michal from Czechia.jpg');
is($ret, 'https://commons.wikimedia.org/wiki/File:Michal%20from%20Czechia.jpg',
	"Link defined by image name with 'File:' prefix.");

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->mw_link('Image:Michal from Czechia.jpg');
is($ret, 'https://commons.wikimedia.org/wiki/Image:Michal%20from%20Czechia.jpg',
	"Link defined by image name with 'Image:' prefix.");
