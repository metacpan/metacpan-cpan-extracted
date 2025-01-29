use Test::More;

use Colouring::In::XS;

my $color = Colouring::In::XS->new([0, 0, 0], 'a');
is($color->toRGB(1), 'rgb(0,0,0)');

is_deeply($color->rgb(0,0,0,1)->toCSS, '#000');
is_deeply($color->hsl('0', '0', '0', 1)->toCSS, '#000');

is($color->lighten('100%', 'exists')->toRGB(), 'rgb(255,255,255)');

my $col2 = Colouring::In::XS->new([0, 0, 0, 1]);

is($col2->lighten('50%', 'relative')->toHSL(), 'hsl(0,0%,50%)');

my $col3 = Colouring::In::XS->new([1, 1, 1], 1);
is($col3->lighten('50%', 'relative')->toHSL(), 'hsl(0,0%,50%)');

my $col4 = Colouring::In::XS->new([255, 255, 255], 1);
is($col4->darken('100%', 'exists')->toRGB(), 'rgb(0,0,0)');
is($col4->darken('50%', 'relative')->toHSL(), 'hsl(0,0%,50%)');

my $nw = $col4->fadeout('50%', 'exists');
is($nw->toRGBA, 'rgba(255,255,255,0.5)');
$nw = $nw->fadeout('50%', 'relative'); 
is($nw->toRGBA, 'rgba(255,255,255,0.25)');

my $in = $nw->fadein('50%', 'exists');
is($in->toRGBA, 'rgba(255,255,255,0.75)');
is($in->fadein('10%', 'relative')->toRGBA, 'rgba(255,255,255,0.82)');

my $undefs = Colouring::In::XS->new([undef, undef, undef], undef);

is($undefs->toRGBA, 'rgba(255,255,255,1)' );
my $okay = Colouring::In::XS->new([105, 200, 10], 1);
is($okay->toHEX, '#69c80a');
#TODO: rounding
is($okay->toHSL(), 'hsl(90,90%,41%)');

my $okay2 = Colouring::In::XS->new([255, 220, 230]);
is($okay2->toHSL(), 'hsl(342,100%,93%)');
is($okay2->toHSV(), 'hsv(343,14%,100%)');

my $okay3 = Colouring::In::XS->new([225, 255, 230]);
is($okay3->toHSL(), 'hsl(130,100%,94%)');
is($okay3->toHSV(), 'hsv(130,12%,100%)');

my $okay4 = Colouring::In::XS->new([225, 230, 255, 1]);
is($okay4->toHSL(), 'hsl(229,100%,94%)');
is($okay4->toHSV(), 'hsv(230,12%,100%)');

done_testing();


