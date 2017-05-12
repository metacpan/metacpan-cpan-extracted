#!perl

# This test simply loads all the modules
# it does this by scanning the directory for .pm files
# and use'ing each in turn

# It is slow because of the fork required for each separate use
use 5.006;
use strict;
use warnings;

# Test module only used for planning
# Note that we can not use Test::More since Test::More
# will lose count of its tests and complain (through the fork)
use Test::More;

use File::Find;

our @modules;

# If SKIP_COMPILE_TEST environment variable is set we
# just skip this test because it takes a long time
if (exists $ENV{SKIP_COMPILE_TEST}) {
  print "1..0 # Skip compile tests not required\n";
  exit;
}


# Scan the blib/ directory looking for modules


find({ wanted => \&wanted,
       no_chdir => 1,
       }, "blib");

# Start the tests
plan tests => (scalar(@modules));

# Loop through each module and try to run it

$| = 1;
my $counter = 0;

my $tempfile = "results.dat";

for my $module (@modules) {

  # Try forking. Perl test suite runs 
  # we have to fork because each "use" will contaminate the 
  # symbol table and we want to start with a clean slate.
  my $pid;
  if ($pid = fork) {
    # parent

    # wait for the forked process to complete
    waitpid($pid, 0);

    # Control now back with parent.

  } else {
    # Child
    die "cannot fork: $!" unless defined $pid;

    my $isok = 1;
    my $skip = '';
    eval "use $module ();";
    if( $@ ) {
      if ($@ =~ /Can't locate (.*\.pm) in/) {
        my $missing = $1;
        diag( "$module can not locate $missing" );
        $skip = "missing module $missing from $module";
      } else {
        diag( "require failed with '$@'\n" );
        $isok = 0;
      }
    }

    # Open the temp file
    open( my $fh, "> $tempfile") || die "Could not open $tempfile: $!";
    print $fh "$isok $skip\n";
    close($fh);

    exit;
  }

  if (open( my $fh, "< $tempfile")) {
    my $line = <$fh>;
    close($fh);
    if (defined $line) {
      chomp($line);
      my ($status, $skip) = split(/\s+/, $line, 2);
    SKIP: {
        skip( $skip, 1) if $skip;
        ok( $status, "Load $module");
      }
    } else {
      ok( 0, "Could not get results from loading module $module");
    }
  } else {
    # did not get the temp file
    ok(0, "Could not get results from loading module $module");
  }
  unlink($tempfile);

}

# This determines whether we are interested in the module
# and then stores it in the array @modules

sub wanted {
  my $pm = $_;

  # is it a module
  return unless $pm =~ /\.pm$/;

  # Remove the blib/lib (assumes unix!)
  $pm =~ s|^blib/lib/||;

  # Translate / to ::
  $pm =~ s|/|::|g;

  # Remove .pm
  $pm =~ s/\.pm$//;

  push(@modules, $pm);
}
