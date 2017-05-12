# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

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

package App::Chart::Gtk2::IntradayDialog;
use 5.010;
use strict;
use warnings;
use Gtk2 1.220;
use List::Util 'min';
use Regexp::Common 'whitespace';
use POSIX ();
use Glib::Ex::ConnectProperties;
use Gtk2::Ex::CrossHair;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::EntryBits;
use Gtk2::Ex::Units;
use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::IntradayHandler;
use App::Chart::Gtk2::IntradayImage;
use App::Chart::Gtk2::IntradayModeComboBox;
use App::Chart::Gtk2::Job;
use App::Chart::Gtk2::Job::Intraday;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Dialog',
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'The symbol of the stock or commodity to be shown',
                  '', # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('mode',
                  'mode',
                  'The graph mode, such as 1 day or 5 days',
                  '', # default
                  Glib::G_PARAM_READWRITE)];

use constant { RESPONSE_REFRESH  => 0,
               RESPONSE_CROSS    => 1,
               RESPONSE_SAVE     => 2,
               RESPONSE_PRINT    => 3 };


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'symbol'} = '';  # defaults
  $self->{'mode'} = '';

  my $combobox = $self->{'combobox'}
    = App::Chart::Gtk2::IntradayModeComboBox->new;
  $combobox->show;
  $self->add_accel_group ($combobox->accelgroup);

  $self->action_area->add ($combobox);
  Glib::Ex::ConnectProperties->new ([$self,'symbol'],
                                    [$combobox,'symbol']);
  Glib::Ex::ConnectProperties->new ([$combobox,'mode'],
                                    [$self,'mode']);

  my $crossbutton = $self->{'crossbutton'}
    = Gtk2::CheckButton->new (__('Cr_oss'));
  $crossbutton->set_active (0);
  $self->add_action_widget ($crossbutton, RESPONSE_CROSS);

  $self->set_title (__('Chart: Intraday'));
  $self->{'refresh_button'}
    = $self->add_button ('gtk-refresh' => RESPONSE_REFRESH);
  $self->add_buttons ('gtk-print'   => RESPONSE_PRINT,
                      'gtk-save'    => RESPONSE_SAVE,
                      'gtk-close'   => 'close',
                      'gtk-help'    => 'help');
  # this is an "after" to allow a user's signals to be called first on
  # 'close' or 'delete-event', since we're going to $self->destroy on those
  $self->signal_connect_after (response => \&_do_response);

  my $vbox = $self->vbox;

  # display symbol and mode in a label, since can't be certain the window
  # manager will have a good title bar
  my $title_label = $self->{'title_label'} = Gtk2::Label->new ('');
  _update_title_label ($self);
  $vbox->pack_start ($title_label, 0,0,0);

  # centre in area, don't grow image beyond desired size
  my $align = Gtk2::Alignment->new (0.5, 0.5, 0, 0);
  $vbox->pack_start ($align, 1,1,0);

  my $image = $self->{'image'} = App::Chart::Gtk2::IntradayImage->new;
  $align->add ($image);
  Glib::Ex::ConnectProperties->new ([$self,'symbol'],
                                    [$image,'symbol']);
  Glib::Ex::ConnectProperties->new ([$self,'mode'],
                                    [$image,'mode']);

  my $crosshair = $self->{'crosshair'}
    = Gtk2::Ex::CrossHair->new (widget => $image,
                                foreground => 'orange');
  Glib::Ex::ConnectProperties->new ([$crossbutton,'active'],
                                    [$crosshair,'active']);
  $image->add_events ('button-press-mask');
  $image->signal_connect (button_press_event =>\&_do_image_button_press_event);

  my $progress_label = $self->{'progress_label'} = Gtk2::Label->new ('');
  $vbox->pack_start ($progress_label, 0,0,0);

  my $hbox = Gtk2::HBox->new();
  $vbox->pack_start ($hbox, 0,0,0);

  $hbox->pack_start (Gtk2::Label->new (__('Symbol')), 0,0,0);

  my $entry = Gtk2::Entry->new ();
  $self->{'entry'} = $entry;
  $hbox->pack_start ($entry, 1, 1, 0.5 * Gtk2::Ex::Units::em($entry));
  $entry->signal_connect (activate => \&_do_entry_activate);

  my $button = Gtk2::Button->new_with_label (__('Enter'));
  $hbox->pack_start ($button, 0,0,0);
  $button->signal_connect (clicked => \&_do_enter_button);

  # During perl "global destruction" can have App::Chart::Gtk2::Job already
  # destroyed enough that it has disconnected the message emission hook
  # itself, leading to an unsightly Glib warning on attempting
  # signal_remove_emission_hook() in our 'destroy' class closure.
  #
  # As a workaround instead leave it connected, with a weakened ref, and let
  # it return 0 to disconnect itself on the next emission (if any).
  #
  #   App::Chart::Gtk2::Job->signal_add_emission_hook
  #       ('status-changed', \&_do_job_status_changed,
  #        App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
  #
  require App::Chart::Glib::Ex::EmissionHook;
  $self->{'hook'} = App::Chart::Glib::Ex::EmissionHook->new
    ('App::Chart::Gtk2::Job',
     status_changed => \&_do_job_status_changed,
     App::Chart::Glib::Ex::MoreUtils::ref_weak($self));

  $vbox->show_all;

  # secret Control-L to redraw
  # ENHANCE-ME: maybe accel_path thing for configurability
  my $accelgroup = $self->{'accelgroup'} = Gtk2::AccelGroup->new;
  $self->add_accel_group ($accelgroup);
  $accelgroup->connect (Gtk2::Gdk->keyval_from_name('l'), ['control-mask'], [],
                        \&_do_accel_redraw);

  # with a sensible intraday image size
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self, [$image, 512, 288]);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### SET_PROPERTY: $pspec->get_name
  ### newval: ''.\$newval

  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    my $symbol = $newval;
    my $entry = $self->{'entry'};
    $entry->set_text ($symbol);
    Gtk2::Ex::EntryBits::select_region_noclip ($entry, 0, -1);
  }
  _update_title_label ($self);
  _update_job_status ($self);
  $self->refresh_old;
}

