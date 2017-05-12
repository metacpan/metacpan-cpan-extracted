# -*- perl -*-

# t/001_numbers.t - check if numbers in database are correct

use Test::More tests => 4;

use Acme::123;
my $object = Acme::123->new();
my @numbers = $object->getnumbers();
is($numbers[0],"one","English language as default language");
is($numbers[9],"ten","Check all numbers are in English numbers array");
$object->setLanguage('fr');
@numbers = $object->getnumbers();
is($numbers[0],"un","French language check");
is($numbers[9],"dix","Another French language check");
