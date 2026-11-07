use strict;
use warnings;
use Test::More;

use Colouring::In::XS qw/lighten darken fadeout fadein saturate desaturate fade greyscale mix tint shade/;

sub dies_with {
	my ($colour, $message, $name) = @_;
	my $made = eval { Colouring::In::XS->new($colour); 1 };
	is($made, undef, "$name dies");
	like($@, qr/^\Q$message\E/, "$name says why");
}

{
	my $made = eval { Colouring::In::XS->new; 1 };
	is($made, undef, 'new without a colour dies');
	like($@, qr/^Usage: Colouring::In::XS->new\(colour \[, alpha\]\)/, 'with the usage');
}

dies_with('#abcd', 'hex length must be 3 or 6', 'a four digit hex');
dies_with($_, 'Invalid hex character', "the hex $_") for '#-00', '#:::', '#ggg', '#GGG', '#xyz';
dies_with($_, 'Cannot convert the colour format', "the string $_") for 'blue', 'rxx', 'rgx', 'hxx', 'hsx', 'rgb(1,2)', 'hsl(1)';
dies_with({}, 'Cannot convert the colour format', 'a hash reference');

is(Colouring::In::XS->new('#ABC')->toHEX(1), '#aabbcc', 'upper case short hex');
is(Colouring::In::XS->new('#AbCdEf')->toHEX(1), '#abcdef', 'mixed case long hex');

is(Colouring::In::XS->new('#120000')->toHEX, '#120000', 'red keeps the long form');
is(Colouring::In::XS->new('#001200')->toHEX, '#001200', 'green keeps the long form');
is(Colouring::In::XS->new('#000012')->toHEX, '#000012', 'blue keeps the long form');
is(Colouring::In::XS->new('#112233')->toHEX, '#123', 'pairs shorten');

is(Colouring::In::XS->new('rgb(1,2,3,4,5)')->toRGBA, 'rgba(1,2,3,4)', 'a fifth number is dropped');
is(Colouring::In::XS->new('rgb(1,2,3')->toRGBA, 'rgba(1,2,3,1)', 'a number at the end of the string counts');
is(Colouring::In::XS->new('rgb(1,2,3,0.5')->toRGBA, 'rgba(1,2,3,0.5)', 'so does an alpha there');
is(Colouring::In::XS->new('rgb(1,2,3,4,5')->toRGBA, 'rgba(1,2,3,4)', 'and a fifth number there is dropped');
is(Colouring::In::XS->new('hsl(120, 0.5, 50)')->toRGB, 'rgb(126,128,126)', 'a lightness over one makes both percentages');

{
	my ($r) = Colouring::In::XS->new('rgb(' . ('1' x 40) . ',2,3)')->colour;
	cmp_ok($r, '>', 1e30, 'a long run of digits is read');
	cmp_ok($r, '<', 1e31, 'to the width of the number buffer');
}

is(Colouring::In::XS->new([10])->toRGBA, 'rgba(10,255,255,1)', 'a short array fills with white');
is(Colouring::In::XS->new([1, 2])->toRGBA, 'rgba(1,2,255,1)', 'a two element array too');
is(Colouring::In::XS->new([])->toRGBA, 'rgba(255,255,255,1)', 'an empty array is white');
is(Colouring::In::XS->new([1, 2, 3, undef])->toRGBA, 'rgba(1,2,3,1)', 'an undefined fourth element is opaque');
is(Colouring::In::XS->new([1, 2, 3, 0.5])->toRGBA, 'rgba(1,2,3,0.5)', 'a fourth element is the alpha');

is(Colouring::In::XS->rgb('100%', '50%', '0%')->toRGB, 'rgb(255,127,0)', 'rgb takes percentages');
is(Colouring::In::XS->rgb('', '', '')->toRGB, 'rgb(0,0,0)', 'an empty channel is zero');
is(Colouring::In::XS->rgb(10, 20, 30)->toRGBA, 'rgba(10,20,30,1)', 'rgb without an alpha');
is(Colouring::In::XS->rgba(10, 20, 30, 0.5)->toRGBA, 'rgba(10,20,30,0.5)', 'rgba');
is(Colouring::In::XS->rgba(10, 20, 30)->toRGBA, 'rgba(10,20,30,1)', 'rgba without an alpha');
is(Colouring::In::XS->hsl(120, 50, 50)->toRGBA, 'rgba(63,191,63,1)', 'hsl without an alpha');
is(Colouring::In::XS->hsla(120, 50, 50, 0.5)->toRGBA, 'rgba(63,191,63,0.5)', 'hsla');
is(Colouring::In::XS->hsla(120, 50, 50)->toRGBA, 'rgba(63,191,63,1)', 'hsla without an alpha');
is(Colouring::In::XS->new('hsl(120, 0.5, 0.5)')->toRGB, 'rgb(63,191,63)', 'hsl takes fractions');

