use strict;
use warnings;

use Commons::Link;
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Commons::Link->new(
	'utf-8' => 0,
);
my $ret = $obj->link('Michal from Czechia.jpg');
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
	'Link defined by image name.');

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->link('File:Michal from Czechia.jpg');
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
	"Link defined by image name. With prefix 'File:'");

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->link('Image:Michal from Czechia.jpg');
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
	"Link defined by image name. With prefix 'Image:'");

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
$ret = $obj->link('michal from Czechia.jpg');
is($ret, 'http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
	"Link defined by image name. First character is small.");

# Test.
$obj = Commons::Link->new(
	'utf-8' => 1,
);
my $file = decode_utf8('Čaj.jpg');
$ret = $obj->link($file);
is($ret, decode_utf8('http://upload.wikimedia.org/wikipedia/commons/f/f3/%C4%8Caj.jpg'),
	"Link defined by image name. Diacritics.");
