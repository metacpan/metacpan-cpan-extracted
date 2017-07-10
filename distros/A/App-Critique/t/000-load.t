#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('App::Critique');

    use_ok('App::Critique::Session');
    use_ok('App::Critique::Session::File');

    use_ok('App::Critique::Command');
    use_ok('App::Critique::Command::init');
    use_ok('App::Critique::Command::clean');
    use_ok('App::Critique::Command::collect');
    use_ok('App::Critique::Command::status');
    use_ok('App::Critique::Command::remove');
    use_ok('App::Critique::Command::process');

    use_ok('App::Critique::Plugin::UI');
}

done_testing;

