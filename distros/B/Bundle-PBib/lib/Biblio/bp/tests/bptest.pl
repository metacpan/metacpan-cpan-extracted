#!/usr/bin/perl

# Test package routines for bp

if (defined $bib'glb_bpprefix) {
  # We've already loaded bp.
} else {
  unshift(@INC, $ENV{'BPHOME'})  if defined $ENV{'BPHOME'};
  require "bp.pl";
  $| = 1;
  $screenlength = 80;
  $screenoffsetdots  = 30;
  $screenoffsetlcomp = 10;
  # If you're modifying the bp package itself,
  # set them:  1,1,'print'
  # Otherwise, 0,0,'ignore'
  $detail_errors = 1;
  $exitonerror = 0;
  $bperrors = 'print';  # ignore or print
}


sub testcharset {
  local($name, $tests) = @_;

  &bib'load_charset($name);
  &begintest("$name routines", $tests);
}

sub begintest {
  local($tname, $tests) = @_;

  local($outstr) = "testing $tname" . "." x $screenlength;
  print substr($outstr, 0, $screenlength-$screenoffsetdots-$tests);
  $failed = 0;
  $starttime = (times)[0];
}

sub endtest {

  local($add);
  $endtime = (times)[0];
  $add = sprintf(" (%.2f seconds)\n", $endtime - $starttime);
  if ($failed == 0) {
    print " ok$add";
  } elsif ($failed == 1) {
    print " 1 error$add\n";
  } else {
    print " $failed errors$add\n";
  }
}


# check(OPTIONS, FUNCTION_NAME, EXPR, LIST)
#
# This function calls the routine named in FUNCTION_NAME with the
# arguments given in LIST, and expects an answer of EXPR.  If it does
# not receive the answer, it handles outputing the result to the user
# if that is asked for (detailed error checking).  The global variable
# $failed is also incremented on failure.
#
# OPTIONS is a comma seperated list of options to the check function.
#
#   nodetail	indicates no details will be printed.
#   nostatus	indicates no status symbol (. or x) will be printed.
#   norun	indicates that this is just a comparison check, so the
#   		FUNCTION_NAME is not a function and will not be run.
#   partial	is the same as nodetail,norun.
#
# Begin with a '<' if you don't want to print details on an error.
# Begin with a '-' if you don't want to print a status symbol.
# Begin with a ':' if you don't want a routine run.
#
# It returns the function result regardless of success or failure.
#
# Limitations: We can't test routines that return a list.
#
sub check {
  local($options, $routine, $output, @input) = @_;
  local($noprint, $nodetails, $res);

  die("No arguments to check!") unless defined $routine;
  $options =~ s/\bpartial\b/,nodetail,norun,/;
  $nodetails = $options =~ /\bnodetail\b/;
  $noprint   = $options =~ /\bnostatus\b/;
  if ($options =~ /\bnorun\b/) {
    $res = join('', @input);
    @input = ($output);
  } else {
    die("Check: given undefined function $routine") unless defined &$routine;
    $res = &$routine(@input);
  }

  if ($res eq $output) {
    print "." unless $noprint;
    return $res;
  }
  print "x" unless $noprint;

  $failed++;

  if ($detail_errors && !$nodetails) {
    local($outstr) = "\n$routine(" . join(",", @input)
                   . ") = '$res' instead of '$output'\n";
    if (length($outstr) > (20 * $screenlength) ) {
      print "\n$routine failed.  Output is too long to print (", length($outstr), " chars).\n";
    } elsif (length($outstr) > 120) {
      print "\n$routine failed.  Output comparison:\n";
      &longcomp($output, $res);
    } else {
      print $outstr;
    }
  }

  die "\nExiting on error.\n" if $exitonerror;
  $res;
}

sub longcomp {
  local($i, $o) = @_;
  local($pi, $po, $n, $ostr);
  local($llength) = $screenlength-$screenoffsetlcomp;

  return if $i eq $o;

  $i =~ s/[\x00-\x1F]/./g;
  $o =~ s/[\x00-\x1F]/./g;
  print "Long comparison:";
  while (length($i) > 0) {
    $pi = substr($i, 0, $llength); substr($i, 0, $llength) = '';
    $po = substr($o, 0, $llength); substr($o, 0, $llength) = '';
    print "\nexp: $pi";
    print "\ngot: $po\n";
    next if $pi eq $po;
    $ostr = "     ";
    foreach $n (0..$llength) {
      $ostr .= ( substr($pi,$n,1) eq substr($po,$n,1) ) ? " " : "^";
    }
    print $ostr;
  }
  print "\n";
}

#
# MSRNG package
#
$mr_a = 48271;
$mr_m = 2147483647;
$mr_q = 44488;
$mr_r = 3399;

sub mrand {
  local($max) = @_;
  local($lo, $hi, $test);

  $max = 1 unless defined $max;
  $hi = int($mr_seed / $mr_q);
  $lo = int($mr_seed % $mr_q);
  $test = int( ($mr_a * $lo) - ($mr_r * $hi) );
  $mr_seed = ($test > 0) ? $test : $test + $mr_m;
  $max * ($mr_seed / $mr_m);
}

sub msrand {
  local($seed) = @_;

  if (defined $seed) {
    $mr_seed = $seed;
  } else {
    if (    -r "/dev/urandom"
         && open(DEVRANDFILE, "/dev/urandom")
         && (sysread(DEVRANDFILE, $mr_seed, 4) == 4) ) {
      # /dev/urandom is a fast source of good random numbers.
      $mr_seed = unpack("L", $mr_seed);
      close(DEVRANDFILE);
    } elsif (    -r "/dev/random"
              && open(DEVRANDFILE, "/dev/random")
              && (sysread(DEVRANDFILE, $mr_seed, 4) == 4) ) {
      # /dev/random can be slow, but it gives crypto quality numbers.
      $mr_seed = unpack("L", $mr_seed);
      close(DEVRANDFILE);
    } elsif (-x "/etc/pstat") {
      # This is a good way to get the seed on Sun systems
      $mr_seed = unpack("%32L*", `/etc/pstat -pfS`);
    } elsif (-r "/proc/interrupts" && -r "/proc/uptime") {
      # For Linux systems without /dev/random.  Very uniform.
      $mr_seed = unpack("%32L*", `cat /proc/[1-9]*/stat /proc/interrupts /proc/uptime`);
    } else {
      # If pstat isn't available, this seems to have the best distribution.
      $mr_seed = int(time + (times)[0] ^ $$);
    }
  }
  $mr_seed;
}

sub unctrl {
        local($_) = @_;
        s/([\001-\037\177])/'^'.pack('c',ord($1)^64)/eg;
        $_;
}


1;
