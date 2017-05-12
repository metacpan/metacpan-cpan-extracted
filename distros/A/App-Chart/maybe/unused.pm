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


#------------------------------------------------------------------------------
# generic helpers

# sub widget_clear_region {
#   my ($widget, $region) = @_;
#   if (my $win = $widget->window) {
#     window_clear_region ($win);
#   }
# }


# strftime() on Time::Piece taking and returning a wide-char string
sub time_piece_strftime_wide {
  my ($timepiece, $format) = @_;
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());
  $format = Encode::encode ($charset, $format);
  my $str = $timepiece->strftime ($format);
  return Encode::decode ($charset, $str);
}



# _all_map_same ($func, $x, $y, ...) returns true if calls $func->($x),
# $func->($y), etc all return the same number.
sub _all_map_same {
  my $func = shift;
  if (@_) {
    my $want = $func->(shift @_);
    foreach (@_) {
      if ($func->($_) != $want) { return 0; }
    }
  }
  return 1;
}


sub symlist_count {
  my ($key) = @_;
  my $last = App::Chart::Database::read_notes_single
    ('SELECT seq FROM symlist ORDER BY seq DESC LIMIT 1');
  if (defined $last) {
    return $last + 1;
  } else {
    return 0;
  }
}

sub adate_time_to_timet {
  my ($adate, $time) = @_;
  my ($year, $month, $day) = App::Chart::adate_to_ymd ($adate);
  return Date::Calc::Date_to_Time ($year, $month, $day, 0,0,$time||0);
}

sub timepiece_to_wdate {
  my ($t) = @_;
  return wdate_to_tdate (timepiece_to_tdate ($t));
}
sub timepiece_to_tdate {
  my ($t) = @_;
  return App::Chart::ymd_to_tdate_floor ($t->year, $t->mon, $t->mday);
}
sub wdate_to_tdate {
  my ($wdate) = @_;
  return $wdate * 5;
}


sub liststore_fill_dbi {
  my ($store, $sth) = @_;

  my $len = $store->iter_n_children(undef);
  my $iter = $store->get_iter_first;
  my @cols = (0 .. $store->get_n_columns - 1);
  while (my @data = $sth->fetchrow_array) {
    @data = List::MoreUtils::mesh (@cols, @data);
    if ($iter) {
      $store->set ($iter, @data);
      $iter = $store->iter_next ($iter);
    } else {
      $store->insert_with_values ($len++, @data);
    }
  }
  if ($iter) {
    while ($store->remove ($iter)) {
    }
  }
  $sth->finish;
}


sub liststore_truncate {
  my ($store, $n) = @_;
  my $iter = $store->iter_nth_child (undef, $pos)
    || return;
    while ($self->remove ($iter)) {
    }
}


# return $widget if it has a window, or its next windowed parent
sub _get_windowed_widget {
  my ($widget) = @_;
  while ($widget->flags & 'no-window') {
    $widget = $widget->get_parent;
    if (! $widget) { last; }
  }
  return $widget;
}


#------------------------------------------------------------------------------

sub delete_extra {
  my ($symbol, $key) = @_;
  my $dbh = App::Chart::DBI->instance;
  $dbh->do ('DELETE FROM extra WHERE symbol=? AND key=?', {}, $symbol, $key);
}

sub strftime_unixtime_local {
  my ($format, $unixtime) = @_;
  my $time = $unixtime + $App::Chart::unixtime_base;
  return App::Chart::strftime_wide ($format, localtime ($time));
}

#------------------------------------------------------------------------------

=item App::Chart::unixtime ()

Return the current time in Unix style seconds since midnight 1 Jan
1970.  This function always uses 1970 as the epoch, unlike C<time()> which
is either 1970 or 1904 depending on the platform (1904 on MacOS).

=cut

our $unixtime_base = Date::Calc::Date_to_Time (1970,1,1, 0,0,0);
sub unixtime {
  return (time () - $unixtime_base);
}


