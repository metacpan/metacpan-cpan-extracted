#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

use constant MSWIN => $^O =~ /mswin/i ? 1 : 0;

my $build_requires = {
        'Test::Simple'          => 1,    # libtest-simple-perl
    };

my $prereq_pm = {
        'Class::C3::Adopt::NEXT'=> 0.13, # libclass-c3-adopt-next-perl
        'Class::Singleton'      => 1.40,
        'Config::General'       => 2.00, # libconfig-general-perl
        'DBI'                   => 1.63, # libdbi-perl
        'ExtUtils::MakeMaker'   => 6.60,
        'File::Copy'            => 2.00,
        'File::Copy::Recursive' => 0.38, # libfile-copy-recursive-perl
        'File::Find'            => 0,
        'File::Path'            => 2.00,
        'File::Pid'             => 1.00,
        'File::Spec'            => 0.82,
        'File::Temp'            => 0,
        'IO'                    => 0,
        'IO::String'            => 1.08, # libio-all-perl
        'IPC::Open3'            => 1.00,
        'JSON'                  => 2.90, # libjson-perl libjson-xs-perl
        'List::Util'            => 1.45, # libscalar-list-utils-perl
        'MIME::Base64'          => 3.00, # libemail-mime-encodings-perl
        'MIME::Lite'            => 3.00, # libmime-lite-perl
        'MRO::Compat'           => 0.12, # libmro-compat-perl
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
$prereq_pm->{'Sys::SigAction'}  =  0.20 unless MSWIN; # libsys-sigaction-perl

my $exefiles = [qw(
        bin/ctklib
    )];

WriteMakefile(
    'NAME'                  => 'CTK',
    'DISTNAME'              => 'CTKlib',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/CTK.pm',
    'XS_VERSION'            => '1.00',
    'ABSTRACT'              => 'Command-line ToolKit library (CTKlib)',
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
            homepage        => 'http://www.serzik.com',
            repository      => 'http://svn.serzik.com/CTKlib/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
    clean => {
        FILES => '*.log *.tmp src/*.tmp src/src src/dst src/dst2',
    },
);
