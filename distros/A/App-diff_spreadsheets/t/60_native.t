#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon qw/bug run_perlscript/; # Test::More etc.
# N.B. Can not use :silent because it breaks Capture::Tiny
use t_dsUtils qw/runtest $progname $progpath/;

my $tlib = "$Bin/../tlib";

# runtest($in1, $in2, $exp_out, $exp_err, $exp_exit, $desc)

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
        "some sheets with unique names",
        "-m", "native"  # explictly specify method
      );

done_testing;

