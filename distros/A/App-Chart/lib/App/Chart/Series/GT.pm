# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::GT;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use base 'App::Chart::Series';

use GT::Prices;
use GT::Conf;
use GT::Eval;
use GT::DateTime;
use GT::Tools;

use constant DEBUG => 0;


my %class_to_timeframe = ('App::Chart::Timebase::Days'   => $DAY,
                          'App::Chart::Timebase::Weeks'  => $WEEK,
                          'App::Chart::Timebase::Months' => $MONTH,
                          'App::Chart::Timebase::Years'  => $YEAR);

sub new {
  my ($class, $type, $parent, @args) = @_;
  if (DEBUG) { local $,=' '; say "GT->new type '$type' args", @args; }
  my $indicator = GT::Eval::create_standard_object ($type, @args);
  my $nb_values = $indicator->get_nb_values;
  my $arrays = {};
  foreach my $i (0 .. $nb_values-1) {
    my $name = $indicator->get_name ($i);
    $arrays->{$name} = [];
  }
  my $array_aliases = { values => $indicator->get_name(0) };
  if (DEBUG) { require Data::Dumper;
               print "  ",Data::Dumper->Dump([$arrays],['arrays']);
               print "  ",Data::Dumper->Dump([$array_aliases],
                                             ['array_aliases']); }

  return $class->SUPER::new (parent        => $parent,
                             indicator     => $indicator,
                             arrays        => $arrays,
                             array_aliases => $array_aliases);
}

sub name {
  my ($self) = @_;
  my $indicator = $self->{'indicator'};
  return $indicator->get_name;
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  if (DEBUG) { say "GT fill_part $lo $hi"; }

  my $parent = $self->{'parent'};
  my $timebase = $self->timebase;
  my $indicator = $self->{'indicator'};

  require GT::DB::Chart;
  my $db = GT::DB::Chart->new ($parent, $hi);
  my $code = $parent->symbol || 'DUMMY-STOCK-CODE';
  my $timebase_class = ref $timebase;
  # ENHANCE-ME: can probably fallback to $DAYS or something for unknown
  # $timebase_class, not much in the GT indicators depends on the timebase
  my $timeframe = $class_to_timeframe{$timebase_class}
    || croak "Timebase class $timebase_class not known to GT";
  my $full = 0;
  my $start = $timebase->to_iso ($lo);
  my $end = $timebase->to_iso ($hi);
  my $nb_item = 0;
  my $max_loaded_items = $hi - $lo + 1 + $indicator->days_required;

  if (DEBUG) { say "  find_calculator  start=$start end=$end code=$code timeframe=$timeframe max_loaded_items=$max_loaded_items"; }
  my ($calc, $first, $last);

  if (! eval {
    ($calc, $first, $last) = GT::Tools::find_calculator
      ($db, $code, $timeframe, $full, $start,$end,$nb_item,$max_loaded_items);
    1
  }) {
    if ($@ =~ /No data available/i) { return; }
    die $@;
  }
  if (DEBUG) { say "  gives  first=$first last=$last"; }

  $indicator->calculate_interval ($calc, $first, $last);

  my $nb_values = $indicator->get_nb_values;
  my $indic_cache = $calc->indicators;  # GT::Cache of indicator results
  my $prices = $calc->prices;           # GT::Prices inputs
  if (DEBUG >= 2) {
    require Data::Dumper;
    print "  ",Data::Dumper->Dump([$indicator],['indicator']);
    print "  ",Data::Dumper->Dump([$prices],['prices']);
    print "  ",Data::Dumper->Dump([$indic_cache],['indic_cache']);
  }

  for (my $n = 0; $n < $nb_values; $n++) {
    my $name = $indicator->get_name($n);
    my $array = $self->{'arrays'}->{$name};

    # reverse to pre-extend $array
    for (my $i = $last; $i >= $first; $i--) {
      my $value = $indic_cache->get($name, $i) // next;
      my $t = $prices->at($i)->[$GT::DB::Chart::DATE_T];
      $array->[$t] = $value;
      if (DEBUG >= 2) { print "    i=$i t=$t value=$value\n"; }
    }
  }
  if (DEBUG >= 2) { print "\n"; }
}

1;
__END__

=for stopwords GeniusTrader

=head1 NAME

App::Chart::Series::GT -- ...

=for test_synopsis my ($parent)

=head1 SYNOPSIS

 use App::Chart::Series::GT;
 my $series = App::Chart::Series::GT->new ('I:SMA', $parent);

=head1 CLASS HIERARCHY

    App::Chart::Series
      App::Chart::Series::GT

=head1 DESCRIPTION

A C<App::Chart::Series::GT> series applies a GeniusTrader indicator or
average to a given series.  You must have GeniusTrader available to use
this, see

=over

L<http://www.geniustrader.org/>

=back

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Series::GT->new ($gt_type, $parent, $arg...) >>

...

=back

=head1 SEE ALSO

L<App::Chart::Series>, GeniusTrader, L<App::Chart::Series::TA>

=cut
