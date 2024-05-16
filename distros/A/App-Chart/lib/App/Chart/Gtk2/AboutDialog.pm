# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023, 2024 Kevin Ryde

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

package App::Chart::Gtk2::AboutDialog;
use 5.010;
use strict;
use warnings;
use Glib;
use Gtk2;
use Software::License::GPL_3;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Gtk2::GUI;

use Glib::Object::Subclass 'Gtk2::AboutDialog';

our $VERSION = 274;

# this applies to the whole program
my $copyright_string
  = __('Copyright (C) 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010 Kevin Ryde');

sub INIT_INSTANCE {
  my ($self) = @_;

  # Per Gtk docs, this must be before set_website() etc.
  # Had thought the default in Gtk 2.16 up was gtk_show_uri, needing no
  # setting here, but that doesn't seem to be so.
  # ENHANCE-ME: Maybe this belongs with global GUI inits.
  Gtk2::AboutDialog->set_url_hook (\&_do_url_hook);

  # "authors" comes out as a separate button and dialog, don't need that
  # $self->set_authors (__('Kevin Ryde'));

  $self->set_version ($self->VERSION);
  $self->set_copyright ($copyright_string);
  $self->set_website ('http://user42.tuxfamily.org/chart/index.html');

  # the same as COPYING in the sources
  my $sl = Software::License::GPL_3->new({ holder => 'Kevin Ryde' });
  $self->set_license ($sl->license);

  $self->set_comments
    (__x("Chart is Free Software, distributed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.  Click on the License button below for the full text.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the license for more.

You are running under: Perl {perlver}, Gtk2-Perl {gtkperlver}, Gtk {gtkver}, Glib-Perl {glibperlver}, Glib {glibver}
",
         perlver     => sprintf('%vd', $^V),
         gtkver      => (Gtk2::major_version() . '.' . Gtk2::minor_version()
                         . '.' . Gtk2::micro_version()),
         glibver     => (Glib::major_version() . '.' . Glib::minor_version()
                         . '.' . Glib::micro_version()),
         gtkperlver  => Gtk2->VERSION,
         glibperlver => Glib->VERSION));

  # connect to self rather than class closure for "response" since bad
  # $response enum interpretation as of Perl-Gtk2 1.220
  $self->signal_connect (response => \&_do_response);
}

sub _do_response {
  my ($self, $response) = @_;

  if ($response eq 'cancel') {
    # "Close" button gives GTK_RESPONSE_CANCEL.
    # Emit 'close' same as a keyboard Esc to close, and that signal defaults
    # to raising 'delete-event', which in turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

sub _do_url_hook {
  my ($self, $url) = @_;
  App::Chart::Gtk2::GUI::browser_open ($url, $self);
}

1;
__END__

=for stopwords AboutDialog

=head1 NAME

App::Chart::Gtk2::AboutDialog -- about dialog module

=head1 SYNOPSIS

 use App::Chart::Gtk2::AboutDialog;
 my $dialog = App::Chart::Gtk2::AboutDialog->new;
 $dialog->present;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::AboutDialog> is a subclass of C<Gtk2::AboutDialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::AboutDialog
                App::Chart::Gtk2::AboutDialog

=head1 FUNCTIONS

=over 4

=item C<< $dialog = App::Chart::Gtk2::AboutDialog->new() >>

Create and return a new AboutDialog.  The dialog close button or window
manager delete event destroys the dialog.

=back

=head1 SEE ALSO

L<chart>,
L<Gtk2::AboutDialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2023, 2024 Kevin Ryde

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
