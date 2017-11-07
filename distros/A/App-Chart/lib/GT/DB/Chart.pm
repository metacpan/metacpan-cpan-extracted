# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017 Kevin Ryde

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

package GT::DB::Chart;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util;

# don't "use base" since GT::DB as of 2010 doesn't have a $VERSION and
# base.pm will warn and assign $GT::DB::VERSION=-1
use GT::DB;
our @ISA = ('GT::DB');

use GT::Prices;
use GT::Conf;
use GT::DateTime;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 264;

# extra appended to GT::Prices elements giving the tdate etc corresponding
# to the $DATE element
our $DATE_T = List::Util::max ($OPEN, $HIGH, $LOW, $CLOSE, $VOLUME, $DATE) + 1;

sub new {
  my ($class, $series, $hi) = @_;
  return bless { series => $series,
                 hi => $hi,
               }, $class;
}

sub disconnect {
  my ($self) = @_;
  if (App::Chart::DBI->can('disconnect')) { # if loaded
    App::Chart::DBI->disconnect;
  }
}

sub has_code {
  my ($self, $symbol) = @_;
  ### GT-DB-Chart has_code(): $symbol
  require App::Chart::Database;
  return App::Chart::Database->symbol_exists ($symbol);
}

sub get_db_name {
  my ($self, $symbol) = @_;
  ### GT-DB-Chart get_db_name(): $symbol
  require App::Chart::Database;
  return App::Chart::Database->symbol_name ($symbol);
}

my %timeframe_to_class = ($WEEK  => 'Weeks',
                          $MONTH => 'Months',
                          $YEAR  => 'Years');

sub get_prices {
  my ($self, $symbol, $timeframe) = @_;
  return $self->get_last_prices ($symbol, -1, $timeframe);
}

sub get_last_prices {
  my ($self, $symbol, $limit, $timeframe) = @_;
  ### GT-DB-Chart get_last_prices(): $symbol
  ### $limit
  ### $timeframe

  $timeframe ||= $DAY;
  my $prices = GT::Prices->new;
  $prices->set_timeframe ($timeframe);

  if ($timeframe < $DAY) {
    ### no intraday data
    return $prices;
  }
  if ($limit == 0) {
    return $prices;
  }

  my $series = $self->{'series'} || do {
    require App::Chart::Series::Database;
    App::Chart::Series::Database->new ($symbol);
  };
  if ($timeframe != $DAY) {
    # can leave this to GT::Tools too, maybe
    my $class = $timeframe_to_class{$timeframe}
      or croak __PACKAGE__.": unrecognised timeframe $timeframe";
    $series = $series->collapse ($class);
  }

  my $hi = $self->{'hi'} // $series->hi;
  my $lo;
  if ($limit == -1) {
    $lo = 0; # all data
  } else {
    # the newest $limit many values
    $lo = $series->find_before ($hi, $limit-1);
  }

  $series->fill ($lo, $hi);
  my $opens    = $series->array('opens')   || [];
  my $highs    = $series->array('highs')   || [];
  my $lows     = $series->array('lows')    || [];
  my $closes   = $series->array('closes')  || $series->values_array;
  my $volumes  = $series->array('volumes') || [];
  my $timebase = $series->timebase;

  foreach my $t ($lo .. $hi) {
    $closes->[$t] // next;
    my @elem;
    $elem[$DATE_T] = $t;
    $elem[$OPEN]   = $opens->[$t] || $closes->[$t];
    $elem[$HIGH]   = $highs->[$t] || $closes->[$t];
    $elem[$LOW]    = $lows->[$t]  || $closes->[$t];
    $elem[$CLOSE]  = $closes->[$t];
    $elem[$VOLUME] = $volumes->[$t] || 0;
    $elem[$DATE]   = $timebase->to_iso($t);
    $prices->add_prices (\@elem);  # added in ascending date order
  }
  return $prices;
}

1;
__END__

=for stopwords GeniusTrader Ryde

=head1 NAME

GT::DB::Chart - GeniusTrader access to data from Chart

=head1 SYNOPSIS

 use GT::DB::Chart;
 my $db = GT::DB::Chart->new;
 my $prices = $db->get_prices ('BHP.AX', $GT::Prices::DAYS);

=head1 DESCRIPTION

This is a C<GT::DB> module giving access to the Chart database from
GeniusTrader scripts and calculations.

=head1 FUNCTIONS

=over 4

=item C<< $db = GT::DB::Chart->new() >>

Create and return a new C<GT::DB::Chart> object to retrieve data from
the Chart database (F<~/Chart/database.sqdb>).

=item C<< $db->disconnect() >>

Disconnect from the Chart database.

=item C<< $prices = $db->get_prices ($symbol, $timeframe) >>

=item C<< $prices = $db->get_last_prices ($symbol, $limit, $timeframe) >>

Create and return a C<GT::Prices> object with the data for C<$symbol> in the
given C<$timeframe> increments.  C<$timeframe> can be C<$DAYS>, C<$WEEKS>,
C<$MONTHS> or C<$YEARS>.

C<get_prices()> returns all available data for C<$symbol>,
C<get_last_prices()> returns only the most recent C<$limit> many values (or
as many as available).  For example to get the last 250 trading days,

    my $prices = $db->get_last_prices ('GM', 250,
                                       $GT::Prices::DAYS);

=item C<< $str = $db->get_db_name ($symbol) >>

Return the company name for the stock C<$symbol>, or C<undef> if unknown.

For most applications use C<< $db->get_name() >> instead (see C<GT::DB>),
since it tries your F<~/.gt/sharenames> file if nothing from
C<get_db_name()>.

=back

=head1 SEE ALSO

L<GT::DB>, L<GT::Prices>

L<App::Chart::Series::Database>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017 Kevin Ryde

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
