#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon qw/bug run_perlscript/; # Test::More etc.
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
{ my $wstat = run_perlscript $progpath;
  ok($wstat==(2<<8), "$progname sans args WITHOUT CAPTURE");
}

{ my ($out, $err, $wstat) = capture{ run_perlscript $progpath };

  ok($out eq "", "$progname sans args -> silent on stdout but...")
    &&
  like($err, qr/Usage/, "$progname sans args -> Usage on stderr")
    || diag dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat);
}

{ my ($out, $err, $wstat) = capture{ run_perlscript $progpath, "-h" };

  like($out, qr/NAME.*SYNOPSIS.*OPTIONS/s, 
       "$progname -h => Extended help on stdout")
    || diag dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat);

  ok($err eq "", "$progname -h => nothing on stderr")
    || diag dvis '\n  $out\n  $err\n  ', sprintf("  wstat=%04x\n", $wstat);
}

done_testing;

