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

package App::Chart::Gtk2::SeriesTreeView;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');
use List::Util;

use Gtk2::Ex::Units;
use App::Chart::Database;
use App::Chart::Intraday;
use App::Chart::Gtk2::SeriesModel;
use App::Chart::Gtk2::Ex::CellRendererTextBits;

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::TreeView',
  properties => [Glib::ParamSpec->scalar
                 ('series',
                  'series',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE)
                ];


sub INIT_INSTANCE {
  my ($self) = @_;
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('data-changed', \&_do_data_changed, $self);

  $self->set (fixed_height_mode => 1);

  my $em = Gtk2::Ex::Units::em($self);
  {
    my $renderer = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 0,
                    ypad => 0);
    $renderer->set_fixed_height_from_font (1);

    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Date'), $renderer, text => App::Chart::Gtk2::SeriesModel::COL_DATE);
    $column->set (sizing => 'fixed',
                  fixed_width => 10*$em,  # eg. "2007-12-31"
                  resizable => 1);
    $self->append_column ($column);
  }

  foreach my $elem ([ App::Chart::Gtk2::SeriesModel::COL_OPEN,  __('Open'), 7 ],
                    [ App::Chart::Gtk2::SeriesModel::COL_HIGH,  __('High'), 7 ],
                    [ App::Chart::Gtk2::SeriesModel::COL_LOW,   __('Low'),  7 ],
                    [ App::Chart::Gtk2::SeriesModel::COL_CLOSE, __('Close'), 7 ],
                    [ App::Chart::Gtk2::SeriesModel::COL_VOLUME,  __('Volume'), 10 ],
                    [ App::Chart::Gtk2::SeriesModel::COL_OPENINT, __('Openint'), 9 ],
                   ) {
    my ($colnum, $heading, $width) = @$elem;
    my $renderer = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 1,
                    ypad => 0,
                    editable => 1);
    $renderer->set_fixed_height_from_font (1);

    my $column = Gtk2::TreeViewColumn->new_with_attributes
      ($heading, $renderer, text => $colnum);
    $column->set (sizing      => 'fixed',
                  fixed_width => $width * $em,
                  resizable   => 1);
    App::Chart::Gtk2::Ex::CellRendererTextBits::renderer_edited_set_value ($renderer, $column, $colnum);
    $self->append_column ($column);
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if (DEBUG) { print "SeriesTreeView: set $pname ",$newval//'undef',"\n"; }
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'series') {
    $self->refresh;
  }
}

sub refresh {
  my ($self) = @_;
  my $series = $self->{'series'};
  if (DEBUG) { print "SeriesTreeView refresh ",$series//'undef',"\n"; }

  require Gtk2::Ex::WidgetCursor;
  Gtk2::Ex::WidgetCursor->busy;
  my $model = $self->{'model'}
    = App::Chart::Gtk2::SeriesModel->new (series => $series);
  $self->set_model ($model);
}

sub _do_entry_activate {
  my ($entry, $self) = @_;
  $self->set_symbol ($entry->get_text);
}

sub _do_data_changed {
  my ($self, $symbol_hash) = @_;
  my $symbol = $self->{'symbol'} // return;
  if (exists $symbol_hash->{$symbol}) {
    $self->refresh;
  }
}

1;
__END__

=for stopwords SeriesTreeView

=head1 NAME

App::Chart::Gtk2::SeriesTreeView -- raw data display dialog

=head1 SYNOPSIS

 use App::Chart::Gtk2::SeriesTreeView;
 App::Chart::Gtk2::SeriesTreeView->popup();

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::SeriesTreeView> is a subclass of C<Gtk2::TreeView>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::TreeView
          App::Chart::Gtk2::SeriesTreeView

=head1 DESCRIPTION

A C<App::Chart::Gtk2::SeriesTreeView> widget displays raw daily date, open, high, low,
etc from the database.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::SeriesTreeView->new (key=>value,...) >>

Create and return a new SeriesTreeView widget.

=back

=cut
