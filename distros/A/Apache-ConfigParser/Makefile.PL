# This -*- perl -*- script writes the Makefile for this package.

use strict;
require 5.004_05;
use ExtUtils::MakeMaker;

$|                  = 1;
my $missing_modules = 0;
my $version;

$version = 0.01;
print "Checking for File::FnMatch $version...";
eval "use File::FnMatch $version;";
if ($@) {
  print " failed\n";
  ++$missing_modules;
  print <<EOT;
$@

File::FnMatch is used to find Apache configuration files that match a glob.

EOT
} else {
  print " ok\n";
}

$version = 0.82;
print "Checking for File::Spec $version...";
eval "use File::Spec $version;";
if ($@) {
  print " failed\n";
  ++$missing_modules;
  print <<EOT;
$@

File::Spec must be installed for Apache configuration file directives
that take file and directory path names to be parsed in an operating
system independent manner.

EOT
} else {
  print " ok\n";
}

$version = 0.18;
print "Checking for Test::More $version...";
eval "use Test::More $version;";
if ($@) {
  print " failed\n";
  ++$missing_modules;
  print <<EOT;
$@

Test::More is used to test the package.

EOT
} else {
  print " ok\n";
}

$version = 1.04;
print "Checking for Tree::DAG_Node $version...";
eval "use Tree::DAG_Node $version;";
if ($@) {
  print " failed\n";
  ++$missing_modules;
  print <<EOT;
$@

Tree::DAG_Node must be installed to set up a tree structure for the
Apache configuration files.

EOT
} else {
  print " ok\n";
}

print <<EOT if $missing_modules;

The missing module can be obtained from CPAN.  Visit
  <URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT

WriteMakefile(
  'NAME'	 => 'Apache::ConfigParser',
  'VERSION_FROM' => 'lib/Apache/ConfigParser.pm', # finds $VERSION
  'PREREQ_PM'    => { 'File::FnMatch'  => 0.01,
                      'Tree::DAG_Node' => 1.04 },
  'dist'         => { 'COMPRESS'       => 'gzip -9',
                      'SUFFIX'         => 'gz'
                    },
);
