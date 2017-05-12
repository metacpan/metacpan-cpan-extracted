#
# setpriority.t
#

use BSD::Resource;

$debug = 1;

print "1..3\n";

my $nice = 0;

my $ps = "ps -o pid,nice";

if (open(PS, "$ps 2>/dev/null|")) {
    while(<PS>) {
        if (/^\s*$$\s+(-?\d+)\s*$/) {
	    $nice = $1;
	    last;
	}
    }
    close(PS);
} else {
    print "# open(..., '$ps >/dev/null|') failed: $!\n";
    if (open(NICE, "nice --version 2>/dev/null|")) {
	my $gnu = 0;
	while (<NICE>) {
	    if (/GNU/) {
		$gnu = 1;
		last;
	    }
	}
	close(NICE);
	if ($gnu) {
	    if (open(NICE, "nice|")) {
		chomp($nice = <NICE>);
		unless ($nice =~ /^-?\d+$/) {
		    print "# nice returned: '$nice'\n";
		    $nice = 0;
		}
	    } else {
		print "# nice failed: $!\n";
	    }
	}
    } else {
	print "# nice --version failed: $!\n";
    }
}

print "# nice = $nice\n";

if ($nice <= 0) {
    $origprio = getpriority(PRIO_PROCESS, 0);

    print "# origprio = $origprio ($!)\n" if ($debug);

    $gotlower = setpriority(PRIO_PROCESS, 0, $origprio + 1);

    print "# gotlower = $gotlower ($!)\n" if ($debug);

    # we must use getpriority() to find out whether setpriority() really worked

    $lowerprio = getpriority(PRIO_PROCESS, 0);
    
    print "# lowerprio = $lowerprio ($!)\n" if ($debug);

    $fail = (not $gotlower or not $lowerprio == $origprio + 1);

    print 'not '
	if ($fail);
    print "ok 1\n";
    if ($fail) {
	print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
	print "# gotlower = $gotlower, lowerprio = $lowerprio\n";
    }

    if ($origprio == 0) {

	$gotlower = setpriority();

	print "# gotlower = $gotlower ($!)\n" if ($debug);

	# we must use getpriority() to find out whether setpriority()
	# really worked.

	$lowerprio = getpriority();

	print "# lowerprio = $lowerprio\n" if ($debug);

	$fail = (not $gotlower or not $lowerprio == 10);

	print 'not '
	    if ($fail);
	print "ok 2\n";
	if ($fail) {
	    print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
	    print "# gotlower = $gotlower, lowerprio = $lowerprio\n";
	}
    } else {
	print "ok 2 # skipped (origprio = $origprio)\n";
    }
} else {
  print "ok 1 # skipped\n";
  print "ok 2 # skipped\n";
}

if ($> == 0) { # only effective uid root can even attempt this
  $gothigher = setpriority(PRIO_PROCESS, 0, -5);
  print "# gothigher = $gothigher\n" if ($debug);
  $higherprio = getpriority(PRIO_PROCESS, 0);
  print "# higherprio = $higherprio\n" if ($debug);
  $fail = (not $gothigher or not $higherprio == -5);
  print 'not '
    if ($fail);
  if ($fail) {
    print "# syserr = '$!' (",$!+0,"), ruid = $<, euid = $>\n";
    print "# gothigher = $gothigher, higherprio = $higherprio\n";
  }
  print "ok 3 # (euid = $>) \n";
} else {
  print "ok 3 # skipped (euid = $>)\n";
}

# eof
