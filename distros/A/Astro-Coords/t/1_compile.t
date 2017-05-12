# This test simply loads all the modules
# it does this by scanning ORAC-DR lib dir for .pm files
# and use'ing each in turn

# It is slow because of the fork required for each separate use

use strict;
use warnings;
use Test; # Not really needed since we don't use ok()

use File::Find;

our @modules;

# If PERL_SKIP_COMPILE_TEST environment variable is set we
# just skip this test because it takes a long time
if (exists $ENV{PERL_SKIP_COMPILE_TEST}) {
  print "1..0 # Skip compile tests not required\n";
  exit;
}


# Scan the blib/lib/JAC directory looking for modules


find({ wanted => \&wanted,
       no_chdir => 1,
       }, "blib/lib/Astro");

# Start the tests
plan tests => scalar(@modules);


# Loop through each module and try to run it

$| = 1;

for my $module (@modules) {

  # Try forking. Perl test suite runs 
  # we have to fork because each "use" will contaminate the 
  # symbol table and we want to start with a clean slate.
  my $pid;
  if ($pid = fork) {
    # parent

    # wait for the forked process to complet
    waitpid($pid, 0);

    # Control now back with parent.

  } else {
    # Child
    die "cannot fork: $!" unless defined $pid;
    eval "use $module ();";
    if( $@ ) {
      warn "require failed with '$@'\n";
      print "not ";
    }
    print "ok - $module\n";
    # Must remember to exit from the fork
    exit;
  }
}

# This determines whether we are interested in the module
# and then stores it in the array @modules

sub wanted {
  my $pm = $_;

  # is it a module
  return unless $pm =~ /\.pm$/;

  print "pm is $pm\n";



  # Remove the blib/lib (assumes unix!)
  $pm =~ s|^blib/lib/||;

  # Translate / to ::
  $pm =~ s|/|::|g;

  # Remove .pm
  $pm =~ s/\.pm$//;

  push(@modules, $pm);
}
