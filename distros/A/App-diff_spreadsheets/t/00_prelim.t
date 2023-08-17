#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon qw/bug run_perlscript $silent $debug/; # Test2::V0 etc.
# N.B. Can not use :silent because it breaks Capture::Tiny

use Capture::Tiny qw/capture/;
use Env qw/@PERL5LIB/; # ties @PERL5LIB

my $progname = "diff_spreadsheets";
my $progpath = path("$Bin/../bin/$progname")->canonpath;

## Allow the program to find lib/App/diff_spreadsheets.pm during casual
## testing with perl -Ilib t/...
#if (defined $ENV{PERL5LIB}) {
#  push @PERL5LIB, @INC;
#}

note "## progpath=",u($progpath);

ok(defined($progpath) && -e $progpath, "Found the script");

if ($^O ne "MSWin32") {
  ok(-x $progpath, "Script is executable");
}

# On Windows, the 'nul' device (from File::Spec->devnull) does not behave
# like /dev/null on unix; attempts to copy from 'nul' fail with "No such file"
# So create a real empty file to read from.
my $empty = Path::Tiny->tempfile(); $empty->spew("");

# Every single cpantesters test fails with errors like
#   Can't load '/opt/perl-5.37.10/lib/5.37.10/x86_64-linux/auto/Fcntl/Fcntl.so'
# What is going on???

{ my $wstat = run_perlscript $progpath, $empty, $empty;
  ok($wstat==0, "status==0 for $progname emptyfile emptyfile");
}

# Test arg help
{ my ($out, $err, $wstat) = capture{ run_perlscript $progpath };

  ok($out eq "", "$progname sans args -> silent on stdout but...",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
    
  like($err, qr/Usage/, "$progname sans args -> Usage on stderr",
         dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
}

{ my ($out, $err, $wstat) = capture{ run_perlscript $progpath, "-h" };

  # Sometimes NAME, SYNOPSIS etc. are overprinted e.g. S\bSY\bY...
  # so check for other text
  #like($out, qr/NAME.*SYNOPSIS.*OPTIONS/s, "$progname -h => Extended help on stdout",
  #       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
  like($out, qr/diff_spreadsheet.*OPTION/s, "$progname -h => Extended help on stdout",
         dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));

  if ($debug) {
     warn "Out:$out\nErr:$err\n";
  } else {
    ok($err eq "", "$progname -h => nothing on stderr",
         dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
  }
}

# Detecting functional errors
{ my $nepath = " non existent file .csv";
  my ($out, $err, $wstat) = capture {
    die "oops" if -e $nepath;
    run_perlscript $progpath, $empty, $nepath;
  };
  ok($out eq "", "$progname diags should only be on stderr",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
  
  like($err, qr/\Q$nepath\E.*(missing|no such)/i, "$progname catches non-existent file",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
}

done_testing;

