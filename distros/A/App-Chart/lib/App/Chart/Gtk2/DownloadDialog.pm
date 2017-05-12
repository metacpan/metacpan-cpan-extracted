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

package App::Chart::Gtk2::DownloadDialog;
use 5.010;
use strict;
use warnings;
use Glib::Ex::SignalIds;
use Gtk2 1.220;
use Gtk2::Ex::Units;
use Locale::TextDomain ('App-Chart');
use Regexp::Common 'whitespace';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Job;
use App::Chart::Gtk2::JobQueue;
use App::Chart::Gtk2::Subprocess;

# uncomment this to run the ### lines
#use Smart::Comments;


use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';
use Glib::Object::Subclass
  'Gtk2::Dialog',
  signals => { destroy => \&_do_destroy };

use constant { RESPONSE_START  => 0,
               RESPONSE_STOP   => 1,
               RESPONSE_CLEAR  => 2 };

use constant { WHEN_UPDATE  => 0,
               WHEN_BACKTO  => 1 };

sub popup {
  my ($class, $symbol, $parent) = @_;
  require App::Chart::Gtk2::Ex::ToplevelBits;
  my $dialog = App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     hide_on_delete => 1,
     screen => $parent);
  if (defined $symbol) {
    $dialog->{'entry'}->set_text($symbol);
  }
  return $dialog;
}
sub popup_update {
  my ($class, $symbol, $parent) = @_;
  my $dialog = $class->popup ($symbol, $parent);
  $dialog->start ($symbol, undef);
  $dialog->{'hide_on_success'} = 1;
  return $dialog;
}

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: Download'));
  $self->add_buttons (__('_Start') => RESPONSE_START,
                      __('_Stop')  => RESPONSE_STOP,
                      'gtk-clear' => RESPONSE_CLEAR,
                      'gtk-close' => 'close',
                      'gtk-help'  => 'help');
  $self->signal_connect (response => \&_do_response);
  my $vbox = $self->vbox;

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0,
                  ypad => 0);

  { my $label = Gtk2::Label->new (__('Subprocesses'));
    $label->set (xalign => 0);
    $vbox->pack_start ($label, 0,0,0);
  }

  my $proc_scrolled = Gtk2::ScrolledWindow->new;
  $proc_scrolled->set (hscrollbar_policy => 'automatic',
                       vscrollbar_policy => 'automatic');
  $vbox->pack_start ($proc_scrolled, 1,1,0);

  {
    require App::Chart::Gtk2::Subprocess;
    my $treeview = $self->{'proc_treeview'}
      = Gtk2::TreeView->new_with_model ($App::Chart::Gtk2::Subprocess::store);
    $treeview->set (headers_visible => 0,
                    reorderable => 1);
    $proc_scrolled->add ($treeview);
    $treeview->add_events ('button-press-mask');
    $treeview->signal_connect
      (button_press_event => \&_do_proc_treeview_button_press, $self);

    {
      my $column = Gtk2::TreeViewColumn->new;
      $column->pack_start ($renderer, 1);
      $column->set_cell_data_func ($renderer, \&_proc_cell_status);
      $treeview->append_column ($column);
    }
  }

  { my $label = Gtk2::Label->new (__('Jobs'));
    $label->set (xalign => 0);
    $vbox->pack_start ($label, 0,0,0);
  }

  my $model = $self->{'model'} = App::Chart::Gtk2::JobQueue->instance;
  $self->{'model_ids'} = Glib::Ex::SignalIds->new
    ($model,
     $model->signal_connect (row_changed => \&_do_job_row_changed, $self));

  my $jobs_scrolled = Gtk2::ScrolledWindow->new;
  $jobs_scrolled->set (hscrollbar_policy => 'automatic',
                       vscrollbar_policy => 'automatic');
  $vbox->pack_start ($jobs_scrolled, 1,1,0);

  my $treeview = $self->{'jobs_treeview'}
    = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (headers_visible => 0,
                  reorderable => 1);
  $jobs_scrolled->add ($treeview);
  $treeview->add_events ('button-press-mask');
  $treeview->signal_connect
    (button_press_event => \&_do_jobs_treeview_button_press);

  my $selection = $treeview->get_selection();
  $selection->signal_connect (changed => \&_do_selection_changed, $self);
  $selection->set_mode ('single');

  {
    my $column = Gtk2::TreeViewColumn->new;
    $column->pack_start ($renderer, 1);
    $column->set_cell_data_func ($renderer, \&_job_cell_status);
    $treeview->append_column ($column);
  }

  { my $label = Gtk2::Label->new(__('Messages'));
    $label->set (xalign => 0);
    $vbox->pack_start ($label, 0,0,0);
  }
  my $textbuf = $self->{'textbuf'} = Gtk2::TextBuffer->new();
  $textbuf->signal_connect ('changed', \&_do_textbuf_changed, $self);

  require Gtk2::Ex::TextView::FollowAppend;
  my $textview = $self->{'textview'}
    = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf);
  $textview->set (wrap_mode => 'char',
                  editable => 0);

  my $messages_scrolled = Gtk2::ScrolledWindow->new();
  $messages_scrolled->add($textview);
  $messages_scrolled->set_policy('never', 'always');
  $vbox->pack_start ($messages_scrolled, 1, 1, 0);

  # During perl "global destruction" can have App::Chart::Gtk2::Job already
  # destroyed enough that it has disconnected the message emission hook
  # itself, leading to an unsightly Glib warning if attempting
  # signal_remove_emission_hook() in our 'destroy' class closure.  So
  # instead leave it connected, with a weakened ref, and let it return 0 to
  # disconnect itself on the next emission (if any).
  #
  #  App::Chart::Gtk2::Job->signal_add_emission_hook
  #      (message => \&_do_job_message, App::Chart::Glib::Ex::MoreUtils::ref_weak ($self));
  #
  require App::Chart::Glib::Ex::EmissionHook;
  $self->{'hook'} = App::Chart::Glib::Ex::EmissionHook->new
    ('App::Chart::Gtk2::Job',
     message => \&_do_job_message,
     App::Chart::Glib::Ex::MoreUtils::ref_weak($self));

  my $hbox = Gtk2::HBox->new (0, 0);
  $hbox->pack_start (Gtk2::Label->new (__('What:')), 0,0,0);
  $vbox->pack_start ($hbox, 0,0,0);

  my $what_model = $self->{'what_model'}
    = Gtk2::ListStore->new ('Glib::String', 'Glib::Scalar');
  $what_model->set ($what_model->append, 0, __('One symbol'), 1, undef);
  $what_model->set ($what_model->append, 0, __('Favourites'), 1, 'favourites');
  $what_model->set ($what_model->append, 0, __('All'), 1, 'all');

  my $what_combobox = $self->{'what_combobox'}
    = Gtk2::ComboBox->new_with_model ($what_model);
  my $what_renderer = Gtk2::CellRendererText->new;
  $what_combobox->pack_start ($what_renderer, 1);
  $what_combobox->set_attributes ($what_renderer, text => 0);
  $hbox->pack_start ($what_combobox, 0,0,0);

  my $entry = $self->{'entry'} = Gtk2::Entry->new;
  $hbox->pack_start ($entry, 1,1, 0.5 * Gtk2::Ex::Units::em($entry));
  $what_combobox->signal_connect ('changed', \&_do_what_changed, $self);
  $what_combobox->set_active (1);

  $hbox->pack_start (Gtk2::Label->new ('   ' . __('When:')), 0,0,0);

  my $when_model = $self->{'when_model'}
    = Gtk2::ListStore->new ('Glib::String', 'Glib::Scalar');
  $when_model->insert_with_values (WHEN_UPDATE, 0 => __('Update'));
  $when_model->insert_with_values (WHEN_BACKTO, 0 => __('Backto'));

  my $when_combobox = $self->{'when_combobox'}
    = Gtk2::ComboBox->new_with_model ($when_model);
  my $when_renderer = Gtk2::CellRendererText->new;
  $when_combobox->pack_start ($when_renderer, 1);
  $when_combobox->set_attributes ($when_renderer, text => 0);
  $hbox->pack_start ($when_combobox, 0,0,0);
  $when_combobox->set_active (WHEN_UPDATE);
  $when_combobox->signal_connect ('changed', \&_do_when_changed, $self);

  require Date::Calc;
  my ($today_year, undef, undef) = Date::Calc::Today();
  my $when_adj = Gtk2::Adjustment->new ($today_year-5,       # initial
                                        1800, $today_year+1, # min,max
                                        1,10,
                                        0);                  # page_size
  my $when_spin = $self->{'when_spin'}
    = Gtk2::SpinButton->new ($when_adj, 10, 0);
  $hbox->pack_start ($when_spin, 0,0,0);
  $when_spin->set_sensitive (0);

  _update_stop_sensitive ($self);
  _update_clear_sensitive ($self);

  $vbox->show_all;

  # with sensible jobs view, message text and entry sizes
  # FIXME: the initial proportions don't come out with the plain VBox packing
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       [$proc_scrolled,     -1,       '3 lines'],
       [$jobs_scrolled,     -1,       '4 lines'],
       [$messages_scrolled, '60 ems', '10 lines'],
       [$entry,             '10 ems', -1]);
}

