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

package App::Chart::Gtk2::Heading;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::GUI;

# uncomment this to run the ### lines
#use Devel::Comments;


use Glib::Object::Subclass
  'Gtk2::EventBox',
  properties => [Glib::ParamSpec->scalar
                 ('series-list',
                  'series-list',
                  'Arrayref of App::Chart::Gtk2::Symlist objects',
                  Glib::G_PARAM_READWRITE)
                ];
App::Chart::Gtk2::GUI::chart_style_class (__PACKAGE__);
Gtk2::Rc->parse_string (<<'HERE');
widget_class "*.<App__Chart__Gtk2__Heading>.*.GtkLabel" style:application "Chart_style"
HERE

sub INIT_INSTANCE {
  my ($self) = @_;
  my $hbox = Gtk2::HBox->new (0,0);
  $self->add ($hbox);

  my $left = $self->{'left'} = Gtk2::Label->new ('left');
  $left->set (xalign => 0);
  $hbox->pack_start ($left, 0,0,0);

  my $right = $self->{'right'} = Gtk2::Label->new ('right');
  $right->set (xalign => 1);
  $hbox->pack_end ($right, 0,0,0);

  $hbox->show_all;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY
  ### Heading SET_PROPERTY(): "$self   $pname   $newval"

  if ($pname eq 'series_list') {
    my $series_list = $newval;
    ### series_list length: scalar(@$series_list)
    my $series = $series_list->[0];
    my $left = '';
    my $right = '';
    if ($series) {
      ### series for text: "$series"
      $left = ($series_list->[1] || $series)->name;
      # FIXME: Show "- Log" for logarithmic?

      if ($series->can('symbol_name')) {
        $right = $series->symbol_name // '';
      }

      # FIXME: do something in the Timebase classes for an strftime format
      # string, maybe make it configurable
      my $timebase = $series->timebase;
      my $to_date;
      # FIXME: use download-done date here
      my $hi = $series->hi;
      if ($timebase->isa('App::Chart::Timebase::Weeks')) {
        # ENHANCE-ME: the date shown is the start of the week, is that ok?
        $to_date = $timebase->strftime ($App::Chart::option{'d_fmt'},
                                        $hi);
        $to_date = __x('to week {date}', date => $to_date);
      } elsif ($timebase->isa('App::Chart::Timebase::Months')
               || $timebase->isa('App::Chart::Timebase::Quarters')) {
        $to_date = $timebase->strftime (__('to %b %Y'), $hi);
      } elsif ($timebase->isa('App::Chart::Timebase::Years')) {
        $to_date = $timebase->strftime (__('to %Y'), $hi);
      } elsif ($timebase->isa('App::Chart::Timebase::Decades')) {
        $to_date = $timebase->strftime (__('to decade %Y'), $hi);
      } else {
        $to_date = $timebase->strftime ($App::Chart::option{'wd_fmt'},
                                        $hi);
        $to_date = __x('to {date}', date => $to_date);
      }
      $right = join ('    ', $right//'', $to_date . '  ');
    }
    ### $left
    ### $right
    $self->{'left'}->set_text ($left);
    $self->{'right'}->set_text ($right);
  }
}

1;
__END__

=for stopwords superclass arrayref undef

=head1 NAME

App::Chart::Gtk2::Heading -- view heading display widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::Heading;
 my $hscale = App::Chart::Gtk2::Heading->new();

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::Heading> is a subclass of C<Gtk2::EventBox>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::EventBox
            App::Chart::Gtk2::Heading

The superclass is only C<Gtk2::EventBox> to get a container with its own
window, and that might change.

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Heading> widget displays ...

=head1 PROPERTIES

=over 4

=item C<series-list> (arrayref of C<App::Chart::Series> objects, default undef)

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::View>, L<App::Chart::Series>

=cut
