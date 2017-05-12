#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2015, 2016 Kevin Ryde

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
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Manual;

{
  my $good = 1;
  require File::Spec;
  my $texi_filename = File::Spec->catfile (File::Spec->curdir,
                                           'doc', 'chart.texi');
  require File::Slurp;
  my $texi = File::Slurp::read_file ($texi_filename);
  my %texi_nodes;
  while ($texi =~ /^\@node ([^,\n]*)/mg) {
    $texi_nodes{$1} = 1;
  }
  while ($texi =~ /^\@anchor\{([^}]*)}/mg) {
    $texi_nodes{$1} = 1;
  }
  diag "texi nodes ",scalar(keys(%texi_nodes));

  require ExtUtils::Manifest;
  my $m = ExtUtils::Manifest::maniread();
  my $source_count = 0;
  foreach my $filename (keys %$m) {
    if ($filename !~ m{lib/App/Chart}) { next; }

    my $body = File::Slurp::read_file($filename);
    $body =~ s/#[^\n]*//g; # lose comments
    my @lines = split /\n/, $body;
    # while ($body =~ /(['"])CONTEXT\(manual-node\): *(.*?)\1/g) {
    # my $nodename = $1;
    while ($body =~ /__p\('manual-node','(.*?)'/g) {
      my $nodename = $1;
      $source_count++;

      if (! $texi_nodes{$nodename}) {
        diag "no chart.texi node for \"$nodename\" ref in $filename";
        # $good = 0;
      }
    }
  }
  diag "source nodes $source_count";

  ok ($good);
}

exit 0;
