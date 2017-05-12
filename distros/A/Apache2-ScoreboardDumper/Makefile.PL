#!/usr/bin/perl

use strict;
use warnings;

use ModPerl::MM ();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

Apache::TestMM::filter_args();

Apache::TestRunPerl->generate_script();

ModPerl::MM::WriteMakefile(
    NAME         => 'Apache2::ScoreboardDumper',
    VERSION_FROM => 'lib/Apache2/ScoreboardDumper.pm',
    PREREQ_PM    => {
        'mod_perl2'          => '2',
        'Test::More'         => '0.47',
        'Apache::Scoreboard' => 0,
    },
);
