# update entries if database changes



# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::PreferencesDialog;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::Units;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::DBI;

# use App::Chart::Gtk2::Ex::ToplevelSingleton hide_on_delete => 1;
# use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';
# sub popup {
#   my ($class, $parent) = @_;
#   my $self = $class->instance;
#   $self->present;
#   return $self;
# }

use Glib::Object::Subclass
  'Gtk2::Dialog',
  signals => { show => \&_do_show },
  properties => [];


my @preferences = ( { key     => 'lme-username',
                      name    => __('LME Username'),
                      type    => 'string',
                      default => '' },
                    { key     => 'lme-password',
                      name    => __('LME Password'),
                      type    => 'string',
                      default => ''  },
                  );

use constant RESPONSE_SAVE => 0;

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: Preferences'));
  $self->add_buttons ('gtk-save'   => RESPONSE_SAVE,
                      'gtk-ok'     => 'ok',
                      'gtk-cancel' => 'cancel',
                      'gtk-help'   => 'help');
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;

  my @elements;
  $self->{'elements'} = \@elements;

  foreach my $pref (@preferences) {
    my $key = $pref->{'key'};
    my $name = $pref->{'name'};
    my $type = $pref->{'type'};

    my $hbox = Gtk2::HBox->new (0, 0);
    $hbox->{'key'} = $key;
    $hbox->{'type'} = $type;
    push @elements, $hbox;
    $vbox->pack_start ($hbox, 0,0,
                       0.25 * Gtk2::Ex::Units::line_height($hbox));

    my $label = Gtk2::Label->new ($name . " ");
    $label->set (xalign => 0); # left
    $hbox->pack_start ($label, 0,0,0);

    if ($type eq 'string') {
      my $entry = $hbox->{'entry'} = Gtk2::Entry->new ();
      $hbox->pack_start ($entry, 1,1,0);
      $entry->signal_connect
        (changed => sub { $self->set_response_sensitive (RESPONSE_SAVE, 1); });

    } elsif ($type eq 'boolean') {
      my $checkbox = $hbox->{'checkbox'} = Gtk2::CheckButton->new;
      $hbox->pack_start ($checkbox, 0,0,0);
      $checkbox->signal_connect
        (toggled => sub { $self->set_response_sensitive (RESPONSE_SAVE, 1); });
    }
  }
  $vbox->show_all;
}

# 'show' class closure
sub _do_show {
  my ($self) = @_;
  $self->load;
  return shift->signal_chain_from_overridden(@_);
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;

  if ($response eq RESPONSE_SAVE) {
    $self->save;

  } elsif ($response eq 'ok') {
    $self->save;
    $self->hide;

  } elsif ($response eq 'cancel') {
    $self->hide;

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Preferences'), $self);
  }
}

sub load {
  my ($self) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $aref;
  my $sth = $dbh->prepare_cached ('SELECT key, value FROM preference');
  $aref = $dbh->selectall_arrayref ($sth);
  $sth->finish;
  _set_widget_values ($self, $aref);
  $self->set_response_sensitive (RESPONSE_SAVE, 0);
}

# aref is an array reference of pairs [ ['key','value'],['key','value'],... ]
sub _set_widget_values {
  my ($self, $aref) = @_;

  PAIR: foreach my $pair (@$aref) {
    my $key = $pair->[0];
    my $value = $pair->[1];

    foreach my $element (@{$self->{'elements'}}) {
      if ($element->{'key'} ne $key) { next; }
      my $type = $element->{'type'};
      if ($type eq 'string') {
        $element->{'entry'}->set_text ($value);
      } elsif ($type eq 'boolean') {
        $element->{'checkbox'}->set_active ($value);
      } else {
        die "oops, unknown type ". $element->{'type'};
      }
      next PAIR;
    }
  }
}

sub save {
  my ($self) = @_;
  my @pairs = _get_widget_values ($self);
  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         foreach my $pair (@pairs) {
           my $key = $pair->[0];
           my $value = $pair->[1];
           $dbh->do ('INSERT OR REPLACE INTO preference (key, value)
                      VALUES (?,?)', {}, $key, $value);
         }
       });
  $self->set_response_sensitive (RESPONSE_SAVE, 0);
}

# return a list of pairs ['key','value'],['key','value'],...
sub _get_widget_values {
  my ($self) = @_;
  my @ret;
  foreach my $element (@{$self->{'elements'}}) {
    my $key = $element->{'key'};
    my $value;
    my $type = $element->{'type'};
    if ($type eq 'string') {
      $value = $element->{'entry'}->get_text;
    } elsif ($type eq 'boolean') {
      $value = ($element->{'checkbox'}->get_active ? 1 : 0);
    } else {
      die "oops, unknown type ". $element->{'type'};
    }
    push @ret, [ $key, $value ];
  }
  return @ret;
}


1;
__END__


=head1 NAME

App::Chart::Gtk2::PreferencesDialog -- preferences dialog widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::PreferencesDialog;
 App::Chart::Gtk2::PreferencesDialog->popup();

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::PreferencesDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::PreferencesDialog

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::PreferencesDialog->popup() >>

=back

=cut
