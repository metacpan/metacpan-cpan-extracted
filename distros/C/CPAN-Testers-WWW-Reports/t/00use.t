#!/usr/bin/perl -w
use strict;

use Test::More tests => 9;

BEGIN {
    use_ok('CPAN::Testers::WWW::Reports');
    use_ok('Labyrinth::Plugin::CPAN');
    use_ok('Labyrinth::Plugin::CPAN::Authors');
    use_ok('Labyrinth::Plugin::CPAN::Builder');
    use_ok('Labyrinth::Plugin::CPAN::Distros');
    use_ok('Labyrinth::Plugin::CPAN::Monitor');
    use_ok('Labyrinth::Plugin::CPAN::Release');
    use_ok('Labyrinth::Plugin::CPAN::Report');
    use_ok('Labyrinth::Plugin::Metabase::Parser');
}
