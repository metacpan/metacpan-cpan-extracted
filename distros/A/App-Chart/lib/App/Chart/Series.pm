# Copyright 2007, 2008, 2009, 2010, 2011, 2016, 2024 Kevin Ryde

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

package App::Chart::Series;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');
use Set::IntSpan::Fast 1.10;    # 1.10 for contains_all_range

use App::Chart;

# uncomment this to run the ### lines
#use Devel::Comments '###';

# defaults
use constant { default_linestyle => 'Line',
               dividends      => [],
               splits         => [],
               annotations    => [],
               parameter_info => [],
               minimum        => undef,
               maximum        => undef,
               hlines         => [],
               units          => '',
             };

sub new {
  #### Series new: @_
  my $class = shift;
  my $self = bless { fill_set => Set::IntSpan::Fast->new,
                     @_ }, $class;
  if (my $parent = $self->{'parent'}) {
    $self->{'arrays'} ||= { map {; $_ => [] }
                            keys %{$parent->{'arrays'}} };
    $self->{'array_aliases'} ||= $parent->{'array_aliases'};
  }
  $self->{'array_aliases'} ||= {};
  return $self;
}

sub name {
  my ($self) = @_;
  return $self->{'name'};
}
sub parent {
  my ($self) = @_;
  return $self->{'parent'};
}

sub timebase {
  my ($self) = @_;
  return ($self->{'timebase'} || $self->{'parent'}->timebase);
}

sub decimals {
  my ($self) = @_;
  if (exists $self->{'decimals'}) { return $self->{'decimals'}; }
  return $self->{'parent'}->decimals;
}

sub symbol {
  my ($self) = @_;
  if (exists $self->{'symbol'}) { return $self->{'symbol'}; }
  if (my $parent = $self->{'parent'}) { return $parent->symbol; }
  return undef;
}

sub hi {
  my ($self) = @_;
  if (exists $self->{'hi'}) { return $self->{'hi'}; }
  return $self->{'parent'}->hi;
}

sub values_array {
  my ($self) = @_;
  return $self->array('values');
}
sub array {
  my ($self, $aname) = @_;
  return ($self->{'arrays'}->{$aname}
          || do { my $alias = $self->{'array_aliases'}->{$aname};
                  $alias && $self->{'arrays'}->{$alias} });
  # croak "No such array in $self: $aname");
}
sub array_names {
  my ($self) = @_;
  return keys %{$self->{'arrays'}};
}

sub fill {
  my ($self, $lo, $hi) = @_;
  if ($lo > $hi) { croak "Series fill lo>hi ($lo, $hi)\n"; }
  if ($hi < 0) { return; }      # nothing
  {
    my $sh = $self->hi;
    $lo = min ($sh, max (0, $lo));
    $hi = min ($sh, $hi);
  }

  my $got_set = $self->{'fill_set'};
  if ($got_set->contains_all_range ($lo, $hi)) { return; } # covered already

  my $want_set = Set::IntSpan::Fast->new;
  $want_set->add_range ($lo, $hi);
  $want_set = $want_set->diff ($got_set);
  ### fill: "$lo-$hi of ".ref($self)
  ### want: $want_set->as_string." on top of ".$got_set->as_string

  # merge now so don't repeat if error in code below
  $got_set->merge ($want_set);
  ### merge to: $got_set->as_string

  my $values = $self->values_array;
  my @array_names = $self->array_names;
  if ($self->array('volumes') && $self->array('volumes') != $values) {
    @array_names = grep {$_ ne 'volumes'} @array_names;
  }
  if ($self->array('openints') && $self->array('openints') != $values) {
    @array_names = grep {$_ ne 'openints'} @array_names;
  }
  my @arrays = map {$self->array($_)} @array_names;

  my $method = ($self->can('fill_part')
                || ($self->can('proc') && 'fill_part_from_proc')
                || die "Series $self has no fill method");

  my $iter = $want_set->iterate_runs;
  while (my ($lo, $hi) = $iter->()) {
    ### do: "$method $lo, $hi"
    $self->$method ($lo, $hi);

    foreach my $array (@arrays) {
      $self->{'fill_high'} = App::Chart::max_maybe ($self->{'fill_high'},
                                                   @{$array}[$lo .. $hi]);
      $self->{'fill_low'} = App::Chart::min_maybe ($self->{'fill_low'},
                                                  @{$array}[$lo .. $hi]);
    }
    ### merge to: $got_set->as_string
  }
}

