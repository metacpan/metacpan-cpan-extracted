#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $MSWIN = $^O =~ /mswin/i ? 1 : 0;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };
my $prereq_pm = {
        'Archive::Extract'      => 0.58,
        'Archive::Tar'          => 1.80,
        'Archive::Zip'          => 1.30,
        'Class::C3::Adopt::NEXT'=> 0.13,
        'Class::Singleton'      => 1.40,
        'Config::General'       => 2.00,
        'ExtUtils::MakeMaker'   => 6.60,
        'File::Copy'            => 2.00,
        'File::Copy::Recursive' => 0.38,
        'File::Find'            => 1.00,
        'File::Path'            => 2.00,
        'File::Pid'             => 1.00,
        'File::Spec'            => 0.82,
        'HTTP::Headers'         => 5.80,
        'HTTP::Request'         => 5.80,
        'HTTP::Response'        => 5.80,
        'IO::Handle'            => 1.20,
        'IPC::Open3'            => 1.00,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::UserAgent'        => 5.80,
        'MIME::Base64'          => 3.00,
        'MIME::Lite'            => 3.00,
        'Moose'                 => 2.00,
        'Net::FTP'              => 2.60,
        'Perl::OSType'          => 1.00,
        'Symbol'                => 1.05,
        'Term::ReadKey'         => 2.10,
        'Term::ReadLine'        => 1.04,
        'Test::More'            => 0.94,
        'Text::ParseWords'      => 3.27,
        'Time::HiRes'           => 1.97,
        'Time::Local'           => 1.20,
        'URI'                   => 1.60,
        'XSLoader'              => 0.01,
        'YAML'                  => 0.73,
        'namespace::autoclean'  => 0.13,
    };
$prereq_pm->{'Sys::SigAction'}  =  0.15 unless $MSWIN;

my $exefiles = [qw(
        bin/ctklib
        bin/ctklib-tiny
    )];
push @$exefiles, (qw(bin/pv.exe)) if $MSWIN;

WriteMakefile(
    'NAME'                  => 'CTK',
    'DISTNAME'              => 'CTKlib',
    'MIN_PERL_VERSION'      => 5.010001,
    'DIR'                   => ['xs'],
    'VERSION_FROM'          => 'lib/CTK.pm',
    'ABSTRACT_FROM'         => 'lib/CTK.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Sergey Lepenkov (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'lgpl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.com',
            repository      => 'http://svn.serzik.com/CTKlib/trunk',
            license         => 'http://opensource.org/licenses/lgpl-license.php',
        },
    },

);

# For Test::Distribution patch
eval { require File::Copy; File::Copy::copy("CHANGES","ChangeLog"); 1 } unless $MSWIN;
