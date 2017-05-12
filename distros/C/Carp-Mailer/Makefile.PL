#!/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Carp::Mailer',
    VERSION_FROM => 'lib/Carp/Mailer.pm',
    PREREQ_FATAL => 1,
    PREREQ_PRINT => 1,
    PREREQ_PM => {
        Text::Template => 0,
        Mail::Mailer => 0,
    },

);
