#!perl

use 5.010;
use strict;
use warnings;

{
    package myclass;
    use Moo;
    with 'Color::Theme::Role::ANSI';
}

package main;

my $o = myclass->new;

use Test::More 0.98;

subtest "theme_color_to_ansi (16 color)" => sub {
    local $o->{color_depth} = 16;
    is($o->theme_color_to_ansi("ff0000"), "\e[31;1m");
    is($o->theme_color_to_ansi({fg=>"ff0000", bg=>"00ff00"}), "\e[31;1m\e[42m");
};

# XXX theme_color_to_ansi (256 color)
# XXX theme_color_to_ansi (24bit)
# XXX theme_color_as_ansi

DONE_TESTING:
done_testing;
