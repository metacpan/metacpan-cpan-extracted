use strict;
use warnings;

use Commons::Link;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Commons::Link->new(
	'utf-8' => 0,
);
my $ret = $obj->thumb_link('Michal from Czechia.jpg', 100);
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Michal_from_Czechia.jpg/100px-Michal_from_Czechia.jpg',
	'Link defined by image name and width.');

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->thumb_link('File:Michal from Czechia.jpg', 100);
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Michal_from_Czechia.jpg/100px-Michal_from_Czechia.jpg',
	"Link defined by image name and width. With prefix 'File:'");

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->thumb_link('Image:Michal from Czechia.jpg', 100);
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Michal_from_Czechia.jpg/100px-Michal_from_Czechia.jpg',
	"Link defined by image name and width. With prefix 'Image:'");

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->thumb_link('michal from Czechia.jpg', 100);
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Michal_from_Czechia.jpg/100px-Michal_from_Czechia.jpg',
	"Link defined by image name and width. First character is small.");
