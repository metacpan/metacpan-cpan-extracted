#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon qw/bug run_perlscript/; # Test2::V0 etc.
# N.B. Can not use :silent because it breaks Capture::Tiny
use t_dsUtils qw/runtest $progname $progpath/;

use Spreadsheet::Edit::IO 1000.001 ();
my $can_cvt_spreadsheets    = Spreadsheet::Edit::IO::can_cvt_spreadsheets();
my $can_extract_named_sheet = Spreadsheet::Edit::IO::can_extract_named_sheet();
my $can_extract_allsheets   = Spreadsheet::Edit::IO::can_extract_allsheets();

if (!$can_extract_named_sheet) {
  plan(skip_all => "External tools (Libre Office) not installed or too old");
}

my $tlib = "$Bin/../tlib";

use open ':std', IO => ':encoding(UTF-8)';

BEGIN {
  $ENV{COLUMNS} = 60;  # for fixed-width test ouput
}

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
        qr{^[\s\n]*\
---+ Changed row 3 ---+
        CITY: '' →  'Philadelphia'

---+ ADDED row 5 ---+
  FIRST NAME: 'Frederick'
   LAST NAME: 'Douglass'
    Address1: 'Mount Hope Cemetary'
    Address2: '1133 Mt Hope Ave'
        CITY: 'Rochester'
       STATE: 'NY'
         ZIP: '14620'
[\s\n]*$},
        "", 1,
          "Changed row and Added rows",
        "-m", "native"
       );

runtest("$tlib/Multisheet.xlsx[EmptySheet]",
        "$tlib/Multisheet.xlsx[EmptySheet]",
        "", "", 0,
        "Identical empty sheets (not even titles)",
        "-m", "native"  # explictly specify method
       );

runtest("$tlib/Multisheet.xlsx[EmptySheet]",
        "$tlib/Multisheet2.xlsx[OneCellOnly]",
        qr{^[\s\n]*\
---+ Changed row 1 ---+
 +\(col A\): '' →  'xyzzx'
[\s\n]*$},
        "", 1,
        "Completely empty sheet vs. Title-only",
        "-m", "native"  # explictly specify method
       );

runtest("$tlib/Multisheet.xlsx",
        "$tlib/Multisheet2.xlsx",
        qr/.* \*\*\*\ *Sheet.*EmptySheet.*exists\ ONLY\ in.*Multisheet.xlsx
           .* \*\*\*\ *Sheet.*OneCellOnly.*exists\ ONLY\ in.*Multisheet2.xlsx
           .* \*\*\*\ *SHEET\ "?AddrListSheet"?\ *\*\*\*
           .* ----*\ Changed\ +row\ +3\ .*
           .* CITY.*:.*'bogon'
          /isx, "", 2,
        "some sheets with unique names",
        "-m", "native"  # explictly specify method
      );

done_testing;

