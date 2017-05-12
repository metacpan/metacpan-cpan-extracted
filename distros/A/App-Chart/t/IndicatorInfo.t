#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

require App::Chart::IndicatorInfo;

require FindBin;
require File::Spec;
require ExtUtils::Manifest;
diag "FindBin $FindBin::Bin";
my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @files = keys %$manifest;
@files = grep {m{^lib/App/Chart/Series/Derived/}} @files;

diag scalar(@files)," series modules";
my $good = 1;
require Module::Load;
require Module::Util;
foreach my $file (@files) {
  my $class = $file;
  $class =~ s{^lib/}{} or die;
  $class = Module::Util::path_to_module($class);
  # diag "load $class";
  Module::Load::load ($class);

  my $funcname = "${class}::parameters";
  if (exists &$funcname) {
    diag "$file:1: unexpected $funcname()";
    $good = 0;
  }

  # Inheriting the default [] no parameters is fairly normal
  #   my $funcname = "${class}::parameter_info";
  #   if (! defined &$funcname) {
  #     print "$file:1: no $funcname\n";
  #     $good = 0;
  #   }
}
ok ($good);

exit 0;
