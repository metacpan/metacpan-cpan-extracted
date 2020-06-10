#!perl

use 5.010001;
use strict;
use warnings;

use Test::More 0.98;
use Color::ANSI::Util qw(
                           ansi16_to_rgb
                           rgb_to_ansi16
                           rgb_to_ansi16_fg_code
                           ansi16fg
                           rgb_to_ansi16_bg_code
                           ansi16bg

                           ansi256_to_rgb
                           rgb_to_ansi256
                           rgb_to_ansi256_fg_code
                           ansi256fg
                           rgb_to_ansi256_bg_code
                           ansi256bg

                           rgb_to_ansi24b_fg_code
                           ansi24bfg
                           rgb_to_ansi24b_bg_code
                           ansi24bbg

                           rgb_to_ansi_fg_code
                           ansifg
                           rgb_to_ansi_bg_code
                           ansibg

                           ansi_reset
                    );

subtest "16 colors" => sub {
    is(ansi16_to_rgb(1), "800000");
    is(ansi16_to_rgb(9), "ff0000");
    is(ansi16_to_rgb("red"), "800000");
    is(ansi16_to_rgb("bold red"), "ff0000");
    is(rgb_to_ansi16("7e0000"), 1);
    is(rgb_to_ansi16("ee1111"), 9);
    is(rgb_to_ansi16_fg_code("7e0000"), "\e[31m");
    is(ansi16fg             ("fe0000"), "\e[31;1m");
    is(rgb_to_ansi16_bg_code("7e0000"), "\e[41m");
    is(ansi16bg             ("fe0000"), "\e[41m");
};

subtest "256 colors" => sub {
    is(ansi256_to_rgb(156), "afff87");
    is(rgb_to_ansi256("ff0000"), 9);
    is(rgb_to_ansi256("afff80"), 156);
    is(rgb_to_ansi256("afdf80"), 107);
    is(rgb_to_ansi256_fg_code("7e0000"), "\e[38;5;1m");
    is(ansi256fg             ("fe0000"), "\e[38;5;9m");
    is(rgb_to_ansi256_bg_code("7e0000"), "\e[48;5;1m");
    is(ansi256bg             ("fe0000"), "\e[48;5;9m");
};

subtest "24bit colors" => sub {
    is(rgb_to_ansi24b_fg_code("7e0102"), "\e[38;2;126;1;2m");
    is(ansi24bfg             ("fe0102"), "\e[38;2;254;1;2m");
    is(rgb_to_ansi24b_bg_code("7e0102"), "\e[48;2;126;1;2m");
    is(ansi24bbg             ("fe0102"), "\e[48;2;254;1;2m");
};

subtest "color detection (ENV)" => sub {
    local $Color::ANSI::Util::_use_termdetsw = 0;
    local $Color::ANSI::Util::_color_depth;
    local $ENV{COLOR_DEPTH};

    $Color::ANSI::Util::_color_depth = undef;
    {
        local $ENV{COLOR} = 0;
        is(ansifg("7e0102"), "");
    }

    $Color::ANSI::Util::_color_depth = undef;
    $ENV{COLOR_DEPTH} = 0;
    is(ansifg("7e0102"), "");
    is(ansi_reset(1), "");
    is(ansi_reset(), "\e[0m");

    $Color::ANSI::Util::_color_depth = undef;
    $ENV{COLOR_DEPTH} = 16;
    is(ansifg("7e0102"), "\e[31m");

    $Color::ANSI::Util::_color_depth = undef;
    $ENV{COLOR_DEPTH} = 256;
    is(ansifg("7e0102"), "\e[38;5;1m");

    $Color::ANSI::Util::_color_depth = undef;
    $ENV{COLOR_DEPTH} = 2**24;
    is(ansifg("7e0102"), "\e[38;2;126;1;2m");
};

subtest "color detection (simple heuristic)" => sub {
    local $Color::ANSI::Util::_use_termdetsw = 0;
    local $Color::ANSI::Util::_color_depth;
    local $ENV{COLOR_DEPTH};
    local $ENV{KONSOLE_DBUS_SERVICE};

    $Color::ANSI::Util::_color_depth = undef;
    is(ansifg("7e0102"), "\e[31m");

    $Color::ANSI::Util::_color_depth = undef;
    $ENV{KONSOLE_DBUS_SERVICE} = 1;
    is(ansifg("7e0102"), "\e[38;2;126;1;2m");
};

DONE_TESTING:
done_testing();
