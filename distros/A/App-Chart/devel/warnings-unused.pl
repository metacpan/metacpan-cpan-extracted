#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2015 Kevin Ryde

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
use Test::Vars;
vars_ok('lib/App/Chart/Series/Derived/Ulcer.pm');
# vars_ok('/tmp/Ulcer.pm');
exit 0;

__END__

# Usage: perl warnings-unused.pl filename...

use strict;
use warnings;
use warnings::unused '-global';
use ExtUtils::Manifest;
use File::Spec;
use FindBin;
use Module::Load;

BEGIN {
  # my $toplevel_dir = (@ARGV ? shift @ARGV : File::Spec->curdir);
  # File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
  my $toplevel_dir = File::Spec->curdir;

  unshift @INC, File::Spec->catdir ($toplevel_dir, 'lib');

  my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
  my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

  foreach my $filename (keys %$manifest) {
    if ($filename =~ /maybe/) { next; }
    my $module = $filename;
    $module =~ s{lib/(.*)\.pm}{$1} or next;
    $module =~ s{/}{::}g;
    print "$module\n";
    eval { Module::Load::load ($module); 1 }
      or print "$module error: $@";
  }
}

exit 0;
