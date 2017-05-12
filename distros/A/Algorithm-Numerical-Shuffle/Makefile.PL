#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 => 'Algorithm::Numerical::Shuffle',
    VERSION_FROM         => 'lib/Algorithm/Numerical/Shuffle.pm',
    ABSTRACT_FROM        => 'lib/Algorithm/Numerical/Shuffle.pm',
    PREREQ_PM            => {'strict'    =>  0,
                             'warnings'  =>  0,
                             'Exporter'  =>  0,},
    MIN_PERL_VERSION     =>  5.006,
    AUTHOR               => 'Abigail <cpan@abigail.be>',
    LICENSE              => 'mit',
    META_MERGE           => {
        build_requires   => {'Test::More' => 0,
                             'strict'     => 0,
                             'warnings'   => 0,
                            },
        resources        => {
            repository   => 'git://github.com/Abigail/regexp--charclasses.git',
        },
        keywords         => ['algorithm', 'shuffle', 'shuffling'],
    },
);

my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
