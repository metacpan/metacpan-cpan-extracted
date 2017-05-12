#!/usr/bin/perl -w

# Copyright 2005, 2006, 2007, 2009, 2010, 2013, 2016 Kevin Ryde

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
use Test::More;
use File::Temp;
use File::Spec;

my $devnull = File::Spec->devnull;
{
  my $exit_status = system "scrollkeeper-install >$devnull 2>&1";
  if ($exit_status != 0) {
    diag sprintf("exit status %#X",$exit_status);
    my $output = `scrollkeeper-install 2>&1`;
    diag "scrollkeeper-install output:\n", $output;
    plan skip_all => 'due to scrollkeeper-install program not available';
  }
}
plan tests => 1;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

my $omffile = File::Spec->rel2abs(File::Spec->catfile('doc','chart.omf'));

my $tempdir = File::Temp->newdir ('chart-test-omf-XXXXXX',
                                  TMPDIR => 1);
diag "tempdir $tempdir";
chdir($tempdir) or die "Cannot chdir to $tempdir: $!";

my $wstat = system
  "scrollkeeper-install -v -p $tempdir $omffile >omf.out 2>omf.err";
is ($wstat, 0, 'scrollkeeper-install exit status');

# show output only on error, the normal output is only confusing
if ($wstat) {
  require File::Slurp;
  diag "omf.out stdout:";
  diag File::Slurp::read_file('omf.out');
  diag "omf.err stderr:";
  diag File::Slurp::read_file('omf.err');
}

# chdir out of directory so File::Temp can remove it
chdir(File::Spec->rootdir);
exit 0;
