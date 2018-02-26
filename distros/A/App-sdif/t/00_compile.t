use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::sdif

    App::sdif::LabelStack

    App::cdif::Command
    App::cdif::Tmpfile

    App::sdif::debug
    App::sdif::default
    App::sdif::colors
    App::sdif::autocolor
    App::sdif::autocolor::Apple_Terminal

    App::cdif::debug
    App::cdif::default
    App::cdif::colors
);

done_testing;

