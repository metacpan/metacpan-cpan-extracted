#
# times.t
#
# We will test only the user time and system time resources
# of all the resources returned by getrusage() as they are
# probably the most portable of them all.
#

use BSD::Resource qw(times);

my $debug = 1;

$| = 1 if ($debug);

require "./t/burn.pl";

burn();

sleep(2);

@t0 = CORE::times();
@t1 = times();
@t2 = BSD::Resource::times();

if ($debug) {
    print "# CORE::times()          = @t0\n";
    print "# times                  = @t1\n";
    print "# BSD::Resource::times() = @t2\n";
}

if ($t0[0] < 0.5 || $t0[1] < 0.5) {
    print "1..0 # SKIP Not enough user or system time accumulated for test\n";
    exit;
}

print "1..2\n";

sub far ($$$) {
  my ($a, $b, $r) = @_;

  print "# far: a = $a, b = $b, r = $r\n" if $debug;
  print "# far: abs(a/b-1) = ", $b ? abs($a/$b-1) : "-", "\n" if $debug; 
  $b == 0 ? 0 : (abs($a/$b-1) > $r);
}

print 'not ' if far($t1[0], $t0[0], 0.20) or
	        far($t1[1], $t0[1], 0.50);
print "ok 1\n";

print 'not ' if far($t1[0], $t2[0], 0.10) or
	        far($t1[1], $t2[1], 0.10) or
                far($t1[2], $t2[2], 0.10) or
                far($t1[3], $t2[3], 0.10);
print "ok 2\n";

# eof
