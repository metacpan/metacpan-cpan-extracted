#!/usr/bin/perl -t
######################
#
#    Copyright (C) 2011 - 2015 TU Clausthal, Institut für Maschinenwesen, Joachim Langenbach
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

use Test::More tests => 14;
use FindBin;
use File::Copy qw(move);
use strict;
use warnings;
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
  use_ok(
    'CAD::Firemen::Common',
    qw(
      strip
      maxLength
      getInstallationPath
      getInstallationConfigCdb
      getInstallationConfigPro
      printColored
      print2ColsRightAligned
      testPassed
      testFailed
    )
  ) || print "Bail out!\n";

  # strip
  my $string = " this is a     string with many   white spaces at the    beginning    and the end   and in between    ";
  is(strip($string), "this is a string with many white spaces at the beginning and the end and in between", "Too much spaces left");

  # untaint
  $string = "c:\\PROGRA~2\\PTC\\Creo 3.0\\help";
  is(CAD::Firemen::Common::untaint($string), $string);
  $string = "This is a string with a ; in it, which is totaly ok";
  is(CAD::Firemen::Common::untaint($string), $string);

  # maxLength
  my @test = qw(wirklichamlaengsten laenger kurz nochlaenger);
  is(maxLength(@test), length($test[0]), "wirklichamlaengsten not the longest");

  # we must clear the config file before
  my $origFile = CAD::Firemen::Common::_settingsFile();
  my $backupFile = $origFile .".backup";
  move($origFile, $backupFile);
  # testing getInstallationPath, ...ConfigCDB, ...ConfigPro
  $ENV{PATH} = "C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem;C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\;D:\\Program Files\\proeWildfire 5.0\\bin;D:\\Program Files\\proeWildfire 5.0\\mech\\bin";
  is(getInstallationPath(), "D:\\Program Files\\proeWildfire 5.0", "Get wrong installation path");
  is(getInstallationConfigCdb(), "D:\\Program Files\\proeWildfire 5.0/text/config.cdb", "Get wrong config.cdb");
  is(getInstallationConfigPro(), "D:\\Program Files\\proeWildfire 5.0/text/config.pro", "Get wrong config.pro");
  # restore config file
  move($backupFile, $origFile);

  # testing print methods

  # printColored
  my ($result, $output) = runRedirectedAll(\&printColored, "Test", "red");
  #is($output, "[31mTest[0m", "Testing print colored");
  is($output, "[31mTest[0m[0m", "Testing print colored");

  # print2ColsRightAligned
  ($result, $output) = runRedirectedAll(\&print2ColsRightAligned, "Super Test", "Result", "green");
  # because of the failing GetTerminalSize() during the test run, we must use the default value of 100
  my $width = 100 -  length("Result") - 2;
  $result = sprintf("%-". $width ."s", "Super Test") ."[32mResult[0m[0m
";
  is($output, $result, "print2ColsRightAligned");

  ($result, $output) = runRedirectedAll(\&print2ColsRightAligned, "Super Test", "Result");
  # because of the failing GetTerminalSize() during the test run, we must use the default value of 100
  $width = 100 -  length("Result") - 2;
  $result = sprintf("%-". $width ."s", "Super Test") ."[0mResult[0m[0m
";
  is($output, $result, "print2ColsRightAligned, without color");

  # testPassed and testFailed
  ($result, $output) = runRedirectedAll(\&testPassed, "Super Test");
  # because of the failing GetTerminalSize() during the test run, we must use the default value of 100
  $width = 100 -  length("PASSED") - 2;
  $result = sprintf("%-". $width ."s", "Super Test") ."[32mPASSED[0m[0m
";
  is($output, $result, "testPassed");
    ($result, $output) = runRedirectedAll(\&testFailed, "Super Test");
  # because of the failing GetTerminalSize() during the test run, we must use the default value of 100
  $width = 100 -  length("FAILED") - 2;
  $result = sprintf("%-". $width ."s", "Super Test") ."[31mFAILED[0m[0m
";
  is($output, $result, "testFailed");

  $string = "Load Config \$ 1? = \"(c:\\asdasd/asdasd!), | + [10]";
  ($result, $output) = runRedirectedAll(\&testPassed, $string);
  $width = 100 -  length("PASSED") - 2;
  $result = sprintf("%-". $width ."s", $string). "[32mPASSED[0m[0m
";
  is($output, $result, "testPassed - special chars");
}

diag( "Testing CAD::Firemen::Common $CAD::Firemen::Common::VERSION, Perl $], $^X" );
