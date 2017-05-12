#!/usr/bin/perl -t
# need -t here, because Devel::CoveR::DB::IO::JSON has some problems here
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

use Test::More tests => 59;
use FindBin;
use strict;
use warnings;

BEGIN {
  # include Change module
  use_ok( 'CAD::Firemen::Change' ) || print "Bail out!\n";

  # testing constructor without arguments
  my $change = new CAD::Firemen::Change();
  is($change->option(), "", "Option is not empty");
  is($change->valueOld(), "", "Old value is not empty");
  is($change->valueNew(), "", "New value is not empty");
  is($change->changeType(), 0, "Asked for undefined change type");
  is($change->changeType(CAD::Firemen::Change::Type->NoChange), 1, "Change type is NoChange");
  is($change->changeType(CAD::Firemen::Change::Type->NoSpecial), 0, "Change type is not NoSpecial");
  is($change->changeType(CAD::Firemen::Change::Type->Path), 0, "Change type is not Path");
  is($change->changeType(CAD::Firemen::Change::Type->Case), 0, "Change type is not Case");
  is($change->changeType(CAD::Firemen::Change::Type->ValuesChanged), 0, "Change type is not ValuesChanged");
  is($change->changeType(CAD::Firemen::Change::Type->DefaultValueChanged), 0, "Change type is not DefaultValueChanged");
  is($change->changeDescription(), "", "Empty description");
  is(scalar(@{$change->possibleValuesOld()}), 0, "No possible old values");
  is(scalar(@{$change->possibleValuesNew()}), 0, "No possible new values");
  is($change->defaultValueOld(), "", "No old default value");
  is($change->defaultValueNew(), "", "No new default value");
  is($change->evalChange(), 1, "Testing evalChange() with default values");

  # testing constructor with default values
  my $name = "OPTION_NAME";
  my $valueOld = "OLD_VALUE";
  my $valueNew = "NEW_VALUE";
  $change = new CAD::Firemen::Change(
    "name" => $name,
    "valueOld" => $valueOld,
    "valueNew" => $valueNew
  );
  is($change->option(), $name, "Option is not empty");
  is($change->valueOld(), $valueOld, "Old value is not empty");
  is($change->valueNew(), $valueNew, "New value is not empty");
  is($change->changeType(CAD::Firemen::Change::Type->NoSpecial), 1, "Change type is NoSpecial");

  # testing set functions
  my $posValuesOld = ["Test1", "test2", "test3"];
  my $posValuesNew = ["Test2", "test2", "test10"];
  $change = new CAD::Firemen::Change();
  is($change->setOption($name), 1, "Option not set (setOption($name))");
  is($change->option(), $name, "Option not set (option() ne $name)");
  is($change->setOption(), 0, "Option not set (setOption())");
  is($change->setValueOld($valueOld), 1, "Old value not set (setValueOld($valueOld))");
  is($change->valueOld(), $valueOld, "Old value not set (valueOld() ne $valueOld)");
  is($change->setValueOld(), 0, "Old value not set (setValueOld())");
  is($change->setValueNew($valueNew), 1, "New value not set (setValueNew($valueNew))");
  is($change->valueNew(), $valueNew, "New value not set (valueNew() ne $valueNew)");
  is($change->setValueNew(), 0, "New value not set (setValueNew())");
  is($change->setPossibleValuesOld(), 0, "Set old possible values (setPossibleValuesOld())");
  is($change->setPossibleValuesOld("Test"), 0, "Set old possible values (setPossibleValuesOld(test))");
  is($change->setPossibleValuesOld($posValuesOld), 1, "Set old possible values");
  is(@{$change->possibleValuesOld()}, @{$posValuesOld}, "Get possible old values");
  is($change->setPossibleValuesNew(), 0, "Set old possible values (setPossibleValuesNew())");
  is($change->setPossibleValuesNew("Test"), 0, "Set old possible values (setPossibleValuesNew(test))");
  is($change->setPossibleValuesNew($posValuesNew), 1, "Set new possible values");
  is(@{$change->possibleValuesNew()}, @{$posValuesNew}, "Get possible new values");
  is($change->setDefaultValueOld("asdasd"), 0, "Set not existing old default value");
  is($change->setDefaultValueOld("test3"), 1, "Set existing old default value");
  is($change->setDefaultValueNew("asdasd"), 0, "Set not existing new default value");
  is($change->setDefaultValueNew("test10"), 1, "Set existing new default value");

  # testing eval changes, changeType and highlightColor
  $change = new CAD::Firemen::Change();
  $change->setValueOld("VALUE_OLD");
  $change->setValueNew("VALUE_NEW");
  is($change->evalChange(), 1, "evalChanges()");
  is($change->changeType(CAD::Firemen::Change::Type->NoSpecial), 1, "changeType() was not set correctly be evalChanges() (CAD::Firemen::Change::Type->NoSpecial)");
  is($change->highlightColor(), "YELLOW", "highlightColor() is evaluated correctly (Firemen::Change::Type->NoSpecial)");
  $change = new CAD::Firemen::Change();
  $change->setValueOld("VALUE_old");
  $change->setValueNew("VALUE_OLD");
  is($change->evalChange(), 1, "evalChanges()");
  is($change->changeType(CAD::Firemen::Change::Type->Case), 1, "changeType() is set correctly be evalChanges() (CAD::Firemen::Change::Type->Case)");
  is($change->highlightColor(), "CYAN", "highlightColor is evaluated correctly (Firemen::Change::Type->Case)");
  $change = new CAD::Firemen::Change();
  $change->setValueOld("c:\\test\\test.txt");
  $change->setValueNew("d:\\test_changed\\test__changed.txt");
  is($change->evalChange(), 1, "evalChanges()");
  is($change->changeType(CAD::Firemen::Change::Type->Path), 1, "changeType() is set correctly be evalChanges() (CAD::Firemen::Change::Type->Path)");
  is($change->highlightColor(), "MAGENTA", "highlightColor is evaluated correctly (CAD::Firemen::Change::Type->Path)");
  $change = new CAD::Firemen::Change();
  $change->setValueOld("VALUE_OLD");
  $change->setValueNew("VALUE_OLD");
  is($change->evalChange(), 1, "evalChanges()");
  is($change->changeType(CAD::Firemen::Change::Type->NoChange), 1, "changeType() is set correctly be evalChanges()");
  is($change->highlightColor(), "YELLOW", "highlightColor is evaluated correctly (CAD::Firemen::Change::Type->NoChange)");

  # testing eval changes with possible and default values
  $change = new CAD::Firemen::Change();
  $change->setValueOld("VALUE_OLD");
  $change->setValueNew("VALUE_NEW");
  $change->setPossibleValuesOld($posValuesOld);
  $change->setPossibleValuesNew($posValuesNew);
  $change->setDefaultValueNew("test3");
  $change->setDefaultValueNew("test10");
  is($change->evalChange(), 1, "evalChanges()");
  is($change->changeType(CAD::Firemen::Change::Type->NoSpecial), 1, "changeType() is set correctly by evalChanges() (CAD::Firemen::Change::Type->NoSpecial)");
  is($change->changeType(CAD::Firemen::Change::Type->ValuesChanged), 1, "changeType() is set correctly by evalChanges() (CAD::Firemen::Change::Type->ValuesChanged)");
  is($change->changeType(CAD::Firemen::Change::Type->DefaultValueChanged), 1, "changeType() is set correctly by evalChanges() (CAD::Firemen::Change::Type->DefaultValueChanged)");
  is($change->highlightColor(), "YELLOW", "highlightColor() is evaluated correctly (CAD::Firemen::Change::Type->NoSpecial)");
}

diag( "Testing CAD::Firemen::Change $CAD::Firemen::Change::VERSION, Perl $], $^X" );