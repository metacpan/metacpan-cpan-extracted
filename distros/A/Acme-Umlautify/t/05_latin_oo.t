use Acme::Umlautify;
use Test::Simple tests => 4;
use strict;

my $au = new Acme::Umlautify;

ok($au);

ok($au->umlautify_latin('AEIOUYaeiouy') eq 'ÄËÏÖÜYäëïöüÿ');

my @array = $au->umlautify_latin(qw/foo bar baz/);
my $test  = join ':', @array;

ok(scalar(@array) == 3);
ok($test eq 'föö:bär:bäz');
