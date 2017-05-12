#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Apache2::ScoreboardIsFull',
    VERSION_FROM  => 'lib/Apache2/ScoreboardIsFull.pm',
    PREREQ_PM     => { 'Apache::Scoreboard' => 0, 'mod_perl2' => 0 },
    ABSTRACT_FROM => 'lib/Apache2/ScoreboardIsFull.pm',
    AUTHOR        => 'Fred Moyer <fredmoyer@redhotpenguin.com>'
);
