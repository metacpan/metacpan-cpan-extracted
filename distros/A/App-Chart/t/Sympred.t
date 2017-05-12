#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
use Test::More tests => 30;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Sympred;

#-----------------------------------------------------------------------------
# Suffix

{
  my $pred = App::Chart::Sympred::Suffix->new ('.Z');
  App::Chart::Sympred::validate ($pred);
  ok (! $pred->match (''));
  ok (! $pred->match ('Z'));
  ok (! $pred->match ('.'));
  ok ($pred->match ('.Z'));
  ok ($pred->match ('FOO.Z'));
  ok (!$pred->match ('.ZZ'));
  ok (!$pred->match ('FOO'));
  ok (!$pred->match ('^FOO'));
}

{
  my $pred = App::Chart::Sympred::Suffix->new ('.tsp.FQ');
  ok (! $pred->match (''));
  ok (! $pred->match ('X.FQ'));
  ok (! $pred->match ('tsp.FQ'));
  ok ($pred->match ('C.tsp.FQ'));
  ok (! $pred->match ('^FQ'));
}

#-----------------------------------------------------------------------------
# Prefix

{
  my $pred = App::Chart::Sympred::Prefix->new ('^Z');
  App::Chart::Sympred::validate ($pred);
  ok (! $pred->match (''));
  ok (! $pred->match ('Z'));
  ok (! $pred->match ('^'));
  ok ($pred->match ('^Z'));
  ok ($pred->match ('^ZZ'));
  ok ($pred->match ('^ZZZ'));
  ok (!$pred->match ('Z^Z'));
}

{
  my $a = App::Chart::Sympred::Prefix->new ('^A');
  my $b = App::Chart::Sympred::Suffix->new ('.B');
  my $pred = App::Chart::Sympred::Any->new ($a, $b);
  App::Chart::Sympred::validate ($pred);
  ok (! $pred->match (''));
  ok (! $pred->match ('Z'));
  ok (! $pred->match ('.'));
  ok ($pred->match ('.B'));
  ok ($pred->match ('FOO.B'));
  ok ($pred->match ('^A'));
  ok ($pred->match ('^AA'));
  ok (!$pred->match ('FOO'));
  ok (!$pred->match ('B.A'));
  ok (!$pred->match ('B.^A'));
}

exit 0;
