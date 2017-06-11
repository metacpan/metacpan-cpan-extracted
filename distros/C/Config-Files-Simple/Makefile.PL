#!/usr/bin/env perl

use 5.6.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my (%params) = (
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    DISTNAME           => 'Config-Files-Simple',
    NAME               => 'Config::Files::Simple',
    MIN_PERL_VERSION   => 5.6.0,
    VERSION_FROM       => 'lib/Config/Files/Simple.pm',
    ABSTRACT_FROM      => 'lib/Config/Files/Simple.pm',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Carp'                    => 0,
        'Exporter'                => 0,
        'JSON::Parse'             => 0,
        'String::Any::Extensions' => 0.01.1,
        'Module::Load'            => 0,
        'Ref::Util'               => 0,
        'YAML'                    => 0,
    },
    TEST_REQUIRES => {
        'Test::More'      => 1.302031,
        'Hash::MD5'       => 0.08,
        'Path::Tiny'      => 0,
        'Test::Exception' => 0.43,
    },
    clean => { FILES    => 'blib/* Makefile Config-Files-Simple-*' },
    dist  => { COMPRESS => 'gzip', SUFFIX => 'gz' },

);

if ( ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ ) && ( $ExtUtils::MakeMaker::VERSION > 6.30 ) )
{
    $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $params{META_MERGE} = {
        'meta-spec' => { version => 2, },
        resources   => {
            bugtracker => { web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Files-Simple', },
            license    => 'http://dev.perl.org/licenses/',
            repository => {
                type => 'git',
                url  => 'https://github.com/rsavage/Config-Files-Simple.git',
                web  => 'https://github.com/mziescha/Config-Files-Simple',
            },
        },
    };
}

WriteMakefile(%params);
