# Copyright (c) 2015-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

use strict;
use ExtUtils::MakeMaker;

my $DN = 'Bundle-ExCore';

WriteMakefile(
    NAME              => 'Bundle::ExCore',
    VERSION_FROM      => 'lib/Bundle/ExCore.pm',
    PREREQ_PM         => {},
    BUILD_REQUIRES    => {
            'ExtUtils::MakeMaker' => '6.56',
            'Test::More'          => '0.75',
        },
    MIN_PERL_VERSION  => '5.006',
    ABSTRACT_FROM     => 'lib/Bundle/ExCore.pm',
    AUTHOR            => 'Martin Becker <mhasch@cpan.org>',
    SIGN              => 1,
    LICENSE           => 'artistic_2',
    META_MERGE        => {
        'meta-spec'     => { version => 2 },
        dynamic_config  => 0,
        resources       => {
            bugtracker      => {
                web => "https://github.com/mhasch/perl-$DN/issues",
            },
            license         => [
                'https://www.perlfoundation.org/artistic-license-20.html',
            ],
            repository      => {
                url  => "git://github.com/mhasch/perl-$DN.git",
                web  => "https://github.com/mhasch/perl-$DN",
                type => 'git',
            },
        },
    },
);
