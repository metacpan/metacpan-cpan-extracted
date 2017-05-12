##
##  Perl makefile for the official CWB/Perl interface (Perl part)
##

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Getopt::Long;
use FileHandle;

our $config_util = "cwb-config";  # path to cwb-config utility (if not in search path)
our $help = 0;                    # display help page

GetOptions(
  "config=s" => \$config_util,
  "help|h" => \$help,
) or die "\nType 'perl Makefile.PL --help' for usage information.\n";

if ($help) {
  print "Usage:  perl Makefile.PL [--config=/path/to/cwb-config]\n\n";
  print "    --config <path>  full path to 'cwb-config' program (if not in standard search path)\n";
  print "\n";
  exit 2;
}

## required CWB version for this module (3.0, but also accept 2.2.102 until official release)
our $rMajor = 2;
our $rMinor = 2;
our $rBeta = 101;

## run cwb-config to check installed CWB version
my $version = `'$config_util' --version 2>/dev/null`;
unless (defined $version && $version =~ /^([0-9])\.([0-9]{1,2})(\.b?([0-9]+))?$/) {
    print STDERR
      "Can't run cwb-config program.\n",
        "Please make sure that an up-to-date version of the IMS Open Corpus Workbench has been installed and/or use the --config option to specify the full path to the cwb-config program.\n";
    exit 1;
}


our $MajorVersion = $1;
our $MinorVersion = $2;
our $BetaVersion = $4 || 0;
chomp($version);

unless ($MajorVersion > $rMajor
    || ($MajorVersion == $rMajor &&
        ($MinorVersion > $rMinor || $MinorVersion == $rMinor && $BetaVersion >= $rBeta))) {
    print STDERR "Error: need CWB version ",
      version_string($rMajor, $rMinor, $rBeta), " or newer, but only $version is installed.\n";
    exit 1;
}

## obtain relevant configuration options from cwb-config
our $prefix = `'$config_util' --prefix`;
our $bindir = `'$config_util' --bindir`;
our $default_registry = `'$config_util' --default-registry`;
chomp($prefix, $bindir, $default_registry);

print "IMS Open Corpus Workbench v$version found in $prefix tree.\n";
die "Error: can't handle directory paths with apostrophe yet. Please install the CWB in a different directory.\n"
  if "$prefix$bindir$default_registry" =~ /'/;

## write configuration information to CWB::Config module
my $config_file = "lib/CWB/Config.pm";
my $fh = new FileHandle "> $config_file"
  or die "Can't create file '$config_file': $!";
print $fh <<"STOP" or die "Error writing file '$config_file': $!";
package CWB::Config;

our \$Prefix = '$prefix';
our \$BinDir = '$bindir';
our \$Registry = '$default_registry';

1;
STOP
$fh->close
  or die "Error writing '$config_file': $!";
print "Configuraion saved to file $config_file\n";

## now we can let MakeMaker generate the makefile
WriteMakefile(
              'NAME'         => "Alt::CWB::ambs",
              'VERSION_FROM' => "lib/Alt/CWB/ambs.pm",
              'EXE_FILES'    => ["script/cwb-make",
                                 "script/cwb-regedit",
                                 "script/cwb-align-import"],
              'META_MERGE'   => {
                                 "meta-spec" => { version => 2 },
                                 "no_index"  => {
                                                 directory => [ 'lib/CWB/'   ],
                                                 file      => [ 'lib/CWB.pm' ],
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
