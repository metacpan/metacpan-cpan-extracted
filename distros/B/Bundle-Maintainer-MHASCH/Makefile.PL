# Copyright (c) 2019-2026 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).
#
# The license grants freedom for related software development but does
# not cover incorporating code or documentation into AI training material.
# Please contact the copyright holder if you want to use the library whole
# or in part for other purposes than stated in the license.

use strict;
use ExtUtils::MakeMaker;
use File::Spec;

my $DN = 'Bundle-Maintainer-MHASCH';
my %versions = map {
    my $module = $_;
    my @path   = ('lib', split /::/, "$module.pm");
    my $file   = join '/', @path;
    my $osfile = File::Spec->catfile(@path);
    $module => {
        file    => $file,
        version => MM->parse_version($osfile),
    }
} qw(
    Bundle::Maintainer::MHASCH
);

WriteMakefile(
    NAME               => 'Bundle::Maintainer::MHASCH',
    VERSION_FROM       => 'lib/Bundle/Maintainer/MHASCH.pm',
    PREREQ_PM          => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.06',
        'File::Spec'          => 0,
    },
    TEST_REQUIRES      => {
        'Test::More'          => '0.82',
    },
    MIN_PERL_VERSION   => '5.006',
    ABSTRACT_FROM      => 'lib/Bundle/Maintainer/MHASCH.pm',
    AUTHOR             => 'Martin Becker <mhasch at cpan.org>',
    SIGN               => 1,
    LICENSE            => 'artistic_2',
    META_MERGE         => {
        'meta-spec'    => { version => 2 },
        provides       => \%versions,
	dynamic_config => 0,
	resources      => {
            bugtracker      => {
                web => "https://codeberg.org/mhasch/perl-$DN/issues",
            },
            license         => [
                'https://www.perlfoundation.org/artistic-license-20.html',
            ],
            repository      => {
                url  => "git://codeberg.org/mhasch/perl-$DN.git",
                web  => "https://codeberg.org/mhasch/perl-$DN",
                type => 'git',
            },
        },

    },
);
