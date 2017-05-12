#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Data::Dumper;

BEGIN {
  if (eval { require Devel::Mallinfo }) {
    print Dumper(Devel::Mallinfo::mallinfo());
  }
}
use Finance::TA;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  print "TA-Lib ", TA_GetVersionString(), "\n\n";
  my @groups = TA_GroupTable();
  ### @groups
  shift @groups;
  # foreach my $group (@groups) {
  #   my @functions = TA_FuncTable($group);
  #   print "$group ",Dumper(\@functions);
  # }
  exit 0;
}
{
  require App::Chart::Series::Database;
  require App::Chart::Series::TA;
  my $symbol = 'WOW.AX';
  # $symbol = 'CA.LME';
  my $series = App::Chart::Series::Database->new($symbol);
  my $ta = App::Chart::Series::TA->new('SMA',$series,10);
  # my $ta = App::Chart::Series::TA->new('CDLHANGINGMAN',$series);
  print "hi ",$ta->hi,"\n";
  print "ta ",Dumper($ta);
  $ta->fill(100,110);

  my $values = $ta->values_array;
  print "values ",Dumper($values);


  if (eval { require Devel::Mallinfo }) {
    print Dumper(Devel::Mallinfo::mallinfo());
  }
  exit 0;
}

{
  print "lookbacks\n";
  foreach my $funcname (sort {$a cmp $b} all_func_names()) {
    # print "$funcname\n";
    my $lookbackname = "TA_${funcname}_Lookback";
    my $lookbackfunc = Finance::TA->can($lookbackname);
    if (! $lookbackfunc) {
      printf "%-4s  %s\n", 'n/a', $lookbackname;
      next;
    }

    my $fh;
    Finance::TA::TA_GetFuncHandle($funcname, \$fh) == $Finance::TA::TA_SUCCESS
        or die;
    my $fi;
    Finance::TA::TA_GetFuncInfo($fh, \$fi) == $Finance::TA::TA_SUCCESS
        or die;

    my $flags = $fi->{'flags'};

    my @args = fhfi_default_args($fh,$fi);
    # print Data::Dumper->Dump([\@args],['args']);
    my $lookback = $lookbackfunc->(@args);
    printf "%4s  %s -- %s  [%s]\n",
      $lookback, $funcname, join(',',@args),
        ($flags & $Finance::TA::TA_FUNC_FLG_UNST_PER ? 'UNST_PER' : '');
  }
  exit 0;

  sub all_func_names {
    my @ret;
    my @groups = Finance::TA::TA_GroupTable();
    shift @groups;
    foreach my $group (@groups) {
      my @functions = Finance::TA::TA_FuncTable($group);
      shift @functions;
      push @ret, @functions;
    }
    return @ret;
  }

  sub fhfi_default_args {
    my ($fh, $fi) = @_;
    return map {
      my $i = $_;
      my ($retcode, $info);
      if (($retcode = TA_GetOptInputParameterInfo ($fh, $i, \$info))
          != $TA_SUCCESS) {
        die "Oops, cannot TA_GetOptInputParameterInfo";
      }
      $info->{'defaultValue'}
    } (0 .. $fi->{'nbOptInput'}-1);
  }
}

{
  my ($fh, $fi);
  TA_GetFuncHandle("CDLHANGINGMAN", \$fh) == $TA_SUCCESS || die;
  print Dumper($fh);
  TA_GetFuncInfo($fh, \$fi) == $TA_SUCCESS || die;
  ### $fi
  foreach my $field (qw(name
                        group
                        hint
                        flags
                        nbInput
                        nbOptInput
                        nbOutput
                      )) {
    print "$field: ",$fi->{$field},"\n";
  }
  print "\n";
  foreach my $i (0 .. $fi->{'nbInput'} - 1) {
    print "$i\n";
    my $info;
    TA_GetInputParameterInfo($fh, $i, \$info) == $TA_SUCCESS || die;
    print Dumper($info);
    foreach my $field (qw(type
                          paramName
                          flags
                        )) {
      print "$field: ",$info->{$field},"\n";
    }
  }
  print "\n";
  foreach my $i (0 .. $fi->{'nbOptInput'} - 1) {
    print "$i\n";
    my $info;
    TA_GetOptInputParameterInfo($fh, $i, \$info) == $TA_SUCCESS || die;
    print Dumper($info);
    foreach my $field (qw(type
                          paramName
                          flags

                          displayName
                          dataSet
                          defaultValue
                          hint
                          helpFile

                        )) {
      print "$field: ",($info->{$field}//'undef'),"\n";
    }
    my $dataSet = $info->{'dataSet'};
    foreach my $field (qw(min max
                        )) {
      print "  dataSet $field: ",(eval{$dataSet->{$field}}//'undef'),"\n";
    }
  }
  print "\n";
  foreach my $i (0 .. $fi->{'nbOutput'} - 1) {
    print "$i\n";
    my $info;
    TA_GetOutputParameterInfo($fh, $i, \$info) == $TA_SUCCESS || die;
    print Dumper($info);
    foreach my $field (qw(type
                          paramName
                          flags
                        )) {
      print "$field: ",$info->{$field},"\n";
    }
  }
}






