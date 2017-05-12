#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;

BEGIN {
    use_ok('CPAN::Testers::WWW::Admin');
    use_ok('Labyrinth::Plugin::CPAN');
    use_ok('Labyrinth::Plugin::CPAN::Admin');
    use_ok('Labyrinth::Plugin::CPAN::Author');
    use_ok('Labyrinth::Plugin::CPAN::Tester');
}
