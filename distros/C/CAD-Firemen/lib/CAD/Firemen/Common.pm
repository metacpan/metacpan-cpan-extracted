#!/usr/bin/perl
######################
#
#    Copyright (C) 2011 - 2015 TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
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

# Pod::Weaver infos
# ABSTRACT: Shared functions used by other scripts from the Firemen module.

use strict;
use warnings;

package CAD::Firemen::Common;
{
  $CAD::Firemen::Common::VERSION = '0.7.2';
}
use Exporter 'import';
our @EXPORT_OK = qw(
  strip
  print2ColsRightAligned
  testPassed
  testFailed
  maxLength
  printColored
  printBlock
  buildStatistic
  getInstallationPath
  getInstallationConfigCdb
  getInstallationConfigPro
  sharedDir
  installationId
  dbConnect
  loadSettings
  saveSettings
  cleanSvn
);
our %EXPORT_TAGS = (
  PRINTING => [qw(
    print2ColsRightAligned
    testPassed
    testFailed
    maxLength
    printColored
    printBlock
  )]
);
BEGIN {
    if($^O eq "MSWin32"){
      require Win32::Console::ANSI;
    }
}
use POSIX;
use Term::ReadKey;
use Term::ANSIColor;
use File::Path;
use DBI;
use YAML::XS qw(DumpFile LoadFile);
use File::Path qw(rmtree);
use File::Find::Rule;
# Auto reset colors after print line
#$Term::ANSIColor::AUTORESET = 1;

sub strip {
  my $string = shift;
  chomp($string);
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/\s{2,}/ /g;
  return $string;
}

