#!/usr/bin/perl
# Makefile.PL                                                      -*- Perl -*-
#   Makefile generator for B::JVM::Jasmin
#
#   Copyright (C) 1999, Bradley M. Kuhn, All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License, as specified in the LICENSE file that was shipped
# with this distribution.

use 5.00562;

use strict;
use warnings;

use Carp;
use Config;
use ExtUtils::MakeMaker;

use vars qw($VERSION_FILE);

# If you don't put this in a begin block, it does not work.  Who takes control
#  of STDIN or "selects" another output in a BEGIN block?

BEGIN {
  ($ENV{B_JVM_JASMIN_JASMIN_PATH}, $ENV{PERL_JVM_JAVAC},
   $ENV{B_JVM_JASMIN_JAVA_PATH}) = ("", "", "");

  print <<"END";
There are a number of Java .class files that are created for use by perljvm.
You will need to decide where these classes are installed.
END

  $ENV{PERL_JVM_CLASS_FILE_HOME} = "";

  print "Install .class files to: [$Config{installsitelib}/javalib] ";
  chomp($ENV{PERL_JVM_CLASS_FILE_HOME} = <STDIN>);
  $ENV{PERL_JVM_CLASS_FILE_HOME} ||= "$Config{installsitelib}/javalib";

  # Check to make sure we have java installed, of some sort.

  my $JASMIN_MAJOR = 1.0;
  my $JASMIN_MINOR = 6;
  
 
  my @PATH_LIST = split /:/, $ENV{PATH};
  
  # Make sure that version numbers are consistent
  
  $VERSION_FILE = "Jasmin.pm";
  my $VERSION = MM->parse_version($VERSION_FILE);
  
  foreach my $file (<*.pm>) {
    my $newVersion = MM->parse_version($file);
    die("version mismatch: $file is version $newVersion, " .
        "but $VERSION_FILE is $VERSION.  $file must be updated")
      unless ($newVersion eq $VERSION);
  }
  
  # Look for the jasmin program
  
  foreach my $path (@PATH_LIST) {
      if (-x "$path/jasmin") {
        $ENV{B_JVM_JASMIN_JASMIN_PATH} = "$path/jasmin";
        last;
      }
  }
  
  # Look for the java program
  
  foreach my $javaProgram ("java", "kaffe", "japhar") {
    if ($ENV{B_JVM_JASMIN_JAVA_PATH} eq "") {
      foreach my $path (@PATH_LIST) {
        if (-x "$path/$javaProgram") {
          $ENV{B_JVM_JASMIN_JAVA_PATH} = "$path/$javaProgram";
          last;
        }
      }
    }
  }
  
  # Look for the javac program
  
  foreach my $javacProgram ("javac", "guavac", "jikes") {
    if ($ENV{PERL_JVM_JAVAC} eq "") {
      foreach my $path (@PATH_LIST) {
        if (-x "$path/$javacProgram") {
          $ENV{PERL_JVM_JAVAC} = "$path/$javacProgram";
          last;
        }
      }
    }
  }
  
  if ($ENV{B_JVM_JASMIN_JASMIN_PATH} ne "") {
    unless (open(JASMIN, "$ENV{B_JVM_JASMIN_JASMIN_PATH} -version 2>&1|")) {
      carp("$ENV{B_JVM_JASMIN_JASMIN_PATH} does not appear to run");
      $ENV{B_JVM_JASMIN_JASMIN_PATH} = "";
    } else {
      my($version, $major, $minor);
      while (my $line = <JASMIN>) {
        if ($line =~
            /^\s*Jasmin\s+version\s*:\s*v?((\d+)\.(\d+)(?:\.\d+)*)\s*$/i) {
          ($version, $major, $minor) = ($1, $2, $3);
          last;
        }
        if ($version eq "") {
          carp("Unable to run $ENV{B_JVM_JASMIN_JASMIN_PATH} properly!");
          $ENV{B_JVM_JASMIN_JASMIN_PATH} = "";
        }
        elsif ( ($major == $JASMIN_MAJOR && $minor >= $JASMIN_MINOR)
                || ($major > $JASMIN_MAJOR) ) {
          carp("$ENV{B_JVM_JASMIN_JASMIN_PATH} is $version, we need at least " .
               "$JASMIN_MAJOR.$JASMIN_MINOR");
          $ENV{B_JVM_JASMIN_JASMIN_PATH} = "";
        }
      }
      close(JASMIN);
  }
    
  }
  if ($ENV{B_JVM_JASMIN_JAVA_PATH} eq "") {
    carp("perljvm --run will not work!  No JVM found!") 
  } else {
    print "java appears to be $ENV{B_JVM_JASMIN_JAVA_PATH}\n";
  }
  if ($ENV{B_JVM_JASMIN_JASMIN_PATH} eq "") {
    carp("perljvm --run will not work!  Jasmin not found!") 
  } else {
    print "jasmin appears to be $ENV{B_JVM_JASMIN_JASMIN_PATH}\n";
  }
  if ($ENV{PERL_JVM_JAVAC} eq "") {
    die("No Java compiler found, cannot compile this package!")
  } else {
    print "javac appears to be $ENV{PERL_JVM_JAVAC}\n";
  }
}

# Had to do this to get the PATHs into perljvm.  Is there a better solution?

sub MY::processPL {
  package MY;	# so that "SUPER" works right
  my $inherited = shift->SUPER::processPL(@_);
  $inherited =~ s/(\n\t+)(\$\(PERL\))/$1export B_JVM_JASMIN_JASMIN_PATH="$ENV{B_JVM_JASMIN_JASMIN_PATH}"; export B_JVM_JASMIN_JAVA_PATH="$ENV{B_JVM_JASMIN_JAVA_PATH}"; $2/;
  $inherited;
}

# Had to do this so I could run perljvm instead of plan old perl when testing

#sub MY::test {
#  package MY;	# so that "SUPER" works right
#  my $inherited = shift->SUPER::test(@_);
#  $inherited;
#}
###############################################################################
WriteMakefile(
    NAME           => 'B::JVM::Jasmin',
    VERSION_FROM   => $VERSION_FILE,

    AUTHOR         => 'Bradley M. Kuhn <bkuhn@ebb.org>',
    ABSTRACT_FROM  => $VERSION_FILE,

    PL_FILES => {'perljvm.PL' => 'perljvm' },
    EXE_FILES => ['perljvm'],

    DIR => ['Java'],

    clean => {FILES => "lib/B/JVM/Jasmin/*~ perljvm"},

    dist => { 
             CI   => 'cvs -d /home/bkuhn/Files/Graduate/University-of-Cincinnati/CVSThesis commit' }
);