is(Colouring::In::XS->new('#00f')->toHSL, 'hsl(240,100%,50%)', 'a blue hue');
is(Colouring::In::XS->new('#0f0')->toHSL, 'hsl(120,100%,50%)', 'a green hue');
is(Colouring::In::XS->new('#f0f')->toHSL, 'hsl(300,100%,50%)', 'a magenta hue');
is(Colouring::In::XS->new('#0ff')->toHSV, 'hsv(180,100%,100%)', 'a cyan hue');
is(Colouring::In::XS->new('#000')->toHSV, 'hsv(0,0%,0%)', 'black has no hue');

is(Colouring::In::XS->new('rgba(0,0,0,0)')->mix('#fff', 100)->toRGBA, 'rgba(0,0,0,0)', 'all of a transparent colour');
is(Colouring::In::XS->new('#fff')->mix('rgba(0,0,0,0)', 0)->toRGBA, 'rgba(255,255,255,0)', 'none of an opaque colour');

is(lighten('#336699', '20%', 'relative')->toHEX(1), '#6698cc', 'lighten relative');
is(lighten('#336699', '20%', 'exists')->toHEX(1), '#6698cc', 'lighten with another mode');
is(lighten('#336699', '20%', undef)->toHEX(1), '#6698cc', 'lighten with an undefined mode');
is(darken('#336699', '20%', 'relative')->toHEX(1), '#28517a', 'darken relative');
is(darken('#336699', '20%', 'exists')->toHEX(1), '#19324c', 'darken with another mode');
is(darken('#336699', '20%', undef)->toHEX(1), '#19324c', 'darken with an undefined mode');
is(saturate('#336699', '20%', 'relative')->toHEX(1), '#2865a3', 'saturate relative');
is(saturate('#336699', '20%', 'exists')->toHEX(1), '#1e65ad', 'saturate with another mode');
is(saturate('#336699', '20%', undef)->toHEX(1), '#1e65ad', 'saturate with an undefined mode');
is(desaturate('#336699', '20%', 'relative')->toHEX(1), '#3d658e', 'desaturate relative');
is(desaturate('#336699', '20%', 'exists')->toHEX(1), '#476584', 'desaturate with another mode');
is(desaturate('#336699', '20%', undef)->toHEX(1), '#476584', 'desaturate with an undefined mode');
is(fadeout('rgba(255,255,255,0.5)', '20%', 'relative')->toRGBA, 'rgba(255,255,255,0.4)', 'fadeout relative');
is(fadeout('rgba(255,255,255,0.5)', '20%', 'exists')->toRGBA, 'rgba(255,255,255,0.3)', 'fadeout with another mode');
is(fadeout('rgba(255,255,255,0.5)', '20%', undef)->toRGBA, 'rgba(255,255,255,0.3)', 'fadeout with an undefined mode');
is(fadein('rgba(255,255,255,0.5)', '20%', 'relative')->toRGBA, 'rgba(255,255,255,0.6)', 'fadein relative');
is(fadein('rgba(255,255,255,0.5)', '20%', 'exists')->toRGBA, 'rgba(255,255,255,0.7)', 'fadein with another mode');
is(fadein('rgba(255,255,255,0.5)', '20%', undef)->toRGBA, 'rgba(255,255,255,0.7)', 'fadein with an undefined mode');
is(fade('#336699', '20%')->toRGBA, 'rgba(50,101,153,0.2)', 'fade');
is(greyscale('#336699')->toHEX(1), '#996633', 'greyscale');
is(mix('#000', '#fff', 30)->toHEX(1), '#b2b2b2', 'mix at a weight');
is(mix('#000', '#fff', 0)->toHEX(1), '#7f7f7f', 'mix at a weight of zero');
is(mix('#000', '#fff', undef)->toHEX(1), '#7f7f7f', 'mix at an undefined weight');
is(tint('#000', 30)->toHEX(1), '#4c4c4c', 'tint at a weight');
is(tint('#000', 0)->toHEX(1), '#7f7f7f', 'tint at a weight of zero');
is(tint('#000', undef)->toHEX(1), '#7f7f7f', 'tint at an undefined weight');
is(shade('#fff', 30)->toHEX(1), '#b2b2b2', 'shade at a weight');
is(shade('#fff', 0)->toHEX(1), '#7f7f7f', 'shade at a weight of zero');
is(shade('#fff', undef)->toHEX(1), '#7f7f7f', 'shade at an undefined weight');

done_testing;
