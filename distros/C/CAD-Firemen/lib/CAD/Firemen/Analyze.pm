#!/usr/bin/perl
######################
#
#    Copyright (C) 2011  TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
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
# ABSTRACT: Module provides functions to compare to lists with options (and values)

use strict;
use warnings;

package CAD::Firemen::Analyze;
{
  $CAD::Firemen::Analyze::VERSION = '0.7.2';
}
use Exporter 'import';
our @EXPORT_OK = qw(compare checkConfig checkTreeConfig optionsToIngoreAtPathCheckings);
use POSIX;
use File::Spec;

use CAD::Firemen::Change;
use CAD::Firemen::Common qw(print2ColsRightAligned printBlock maxLength testPassed testFailed printColored strip);
use CAD::Firemen::Load qw(loadCDB loadConfig loadDatabase);
use CAD::Firemen::Option::Check;

sub compare {
  my %options1 = ();
  my %options2 = ();
  my $refOptions1 = shift;
  my $refOptions2 = shift;

  # result variables
  my %added = ();
  my %changed = ();
  my %removed = ();
  my %duplicates = ();

  if(!defined($refOptions1)){
    return (\%added, \%changed, \%removed, \%duplicates);
  }
  if(!defined($refOptions2)){
    return (\%added, \%changed, \%removed, \%duplicates);
  }
  %options1 = %{$refOptions1};
  %options2= %{$refOptions2};

  # Compare the options
  # get the options, which are set in config 2 and not in config 1 (added)
  # also determine changed options
  foreach my $opt (sort(keys(%options2))){
    if(scalar(keys(%{$options2{$opt}})) > 1){
      $duplicates{$opt} = "Duplicated in second config at lines ". join(", ", keys(%{$options2{$opt}})) .".";
    }
    if(!exists($options1{$opt})){
      my @keys = keys(%{$options2{$opt}});
      $added{$opt} = $keys[0];
    }
    else{
      if(scalar(keys(%{$options1{$opt}})) > 1){
        if(exists($duplicates{$opt})){
          $duplicates{$opt} .= " ";
        }
        else{
          $duplicates{$opt} = "";
        }
        $duplicates{$opt} .= "Duplicated in first config at lines ". join(", ", keys(%{$options1{$opt}})) .".";
      }
      # evalute changes and assume, that the order is not changed
      # @TODO Get those combination of changes, with less changes
      #        e.g. a change with Case only is smaller change than NoSpecial and so on
      my $max = $options1{$opt};
      my $min = $options2{$opt};
      my @keys1 = sort(keys(%{$options1{$opt}}));
      my @keys2 = sort(keys(%{$options2{$opt}}));
      if(ref($options1{$opt}->{$keys1[0]}) eq "HASH"){
        # it's the format of the cdb files, do not try to detect changes
        next;
      }
      if(scalar(@keys1) < scalar(@keys2)){
        $max = $options2{$opt};
        $min = $options1{$opt};
      }
      for(my $i = 0; $i < scalar(keys(%{$max})); $i++){
        my $change = new CAD::Firemen::Change("name" => $opt);
        if($i < scalar(keys(%{$min}))){
          $change->setValueOld($options1{$opt}->{$keys1[$i]});
          $change->setValueNew($options2{$opt}->{$keys2[$i]});
        }
        else{
          if(scalar(@keys1) < scalar(@keys2)){
            $change->setValueOld("NOT AVAILABLE");
            $change->setValueNew($options2{$opt}->{$keys2[$i]});
          }
          else{
            $change->setValueOld($options1{$opt}->{$keys1[$i]});
            $change->setValueNew("NOT AVAILABLE");
          }
        }
        $change->evalChange();
        if(!$change->changeType(CAD::Firemen::Change::Type->NoChange)){
          if(!exists($changed{$opt})){
            $changed{$opt} = [];
          }
          push(@{$changed{$opt}}, $change);
        }
      }
    }
  }

  foreach my $opt (sort(keys(%options1))){
    if(!exists($options2{$opt})){
      my @keys = keys(%{$options1{$opt}});
      $removed{$opt} = $keys[0];
    }
  }

  return (\%added, \%changed, \%removed, \%duplicates);
}

