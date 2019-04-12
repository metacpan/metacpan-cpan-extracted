#!perl -w

require 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
require './common.pl';

my $version = ag_getversion();

my @pms = qw(Alien/Gimp.pm Alien/Gimp/Install/Files.pm);
WriteMakefile(
  NAME	=> 'Alien::Gimp',
  VERSION => $version,
  MIN_PERL_VERSION => '5.014001',
  LICENSE => 'perl',
  CONFIGURE_REQUIRES	=> {
    'IO::All'		=> 0,
    'ExtUtils::Depends'	=> '0.402',
    'ExtUtils::PkgConfig'	=> 0,
    'Data::Dumper'	=> 0,
    'File::Spec'	=> 0,
  },
  BUILD_REQUIRES	=> {
    'IO::All'		=> 0,
    'ExtUtils::Depends'	=> '0.402',
#    'ExtUtils::PkgConfig'	=> 0,
  },
  TEST_REQUIRES => {
    'Inline'	=> '0.78',
    'Inline::C'	=> '0.67',
    'Test::More' => '0.88',
  },
  PL_FILES => { map { ("lib/$_.PL" => "lib/$_") } @pms },
  PM => { map { ("lib/$_" => "\$(INST_ARCHLIB)/$_") } @pms },
  clean => { FILES => join ' ', map "lib/$_", @pms },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    provides => {
      'Alien::Gimp' => {
	file => 'lib/Alien/Gimp.pm.PL',
	version => $version,
      },
    },
    resources => {
      repository => {
	type => 'git',
	url => 'git://github.com/mohawk2/Alien-Gimp',
	web => 'https://github.com/mohawk2/Alien-Gimp',
      },
    },
  },
);
