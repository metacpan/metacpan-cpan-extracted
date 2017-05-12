use Acme::Umlautify;
use Test::Simple tests => 3;
use utf8;
use strict;

ok(umlautify('This is a test of the emergency umlaut system!') eq 'T̈ḧïs̈ ïs̈ ä ẗës̈ẗ öf̈ ẗḧë ëm̈ër̈g̈ën̈c̈ÿ üm̈l̈äüẗ s̈ÿs̈ẗëm̈!̈', 'String comparison');

my @array = umlautify(qw/foo bar baz/);
my $test  = join ':', @array;

ok(scalar(@array) == 3, 'Array count');
ok($test eq 'f̈öö:b̈är̈:b̈äz̈', 'Array test');
