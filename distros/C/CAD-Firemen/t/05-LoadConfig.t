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

use Test::More tests => 60;
use FindBin;
use strict;
use warnings;

BEGIN {
  # include LoadFiles module
  use_ok( 'CAD::Firemen::Load', qw(loadConfig) ) || print "Bail out!\n";

  # expected result tree
  my %expOptions = (
    "BELL" => {10 => "NO"},
    "DISPLAY_FULL_OBJECT_PATH" => {13 => "YES"},
    "PRO_UNIT_LENGTH" => {16 => "UNIT_M"},
    "FILE_OPEN_DEFAULT_FOLDER" => {19 => "working_directory"},
    "WEB_BROWSER_HOMEPAGE" => {22 => "d:\\Program Files\\BLA\\Common Files\\F000\\templates\\webseite\\index.html"},
    "PROMPT_ON_EXIT" => {26 => "NO"},
    "LINEAR_TOL_0.000" => {29 => "5"},
    "TEMPLATE_DESIGNASM" => {32 => "\$PRO_DIRECTORY\\templates\\imw_mmns_asm_design.asm"},
    "TODAYS_DATE_NOTE_FORMAT" => {35 => "%yyyy-%mm-%dd"}
  );

  my %expErrors = ();
  $expErrors{7} = "Detected uncommented line without an option";

  # test wrong usage
  my ($resultsRef, $errorsRef, $lines) = loadConfig();
  my %results = %{$resultsRef};
  my %errors = %{$errorsRef};
  is(scalar(keys(%results)), 0, "No results without a file");
  is(scalar(keys(%errors)), 1, "1 error given without a file");
  is($lines, 0, "No parsed lines without a file");
  ($resultsRef, $errorsRef, $lines) = loadConfig("");
  %results = %{$resultsRef};
  %errors = %{$errorsRef};
  is(scalar(keys(%results)), 0, "No results without a file");
  is(scalar(keys(%errors)), 1, "1 error given without a file");
  is($lines, 0, "No parsed lines without a file");
  ($resultsRef, $errorsRef, $lines) = loadConfig("asdasd");
  %results = %{$resultsRef};
  %errors = %{$errorsRef};
  is(scalar(keys(%results)), 0, "No results with non existent file");
  is(scalar(keys(%errors)), 1, "1 error given with non existent file");
  is($lines, 0, "No parsed lines without a file");

  # load the file
  ($resultsRef, $errorsRef, $lines) = loadConfig($FindBin::Bin ."/../corpus/config-new.pro");
  %results = %{$resultsRef};
  %errors = %{$errorsRef};

  is($lines, 35, "Parsed lines");
  is(scalar(keys(%results)), scalar(keys(%expOptions)), "Matching option counts");
  is(scalar(keys(%errors)), scalar(keys(%expErrors)), "Matching errors");

  foreach my $opt (keys(%expOptions)){
    # checking that option and its value exists
    is(exists($results{$opt}), 1, "Existence of option ". $opt);
    my @expKeys = keys(%{$expOptions{$opt}});
    my @gotKeys = keys(%{$results{$opt}});
    is(scalar(@expKeys), scalar(@gotKeys), "Matching found value numbers of ". $opt);
    foreach my $line (@expKeys){
      is(exists($results{$opt}->{$line}), 1, "Existence of value of option ". $opt ." in line ". $line);
      # check that they have the same value and
      is($results{$opt}->{$line}, $expOptions{$opt}->{$line}, "Correct value for option ". $opt ." in line ". $line);
      # check the line number
      is($results{$opt}->{$line}, $expOptions{$opt}->{$line}, "Correct line number of option ". $opt ." in line ". $line);
    }
  }

  # testing errors
  foreach my $error (keys(%expErrors)){
    is(exists($errors{$error}), 1, "Existence of error ". $error);
    is($errors{$error}, $expErrors{$error}, "Correct value for error ". $error);
  }
}

diag( "Testing CAD::Firemen::Load::loadConfig $CAD::Firemen::Load::VERSION, Perl $], $^X" );
