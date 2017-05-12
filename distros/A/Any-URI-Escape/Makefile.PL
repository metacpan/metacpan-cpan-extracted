#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Any::URI::Escape',
    VERSION_FROM  => 'lib/Any/URI/Escape.pm',
    PREREQ_PM     => { 'URI::Escape' => 0 },
    ABSTRACT_FROM => 'lib/Any/URI/Escape.pm',
    AUTHOR        => 'Fred Moyer <fred@redhotpenguin.com>',
);
