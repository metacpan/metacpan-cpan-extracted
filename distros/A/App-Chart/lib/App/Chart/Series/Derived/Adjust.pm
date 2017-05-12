# Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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

package App::Chart::Series::Derived::Adjust;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-Chart');

use App::Chart::DBI;
use App::Chart::TZ;
use base 'App::Chart::Series::OHLCVI';

# uncomment this to run the ### lines
#use Smart::Comments;

sub longname  { __('Adjustments') }
sub shortname { __('Adj') }
sub manual    { __p('manual-node','Dividends and Splits') }

use constant { type      => 'special',
               parameter_info => [ { name => __('Splits'),
                                     key  => 'adj_splits',
                                     type => 'boolean',
                                     default => 1 },

                                   { name => __('Divs'),
                                     key  => 'adj_dividends',
                                     type => 'boolean',
                                     default => 1 },

                                   { name => __('Imp'),
                                     key  => 'adj_imputation',
                                     type => 'boolean',
                                     default => 1 },

                                   { name => __('Roll'),
                                     key  => 'adj_rollovers',
                                     type => 'boolean',
                                     default => 0 }],
             };

sub name {
  my ($self) = @_;
  return __x('{parent} - Adj {list}',
             parent => $self->{'parent'}->name,
             list =>
             join (',',
                   ($self->{'adjust_splits'}    ? __('Splits') : ()),
                   ($self->{'adjust_dividends'} ? __('Divs') : ()),
                   ($self->{'adjust_dividends'} && $self->{'adjust_imputation'}
                    ? __('Imp') : ())));
}
sub symbol_name {
  my ($self) = @_;
  if (my $parent = $self->{'parent'}) {
    if (defined (my $symbol = $parent->{'symbol'})) {
      return App::Chart::Database->symbol_name ($symbol);
    }
  }
  return undef;
}

