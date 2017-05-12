use Test::More;

use Colouring::In;

my $white = Colouring::In->new('#ffffff');
my $black = $white->darken('100%');
is($black->toCSS, '#000');
$white = $black->lighten('100%');
is($white->toCSS, '#fff');

done_testing();
