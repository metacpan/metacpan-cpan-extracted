# Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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

package App::Chart::Gtk2::DeleteDialog;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Glib;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;
use App::Chart::Gtk2::GUI;

use Glib::Object::Subclass
  'Gtk2::MessageDialog',
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'The stock or commodity symbol to ask about deleting',
                  '', # default
                  Glib::G_PARAM_READWRITE)];

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set (message_type => 'question',
              modal        => 1,
              title        => __('Chart: Delete Symbol'));
  $self->add_buttons ('gtk-ok'     => 'ok',
                      'gtk-cancel' => 'close');
  $self->signal_connect (response => \&_do_response);
  my $vbox = $self->vbox;

  my $notes_check = $self->{'notes_check'}
    = Gtk2::CheckButton->new_with_label(__('And delete your annotations too'));
  $notes_check->set_active (1);
  $vbox->pack_start ($notes_check, 0,0,0);

  my $notes_none = $self->{'notes_none'}
    = Gtk2::Label->new (__('(No annotations, just downloaded data.)'));
  $notes_none->set_alignment (0, 0.5);
  $vbox->pack_start ($notes_none, 0,0,0);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    my $symbol = $newval;
    $self->set (text => "\n" . __x('Delete symbol {symbol} ?',
                                   symbol => $symbol));
    if ($symbol && symbol_any_notes ($symbol)) {
      $self->{'notes_check'}->show;
      $self->{'notes_none'}->hide;
    } else {
      $self->{'notes_check'}->hide;
      $self->{'notes_none'}->show;
    }
  }
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  if ($response eq 'ok') {
    my $symbol = $self->get('symbol');
    if (defined $symbol) {
      # deleting is normally quite fast, but can be noticeable if the system
      # is a bit loaded or there's a lot of daily data
      require Gtk2::Ex::WidgetCursor;
      Gtk2::Ex::WidgetCursor->busy;

      my $notes_too = $self->{'notes_check'}->get_active;
      App::Chart::Database->delete_symbol ($symbol, $notes_too);
    }
  }
  $self->destroy;
}

# return true if $symbol has any notes in the database
sub symbol_any_notes {
  my ($symbol) = @_;
  my $nbh = App::Chart::DBI->instance;
  my $sth = $nbh->prepare_cached
    ('SELECT symbol FROM annotation WHERE symbol=?  UNION ALL
      SELECT symbol FROM line       WHERE symbol=?  UNION ALL
      SELECT symbol FROM alert      WHERE symbol=?
      LIMIT 1');
  my $row = $nbh->selectrow_arrayref ($sth, undef, $symbol, $symbol, $symbol);
  $sth->finish;
  return (defined $row);
}

sub popup {
  my ($class, $symbol, $parent) = @_;

  # supposed to be insensitive when no symbol, but check in case
  if (! defined $symbol || $symbol eq '') {
    return;
  }

  # if "modal" is obeyed by the window manager then there won't be any other
  # delete dialogs open, but it doesn't hurt to let popup() search
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     transient_for => $parent,
     properties    => { symbol => $symbol });
}

1;
__END__

=for stopwords popup Eg

=head1 NAME

App::Chart::Gtk2::DeleteDialog -- query user to delete symbol from database

=for test_synopsis my ($symbol, $parent_window)

=head1 SYNOPSIS

 use App::Chart::Gtk2::DeleteDialog;
 App::Chart::Gtk2::DeleteDialog->popup ($symbol, $parent_window);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::DeleteDialog> is a subclass of C<Gtk2::MessageDialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::MessageDialog
                App::Chart::Gtk2::DeleteDialog

=head1 DESCRIPTION

A C<App::Chart::Gtk2::DeleteDialog> asks the user whether to delete a given symbol
from the database and if the answer is yes then it does so.

=head1 FUNCTIONS

=over 4

=item C<< $dialog = App::Chart::Gtk2::DeleteDialog->popup ($symbol, $parent_window) >>

Create and popup a dialog asking the user whether to delete C<$symbol>.  The
dialog is created modal, and transient for the given C<$parent_window>.  Eg.

    App::Chart::Gtk2::DeleteDialog->popup ('FOO.ZZ', $toplevel);

The return value is the dialog created, but usually that can be ignored --
when the user answers it the dialog is destroyed.

=item C<< $dialog = App::Chart::Gtk2::DeleteDialog->new (key=>value,...) >>

Create and return a C<App::Chart::Gtk2::DeleteDialog>.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new() >>.  The dialog
is not displayed (but can be with C<show> in the usual way).

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (string)

The stock symbol to ask the user about and delete.  This can be changed
while the dialog is open (and the question text updates accordingly), but
doing so is likely to confuse the user.

=back

=head1 SEE ALSO

L<App::Chart::Database>, L<Gtk2::MessageDialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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
