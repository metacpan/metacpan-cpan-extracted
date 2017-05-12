# Copyright 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Chart is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see
# <http://www.gnu.org/licenses/>.


package App::Chart::Gtk2::Ex::CellView::TreeDND;
use 5.008;
use strict;
use warnings;
use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

sub drag_dest_append_target_list {
  my $widget = shift;
  $widget->set_target_list ($widget->get_target_list, @_);
}

sub drag_dest_init {
  my ($self) = @_;
  ### CellView-TreeDND drag_dest_init()

  $self->drag_dest_set(['highlight'], ['copy','move'],
                       { target => "text/plain",
                         flags  => [] },
                       { target => 'GTK_TREE_MODEL_ROW',
                         flags  => ['same-app'] });
}

sub drag_motion {
  my ($self, $context, $x, $y, $time) = @_;
  ### CellView-TreeDND drag_motion()

  my $path = $self->get_displayed_row || do {
    ### no path set
    return 0;
  };

  my $target = $self->drag_dest_find_target
    ($context, $self->drag_dest_get_target_list) || do {
      ### no matching target
      return 0;
    };

  if ($target->name eq 'GTK_TREE_MODEL_ROW') {
    ### target model row, request data
    $context->{'for_motion'} = 1;
    $self->drag_get_data ($context, $target, $time);
    return 1;
  }

  delete $context->{'for_motion'};
  $context->status ($context->suggested_action, $time);
  return 1;
}

sub drag_drop {
  my ($self, $context, $x, $y, $time) = @_;
  ### CellView-TreeDND drag_drop()
  delete $context->{'for_motion'};

  my $model = $self->get_model || do {
    ### no model to drop on
    return 0;
  };
  $model->isa('Gtk2::TreeDragDest') || do {
    ### model is not a TreeDragDest
    return 0;
  };
  my $path = $self->get_displayed_row  || do {
    ### no row displayed
    return 0;
  };

  my $target = $self->drag_dest_find_target
    ($context, $self->drag_dest_get_target_list);
  $self->drag_get_data ($context, $target, $time);
  return 1;
}

sub drag_data_received {
  my ($self, $context, $x, $y, $sel, $info, $time) = @_;
  ### CellView-TreeDND drag_data_received(): $context->{'for_motion'}

  my ($model, $path);
  my $good =  (($model = $self->get_model)
               && $model->isa('Gtk2::TreeDragDest')
               && ($path = $self->get_displayed_row));

  if ($context->{'for_motion'}) {
    $good &&= $model->row_drop_possible ($path, $sel);
    ### for motion good: $good
    $context->status (($good ? $context->suggested_action : 'default'), $time);
  } else {
    $good &&= $model->drag_data_received ($path, $sel);
    ### received good: $good
    $context->finish ($good, $good && ($context->action eq 'move'), $time);
  }
}

1;
__END__

=for stopwords CellView

=head1 NAME

App::Chart::Gtk2::Ex::CellView::TreeDND -- tree drag and drop mix-in for CellView subclasses

=head1 SYNOPSIS

 package MyNewCellView;
 use Gtk2;
 use App::Chart::Gtk2::Ex::CellView::TreeDND;

 use Glib::Object::Subclass
   'Gtk2::CellView',
   signals => { drag_drop => \&App::Chart::Gtk2::Ex::CellView::TreeDND::drag_drop,
                drag_data_received => \&App::Chart::Gtk2::Ex::CellView::TreeDND::drag_data_received };

=head1 DESCRIPTION

...

=head1 SEE ALSO

L<Gtk2::CellView>, L<Gtk2::TreeModel>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 COPYRIGHT

Copyright 2010 Kevin Ryde

Chart is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Chart is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Chart.  If not, see L<http://www.gnu.org/licenses/>.

=cut
