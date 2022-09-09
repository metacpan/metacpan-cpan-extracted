#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'Test::Simple'          => 1,    # libtest-simple-perl
    };

my $prereq_pm = {
        'Class::Singleton'      => 1.40, # libclass-singleton-perl
        'Config::General'       => 2.00, # libconfig-general-perl
        'DBI'                   => 1.63, # libdbi-perl
        'ExtUtils::MakeMaker'   => 6.60,
        'File::Copy'            => 2.00,
        'File::Copy::Recursive' => 0.38, # libfile-copy-recursive-perl
        'File::Find'            => 0,
        'File::Path'            => 2.00,
        'File::Spec'            => 0.82,
        'File::Temp'            => 0,
        'IO'                    => 0,    # libio-all-perl
        'IO::String'            => 1.08, # libio-string-perl
        'IPC::Open3'            => 1.00,
        'JSON'                  => 2.90, # libjson-perl libjson-xs-perl
        'List::Util'            => 1.45, # libscalar-list-utils-perl
        'MIME::Base64'          => 3.00, # libemail-mime-encodings-perl
        'MIME::Lite'            => 3.00, # libmime-lite-perl
        'Net::FTP'              => 2.60,
        'Perl::OSType'          => 1.00,
        'Symbol'                => 1.05,
        'Sys::Syslog'           => 0,
        'Term::ANSIColor'       => 4.03,
        'Text::SimpleTable'     => 2.00, # libtext-simpletable-perl
        'Time::HiRes'           => 1.97,
        'Time::Local'           => 1.20,
        'Try::Tiny'             => 0.27, # libtry-tiny-perl
        'URI'                   => 1.60, # liburi-perl
        'XML::Simple'           => 2.22, # libxml-simple-perl
        'XSLoader'              => 0.01,
        'YAML'                  => 0.73, # libyaml-perl
        'YAML::XS'              => 0.40, # libyaml-libyaml-perl
    };

my $exefiles = [qw(
        bin/ctklib
    )];

WriteMakefile(
    'NAME'                  => 'CTK',
    'DISTNAME'              => 'CTKlib',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/CTK.pm',
    'XS_VERSION'            => '1.01',
    'ABSTRACT'              => 'CTK ToolKit library (CTKlib)',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'               => 'perl',
    'META_MERGE' => {
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'https://www.serzik.com',
            repository      => 'https://abalama@git.code.sf.net/p/ctklib/code',
            license         => 'https://dev.perl.org/licenses',
        },
    },
    clean => {
        FILES => '*.log *.tmp src/*.tmp src/src src/dst src/dst2',
    },
);