sub untaint {
  my $string = shift;
  if(!defined($string)){
    return "";
  }
  if($string =~ /^([\w\.\s\-\@\:\(\)\!\?\=\+\[\]\$\"\,\|\/\\;~]+)$/gs){
    return $1;
  }
  return "";
}

sub print2ColsRightAligned {
  my $col1Text = untaint(shift);
  my $col2Text = untaint(shift);
  my $col2Color = untaint(shift);
  my $terminalWidth = _terminalWidth();

  if(!defined($col2Color)){
    $col2Color = "";
  }

  my $len = $terminalWidth -  length($col2Text) - 2;
  print sprintf("%-". $len ."s", $col1Text);
  printColored($col2Text, $col2Color);
  print "\n";
}

sub testPassed {
  my $test = shift;
  print2ColsRightAligned($test, "PASSED", "green");
}

sub testFailed {
  my $test = shift;
  print2ColsRightAligned($test, "FAILED", "red");
}

sub maxLength {
  my @list = @_;

  my $max = 0;
  foreach my $elem (@list){
    if(length($elem) > $max){
      $max = length($elem);
    }
  }
  return $max;
}

sub printColored {
  my $text = untaint(shift);
  my $color = untaint(shift);

  if(!defined($text)){
    return;
  }
  if(!defined($color) or ($color eq "")){
    $color = "RESET";
  }

  print colored($text, $color);
  print color 'reset';
}

 sub printBlock {
  my $text = untaint(shift);
  my $indent = untaint(shift);
  my $color = untaint(shift);

  if(!defined($text)){
    return;
  }
  if(!defined($indent)){
    $indent = 0;
  }
  if(!defined($color) or ($color eq "")){
    $color = "RESET";
  }
  # -2 is the linebreak
  my $terminalWidth = _terminalWidth() - 2;
  my $textWidth = $terminalWidth - $indent;

  # remove all linebreaks
  $text =~ s/[\n\r]/ /gs;

  my $start = 0;
  my $end = $textWidth;
  while($start < length($text)){
    my $line = strip(substr($text, $start, $end));
    my $max = $terminalWidth;
    if($textWidth > length($line)){
      $max = length($line) + $indent;
    }
    printColored(sprintf("%". $max ."s", $line), $color);
    print "\n";
    $start += $end;
    # $end is the number of returned characters
    if($start + $end > length($text)){
      $end = length($text) - $start;
    }
  }
}

sub buildStatistic {
  my $label = shift;
  my $value = shift;
  my $max = shift;
  my $result = "";

  if(!defined($label)){
    return $result;
  }
  if(!defined($value)){
    return $result;
  }
  if(!defined($max) || ($max == 0)){
    return $result;
  }

  my $terminalWidth = _terminalWidth() - 2;
  my $relValue = sprintf("%.0f", $value / $max * 100);
  $label .= " [";
  # - 6 is the percent itself (e.g.: " 69%, ")
  my $valueLen = $terminalWidth - length($label) - 1 - 6 - length($value);
  if($valueLen > 100){
    $valueLen = 100;
  }
  my $signs = floor($valueLen * $relValue / 100);
  my $space = $valueLen - $signs;
  $result = "[";
  for(my $i = 0; $i < $signs; $i++){
    $result .= "=";
  }
  $result .= " ". sprintf("%". $space ."s %3s%%, %s", ("", $relValue, $value));
  return $result;
}

sub getInstallationPath {
  my $result = "";
  my @tempPaths = ($ENV{'PATH'} =~ m/;([^;]+(?:proe|creo)[^;]+);/gi);
  my @paths = ();
  # add the paths from config
  my $config = loadSettings();
  if(defined($config)){
    if(exists($config->{"paths"})){
      foreach my $dir (@{$config->{"paths"}}){
        push(@paths, $dir);
      }
    }
  }

  # add path from ENV{PATH}, if not already done
  for(my $i = 0; $i < scalar(@tempPaths); $i++){
    if($tempPaths[$i] =~ m/([\W\w]+)(?:\\|\/)mech(?:\\|\/)bin/i){
      $tempPaths[$i] = $1;
    }
    elsif($tempPaths[$i] =~ m/([\W\w]+)(?:\\|\/)Parametric{0,1}(?:\\|\/)bin$/i){
      $tempPaths[$i] = $1;

      my $alreadyInserted = 0;
      foreach my $existing (@paths){
        if(index($existing, $tempPaths[$i]) != -1){
          $alreadyInserted = 1;
          last;
        }
      }
      if($alreadyInserted){
        $tempPaths[$i] = "";
      }
      else{
        # only search for common files, if path is not already added!
        print "Searching for Common Files directory of installation ". $tempPaths[$i] ."\n";
        my @commonFilesDirectories = File::Find::Rule->name("Common Files")->in($tempPaths[$i]);
        if(scalar(@commonFilesDirectories) == 1){
          testPassed("  Found Common Files for ". $tempPaths[$i]);
          $tempPaths[$i] = $commonFilesDirectories[0];
        }
        else{
          testFailed("  Found Common Files for ". $tempPaths[$i]);
        }
      }
    }
    elsif($tempPaths[$i] =~ m/([\W\w]+)(?:\\|\/)bin$/i){
      $tempPaths[$i] = $1;
    }
    if($tempPaths[$i] ne ""){
      my $add = 1;
      foreach my $existing (@paths){
        if($existing eq $tempPaths[$i]){
          $add = 0;
          last;
        }
      }
      if($add){
        push(@paths, $tempPaths[$i]);
      }
    }
  }

  if(scalar(@paths) == 1){
    $result = $paths[0];
  }
  else{
    @paths = sort(@paths);
    # determine default path
    my $default = 0;
    if(exists($config->{"defaultPath"})){
      for(my $i = 0; $i < scalar(@paths); $i++){
        if($config->{"defaultPath"} eq $paths[$i]){
          $default = $i;
          last;
        }
      }
    }

    print "Possible installations:\n";
    my $max = maxLength(@paths);
    my $i = 0;
    foreach my $dir (@paths){
      print "  ". sprintf("%-". $max ."s", $dir) ." ". $i ."\n";
      $i++;
    }
    print "Or enter -1 to exit.\n";
    print "Please choose one of the installations above [". $default ."]: ";
    my $input = <>;
    $input = strip($input);
    if($input eq ""){
      $input = $default;
    }
    if($input =~ /^\d+$/){
      if(($input >= 0) && ($input < scalar(@paths))){
        $result = $paths[$input];
      }
      else{
        exit 0;
      }
    }
  }

  # add all found paths to config
  $config->{"paths"} = \@paths;
  saveSettings($config);

  return $result;
}

sub getInstallationConfigCdb {
  my $installPath = shift;
  if(!defined($installPath) || ($installPath eq "")){
    $installPath = getInstallationPath();
  }
  if($installPath eq ""){
    return "";
  }
  return $installPath ."/text/config.cdb";
}

sub getInstallationConfigPro {
  my $installPath = shift;
  if(!defined($installPath) || ($installPath eq "")){
    $installPath = getInstallationPath();
  }
  if($installPath eq ""){
    return "";
  }
  return $installPath ."/text/config.pro";
}

sub sharedDir {
  my $dir = "c:/ProgramData/Firemen";
  if(!-d $dir){
    if(!mkpath($dir)){
      return "";
    }
  }
  return $dir;
}

sub installationId {
  my $path = shift;
  if(!defined($path)){
    return "";
   }
  # get most upper folder (root folder) of creo or proe
  if($path =~ m/^.+((?:creo|proe)[^(?:\\|\/)]+).{0,}(M[0-9]{1,})/i){
    $path = $1 ."-". $2;
  }
  else{
    return "";
  }
  $path =~ s/\s/-/g;
  return $path;
}

sub dbConnect {
  my $installation = shift;
  my $verbose = shift;
  my $dbh = undef;
  if(!defined($verbose)){
    $verbose = 0;
  }
  if(!defined($installation)){
    return $dbh;
  }

  $installation = installationId($installation);

  if($installation eq ""){
    return $dbh;
  }

  my $ref = loadSettings();
  my $dbFile = "";
  my %config = ();
  my %dbs = ();
  if(defined($ref)){
    %config = %{$ref};
    if(exists($config{"databases"})){
      %dbs = %{$config{"databases"}};
      if(exists($dbs{$installation})){
        $dbFile = $dbs{$installation};
      }
    }
  }
  if($dbFile eq ""){
    $dbFile = "/options-". $installation .".sqlite";
    $dbs{$installation} = $dbFile;
    $config{"databases"} = \%dbs;
    saveSettings(\%config);
  }

  $dbFile = sharedDir() . $dbFile;
  my $printError = 0;
  if($verbose > 1){
    $printError = 1;
  }
  # we commit our self, to be much faster
  $dbh = DBI->connect(
    "dbi:SQLite:". $dbFile,
    "",
    "",
    {PrintError => $printError, RaiseError => 0, AutoCommit => 0}
  );
  if(!$dbh){
    if($verbose > 0){
      print "Could not connect to database ". $dbFile ."\n";
    }
    return 0;
  }
  return $dbh;
}

sub loadSettings {
  my $file = _settingsFile();
  my $result;
  if(!-e $file){
    return $result;
  }
  return LoadFile($file);
}

sub saveSettings {
  my $settingsRef = shift;
  if(!defined($settingsRef)){
    return 0;
  }
  return DumpFile(_settingsFile(), $settingsRef);
}

sub cleanSvn {
  my $dir = shift;
  rmtree("$dir/.svn");
  local *DIR;
  opendir DIR, $dir or die "opendir $dir: $!";
  for (readdir DIR) {
    next if /^\.{1,2}$/;
    my $path = "$dir/$_";
    cleanSvn($path) if -d $path;
  }
  closedir DIR;
}

sub _settingsFile {
  return sharedDir() ."/config.yml";
}

sub _terminalWidth {
  my $terminalWidth = 100;
  eval{
    my @tmp = GetTerminalSize();
    if(defined($tmp[0])){
      $terminalWidth = $tmp[0];
    }
  };
  return $terminalWidth;
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen::Common - Shared functions used by other scripts from the Firemen module.

=head1 VERSION

version 0.7.2

=head1 METHODS

=head2 strip

Strips out whitespaces at the beginning and the end of the given string.
It also removes double whitespaces.

=head2 untaint

to untaint the string, it strip outs any escape sequences (without \n), to make the string more secure (taint mode)

=head2 print2ColsRightAligned

Prints the string within the first parameter on the far left of the screen.
The second paremeter is printed on the far right of the screen in the color
of optional third parameter. See Term::ANSIColor for the names of the colors.

=head2 testPassed

Prints the content of the first parameter on the far left screen side
and "PASSED" in green on the far right.

=head2 testFailed

Prints the content of the first parameter on the far right side
and "FAILED" in red on the far right.

=head2 maxLength

Returns the lenght of the longest string within the
given array as first parameter.

=head2 printColored

Prints the given text in the given color. The main reason to use this function is to
use Win32::Console within this module.

=head2 printBlock

Prints a text block with an specified indentation.

=head2 buildStatistic

Builds a bar of = to display a percentage value of the ratio between $value and $max.

=head2 getInstallationPath

Method parses $ENV{PATH} and tries to filter out all Firemen related paths.
Afterwards, if more than one is found, the user can select which one he wants
to use. This one is returned than.

The returned path DOES NOT ends with a slash!

=head2 getInstallationConfigCdb

Uses getInstallationConfigPath() to return the full path to the related config.cdb.
You may specify the installation path to get the related config.pro. If not given, it uses
getInstallationPath() to guess or ask one.

=head2 getInstallationConfigPro

Uses getInstallationConfigPath() to return the full path to the related config.pro.
You may specify the installation path to get the related config.pro. If not given, it uses
getInstallationPath() to guess or ask one.

=head2 sharedDir

Returns the path to the shared directory where all modules and scripts of this
distribution places their files.

If it does not exists, it creates it.

=head2 installationId

Compuates an installation identifier out of the creo installation path.
This ID is used e. g. to create the database name.

=head2 dbConnect

Creates a connection to the database and returns the reference to the DBI object
or 0 if an error occurs. If the database does not exists an empty database file
is created.

If you want to insert data, make sure that you use the commit function, since
AutoCommit is disabled.

The database layout is described in fm_create_help.

=head2 loadSettings

Loads the settings from config file and returns a reference to the hash.

Most possible settings are explained at CAD::Firemen (Use perldoc CAD::Firemen).

=head2 saveSettings

Saves the Hash, which reference is given into the config file.

=head2 cleanSvn

Method to delete all .svn directories borrowed from http://snipplr.com/view/27050/ with small change (introduced rmtree)

=head2 _settingsFile
FOR INTERNAL USE ONLY!

Returns the file path to the config file.
Use loadSettings() and saveSettings() to get and store settings

=head2 _terminalWidth
FOR INTERNAL USE ONLY!

Returns the terminal width.

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
