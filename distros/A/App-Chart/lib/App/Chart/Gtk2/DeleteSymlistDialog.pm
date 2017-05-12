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

package App::Chart::Gtk2::DeleteSymlistDialog;
use 5.010;
use strict;
use warnings;
use Glib;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;
use App::Chart::Database;
use App::Chart::Gtk2::GUI;

use App::Chart::Gtk2::Symlist;
use Glib::Object::Subclass
  'Gtk2::MessageDialog',
  properties => [Glib::ParamSpec->object
                 ('symlist',
                  'symlist',
                  'The symlist to ask about deleting',
                  'App::Chart::Gtk2::Symlist',
                  Glib::G_PARAM_READWRITE)];

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set (message_type => 'question',
              modal        => 1,
              title        => __('Chart: Delete Symlist'));
  $self->add_buttons ('gtk-ok'     => 'ok',
                      'gtk-cancel' => 'close');
  $self->signal_connect (response => \&_do_response);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symlist') {
    my $symlist = $newval;
    _update_text ($self);

    $self->{'symlist_ids'} = $symlist && do {
      my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak ($self);
      Glib::Ex::SignalIds->new
          ($symlist,
           $symlist->signal_connect (row_inserted => \&_do_row_insdel,
                                     $ref_weak_self),
           $symlist->signal_connect (row_deleted  => \&_do_row_insdel,
                                     $ref_weak_self))
        };
  }
}

sub _do_row_insdel {
  my $ref_weak_self = $_[-1];
  my $self = $$ref_weak_self || return;
  _update_text ($self);
}

sub _update_text {
  my ($self) = @_;
  my $symlist = $self->{'symlist'};
  my $text;
  if ($symlist) {
    my $length = $symlist->length;
    $text = "\n"
      . __x('Delete symlist "{name}" ?', name => $symlist->name)
        . "\n\n"
          . __nx('It has {length} symbol in it.',
                 'It has {length} symbols in it.',
                 $length,
                 length => $length);
  } else {
    $text = '(No symlist)';
  }
  $self->set (text => $text);
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  if ($response eq 'ok') {
    if (my $symlist = $self->{'symlist'}) {
      $self->set (symlist => undef);
      $symlist->delete_symlist;
    }
  }
  $self->destroy;
}

sub popup {
  my ($class, $symlist, $parent) = @_;

  # if "modal" is obeyed by the window manager then there won't be any other
  # delete dialogs open, but it doesn't hurt to let popup() search
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     transient_for => $parent,
     properties    => { symlist => $symlist });
}

1;
__END__
