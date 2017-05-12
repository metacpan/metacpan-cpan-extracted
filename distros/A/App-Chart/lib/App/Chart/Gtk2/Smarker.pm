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

package App::Chart::Gtk2::Smarker;
use 5.010;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;

use App::Chart::Gtk2::Ex::ListModelPos;


use App::Chart::Gtk2::SymlistListModel;
my $lists = App::Chart::Gtk2::SymlistListModel->instance;

sub new {
  my ($class, $symbol, $symlist) = @_;
  my $listpos = App::Chart::Gtk2::Ex::ListModelPos->new (model => $lists);
  my $self = bless { lists_listpos => $listpos }, $class;
  $self->goto ($symbol, $symlist);
  return $self;
}

sub goto {
  my ($self, $symbol, $symlist) = @_;
  ### Smarker goto: $symbol
  ### symlist: defined $symlist && $symlist->key

  if ($symlist) {
    $self->{'lists_listpos'}->goto ($lists->key_to_pos ($symlist->key));
    my $pos = $symlist->find_symbol_pos ($symbol);
    $self->{'symlist_listpos'}
      = App::Chart::Gtk2::Ex::ListModelPos->new (model => $symlist,
                                     type  => 'at',
                                     index => $pos);
  } else {
    # FIXME: find first symlist containing symbol
    #
    $self->{'lists_listpos'}->goto (0, 'before');
    $self->{'symlist_listpos'} = undef;
  }
}

sub symlist {
  my ($self) = @_;
  my $listpos = $self->{'lists_listpos'} || return undef;
  my $iter = $listpos->iter || return undef;
  my $key = $lists->get_value ($iter, 0);
  return App::Chart::Gtk2::Symlist->new_from_key ($key);
}


sub _condition {
  my ($self, $condition) = @_;
  if (! defined $condition) { return \&Glib::TRUE; }
  if (ref($condition)) { return $condition; }
  return $self->can ("_cond_$condition")
    || croak "No such condition $condition";
}

# 'database' condition means symbol must exist in database (as opposed to
# just being in a symlist to see a quote in the watchlists)
sub _cond_database {
  my ($self, $symlist, $symbol) = @_;
  require App::Chart::Database;
  return App::Chart::Database->symbol_exists ($symbol);
}

sub next {
  my ($self, $condition) = @_;
  $condition = _condition ($self, $condition);

  for (;;) {
    if (my $listpos = $self->{'symlist_listpos'}) {
      if (my $iter = $listpos->next_iter) {
        my $symlist = $listpos->model;
        my $symbol = $symlist->get_value ($iter, 0);
        $condition->($self, $symlist, $symbol) or next;
        return ($symbol, $symlist);
      }
    }

    ### prev list ...
    my $listpos = $self->{'lists_listpos'};
    my $iter = $listpos->next_iter || return;

    my $key = $lists->get_value ($iter, $lists->COL_KEY);
    ### $key
    my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
    $self->{'symlist_listpos'}
      = App::Chart::Gtk2::Ex::ListModelPos->new (model => $symlist,
                                     type => 'start');
  }
}

sub prev {
  my ($self, $condition) = @_;
  $condition = _condition ($self, $condition);

  for (;;) {
    if (my $listpos = $self->{'symlist_listpos'}) {
      if (my $iter = $listpos->prev_iter) {
        my $symlist = $listpos->model;
        my $symbol = $symlist->get_value ($iter, 0);
        $condition->($self, $symlist, $symbol) or next;
        return ($symbol, $symlist);
      }
    }

    my $listpos = $self->{'lists_listpos'};
    my $iter = $listpos->prev_iter || return;

    my $key = $lists->get_value ($iter, $lists->COL_KEY);
    my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
    $self->{'symlist_listpos'}
      = App::Chart::Gtk2::Ex::ListModelPos->new (model => $symlist,
                                     type => 'end');
  }
}

1;
__END__

=for stopwords Smarker symlist

=head1 NAME

App::Chart::Gtk2::Smarker -- ...

=head1 SYNOPSIS

 use App::Chart::Gtk2::Smarker;

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Smarker> object keeps track of a position within

=head1 FUNCTIONS

=over 4

=item C<< $smarker = App::Chart::Gtk2::Smarker->new (...) >>

Create and return an Smarker object.

=item C<< ($symlist, $symbol) = $smarker->next() >>

=item C<< ($symlist, $symbol) = $smarker->prev() >>

Move C<$smarker> to the next or previous symbol and return the
C<App::Chart::Gtk2::Symlist> object and the symbol string.  If there's no more
symbols in the respective direction then the return is an empty list C<()>.

=item C<< $smarker->goto ($symbol) >>

=item C<< $smarker->goto ($symbol, $symlist) >>

Move C<$smarker> to the given symbol, or symbol and symlist.

=back

=cut
