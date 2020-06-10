#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use ColorTheme::Test::Static;
use Role::Tiny;

Role::Tiny->apply_roles_to_package(
    'ColorTheme::Test::Static', 'ColorThemeRole::ANSI');

{
    delete local $ENV{NO_COLOR};
    local $ENV{COLOR} = 1;
    local $ENV{COLOR_DEPTH} = 16;

    my $ct = ColorTheme::Test::Static->new;
    is($ct->get_item_color_as_ansi("color1"), "\e[31;1m");
}

DONE_TESTING:
done_testing;
