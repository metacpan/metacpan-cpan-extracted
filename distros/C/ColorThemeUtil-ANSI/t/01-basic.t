#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use ColorThemeUtil::ANSI qw(
                               item_color_to_ansi
                       );

{
    delete local $ENV{NO_COLOR};
    local $ENV{COLOR} = 1;
    local $ENV{COLOR_DEPTH} = 16;

    is(item_color_to_ansi("ff0000"), "\e[31;1m");
}

DONE_TESTING:
done_testing;
