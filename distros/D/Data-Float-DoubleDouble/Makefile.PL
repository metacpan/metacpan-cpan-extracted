use ExtUtils::MakeMaker;
use strict;
use warnings;

require 5.010;

# You'll notice references to 'NO_DIE' and '$no_die' in this Makefile.PL. They are present only
# so that I can run 'perl Makefile.PL NO_DIE=1' followed by 'dmake dist' on Windows - to create
# the Data-Float-DoubleDouble source distro.

my $no_die = defined($ARGV[0]) && $ARGV[0] eq 'NO_DIE=1' ? 1 : 0;

if($Config::Config{nvtype} ne 'long double' && !$no_die) {
  warn "  This module is usable only with 'long double' builds of perl\n",
       "  Your \$Config{nvtype} reports '", $Config::Config{nvtype}, "'";
  exit 0;
}

my $defines;
$Config::Config{byteorder} =~ /^1234/ ? $defines = "-DWE_HAVE_LENDIAN"
                                      : $defines = "-DWE_HAVE_BENDIAN";

# Check that we have DoubleDouble.
my $nv1 = 1.0;
my $nv2 = $nv1 + (2 ** -1000);
if($nv1 == $nv2 && !$no_die) {
  warn "  This module is not usable with this architecture's long double\n",
       "  It requires that the long double type is a 'double-double'\n";
  exit 0;
}

my %h = (
  NAME => 'Data::Float::DoubleDouble',
  VERSION_FROM => 'DoubleDouble.pm',
  DEFINE => $defines,
  PREREQ_PM => {'Math::NV' => '0.02'},
  LIBS => ['-lm'],
  LICENSE  => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/data-float-doubledouble.git',
        web => 'https://github.com/sisyphus/data-float-doubledouble',
      },
    },
  },
        );

WriteMakefile(%h);