# 'destroy' class closure
# this can be called more than once!
sub _do_destroy {
  my ($self) = @_;
  ### DownloadDialog _do_destroy()

  delete $self->{'model_ids'};

  # break circular references
  delete $self->{'textview'};
  delete $self->{'textbuf'};

  return shift->signal_chain_from_overridden(@_);
}

sub entry_symbol {
  my ($self) = @_;
  my $entry = $self->{'entry'};
  return App::Chart::collapse_whitespace ($entry->get_text());
}

sub _do_textbuf_changed {
  my ($textbuf, $self) = @_;
  _update_clear_sensitive ($self);
}

sub _do_what_changed {
  my ($combobox, $self) = @_;
  my $idx = $self->{'what_combobox'}->get_active;
  $self->{'entry'}->set_sensitive ($idx == 0);
}

sub _do_when_changed {
  my ($combobox, $self) = @_;
  my $idx = $self->{'when_combobox'}->get_active;
  $self->{'when_spin'}->set_sensitive ($idx == WHEN_BACKTO);
}

# 'message' emission hook on App::Chart::Gtk2::Job
sub _do_job_message {
  my ($invocation_hint, $parameters, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return 0; # disconnect
  my ($job, $str) = @$parameters;
  $self->message ($str);
  return 1; # stay connected
}

sub message {
  my ($self, $str) = @_;
  my $textbuf = $self->{'textview'}->get_buffer;
  $textbuf->insert ($textbuf->get_end_iter, $str);
}

sub start {
  my ($self, $what, $when) = @_;
  $self->{'hide_on_success'} = undef;

  my $queue = App::Chart::Gtk2::JobQueue->instance;
  $queue->remove_done;
  App::Chart::Gtk2::Subprocess->remove_done;

  require App::Chart::Gtk2::Job::Download;
  my $job = App::Chart::Gtk2::Job::Download->start ($what, $when);

  # if this job is the only one then select it
  if ($queue->iter_n_children(undef) == 1) {
    my $treeview = $self->{'jobs_treeview'};
    my $selection = $treeview->get_selection;
    $selection->select_path (Gtk2::TreePath->new_from_indices(0));
  }
  return $job;
}

sub _do_start_button {
  my ($self) = @_;

  my $what = $self->{'what_combobox'}->get_active;
  my $type;
  if ($what == 0) {
    $what = $self->{'entry'}->get_text;
    $what =~ s/$RE{ws}{crop}//g;      # leading and trailing whitespace
    if ($what eq '') {
      my $textbuf = $self->{'textbuf'};
      $textbuf->insert ($textbuf->get_end_iter, "No symbol entered.\n");
      $self->{'entry'}->grab_focus;
      return;
    }
    $type = $what;
  } elsif ($what == 1) {
    $type = __('Favourites');
    $what = '--favourites';
  } else {
    $type = __('All');
    $what = '--all';
  }

  my $when_index = $self->{'when_combobox'}->get_active;
  my $when = ($when_index == WHEN_BACKTO
              ? $self->{'when_spin'}->get_value
              : undef);

  $self->start ($what, $when);
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  ### DownloadDialog _do_response(): $response

  if ($response eq RESPONSE_START) {
    $self->_do_start_button;

  } elsif ($response eq RESPONSE_STOP) {
    my $treeview = $self->{'jobs_treeview'};
    my $selection = $treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    my $job = $model->get_value ($iter, 0);
    $job->stop;

  } elsif ($response eq RESPONSE_CLEAR) {
    my $textbuf = $self->{'textbuf'};
    $textbuf->delete ($textbuf->get_start_iter, $textbuf->get_end_iter);
    if (App::Chart::Gtk2::JobQueue->can('remove_done')) { # if loaded
      App::Chart::Gtk2::JobQueue->remove_done;
    }
    if (App::Chart::Gtk2::Subprocess->can('remove_done')) { # if loaded
      App::Chart::Gtk2::Subprocess->remove_done;
    }

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Download'), $self);
  }
}

sub _update_stop_sensitive {
  my ($self) = @_;
  my $treeview = $self->{'jobs_treeview'};
  my $selection = $treeview->get_selection;
  my ($model, $iter) = $selection->get_selected;
  my $job = $iter && $model->get_value ($iter, 0);
  my $sensitive = $job && $job->is_stoppable;
  $self->set_response_sensitive (RESPONSE_STOP, $sensitive);
}
sub _update_clear_sensitive {
  my ($self) = @_;

  my $anything_to_clear = do {
    my $textbuf = $self->{'textbuf'};
    $textbuf->get_char_count != 0
  } || do {
    App::Chart::Gtk2::JobQueue->can('remove_done')  # if loaded
        && List::Util::first {$_->get('done')} App::Chart::Gtk2::JobQueue->all_jobs;
  } || do {
    App::Chart::Gtk2::Subprocess->can('remove_done')  # if loaded
        && List::Util::first {! $_->pid} App::Chart::Gtk2::Subprocess->all_subprocesses;
  };
  $self->set_response_sensitive (RESPONSE_CLEAR, $anything_to_clear);
}

# 'button-press-event' on the treeview
sub _do_proc_treeview_button_press {
  my ($treeview, $event, $self) = @_;
  if ($event->button == 3) {
    require App::Chart::Gtk2::SubprocessStopMenu;
    App::Chart::Gtk2::SubprocessStopMenu->popup_from_treeview ($event, $treeview);
  }
  return Gtk2::EVENT_PROPAGATE;
}

# 'changed' on the treeview selection
sub _do_selection_changed {
  my ($selection, $self) = @_;
  _update_stop_sensitive ($self);
}

# 'row-changed' on the JobQueue model
sub _do_job_row_changed {
  my ($model, $path, $iter, $self) = @_;
  _update_stop_sensitive ($self);

  if (my $hide = $self->{'hide_on_success'}) {
    my $job = $model->get_value ($iter, 0);
    if ($job == $hide && $job->status eq __('Done')) {
      $self->hide;
    }
  }
}

# 'set_cell_data_func' to display a cell in the job model row
sub _job_cell_status {
  my ($treecolumn, $renderer, $model, $iter) = @_;
  my $job = $model->get_value ($iter, 0);
  my $str = join (' - ', $job->type // '', $job->status // ());
  $renderer->set (text => $str);
}

# 'set_cell_data_func' to display a cell in the subprocess model row
sub _proc_cell_status {
  my ($treecolumn, $renderer, $model, $iter) = @_;
  my $proc = $model->get_value ($iter, 0);
  my $str = $proc->status;
  $renderer->set (text => $str);
}

# 'button-press-event' on the treeview
sub _do_jobs_treeview_button_press {
  my ($treeview, $event) = @_;
  if ($event->button == 3) {
    require App::Chart::Gtk2::JobStopMenu;
    my $self = $treeview->get_toplevel;
    my $menu = ($self->{'job_menu'} ||= App::Chart::Gtk2::JobStopMenu->new);
    $menu->popup_from_treeview ($event, $treeview);
  }
  return Gtk2::EVENT_PROPAGATE;
}


#------------------------------------------------------------------------------
# generic helpers


1;
__END__

=for stopwords popup

=head1 NAME

App::Chart::Gtk2::DownloadDialog -- download dialog widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::DownloadDialog;
 App::Chart::Gtk2::DownloadDialog->popup;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::DownloadDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::DownloadDialog

=head1 DESCRIPTION

...

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::DownloadDialog->popup () >>

=item C<< App::Chart::Gtk2::DownloadDialog->popup ($symbol) >>

Popup a C<DownloadDialog> dialog, re-presenting any existing one or
otherwise creating a new one.

The optional C<$symbol> parameter is put into the symbol entry field, so the
user can have that already entered on choosing the "One Symbol" download.

=back

=head1 SEE ALSO

L<App::Chart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
