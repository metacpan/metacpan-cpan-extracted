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


package App::Chart::Gtk2::OpenModel;
use 5.010;
use strict;
use warnings;
use Gtk2 1.190; # for working TreeModelFilter modify_func
use Carp;

use App::Chart;
use App::Chart::Gtk2::Symlist;

use constant DEBUG => 0;

use App::Chart::Gtk2::Ex::ListOfListsModel;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Ex::ListOfListsModel';

use base 'Class::WeakSingleton';
*_new_instance = \&Glib::Object::new;

use constant {
  COL_SYMLIST_OBJECT => 0,
  COL_SYMLIST_NAME   => 1,
  COL_ITEM_SYMBOL    => 2 + App::Chart::Gtk2::Symlist->COL_SYMBOL,
};

sub INIT_INSTANCE {
  my ($self) = @_;

  require App::Chart::Gtk2::SymlistListModel;
  my $symlist_model = App::Chart::Gtk2::SymlistListModel->instance;

  require Gtk2::Ex::TreeModelFilter::Draggable;
  my $symlist_filter
    = Gtk2::Ex::TreeModelFilter::Draggable->new ($symlist_model);
  $symlist_filter->set_modify_func (['App::Chart::Gtk2::Symlist','Glib::String'],
                                    \&_symlist_filter_func);

  $self->set (list_model => $symlist_filter);
}

sub _symlist_filter_func {
  my ($symlist_filter, $iter, $col) = @_;
  if (DEBUG) { print "_symlist_filter_func iter=$iter col=$col\n";
               my $path = $symlist_filter->get_path ($iter);
               print "    path=", defined $path ? $path->to_string : 'undef',
                 "\n";
             }
  my $symlist_model = $symlist_filter->get_model;
  # my $subiter = $symlist_filter->convert_iter_to_child_iter ($iter);

  # avoid strange trouble with convert_iter ....
  my $path = $symlist_filter->get_path ($iter);
  my $subiter = $symlist_model->get_iter ($path) || return undef;

  if (DEBUG) { say "  submodel $symlist_model subiter $subiter";
               say "    iter_is_valid ",
                 $symlist_model->iter_is_valid($subiter)?"yes":"no";
               my $subpath = $symlist_model->get_path ($subiter);
               say "    subpath=",
                 (defined $subpath ? $subpath->to_string : 'undef');
             }

  if ($col == COL_SYMLIST_OBJECT) {
    my $key = $symlist_model->get_value ($subiter, $symlist_model->COL_KEY);
    if (DEBUG) { print "  key ",$key//'undef',"\n"; }
    return App::Chart::Gtk2::Symlist->new_from_key ($key);

  } elsif ($col == COL_SYMLIST_NAME) {
    return $symlist_model->get_value ($subiter, $symlist_model->COL_NAME);

  } else {
    return undef;
  }
}

sub path_for_key {
  my ($self, $key) = @_;
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
  return $self->path_for_model ($symlist);
}

sub path_for_symbol_and_symlist {
  my ($self, $symbol, $symlist) = @_;
  my $path = $self->path_for_model ($symlist) || return undef;
  my $sub_index = $symlist->find_symbol_pos ($symbol);
  if (! defined $sub_index) { return undef; }
  $path->append_index ($sub_index);
  return $path;
}


1;
__END__

=for stopwords watchlist symlist ie

=head1 NAME

App::Chart::Gtk2::OpenModel -- watchlist data model object

=for test_synopsis my ($symlist)

=head1 SYNOPSIS

 use App::Chart::Gtk2::OpenModel;
 my $model = App::Chart::Gtk2::OpenModel->new ($symlist);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::OpenModel> is a subclass of C<Gtk2::TreeModelFilter>,

    Glib::Object
      Gtk2::TreeModelFilter
        App::Chart::Gtk2::OpenModel

=head1 DESCRIPTION

A C<App::Chart::Gtk2::OpenModel> object presents the data from a given
C<App::Chart::Gtk2::Symlist> in a form suitable for C<App::Chart::Open> dialog.
Currently this is its sole use.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::OpenModel->new ($symlist) >>

Create and return a C<App::Chart::Gtk2::OpenModel> object presenting the
symbols in C<$symlist>.

=back

=head1 PROPERTIES

=over 4

=item C<symlist> (C<App::Chart::Gtk2::Symlist> object, read-only)

The symlist to track and get data from.  The intention is that this is
"construct-only", ie. to be set only when first constructing the model.  To
get a different symlist then create a new model.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::OpenDialog>

=cut
