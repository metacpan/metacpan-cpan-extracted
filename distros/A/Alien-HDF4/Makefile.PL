#!perl -w
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
require 'common.pl';
require 5.010;

my ($libpath, $libs) = findlibs();
die <<EOF unless defined $libpath;
Cannot find hdf library, libdf.a.
Please add the correct library path to Makefile.PL or install HDF
EOF

my ($incpath) = findinc();
die <<EOF unless defined $incpath;
Cannot find hdf header file, hdf.h.
Please add the correct library path to Makefile.PL or install HDF
EOF

my $defs = finddefs();
print <<EOF unless length $defs;
WARNING: Unknown cpu type $Config{archname}! Not setting \$hdf_defs.
(This may not be a bad thing)
EOF
print "Final \$hdf_defs flags: '$defs'\n";

my ($szlibs) = findsz();
print "Warning: Did not find libsz, necessary for HDF >= 4.2r0\n"
    unless $szlibs;

my $version = get_version();

my @pms = qw(Alien/HDF4.pm Alien/HDF4/Install/Files.pm);
WriteMakefile(
  NAME	=> 'Alien::HDF4',
  VERSION => $version,
  MIN_PERL_VERSION => '5.010',
  BUILD_REQUIRES	=> {
    'IO::All'		=> 0,
    'ExtUtils::Depends'	=> '0.402',
  },
  CONFIGURE_REQUIRES	=> {
    'IO::All'		=> 0,
    'ExtUtils::Depends'	=> '0.402',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  PL_FILES => { map { ("lib/$_.PL" => "lib/$_") } @pms },
  PM => { map { ("lib/$_" => "\$(INST_ARCHLIB)/$_") } @pms },
  clean => { FILES => join ' ', map "lib/$_", @pms },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    provides => {
      'Alien::HDF4' => {
	file => 'lib/Alien/HDF4.pm.PL',
	version => $version,
      },
    },
    resources => {
      repository => {
	type => 'git',
	url => 'git://github.com/PDLPorters/Alien-HDF4',
	web => 'https://github.com/PDLPorters/Alien-HDF4',
      },
    },
  },
);
