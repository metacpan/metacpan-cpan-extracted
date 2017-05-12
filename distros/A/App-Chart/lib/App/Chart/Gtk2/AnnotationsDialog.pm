# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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

package App::Chart::Gtk2::AnnotationsDialog;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Glib::Ex::ConnectProperties 15;  # v.15 for tree-selection#not-empty
use Gtk2::Ex::DateSpinner;
use Gtk2::Ex::DateSpinner::CellRenderer;
use Gtk2::Ex::Units;
use App::Chart;
use App::Chart::Annotation;
use App::Chart::DBI;

# uncomment this to run the ### lines
# use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Dialog',
  properties => [ Glib::ParamSpec->string
                  ('symbol',
                   __('Symbol'),
                   'Blurb.',
                   '', # default
                   Glib::G_PARAM_READWRITE),
                ];

use constant { RESPONSE_DELETE => 0,
               RESPONSE_TODAY  => 1 };

use constant { COL_ID => 0,
               COL_DATE => 1,
               COL_NOTE => 2 };

sub INIT_INSTANCE {
  my ($self) = @_;
  ### AnnotationsDialog() INIT_INSTANCE ...

  $self->set_title (__('Chart: Annotations'));
  $self->add_buttons (__('_Today') => RESPONSE_TODAY,
                      'gtk-delete' => RESPONSE_DELETE,
                      'gtk-close' => 'close',
                      'gtk-help'  => 'help');
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;
  my $em = Gtk2::Ex::Units::em($self);

  my $heading = $self->{'heading'} = Gtk2::Label->new (' ');
  $vbox->pack_start ($heading, 0,0,0);

  my $scrolled = Gtk2::ScrolledWindow->new;
  $scrolled->set (hscrollbar_policy => 'automatic',
                  vscrollbar_policy => 'automatic');
  $vbox->pack_start ($scrolled, 1,1,0);

  my $store = $self->{'store'}
    = Gtk2::ListStore->new ('Glib::String', 'Glib::String', 'Glib::String');

  my $treeview = $self->{'treeview'}
    = Gtk2::TreeView->new_with_model ($store);
  $treeview->set (headers_visible => 1,
                  reorderable => 0);
  $scrolled->add ($treeview);

  my $selection = $treeview->get_selection;
  $selection->signal_connect (changed => \&_do_selection_changed, $self);
  $selection->set_mode ('single');

  Glib::Ex::ConnectProperties->new
      ([$selection, 'tree-selection#not-empty'],
       [$self,      'response-sensitive#'.RESPONSE_DELETE ]);

  {
    my $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new (xalign => 0,
                                                             ypad => 0,
                                                             editable => 1);
    $renderer->signal_connect (edited => \&_do_date_cell_edited, $self);
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Date'), $renderer, text => COL_DATE);
    $column->set (sizing => 'fixed',
                  fixed_width => 8*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $renderer = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 0,
                    ypad => 0,
                    editable => 1);
    $renderer->signal_connect (edited => \&_do_note_cell_edited, $self);
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Note'), $renderer, text => COL_NOTE);
    $treeview->append_column ($column);
  }

  my $hbox = Gtk2::HBox->new (0, 0);
  $vbox->pack_start ($hbox, 0,0,0);

  ### $hbox
  my $datespinner = $self->{'datespinner'} = Gtk2::Ex::DateSpinner->new;
  ### $datespinner
  $datespinner->set_today;
  $hbox->pack_start ($datespinner, 0,0,0);

  my $entry = $self->{'entry'} = Gtk2::Entry->new;
  $hbox->pack_start ($entry, 1,1, 0.5 * Gtk2::Ex::Units::em($entry));
  $entry->grab_focus;
  $entry->signal_connect (activate => \&_do_entry_enter, $self);

  my $button = Gtk2::Button->new_with_label (__('Enter'));
  $hbox->pack_start ($button, 0,0,0);
  $button->signal_connect (clicked => \&_do_entry_enter, $self);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('data-changed', \&_do_data_changed, $self);

  $vbox->show_all;

  # with sensible annotations list and entry sizes
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       [$scrolled, -1, '15 lines'],
       [$entry,    '40 ems', -1]);
  ### AnnotationsDialog() INIT_INSTANCE finished ...
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### AnnotationsDialog() SET_PROPERTY ...

  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    my $symbol = $newval;
    $self->set_title (__x('Chart: Annotations: {symbol}',
                          symbol => $symbol));
    $self->{'heading'}->set_text ($symbol);
    _fill ($self);
  }
}

sub _do_data_changed {
  my ($self, $symbol_hash) = @_;
  my $symbol = $self->{'symbol'} // return;
  if (exists $symbol_hash->{$symbol}) {
    _fill ($self);
  }
}

