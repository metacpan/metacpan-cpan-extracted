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
  use_ok( 'CAD::Firemen::Analyze', qw(checkTreeConfig) ) || print "Bail out!\n";

  is(checkTreeConfig(), 0, "Everything undefined");
  is(checkTreeConfig(""), 0, "Url empty");
  is(checkTreeConfig("asdasd"), 0, "Wrong  url");
  is(checkTreeConfig($FindBin::Bin ."/../corpus/tree-malformed.cfg"), 0, "Malformed tree config");
  is(runRedirected(\&checkTreeConfig, $FindBin::Bin ."/../corpus/tree-malformed.cfg", 1), 0, "Malformed tree config, verbose 1");
  is(checkTreeConfig($FindBin::Bin ."/../corpus/tree-ok.cfg"), 1, "Everything ok, verbose 0");
  is(runRedirected(\&checkTreeConfig, $FindBin::Bin ."/../corpus/tree-ok.cfg", 1), 1, "Everything ok, verbose 1");
}

diag( "Testing checkTreeConfig from CAD::Firemen::Analyze $CAD::Firemen::Analyze::VERSION, Perl $], $^X" );
