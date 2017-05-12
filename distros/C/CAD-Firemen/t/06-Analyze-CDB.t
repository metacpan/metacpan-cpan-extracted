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

use Test::More tests => 8;
use FindBin;
use strict;
use warnings;

BEGIN {
  # include Diff module
  use_ok( 'CAD::Firemen::Analyze', qw(compare) ) || print "Bail out!\n";
  use_ok( 'CAD::Firemen::Load', qw(loadCDB) ) || print "Bail out!\n";

  # expected result tree
  my %expAdded = ();
  my %expChanged = ();
  my %expRemoved = ();

  %expAdded = ("ACCESSORY_WINDOW_DISPLAY" => 7);

  %expRemoved = (
    "THIS_OPTION_DOES_NOT_EXISTS_IN_NEW_CDB" => 7,
    "THIS_OPTION_DOES_NOT_EXISTS_IN_NEW_CDB_TOO" => 12
  );

  # compare
  my ($ref, $lines) = loadCDB($FindBin::Bin ."/../corpus/config-old.cdb");
  my %old = %{$ref};
  ($ref, $lines) = loadCDB($FindBin::Bin ."/../corpus/config-new.cdb");
  my %new = %{$ref};
  my ($ref1, $ref2, $ref3) = compare(\%old, \%new);
  my %resAdded = %{$ref1};
  my %resChanged = %{$ref2};
  my %resRemoved = %{$ref3};

  is(scalar(keys(%resAdded)), scalar(keys(%expAdded)), "All added options found");
  is(scalar(keys(%resChanged)), scalar(keys(%expChanged)), "All changed options found");
  is(scalar(keys(%resRemoved)), scalar(keys(%expRemoved)), "All removed options found");
  foreach my $opt (keys(%resAdded)){
    my $found = 0;
    foreach my $opt1(keys(%expAdded)){
      if($opt eq $opt1){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Added option is added");
  }
  foreach my $opt (keys(%resChanged)){
    my $found = 0;
    foreach my $opt1(keys(%expChanged)){
      if($opt eq $opt1){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Changed option is added");
  }
  foreach my $opt (keys(%resRemoved)){
    my $found = 0;
    foreach my $opt1(keys(%expRemoved)){
      if($opt eq $opt1){
        $found = 1;
        last;
      }
    }
    is($found, 1, "Removed option is added");
  }
}

diag( "Testing comparing of CDBs with CAD::Firemen::Analyze $CAD::Firemen::Analyze::VERSION, Perl $], $^X" );
