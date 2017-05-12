use Acme::Umlautify;
use Test::Simple tests => 4;
use utf8;
use strict;

my $au = new Acme::Umlautify;

ok($au);

my $check = $au->do('This is a test of the emergency umlaut system!');
ok($check eq 'T̈ḧïs̈ ïs̈ ä ẗës̈ẗ öf̈ ẗḧë ëm̈ër̈g̈ën̈c̈ÿ üm̈l̈äüẗ s̈ÿs̈ẗëm̈!̈','String comparison');

my @array = $au->do(qw/foo bar baz/);
my $test  = join ':', @array;

ok(scalar(@array) == 3, 'Array count');
ok($test eq 'f̈öö:b̈är̈:b̈äz̈', 'Array test');