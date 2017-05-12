#------------------------------------------------------------------------------
# DBO test utilities.
#------------------------------------------------------------------------------

# Count the number of tests in the test file by grepping it for "test {"
# at the start of a line.  Then print the 1..n line that tells the test
# harness how many tests to expect.  The +1 is for testing that Perl
# actually compiles the script.

use vars qw($LOADED $N);
$^W = 1;
$LOADED = 1;
$N = 1;
print "ok 1\n";

BEGIN {
  $| = 1;
  open TEST, "<$0" or die "Can't open $0: $!";
  $TESTS = 7 + grep /^test \{/, <TEST>;
  close TEST or die "Can't close $0: $!";
  print "1..$TESTS\n";
}

# If Perl failed to compile the script, then $LOADED will never have
# been set, and hence test 1 has failed.

END { print "not ok 1\n" unless $LOADED; }

# `test' takes a subroutine which is called.  The subroutine should die
# to indicate failure or complete normally for success.

sub test (&) {
  my ($test) = @_;
  ++ $N;
  eval { &$test };
  if ($@) {
    print STDERR "$@\n";
    print "not ";
  }
  print "ok $N\n";
}

use DBO ':constructors';
use DBO::Visitor::Create;
use vars qw($CONFIG $TABLE $dbo $table1 $schema);
require '.status';

$TABLE = 'dbotest';
$DBO::DEBUG = 1;

1;
