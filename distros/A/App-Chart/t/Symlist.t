#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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


use 5.008;
use strict;
use warnings;
use Test::More tests => 18;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# {
#   require App::Chart::Gtk2::Symlist::All;
#   my $symlist = App::Chart::Gtk2::Symlist::All->instance;
#   require Scalar::Util;
#   Scalar::Util::weaken ($symlist);
#   is ($symlist, undef);
# }

{
  require App::Chart::Gtk2::Symlist::All;
  my $symlist = App::Chart::Gtk2::Symlist::All->instance;
  is ($symlist->key, 'all');
  ok ($symlist->name, 'all name');
  ok ($symlist->symbol_listref, 'all listref');
  ok ($symlist->hash, 'all hash');
  $symlist->reread;
}

{
  require App::Chart::Gtk2::Symlist::Favourites;
  my $symlist = App::Chart::Gtk2::Symlist::Favourites->instance;
  ok ($symlist->name, 'favourites name');
  is ($symlist->key, 'favourites');
  ok ($symlist->symbol_listref, 'favourites listref');
  ok ($symlist->hash, 'favourites hash');
  $symlist->reread;
}

{
  my $key = App::Chart::Gtk2::Symlist::User->add_symlist (0, '** Test symlist');
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);

  sub db_content {
    require App::Chart::DBI;
    my $dbh = App::Chart::DBI->instance;
    return $dbh->selectcol_arrayref ('SELECT symbol FROM symlist_content
                                      WHERE key=? ORDER BY seq ASC',
                                     undef, $key);
  }

  diag ('testlist insert');
  $symlist->insert_with_values (0, 0=>'GM');
  is_deeply (db_content(), ['GM'], 'GM at testlist 0');

  $symlist->remove ($symlist->get_iter_first);
  is_deeply (db_content(), []);

  $symlist->insert_with_values (0, 0=>'AA');
  $symlist->insert_with_values (2, 0=>'CC');
  is_deeply (db_content(), ['AA','CC']);

  { my $path = $symlist->find_symbol_path ('AA');
    is_deeply ($path && [$path->get_indices], [0]);
  }
  { my $path = $symlist->find_symbol_path ('CC');
    is_deeply ($path && [$path->get_indices], [1]);
  }
  { my $path = $symlist->find_symbol_path ('XX');
    is ($path, undef);
  }

  $symlist->insert_symbol_at_pos ('AAX', 1);
  is_deeply (db_content(), ['AA','AAX','CC']);

  $symlist->delete_symbol ('AAX');
  is_deeply (db_content(), ['AA','CC']);

  $symlist->App::Chart::Gtk2::Symlist::Alphabetical::insert_symbol ('BB');
  is_deeply (db_content(), ['AA','BB','CC']);

  $symlist->reorder (2,0,1);
  is_deeply (db_content(), ['CC','AA','BB']);

  $symlist->insert_with_values (0, 0=>'AA');

  $symlist->delete_symlist;
}

exit 0;
