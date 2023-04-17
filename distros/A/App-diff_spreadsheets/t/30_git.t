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
        "identical files -> no output",
        "-m", "git"
       );

runtest("$tlib/Addrlist.xlsx",
        "$tlib/Multisheet.xlsx[AddrListSheet]",
        "", "", 0,
        "1-sheet & multi-sheet[sheetname] (no diffs)",
        "-m", "git"
       );

runtest("$tlib/Addrlist.xlsx", 
        "$tlib/Multisheet.xlsx!AddrListSheet",
        "", "", 0,
        "1-sheet & multi-sheet!sheetname (no diffs)",
        "-m", "git"
       );

runtest("$tlib/presidents.xlsx",
        "$tlib/presidents.csv",
        "", "", 0,
        "1-sheet & csv (no diffs)",
        "-m", "git"
       );

runtest("$tlib/Addrlist.xlsx",
        "$tlib/Multisheet.xlsx!PresidentsSheet",
        qr/./, "", 1,
        "Exit status 1 when diffs found",
        "-m", "git"
       );

# By default it uses --color-words output, so be careful to ignore color escapes
runtest("$tlib/Addrlist.xlsx",
        "$tlib/Addrlist_mod1.xlsx",
        qr{diff.*a/Addrlist.xlsx.*b/Addrlist_mod1.xlsx
           .*
           \@\@\ -1,4\ \+1,5\ \@\@.*\n
           "FIRST\ NAME",.*\n
           John,Brown.*\n
           .*Lucretia.*,,PA.*,Philadelphia,PA,19133.*\n
           Harriet.*\n
           .*Frederick,Douglass
         }xs,
        "", 1,
          "Changed row and Added rows",
        "-m", "git"
       );

runtest("$tlib/Multisheet.xlsx",
        "$tlib/Multisheet2.xlsx",
        qr{\A\*\*\*\ sheet\ 'OtherSheetA'\ exists\ ONLY.*Multisheet.xlsx\n
           .*
           \*\*\*\ sheet\ 'OtherSheetB'\ exists\ ONLY.*Multisheet2.xlsx\n
           .*
           diff.*a/Multisheet.xlsx\[AddrListSheet\].*b/Multisheet2.xlsx\[AddrListSheet\]
           .*
           \@\@\ -1,4\ \+1,4\ \@\@.*\n
           "FIRST\ NAME",.*\n
           John,Brown.*\n
           .*Lucretia.*,,PA.*,bogon,PA,19133.*\n
           Harriet.*\n
         }xs,
         "", 2, # exit 2 due to unmatched sheet names
        "some sheets with unique names",
        "-m", "git"
       );

done_testing;

