#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

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
use ExtUtils::Manifest;

# uncomment this to run the ### lines
#use Smart::Comments;

eval 'use Test::Synopsis; 1'
  or plan skip_all => "due to Test::Synopsis not available -- $@";

my $manifest = ExtUtils::Manifest::maniread();
my @files = grep m{^lib/.*\.pm$}, keys %$manifest;

# no synopsis in perlcritic bits
# @files = grep {! m</Perl/Critic/> } @files;

if (! eval { require Finance::Quote }) {
  diag "skip Finance::Quote::* since Finance::Quote not available -- $@";
  @files = grep {! m</Finance/Quote/> } @files;
}

if (! eval { require GT::DB }) {
  diag "skip GT::DB::* since GT::DB not available -- $@";
  @files = grep {! m</GT/DB/> } @files;
}

if (! eval { require GT::Prices }) {
  diag "skip GT::Prices::* since GT::Prices not available -- $@";
  @files = grep {! m<Series/GT> } @files;
}

if (! eval { require Finance::TA }) {
  diag "skip App::Chart::Series::TA since Finance::TA not available -- $@";
  @files = grep {! m<App/Chart/Series/TA> } @files;
}

# Gtk2::Ex::Datasheet::DBI 2.1 does '-init'
require Gtk2;
unless (Gtk2->init_check) {
  @files = grep {! m</RawDialog> } @files;
}

plan tests => 1 * scalar @files;

## no critic (ProhibitCallsToUndeclaredSubs)
synopsis_ok(@files);

exit 0;
