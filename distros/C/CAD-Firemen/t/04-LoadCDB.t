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

use Test::More tests => 51;
use FindBin;
use strict;
use warnings;

BEGIN {
  # include LoadFiles module
  use_ok( 'CAD::Firemen::Load', qw(loadCDB) ) || print "Bail out!\n";

  my $fileOk = $FindBin::Bin ."/../corpus/config-new.cdb";
  my $fileMalformed = $FindBin::Bin ."/../corpus/config-malformed.cdb";
  my %result = ();
  my %errors = ();
  # expected result tree
  my %expResults = (
    "2D_PALETTE_PATH" => {
      3 => {
        "( -Fs )" => 0
      }
    },
    "ACCESSORY_WINDOW_DISPLAY" => {
      7 => {
        "UNDOCKED" => 0,
        "DOCKED" => 0
      }
    },
    "ACIS_EXPORT_PARAMS" => {
      12 => {
        "YES" => 0,
        "NO" => 0
      }
    },
    "ACIS_EXPORT_UNITS" => {
      19 => {
        "in" => 0,
        "ft" => 0,
        "m" => 0,
        "mm" => 0,
        "cm" => 0,
        "MICRON" => 0,
        "EFAULT" => 0
      }
    },
    "ACIS_OUT_VERSION" => {
      29 => {
        4 => 0,
        5 => 0
      }
    },
    "DEPTHCUE_VALUE" => {
      34 => {
        "YES" => 0,
        "NO" => 0
      }
    }
  );


  # test wrong usage
  my ($ref1, $ref2) = loadCDB();
  %result = %{$ref1};
  %errors = %{$ref2};
  is(scalar(keys(%result)), 0, "No results without a file");
  is(scalar(keys(%errors)), 1, "1 error given without a file");
  ($ref1, $ref2) = loadCDB("");
  %result = %{$ref1};
  %errors = %{$ref2};
  is(scalar(keys(%result)), 0, "No results without a file");
  is(scalar(keys(%errors)), 1, "1 error given without a file");
  ($ref1, $ref2) = loadCDB("asdasd");
  %result = %{$ref1};
  %errors = %{$ref2};
  is(scalar(keys(%result)), 0, "No results with non existent file");
  is(scalar(keys(%errors)), 1, "1 error given with non existent file");
  ($ref1, $ref2) = loadCDB($fileMalformed);
  %result = %{$ref1};
  %errors = %{$ref2};
  is(scalar(keys(%result)), scalar(keys(%expResults)), "All options found");
  is(scalar(keys(%errors)), 1, "Wrong error number with existent malformed file");
  #is(exists($errors{33}), 1, "Wrong error line number ". join(", ", keys(%errors)));
  is(exists($errors{33}), 1, "Wrong error line number ". join(", ", keys(%errors)));

  # load the file
  ($ref1, $ref2) = loadCDB($fileOk);
  %result = %{$ref1};
  %errors = %{$ref2};

  is(scalar(keys(%result)), scalar(keys(%expResults)), "All options found");
  foreach my $opt (keys(%expResults)){
    # check that option was recognized
    is(exists($result{$opt}), 1, "Existence of option ". $opt);
    is(scalar(keys(%{$result{$opt}})), scalar(keys(%{$expResults{$opt}})), "Same number of lines found");
    foreach my $line (keys(%{$expResults{$opt}})){
      # check that the line is correct
      is(exists($result{$opt}->{$line}), 1, "Line exists");
      # check each parameters of the options
      my %values = %{$result{$opt}->{$line}};
      my %expValues = %{$expResults{$opt}->{$line}};
      is(scalar(keys(%values)), scalar(keys(%expValues)), "Number of values of option ". $opt);
      foreach my $expValue (keys(%expValues)){
        is(exists($values{$expValue}), 1, "Existence of value ". $expValue);
      }
    }
  }
}

diag( "Testing CAD::Firemen::Load::loadCDB $CAD::Firemen::Load::VERSION, Perl $], $^X" );
