# Copyright 2009, 2010, 2011, 2013 Kevin Ryde

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

package App::Chart::Gtk2::JobsRunningDialog;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;

use Glib::Object::Subclass
  'Gtk2::MessageDialog';

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set (message_type => 'question',
              modal => 1,
              title => __('Chart: Jobs Running Query'),
              text  => __('Job(s) still running, stop them ?'),
              destroy_with_parent => 1);
  $self->add_buttons ('gtk-ok'     => 'ok',
                      'gtk-cancel' => 'close');
  $self->signal_connect (response => \&_do_response);

  require App::Chart::Gtk2::JobQueue;
  my $model = Gtk2::TreeModelFilter->new (App::Chart::Gtk2::JobQueue->instance);
  $model->set_visible_func
    (sub {
       my ($jobqueue, $iter) = @_;
       return _job_is_queryable ($jobqueue->get($iter,0));
     });
  $model->get_iter_first || return;

  my $vbox = $self->vbox;
  my $treeview = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (headers_visible => 0);
  $vbox->pack_start ($treeview, 0,0,0);

  my $column = Gtk2::TreeViewColumn->new;
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0,
                  ypad => 0);
  $column->pack_start ($renderer, 1);
  require App::Chart::Gtk2::DownloadDialog;
  $column->set_cell_data_func
    ($renderer, \&App::Chart::Gtk2::DownloadDialog::_job_cell_status);
  $treeview->append_column ($column);

  $vbox->show_all;
}

sub _job_is_queryable {
  my ($job) = @_;
  return ($job->is_stoppable
          && ($job->isa('App::Chart::Gtk2::Job::Download')
              # not a subclass at the moment ...
              || $job->get('name') eq __('Vacuum database')));
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;

  if ($response eq 'ok') {
    Gtk2::Ex::WidgetCursor->busy;
    if (my $parent = $self->get_transient_for) {
      $parent->destroy;
    } else {
      warn 'JobsRunningDialog: no parent to destroy';
    }
    $self->destroy;

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which
    # in turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

sub popup {
  my ($class, $parent) = @_;

  # if "modal" is obeyed by the window manager then there won't be any other
  # JobsRunningDialog's open, but it doesn't hurt to let dialog_popup search
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::dialog_popup
    (class         => $class,
     transient_for => $parent);
}

sub query_and_quit {
  my ($class, $parent) = @_;
  if (App::Chart::Gtk2::JobQueue->can('instance')
      && (List::Util::first {_job_is_queryable($_)}
          App::Chart::Gtk2::JobQueue->all_jobs)) {
    $class->popup ($parent);
  } else {
    $parent->destroy;
  }
}

1;
__END__

=for stopwords ok Intraday

=head1 NAME

App::Chart::Gtk2::JobsRunningDialog -- query user about running jobs before quitting

=for test_synopsis my ($main_window)

=head1 SYNOPSIS

 use App::Chart::Gtk2::JobsRunningDialog;
 App::Chart::Gtk2::JobsRunningDialog->query_and_quit ($main_window);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::JobsRunningDialog> is a subclass of C<Gtk2::MessageDialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::MessageDialog
                App::Chart::Gtk2::JobsRunningDialog

=head1 DESCRIPTION

A C<App::Chart::Gtk2::JobsRunningDialog> asks the user whether to kill running jobs
before quitting.  Cancel means don't quit, ok means kill the jobs.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::JobsRunningDialog->query_and_quit ($main_window) >>

C<$main_window> is a C<Gtk2::Window> which is the application main window.
If there's any running or pending Download or Vacuum jobs in the
C<App::Chart::Gtk2::JobQueue> then popup a JobsRunningDialog asking the user
whether to kill them and quit, or cancel to not quit.

If the user chooses to kill then C<< $main_window->destroy() >> is called.
C<$main_window> should be set up to exit the main loop if destroyed and the
jobs will be stopped or discarded in the usual way when garbage collected.

If there's no running or pending jobs then C<< $main_window->destroy() >> is
called immediately, without any dialog.  Intraday image downloads and latest
quote downloads are ignored for quit query purposes since they're only for
immediate display, they're not user initiated database updates.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Job>, L<App::Chart::Gtk2::JobQueue>, L<Gtk2::MessageDialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2009, 2010, 2011, 2013 Kevin Ryde

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
