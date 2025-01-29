use Test::More;

use Colouring::In::XS;

my $white = Colouring::In::XS->new('#ffffff');
my $black = $white->darken('100%');
is($black->toCSS, '#000');
$white = $black->lighten('100%');
is($white->toCSS, '#fff');
my $transparent = $white->fadeout('100%');
is($transparent->toCSS, 'rgba(255,255,255,0)');
$white = $transparent->fadein('100%');

is($white->toCSS, '#fff');

done_testing();
