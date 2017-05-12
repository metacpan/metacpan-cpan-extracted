#!perl

use 5.010;
use strict;
use warnings;

use Color::RGB::Util qw(
                           mix_2_rgb_colors
                           rand_rgb_color
                           rgb2grayscale
                           rgb2sepia
                           reverse_rgb_color
                           rgb_luminance
                           tint_rgb_color
                   );
use Test::More 0.98;

subtest mix_2_rgb_colors => sub {
    is(mix_2_rgb_colors('#ff8800', '#0033cc'), '7f5d66');
    is(mix_2_rgb_colors('ff8800', '0033cc', 0), 'ff8800');
    is(mix_2_rgb_colors('FF8800', '0033CC', 1), '0033cc');
    is(mix_2_rgb_colors('0033CC', 'FF8800', 0.75), 'bf7233');
    is(mix_2_rgb_colors('0033CC', 'FF8800', 0.25), '3f4899');
};

subtest rand_rgb_color => sub {
    ok "currently not tested";
};

subtest rgb2grayscale => sub {
    is(rgb2grayscale('0033CC'), '555555');
};

subtest rgb2sepia => sub {
    is(rgb2sepia('0033CC'), '4d4535');
};

subtest reverse_rgb_color => sub {
    is(reverse_rgb_color('0033CC'), 'ffcc33');
};

subtest rgb_luminance => sub {
    ok(abs(0      - rgb_luminance('000000')) < 0.001);
    ok(abs(1      - rgb_luminance('ffffff')) < 0.001);
    ok(abs(0.6254 - rgb_luminance('d090aa')) < 0.001);
};

subtest tint_rgb_color => sub {
    is(tint_rgb_color('#ff8800', '#0033cc'), 'b36e3c');
    is(tint_rgb_color('ff8800', '0033cc', 0), 'ff8800');
    is(tint_rgb_color('FF8800', '0033CC', 1), '675579');
    is(tint_rgb_color('0033CC', 'FF8800', 0.75), '263fad');
    is(tint_rgb_color('0033CC', 'FF8800', 0.25), '0c37c1');
};

DONE_TESTING:
done_testing();
