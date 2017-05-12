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

package App::Chart::Gtk2::IntradaySave;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::Units;
use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::FileChooserDialog',
  signals => { delete_event => \&Gtk2::Widget::hide_on_delete },
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
               RESPONSE_CROSS    => 1 };


sub new {
  my $class = shift;
  # pending support for object "constructor" thingie
  $class->SUPER::new (action => 'save', @_);
}

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'symbol'} = '';  # defaults
  $self->{'mode'} = '';

  $self->set_title (__('Chart: Save Intraday Image'));
  $self->add_buttons ('gtk-save'   => 'accept',
                      'gtk-cancel' => 'cancel',
                      # 'gtk-help'    => 'help'
                     );

  # connect to self instead of a class handler since as of Gtk2-Perl 1.200 a
  # Gtk2::Dialog class handler for 'response' is called with response IDs as
  # numbers, not enum strings like 'accept'
  #
  # this is an "after" to allow a user's signals to be called first on
  # 'close' or 'delete-event', since we're going to $self->destroy on those
  #
  $self->signal_connect_after (response => \&_do_response);

  my $vbox = $self->vbox;
  {
    my $label = Gtk2::Label->new (__('Save intraday image to file')
                                  . "\n\nCaution: This is a bit rough yet.");
    $label->show;
    $vbox->pack_start ($label, 0,0,0);
    $vbox->reorder_child ($label, 0); # at the top of the dialog
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
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

sub _do_response {
  my ($self, $response) = @_;
  ### IntradaySave response: $response

  if ($response eq 'accept') {
    $self->save;

  } elsif ($response eq 'cancel') {
    # raise 'close' as per a keyboard Esc to close, which defaults to
    # raising 'delete-event', which is setup as a hide() above
    $self->signal_emit ('close');
  }
}

sub popup {
  my ($class, $intradaydialog) = @_;
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     properties => { transient_for => $intradaydialog },
     screen => $intradaydialog);
}

sub save {
  my ($self) = @_;
  my $intradaydialog = $self->get_transient_for;
  my ($symbol, $mode) = $intradaydialog->get('symbol','mode');

  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached
    ('SELECT image, error FROM intraday_image WHERE symbol=? AND mode=?');
  my ($blob, $error) = $dbh->selectrow_array
    ($sth, undef, $self->{'symbol'}, $self->{'mode'});
  $sth->finish();
  if (defined $blob) {
    my $filename = $self->get_filename;
    open my $fh, '>', $filename or die;
    binmode ($fh) or die;
    print $fh $blob or die;
    close $fh or die;
  } else {
    my $msg = Gtk2::MessageDialog->new ($self,
                                        ['modal','destroy-with-parent'],
                                        'error',
                                        'ok',
                                        "No image to save: %s",
                                        $error||__('(No data)'));
    $msg->signal_connect (response => sub {
                            my ($msg) = @_;
                            $msg->destroy;
                          });
    $msg->present;
  }
}

1;
__END__

=for stopwords intraday

=head1 NAME

App::Chart::Gtk2::IntradaySave -- intraday image saving dialog

=for test_synopsis my $intradaydialog

=head1 SYNOPSIS

 use App::Chart::Gtk2::IntradaySave;
 App::Chart::Gtk2::IntradaySave->popup ($intradaydialog);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::IntradaySave> is a subclass of C<Gtk2::FileChooserDialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::FileChooserDialog
                App::Chart::Gtk2::IntradaySave

=head1 DESCRIPTION

An IntradaySave offers to save an intraday image file to disk, out of the
database.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::IntradaySave->popup ($intradaydialog) >>

=item C<< $savedialog->save () >>

=back

=head1 PROPERTIES

=over 4

=item C<parent>

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::IntradayImage>

=cut
