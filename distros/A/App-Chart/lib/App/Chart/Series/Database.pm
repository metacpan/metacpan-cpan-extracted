# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023, 2024 Kevin Ryde

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

package App::Chart::Series::Database;
use 5.010;
use strict;
use warnings;
use Carp;
use Scalar::Util;

use App::Chart::Database;
use App::Chart::DBI;
use base 'App::Chart::Series::OHLCVI';

our $VERSION = 273;

use constant DEBUG => 0;

# %cache is keyed by symbol string, with value a App::Chart::Series::Database
# object.  The value reference is weakened so it becomes undef when
# otherwise unused.
#
our %cache = ();

sub _purge_cache_on_data_changed {
  my ($symbol_hash) = @_;
  if (DEBUG) {
    print "data-changed, purge series: ",
      join (', ', grep {exists $cache{$_}} keys %$symbol_hash),"\n";
  }
  delete @cache{keys %$symbol_hash}; # hash slice
}
use constant::defer _init_cache => sub {
  App::Chart::chart_dirbroadcast()->connect_first
      ('data-changed', \&_purge_cache_on_data_changed);
  return;
};

sub new {
  my ($class, $symbol) = @_;
  if (DEBUG) { print "Series new $symbol\n"; }

  my $self = $cache{$symbol};
  if ($self) { return $self; }

  my $base = App::Chart::DBI->read_single
    ('SELECT date FROM daily WHERE symbol=? ORDER BY date ASC LIMIT 1',
     $symbol);
  if (! $base) {
    require App::Chart::TZ;
    my $timezone = App::Chart::TZ->for_symbol ($symbol);
    $base = $timezone->iso_date;
  }
  if (DEBUG) { print "  base $base\n"; }
  require App::Chart::Timebase::Days;
  my $timebase = App::Chart::Timebase::Days->new_from_iso ($base);

  $self = $class->SUPER::new (symbol   => $symbol,
                              timebase => $timebase);

  # lose any cache entries which have gone undef through weaks destroyed
  delete @cache{grep {! $cache{$_}} keys %cache};

  # add new entry
  _init_cache();
  $cache{$symbol} = $self;
  Scalar::Util::weaken ($cache{$symbol});

  return $self;
}

