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

package App::Chart::Gtk2::SeriesModel;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Carp;
use Gtk2::Ex::TreeModel::ImplBits;


use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ 'Gtk2::TreeModel' ],
  properties => [ Glib::ParamSpec->scalar
                  ('series',
                   'series',
                   'The perl App::Chart::Series object to present.',
                   Glib::G_PARAM_READWRITE)
                ];

use constant { COL_DATE     => 0,
               COL_OPEN     => 1,
               COL_HIGH     => 2,
               COL_LOW      => 3,
               COL_CLOSE    => 4,
               COL_VOLUME   => 5,
               COL_OPENINT  => 6,
               NUM_COLUMNS  => 7 };

sub _validate_iter {
  my ($self, $iter) = @_;
  if (! defined $iter) { return; }
  if ($iter->[0] != $self->{'stamp'}) {
    croak "iter is not for this ".ref($self)." (id ",
      $iter->[0]," want ",$self->{'stamp'},")\n";
  }
}

sub INIT_INSTANCE {
  my ($self) = @_;
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'series') {
  }
}

# gtk_tree_model_get_flags
#
sub GET_FLAGS {
  return [ 'list-only' ];
}

# gtk_tree_model_get_n_columns
#
sub GET_N_COLUMNS {
  my ($self) = @_;
  my $series = $self->{'series'};
  if ($series && $series->isa ('Series::OHLCVI')) {
    return 7;
  } else {
    return 2;
  }
}

# gtk_tree_model_get_column_type
#
use constant GET_COLUMN_TYPE => 'Glib::String';

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;
  $path->get_depth == 1 or return undef;
  my ($n) = $path->get_indices;
  return [ $self->{'stamp'}, $n, undef, undef ];
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  _validate_iter ($self, $iter);
  my $n = $iter->[1];
  return Gtk2::TreePath->new_from_indices ($n);
}

sub data {
  my ($self) = @_;
  if (exists $self->{'data'}) { return $self->{'data'}; }
  my $symbol = $self->{'symbol'};
  if (! defined $symbol) { return ($self->{'data'} = []); }

  ### raw read: $symbol
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached
    ('SELECT date, open, high, low, close, volume, openint
      FROM daily WHERE symbol=? ORDER BY date ASC');
  my $data = $dbh->selectall_arrayref ($sth, undef, $symbol);
  return ($self->{'data'} = $data);
}

sub length {
  my ($self) = @_;
  my $series = $self->{'series'};
  if (! $series) { return 0; }
  return $series->hi + 1;
}

# gtk_tree_model_get_value
#
my %col_to_array = (COL_OPEN,    'opens',
                    COL_HIGH,    'highs',
                    COL_LOW,     'lows',
                    COL_CLOSE,   'closes',
                    COL_VOLUME,  'volumes',
                    COL_OPENINT, 'openints');
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  _validate_iter ($self, $iter);
  my $n = $iter->[1];
  ### GET_VALUE: "$n,$col"
  if ($n < 0) { return ''; }

  my $series = $self->{'series'};
  if (! $series) { return ''; }

  if ($col == 0) {
    return $series->timebase->to_iso ($n);
  }
  $series->fill ($n, $n);
  if (! $series->isa ('App::Chart::Series::OHLCVI')) {
    return $series->values_array->[$n];
  }
  my $array = $col_to_array{$col} // return '';
  return $series->array($array)->[$n];
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;
  _validate_iter ($self, $iter);

  my $n = $iter->[1] + 1;
  if ($n >= $self->length) {
    # past last record
    return undef;
  }
  return [ $self->{'stamp'}, $n, undef, undef ];
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  my ($self, $iter) = @_;
  _validate_iter ($self, $iter);

  if ($iter) {
    # no children of any nodes
    return undef;
  } else {
    # $iter==NULL means first toplevel
    return [ $self->{'stamp'}, 0, undef, undef ];
  }
}

# gtk_tree_model_iter_has_child
# Note Gtk2 prior to 1.183 demands numeric return (zero or non-zero).
#
use constant ITER_HAS_CHILD => 0;

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;
  _validate_iter ($self, $iter);

  if ($iter) {
    # nothing under actual rows
    return 0;
  } else {
    # $iter==NULL asks about toplevel
    return $self->length;
  }
}

