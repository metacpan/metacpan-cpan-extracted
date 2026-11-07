use strict;
use warnings;
use Test::More;

use Colouring::In::XS;

# A method call compiled after the module loads runs the module's own op in
# place of entersub. Every method here is called on a colour object, so each
# op runs, with and without its optional argument.

my $c = Colouring::In::XS->new('#336699');
my $h = Colouring::In::XS->new('rgba(255,255,255,0.5)');

is($c->fade('50%')->toRGBA, 'rgba(50,101,153,0.5)', 'fade');

is($c->saturate('20%')->toHEX(1), '#1e65ad', 'saturate');
is($c->saturate('20%', 'relative')->toHEX(1), '#2865a3', 'saturate relative');
is($c->saturate('20%', undef)->toHEX(1), '#1e65ad', 'saturate with an undefined mode is absolute');
is($c->saturate('20%', 'exists')->toHEX(1), '#1e65ad', 'as is any other mode');

is($c->desaturate('20%')->toHEX(1), '#476584', 'desaturate');
is($c->desaturate('20%', 'relative')->toHEX(1), '#3d658e', 'desaturate relative');
is($c->desaturate('20%', undef)->toHEX(1), '#476584', 'desaturate with an undefined mode is absolute');
is($c->desaturate('20%', 'exists')->toHEX(1), '#476584', 'as is any other mode');

is($c->greyscale->toHEX(1), '#996633', 'greyscale');

is($c->lighten('10%', undef)->toHEX(1), '#3f7fbf', 'lighten with an undefined mode');
is($c->lighten('10%', 'relative')->toHEX(1), '#3f7fbf', 'lighten relative');
is($c->darken('10%', undef)->toHEX(1), '#264c72', 'darken with an undefined mode');
is($c->darken('10%', 'relative')->toHEX(1), '#2d5b89', 'darken relative');
is($h->fadeout('20%', undef)->toRGBA, 'rgba(255,255,255,0.3)', 'fadeout with an undefined mode');
is($h->fadeout('20%', 'relative')->toRGBA, 'rgba(255,255,255,0.4)', 'fadeout relative');
is($h->fadein('20%', undef)->toRGBA, 'rgba(255,255,255,0.7)', 'fadein with an undefined mode');
is($h->fadein('20%', 'relative')->toRGBA, 'rgba(255,255,255,0.6)', 'fadein relative');

is($c->mix('#fff')->toHEX(1), '#99b2cc', 'mix at the default weight');
is($c->mix('#fff', 30)->toHEX(1), '#c1d1e0', 'mix at a weight');
is($c->mix('#fff', 0)->toHEX(1), '#99b2cc', 'a weight of zero is the default');
is($c->mix('#fff', undef)->toHEX(1), '#99b2cc', 'an undefined weight is the default');

is($c->tint->toHEX(1), '#99b2cc', 'tint at the default weight');
is($c->tint(30)->toHEX(1), '#7093b7', 'tint at a weight');
is($c->tint(0)->toHEX(1), '#99b2cc', 'tint at a weight of zero');
is($c->tint(undef)->toHEX(1), '#99b2cc', 'tint at an undefined weight');

is($c->shade->toHEX(1), '#19334c', 'shade at the default weight');
is($c->shade(30)->toHEX(1), '#23476b', 'shade at a weight');
is($c->shade(0)->toHEX(1), '#19334c', 'shade at a weight of zero');
is($c->shade(undef)->toHEX(1), '#19334c', 'shade at an undefined weight');

is($h->toRGB, 'rgba(255,255,255,0.5)', 'toRGB keeps an alpha below one');
is($c->toRGB, 'rgb(51,102,153)', 'and drops an alpha of one');

done_testing;
