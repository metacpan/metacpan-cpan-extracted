#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::RandomResult;

use Color::RGB::Util qw(
                           assign_rgb_color
                           assign_rgb_dark_color
                           assign_rgb_light_color
                           hsl2hsv
                           hsl2rgb
                           hsv2hsl
                           hsv2rgb
                           int2rgb
                           mix_2_rgb_colors
                           mix_rgb_colors
                           rand_rgb_color
                           rand_rgb_colors
                           reverse_rgb_color
                           rgb2grayscale
                           rgb2hsl
                           rgb2hsv
                           rgb2int
                           rgb2sepia
                           rgb_diff
                           rgb_distance
                           rgb_is_dark
                           rgb_is_light
                           rgb_luminance
                           tint_rgb_color
                   );

subtest _wrap_h => sub {
    is(Color::RGB::Util::_wrap_h(0), 0);
    is(Color::RGB::Util::_wrap_h(1), 1);
    is(Color::RGB::Util::_wrap_h(-10), 350);
    is(Color::RGB::Util::_wrap_h(360), 360);
    is(Color::RGB::Util::_wrap_h(370), 10);
    is(Color::RGB::Util::_wrap_h(730), 10);
    is(Color::RGB::Util::_wrap_h(-360), 0);
    is(Color::RGB::Util::_wrap_h(-370), 350);
};

subtest assign_rgb_color => sub {
    is(assign_rgb_color(""),    "da5509");
    is(assign_rgb_color("foo"), "0b5d33");
    is(assign_rgb_color("baz"), "bb40a2");
};

subtest assign_rgb_dark_color => sub {
    is(assign_rgb_dark_color(""),    "da5509");
    is(assign_rgb_dark_color("foo"), "0b5d33");
    is(assign_rgb_dark_color("baz"), "5d2051");
};

subtest assign_rgb_light_color => sub {
    is(assign_rgb_light_color(""),    "ecaa84");
    is(assign_rgb_light_color("foo"), "85ae99");
    is(assign_rgb_light_color("baz"), "bb40a2");
};

subtest hsl2hsv => sub {
    is(hsl2hsv("0 1 0.5"), "0 1 1"); # red ff0000
    is(hsl2hsv("120 1 0.5"), "120 1 1"); # green 00ff00
    is(hsl2hsv("120 1 0.751"), "120 0.498 1"); # light green 80ff80
    is(hsl2hsv("240 1 0.251"), "240 1 0.502"); # dark blue 000080

    # test wrapping of h
    is(hsl2hsv("720 1 0.5"), "0 1 1"); # red ff0000
};

subtest hsv2hsl => sub {
    is(hsv2hsl("0 1 1"), "0 1 0.5"); # red ff0000
    is(hsv2hsl("120 1 1"), "120 1 0.5"); # green 00ff00
    is(hsv2hsl("120 0.498 1"), "120 1 0.751"); # light green 80ff80
    is(hsv2hsl("240 1 0.502"), "240 1 0.251"); # dark blue 000080

    # test wrapping of h
    is(hsv2hsl("720 1 1"), "0 1 0.5"); # red ff0000
};

subtest hsv2rgb => sub {
    is(hsv2rgb("0 1 1"), "ff0000");
    is(hsv2rgb("120 0.498 1"), "80ff80");
    is(hsv2rgb("240 1 0.502"), "000080");

    # test wrapping of h
    is(hsv2rgb("720 1 1"), "ff0000");
};

subtest hsl2rgb => sub {
    is(hsl2rgb("0 1 0.5"), "ff0000");
    is(hsl2rgb("120 1 0.751"), "80ff80");
    is(hsl2rgb("240 1 0.251"), "000080");

    # test wrapping of h
    is(hsl2rgb("720 1 0.5"), "ff0000");
};

subtest int2rgb => sub {
    is(int2rgb(0x000000), "000000");
    is(int2rgb(0xffffff), "ffffff");
    is(int2rgb(0xfa0000), "fa0000");
    is(int2rgb(0x00af00), "00af00");
    is(int2rgb(0x0000fa), "0000fa");
};

