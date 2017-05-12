#
# setrlimit.t
#

use BSD::Resource;

# use strict;

my @LIM = sort keys %{ get_rlimits() };

print "1..", scalar @LIM, "\n";;

my $test_no = 1;

for my $lim (@LIM) {
    print "# lim = $lim\n";
    if ($^O =~ /^netbsd/ &&
	$lim eq 'RLIMIT_STACK') {
      # NetBSD:
      # - RLIMIT_STACK exists, but setrlimit calls on it fail.
      print "ok $test_no # SKIP $^O $lim\n";
    } elsif ($^O =~ /^cygwin/ &&
	     # Cygwin:
	     # - NOFILE/OFILE/OPEN_MAX: setrlimit calls succeed,
	     #   but then the subsequent getrlimit calls return
	     #   the old value before the setrlimit call.  So the
	     #   setrlimit seems to be faking its success.
	     # - STACK: the soft values (which we use for testing)
	     #   seem to be some strange portion of the hard value
	     #   (which is 8MB, or 0x800000), namely 0x5fbf83 or
	     #   0.748032 of the max.  And our tests tries to get
	     #   0.75 of that, and trying to setrlimit that miserably
	     #   fails.
	     $lim =~ /^RLIMIT_(NOFILE|OFILE|OPEN_MAX|STACK)/) {
	print "ok $test_no # SKIP $^O $lim\n";
    } else {
      my ($old_soft, $old_hard) = getrlimit($lim);
      print "# old_soft = $old_soft, old_hard = $old_hard\n";
      my ($try_soft,  $try_hard ) =
	map { ($_ == RLIM_INFINITY) ?
		RLIM_INFINITY : int(0.75 * $_) }
	  ($old_soft, $old_hard);
      print "# try_soft = $try_soft, try_hard = $try_hard\n";
      # If either the soft or the hard limit is the RLIM_INFINITY,
      # don't bother testing because whether that succeeds depends
      # on too many factors (which OS, which user).
      if ($try_soft == RLIM_INFINITY) {
	print "ok $test_no # SKIP soft_limit == RLIM_INFINITY\n";
      } elsif ($try_hard == RLIM_INFINITY) {
	print "ok $test_no # SKIP hard_limit == RLIM_INFINITY\n";
      } else {
	if ($lim =~
	    /^RLIMIT_(FSIZE|DATA|STACK|CORE|RSS|MEMLOCK|AS|VMEM|AIO_MEM)/) {
	  my $n = 4096;
	  print "# Rounding down to $n byte boundary\n";
	  ($try_soft, $try_hard) =
	    map { int($_ / $n) * $n } ($try_soft, $try_hard);
	}
	print "# try_soft = $try_soft, try_hard = $try_hard\n";
	my $success = setrlimit($lim, $try_soft, $try_hard);
	if ($success) {
	  print "# setrlimit($lim, $try_soft) = OK\n";
	  my $new_soft = getrlimit($lim);
	  print "# getrlimit($lim) = $new_soft\n";
	  # ASSUMPTION: setrlimit() requests are rounded DOWN, not up.
	  if (($new_soft > 0 || $old_soft == 0) && $new_soft <= $try_soft) {
	    print "ok $test_no # $try_soft <= $new_soft\n";
	  } else {
	    print "not ok $test_no # $try_soft > $new_soft\n";
	  }
	} else {
	  print "not ok $test_no # setrlimit($lim, $try_soft, $try_hard) failed: $!\n";
	}
      }
    }
    $test_no++;
}

exit(0);

