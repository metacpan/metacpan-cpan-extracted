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

use Test::More tests => 24;
use strict;
use warnings;
use FindBin;
use File::Basename;
use lib dirname(__FILE__);

=method runRedirected

Redirects STDOUT to a local variable, executes the given function (reference) and attaches
all supplied arguments. The return is the return of the called method.

This is useful to test functions which call the print function.

=cut
sub runRedirected{
  my $subRef = shift;
  my ($exitCode, $stdout) = runRedirectedAll($subRef, @_);
  return $exitCode;
}

=method runRedirectedAll

This method returns the exit code of the executed method and the output of stdout

=cut
sub runRedirectedAll{
  my $subRef = shift;
  my $stdout;
  my $result;
  {
    local *STDOUT;
    open STDOUT, '>', \$stdout
        or die "Cannot open STDOUT to a scalar: $!";
    $result = $subRef->(@_);
    close STDOUT
        or die "Cannot close redirected STDOUT: $!";
  }
  return ($result, $stdout);
}

BEGIN {
  # include Diff module
  use_ok( 'CAD::Firemen::Analyze', qw(checkConfig) ) || print "Bail out!\n";

  is(checkConfig(), 0, "Everything undefined");
  is(checkConfig("cdbUrl" => "", "cfgUrl" => ""), 0, "Both urls empty");
  is(checkConfig("cdbUrl" => "asd"), 0, "Wrong cdb url, undefined cdf url");
  is(checkConfig("cdbUrl" => "asd", "cfgUrl" => ""), 0, "Wrong cdb url, empty cdf url");
  is(checkConfig("cdbUrl" => "asd", "cfgUrl" => "asdasd"), 0, "Wrong cdb url, wrong cfg url");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-malformed.cdb", "cfgUrl" => ""), 0, "Malformed CDB");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-malformed.cdb", "cfgUrl" => "", "verbose" => 3), 0, "Malformed CDB, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-new.cdb",  "cfgUrl" => $FindBin::Bin ."/../corpus/config-new.pro"), 0, "Malformed config");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-new.cdb",  "cfgUrl" => $FindBin::Bin ."/../corpus/config-new.pro", "verbose" => 3), 0, "Malformed config, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-ok.pro", "verbose" => 0), 1, "Everything ok, verbose 0");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-ok.pro", "verbose" => 3), 1, "Everything ok, verbose 3");

  # test all checked errors
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-compare.pro"), 0, "Compare");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-compare.pro", "verbose" => 3), 0, "Compare, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-values-case.pro"), 0, "Values case sensitive");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-values-case.pro", "verbose" => 3), 0, "Values case sensitive, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-values-case.pro", "caseInsensitive" => 1), 1, "Values case sensitive");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-values-case.pro", "caseInsensitive" => 1, "verbose" => 3), 1, "Values case sensitive, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-values-emptyfs.pro"), 0, "Values empty fs");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-values-emptyfs.pro", "verbose" => 3), 0, "Values empty fs, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfigcdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-duplicates.pro"), 0, "Duplicates");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfigcdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-duplicates.pro", "verbose" => 3), 0, "Duplicates, verbose 3");
  is(checkConfig("cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-absolutepaths.pro"), 0, "No absolute paths");
  is(runRedirected(\&checkConfig, "cdbUrl" => $FindBin::Bin ."/../corpus/config-checkConfig.cdb", "cfgUrl" => $FindBin::Bin ."/../corpus/config-error-absolutepaths.pro", "verbose" => 3), 0, "No absolute paths, verbose 3");
}

diag( "Testing checkConfig from CAD::Firemen::Analyze $CAD::Firemen::Analyze::VERSION, Perl $], $^X" );