# gtk_tree_model_iter_nth_child
#
sub ITER_NTH_CHILD {
  my ($self, $iter, $n) = @_;
  _validate_iter ($self, $iter);

  if ($iter) {
    # nothing unde actual rows
    return undef;
  } else {
    # $iter==NULL means nth toplevel
    if ($n < 0 || $n >= $self->length) {
      # out of range
      return undef;
    }
    return [ $self->{'stamp'}, $n, undef, undef ];
  }
}

# gtk_tree_model_iter_parent
#
sub ITER_PARENT {
  my ($self, $iter) = @_;
  _validate_iter ($self, $iter);
  return undef;
}

my @field_name = qw(date open high low close volume openint);

sub set_value {
  (@_ == 4) or croak 'SeriesModel::set_value(): wrong number of arguments';
  my ($self, $iterobj, $col, $value) = @_;
  my $iter = $iterobj->to_arrayref ($self->{'stamp'});
  ### set_value: "$self $iter, $col, $value"
  _validate_iter ($self, $iter);
  my $n = $iter->[1];

  my $series = $self->{'series'};
  if (! $series->isa ('App::Chart::Series::Database')) {
    croak "Can only change Database series";
  }
  my $symbol = $series->symbol || croak "No symbol in series";

  my $date = $series->timebase->to_iso ($n);
  my $field = $field_name[$col];

  require App::Chart::Database;
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  ### write: "$symbol $date $field $value"

  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         if (! App::Chart::DBI->read_single
             ('SELECT symbol FROM daily WHERE symbol=? AND date=?',
              $symbol, $date)) {
           $dbh->do ('INSERT INTO daily (symbol, date) VALUES (?,?)',
                     undef, # attrs
                     $symbol, $date);
         }
         my $sth = $dbh->prepare_cached
           ("UPDATE daily SET $field=? WHERE symbol=? AND date=?");
         $sth->execute ($value, $symbol, $date);
         $sth->finish;
       });
  $series->{'fill_set'}->remove ($n);

  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
  $self->row_changed ($self->get_path($iterobj), $iterobj);
}

1;
__END__

=for stopwords TreeModel OHLCVI

=head1 NAME

App::Chart::Gtk2::SeriesModel -- TreeModel for App::Chart::Series

=for test_synopsis my ($series)

=head1 SYNOPSIS

 use App::Chart::Gtk2::SeriesModel;
 my $model = App::Chart::Gtk2::SeriesModel->new (series => $series);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::SeriesModel> is a subclass of C<Glib::Object>,

    Glib::Object
      App::Chart::Gtk2::SeriesModel

The following interfaces are implemented

    Gtk2::TreeModel
    Gtk2::Buildable (inherited)

=head1 DESCRIPTION

A C<App::Chart::Gtk2::SeriesModel> object presents the data from a
C<App::Chart::Series::OHLCVI> in C<Gtk2::TreeModel> form suitable for
C<App::Chart::Gtk2::RawDialog> (which is currently this is its sole use).

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::SeriesModel->new (key => value, ...) >>

Create and return a C<App::Chart::Gtk2::SeriesModel> object.  Optional key/value
pairs can be given to set initial properties as per
C<< Glib::Object->new >>.

=back

=head1 CONSTANTS

The following constants give the column numbers in the model,

    App::Chart::Gtk2::SeriesModel::COL_DATE
    App::Chart::Gtk2::SeriesModel::COL_OPEN
    App::Chart::Gtk2::SeriesModel::COL_HIGH
    App::Chart::Gtk2::SeriesModel::COL_LOW
    App::Chart::Gtk2::SeriesModel::COL_CLOSE
    App::Chart::Gtk2::SeriesModel::COL_VOLUME
    App::Chart::Gtk2::SeriesModel::COL_OPENINT

=head1 PROPERTIES

=over 4

=item C<series> (App::Chart::Series::OHLCVI)

The series to present data from.  Currently this has to be an OHLCVI.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::RawDialog>

=cut