# refresh if the image in the database is more than 2 minutes old, or
# there's none in the database at all
sub refresh_old {
  my ($self) = @_;
  my $symbol = $self->{'symbol'} || return;
  my $mode   = $self->{'mode'}   || return;

  require App::Chart::DBI;
  require App::Chart::Download;
  my $timestamp = App::Chart::DBI->read_single
    ('SELECT fetch_timestamp FROM intraday_image WHERE symbol=? AND mode=?',
     $symbol, $mode);
  if (! App::Chart::Download::timestamp_within ($timestamp, 120)) {
    $self->refresh;
  }
}

# download a fresh image for the current symbol+mode
sub refresh {
  my ($self) = @_;
  ### IntradayDialog refresh()
  my $symbol = $self->{'symbol'} || return;
  my $mode   = $self->{'mode'}   || return;

  require App::Chart::Gtk2::Job::Intraday;
  App::Chart::Gtk2::Job::Intraday->start ($symbol, $mode);
  _update_job_status ($self);
}

# 'activate' signal on the Gtk2::Entry
sub _do_entry_activate {
  my ($entry) = @_;
  my $self = $entry->get_toplevel;
  $self->goto_entry;
}
# 'clicked' signal on the "Enter" button
sub _do_enter_button {
  my ($button) = @_;
  my $self = $button->get_toplevel;
  $self->goto_entry;
}
# set symbol to current contents of the text entry widget
sub goto_entry {
  my ($self) = @_;
  my $entry = $self->{'entry'};
  my $symbol = $entry->get_text;
  $symbol =~ s/$RE{ws}{crop}//go;      # leading and trailing whitespace
  $self->set (symbol => $symbol);
  $self->refresh_old;
}

