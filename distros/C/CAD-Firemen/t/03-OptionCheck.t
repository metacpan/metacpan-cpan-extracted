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

use Test::More tests => 13;
use FindBin;
use strict;
use warnings;

BEGIN {
  # include Check module
  use_ok( 'CAD::Firemen::Option::Check' ) || print "Bail out!\n";

  my $name = "SUPER OPTION";
  my $errorString = "ERROR STRING";
  my $check = new CAD::Firemen::Option::Check();
  is($check->setOption(), 0, "Test setOption()");
  is($check->setOption($name), 1, "Test setOption(\$name)");
  is($check->option(), $name, "Test option() = \$name");
  is($check->setErrorString(), 0, "Test setErrorString()");
  is($check->setErrorString($errorString), 1, "Test setErrorString(\$errorString)");
  is($check->errorString(), $errorString, "Test errorString()= \$errorString");
  is($check->setCase(), 0, "Test setCase()");
  is($check->setCase(1), 1, "Test setCase(1)");
  is($check->case(), 1, "Test case() = 1");

  $check = new CAD::Firemen::Option::Check("name" => $name, "errorString" => $errorString, "case" => 1);
  is($check->option(), $name, "Test new(name)");
  is($check->errorString(), $errorString, "Test new(errorString)");
  is($check->case(), 1, "Test new(case)");
}

diag( "Testing CAD::Firemen::Option::Check $CAD::Firemen::Option::Check::VERSION, Perl $], $^X" );
