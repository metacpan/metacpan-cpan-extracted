#
# This file is part of CPANPLUS::Dist::Fedora.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use lib './inc';

use Test::Run::Builder;

my $builder = Test::Run::Builder->new (
    module_name         => 'CPANPLUS::Dist::Fedora',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    license             => 'perl',
    dist_version_from   => 'lib/CPANPLUS/Dist/Fedora.pm',
    add_to_cleanup => [
        'CPANPLUS-Dist-Fedora-*', 'MANIFEST.bak',
        map { ( '*/' x $_ ) . '*~' } 0..5 ],
    script_files   => [ ],
    configure_requires => {
        'Module::Build' => '0.36',
    },
    test_requires => {
        'Test::More'           => 0,
    },
    requires       => {
        'CPANPLUS'             => 0,
        'CPANPLUS::Dist::Base' => 0,
        'CPANPLUS::Error'      => 0,
        'File::Basename'       => 0,
        'File::Copy'           => 0,
        'IPC::Cmd'             => 0,
        'Pod::POM'             => 0,
        'Pod::POM::View::Text' => 0,
        'POSIX'                => 0,
        'Text::Wrap'           => 0,
        'Template'             => 0,
        'perl'                 => '5.008',
    },
    recommends     => {
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::TrailingSpace' => 0,
    },
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/cpanplus-dist-backends",
        },
        keywords =>
        [
            qw(
            RHEL
            centos
            cpan
            cpanplus
            fedora
            perl
            rhel
            rpm
            ),
        ],
    },
);

$builder->create_build_script();
