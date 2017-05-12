#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 => 'Acme::Time::Baby',
    VERSION_FROM         => 'lib/Acme/Time/Baby.pm',
    ABSTRACT_FROM        => 'lib/Acme/Time/Baby.pm',
    PREREQ_PM            => {
        'strict'         =>  0,
        'warnings'       =>  0,
        'vars'           =>  0,
    },
    MIN_PERL_VERSION     =>  5.006,
    AUTHOR               => 'Abigail <acme-time-baby@abigail.be>',
    LICENSE              => 'mit',
    META_MERGE           => {
        test_requires    => {
            'Test'       => 0,
            'Test::More' => 0,
        },
        resources        => {
            repository   => 'git://github.com/Abigail/acme--time--baby.git',
        },
        keywords         => [qw [Time Clock]],
    },
);

my %filter = (
    MIN_PERL_VERSION     => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
    LICENSE              => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
