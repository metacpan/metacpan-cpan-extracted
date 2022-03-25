use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %common_reqs = (
    "Alien::Build" => "2.25",  #  needed for clean_install
    "ExtUtils::MakeMaker" => "6.52",
    "Alien::Build::MM" => "1.41",
    "Alien::patch" => 0,
    "File::Find::Rule" => 0,
    "parent" => 0,
    "PkgConfig" => 0.19026,
    "Alien::Build::Plugin::Cleanse::BuildDir" => 0,
    'Sort::Versions' => 0,
    'Alien::libtiff' => 0,
    "Alien::geos::af" => '1.005',
    "Alien::proj" => '1.13',
    "Alien::sqlite" => '1.02',
    "FFI::CheckLib"   => "0.23",
    #"File::Stat" => 0,
    #($^O =~ /mswin/i) ? ("Alien::MSYS" => 0) : (),
    'Alien::Build::Plugin::PkgConfig::PPWrapper' => '0',
);

my %WriteMakefileArgs = (
    "ABSTRACT" => "Alien package for the Geospatial Data Abstraction Library (GDAL)",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "Alien::gdal",
    "VERSION_FROM" => "lib/Alien/gdal.pm",
    "CONFIGURE_REQUIRES" => {
        %common_reqs,
        "PkgConfig"  => 0,
        "HTTP::Tiny" => 0.044,  #  something, somewhere needs this version, need to track it down
    },
    "BUILD_REQUIRES" => {
        %common_reqs,
    },
    "TEST_REQUIRES" => {
        "Test::Alien" => 0,
    },
    "PREREQ_PM" => {
        "Alien::Base" => "1.41",
        "Capture::Tiny" => 0,
        "Path::Tiny" => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-alien-gdal',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-alien-gdal/issues/',
            },
        },
        #prereqs => {
        #    build => {
        #        suggests => {
        #            "Alien::spatialite" => '1.03',
        #        },
        #    },
        #},
    },
    "DISTNAME" => "Alien-gdal",
    "LICENSE"  => "perl",
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new (
    #my_alienfile_meta => 0,
    clean_install => 1,
);
sub MY::install {
  $abmm->mm_install(@_);
}

%WriteMakefileArgs = $abmm->mm_args(
    %WriteMakefileArgs,
);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
