#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon qw/bug run_perlscript/; # Test2::V0 etc.
# N.B. Can not use :silent because it breaks Capture::Tiny

use Capture::Tiny qw/capture/;

my $progname = "diff_spreadsheets";
my $progpath = "$Bin/../bin/$progname";

# Allow the program to find lib/App/diff_spreadsheets.pm during casual
# testing with perl -Ilib t/...
$ENV{PERL5LIB} = join(':',$ENV{PERL5LIB},@INC);

note "## progpath=$progpath";

ok(-x $progpath, "Found the script");

# Every single cpantesters test fails with errors like
#   Can't load '/opt/perl-5.37.10/lib/5.37.10/x86_64-linux/auto/Fcntl/Fcntl.so'
# What is going on???

{ my $wstat = run_perlscript $progpath, devnull(), devnull();
  ok($wstat==0, "status==0 for $progname devnull devnull");
}

# Test arg help
{ my ($out, $err, $wstat) = capture{ run_perlscript $progpath };

  ok($out eq "", "$progname sans args -> silent on stdout but...",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
    
  like($err, qr/Usage/, "$progname sans args -> Usage on stderr",
         dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
}

{ my ($out, $err, $wstat) = capture{ run_perlscript $progpath, "-h" };

  like($out, qr/NAME.*SYNOPSIS.*OPTIONS/s, "$progname -h => Extended help on stdout",
         dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));

  ok($err eq "", "$progname -h => nothing on stderr",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
}

# Detecting functional errors
{ my $nepath = " non existent file .csv";
  my ($out, $err, $wstat) = capture {
    die "oops" if -e $nepath;
    run_perlscript $progpath, devnull(), $nepath;
  };
  ok($out eq "", "$progname diags should only be on stderr",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
  
  like($err, qr/\Q$nepath\E.*(missing|no such)/i, "$progname catches non-existent file",
       dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat));
}

done_testing;

