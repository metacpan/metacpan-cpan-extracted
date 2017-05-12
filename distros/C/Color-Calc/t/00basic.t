use Test::More tests => 3;
use Test::NoWarnings;

use_ok('Color::Calc');

my $cc = new Color::Calc;
isa_ok($cc, 'Color::Calc');