sub optionsToIngoreAtPathCheckings {
  # allowed options with relative paths
  # (it is only checked, whether the key exists, the value is ignored)
  my %allowedRelativePaths = ();
  $allowedRelativePaths{"TRAIL_DIR"} = 1;
  $allowedRelativePaths{"PROTKDAT"} = 1;
  return %allowedRelativePaths;
}

sub optionsToIngoreAtDuplicatesCheckings {
  # allowed options with relative paths
  # (it is only checked, whether the key exists, the value is ignored)
  my %allowedDuplicates = ();
  $allowedDuplicates{"PROTKDAT"} = 1;
  return %allowedDuplicates;
}

sub checkConfig {
  my (%params) = @_;
  my $dbh = $params{"databaseHandle"};
  my $cdbUrl = $params{"cdbUrl"};
  my $cfgUrl = $params{"cfgUrl"};
  my $caseInsensitive = $params{"caseInsensitive"};
  my $verbose = $params{"verbose"};
  my $description = $params{"description"};

  # allowed options with relative paths
  # (it is only checked, whether the key exists, the value is ignored)
  my %allowedRelativePaths = optionsToIngoreAtPathCheckings();

  # allowed options with occurence greater one
  my %allowedDuplicates = optionsToIngoreAtDuplicatesCheckings();

  my %options = ();
  my %descriptions = ();
  my %resultsCompare = ();
  my %resultsDuplicates = ();
  my %resultsWrongValues = ();
  my %resultsAbsolutePaths = ();
  my %resultsDefaultValues= ();
  my $checkResult = 1;

  if(!defined($verbose)){
    $verbose = 0;
  }
  if(!defined($caseInsensitive)){
    $caseInsensitive = 0;
  }
  if(!defined($description)){
    $description = 0;
  }

  if(!defined($dbh) && (!defined($cdbUrl) || $cdbUrl eq "")){
    return 0;
  }

  if(!defined($cfgUrl) || $cfgUrl eq ""){
    return 0;
  }

  if($verbose > 2){
    if($dbh){
      print "Database:      ". $dbh->{Name} ."\n";
    }
    print "CDB URL:       ". $cdbUrl ."\n";
    print "Config URL:    ". $cfgUrl ."\n";
  }

  if(!defined($dbh)){
    my ($ref1, $ref2) = loadCDB($cdbUrl, $verbose);
    %options = %{$ref1};
    my %errorsCDB = %{$ref2};
    if(scalar(keys(%errorsCDB))){
      if($verbose > 0){
        testFailed("Load CDB");
      }
      if($verbose > 1){
        print "Errors while parsing ". $cdbUrl .":\n";
        my @lines = sort { $a <=> $b } keys(%errorsCDB);
        my $max = length($lines[scalar(@lines) - 1]);
        foreach my $line (@lines){
          printColored(sprintf("%". $max ."s", $line) .": ". $errorsCDB{$line} ."\n", "red");
        }
      }
      return 0;
    }
  }
  else{
    my ($ref1, $ref2, $ref3) = loadDatabase($dbh, "SELECT * FROM options", $verbose);
    %options = %{$ref1};
    my %errors = %{$ref2};
    %descriptions = %{$ref3};
    if(scalar(keys(%errors))){
      if($verbose > 0){
        testFailed("Query Database");
      }
      if($verbose > 1){
        print "Errors whilequerying the database ". $dbh->{Name} .":\n";
        my @lines = sort { $a <=> $b } keys(%errors);
        my $max = length($lines[scalar(@lines) - 1]);
        foreach my $line (@lines){
          printColored(sprintf("%". $max ."s", $line) .": ". $errors{$line} ."\n", "red");
        }
      }
      return 0;
    }
  }

  if($verbose > 0){
    my $name = $cdbUrl;
    if($dbh){
      $name = $dbh->{Name};
    }
    print2ColsRightAligned("Load Options from ". $name,  scalar(keys(%options)), "green");
  }
  if($verbose > 2){
    foreach my $key (sort(keys(%options))){
      print $key ."\n";
      foreach my $param (sort(keys(%{$options{$key}}))){
        print "   ". $param;
        if($options{$param}){
          print " (Default)";
        }
        print "\n";
      }
    }
  }

  # Load the config.pro file and check, if there are not supported options
  my ($resultRef, $errorRef, $parsedLines) = loadConfig($cfgUrl);
  my %cfgOptions = %{$resultRef};
  my %errors = %{$errorRef};
  if(scalar(keys(%errors)) < 1){
    if($verbose > 0){
      testPassed("Load Config (Lines: ". $parsedLines .", Options: ". scalar(keys(%cfgOptions)) .")");
    }
  }
  else{
    if($verbose > 0){
      testFailed("Load Config");
    }
    if($verbose > 1){
      my @lines = sort { $a <=> $b } keys(%errors);
      my $length = length($lines[scalar(@lines) - 1]);
      foreach my $line (@lines){
        print sprintf("%". $length ."s", $line) .": ". $errors{$line} ."\n";
      }
    }
    return 0;
  }

  foreach my $opt (keys(%cfgOptions)){
    # check of existence
    if(!exists($options{$opt})){
      my @lines = keys(%{$cfgOptions{$opt}});
      $resultsCompare{$lines[0]} = new CAD::Firemen::Option::Check(
        "name" => $opt,
        "errorString" => "The option ". $opt ." is not listed in given cdb"
      ); "The option ". $opt ." is not listed in given cdb";
    }
    else{
      foreach my $line (keys(%{$cfgOptions{$opt}})){
        # checks whether the given value is supported
        if(scalar(keys(%{$options{$opt}})) > 0){
          my $found = 0;
          my $case = 0;
          my @cdbKeys = keys(%{$options{$opt}});
          my $cdbKey = $cdbKeys[0];
          foreach my $value (keys(%{$options{$opt}->{$cdbKey}})){
            # handle special case ( -FS )
            # I think ( -Fs ) means something like Free String
            # Therefore all values which have the possible Value ( -Fs )
            # are set to found, if they are not empty
            if($value eq "( -Fs )"){
              if($cfgOptions{$opt}->{$line} ne ""){
                $found = 1;
                last;
              }
            }
            # it's equal to default value
            if((uc($value) eq uc($cfgOptions{$opt}->{$line})) && $options{$opt}->{$cdbKey}->{$value}){
              $resultsDefaultValues{$line} = new CAD::Firemen::Option::Check(
                "name" => $opt,
                "errorString" => "The option ". $opt ." is equal to default value (". $value .")"
              );
            }
            if($value eq $cfgOptions{$opt}->{$line}){
              $found = 1;
              last;
            }
            if(uc($value) eq uc($cfgOptions{$opt}->{$line})){
              $case = 1;
              last;
            }
          }
          if(!$found){
            $resultsWrongValues{$line} = new CAD::Firemen::Option::Check(
              "name" => $opt,
              "errorString" => "The option ". $opt ." has not supported value ". $cfgOptions{$opt}->{$line} ." (Possible: ". join("|", keys(%{$options{$opt}->{$cdbKey}})) .")",
              "case" => $case
            );
          }
        }
        # check that only relative paths are used,
        # if this option is not listed in %allowedRelativePaths
        if(!exists($allowedRelativePaths{$opt}) && File::Spec->file_name_is_absolute($cfgOptions{$opt}->{$line})){
          $resultsAbsolutePaths{$line} = new CAD::Firemen::Option::Check(
            "name" => $opt,
            "errorString" => "The Option ". $opt ." contains an absolute path: ". $cfgOptions{$opt}->{$line}
          );
        }
      }
    }

    # check for duplicates
    if(!exists($allowedDuplicates{$opt}) && (scalar(keys(%{$cfgOptions{$opt}})) > 1)){
      $resultsDuplicates{$opt} = new CAD::Firemen::Option::Check(
        "name" => $opt,
        "errorString" => "The Option ". $opt ." is set at lines ". join(", ", keys(%{$cfgOptions{$opt}}))
      );
    }
  }

  # print the result of the compare check (if option exists)
  my @keys = sort { $a <=> $b } keys(%resultsCompare);
  if(scalar(@keys) < 1){
    if($verbose > 0){
      testPassed("COMPARE");
    }
  }
  else{
    $checkResult = 0;
    if($verbose > 0){
      testFailed("COMPARE");
    }
    if($verbose > 1){
      my $length = length($keys[scalar(@keys) - 1]);
      foreach my $key (@keys){
        print sprintf("%". $length ."s", $key) .": ". $resultsCompare{$key}->errorString() ."\n";
        if($description && exists($descriptions{$resultsCompare{$key}->option()})){
          printBlock($descriptions{$resultsCompare{$key}->option()}, $length + 4);
        }
      }
    }
  }

  # print the result of the value check
  # handle ignored cases
  @keys = sort { $a <=> $b } keys(%resultsWrongValues);
  my $ignored = 0;
  foreach my $key (@keys){
    if($resultsWrongValues{$key}->case()){
      $ignored++;
    }
  }
  if(!$caseInsensitive){
    $ignored = 0;
  }
  if((scalar(@keys) < 1) || ($caseInsensitive && (scalar(@keys) == $ignored))){
    if($verbose > 0){
      testPassed("VALUES (Ignored: ". $ignored .")");
    }
  }
  else{
    $checkResult = 0;
    if($verbose > 0){
      testFailed("VALUES (Ignored: ". $ignored .")");
    }
    if($verbose > 1){
      my $length = length($keys[scalar(@keys) - 1]);
      foreach my $key (@keys){
        my $color = "reset";
        if($resultsWrongValues{$key}->case()){
          $color = "cyan";
        }
        if(!$resultsWrongValues{$key}->case() || !$caseInsensitive){
          printColored(sprintf("%". $length ."s", $key) .": ". $resultsWrongValues{$key}->errorString() ."\n", $color);
          if($description && exists($descriptions{$resultsWrongValues{$key}->option()})){
            printBlock($descriptions{$resultsWrongValues{$key}->option()}, $length + 4);
          }
        }
      }
    }
  }

  # print the result of the default values here (they are not treated as errors)
  @keys = sort { $a <=> $b } keys(%resultsDefaultValues);
  if(scalar(@keys) < 1){
    if($verbose > 0){
      testPassed("Default values");
    }
  }
  else{
    if($verbose > 0){
      print2ColsRightAligned("Default values", scalar(@keys), "yellow");
    }
    if($verbose > 1){
      my $length = length($keys[scalar(@keys) - 1]);
      foreach my $key (@keys){
        print sprintf("%". $length ."s", $key) .": ". $resultsDefaultValues{$key}->errorString() ."\n";
        if($description && exists($descriptions{$resultsDefaultValues{$key}->option()})){
          printBlock($descriptions{$resultsDefaultValues{$key}->option()}, $length + 4);
        }
      }
    }
  }

  # print the result of the duplicate check
  @keys = sort(keys(%resultsDuplicates));
  if(scalar(@keys) < 1){
    if($verbose > 0){
      testPassed("DUPLICATES");
    }
  }
  else{
    $checkResult = 0;
    if($verbose > 0){
      testFailed("DUPLICATES");
    }
    if($verbose > 1){
      my $length = maxLength(@keys);
      foreach my $key (@keys){
        printColored(sprintf("%". $length ."s", $key) .": ". $resultsDuplicates{$key}->errorString() ."\n", "red");
        if($description && exists($descriptions{$resultsDuplicates{$key}->option()})){
          printBlock($descriptions{$resultsDuplicates{$key}->option()}, $length + 4);
        }
      }
    }
  }

  # print the result of the no absolute path check
  @keys = sort { $a <=> $b } keys(%resultsAbsolutePaths);
  if(scalar(@keys) < 1){
    if($verbose > 0){
      testPassed("NO ABSOLUTE PATHS");
    }
  }
  else{
    $checkResult = 0;
    if($verbose > 0){
      testFailed("NO ABSOLUTE PATHS");
    }
    if($verbose > 1){
      my $length = length($keys[scalar(@keys) - 1]);
      foreach my $key (@keys){
        printColored(sprintf("%". $length ."s", $key) .": ". $resultsAbsolutePaths{$key}->errorString() ."\n", "red");
        if($description && exists($descriptions{$resultsAbsolutePaths{$key}->option()})){
          printBlock($descriptions{$resultsAbsolutePaths{$key}->option()}, $length + 4);
        }
      }
    }
  }

  return $checkResult;
}

