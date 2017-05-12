#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 =>  'Date::Maya',
    VERSION_FROM         =>  'lib/Date/Maya.pm',
    ABSTRACT             =>  'Translate between Julian days and Maya days.',
    PREREQ_PM            => {
        'strict'                =>  0,
        'warnings'              =>  0,
        'Exporter'              =>  0,
        'constant'              =>  0,
        'integer'               =>  0,
    },
    MIN_PERL_VERSION     =>   5.006,
    AUTHOR               =>  'Abigail <date-maya@abigail.be>',
    LICENSE              =>  'mit',
    META_MERGE           => {
        test_requires    => {
            'strict'             => 0,
            'warnings'           => 0,
        },
        resources        => {
            repository   =>  'git://github.com/Abigail/date--maya.git',
        },
        keywords         => [qw [dates date Maya calendar]],
    },
);

$args {META_MERGE} {build_requires} ||= {
    'ExtUtils::MakeMaker' =>  0,
    %{$args {META_MERGE} {test_requires}}
};

$args {META_MERGE} {configure_requires} ||=
    $args {META_MERGE} {build_requires};


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
