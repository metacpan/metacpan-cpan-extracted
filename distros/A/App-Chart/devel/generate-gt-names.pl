#!/usr/bin/perl -w

# Copyright 2009, 2010, 2016 Kevin Ryde

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


# Usage: perl devel/generate-gt-names.pl
#

use strict;
use warnings;
use Module::Find;
use Module::Util;
use File::Slurp;
use Data::Dumper;
use POSIX ();

my $option_verbose = 1;

POSIX::setlocale(POSIX::LC_MESSAGES(), 'C');

my @modules = Module::Find::findsubmod ('GT::Indicators');
foreach my $module (@modules) {
  my $filename = Module::Util::find_installed ($module)
    || die "oops $module filename not found";

  my $key = $module;
  $key =~ s/^GT::Indicators:://;

  my $content = File::Slurp::slurp ($filename);
  if (! ($content =~ /=head1 NAME\n\n(.*)/
         || $content =~ /=head2 Overview\n\nThe (.*?) indicator/
         || $content =~ /=head2 Overview\n\nThe (.*?) \(/
         || $content =~ /=head[12] \Q$module\E\n\nThe standard (.*?) \(/
         || $content =~ /=head[12] \Q$module\E\n\nThe (.*?) \(/
         || $content =~ /=head2 Overview\n\n([A-Z][A-Za-z0-9]+ )+/
         || $content =~ /=head2 \Q$module\E\n\n([A-Z][A-Za-z0-9]+ )+/
         || $content =~ /=head1 \Q$module\E\n\nThe (.*?) indicator/
         || $content =~ /=head2 \Q$module\E\n\nThe (.*?) stop/
         || $content =~ /=head1 \Q$module\E\n\n(.*?) \(/
        )) {
    print "$filename:1:1: not matched\n";
    next;
  }
  my $line = $1;
  $line =~ s/^GT::Indicators:://;

  if ($line eq $key) {
    print "# $module - same as key\n";
    next;
  }

  print "$module -- $line\n";
}

exit 0;
