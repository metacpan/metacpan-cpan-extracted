#!/usr/bin/perl -t
######################
#
#    Copyright (C) 2011  TU Clausthal, Institut für Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

use Test::More tests => 64;
use FindBin;
use strict;
use warnings;

BEGIN {
  # include Diff module
  use_ok( 'CAD::Firemen::Analyze', qw(compare) ) || print "Bail out!\n";
  use_ok( 'CAD::Firemen::Load', qw(loadConfig) ) || print "Bail out!\n";
  use_ok( 'CAD::Firemen::Change' ) || print "Bail out!\n";

  # expected result tree
  my %expAdded = ("WEB_BROWSER_HOMEPAGE" => 22);
  my %expChanged = (
    "BELL" => [new CAD::Firemen::Change("name" => "BELL")],
    "PRO_UNIT_LENGTH" => [new CAD::Firemen::Change("name" => "PRO_UNIT_LENGTH")],
    "PROMPT_ON_EXIT" => [new CAD::Firemen::Change("name" => "PROMPT_ON_EXIT")]
  );
  my %expRemoved = (
    "SHOW_SHADED_EDGES" => 35,
    "UI_THEME" => 37
  );

  # compare
  my ($resultRef, $errorRef, $parsedLines) = loadConfig($FindBin::Bin ."/../corpus/config-old.pro");
  my %cfg1Options = %{$resultRef};
  my %cfg1Errors = %{$errorRef};
  ($resultRef, $errorRef, $parsedLines) = loadConfig($FindBin::Bin ."/../corpus/config-new.pro");
  my %cfg2Options = %{$resultRef};
  my %cfg2Errors = %{$errorRef};
  my ($ref1, $ref2, $ref3, $ref4) = compare(\%cfg1Options, \%cfg2Options);
  my %resAdded = %{$ref1};
  my %resChanged = %{$ref2};
  my %resRemoved = %{$ref3};
  my %duplicates = %{$ref4};

  is(scalar(keys(%resAdded)), scalar(keys(%expAdded)), "All added options found");
  is(scalar(keys(%resChanged)), scalar(keys(%expChanged)), "All changed options found");
  is(scalar(keys(%resRemoved)), scalar(keys(%expRemoved)), "All removed options found");
  foreach my $opt (keys(%resAdded)){
    my $found = 0;
    foreach my $opt1(keys(%expAdded)){
      if(($opt eq $opt1) && ($resAdded{$opt} eq $expAdded{$opt1})){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Added option ". $resAdded{$opt} ." is found");
  }
  foreach my $opt (keys(%resChanged)){
    my $found = 0;
    foreach my $opt1(keys(%expChanged)){
      if($opt eq $opt1){
       is(scalar(@{$resChanged{$opt}}), scalar(@{$expChanged{$opt}}), "Correct changes per option ". $opt ." found");
        $found = 1;
        last;
      }
    }
    is($found, 1, "Changed option ". $opt ." is found");
  }
  foreach my $opt (keys(%resRemoved)){
    my $found = 0;
    foreach my $opt1(keys(%expRemoved)){
      if(($opt eq $opt1) && ($resRemoved{$opt} eq $expRemoved{$opt1})){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Removed option ". $resRemoved{$opt} ." is found");
  }

  # another example with changed duplicates
  # expected result tree
  %expAdded = (
    "FRT_ENABLED" => 100,
    "PEN_TABLE_FILE" => 103,
    "PDF_USE_PENTABLE" => 106,
    "BMGR_PREF_FILE" => 109,
    "DEFAULT_DRAW_SCALE" => 112,
    "SKETCHER_LOCK_MODIFIED_DIMS" => 115,
    "MASS_PROPERTY_CALCULATE" => 119,
    "TOLERANCE_STANDARD" => 122,
    "WELD_UI_STANDARD" => 125,
    "PRO_MATERIAL_DIR" => 128
  );
  %expChanged = (
    "DISPLAY" => [new CAD::Firemen::Change(
      "name" => "DISPLAY",
      "valueOld" => "HIDDENVIS",
      "valueNew" => "SHADE"
    )],
    "DRAWING_SETUP_FILE" => [new CAD::Firemen::Change(
      "name" => "DRAWING_SETUP_FILE",
      "valueOld" => "\$PRO_DIRECTORY\\text\\din.dtl",
      "valueNew" => "\$PRO_DIRECTORY\\text\\imw_din.dtl"
    )],
    "MDL_TREE_CFG_FILE" => [new CAD::Firemen::Change(
      "name" => "MDL_TREE_CFG_FILE",
      "valueOld" => "\$PRO_DIRECTORY\\text\\tree.cfg",
      "valueNew" => "\$PRO_DIRECTORY\\text\\imw_tree.cfg"
    )],
    "TEMPLATE_DESIGNASM" => [new CAD::Firemen::Change(
      "name" => "TEMPLATE_DESIGNASM",
      "valueOld" => "\$PRO_DIRECTORY\\templates\\mmns_asm_design.asm",
      "valueNew" => "\$PRO_DIRECTORY\\templates\\imw_mmns_asm_design.asm"
    )],
    "TEMPLATE_SOLIDPART" => [new CAD::Firemen::Change(
      "name" => "TEMPLATE_SOLIDPART",
      "valueOld" => "\$PRO_DIRECTORY\\templates\\mmns_part_solid.prt",
      "valueNew" => "\$PRO_DIRECTORY\\templates\\imw_mmns_part_solid.prt"
    )],
    "TRAIL_DIR" => [new CAD::Firemen::Change(
      "name" => "TRAIL_DIR",
      "valueOld" => "C:\\Trail-13",
      "valueNew" => "C:\\Trail"
    )],
    "PROTKDAT" => [
      new CAD::Firemen::Change(
        "name" => "PROTKDAT",
        "valueOld" => "D:\\Program Files\\ANSYS Inc\\v130\\aisol\\CADIntegration\\\$ANSYS_PROEWF_VER130\\ProEPages\\config\\WBPlugInPE.dat",
        "valueNew" => "\$CADENAS/iface/proewildfire/win/protkwf5_64.dat"
      ),
      new CAD::Firemen::Change(
        "name" => "PROTKDAT",
        "valueOld" => "\$PROMIF_ACN130\\protk.dat",
        "valueNew" => "D:\\Program Files\\ANSYS Inc\\v121\\AISOL\\CAD Integration\\\$ANSYS_PROEWF_VER121\\ProEPages\\config\\WBPlugInPE.dat"
      ),
      new CAD::Firemen::Change(
        "name" => "PROTKDAT",
        "valueOld" => "NOT AVAILABLE",
        "valueNew" => "\$PROMIF_ACN121\\protk.dat"
      )
    ]
  );
  %expRemoved = (
    "SPIN_CONTROL" => 10,
    "DRAWING_FILE_EDITOR" => 55,
    "SKETCHER_INTENT_MANAGER" => 85
  );
  my %expDuplicates = (
    "PROTKDAT" => "Duplicated in second config at lines 99, 98, 95"
  );
  ($resultRef, $errorRef, $parsedLines) = loadConfig($FindBin::Bin ."/../corpus/config-changed-doubles-old.pro");
  %cfg1Options = %{$resultRef};
  %cfg1Errors = %{$errorRef};
  ($resultRef, $errorRef, $parsedLines) = loadConfig($FindBin::Bin ."/../corpus/config-changed-doubles-new.pro");
  %cfg2Options = %{$resultRef};
  %cfg2Errors = %{$errorRef};
  ($ref1, $ref2, $ref3, $ref4) = compare(\%cfg1Options, \%cfg2Options);
  %resAdded = %{$ref1};
  %resChanged = %{$ref2};
  %resRemoved = %{$ref3};
  my %resDuplicates = %{$ref4};

  is(scalar(keys(%resAdded)), scalar(keys(%expAdded)), "All added options found");
  is(scalar(keys(%resChanged)), scalar(keys(%expChanged)), "All changed options found");
  is(scalar(keys(%resRemoved)), scalar(keys(%expRemoved)), "All removed options found");
  is(scalar(keys(%resDuplicates)), scalar(keys(%expDuplicates)), "All duplicated options found");
  foreach my $opt (keys(%resAdded)){
    my $found = 0;
    foreach my $opt1(keys(%expAdded)){
      if(($opt eq $opt1) && ($resAdded{$opt} eq $expAdded{$opt1})){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Added option ". $resAdded{$opt} ." is found");
  }
  foreach my $opt (keys(%expChanged)){
    my $found = 0;
    foreach my $opt1(keys(%resChanged)){
      if($opt eq $opt1){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Changed option ". $opt ." exists");
    if($found){
      is(scalar(@{$resChanged{$opt}}), scalar(@{$expChanged{$opt}}), "Correct changes per option ". $opt ." found");
      for(my $i = 0; $i < scalar(@{$resChanged{$opt}}); $i++){
        is($resChanged{$opt}->[$i]->valueOld(), $expChanged{$opt}->[$i]->valueOld(), "Correct value old of option ". $opt ." changeset ". $i);
        is($resChanged{$opt}->[$i]->valueNew(), $expChanged{$opt}->[$i]->valueNew(), "Correct value new of option ". $opt ." changeset ". $i);
      }
    }
  }
  foreach my $opt (keys(%resRemoved)){
    my $found = 0;
    foreach my $opt1(keys(%expRemoved)){
      if(($opt eq $opt1) && ($resRemoved{$opt} eq $expRemoved{$opt1})){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Removed option ". $resRemoved{$opt} ." is found");
  }
}

diag( "Testing comparing of Configs with CAD::Firemen::Analyze $CAD::Firemen::Analyze::VERSION, Perl $], $^X" );
