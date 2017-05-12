#!perl
use blib;

BEGIN {
  # protect against prove-style non-interactive usage (Test::Harness fails)
  # make test works okay
  if ($ENV{AUTOMATED_TESTING} or $ENV{PERL_DL_NONLAZY}) {
    print "1..0 # skip non-interactive Test::Harness. Try make test instead.\n";
    exit;
  }
  use B::Debugger(@_);
  print "1..3\n";
  print "# enter c to finish the test";
}
for (1,2,3) { print "ok $_\n" if /\d/ }
