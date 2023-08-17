#!/usr/bin/perl

use warnings 'all';
use strict;
BEGIN {
   if (-d "./lib") {
      use lib "./lib";
   }
   if (-d "../lib") {
      use lib "../lib";
   }
}
use Test::Inter;
my $ti;

BEGIN {
   $ti      = new Test::Inter $0;
   unless ($ENV{RELEASE_TESTING}) {
      $ti->skip_all('Author tests not required for installation (set RELEASE_TESTING to test)');
   }
}

# CPANTORPM-DEPREQ REQEXCL IO::File
# CPANTORPM-DEPREQ REQEXCL File::Find::Rule

use IO::File;
use File::Find::Rule;

################################################################
# Test: the directory must contain the version number
#
# A module is in a directory (with major.minor version):
#    My-Mod-Name-##.##

my $libdir  = $ti->testdir('lib');
my $testdir = $ti->testdir();
my $moddir  = $ti->testdir('mod');
my @dir     = split(/\//,$moddir);
my $dir     = pop(@dir);

my($mod,$vers,$valid);
if ($dir =~ /^(.*)\-(\d+\.\d+)$/) {
   $mod     = $1;
   $vers    = $2;
   $valid   = 1;
} else { 
   $valid   = 0;
}

$ti->ok($valid,"Valid directory");
$ti->skip_all('Remaining tests require a valid directory')  if (! defined $vers);

################################################################
# Test: each .pm file must include a variable:
#   $VERSION = '##.##'
# A file is invalid if it does not have this, or if the version does
# not match the version contained in the directory.
#
# If there is a file _version.ign, it should be a list of filename
# substrings to ignore (any .pm file with any of these substrings
# will be ignored).

my @ign     = ();
if (-f "$testdir/_version.ign") {
   open(IN,"$testdir/_version.ign");
   @ign     = <IN>;
   close(IN);
   chomp(@ign);
}

my $in      = new IO::File;
my @files   = File::Find::Rule->file()->name('*.pm')->in($libdir);

FILE:
foreach my $file (@files) {
   my $f = $file;
   $f    =~ s,^$libdir/,,;
   $f    =~ s,^$testdir/,,  if ($mod eq 'Test-Inter');

   foreach my $ign (@ign) {
      next FILE  if ($file =~ /\Q$ign\E/);
   }

   $in->open($file);
   my @tmp = <$in>;
   chomp(@tmp);
   my @v   = grep /^\$VERSION\s*=\s*['"]\d+\.\d+['"];$/, @tmp;
   if (! @v) {
      $ti->ok(0,$f);
      $ti->diag('File contains no valid version line');
   } elsif (@v > 1) {
      $ti->ok(0,$f);
      $ti->diag('File contains multiple version lines');
   } else {
      $v[0] =~ /['"](\d+\.\d+)['"]/;
      my $v = $1;
      $ti->is($v,$vers,$f);
      $ti->diag('File contains incorrect version number')  if ($v ne $vers);
   }
}

################################################################
# Any .pm file with a version method can also be tested by getting
# the result of the version method.
#
# Note that the only module this test is not guaranteed to work on
# is Test::Inter because the version that is loaded above is not
# necessarily the one on disk.

my %required;
chdir($libdir);

FILE:
foreach my $file (@files) {
   my $f = $file;
   $f    =~ s,^$libdir/,,;

   foreach my $ign (@ign) {
      next FILE  if ($file =~ /\Q$ign\E/);
   }

   $in->open($file);
   my @tmp = <$in>;
   chomp(@tmp);
   my $package;
   foreach my $line (@tmp) {
      if ($line =~ /^package (\S+)/) {
         $package = $1;
         $package =~ s,;$,,;
         next;
      }
      if ($package  &&  $line =~ /^\s*sub\s+version\s*/) {
         if (! exists $required{$file}  &&  $f ne 'Test/Inter.pm') {
            require "./$f";
            $required{$f} = 1;
         }
         my $v = eval "${package}::version()";
         if (! $v) {
            $ti->ok(0,$package);
            $ti->diag('version method does not return a version');
            next;
         }
         $ti->is($v,$vers,$package);
         $ti->diag('version returns incorrect version number')  if ($v ne $vers);
      }
   }
}

$ti->done_testing();

