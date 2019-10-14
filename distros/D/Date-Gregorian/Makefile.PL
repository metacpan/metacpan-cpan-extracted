# Copyright (c) 1999-2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $DN = 'Date-Gregorian';
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
    Date::Gregorian
    Date::Gregorian::Business
    Date::Gregorian::Exact
);

WriteMakefile(
    NAME               => 'Date::Gregorian',
    VERSION_FROM       => 'lib/Date/Gregorian.pm',
    ABSTRACT_FROM      => 'lib/Date/Gregorian.pm',
    AUTHOR             => 'Martin Becker <becker-cpan-mp (at) cozap.com>',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => '5.006',
    PREREQ_PM          => {
        'Carp' => '0',
    },
    SIGN               => 1,
    META_MERGE         => {
        'meta-spec'    => { version => 2 },
        provides       => \%versions,
        dynamic_config => 0,
        resources      => {
            bugtracker => {
                web => "https://rt.cpan.org/Public/Dist/Display.html?Name=$DN",
            },
            license => [
                'https://www.perlfoundation.org/artistic-license-20.html',
            ],
            repository => {
                url  => "git://github.com/mhasch/perl-$DN.git",
                web  => "https://github.com/mhasch/perl-$DN",
                type => 'git',
            },
        },
        prereqs => {
            runtime => {
                recommends   => {
                    'DateTime' => '0.1501',
                },
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'File::Spec'          => '0',
    },
);
