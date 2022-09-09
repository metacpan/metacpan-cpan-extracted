use Test::More tests => 5;
use Test::NoWarnings;

use_ok('Acme::DOBBY::Utils');
ok(defined &Acme::DOBBY::Utils::sum, 'sum is defined');
is(sum(1..10),55,'Good sum');
is(sum(qw(1 2 3 a b c 123abc)),129,'The weird sum is 128');