sub checkTreeConfig {
  my $cfgUrl = shift;
  my $verbose = shift;

  my $CFG;
  my %resultsEmptyLines = ();

  if(!defined($verbose)){
    $verbose = 0;
  }

  if(!defined($cfgUrl) || $cfgUrl eq ""){
    if($verbose > 0){
      print "No URL given\n";
    }
    return 0;
  }

  # Get all possible options listed within the cdb file
  if(!open($CFG, "<", $cfgUrl)){
    if($verbose > 0){
      print "Could not open file! (". $cfgUrl .")\n";
    }
    return 0;
  }

  my $i = 0;
  while(<$CFG>){
    my $line = strip($_);
    $i++;
    if($line eq ""){
      $resultsEmptyLines{$i} = "Empty line";
    }
  }

  close($CFG);

  my $result = 1;
  # print the result of the no blank lines
  my @keys = sort { $a <=> $b } keys(%resultsEmptyLines);
  if(scalar(@keys) < 1){
    if($verbose > 0){
      testPassed("NO EMPTY LINES");
    }
  }
  else{
    $result = 0;
    if($verbose > 0){
      testFailed("NO EMPTY LINES");
    }
    if($verbose > 1){
      my $length = length($keys[scalar(@keys) - 1]);
      foreach my $key (@keys){
        printColored(sprintf("%". $length ."s", $key) .": ". $resultsEmptyLines{$key} ."\n", "red");
      }
    }
  }

  return $result;
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen::Analyze - Module provides functions to compare to lists with options (and values)

=head1 VERSION

version 0.7.2

=head1 METHODS

=head2 compare

Compares two lists of options and returns references to lists with added, changed and removed options.
It ignores all options, which are duplicated

The added and removed list of options is an array, which contains the option names as values.
The list of changed options is a hash with the option names as keys and references to the related
CAD::Firemen::Change object as values.

# the keys of %{$added} and %{$removed} are the option names of the second options
$added = {
  "ADDED_OPTION_ONE" => FIRST_LINE_NUMBER,
  "ADDED_OPTION_TWO" => FIRST_LINE_NUMBER
};

$changed {
  "OPTION_NAME" => [
    CAD::Firemen::Change,
    CAD::Firemen::Change
  ];
};

# the keys of %{$removed} are the option names of the second options
$removed = {
  "REMOVED_OPTION_ONE" => FIRST_LINE_NUMBER,
  "REMOVED_OPTION_TWO" => FIRST_LINE_NUMBER,
  "REMOVED_OPTION_ONE" => FIRST_LINE_NUMBER
};

=head2 optionsToIngoreAtPathCheckings

The paths from the options listed within the returned hash
should be ignored when checking for relative paths and for existing
directory and files in structure checkings (see fm_check_struct)

=head2 optionsToIngoreAtDuplicatesCheckings

The options listed here, may be needed more than one time in a config.

=head2 checkConfig

This method checks the given config among other tests also with help of
the given cdb file. The function returns 0 if some test failes and returns
1 if all tests are passed.

To check case insensitive, set caseInsensitive = 1.

Per default (verbose level = 0) this function outputs
nothing. So it may be useful to call it with verbose level = 1.

=head2 checkTreeConfig

This method checks the given tree config. Actually it checks, that no empty lines are in the file.

Per default (verbose level = 0) this function outputs
nothing. So it may be useful to call it with verbose level = 1.

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
