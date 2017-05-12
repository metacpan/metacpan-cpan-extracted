# Copyright 2010, 2011 Kevin Ryde

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

package App::Chart::BrowseHistoryDialog;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::Units;
use App::Chart;
use App::Chart::Annotation;
use App::Chart::DBI;
use App::Chart::SymbolHistory;


use Glib::Object::Subclass
  'Gtk2::Dialog',
  properties => [ Glib::ParamSpec->object
                  ('symbol-history',
                   'Symbol history',
                   'Gtk2::TreeModel to display.',
                   'App::Chart::SymbolHistory',
                   Glib::G_PARAM_READWRITE),
                ];

use constant { RESPONSE_DELETE => 0,
               RESPONSE_TODAY  => 1 };

use constant { COL_ID => 0,
               COL_DATE => 1,
               COL_NOTE => 2 };

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: BrowseHistory'));
  $self->add_buttons ('gtk-close' => 'close',
                      'gtk-help'  => 'help');
  $self->set_response_sensitive (RESPONSE_DELETE, 0);
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;
  my $em = Gtk2::Ex::Units::em($self);

  my $heading = $self->{'heading'} = Gtk2::Label->new (__('(No current)'));
  $vbox->pack_start ($heading, 0,0,0);

  my $table = Gtk2::Table->new (1, 2);
  $vbox->pack_start ($table, 0,0,0);

  my $tpos = 0;
  foreach my $i (0, 1) {
    my $type = ('back', 'forward')[$i];
    my $scrolled = $self->{"scrolled_$type"} = Gtk2::ScrolledWindow->new;
    $scrolled->set (hscrollbar_policy => 'automatic',
                    vscrollbar_policy => 'automatic');
    $table->attach ($scrolled, $tpos, $tpos+1, 0,1,
                    ['fill','shrink','expand'],
                    ['fill','shrink','expand'],
                    POSIX::ceil(Gtk2::Ex::Units::width($table,'.2 em')), 0);
    $tpos++;

    my $treeview = $self->{"treeview_$type"} = Gtk2::TreeView->new;
    $treeview->set (headers_visible => 1,
                    reorderable => 0);
    $treeview->signal_connect (row_activated => \&_do_row_activated);
    $scrolled->add ($treeview);

    my $renderer = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 0, ypad => 0);
    my $name = (__('Back'),__('Forward'))[$i];
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      ($name, $renderer, text => 0);
    # $column->set (resizable => 0);
    $treeview->append_column ($column);
  }

  $vbox->show_all;

  # with sensible annotations list and entry sizes
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       [$self->{'scrolled_back'},    '20 em', '15 lines'],
       [$self->{'scrolled_forward'}, '20 em', '15 lines']);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol_history') {
    $self->{'treeview_back'}->set_model ($newval->{'back_model'});
    $self->{'treeview_forward'}->set_model ($newval->{'forward_model'});
  }
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;

  if ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');
  }

#   } elsif ($response eq 'help') {
#     require App::Chart::Manual;
#     App::Chart::Manual->open(__p('manual-node','BrowseHistory'), $self);
}

# 'row-activated' signal on a TreeView
sub _do_row_activated {
  my ($treeview, $path, $treeviewcolumn) = @_;
}

sub popup {
  my ($class) = @_;
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class, hide_on_delete => 1);
}


1;
__END__

=for stopwords Popup

=head1 NAME

App::Chart::BrowseHistoryDialog -- browsing history dialog

=head1 SYNOPSIS

 use App::Chart::BrowseHistoryDialog;
 App::Chart::BrowseHistoryDialog->popup;

=head1 WIDGET HIERARCHY

C<App::Chart::BrowseHistoryDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::BrowseHistoryDialog

=head1 DESCRIPTION

...

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::BrowseHistoryDialog->popup () >>

Popup a C<BrowseHistoryDialog> dialog, re-presenting an existing one or
otherwise creating a new one.

=back

=cut
