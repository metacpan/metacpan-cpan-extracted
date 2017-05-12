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
# ABSTRACT: Module to parse files from Firemen (like pro and cdb files)

use strict;
use warnings;

package CAD::Firemen::Load;
{
  $CAD::Firemen::Load::VERSION = '0.7.2';
}
use Exporter 'import';
our @EXPORT_OK = qw(loadConfig loadCDB loadDatabase);
use POSIX;
use CAD::Firemen::Common qw(strip printColored);


sub loadConfig {
  my $cfgUrl = shift;
  my $CFG;
  my %options= ();
  my %errors = ();

  if(!defined($cfgUrl) || $cfgUrl eq ""){
    $errors{0} = "No URL given";
    return (\%options, \%errors, 0);
  }

  # Get all possible options listed within the cdb file
  if(!open($CFG, "<", $cfgUrl)){
    $errors{0} = "Could not open file! (". $cfgUrl .")";
    return (\%options, \%errors, 0);
  }

  my $i = 0;
  while(<$CFG>){
    my $line = strip($_);
    $i++;
    # skip comments and mapkeys
    if($line !~ m/^\s*!/){
      if($line =~ m/^\s*mapkey/){
        # handle mapkeys here
      }
      else{
        if($line =~ m/^([^\s]+)\s+([^!]+)/){
          my $opt = uc($1);
          if(!exists($options{$opt})){
            $options{$opt} = {};
          }
          $options{$opt}->{strip($i)} = strip($2);
        }
        else{
          if($line ne ""){
            $errors{$i} = "Detected uncommented line without an option";
          }
        }
      }
    }
  }

  close($CFG);

  return (\%options, \%errors, $i);
}

sub loadCDB {
  my $cdbUrl = shift;
  my $CDB;
  my %results = ();
  my %errors = ();

  if(!defined($cdbUrl) || $cdbUrl eq ""){
    $errors{0} = "No URL given";
    return (\%results, \%errors);
  }

  # Get all possible options listed within the cdb file
  if(!open($CDB, "<", $cdbUrl)){
    $errors{0} = "Could not open file! (". $cdbUrl .")";
    return (\%results, \%errors);
  }

  my $i = 1;
  while(<$CDB>){
    my $line = strip($_);
    if($line =~ m/^([^\s]+)\s{0,}\( -[\w\d]+\s{0,}\)/){
      my $ref;
      my $error = "";
      my $lineNumber = $i;
      ($ref, $i, $error) = _extractParameters($CDB, $i);
      $results{uc($1)} = { $lineNumber => $ref };
      if($error ne ""){
        $errors{$i} = $error;
      }
      # this can not be treated as an error, because many options does not have values supplied
      #if(scalar(@opts) < 1){
      #  $errors{$i} = "WARNING: Could not get a list of parameters for option ". $1;
      #}
    }
    $i++;
  }

  close($CDB);

  return (\%results, \%errors);
}

sub loadDatabase {
  my $dbh = shift;
  my $sqlQuery = shift;
  my $verbose = shift;

  my %options = ();
  my %errors = ();
  my %descriptions = ();

  if(!defined($verbose)){
    $verbose = 0;
  }
  if(!$dbh){
    $errors{0} = "No database handle given";
    return (\%options, \%errors, \%descriptions);
  }
  if(!defined($sqlQuery) || ($sqlQuery eq "")){
    $errors{0} = "No SQL Query string given";
    return (\%options, \%errors, \%descriptions);
  }
  my $ref = $dbh->selectall_hashref($sqlQuery, 'name');
  if(!$ref){
    $errors{0} = "Error ". $dbh->err ." (". $dbh->errstr .")";
    return (\%options, \%errors, \%descriptions);
  }
  my %results = %{$ref};
  foreach my $name (keys(%results)){
    $sqlQuery  = "SELECT vals.id as id, vals.name as name FROM options_values as vals, options_has_values opthasvals";
    $sqlQuery .= " WHERE vals.id=opthasvals.valuesId";
    $sqlQuery .= "  AND opthasvals.optionsId=". $results{$name}->{"id"};
    $ref = $dbh->selectall_hashref($sqlQuery, "id");
    if(!defined($ref)){
      next;
    }
    my %tmpValues = ();
    foreach my $valId (keys(%{$ref})){
      $tmpValues{$ref->{$valId}->{"name"}} = 0;
      if(defined($results{$name}->{"defaultValueId"}) && ($valId == $results{$name}->{"defaultValueId"})){
        $tmpValues{$ref->{$valId}->{"name"}} = 1;
      }
    }
    # we use line 0 here, because we do not know the line
    $options{$name} = { 0 => \%tmpValues};
    $descriptions{$name} = $results{$name}->{"description"};
  }

  return (\%options, \%errors, \%descriptions);
}

sub _extractParameters {
  my $CDB = shift;
  # the line number
  my $i = shift;
  my $start = 0;
  my %values = ();
  while(<$CDB>){
    # raise it here, because we have read a new line already
    $i++;
    my $line = strip($_);
    if($line eq "{"){
      $start = 1;
    }
    elsif($line eq "}"){
      if(!$start){
        # we found an end, without a beginning,
        # therefore it was an error
        return (\%values, $i, "No opening bracket found");
      }
      return (\%values, $i, "");
    }
    elsif($start){
      $values{$line} = 0;
    }
  }
  my %tmp = ();
  return (\%tmp, $i, "No opening or closing bracket found");
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen::Load - Module to parse files from Firemen (like pro and cdb files)

=head1 VERSION

version 0.7.2

=head1 METHODS

=head2 loadConfig

Loads the given config file and returns an array as described below.
As parameter it expacts the URL to the config file which should be loaded.

$results = {
   "OPTION_ONE" => {
     "1" => "VALUE_OF_OPTION_ONE_IN_LINE_1",
     "2" => "VALUE_OF_OPTION_ONE_IN_LINE_2"
   },
   "OPTION_TWO" => {
     "12" => "VALUE_OF_OPTION_TWO_IN_LINE_12"
   }
 };

 $errors = {
   "1" => "Error description for line 1",
   "12" => "Error description for line 12"
 };

 return ($results, $errors, PARSED_LINES);

=head2 loadCDB

The function loads a CDB file and returns the result as a hash like shown below.

Expacts the URL to the cdb file which should be loaded as first parameter.

Result:

 # since in cdb, the option should be present ones, the line number
 # is only mentioned to be compatible to the output format of
 # loadConfig()
 $results = {
   "OPTION_ONE" => {
     1 => {
       "YES" => 0,
       "NO" => 1
     }
   },
   "OPTION_WITHOUT_DEFAULT_VALUE" => {
     2 => {
       "VALUE1" => 0,
       "VALUE2" => 0,
       "VALUE3" => 0
     }
   }
 };

 $errors = {
   "1" => "Error description for line 1",
   "12" => "Error description for line 12"
 };
 return ($results, $errors)

=head2 loadDatabase

Loads the options from given database and returns the same structure as descriped at
loadCDB(). But it adds a third hash reference to the return vector, which contains
descriptions (values) for the options (keys).

It needs the database handle as first parameter and the SQL query string, which should be
used to find options as second parameter.

=head2 __extractParameters
FOR INTERNAL USE ONLY!

Returns an array with possible values for the actual option.
Requires a valied file handler as first parameter.

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
