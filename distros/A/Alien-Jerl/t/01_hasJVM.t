use Test::More tests => 1;
use strict;
use warnings;


my $missingMessage = "Missing JVM, ergo you cannot test JERL (Download a JVM and make it available)";
my $diagMessage = "";
my $errorMessage = "NONE";

# use this for exercising different CMD requests on functioning Machines
# example (BASH): 
#    export JAVATEST=1; make test;
my $forceJavaTest = $ENV{JAVATEST};
if ($forceJavaTest) {
   diag("FORCING JAVA TEST: # $forceJavaTest");
} else {
  $forceJavaTest = 0;
}

# 
#  Try different invocations for JAVA.  There have been a few different
#  CPAN testers who have JAVA but for some reason Java doesn't run or has
#  issues.  This area attemps to force/reproduce those cases on a working
#  javabox (like mine).  Additionally, it tries other ways to call java.
#


# Get the Java version
my $javaVersion = `java -version 2>&1` || 'missing';
diag("JAVA Call: simple with redirected output");
chomp($javaVersion);

# FORCED TEST: 
#   CPANTESTER ISSUE .. not enough space to run java
#   Ex: Bash> export JAVATEST=4; make test
if ($forceJavaTest == 4) {
  $javaVersion = "Found Java Version: Error occurred during initialization of VM\nCould not reserve enough space for object heap\nError: Could not create the Java Virtual Machine.\nError: A fatal exception has occurred. Program will exit.\n";
}

# Retry with specified memory -Xmx256M
if ($javaVersion =~ m/error|missing/gis || $forceJavaTest == 1) {
   $javaVersion = `java -Xmx256M -version 2>&1` || 'missing';
   diag("JAVA Call: Xmx256");
   chomp($javaVersion);
}

# Retry with specified memory -Xmx128M
if ($javaVersion =~ m/error|missing/gis || $forceJavaTest == 2) {
   $javaVersion = `java -Xmx128M -version 2>&1` || 'missing';
   diag("JAVA Call: Xmx128");
   chomp($javaVersion);
}

# Retry with simplest params (note, if version info isn't stdout this will fail to retrieve the information)
if ($javaVersion =~ m/error|missing/gis || $forceJavaTest == 3) {
   $javaVersion = `java -version` || 'missing';
   diag("JAVA Call: Simple");
   chomp($javaVersion);
}

# Respond to specific version related issues here
#

#
# MSWIN issue : an error string is returned instead of false/empty
# 
if ( $javaVersion =~ m/is not recognized as an/gis) {
  $javaVersion = 'missing';
  $diagMessage .=  "Found error similar to the following: ( 'java' is not recognized as an internal or external command ) ...  stopping tests. ";
}

#
# JVM Error : 
# 
if ( $javaVersion =~ m/ERROR/gis) {
  $errorMessage = $javaVersion;

  $diagMessage .=  "\nJVM is returning an Error when querying version information ...  stopping tests.\n";
  $diagMessage .=  "!!!!!!!!!!  Error Message !!!!!!!: = $errorMessage\n";

  # flag as missing/not runnable
  $javaVersion = 'missing';
}


SKIP: { 
      
      # skip all tests if you cannot run JAVA (how can you test without a prerequisite, you cannot).
      skip $missingMessage, 1 unless ($javaVersion && $errorMessage eq 'NONE');
 
      isnt ($javaVersion, 'missing', 'Tested that JVM is *NOT* Missing');
}

TROUBLESHOOT: {	

      # Begin troubleshooting to accumulate in $diagMessage      

      # do you have a java executable available to the automated test
      #
      if ($javaVersion eq 'missing') {
	 $diagMessage .= 'Java was NOT available to the commandline. Consider adding Java to your path.';
      }

      # do you have a broken java distribution: a good example of a java version would be a multiline 
      # like the following: 
      #
      #java version "1.6.0_18"
      #OpenJDK Runtime Environment (IcedTea6 1.8.13) (6b18-1.8.13-0+squeeze2)
      #OpenJDK Client VM (build 14.0-b16, mixed mode, sharing)


      my @checks = ( 'java', 'ver', 'jdk' );
      
      # check for items and report in diagnostic message
      $diagMessage .= '[Version Diagnostic Check]...';
      foreach my $checkForThis (@checks) {
            if ($javaVersion !~ m/$checkForThis/ig) { 
	       $diagMessage .= '[Could not find "'.$checkForThis.'" in version]'; 
	    }
      }
      $diagMessage .= '..[Completed: Version Diagnostic]'."\n";

      # do you have JVM memory issues (like the following) :
      # 
      # Error occurred during initialization of VM
      # Could not reserve enough space for object heap
      # Error: Could not create the Java Virtual Machine. 
      # Error: A fatal exception has occurred. Program will exit. 

      my @memChecks = ('initialization', 'heap', 'ould not reserve');
      $diagMessage .= '[Memory Diagnostic Check]...';
      foreach my $checkForThis (@memChecks) {	    
            if ($javaVersion =~ m/$checkForThis/ig || $errorMessage =~ m/$checkForThis/ig) { 
               my $memfree = `cat /proc/meminfo | grep -i memfree`;
	       $diagMessage .= '[Possible Memory Issue With Java (cat /proc/meminfo | grep memfree = '.$memfree.'): encountered "'.$checkForThis.'"]'; 
	    }	    
      }
      $diagMessage .= '...[Completed: Memory Diagnostic]'."\n";

      $diagMessage .= '[Misc Diagnostic Checks]...';
      if ($javaVersion =~ m/reserve .*? space/ig) { 
      	 $diagMessage .= '[Possible Memory Issue With Java]'; 
      }
      $diagMessage .= '...[Completed: Misc Diagnostic]'."\n";
}

diag("\n---------------------------------------- [ Test for JVM ... ]");
diag("-- Found Java Version: $javaVersion ");
diag("----------------------- Diagnostic Messages ------------");
diag("--\n $diagMessage ");
diag("----------------------- Error Messages -----------------");
diag("--\n $errorMessage ");
diag("---------------------------------------- [ ... Test for JVM ]");