sub derive {
  my ($class, $parent, %options) = @_;

  my $adjust_splits     = $options{'adjust_splits'};
  my $adjust_dividends  = $options{'adjust_dividends'};
  if (! $adjust_splits && ! $adjust_dividends) { return $parent; }

  # Only go up to today (in the symbol's timezone) for adjustments.  Stuff
  # in the future shouldn't be applied until then.  Decide this at init time
  # in case we live long enough for the time to reach a new day.
  #
  my $symbol = $parent->{'symbol'};
  my $timezone = App::Chart::TZ->for_symbol ($symbol);
  my $hi_iso = $timezone->iso_date;

  my $timebase = $parent->timebase;
  my $lo_iso = $timebase->to_iso (0);

  # if for each option it's either not wanted or there's no data for it,
  # then can just return unmodified $parent
  #
  if ((! $adjust_splits
       || ! App::Chart::DBI->read_single ('SELECT date FROM split
                          WHERE (symbol=? AND (date BETWEEN ? AND ?))
                          LIMIT 1', $symbol, $lo_iso, $hi_iso))
      &&
      (! $adjust_dividends
       || ! App::Chart::DBI->read_single ('SELECT ex_date FROM dividend
                          WHERE (symbol=? AND (ex_date BETWEEN ? AND ?))
                          LIMIT 1', $symbol, $lo_iso, $hi_iso))) {
    ### Adjust no splits or dividends to apply
    return $parent;
  }

  return $class->SUPER::new (parent     => $parent,
                             adj_hi_iso => $hi_iso,
                             %options);
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  ### Adjust fill_part() "$lo $hi"

  my $dbh = App::Chart::DBI->instance;
  my $timebase = $self->timebase;
  my $parent = $self->{'parent'};
  my $symbol = $parent->{'symbol'};
  my $lo_iso = $timebase->to_iso ($lo);  # requested $lo
  my $hi_iso = $self->{'adj_hi_iso'};    # all splits/divs to today

  my $splits = [];
  if ($self->{'adjust_splits'}) {
    my $sth = $dbh->prepare_cached
      ('SELECT date, new, old
        FROM split WHERE (symbol=? AND (date BETWEEN ? AND ?))
        ORDER BY date DESC');
    $splits = $dbh->selectall_arrayref ($sth, {Slice=>{}},
                                        $symbol, $lo_iso, $hi_iso);
    $sth->finish;
    foreach my $row (@$splits) {
      $row->{'date'} = $timebase->from_iso_floor ($row->{'date'});
    }
  }
  push @$splits, { date => $lo-1 }; # sentinel
  ### $splits

  my $dividends = [];
  if ($self->{'adjust_dividends'}) {
    my $sth = $dbh->prepare_cached
      ('SELECT ex_date, amount, imputation
        FROM dividend WHERE (symbol=? AND (ex_date BETWEEN ? AND ?))
        ORDER BY ex_date DESC');
    $dividends = $dbh->selectall_arrayref ($sth, {Slice=>{}},
                                           $symbol, $lo_iso, $hi_iso);
    $sth->finish;
    foreach my $row (@$dividends) {
      $row->{'ex_date'} = $timebase->from_iso_floor ($row->{'ex_date'});
    }
  }
  push @$dividends, { ex_date => $lo-1 }; # sentinel
  ### $dividends

  $hi = $parent->find_after($hi,1);

  $parent->fill ($lo, $hi);
  my $p_opens    = $parent->array('opens');
  my $p_closes   = $parent->array('closes');
  my $p_highs    = $parent->array('highs');
  my $p_lows     = $parent->array('lows');
  my $p_volumes  = $parent->array('volumes');
  my $p_openints = $parent->array('openints');

  my $s_opens    = $self->{'opens'};
  my $s_closes   = $self->{'closes'};
  my $s_highs    = $self->{'highs'};
  my $s_lows     = $self->{'lows'};
  my $s_volumes  = $self->{'volumes'};
  my $s_openints = $self->{'openints'};

  my $factor = 1;
  my $post_close;
  for (my $t = $hi; $t >= $lo; $t--) {

    if ($p_opens->[$t])   { $s_opens->[$t]  = $p_opens->[$t]  * $factor; }
    if ($p_highs->[$t])   { $s_highs->[$t]  = $p_highs->[$t]  * $factor; }
    if ($p_lows->[$t])    { $s_lows->[$t]   = $p_lows->[$t]   * $factor; }
    if ($p_closes->[$t])  { $post_close     = $p_closes->[$t];
                            $s_closes->[$t] = $post_close     * $factor;
                          }
    if ($p_volumes->[$t]) { $s_volumes->[$t]  = $p_volumes->[$t]  / $factor;}
    if ($p_openints->[$t]){ $s_openints->[$t] = $p_openints->[$t] / $factor;}

    for ( ; $splits->[0]->{'date'} >= $t; shift @$splits) {
      $factor *= ($splits->[0]->{'old'} / $splits->[0]->{'new'});
      ### factor now: $factor
    }

    for ( ; $dividends->[0]->{'ex_date'} >= $t; shift @$dividends) {
      my $div = $dividends->[0]->{'amount'};
      Scalar::Util::looks_like_number ($div) or next;

      if ($self->{'adjust_imputation'}) {
        my $imp = $dividends->[0]->{'imputation'};
        if (Scalar::Util::looks_like_number ($imp)) { $div += $imp; }
      }
      if (defined $post_close) {
        # factor chosen so if prev=post+div then prev*factor==post
        $factor *= $post_close / ($post_close + $div);
        ### dividend: $div
        ### $post_close
        ### factor now: $factor
      }
    }
  }
}

sub dividends {
  my ($self) = @_;
  return $self->{'parent'}->dividends;
}
sub splits {
  my ($self) = @_;
  return $self->{'parent'}->splits;
}
sub annotations {
  my ($self) = @_;
  return $self->{'parent'}->annotations;
}

sub Alerts_arrayref {
  my ($self) = @_;
  my $parent = $self->{'parent'};
  if (my $func = $parent->can('Alerts_arrayref')) {
    return $parent->$func;
  } else {
    return [];
  }
}

# FIXME: Adjust endpoints per display
sub AnnLines_arrayref {
  my ($self) = @_;
  my $parent = $self->{'parent'};
  if (my $func = $parent->can('AnnLines_arrayref')) {
    return $parent->$func;
  } else {
    return [];
  }
}

1;
__END__


=head1 NAME

App::Chart::Series::Derived::Adjust -- series adjustments for dividends, splits, etc

=for test_synopsis my ($series)

=head1 SYNOPSIS

 use App::Chart::Series::Derived::Adjust;
 my $adj_series = App::Chart::Series::Derived::Adjust->derive
                      ($series, adjust_splits => 1);

=head1 DESCRIPTION

A C<App::Chart::Series::Derived::Adjust> series applies adjustments to an underlying
database series for stock splits, dividend reinvestment, etc.  The split
information etc is obtained from the database.

=head1 FUNCTIONS

=over 4

=item App::Chart::Series::Derived::Adjust->derive ($series, key=>value,...)

Create a new series which applies adjustments to C<$series>, for some or all
of dividends, splits, capital returns, etc.  C<$series> must be a
C<App::Chart::Series::Database> object.  The adjustments are controlled by
the following options arguments taken in key/value style

    adjust_splits        adjust for stock splits
    adjust_dividends     adjust for dividends (as reinvested)
    adjust_imputation    include imputation credits in dividends

For example

    my $db_series = App::Chart::Series::Database->new ('BHP.AX');

    my $adj_series = App::Chart::Series::Derived::Adjust->derive
      ($db_series, adjust_splits => 1,
                   adjust_dividends => 1);

If the options ask for no adjustments at all, or there's no splits etc in
the database for the C<$series> symbol then C<$series> is simply returned.

=back

=head1 SEE ALSO

L<App::Chart::Series::Database>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
