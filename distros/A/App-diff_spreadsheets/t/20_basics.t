#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon qw/bug run_perlscript/; # Test::More etc.
# N.B. Can not use :silent because it breaks Capture::Tiny

use Capture::Tiny qw/capture/;

my $tlib = "$Bin/../tlib";

my $progname = "diff_spreadsheets";
my $progpath = "$Bin/../bin/$progname";

sub runtest($$$$$$) {
  my ($in1, $in2, $exp_out, $exp_err, $exp_exit, $desc) = @_;
  my ($out, $err, $wstat) = capture{ run_perlscript $progpath, $in1, $in2 };
  my @m;
  if (ref $exp_out) {
    push @m, "stdout wrong (!~ $exp_out)" if $out !~ /$exp_out/;
  } else {
    push @m, "stdout wrong (ne '$exp_out')" if $out ne $exp_out;
  }
  if (ref $exp_err) {
    push @m, "stderr wrong (!~ $exp_err)" if $err !~ /$exp_err/;
  } else {
    push @m, "stderr wrong (ne '$exp_err')" if $err ne $exp_err;
  }
  if ($wstat != ($exp_exit << 8)) {
    push @m, "exit status wrong (not $exp_exit)"
  }
  if (@m) {
    my ($lno) = (caller(0))[2];
    diag sprintf("%s at line %d: wstat=0x%04x", join(";\n  ",@m), $lno, $wstat),
         dvis('\n   $out\n   $err\n');
  }
  @_ = (@m==0, $desc);
  goto &Test::More::ok
}

runtest("$tlib/presidents.xlsx",
        "$tlib/presidents.xlsx",
        "", "", 0,
        "identical files -> no output");

runtest("$tlib/Addrlist.xlsx",
        "$tlib/Multisheet.xlsx[AddrListSheet]",
        "", "", 0,
        "1-sheet & multi-sheet[sheetname] (no diffs)");

runtest("$tlib/Addrlist.xlsx", 
        "$tlib/Multisheet.xlsx!AddrListSheet",
        "", "", 0,
        "1-sheet & multi-sheet!sheetname (no diffs)");

runtest("$tlib/presidents.xlsx",
        "$tlib/presidents.csv",
        "", "", 0,
        "1-sheet & csv (no diffs)");

runtest("$tlib/Addrlist.xlsx",
        "$tlib/Multisheet.xlsx!PresidentsSheet",
        qr/./, "", 1,
        "Exit status 1 when diffs found");

runtest("$tlib/Addrlist.xlsx",
        "$tlib/Addrlist_mod1.xlsx",
        qr/.* Changed\ +row\ +3:.*CITY.*Philadelphia
           .* ADDED\ +row\ +5:
           .* FIRST\ NAME.*:.*Frederick
           .* LAST\ NAME.*:.*Douglass
          /sx, "", 1, 
          "Changed row and Added rows");

runtest("$tlib/Multisheet.xlsx",
        "$tlib/Multisheet2.xlsx",
        qr/.* \*\*\*\ *Sheet.*OtherSheetA.*exists\ ONLY\ in.*Multisheet.xlsx
           .* \*\*\*\ *Sheet.*OtherSheetB.*exists\ ONLY\ in.*Multisheet2.xlsx
           .* \*\*\*\ *AddrListSheet\ *\*\*\*
           .* Changed\ +row\ +3:
           .* CITY.*:.*bogon
          /isx, "", 2,
        "some sheets with unique names");

done_testing;

