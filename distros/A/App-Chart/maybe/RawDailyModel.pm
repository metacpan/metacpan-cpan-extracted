# Raw daily data MVC model.

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


package App::Chart::RawDailyModel;

use strict;
use warnings;
use Glib;
use Gtk2;
use Carp;
use Gtk2::Ex::TreeModel::ImplBits;
use Locale::TextDomain ('App-Chart');

use App::Chart::Gtk2::Symlist;

use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ Gtk2::TreeModel:: ],
  properties => [ Glib::ParamSpec->string
                  ('symbol',
                   __('Symbol'),
                   'The symbol for the data to present.',
                   '', # default
                   Glib::G_PARAM_READWRITE) ];


use constant { COL_DATE     => 0,
               COL_OPEN     => 1,
               COL_HIGH     => 2,
               COL_LOW      => 3,
               COL_CLOSE    => 4,
               COL_VOLUME   => 5,
               COL_OPENINT  => 6,
               NUM_COLUMNS  => 7
             };
my @field_name = ('date', 'open', 'high', 'low', 'close', 'volume', 'openint');

my $select_sql = 'SELECT ' . join(',', @field_name)
  . 'FROM daily WHERE symbol=? ORDER BY date ASC';

sub _do_data_changed {
  my ($self, $symbol_hash) = @_;
}

sub INIT_INSTANCE {
  my ($self) = @_;
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('data-changed', \&_do_data_changed, $self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    delete $self->{'data'};
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
  return NUM_COLUMNS;
}

# gtk_tree_model_get_column_type
#
sub GET_COLUMN_TYPE {
  # my ($self, $index) = @_;
  return 'Glib::String';
}

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;

  if ($path->get_depth != 1) { die "RawDailyModel depth is only 1"; }
  my ($n) = $path->get_indices;
  return [ $self->{'stamp'}, $n, undef, undef ];
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  my $n = $iter->[1];
  return Gtk2::TreePath->new_from_indices ($n);
}

sub data {
  my ($self) = @_;
  if (exists $self->{'data'}) { return $self->{'data'}; }

  my $symbol = $self->{'symbol'};
  if (! $symbol) { return ($self->{'data'} = []); }

  ### raw read: $symbol
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached ($select_sql);
  my $data = $dbh->selectall_arrayref ($sth, undef, $symbol);
  return ($self->{'data'} = $data);
}

sub length {
  my ($self) = @_;
  return @{$self->data()};
}

# gtk_tree_model_get_value
#
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  my $n = $iter->[1];
  #### get_value: $n,$col
  return $self->data->[$n]->[$col];
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;

  my $n = $iter->[1];
  if ($n >= $self->length - 1) {
    # at last record
    return undef;
  }
  return [ $self->{'stamp'}, $n + 1, undef, undef ];
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  my ($self, $iter) = @_;

  if ($iter) {
    # no children of any nodes
    return undef;
  } else {
    # $iter==NULL means first toplevel
    return [ $self->{'stamp'}, 0, undef, undef ];
  }
}

# gtk_tree_model_iter_has_child
#
sub ITER_HAS_CHILD {
  # my ($self, $iter) = @_;
  return 0;
}

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;

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
  # my ($self, $iter) = @_;
  return undef;
}

sub set_value {
  my ($self, $iter, $col, $value) = @_;
  $iter = $iter->to_arrayref ($self->{'stamp'});
  my $n = $iter->[1];
  print "set_value $self $iter, $col, $value\n";
  my $symbol = $self->{'symbol'};
  my $data = $self->{'data'};
  my $date = $data->[$n]->[0];
  my $field = $field_name[$col];

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  print "write $symbol $date $field $value\n";
  my $sth = $dbh->prepare_cached
    ("UPDATE daily SET $field=? WHERE symbol=? AND date=?");
  $sth->execute ($value, $symbol, $date);

  delete $self->{'data'};
  $self->row_changed ($self->get_path($iter), $iter);
}

1;
__END__

=head1 NAME

App::Chart::RawDailyModel -- raw daily data model

=head1 SYNOPSIS

 use App::Chart::RawDailyModel;
 my $model = App::Chart::RawDailyModel->new (symlist => $symlist);

=head1 OBJECT HIERARCHY

C<App::Chart::RawDailyModel> is a subclass of C<Glib::Object>,

    Glib::Object
      App::Chart::RawDailyModel

The following GInterfaces are implemented

    Gtk2::TreeModel
    Gtk2::Buildable (inherited)

=head1 DESCRIPTION

A C<App::Chart::RawDailyModel> object presents database daily data in
C<Gtk2::TreeModel> form.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::RawDailyModel->new (key => value, ...) >>

Create and return a C<App::Chart::RawDailyModel> object.  Optional key/value
pairs can be given to set initial properties as per
C<< Glib::Object->new >>.

=item C<< $model->set_value ($iter, $col, $value) >>

Set the value in row C<$iter> and column C<$col> to C<$value>.  This updates
the database (and emits the C<row-changed> signal).

=back

=head1 CONSTANTS

The following constants give column numbers in the model,

    App::Chart::RawDailyModel::COL_DATE
    App::Chart::RawDailyModel::COL_OPEN
    App::Chart::RawDailyModel::COL_HIGH
    App::Chart::RawDailyModel::COL_LOW
    App::Chart::RawDailyModel::COL_CLOSE
    App::Chart::RawDailyModel::COL_VOLUME
    App::Chart::RawDailyModel::COL_OPENINT

=head1 PROPERTIES

=over 4

=item C<symbol> (string, default empty "")

The symbol to present data for.  Currently the intention is that this is
"construct-only", ie. to be set only when first constructing the model.

Perhaps in the future something tricky can be done to update the data with
updates for all rows and insert/deletes to try to keep date rows common to
the new and old symbol.  (But maintaining a date position is probably much
more easily done by the view.)

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::RawDialog>

=cut
