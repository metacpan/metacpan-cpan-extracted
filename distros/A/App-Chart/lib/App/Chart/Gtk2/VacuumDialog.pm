# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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


# FIXME: consistency checks mark as historical things merely not downloaded
# for a while


package App::Chart::Gtk2::VacuumDialog;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Glib::Ex::ConnectProperties;
use Gtk2::Ex::Units;
use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;

use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';

use Glib::Object::Subclass
  'Gtk2::Dialog',
  signals => { destroy => \&_do_destroy };

use constant { RESPONSE_START  => 0,
               RESPONSE_STOP   => 1,
               RESPONSE_CLEAR  => 2 };

# sub popup {
#   my ($class) = @_;
#   require Gtk2::Ex::WidgetCursor;
#   Gtk2::Ex::WidgetCursor->busy;
#   my $dialog = $class->instance;
#   $dialog->present;
#   return $dialog;
# }

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: Vacuum'));
  $self->add_buttons (__('_Start') => $self->RESPONSE_START,
                      __('_Stop')  => $self->RESPONSE_STOP,
                      'gtk-clear'  => $self->RESPONSE_CLEAR,
                      'gtk-close'  => 'close',
                      'gtk-help'   => 'help');
  $self->signal_connect (response => \&_do_response);
  my $vbox = $self->vbox;

  my $heading = Gtk2::Label->new (__"Compact and clean out the database.\n(May take a while if the database is big.)");
  $heading->set (justify => 'center');
  $vbox->pack_start ($heading, 0,0,0);

  {
    my $button = $self->{'consistency'}
      = Gtk2::CheckButton->new_with_label (__('Consistency Checks'));
    $button->set_active (1);
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $button = $self->{'compact'}
      = Gtk2::CheckButton->new_with_label (__('Compact Files'));
    $button->set_active (1);
    $vbox->pack_start ($button, 0, 0, 0);
  }
  {
    my $button = $self->{'verbose'}
      = Gtk2::CheckButton->new_with_label (__('Verbose'));
    $vbox->pack_start ($button, 0, 0, 0);
  }

  my $textbuf = $self->{'textbuf'} = Gtk2::TextBuffer->new;

  # clear button sensitive when there is in fact something to clear
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#not-empty'],
       [$self,    'response-sensitive#'.$self->RESPONSE_CLEAR]);

  require Gtk2::Ex::TextView::FollowAppend;
  my $textview = $self->{'textview'}
    = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf);
  $textview->set (wrap_mode => 'char',
                  editable => 0);

  my $scrolled = Gtk2::ScrolledWindow->new();
  $scrolled->add($textview);
  $scrolled->set_policy('never', 'always');
  $vbox->pack_start ($scrolled, 1, 1, 0);

  my $status = $self->{'status'}
    = Gtk2::Label->new ("Press Start to begin vacuuming ...\n");
  $vbox->pack_start ($status, 0,0,0);

  _update_stop_sensitive ($self);
  $vbox->show_all;

  # with sensible message area size
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       [$textview, '60 ems', -1],
       [$scrolled, -1, '6 lines']);
}

# 'destroy' class closure
# this can be called more than once!
sub _do_destroy {
  my ($self) = @_;
  ### VacuumDialog destroy

  delete $self->{'model_ids'};

  # break circular references
  delete $self->{'textview'};
  delete $self->{'textbuf'};

  return shift->signal_chain_from_overridden(@_);
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  ### VacuumDialog response: $response

  if ($response eq RESPONSE_START) {
    my $textbuf = $self->{'textbuf'};
    $textbuf->delete ($textbuf->get_start_iter, $textbuf->get_end_iter);
    $self->start;

  } elsif ($response eq RESPONSE_STOP) {
    $self->stop;

  } elsif ($response eq RESPONSE_CLEAR) {
    my $textbuf = $self->{'textbuf'};
    $textbuf->delete ($textbuf->get_start_iter, $textbuf->get_end_iter);
    _remove_done_job ($self);

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');

  } elsif ($response eq 'help') {
    # require App::Chart::Manual;
    # App::Chart::Manual->open(__p('manual-node','Vacuum'), $self);
  }
}

sub start {
  my ($self) = @_;
  $self->stop;
  $self->{'status'}->set_text (__('Starting vacuum job'));
  $self->message (__("Vacuuming ...\n"));
  require App::Chart::Gtk2::Job;
  my $job = $self->{'job'} = App::Chart::Gtk2::Job->start
    (args => ['vacuum',
              (map { ($_, $self->{$_}->get_active) }
               'compact', 'consistency', 'verbose') ],
     name => __('Vacuum database'));
  $job->signal_connect (message => \&_do_job_message,
                        App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
  $job->signal_connect (status_changed => \&_do_job_status,
                        App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
  _update_stop_sensitive ($self);
  return $job;
}
sub stop {
  my ($self) = @_;
  my $job = $self->{'job'} || return;
  $job->stop;
  _remove_done_job ($self);
}
sub _remove_done_job {
  my ($self) = @_;
  my $job = $self->{'job'} || return;
  if ($job->is_done) {
    ### VacuumDialog: removing done job
    delete $self->{'job'};
    App::Chart::Gtk2::JobQueue->remove_job ($job);
  }
}

# 'message' signal handler for App::Chart::Gtk2::Job
sub _do_job_message {
  my ($job, $str, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->message ($str);
}
sub message {
  my ($self, $str) = @_;
  my $textbuf = $self->{'textview'}->get_buffer;
  $textbuf->insert ($textbuf->get_end_iter, $str);
}

# 'status-changed' signal handler for App::Chart::Gtk2::Job
sub _do_job_status {
  my ($job, $str, $ref_weak_self) = @_;
  ### VacuumDialog: job status: $str
  my $self = $$ref_weak_self || return;
  $self->{'status'}->set_text ($str);
  _update_stop_sensitive ($self);

  if ($job->is_done) {
    $self->message (__("done\n"));
  }
}

sub _update_stop_sensitive {
  my ($self) = @_;
  my $job = $self->{'job'};
  my $running = $job && $job->is_stoppable;
  $self->set_response_sensitive (RESPONSE_START, ! $running);
  $self->set_response_sensitive (RESPONSE_STOP, $running);
}

1;
__END__

=for stopwords Popup

=head1 NAME

App::Chart::Gtk2::VacuumDialog -- vacuum the database dialog widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::VacuumDialog;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::VacuumDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::VacuumDialog

=head1 DESCRIPTION

...

=head1 FUNCTIONS

=cut

# =over 4
# 
#  App::Chart::Gtk2::VacuumDialog->popup;
# 
# =item C<< App::Chart::Gtk2::VacuumDialog->popup () >>
# 
# Popup a C<VacuumDialog> dialog.
# 
# =back