sub range {
  my ($self, $lo, $hi, @array_names) = @_;
  ### Series range: "$lo $hi of @array_names"
  $lo = max ($lo, 0);
  if ($hi < $lo) { return; }    # eg. lo==-5 hi==-1, no data before 0
  $self->fill ($lo, $hi);
  my $arrays_hash = $self->{'arrays'}; # hash
  if (! @array_names) {
    @array_names = $self->range_default_names;
  }
  my @arefs = @{$arrays_hash}{@array_names}; # hash slice

  require List::MoreUtils;
  return List::MoreUtils::minmax
    (grep {defined} map { @{$_}[$lo .. $hi] } @arefs);
}
sub range_default_names {
  my ($self) = @_;
  return keys %{$self->{'arrays'}};  # all arrays
}

sub linestyle {
  my ($self, $newval) = @_;
  if (@_ >= 2) {
    $self->{'linestyle'} = $newval;
  } elsif ($self->{'linestyle'}) {
    return $self->{'linestyle'};
  } else {
    return $self->default_linestyle;
  }
}
sub linestyle_class {
  my ($self) = @_;
  my $linestyle = $self->linestyle // return undef;
  return "App::Chart::Gtk2::LineStyle::$linestyle";
}

# Return (LOWER UPPER) which is a suggested initial Y-axis page range to
# show for dates LO to HI.  This is for use both with
# App::Chart::Series::OHLCVI and also any other series type without its own
# specific style.
#
# As described in "Main Window" in the manual, the aim is to scale according
# to apparent volatility, so that daily range or daily close-to-close change
# are some modest fraction of the initial page.  In particular if the series
# is just going sideways it's not zoomed out to try to fill the whole
# screen.  The absolute price level is not used, so say bond prices which
# hover near 100 still get scaled out to make typical daily changes of 0.1
# or whatever visible.
#
sub initial_range {
  my ($self, $lo, $hi) = @_;
  ### Series initial_range: "$lo to $hi   $self"
  $lo = max ($lo, 0);
  $hi = max ($hi, 0);
  $self->fill ($lo, $hi);
  my $highs = $self->array('highs') // [];
  my $lows  = $self->array('lows') // $highs;
  my $values = $self->values_array;
  my @diffs = ();

  my $timebase = $self->timebase;
  my $latest;
  if ($self->units eq 'price'
      && (my $symbol = $self->symbol)) {
    $latest = defined $symbol && App::Chart::Latest->get($symbol);
  }
  if ($latest
      && defined $latest->{'high'}
      && defined $latest->{'low'}
      && defined (my $last_iso = $latest->{'last_date'})) {
    my $last_t = $timebase->from_iso_floor ($last_iso);
    if ($last_t >= $lo && $last_t <= $hi) {
      push @diffs, $latest->{'high'} - $latest->{'low'};
    }
  }

  # high to low ranges in ohlcv
  if ($highs != $lows) {
    foreach my $i ($lo .. $hi) {
      if (defined $highs->[$i] && defined $lows->[$i]) {
        my $diff = CORE::abs ($highs->[$i] - $lows->[$i]);
        if ($diff != 0) {
          push @diffs, $diff;
        }
      }
    }
  }

  # ENHANCE-ME: look at all parts of a multi-line like macd, bollinger,
  # guppy, etc
  #     (if (= 2 (array-rank array))
  # 	# macd, not quite right
  # 	(set! array (make-shared-array-column array 0)))

  # close to close ranges
  {
    my $prev;
    foreach my $i ($lo .. $hi) {
      my $value = $values->[$i];
      if (! defined $value) { next; }

      if (defined $prev) {
        my $diff = CORE::abs ($value - $prev);
        if ($diff != 0) {
          push @diffs, $diff;
        }
      }
      $prev = $value;
    }
  }

  if (! @diffs) {
    ### no diffs for initial range: "$lo $hi"
    my ($l, $h) = $self->range ($lo, $hi);
    if (defined $l) {
      # for just a single close value pretend 20% around the value
      return $h * 0.8, $l / 0.8;
    }
    return;
  }

  # page will show 25x the median range
  @diffs = sort {$a <=> $b} @diffs;
  my $page = 25 * $diffs[CORE::int ($#diffs / 2)];
  ### initial page by: "25*median is $page"

  # make page no more than twice upper,lower data range, so the
  # data is not less than half the window
  { my ($l, $h) = $self->range ($lo, $hi);
    if (defined $l) {
      ### series range: "$l to $h"
      $page = min ($page, 2 * ($h - $l));
    }
  }
  ### shrink to use minimum half window: $page

  # make page no smaller than last 1/2 of data, so that's visible
  { my ($l, $h) = $self->range (CORE::int (($lo + $hi) / 2), $hi);
    if ($l) { $page = max ($page, $h - $l); }
  }
  ### expand so last half data visible: $page

  my ($l, $h);
  my $accumulate = sub {
    my ($value) = @_;
    ### accumulate: $value
    if (! defined $value) { return 1; }
    my $new_l = defined $l ? min ($value, $l) : $value;
    my $new_h = defined $h ? max ($value, $h) : $value;
    if ($new_h - $new_l <= $page) {
      $l = $new_l;
      $h = $new_h;
    }
    if (! defined $l) {
      $l = $new_l;
      $h = $new_l + $page;
    }
    return 0;
  };
  if ($latest) {
    if (defined (my $quote_iso = $latest->{'quote_date'})) {
      my $quote_t = $timebase->from_iso_floor ($quote_iso);
      if ($quote_t >= $lo && $quote_t <= $hi) {
        $accumulate->($latest->{'bid'});
        $accumulate->($latest->{'offer'});
      }
    }
    if (defined (my $last_iso = $latest->{'last_date'})) {
      my $last_t = $timebase->from_iso_floor ($last_iso);
      if ($last_t >= $lo && $last_t <= $hi) {
        $accumulate->($latest->{'last'});
        $accumulate->($latest->{'high'});
        $accumulate->($latest->{'low'});
      }
    }
  }
  for (my $i = $hi; $i >= $lo; $i--) {
    foreach my $value ($values->[$i], $highs->[$i], $lows->[$i]) {
      $accumulate->($value);
    }
  }

  my $extra = ($page - ($h - $l)) / 2;
  $l -= $extra;
  $h += $extra;
  ### initial range decided: "$l $h   $self"
  return ($l, $h);
}

# 	    # don't go below `datatype-minimum' (if present), so long as
# 	    # the actual data respects that minimum
# 	    (and-let* ((minimum    (datatype-minimum datatype))
# 		       (actual-min (apply min-maybe lst-closes))
# 		       (           (>= actual-min minimum)))
# 	      (set! lower (max lower minimum)))

sub filled_low {
  my ($self) = @_;
  return $self->{'fill_low'};
}
sub filled_high {
  my ($self) = @_;
  return $self->{'fill_high'};
}

sub find_before {
  my ($self, $before, $n) = @_;
  ### Series find_before(): "before=$before n=$n"
  if ($n <= 0) { return $before; } # asking for no points before

  my $values = $self->values_array;
  my $chunk = $n;

  my $i = $before - 1;
  for (;;) {
    $chunk *= 2;
    my $pre = $i - $chunk;
    $self->fill ($pre, $i);

    for ( ; $i >= $pre; $i--) {
      if ($i < 0) {
        ### not found, return 0
        return 0;
      }
      if (defined $values->[$i]) {
        $n--;
        if ($n <= 0) {
          ### find_before() found: $i
          return $i;
        }
      }
    }
  }
}

# return pos where there's a value somwhere $pos > $after, or $after if no more
sub find_after {
  my ($self, $after, $n) = @_;
  ### Series find_after(): "$after n=".($n//'undef')
  if ($n <= 0) { return $after; } # asking for no points after

  my $values = $self->values_array;
  my $hi = $self->hi;
  my $chunk = $n;

  my $i = $after + 1;
  $i = max ($i, 0);
  for (;;) {
    $chunk *= 2;
    my $post = $i + $chunk;
    $self->fill ($i, $post);
    for ( ; $i <= $post; $i++) {
      if ($i > $hi) { return $hi; }
      if (defined $values->[$i]) {
        $n--;
        if ($n <= 0) {
          ### find_after() found: $i
          return $i;
        }
      }
    }
  }
}

#------------------------------------------------------------------------------

sub AUTOLOAD {
  our $AUTOLOAD;
  ### Series AUTOLOAD $AUTOLOAD
  my $name = $AUTOLOAD;
  $name =~ s/(.*):://;
  if (my $subr = __PACKAGE__->can($name)) {
    { no strict; *$name = $subr; }
    goto &$subr;
  }
  croak "App::Chart::Series unknown function '$name'";
}

sub can {
  my ($self_or_class, $name) = @_;
  ### Series can(): "$self_or_class '$name'"

  return $self_or_class->SUPER::can($name) || do {
    if ($name =~ /^GT_/p) {
      require App::Chart::Series::GT;
      my $type = "I:${^POSTMATCH}";
      return sub { App::Chart::Series::GT->new ($type, @_) };
    }
    if ($name =~ /^TA_/p) {
      require App::Chart::Series::TA;
      my $type = ${^POSTMATCH};
      return sub { App::Chart::Series::TA->new ($type, @_) };
    }
    require Module::Util;
    my $class = "App::Chart::Series::Derived::\u$name";
    Module::Util::find_installed($class)
        || return undef;  # no such plugin

    #     if (DEBUG) { print "  func $name class $class\n";
    #                  if (eval { Module::Load::load ($class); 1 }) {
    #                    no strict 'refs';
    #                    print "    loads ok, new() is ", \&{"${class}::new"}, "\n";
    #                  } else {
    #                    print "    didn't load -- $@\n";
    #                  }
    #                }

    require Module::Load;
    Module::Load::load ($class);
    return sub { $class->new (@_) };
  };
}

# avoid going through AUTOLOAD for destroy
sub DESTROY {
}

use overload
  '0+'   => sub { croak 'Cannot use App::Chart::Series as a number' },
  'bool' => sub { 1 },
  '!'    => sub { 0 },
  '""'   => sub { $_[0] },
  '@{}'  => sub { $_[0]->fill(0,$_[0]->hi); $_[0]->values_array },
  '+'   => \&_overload_add,
  '-'   => \&sub,
  '*'   => \&_overload_mul,
  '/'   => \&div,
  'neg' => \&neg,
  '**'  => \&pow,
  'abs'  => \&abs,
  'cos'  => \&cos,
  'exp'  => \&exp,
  'int'  => \&int,
  'log'  => \&log,
  'sin'  => \&sin,
  'sqrt' => \&sqrt;

sub _func {
  my ($series, $subr) = @_;
  require App::Chart::Series::Func;
  return App::Chart::Series::Func->new ($series, $subr);
}

sub neg  { $_[0]->_func (sub { - $_[0] }) }
sub abs  { $_[0]->_func (sub { CORE::abs $_[0] }) }
sub cos  { $_[0]->_func (sub { CORE::cos $_[0] }) }
sub exp  { $_[0]->_func (sub { CORE::exp $_[0] }) }
sub int  { $_[0]->_func (sub { CORE::int $_[0] }) }
sub log  { $_[0]->_func (sub { CORE::log $_[0] }) }
sub sin  { $_[0]->_func (sub { CORE::sin $_[0] }) }
sub sqrt { $_[0]->_func (sub { CORE::sqrt $_[0] }) }

sub _overload_add {
  my ($x, $y) = @_;
  if (ref $y) {
    # series + series
    require App::Chart::Series::AddSub;
    return App::Chart::Series::AddSub->new ($x, $y);
  } else {
    # series + number
    return $x->_func (sub{ $_[0] + $y });
  }
}
sub sub {
  my ($x, $y, $swap) = @_;
  if (ref $y) {
    # series - series
    require App::Chart::Series::AddSub;
    return App::Chart::Series::AddSub->new (($swap ? ($y, $x) : ($x, $y)),
                                           negate => 1);
  } else {
    # series - number, or number - series
    return $x->_func ($swap
                      ? sub{ $y - $_[0] }
                      : sub{ $_[0] - $y });
  }
}
sub _overload_mul {
  my ($x, $y) = @_;
  return $x->mul($y);
}
sub div {
  my ($x, $y, $swap) = @_;
  if (ref $y) { croak 'Can only divide a App::Chart::Series by a constant'; }
  if ($swap) {
    croak "Not implemented";
  } else {
    return $x * (1/$y);
  }
}
sub pow {
  my ($series, $power, $swap) = @_;
  if (ref $power) {
    croak __('Can only raise App::Chart::Series to a scalar power');
  }
  return $series->_func ($swap
                         ? sub{ $power ** $_[0] }
                         : sub{ $_[0] ** $power });
}

1;
__END__

=for stopwords undef openint indices undefs delisted autoloads ie

=head1 NAME

App::Chart::Series -- series data object

=head1 SYNOPSIS

 use App::Chart::Series;

=head1 DESCRIPTION

A C<App::Chart::Series> object holds a data series.  It basically holds an
array or multiple arrays, of values indexed from 0 up to C<< $series->hi >>.
Portions of the arrays are filled on request with the C<fill> method, so
just some of a big series can be read from disk or calculated.

Array elements with no value for a given date are undef.  The arrays may be
shorter than C<< $series->hi >> when no data near the end.  And for instance
the "openint" array of futures open interest is always empty for ordinary
shares.

Array indices are values in a timebase, see L<App::Chart::Timebase>, so 0 is
some starting date, perhaps a particular day, or a whole month or week.  A
fixed sequence like this with undefs for public holidays or delisted times
makes it easy to fill portions without knowing how much there might be
altogether in the database, but skipping undefs all the time when
calculating is a bit tedious.

C<App::Chart::Series> itself is just a base class, with various methods
common to series objects.  Objects are only actually created by subclasses
such as C<App::Chart::Series::Database>.

Derived series can be made with autoloads for the derived modules, such as
C<< $series->SMA(10) >> to calculate a simple moving average.  But maybe the
way that works will change, since in a chained calculation the full data
arrays of intermediate parts don't need to be kept, it's just algorithms or
transformations that need to be combined.

=head1 FUNCTIONS

=over 4

=item C<< $series->timebase() >>

Return the C<App::Chart::Timebase> object which is the basis for C<$series>
(see L<App::Chart::Timebase>).

=item C<< $series->decimals() >>

Return the number of decimal places which should normally be shown for
values in C<$series>.  For example in a database price series this might be
2 to show dollars and cents, but for a series of trading volumes it would be
0.

This is only an intended accuracy to display (or minimum accuracy), not a
limit on the accuracy of the values in C<$series>.

=item C<< $series->symbol() >>

Return the stock or commodity symbol for the data in this series, or
C<undef> if it's not associated with a symbol at all.

=item C<< $series->hi() >>

Return the maximum index into the series arrays, ie. the arrays can be
filled with data from 0 up to C<< $series->hi >> inclusive.

=item C<< $series->fill ($lo, $hi) >>

Ask for data to be available for the arrays from C<$lo> to C<$hi> inclusive.
This might read the database, or make a data calculation, etc, if it hasn't
already been done for the range.

If C<$lo> or C<$hi> are outside the actual available range (ie. C<$lo>
negative and/or C<$hi> above C<< $series->hi >>), then just the actual
available parts are loaded and the excess ignored.

=item C<< $series->range ($lo, $hi) >>

Return two values C<($lower, $upper)> which is the range of values taken by
C<$series> between timebase values C<$lo> and C<$hi>, inclusive.  If there's
no data at all in that range the return is an empty list C<()>.

=item C<< $series->initial_range ($lo, $hi) >>

Return two values C<($lower, $upper)> which is a good price range
(vertically) to display for the data between points C<$lo> and C<$hi>.  If
there's no data in that range the return is an empty list C<()>.

=back

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2016, 2024 Kevin Ryde

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
