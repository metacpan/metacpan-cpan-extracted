#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'CSAF',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/CSAF.pm',
    ABSTRACT_FROM      => 'lib/CSAF.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => ['bin/csaf-validator', 'bin/csaf-rolie', 'bin/csaf-downloader', 'bin/csaf2html'],
    MIN_PERL_VERSION   => 5.010,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {
        'Cpanel::JSON::XS'      => '0',
        'Digest::SHA'           => '0',    # CORE
        'File::Basename'        => '0',    # CORE
        'File::Path'            => '0',    # CORE
        'File::Spec::Functions' => '0',    # CORE
        'GnuPG::Interface'      => '0',
        'LWP::UserAgent'        => '0',
        'JSON::Validator'       => '3.15',
        'List::MoreUtils'       => '0.423',
        'List::Util'            => '0',    # CORE
        'Log::Any'              => '0',
        'Moo'                   => '0',
        'Parallel::ForkManager' => '0',
        'Template'              => '0',
        'Tie::File'             => '0',    # CORE
        'Time::Piece'           => '0',    # CORE
        'URI::PackageURL'       => '0',
        'YAML::XS'              => '0',
        'CVSS'                  => '0',
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-CSAF/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-CSAF',
                web  => 'https://github.com/giterlizzi/perl-CSAF'
            }
        },
        x_purl => 'pkg:cpan/GDT/CSAF'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'CSAF-*'}
);
