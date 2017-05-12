## 
##  Perl makefile for the official CWB/Perl interface (C API)
##
$| = 1;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Getopt::Long;
use Config;
use File::Spec;

our $config_util = "cwb-config";  # path to cwb-config utility (if not in search path)
our $help = 0;                    # display help page

GetOptions(
  "help|h" => \$help,
) or die "\nType 'perl Makefile.PL --help' for usage information.\n";

if ($help) {
  print "Usage:  perl Makefile.PL [--config=/path/to/cwb-config]\n";
  print "    --config <path>  full path to 'cwb-config' program (if not in standard search path)\n";
  print "\n";
  exit 2;
}

## required CWB version for this module (3.0, but also accept 2.2.101 until official release)
our $rMajor = 2;
our $rMinor = 2;
our $rBeta = 101;

## run cwb-config to check installed CWB version
my $version = `'$config_util' --version 2>/dev/null`;
die
  "Can't run cwb-config program.\n",
  "Please make sure that an up-to-date version of the IMS Open Corpus Workbench has been installed and/or use the --config option to specify the full path to the cwb-config program.\n"
  unless defined $version and $version =~ /^([0-9])\.([0-9]{1,2})(\.b?([0-9]+))?$/;

our $MajorVersion = $1;
our $MinorVersion = $2;
our $BetaVersion = $4 || 0;
chomp($version);

die "Error: need CWB version ", version_string($rMajor, $rMinor, $rBeta), " or newer, but only $version is installed.\n"
  unless $MajorVersion > $rMajor
    or ($MajorVersion == $rMajor and
          ($MinorVersion > $rMinor or $MinorVersion == $rMinor and $BetaVersion >= $rBeta));

## check whether C API is available (cwb/cl.h and libcl.a)
print "Checking for CL library ... ";
{
  my $incdir = `'$config_util' --incdir`;
  chomp($incdir);
  my $cl_h = "$incdir/cwb/cl.h";
  unless (-f $cl_h and -s $cl_h > 0) {
    die "\nERROR: Can't find header file $cl_h\n";
  }
  my $libdir = `'$config_util' --libdir`;
  chomp($libdir);
  my $libcl_a = "$libdir/libcl.a";
  unless (-f $libcl_a and -s $libcl_a > 0) {
    die "\nERROR: Can't find library file $libcl_a\n";
  }
}
print "ok\n";

chomp(my $CFLAGS  = `'$config_util' -I`);
chomp(my $LDFLAGS = `'$config_util' -L`);

WriteMakefile(
  NAME          => 'CWB::CL',
  DISTNAME      => 'Alt-CWB-CL-ambs',
  VERSION_FROM  => 'lib/Alt/CWB/CL/ambs.pm',
  XS_VERSION    => '2.2.102',
  PREREQ_PM     => {},
  TYPEMAPS      => ["CL.typemap"],
  XS            => { 'CL.xs' => 'CL.c' },
  OBJECT        => "CL".$Config{obj_ext},
  INC           => $CFLAGS,
  LIBS          => $LDFLAGS,
  DEFINE        => "",
  META_MERGE    => {
                    "meta-spec" => { version => 2 },
                    "no_index"  => {
                                    directory => [ 'lib/CWB/'   ],
                                   },
                   },
);
