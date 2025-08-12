#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App-CPAN-SBOM',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/App/CPAN/SBOM.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.016,
    PL_FILES           => {},
    EXE_FILES          => ['bin/cpan-sbom'],
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {
        'SBOM::CycloneDX'  => 0,
        'CPAN::Audit'      => 0,
        'MetaCPAN::Client' => 0,
        'URI::PackageURL'  => '2.22',
        'MIME::Base64'     => 0,
        'HTTP::Tiny'       => 0,
        'Cpanel::JSON::XS' => 0,
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-App-CPAN-SBOM/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-App-CPAN-SBOM',
                web  => 'https://github.com/giterlizzi/perl-App-CPAN-SBOM'
            },
        },
        x_purl => 'pkg:cpan/GDT/App-CPAN-SBOM'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'App-CPAN-SBOM-*'},
);