subtest mix_2_rgb_colors => sub {
    dies_ok { mix_2_rgb_colors('0', 'ffffff') };
    is(mix_2_rgb_colors('#ff8800', '#0033cc'), '7f5d66');
    is(mix_2_rgb_colors('ff8800', '0033cc', 0), 'ff8800');
    is(mix_2_rgb_colors('FF8800', '0033CC', 1), '0033cc');
    is(mix_2_rgb_colors('0033CC', 'FF8800', 0.75), 'bf7233');
    is(mix_2_rgb_colors('0033CC', 'FF8800', 0.25), '3f4899');
};

subtest mix_rgb_colors => sub {
    dies_ok { mix_rgb_colors('0', 1) } 'invalid rgb -> dies';
    dies_ok { mix_rgb_colors('000000', 0) } 'total weight zero #1 -> dies';
    dies_ok { mix_rgb_colors('000000', 0) } 'total weight zero #2 -> dies';
    is(mix_rgb_colors('#ff8800', 1, '#0033cc', 1), '7f5d66');
    is(mix_rgb_colors('#ff8800', 2, '#0033cc', 1), 'aa6b44');
    is(mix_rgb_colors('#ff8800', 1, '#0033cc', 2, '000000', 3), '2a2744');
};

subtest rand_rgb_color => sub {
    results_look_random { rgb2int(rand_rgb_color()) } between=>[0, 0xffffff];
};

subtest rand_rgb_colors => sub {
    my @vals = rand_rgb_colors(5);
    is(scalar(@vals), 5);

    results_look_random { rgb2int(rand_rgb_colors()) } between=>[0, 0xffffff];
};

subtest reverse_rgb_color => sub {
    is(reverse_rgb_color('0033CC'), 'ffcc33');
};

subtest rgb2grayscale => sub {
    is(rgb2grayscale('0033CC'), '555555');
    is(rgb2grayscale('0033CC', 'weighted_average'), '353535');
    dies_ok { rgb2grayscale('0033cc', 'foo') } 'unknown algo -> dies';
};

subtest rgb2hsl => sub {
    is(rgb2hsl("ff0000"), "0 1 0.5");
    is(rgb2hsl("80ff80"), "120 1 0.751");
    is(rgb2hsl("000080"), "240 1 0.251");
};

subtest rgb2hsv => sub {
    is(rgb2hsv("ff0000"), "0 1 1");
    is(rgb2hsv("80ff80"), "120 0.498 1");
    is(rgb2hsv("000080"), "240 1 0.502");
};

subtest rgb2int => sub {
    is(rgb2int('000000'), 0);
    is(rgb2int('ffffff'), 0xffffff);
    is(rgb2int('fa0000'), 0xfa0000);
    is(rgb2int('00af00'), 0x00af00);
    is(rgb2int('0000fa'), 0x0000fa);
};

subtest rgb2sepia => sub {
    is(rgb2sepia('0033CC'), '4d4535');
};

subtest rgb_diff => sub {
    is(int(rgb_diff("000000","000000", "approx1")),   0);
    is(int(rgb_diff("00ff00","0000ff", "approx1")), 674);
    is(int(rgb_diff("ff0000","000000", "approx1")), 403);
    dies_ok { rgb_diff("000000","000000", "foo") } 'unknown algo -> dies';
};

subtest rgb_distance => sub {
    is(rgb_distance('000000', '000000'), 0);
    is(rgb_distance('01f000', '04f400'), 5);
    is(rgb_distance('ffff00', 'ffffff'), 255);
};

subtest rgb_is_dark => sub {
    ok( rgb_is_dark('000000'));
    ok( rgb_is_dark('404040'));
    ok(!rgb_is_dark('a0a0a0'));
    ok(!rgb_is_dark('ffffff'));
};

subtest rgb_is_light => sub {
    ok(!rgb_is_light('000000'));
    ok(!rgb_is_light('404040'));
    ok( rgb_is_light('a0a0a0'));
    ok( rgb_is_light('ffffff'));
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
