#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
use strict;

# Ebook::Epub needs Moose which required perl 5.8.3.
require 5.008003;

my %deps = (
        'Pod::Simple'  => 3.15,
        'EBook::EPUB'  => 0.5,
        'Getopt::Long' => 0,
        'Pod::Usage'   => 0,
        'File::Temp'   => 0,
);

my %resources = (
    homepage    => 'http://jmcnamara.github.com/app-pod2epub/',
    repository  => 'http://github.com/jmcnamara/app-pod2epub',
    bugtracker  => 'http://github.com/jmcnamara/app-pod2epub/issues',
);

my %params = (
    'AUTHOR'        => 'John McNamara (jmcnamara@cpan.org)',
    'ABSTRACT_FROM' => 'lib/App/Pod2Epub.pm',
    'NAME'          => 'App::Pod2Epub',
    'VERSION_FROM'  => 'lib/App/Pod2Epub.pm',
    'NEEDS_LINKING' => 0,
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'EXE_FILES'     => ['bin/pod2epub'],
    'LICENSE'       => 'perl',
    'PREREQ_PM'     => \%deps,
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $params{META_MERGE} = { resources => \%resources };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.30_01' ) {
    $params{LICENSE} = 'perl';
}

WriteMakefile(%params);

