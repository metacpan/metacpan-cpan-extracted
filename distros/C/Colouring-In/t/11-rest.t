use Test::More;

use Colouring::In;

my $color = Colouring::In->new([0, 0, 0], 'a');
is($color->toRGB(1), 'rgb(0,0,0)');
is_deeply($color->rgb(0,0,0,1), {
	'alpha' => 1,
	'colour' => [
		'0',
		'0',
		'0'
	]
});
is_deeply($color->hsl('0', '0', '0', 1), {
	'alpha' => 1,
	'colour' => [
		'0',
		'0',
		'0'
	]
});
is($color->lighten('100%', 'exists')->toRGB(), 'rgb(255,255,255)');
my $col2 = Colouring::In->new([0, 0, 0, 1]);
is($col2->lighten('50%', 'relative')->toHSL(), 'hsl(0,0%,49.8039215686275%)');
my $col3 = Colouring::In->new([1, 1, 1], 1);
is($col3->lighten('50%', 'relative')->toHSL(), 'hsl(0,0%,0.392156862745098%)');
my $col4 = Colouring::In->new([255, 255, 255], 1);
is($col4->darken('100%', 'exists')->toRGB(), 'rgb(0,0,0)');
is($col4->darken('50%', 'relative')->toHSL(), 'hsl(0,0%,49.8039215686275%)');

my $nw = $col4->fadeout('50%', 'exists');
is($nw->toRGBA, 'rgba(255,255,255,0.5)');
$nw = $nw->fadeout('50%', 'relative'); 
is($nw->toRGBA, 'rgba(255,255,255,0.25)');

my $in = $nw->fadein('50%', 'exists');
is($in->toRGBA, 'rgba(255,255,255,0.75)');
is($in->fadein('10%', 'relative')->toRGBA, 'rgba(255,255,255,0.825)');

my $undefs = Colouring::In->new([undef, undef, undef], undef);
is($undefs->toRGBA, 'rgba(255,255,255,1)' );

my $okay = Colouring::In->new([105, 200, 10], 1);
is($okay->toHEX, '#69c80a');
#TODO: rounding
is($okay->toHSL(), 'hsl(90,90.4761904761905%,41.1764705882353%)');

my $okay2 = Colouring::In->new([255, 220, 230]);
is($okay2->toHSL(), 'hsl(342.857142857143,100%,93.1372549019608%)');
is($okay2->toHSV(), 'hsv(342.857142857143,13.7254901960784%,100%)');

my $okay3 = Colouring::In->new([225, 255, 230]);
is($okay3->toHSL(), 'hsl(130,100%,94.1176470588235%)');
is($okay3->toHSV(), 'hsv(130,11.7647058823529%,100%)');

my $okay4 = Colouring::In->new([225, 230, 255, 1]);
is($okay4->toHSL(), 'hsl(230,100%,94.1176470588235%)');
is($okay4->toHSV(), 'hsv(230,11.7647058823529%,100%)');





done_testing();


