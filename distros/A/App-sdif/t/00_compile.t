use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::sdif

    App::sdif::LabelStack

    App::cdif::Command
    App::cdif::Tmpfile

    App::sdif::colors
    App::sdif::osx_autocolor
);

done_testing;