sub hi {
  my ($self) = @_;
  if (! exists $self->{'hi'}) {
    if (DEBUG) { print "Series hi for $self->{'symbol'}\n"; }
    my $date = App::Chart::DBI->read_single
      ('SELECT date FROM daily WHERE symbol=? ORDER BY date DESC LIMIT 1',
       $self->{'symbol'});
    if (DEBUG) { print "  iso ",$date//'undef',"\n"; }
    my $timebase = $self->{'timebase'};
    $self->{'hi'} = ($date
                     ? $timebase->from_iso_floor ($date)
                     : 0);
    if (DEBUG) { print "  hi=$self->{'hi'}\n"; }
  }
  return $self->{'hi'};
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  if (DEBUG) { print "Database $self->{'symbol'} fill_part $lo $hi\n"; }

  my $dbh = App::Chart::DBI->instance;
  my $timebase = $self->{'timebase'};

  # date descending so first store pre-extends the respective arrays
  my $sth = $dbh->prepare_cached
    ('SELECT date, open, high, low, close, volume, openint
      FROM daily WHERE (symbol=? AND (date BETWEEN ? AND ?))
      ORDER BY date DESC');

  my $aref = $dbh->selectall_arrayref ($sth, undef,
                                       $self->{'symbol'},
                                       $timebase->to_iso ($lo),
                                       $timebase->to_iso ($hi));
  $sth->finish;

  my $opens    = $self->array('opens');
  my $highs    = $self->array('highs');
  my $lows     = $self->array('lows');
  my $closes   = $self->array('closes');
  my $volumes  = $self->array('volumes');
  my $openints = $self->array('openints');

  foreach my $row (@$aref) {
    my $i = $timebase->from_iso_floor ($row->[0]);
    next if ($i < 0);

    if (defined $row->[1]) { $opens->[$i]    = $row->[1]; }
    if (defined $row->[2]) { $highs->[$i]    = $row->[2]; }
    if (defined $row->[3]) { $lows->[$i]     = $row->[3]; }
    if (defined $row->[4]) { $closes->[$i]   = $row->[4]; }
    if (defined $row->[5]) { $volumes->[$i]  = $row->[5]; }
    if (defined $row->[6]) { $openints->[$i] = $row->[6]; }
  }
}

sub name {
  my ($self) = @_;
  return $self->symbol;  # in Series.pm
}
#  {
#   $self->{'symbol'}
# 
#   if (! exists $self->{'name'}) {
#     $self->{'name'} = App::Chart::Database->symbol_name ($self->{'symbol'});
#   }
#   return $self->{'name'}
# }
sub symbol_name {
  my ($self) = @_;
  return App::Chart::Database->symbol_name ($self->{'symbol'});
}

sub decimals {
  my ($self) = @_;
  if (! exists $self->{'decimals'}) {
    $self->{'decimals'}
      = App::Chart::Database->symbol_decimals ($self->{'symbol'});
  }
  return $self->{'decimals'};
}

sub dividends {
  my ($self) = @_;
  return ($self->{'dividends'} ||= do {
    my $dbh = App::Chart::DBI->instance;
    my $sth = $dbh->prepare_cached
      ('SELECT ex_date, type, amount, imputation, qualifier, note
        FROM dividend WHERE symbol=? ORDER BY ex_date ASC');
    my $aref = $dbh->selectall_arrayref ($sth, {Slice=>{}}, $self->{'symbol'});

    my $timebase = $self->{'timebase'};
    foreach my $div (@$aref) {
      foreach my $date (qw(ex_date record_date pay_date)) {
        my $iso = $div->{$date} or next;
        my $t   = $timebase->from_iso_floor ($iso);
        $div->{$date.'_t'} = $t;
      }
    }
    $aref
  });
}

sub splits {
  my ($self) = @_;
  return ($self->{'splits'} ||= do {
    my $dbh = App::Chart::DBI->instance;
    my $sth = $dbh->prepare_cached
      ('SELECT date, new, old, note
        FROM split WHERE symbol=? ORDER BY date ASC');
    my $aref = $dbh->selectall_arrayref ($sth, {Slice=>{}}, $self->{'symbol'});

    my $timebase = $self->{'timebase'};
    foreach my $div (@$aref) {
      my $iso = $div->{'date'} or next;
      my $t   = $timebase->from_iso_floor ($iso);
      $div->{'date_t'} = $t;
    }
    $aref
  });
}

sub annotations {
  my ($self) = @_;
  return ($self->{'annotations'} ||= do {
    if (DEBUG) { print "Series::Database read annotations ",
                   $self->{'symbol'},"\n"; }
    my $dbh = App::Chart::DBI->instance;
    my $sth = $dbh->prepare_cached
      ('SELECT id, date, note FROM annotation
        WHERE symbol=? ORDER BY date ASC');
    my $aref = $dbh->selectall_arrayref ($sth, {Slice=>{}}, $self->{'symbol'});

    my $timebase = $self->{'timebase'};
    foreach my $ann (@$aref) {
      my $iso = $ann->{'date'} or next;
      my $t   = $timebase->from_iso_floor ($iso);
      $ann->{'date_t'} = $t;
    }
    $aref
  });
}

sub Alerts_arrayref  {
  my ($series) = @_;
  return ($series->{__PACKAGE__.'.array'} ||= do {
    my $symbol = $series->symbol || '';
    require App::Chart::DBI;
    my $dbh = App::Chart::DBI->instance;

    my $sth = $dbh->prepare_cached ('SELECT * FROM alert WHERE symbol=?');
    my $aref = $dbh->selectall_arrayref ($sth, {Slice=>{}}, $symbol);
    $sth->finish;
    if (@$aref) {
      require App::Chart::Annotation;
      foreach my $elem (@$aref) {
        bless $elem, 'App::Chart::Annotation::Alert';
      }
    }
    $aref;
  });
}


1;
__END__

=for stopwords OHLCVI

=head1 NAME

App::Chart::Series::Database -- symbol data series from database

=head1 SYNOPSIS

 use App::Chart::Series::Database;
 my $series = App::Chart::Series::Database->new ('BHP.AX');

=head1 CLASS HIERARCHY

    App::Chart::Series
      App::Chart::Series::OHLCVI
        App::Chart::Series::Database

=head1 FUNCTIONS

=over 4

=item C<< $series = App::Chart::Series::Database->new ($symbol) >>

Return a series object which is the OHLCVI data for C<$symbol> from the
database.

If the database changes then C<new()> should be called again to get a new
object with new values, date range, etc.

=back

=head1 SEE ALSO

L<App::Chart::Series::OHLCVI>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023, 2024 Kevin Ryde

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