sub _fill {
  my ($self) = @_;
  ### AnnotationsDialog _fill()
  my $store = $self->{'store'};
  $store->clear;

  my $symbol = $self->{'symbol'};
  if (defined $symbol) {
    require App::Chart::Series::Database;
    my $series = App::Chart::Series::Database->new ($symbol);
    my $aref = $series->annotations;
    ### $aref

    foreach my $ann (@$aref) {
      $store->set ($store->prepend,
                   COL_ID,   $ann->{'id'},
                   COL_DATE, $ann->{'date'},
                   COL_NOTE, $ann->{'note'});
    }
  }
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  ###  AnnotationsDialog _do_response()
  ### $response

  if ($response eq RESPONSE_TODAY) {
    $self->{'datespinner'}->set_today;

  } elsif ($response eq RESPONSE_DELETE) {
    _do_delete ($self);

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Annotations'), $self);
  }
}

# 'changed' on the treeview selection
sub _do_selection_changed {
  my ($selection, $self) = @_;

  my ($model, $iter) = $selection->get_selected;
  if ($iter) {
    my $date = $model->get_value ($iter, COL_DATE);
    my $str = $model->get_value ($iter, COL_NOTE);
    $self->{'datespinner'}->set (value => $date);
    $self->{'entry'}->set_text ($str);
  }
}

# 'Delete' button in the dialog
sub _do_delete {
  my ($self) = @_;
  ### AnnotationsDialog _do_delete()

  my $symbol = $self->{'symbol'} || return;
  my $selection = $self->{'treeview'}->get_selection;
  my ($model, $iter) = $selection->get_selected;
  if (! $iter) { return; }
  my $id = $model->get_value ($iter, COL_ID);
  ### $symbol
  ### $id

  my $dbh = App::Chart::DBI->instance;
  $dbh->do ('DELETE FROM annotation WHERE symbol=? AND id=?',
            undef,
            $symbol, $id);
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

# 'activate' on the Gtk2::Entry and 'clicked' on the Gtk2::Button "Add"
sub _do_entry_enter {
  my ($entry_or_button, $self) = @_;

  my $symbol = $self->{'symbol'} || return;
  my $date = $self->{'datespinner'}->get_value;
  my $str = $self->{'entry'}->get_text;

  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         my $id = App::Chart::Annotation::next_id ('annotation', $symbol);

         $dbh->do('INSERT INTO annotation (symbol, id, date, note)
            VALUES (?,?,?,?)',
                  undef,
                  $symbol, $id, $date, $str);
       });
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

# 'edited' signal on the Date column Gtk2::Ex::DateSpinner::CellRenderer
sub _do_date_cell_edited {
  my ($renderer, $pathstr, $newstr, $self) = @_;
  my $path = Gtk2::TreePath->new_from_string ($pathstr);
  my $model = $self->{'store'};
  my $iter = $model->get_iter ($path);

  my $symbol = $self->{'symbol'} || return;
  my $id = $model->get_value ($iter, COL_ID);

  my $dbh = App::Chart::DBI->instance;
  $dbh->do('UPDATE annotation SET date=? WHERE symbol=? AND id=?',
           undef,
           $newstr, $symbol, $id);
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

# 'edited' signal on the Notes column Gtk2::CellRendererText
sub _do_note_cell_edited {
  my ($renderer, $pathstr, $newstr, $self) = @_;
  my $path = Gtk2::TreePath->new_from_string ($pathstr);
  my $model = $self->{'store'};
  my $iter = $model->get_iter ($path);

  my $symbol = $self->{'symbol'} || return;
  my $id = $model->get_value ($iter, COL_ID);

  my $dbh = App::Chart::DBI->instance;
  $dbh->do('UPDATE annotation SET note=? WHERE symbol=? AND id=?',
           undef,
           $newstr, $symbol, $id);
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

sub popup {
  my ($class, $symbol, $parent) = @_;
  if (! defined $symbol) { $symbol = ''; }
  require App::Chart::Gtk2::Ex::ToplevelBits;
  my $dialog = App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     hide_on_delete => 1,
     screen => $parent);
  $dialog->set (symbol => $symbol);
  return $dialog;
}


1;
__END__

=for stopwords Popup

=head1 NAME

App::Chart::Gtk2::AnnotationsDialog -- annotations editing dialog

=head1 SYNOPSIS

 use App::Chart::Gtk2::AnnotationsDialog;
 App::Chart::Gtk2::AnnotationsDialog->popup;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::AnnotationsDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::AnnotationsDialog

=head1 DESCRIPTION

...

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::AnnotationsDialog->popup () >>

=item C<< App::Chart::Gtk2::AnnotationsDialog->popup ($symbol) >>

Popup a C<AnnotationsDialog> dialog for C<$symbol>, either re-presenting any
existing one or otherwise creating a new one.

=back

=cut
