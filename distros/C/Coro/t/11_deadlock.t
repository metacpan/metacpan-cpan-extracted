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
   my $old_idle = $Coro::idle;
   $Coro::idle = sub {
      print "ok 2\n";
      close STDERR;
      close STDOUT;
      $old_idle->();
   };
   schedule;
   exit 3;
};

waitpid $pid, 0;
print
   3 == $? >> 8
      ? "not " : "", "ok 3\n";

my $coro = new Coro sub {
   print "ok 5\n";
   Coro::Util::_exit 0;
};

$Coro::idle = sub {
   $coro->ready;
};

print "ok 4\n";

schedule;
die;
