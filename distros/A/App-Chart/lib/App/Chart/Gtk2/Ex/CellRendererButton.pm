# not really working ???



# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::CellRendererButton;
use 5.006;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::CellRendererText',
  signals => { editing_started => \&_do_editing_started,
               clicked => { param_types => ['Glib::String'],
                            return_type => undef },
             };


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set (editable => 1);
}

# gtk_cell_renderer_start_editing()
#
sub START_EDITING {
  my ($self, $event, $view, $pathstr, $back_rect, $cell_rect, $flags) = @_;
  ### CellRendererButton START_EDITING: $pathstr
  $self->{'pathstr'} = $pathstr;
  return undef;
}

sub _do_editing_started {
  my ($self, $editable, $pathstr) = @_;
  ### CellRendererButton editing_started
  $self->signal_chain_from_overridden ($editable, $pathstr);
  $self->stop_editing (1);
  $self->signal_emit ('clicked', $self->{'pathstr'});
}

1;
__END__

=for stopwords renderer DateSpinner CellRendererButton Eg

=head1 NAME

App::Chart::Gtk2::Ex::CellRendererButton -- date cell renderer with DateSpinner for editing

=for test_synopsis my ($treeviewcolumn)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::CellRendererButton;
 my $renderer = App::Chart::Gtk2::Ex::CellRendererButton->new;

 $treeviewcolumn->pack_start ($renderer, 0);
 $treeviewcolumn->add_attribute ($renderer, text => 0);

 $renderer->signal_connect (clicked => sub { some_code() });

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::Ex::CellRendererButton> is a subclass of
C<Gtk2::CellRendererText>.

    Gtk2::Object
      Gtk2::CellRenderer
        Gtk2::CellRendererText
          App::Chart::Gtk2::Ex::CellRendererButton

=head1 DESCRIPTION

C<CellRendererButton> ...

=head1 FUNCTIONS

=over 4

=item C<< $renderer = App::Chart::Gtk2::Ex::CellRendererButton->new (key=>value,...) >>

Create and return a new CellRendererButton object.  Optional key/value pairs
set initial properties as per C<< Glib::Object->new >>.  Eg.

    my $renderer = App::Chart::Gtk2::Ex::CellRendererButton->new;

=back

=head1 SEE ALSO

L<Gtk2::CellRenderer>

=cut
