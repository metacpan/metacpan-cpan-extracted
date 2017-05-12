BEGIN {
   if ($^O =~ /mswin32/i) {
      print <<EOF;
1..0 # Perl binary broken, skipping test. Upgrading to a working perl is advised.
EOF
      exit 0;
   }
}

BEGIN { $| = 1; print "1..5\n"; }

use Coro;

print "ok 1\n";

my $pid = fork or do {
   print "ok 2\n";
   async {
      print "ok 4\n";
      exit 0;
   };
   print "ok 3\n";
   Coro::cede;
   print "not ok 5\n";
   exit 1;
};

waitpid $pid, 0;
print $?  ? "not " : "", "ok 5\n";

