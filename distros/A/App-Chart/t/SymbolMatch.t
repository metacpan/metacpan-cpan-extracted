#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

require App::Chart::SymbolMatch;
ok (1);
exit 0;
__END__


use App::Chart::Gtk2::Symlist;

my $alerts = App::Chart::Gtk2::Symlist::_new_from_known_key ('alerts');
$alerts->{'symbol_listref'} = [ ];

my $favourites = App::Chart::Gtk2::Symlist::_new_from_known_key ('favourites');
$favourites->{'symbol_listref'} = [ 'BHP.AX', '^GSPC' ];

my $all = App::Chart::Gtk2::Symlist::_new_from_known_key ('all');
$all->{'symbol_listref'} = [ 'FOO.AX', 'ZZZ.ZZ' ];

my $historical = App::Chart::Gtk2::Symlist::_new_from_known_key ('historical');
$historical->{'symbol_listref'} = [ ];

my @test_all_lists = ($alerts, $favourites, $all, $historical);
sub test_all_lists {
  return @test_all_lists;
}

{ no warnings;
  *App::Chart::Gtk2::Symlist::all_lists = \&test_all_lists;
}

{
  my ($symbol, $symlist) = App::Chart::SymbolMatch::find ('b');
  is ($symbol, 'BHP.AX');
}
{
  my ($symbol, $symlist) = App::Chart::SymbolMatch::find ('bbw');
  is ($symbol, undef);
}
{
  my ($symbol, $symlist) = App::Chart::SymbolMatch::find ('FOO');
  is ($symbol, 'FOO.AX');
}
{
  my ($symbol, $symlist) = App::Chart::SymbolMatch::find ('gspc');
  is ($symbol, '^GSPC');
}

exit 0;
