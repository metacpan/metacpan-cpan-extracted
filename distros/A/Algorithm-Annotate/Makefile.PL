#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Chia-liang Kao (clkao@clkao.org)',
    ABSTRACT            => 'Represent a series of changes in annotation list',
    NAME                => 'Algorithm::Annotate',
    VERSION_FROM        => 'Annotate.pm',
    DISTNAME            => 'Algorithm-Annotate',
    PREREQ_PM           => {
        'Algorithm::Diff'   => '1.15',
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);

