#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2020 Kevin Ryde

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


# load all modules with Test::Compile, if available

use strict;
use warnings;
use Test::More;

if (! eval 'use Test::Compile::Internal 0.08; 1') {
  plan skip_all => "due to Test::Compile::Internal not available -- $@";
}

foreach my $dir (@INC) {
  if (ref $dir) {
    plan skip_all => "due to a coderef in \@INC not enjoyed by Test::Compile::Internal";
  }
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $tc = Test::Compile::Internal->new();
# $tc->verbose(1);

my @plfiles = ('chart');
my @pmdirs = ('blib');
my @pmfiles = $tc->all_pm_files (@pmdirs);

@pmfiles = grep { ! m{Perl/Critic}
                    && ! m{App/Chart/Gtk2/RawDialog}
                    && ! m{App/Chart/Gtk2/IndicatorModelGenerated} } @pmfiles;

unless (eval {require GT::Prices}) {
  diag "skip GT modules, GT::Prices not available -- $@";
  @pmfiles = grep { !m{/GT} } @pmfiles;
}
unless (eval {require Finance::TA}) {
  diag "skip TA modules, Finance::TA not available -- $@";
  @pmfiles = grep { !m{/TA} } @pmfiles;
}
unless (eval {require Finance::Quote}) {
  diag "skip F-Q modules, Finance::Quote not available -- $@";
  @pmfiles = grep { !m{Finance/Quote} } @pmfiles;
}

plan tests => scalar(@plfiles) + scalar(@pmfiles);

foreach my $filename (@plfiles) {
  ok($tc->pl_file_compiles($filename));
}
foreach my $filename (@pmfiles) {
  ok($tc->pm_file_compiles($filename));
}

exit 0;
