use ExtUtils::MakeMaker;
use strict;

print << '.';

Note:   To use this module, a few command line utlities are required.
        They are provided by the following debian packages, which you
        will need to install:

            libc6-dev:  /usr/bin/gencat
            dpkg:       /usr/bin/dpkg
            debhelper:  /usr/bin/dh_perl
            gcc:        /usr/bin/gcc
            dpkg-dev:   /usr/bin/dpkg-buildpackage
            fakeroot:   /usr/bin/fakeroot
            findutils:  /usr/bin/find, /usr/bin/xargs

        To use the (optional) automatic creation of Sources.gz and 
        Packages.gz files, to use your locally created .debs as an 
        apt repository you need the following programs:
            
            apt-utils:  /usr/bin/apt-ftparchive

.

WriteMakefile (
    NAME            => 'CPANPLUS::Dist::Deb',
    VERSION_FROM    => 'lib/CPANPLUS/Dist/Deb.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 
                        'Test::More'                => 0, 
                        'CPANPLUS'                  => '0.81', # dev version
                        'CPANPLUS::Dist::Build'     => '0.03',
                        'Locale::Maketext::Simple'  => 0,
                        'Params::Check'             => '0.23',
                        'Object::Accessor'          => '0.02',
                        'IPC::Cmd'                  => '0.23',
                        'Module::Load::Conditional' => '0.06',
                        'Module::Pluggable'         => '2.4',
                        'YAML'                      => 0,
                        'Package::Constants'        => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'CPANPLUS plugin to create debian packages on the fly'
);     
