#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Apache2::TaintRequest',
    VERSION_FROM => 'lib/Apache2/TaintRequest.pm',
    PREREQ_PM    => {
        'HTML::Entities' => 0,
        'Taint'          => 0
    },
    ABSTRACT_FROM => 'lib/Apache2/TaintRequest.pm',
    AUTHOR        => 'Fred Moyer <fred@redhotpenguin.com>'
);
