## 
##  Perl makefile for the official CWB/Perl interface (C API)
##
$| = 1;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Getopt::Long;
use File::Spec;
use Config;

our $config_util = "cwb-config";  # path to cwb-config utility (if not in search path)
our $help = 0;                    # display help page

GetOptions(
  "config=s" => \$config_util,
  "help|h" => \$help,
) or die "\nType 'perl Makefile.PL --help' for usage information.\n";

if ($help) {
  print "Usage:  perl Makefile.PL [--config=/path/to/cwb-config]\n";
  print "    --config <path>  full path to 'cwb-config' program (if not in standard search path)\n";
  print "\n";
  exit 2;
}

## required CWB version for this module (3.5)
our $rMajor = 3;
our $rMinor = 5;
our $rBeta  = 0;

## run cwb-config to check installed CWB version
my $version = `'$config_util' --version 2>/dev/null`;
die
  "Can't run cwb-config program.\n",
  "Please make sure that an up-to-date version of the IMS Open Corpus Workbench has been installed and/or use the --config option to specify the full path to the cwb-config program.\n"
  unless defined $version and $version =~ /^([0-9])\.([0-9]{1,2})(\.b?([0-9]+))?$/;

our $MajorVersion = $1;
our $MinorVersion = $2;
our $BetaVersion  = $4 || 0;
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
  
  my @libcl = grep { -f && -s > 0 } map {"$libdir/libcl.$_"} qw(a so dylib dll);
  unless (@libcl) {
    die "\nERROR: Can't find library file libcl.{a,so,dylib,dll}\n";
  }
}
print "ok\n";

my $CFLAGS = `'$config_util' -I`;
chomp $CFLAGS;
my $LDFLAGS = `'$config_util' -L`;
chomp $LDFLAGS;

# for some configurations, we need to smuggle $LDFLAGS in via LDDLFLAGS as well
# because LIBS is scrubbed by MakeMaker, removing any non-standard flags
my $LDDLFLAGS = $Config{lddlflags}; # documentation says this is the default
if (" $LDFLAGS" =~ /\s-[^Ll]/) {
  # assume that anything except -L<dir> and -l<lib> is problematic
  $LDDLFLAGS .= " $LDFLAGS";
}

WriteMakefile(
  NAME          => 'CWB::CL',
  VERSION_FROM  => 'lib/CWB/CL.pm', # finds $VERSION
  PREREQ_PM     => {}, # e.g., Module::Name => 1.1
  TYPEMAPS      => ["CL.typemap"],
  INC           => $CFLAGS,
  LIBS          => $LDFLAGS,
  LDDLFLAGS     => $LDDLFLAGS, # see above why this may be needed
  DEFINE        => "",
  LICENSE       => "perl",
  META_MERGE    => {
    resources => {
      homepage => 'https://cwb.sourceforge.io/',
      repository => 'http://svn.code.sf.net/p/cwb/code/perl/trunk',
    },
  },
);


##
##  Subroutines
##

sub version_string {
  my ($major, $minor, $beta) = @_;
  my $s = "$major.$minor";
  if ($beta > 0) {
    $s .= ".$beta"; # in future, "beta" versions are simply listed as releases, without "b" marker
  }
  return $s;
}
