# Copyright 2007, 2008, 2009, 2010, 2011, 2014, 2015, 2016, 2017 Kevin Ryde

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

package App::Chart::Latest;
use 5.006;
use strict;
use warnings;
use Date::Calc;
use Encode;
use List::Util qw(min max);
use POSIX ();
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::LatestHandler;
use App::Chart::TZ;
use App::Chart::Timebase;

# uncomment this to run the ### lines
# use Smart::Comments;

our %get_cache = ();

sub _purge_cache_on_latest_changed {
  my ($symbol_hash) = @_;
  ### _purge_cache_on_latest_changed(): join (', ', grep {exists $get_cache{$_}} keys %$symbol_hash)

  delete @get_cache{keys %$symbol_hash}; # hash slice
}

sub get {
  my ($class,$symbol) = @_;
  ### Latest: $symbol

  if (! tied %get_cache) {
    require Tie::Cache;
    tie %get_cache, 'Tie::Cache', { MaxCount => 100 };
    App::Chart::chart_dirbroadcast()->connect_first
        ('latest-changed', \&_purge_cache_on_latest_changed);
  }
  if (my $latest = $get_cache{$symbol}) {
    ### cached: $latest
    return $latest;
  }

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $latest = do {
    my $sth = $dbh->prepare_cached
      ('SELECT symbol, name, currency,
               quote_date, quote_time, bid, offer,
               last_date, last_time, open, high, low, last, change, volume,
               source, halt, limit_up, limit_down,
               dividend, note, error, fetch_timestamp
        FROM latest
        WHERE symbol=?');
    $dbh->selectrow_hashref ($sth, undef, $symbol);
  };
  ### FROM latest: $latest

  if (! defined $latest) {
    my $sth = $dbh->prepare_cached
      ('SELECT symbol, date, open, high, low, close, volume
        FROM daily WHERE symbol=? AND close NOT NULL
        ORDER BY date DESC LIMIT 2');
    my $aref = $dbh->selectall_arrayref ($sth, { Slice => {} }, $symbol);
    $latest = $aref->[0];
    my $prev = $aref->[1];
    if (defined ($latest)) {
      $latest->{'last_date'}       = delete $latest->{'date'};
      my $last = $latest->{'last'} = delete $latest->{'close'};
      $latest->{'source'}          = 'database';

      if (defined $last && defined(my $prev_close = $prev->{'close'})) {
        $latest->{'change'} = App::Chart::decimal_sub ($last, $prev_close);
      }

      my $info_get_sth = $dbh->prepare_cached
        ('SELECT name, currency, exchange FROM info WHERE symbol=?');
      ($latest->{'name'}, $latest->{'currency'}, $latest->{'exchange'})
        = $dbh->selectrow_array ($info_get_sth, undef, $symbol);
    }
    ### FROM daily: $latest
  }

  # if the latest record doesn't already have a dividend then check the database
  # (and always do so when constructing from daily data)
  if (defined $latest && defined $latest->{'last_date'}) {
    $latest->{'dividend'} //= App::Chart::DBI->read_single
      ('SELECT amount FROM dividend WHERE symbol=? AND ex_date=?',
       $symbol, $latest->{'last_date'});
  }

  if (! defined ($latest)) {
    $latest = { symbol => $symbol,
                error  => __('no data'),
                source => 'dummy' };
    ### fallback no data: $latest
  }

  #   $latest->{'inprogress'} = ($App::Chart::Gtk2::Job::Latest::inprogress{$symbol}
  #                              ? 1 : 0);

  $get_cache{$symbol} = $latest;
  return bless $latest, $class;
}

sub quote_adate {
  my ($self) = @_;
  my $iso = $self->{'quote_date'};
  if (! defined $iso) { return undef; }
  return iso_to_adate ($iso);
}

sub last_adate {
  my ($self) = @_;
  my $iso = $self->{'last_date'};
  if (! defined $iso) { return undef; }
  return iso_to_adate ($iso);
}

sub iso_to_adate {
  my ($iso) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($iso);
  return App::Chart::ymd_to_adate ($year, $month, $day);
}

sub short_datetime {
  my ($self) = @_;
  return ($self->{'short_datetime'} ||= do {
    my $isodate = $self->{'quote_date'};
    my $timestr = $self->{'quote_time'};

    # if there's a quote date but no bid/offer, then use last-date, but only
    # if there's an actual value for last-date
    if ((! defined $isodate || (! $self->{'bid'} && ! $self->{'offer'}))
        && defined $self->{'last_date'}) {
      $isodate = $self->{'last_date'};
      $timestr = $self->{'last_time'};
    }
    form_short_datetime ($self->{'symbol'}, $isodate, $timestr)
  });
}


sub hmsstr_to_seconds {
  my ($str) = @_;
  my ($hour, $min, $sec) = split /:/, $str;
  return App::Chart::hms_to_seconds ($hour, $min, $sec||0);
}

sub mjd_to_week {
  my ($mjd) = @_;
  return int (($mjd+2) / 7);
}

# $show_iso is an ISO date string like '2008-08-20'
# $show_timestr is a time string like '14:59:59'
# both are in the timezone of $symbol
# return a short string representing the date and/or time
#
sub form_short_datetime {
  my ($symbol, $show_iso, $show_timestr) = @_;
  if (! defined $show_iso) { return ''; }

  my $timezone = App::Chart::TZ->for_symbol ($symbol);
  my ($now_year, $now_month, $now_day) = $timezone->ymd;
  my $now_iso = App::Chart::ymd_to_iso ($now_year, $now_month, $now_day);

  if ($now_iso eq $show_iso) {
    if (defined $show_timestr) {
      $show_timestr =~ s/:[0-9]+$//;  # lose trailing seconds
      return $show_timestr;
    } else {
      return __('Today');
    }
  }

  my ($show_year, $show_month, $show_day) = App::Chart::iso_to_ymd ($show_iso);

  my $now_days  = Date::Calc::Date_to_Days ($now_year, $now_month, $now_day);
  my $show_days = Date::Calc::Date_to_Days ($show_year,$show_month,$show_day);

  # 1=Mon, 2=Tue, ...
  my $now_dow  = Date::Calc::Day_of_Week ($now_year, $now_month, $now_day);
  my $show_dow = Date::Calc::Day_of_Week ($show_year, $show_month, $show_day);

  my $now_wdate  = $now_days - $now_dow;
  my $show_wdate = $show_days - $show_dow;

  # default full date
  my $format = '%d%b%Y';

  if ($now_wdate == $show_wdate
      || ($now_wdate == $show_wdate + 1
          && (($now_dow == 1 || $now_dow == 2)  # Mon or Tue
              && $now_days - $show_days <= 4))) {
    # for same week, or on Mon the prev Thu,Fri or on Tue the prev Fri, just
    # show day
    $format = '%a';

  } elsif ($show_year == $now_year
           || ($show_year + 1 == $now_year
               && $show_month == 12 && $now_month == 1)) {
    # for this year, or for Dec in Jan, just show mday+month
    $format = '%d-%b';

  } elsif (abs ($show_year - $now_year) < 40) {
    # for +/- 40 years of today, show abbreviated year
    $format = '%d%b%y';
  }

  return App::Chart::Timebase::strftime_ymd
    ($format, $show_year, $show_month, $show_day);
}

sub mjd_to_weeknum {
  my ($mjd) = @_;
  return POSIX::floor ((POSIX::floor($mjd)  - 2) / 7);
}

sub formatted_volume {
  my ($latest) = @_;
  my $volume = $latest->{'volume'};
  if (! defined $volume) { return undef; }
  if (my $fv = $latest->{'formatted_volume'}) { return $fv; }

  my $suffix = '';
  if ($volume >= 10_000_000_000) {
    # billions
    $volume /= 1_000_000_000;
    $suffix = __p('billions','b');
  } elsif ($volume >= 10_000_000) {
    # millions
    $volume /= 1_000_000;
    $suffix = __p('millions','m');
  } elsif ($volume >= 10_000) {
    # millions
    $volume /= 1_000;
    $suffix = __p('thousands','k');
  }
  my $decimals = max (0, 3 - num_integer_digits ($volume));
  my $nf = App::Chart::number_formatter();
  return ($latest->{'formatted_volume'}
          = $nf->format_number ($volume, $decimals, 0) . $suffix);
}

sub num_integer_digits {
  my ($n) = @_;
  return 1 + max (0, POSIX::floor (POSIX::log10 (abs ($n))));
}

1;
__END__

=for stopwords adate

=head1 NAME

App::Chart::Latest -- latest price records

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Latest->get ($symbol) >>

Return a latest prices object for C<$symbol>.  It contains the following
fields

Basic information

    symbol        string
    name          string
    currency      string

Latest bid/offer quote

    quote_date    ISO string like 2008-08-20
    quote_time    string like 14:59:59
    bid           best buyer's price
    offer         best seller's price

Latest trading day

    last_date     ISO string like 2008-08-20
    last_time     string like 14:59:59
    open          day's first trade price
    high          day's highest trade price
    low           day's lowest trade price
    last          last trade price
    change        difference 'last' from the previous day's close
    volume        day's volume, so far

Other information

    halt          1 if trading halted
    limit_up      1 if at its daily limit up move
    limit_down    1 if at its daily limit down move
    dividend      ex-dividend amount, if ex today (ie. 'last_date')
    note          other free-form note
    error         message string

Dates and times are in the timezone of C<$symbol>.

=item C<< $latest->quote_adate() >>

=item C<< $latest->last_adate() >>

Return the quote date or last trade date in the form of an "adate" number.

=item C<< $latest->short_datetime() >>

Return a string which is a short form of the date time in C<$latest>.  The
quote date/time is used if present, or the last trade date/time if not.

=item C<< $latest->formatted_volume() >>

Return a string which is the C<$latest> volume figure formatted and
abbreviated.  For example a value 150000 gives C<"150k">.

=back

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2014, 2015, 2016, 2017 Kevin Ryde

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
