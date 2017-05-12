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


package App::Chart::Gtk2::IndicatorModel;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::MoreUtils;
use Locale::TextDomain ('App-Chart');

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::TreeStore';

use Class::Singleton 1.03; # 1.03 for _new_instance()
use base 'Class::Singleton';
*_new_instance = \&Glib::Object::new;

my %columns;
BEGIN {
  %columns = (COL_KEY      => 0,   # string
              COL_NAME     => 1,   # string
              COL_TYPE     => 2,   # string
              COL_PRIORITY => 3);  # string
}
use constant ({%columns});
use constant NUM_COLS => 4;

our $MODEL;
use constant::defer INIT_INSTANCE => sub {
  my ($self) = @_;

  $self->set_column_types (('Glib::String') x NUM_COLS);
  @{$self}{keys %columns} = values %columns;

  $self->set ($self->append(undef),
              COL_KEY,     'None',
              COL_NAME,    __('None'));

  my $aref = require App::Chart::Gtk2::IndicatorModelGenerated;

  # add anything not in IndicatorModelGenerated.pm
  {
    require Module::Find;
    require Gtk2::Ex::TreeModelBits;
    my %extra;
    # hash slice, everything on disk
    @extra{map {s/^App::Chart::Series::Derived:://;$_}
             Module::Find::findsubmod ('App::Chart::Series::Derived')} = ();
    # hash slice, drop keys already in the model
    delete @extra{map {$_->{'key'}} @$aref};

    # could load each extra to get name,type,priority ...
    foreach my $key (sort keys %extra) {
      push @$aref, { key      => $key,
                     name     => $key,
                     priority => 0 };
    }
  }

  # sort by translated name, case-insensitive
  @$aref = sort {$b->{'priority'} <=> $a->{'priority'}
                   || lc($a->{'name'}) cmp lc($b->{'name'})
                     || $a->{'name'} cmp $b->{'name'}
                   } @$aref;
  my ($top, $low)
    = List::MoreUtils::part {$_->{'priority'} >= 0 ? 0 : 1} @$aref;
  foreach my $elem (@$top) {
    $self->set($self->append(undef),
               COL_KEY,      $elem->{'key'},
               COL_NAME,     $elem->{'name'},
               COL_TYPE,     $elem->{'type'},
               COL_PRIORITY, $elem->{'priority'});
  }
  if (@$low) {
    my $low_iter = $self->append(undef);
    $self->set ($low_iter,
                COL_KEY,     'low-priority',
                COL_NAME,    __('Low Priority'));
    foreach my $elem (@$low) {
      $self->set($self->append($low_iter),
                 COL_KEY,      $elem->{'key'},
                 COL_NAME,     $elem->{'name'},
                 COL_TYPE,     $elem->{'type'},
                 COL_PRIORITY, $elem->{'priority'});
    }
  }
  if (DEBUG) {
    require Scalar::Util;
    Scalar::Util::weaken ($aref);
    if ($aref) {
      die "Oops, IndicatorModelGenerated array not destroyed";
    } else {
      print "IndicatorModelGenerated array destroyed\n";
    }
  }

  #--------------
  # TA

  if (eval { require Finance::TA }) {
    my $talib_iter = $self->append(undef);
    $self->set ($talib_iter, COL_NAME, __('TA-Lib'));
    my $talib_path = $self->get_path ($talib_iter);

    my %exclude = ('0',                   1,
                   'Math Operators',      1,
                   'Math Transform',      1,
                  );

    my @groups = Finance::TA::TA_GroupTable();
    @groups = grep {!$exclude{$_}} @groups;
    foreach my $group (@groups) {

      my @functions = Finance::TA::TA_FuncTable($group);
      shift @functions;

      $talib_iter = $self->get_iter($talib_path);
      my $group_iter = $self->append($talib_iter);
      $self->set ($group_iter, COL_NAME, $group);
      my $group_path = $self->get_path ($group_iter);

      foreach my $func (@functions) {
        if ($func eq 'MA') { next; } # selectable MA

        my $fh;
        Finance::TA::TA_GetFuncHandle($func, \$fh) == $Finance::TA::TA_SUCCESS
            or die;
        my $fi;
        Finance::TA::TA_GetFuncInfo($fh, \$fi) == $Finance::TA::TA_SUCCESS
            or die;

        # flag bits per ta_abstract.h
        # TA_FUNC_FLG_VOLUME     for volume overlay
        # TA_FUNC_FLG_UNST_PER   initial unstable
        my $flags = $fi->{'flags'};
        no warnings 'once';

        # if ($flags & $Finance::TA::TA_FUNC_FLG_CANDLESTICK) { next; }

        my $type = 'indicator';
        if ($group eq 'Price Transform') {
          $type = 'selector';
        } elsif ($flags & $Finance::TA::TA_FUNC_FLG_OVERLAP) {
          # output same as input
          $type = 'average';
        }

        my $hint = $fi->{'hint'};
        my $name = $hint;
        if ($hint !~ /\Q$func/) {
          $name = "$func - $name";
        }

        $group_iter = $self->get_iter($group_path);
        my $func_iter = $self->append($group_iter);
        $self->set ($func_iter,
                    COL_KEY,  "TA_$func",
                    COL_NAME, $name,
                    COL_TYPE, $type);
      }

      $group_iter = $self->get_iter($group_path);
      if ($self->iter_n_children ($group_iter) == 0) {
        $self->remove ($group_iter);
      }
    }
  }

  #--------------
  # GT

  require Module::Find;
  if (my @modules = Module::Find::findsubmod ('GT::Indicators')) {

    my %type = (ADL   => 'indicator',
                ADX   => 'indicator',
                ADXR  => 'indicator',
                AROON => 'indicator',
                AT3   => 'average',
                ATR   => 'indicator',
                BBO   => 'indicator',
                BOL   => 'average',
                BPCorrelation => [ 'indicator', __('GT Misc') ],
                CCI     => 'indicator',
                CHAIKIN => 'indicator',
                CMO     => 'indicator',

                # result is a binary code or something, so might be much to
                # view
                CNDL    => [ 'indicator', __('GT Misc') ],

                ChaikinsVola => 'indicator',
                Chandelier   => 'average',
                DMI      => 'indicator',
                DSS      => 'indicator',
                EMA      => 'average',
                ENV      => 'average',
                EPMA     => 'average',
                EVWMA    => 'average',
                ElderRay => 'indicator',
                FISH     => 'indicator',
                FRAMA    => 'average',
                ForceIndex    => 'indicator',
                FromTimeframe => 'special',  # time collapsing
                GAPO          => 'indicator',
                GMEAN         => [ 'indicator', __('GT Misc') ],
                HilbertPeriod => [ 'indicator', __('GT Misc') ],
                HilbertSine   => [ 'indicator', __('GT Misc') ],
                IFISH         => 'indicator',
                InstantTrendLine => 'average',
                Interquartil => 'indicator',
                KAMA    => 'average',
                Keltner => 'average',
                KirshenbaumBands => 'average',
                # LinearRegression.pm
                MACD => 'indicator',
                MAMA => 'average',
                MASS => 'indicator',
                MEAN => 'selector',
                MFI  => 'indicator',
                MOM  => 'indicator',
                MaxDrawDown      => 'indicator',
                MaxPossibleGain  => 'indicator',
                MaxPossibleLoss  => 'indicator',
                OBV    => 'indicator',

                # but param is a date, so probably can't use
                PERF   => [ 'indicator', __('GT Misc') ],

                PFE    => 'indicator',
                PFEraw => 'indicator',
                PGO    => 'indicator',
                PP     => 'average',
                PercentagePosition => 'indicator',

                # but params are strings, so probably can't use
                Prices   => 'selector',

                QSTICK   => 'indicator',
                RAVI     => 'indicator',
                REMA     => 'average',
                RMI      => 'indicator',
                ROC      => 'indicator',
                RSI      => 'indicator',
                RSquare  => 'indicator',
                Range    => [ 'indicator', __('GT Misc') ],
                SAR      => 'average',
                SMA      => 'average',
                SMI      => 'indicator',
                STO      => 'indicator',
                SWMA     => 'average',
                SafeZone => 'indicator',
                StandardDeviation => [ 'indicator', __('GT Misc') ],
                StandardError     => [ 'indicator', __('GT Misc') ],
                T3        => 'average',
                TDREI     => 'indicator',
                TETHER    => 'average',
                TMA       => 'average',
                TP        => 'selector',
                TR        => [ 'indicator', __('GT Misc') ],
                TRIX      => 'average',
                Test      => 'exclude',  # development stuff
                UI        => 'indicator',
                VHF       => 'indicator',
                VOSC      => [ 'indicator', __('GT Misc') ],
                VROC      => [ 'indicator', __('GT Misc') ],
                WMA       => 'average',
                WTCL      => 'selector',
                WWMA      => 'average',
                WilliamsR => 'indicator',
                ZigZag    => 'average',
               );


    my $gt_iter = $self->append(undef);
    $self->set ($gt_iter, COL_NAME, __('Genius Trader'));
    my $gt_path = $self->get_path ($gt_iter);
      my %other;

    foreach my $mod (sort @modules) {
      $mod =~ s/^GT::Indicators:://;

      my $type = $type{$mod};
      if (ref $type) {
        ($type, my $sub) = @$type;
        push @{$other{$sub}}, [ $mod, $type ];
        next;
      }
      if (defined $type && $type eq 'exclude') {
        next;
      }

      $gt_iter = $self->get_iter($gt_path);
      my $mod_iter = $self->append($gt_iter);

      $self->set ($mod_iter,
                  COL_KEY,  "GT_$mod",
                  COL_NAME, __x('GT {name}', name => $mod),
                  COL_TYPE, $type);
    }

    foreach my $sub (sort keys %other) {
      $gt_iter = $self->get_iter($gt_path);
      my $sub_iter = $self->append($gt_iter);
      $self->set ($sub_iter, COL_NAME, $sub);
      my $sub_path = $self->get_path($sub_iter);

      foreach my $elem (@{$other{$sub}}) {
        my ($mod, $type) = @$elem;

        $sub_iter = $self->get_iter($sub_path);
        my $mod_iter = $self->append($sub_iter);
        $self->set ($mod_iter,
                    COL_KEY,  "GT_$mod",
                    COL_NAME, __x('GT {name}', name => $mod),
                    COL_TYPE, $type);
      }
    }
  }

  return;
};


my %by_type;
sub by_type {
  my ($class, $want_type) = @_;
  if (! $want_type) { return $class->instance; }

  return ($by_type{$want_type} ||= do {
    my $model = Gtk2::TreeModelFilter->new ($class->instance);
    @{$model}{keys %columns} = values %columns;

    $model->set_visible_func
      (Gtk2::Ex::TreeModelFilterBits::visible_func_hide_empty_parents
       (sub {
          my ($model, $iter) = @_;
          my $type = $model->get($iter,COL_TYPE);
          return (! $type || $type eq $want_type);
        }));
    $model
  });
}

# =over 4
# 
# =item C<< $wrapped_visible_func = Gtk2::Ex::TreeModelFilterBits::visible_func_hide_empty_parents ($visible_func) >>
# 
# Return a function suitable for use as a TreeModelFilter
# C<set_visible_func> which applies C<$visible_func> and in addition makes
# parent rows visible only if there's at least one visible child row under
# it.
#
# C<$visible_func> is called just like a normal C<set_visible_func>, ie.
# 
#     bool = &$visible_func ($model, $iter, $userdata);
# 
# The C<$wrapped_visible_func> returned is designed to be called the same
# way.
#
# If you omit C<$userdata> from the C<set_visible_func> install then just
# two arguments are passed.  C<$wrapped_visible_func> likewise passes just
# two arguments to C<$visible_func> in that case (though it'd be unusual for
# that to make much difference).
# 
# =back
# 
# =cut

sub Gtk2::Ex::TreeModelFilterBits::visible_func_hide_empty_parents {
  my ($visible_func) = @_;

  # cf Sub::Recursive for avoiding circularities
  #
  my $weak_wrapped_func;
  my $wrapped_func = sub {
    if (! $visible_func->(@_)) { return 0; }
    my ($model, $iter) = @_;
    if (my $subiter = $model->iter_children ($iter)) {
      shift; shift;
      do {
        if ($weak_wrapped_func->($model, $subiter, @_)) {
          return 1;
        }
      } while ($subiter = $model->iter_next($subiter));
      return 0;
    } else {
      goto $visible_func;
    }
  };
  require Scalar::Util;
  $weak_wrapped_func = $wrapped_func;
  Scalar::Util::weaken ($weak_wrapped_func);
  return $wrapped_func;
}

1;
__END__
