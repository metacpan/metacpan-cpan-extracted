#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Data::Password::Filter',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Data/Password/Filter.pm',
    ABSTRACT_FROM      => 'lib/Data/Password/Filter.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM     => {
        'autodie'          => '2.26',
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
        'File::Share'      => '0.25',
        'Type::Tiny'       => '1.000005',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Password-Filter-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Data::Password::Filter'         => { file => 'lib/Data/Password/Filter.pm'       , version => '0.17' },
            'Data::Password::Filter::Params' => { file => 'lib/Data/Password/Filter/Params.pm', version => '0.17' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Data-Password-Filter.git',
                web  => 'https://github.com/manwar/Data-Password-Filter',
            },
        }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';