# 'button-press-event' in the IntradayImage widget
sub _do_image_button_press_event {
  my ($image, $event) = @_;
  if ($event->button == 3) {
    my $self = $image->get_toplevel;
    $self->{'crosshair'}->start ($event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _do_response {
  my ($self, $response) = @_;
  ### IntradayDialog response: $response

  if ($response eq RESPONSE_REFRESH) {
    $self->refresh;

  } elsif ($response eq RESPONSE_SAVE) {
    require App::Chart::Gtk2::IntradaySave;
    App::Chart::Gtk2::IntradaySave->popup ($self);

  } elsif ($response eq RESPONSE_PRINT) {
    $self->print_image;

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Intraday'), $self);
  }
}

sub _update_title_label {
  my ($self) = @_;
  my $title_label = $self->{'title_label'};
  my $symbol = $self->{'symbol'};
  my $mode = $self->{'mode'};
  my $handler
    = App::Chart::IntradayHandler->handler_for_symbol_and_mode ($symbol, $mode);
  my $modename = ($handler ? $handler->name_sans_mnemonic : '');
  $title_label->set_text ($symbol
                          ? __x('Chart: Intraday: {symbol} - {modename}',
                                symbol => $symbol,
                                modename => $modename)
                          : __('Chart: Intraday'));
}

# 'status-change' signal emission hook
sub _do_job_status_changed {
  my ($invocation_hint, $param_list, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return 0; # disconnect
  _update_job_status ($self);
  return 1; # stay connected
}

sub _update_job_status {
  my ($self) = @_;
  ### IntradayDialog update job status
  my $symbol = $self->{'symbol'};
  my $mode = $self->{'mode'};
  my $job = App::Chart::Gtk2::Job::Intraday->find ($symbol, $mode);
  my $job_running = ($job && $job->is_stoppable);
  ### job: $job

  my $status_str = ($job ? __('Download: ') . $job->status : '');
  $self->{'progress_label'}->set_text ($status_str);
  ### status: $job && $job->status

  $self->set_response_sensitive (RESPONSE_REFRESH,
                                 $symbol && $mode && ! $job_running);

  if ($job_running) {
    # created when first needed for a running job
    $self->{'widgetcursor'} ||= do {
      require Gtk2::Ex::WidgetCursor;
      Gtk2::Ex::WidgetCursor->new (widgets => [ $self->{'image'},
                                                $self->{'refresh_button'} ],
                                   cursor => 'watch',
                                   priority => 10);
    };
  }
  if (my $wcursor = $self->{'widgetcursor'}) {
    $wcursor->active ($job_running);
  }
}

sub _do_accel_redraw {
  my ($accelgroup, $self, $keyval, $modifiers) = @_;
  $self->queue_draw;
}

sub popup {
  my ($class, $symbol, $parent) = @_;
  if (! defined $symbol) { $symbol = ''; }
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     properties => { symbol => $symbol },
     screen => $parent);
}

#------------------------------------------------------------------------------
# printing

sub print_image {
  my ($self) = @_;
  my $print = Gtk2::PrintOperation->new;
  $print->set_n_pages (1);
  if (my $settings = $self->{'print_settings'}) {
    $print->set_print_settings ($settings);
  }
  $print->signal_connect (draw_page => \&_draw_page,
                          App::Chart::Glib::Ex::MoreUtils::ref_weak($self));

  my $result = $print->run ('print-dialog', $self);
  if ($result eq 'apply') {
    $self->{'print_settings'} = $print->get_print_settings;
  }
}

sub _draw_page {
  my ($print, $pcontext, $pagenum, $ref_weak_self) = @_;
  ### _draw_page()
  my $self = $$ref_weak_self || return;
  my $c = $pcontext->get_cairo_context;

  my $symbol = $self->{'symbol'};
  my $mode = $self->{'mode'};
  my $handler = App::Chart::IntradayHandler->handler_for_symbol_and_mode
    ($symbol, $mode);
  my $modename = ($handler ? $handler->name_sans_mnemonic : '');
  my $str = "$symbol - $mode";

  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached
    ('SELECT image, error, fetch_timestamp FROM intraday_image WHERE symbol=? AND mode=?');
  my ($blob, $error, $timestamp) = $dbh->selectrow_array
    ($sth, undef, $self->{'symbol'}, $self->{'mode'});
  $sth->finish();
  if (defined $timestamp) {
    my $timet = App::Chart::Download::timestamp_to_timet($timestamp);
    my $timezone = App::Chart::TZ->for_symbol ($symbol);
    $str .= '    ' . POSIX::strftime ($App::Chart::option{'d_fmt'} . ' %H:%M',
                                      $timezone->localtime($timet));
  }
  $str .= "\n\n"; # blank line

  my $pixbuf = $self->{'image'}->_load_pixbuf;
  # $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file
  #   ('/usr/share/emacs/23.2/etc/images/splash.png');
  # $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file
  #   ('/usr/share/games/gav/themes/classic/background_big.png');
  if (! ref $pixbuf) {
    $str .= $pixbuf;  # error message
  }

  my $pwidth = $pcontext->get_width;
  ### $pwidth

  my $layout = $pcontext->create_pango_layout;
  $layout->set_width ($pwidth * Gtk2::Pango::PANGO_SCALE);
  $layout->set_text ($str);
  my (undef, $str_height) = $layout->get_pixel_size;
  ### $str_height
  $c->move_to (0, 0);
  Gtk2::Pango::Cairo::show_layout ($c, $layout);

  if (ref $pixbuf) {
    my $pixbuf_width = $pixbuf->get_width;
    my $pixbuf_height = $pixbuf->get_height;
    ### $pixbuf_width
    ### $pixbuf_height

    my $pheight = $pcontext->get_height - $str_height;
    $c->translate (0, $str_height);

    if ($pixbuf_width > $pwidth || $pixbuf_height > $pheight) {
      # shrink if too big
      my $factor = min ($pwidth / $pixbuf_width,
                        $pheight / $pixbuf_height);
      $c->scale ($factor, $factor);
    }

    Gtk2::Gdk::Cairo::Context::set_source_pixbuf ($c, $pixbuf, 0,0);
    $c->rectangle (0,0, $pixbuf_width,$pixbuf_height);
    $c->paint;
  }
}

1;
__END__

=for stopwords intraday

=head1 NAME

App::Chart::Gtk2::IntradayDialog -- intraday graph dialog widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::IntradayDialog;
 App::Chart::Gtk2::IntradayDialog->popup;              # initially empty
 App::Chart::Gtk2::IntradayDialog->popup ('BHP.AX');   # or given symbol

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::IntradayDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::IntradayDialog

=head1 DESCRIPTION

A C<App::Chart::Gtk2::IntradayDialog> displays intraday graphs in the form of
downloaded graphics images.  The various data sources setup available modes
such as 1-day or 5-day and the C<IntradayDialog> downloads and shows them.

Some data sources don't offer historical data as figures, but only as
graphics images.  For them "intraday" is pressed into service to show daily
data too.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::IntradayDialog->popup () >>

=item C<< App::Chart::Gtk2::IntradayDialog->popup ($symbol) >>

Present an intraday dialog for C<$symbol>.  C<$symbol> is a string, or
empty, C<undef> or omitted to get a dialog showing nothing initially.

If a dialog already exists showing C<$symbol> then it's raised rather than
creating a new one.

=item C<< $dialog->goto_entry() >>

Go to the symbol entered in the text entry box by setting it as the
C<symbol> property.  This is used by the return key in that entry box and
the "Enter" button beside it.

=item C<< $dialog->refresh() >>

Download a new image for the current symbol and mode.  This is the "Refresh"
button in the action area.

=back

=head1 PROPERTIES

=over 4

=item C<symbol>

The stock symbol (a string) to display.

=item C<mode>

The display mode (a string), such as '1 Day'.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::IntradayImage>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

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
