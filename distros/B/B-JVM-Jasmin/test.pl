#!perl -I ../blib/lib

# Last change: Fri May 28 03:16:57 BST 1999

# This is written in a peculiar style, since we're trying to avoid
# most of the constructs we'll be testing for.

$| = 1;

if ($#ARGV >= 0 && $ARGV[0] eq '-v') {
    $verbose = 1;
    shift;
}

chdir 'tests';

die "You need to run \"make test\" first to set things up.\n"
  unless -e '../perljvm';

# check leakage for embedders
$ENV{PERL_DESTRUCT_LEVEL} = 2 unless exists $ENV{PERL_DESTRUCT_LEVEL};

$ENV{EMXSHELL} = 'sh';        # For OS/2

if ($#ARGV == -1) {
    @ARGV = split(/[ \n]/, `echo not-from-perl/*.t base/if.t`);
}

_testprogs('perljvm', @ARGV);

sub _testprogs {
    $type = shift @_;
    @tests = @_;


    print <<'EOT' if ($type eq 'compile');
--------------------------------------------------------------------------------
TESTING COMPILER
--------------------------------------------------------------------------------
EOT

    $ENV{PERLCC_TIMEOUT} = 120 
          if ($type eq 'compile' && !$ENV{PERLCC_TIMEOUT});

    $bad = 0;
    $good = 0;
    $total = @tests;
    $files  = 0;
    $totmax = 0;
    $maxlen = 0;
    foreach (@tests) {
	$len = length;
	$maxlen = $len if $len > $maxlen;
    }
    # +3 : we want three dots between the test name and the "ok"
    # -2 : the .t suffix
    $dotdotdot = $maxlen + 3 - 2;
    while ($test = shift @tests) {

	if ($test =~ /^$/) {
	    next;
	}
	$te = $test;
	chop($te);
	print "$te" . '.' x ($dotdotdot - length($te));

	open(SCRIPT,"<$test") or die "Can't run $test.\n";
	$_ = <SCRIPT>;
	close(SCRIPT);
	if (/#!.*perl(.*)$/) {
	    $switch = $1;
	    if ($^O eq 'VMS') {
		# Must protect uppercase switches with "" on command line
		$switch =~ s/-([A-Z]\S*)/"-$1"/g;
	    }
	}
	else {
	    $switch = '';

	}
	if ($type eq 'perljvm') {
            $INC = ' -I' . join(' -I', @INC);
	    open(RESULTS, "$^X $INC ../perljvm --run $test |") or print "can't run.\n";
	}

	$ok = 0;
	$next = 0;
	while (<RESULTS>) {
	    if ($verbose) {
		print $_;
	    }
	    unless (/^(#|Generated:)/) {
		if (/^1\.\.([0-9]+)/) {
		    $max = $1;
		    $totmax += $max;
		    $files += 1;
		    $next = 1;
		    $ok = 1;
		}
		else {
		    $next = $1, $ok = 0, last if /^not ok ([0-9]*)/;
		    if (/^ok (\d+)(\s*#.*)?$/ && $1 == $next) {
			$next = $next + 1;
		    }
		    else {
			$ok = 0;
		    }
		}
	    }
	}
	close RESULTS;
	$next = $next - 1;
	if ($ok && $next == $max) {
	    if ($max) {
		print "ok\n";
		$good = $good + 1;
	    }
	    else {
		print "skipping test on this platform\n";
		$files -= 1;
	    }
	}
	else {
	    $next += 1;
	    print "FAILED at test $next\n";
	    $bad = $bad + 1;
	    $_ = $test;
	    if (/^base/) {
		die "Failed a basic test--cannot continue.\n";
	    }
	}
    }

    if ($bad == 0) {
	if ($ok) {
	    print "All tests successful.\n";
	}
	else {
	    die "FAILED--no tests were run for some reason.\n";
	}
    }
    else {
	$pct = sprintf("%.2f", ($files - $bad) / $files * 100);
	if ($bad == 1) {
	    warn "Failed 1 test script out of $files, $pct% okay.\n";
	}
	else {
	    warn "Failed $bad test scripts out of $files, $pct% okay.\n";
	}
	warn <<'SHRDLU';
   ### Since not all tests were successful, you may want to run some
   ### of them individually and examine any diagnostic messages they
   ### produce.
   ### You can run them using:
   ###                $^X $INC ../perljvm --run
SHRDLU
    }
    ($user,$sys,$cuser,$csys) = times;
    print sprintf("u=%g  s=%g  cu=%g  cs=%g  scripts=%d  tests=%d\n",
	$user,$sys,$cuser,$csys,$files,$totmax);
}
exit ($bad != 0);
