#!/usr/bin/perl

use ExtUtils::MakeMaker;
use strict;
use warnings;

require 5.008002;

my %deps = (
    'Test::More'   => 0,
    'Data::Dumper' => 0,
    'Perl::Tidy'   => 0,
);

my %resources = (
    homepage    => 'http://jmcnamara.github.com/data-dumper-perltidy/',
    repository  => 'http://github.com/jmcnamara/data-dumper-perltidy',
    bugtracker  => 'http://github.com/jmcnamara/data-dumper-perltidy/issues',
);

my %params = (
    NAME          => 'Data::Dumper::Perltidy',
    AUTHOR        => 'John McNamara <jmcnamara@cpan.org>',
    VERSION_FROM  => 'lib/Data/Dumper/Perltidy.pm',
    ABSTRACT_FROM => 'lib/Data/Dumper/Perltidy.pm',
    PL_FILES      => {},
    PREREQ_PM     => \%deps,
    dist          => { COMPRESS => 'gzip --best', SUFFIX => 'gz', },
    clean         => { FILES => 'Data-Dumper-Perltidy-*' },
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $params{META_MERGE} = { resources => \%resources };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.30_01' ) {
    $params{LICENSE} = 'perl';
}

WriteMakefile(%params);
