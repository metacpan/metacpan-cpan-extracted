#!perl
use Config;
$file = shift @ARGV;
open OUT,">$file" or die "Can't create $file: $!";
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

my $tool = shift;

# this will definitely not work
if ( not $tool ) {
	die "Usage: phylotastic ModuleName <args>\n (see 'man Bio::PhyloTastic')\n";
}

# create package name
my $package = "Bio/PhyloTastic/$tool.pm";
my $class = "Bio::PhyloTastic::$tool";

# try to load
eval { require $package };
if ( $@ ) {
	die <<"ERROR";
==================================== ERROR =====================================
 FAILED TO LOAD $class
================================= EXPLANATION ==================================
 The perl package $class (or one of its dependencies) 
 couldn't be loaded correctly. This is either because it hasn't been installed
 system-wide or because the environment variable PERL5LIB does not include the
 path to the lib folder of the cpan api.
================================================================================
  The error that was issued when attempting to run the $tool tool was:
$@
================================================================================
ERROR
}

# run the tool
$class->run;

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";

