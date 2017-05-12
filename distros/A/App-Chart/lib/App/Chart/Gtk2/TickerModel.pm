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


package App::Chart::Gtk2::TickerModel;
use 5.010;
use strict;
use warnings;
use Gtk2 1.200; # for working TreeModelFilter modify_func
use Carp;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::TreeModelFilter::Draggable;
use App::Chart;


use Glib::Object::Subclass
  'Gtk2::Ex::TreeModelFilter::Draggable';

use constant { UP_SPAN => '<span foreground="green">',

               # a brightish red, for contrast against a black background
               DOWN_SPAN => '<span foreground="#FF7070">',

               INPROGRESS_SPAN => '<span foreground="light blue">' };

sub new {
  my ($class, $symlist) = @_;

  # FIXME: As of Gtk2-Perl 1.201 Gtk2::TreeModelFilter::new() leaks a
  # reference (its returned object is never destroyed), so go through
  # Glib::Object::new() instead.  Can switch to SUPER::new when ready to
  # depend on a fixed Gtk2-Perl.
  #
  my $self = Glib::Object::new ($class, child_model => $symlist);

  $self->{'symlist'} = $symlist;
  $self->set_modify_func ([ 'Glib::String' ], \&_model_filter_func);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('latest-changed', \&_do_latest_changed, $self);
  return $self;
}

# 'latest-changed' from DirBroadcast
sub _do_latest_changed {
  my ($self, $changed) = @_;
  ### Ticker: latest-changed: keys %$changed

  my $symlist = $self->{'symlist'};
  $symlist->foreach (sub {
                       my ($self, $path, $iter) = @_;
                       my $symbol = $self->get_value($iter,0);
                       if (exists $changed->{$symbol}) {
                         ### Ticker: changed: $symbol, $path->to_string
                         $self->row_changed ($path, $iter);
                       }
                       return 0; # keep iterating
                     });
}

sub _model_filter_func {
  my ($self, $iter, $col) = @_;

  my $child_model = $self->get_model;
  my $child_iter = $self->convert_iter_to_child_iter ($iter);
  my $symbol = $child_model->get_value ($child_iter, 0);

  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);
  return _form ($self, $latest);
}

# return a pango markup string to display for $latest
sub _form {
  my ($self, $latest) = @_;

  return ($latest->{__PACKAGE__.'.form'} ||= do {
    my $symbol = $latest->{'symbol'};
    my $last = $latest->{'last'}
      // return $symbol . ' ' . ($latest->{'note'} || __('no data'));
    my $nf = App::Chart::number_formatter();
    my $str = $symbol . ' '
      . $nf->format_number ($last, App::Chart::count_decimals($last), 1);

    my $change = $latest->{'change'};
    if ($latest->{'halt'})          { $str .= ' '.__('halt'); }
    elsif ($latest->{'limit_up'})   { $str .= ' '.__('limit up'); }
    elsif ($latest->{'limit_down'}) { $str .= ' '.__('limit down'); }
    elsif (! defined $change)       { }  # nothing added for undef
    elsif ($change == 0)            { $str .= ' '.__('unch'); }
    else {
      $str .= ' ' . ($change > 0 ? '+' : '')
        . $nf->format_number ($change,App::Chart::count_decimals($change), 1);
    }

    my $span;
    if ($App::Chart::Gtk2::Job::Latest::inprogress{$symbol}) {
      $span = INPROGRESS_SPAN;
    } elsif ($latest->{'inprogress'}) {
      $span = INPROGRESS_SPAN;
    } elsif (defined $change && $change>0) {
      $span = UP_SPAN;
    } elsif (defined $change && $change<0) {
      $span = DOWN_SPAN;
    }
    if ($span) {
      $str = $span . $str . '</span>';
    }
    $str;
  });
}

1;
__END__

=for stopwords symlist ie

=head1 NAME

App::Chart::Gtk2::TickerModel -- ticker display data model object

=for test_synopsis my ($symlist)

=head1 SYNOPSIS

 use App::Chart::Gtk2::TickerModel;
 my $model = App::Chart::Gtk2::TickerModel->new ($symlist);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::TickerModel> is a subclass of C<Gtk2::TreeModelFilter>,

    Glib::Object
      Gtk2::TreeModelFilter
        App::Chart::Gtk2::TickerModel

=head1 DESCRIPTION

A C<App::Chart::Gtk2::TickerModel> object presents the data from a given
C<App::Chart::Gtk2::Symlist> in a form suitable for the C<App::Chart::Gtk2::Ticker>
widget.  Currently this is its sole use.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::TickerModel->new ($symlist) >>

Create and return a C<App::Chart::Gtk2::TickerModel> object presenting the
symbols in C<$symlist>.

=back

=head1 PROPERTIES

=over 4

=item C<symlist> (C<App::Chart::Gtk2::Symlist> object, read-only)

The symlist to track and get data from.  The intention is that this is
"construct-only", ie. to be set only when first constructing the model.  To
present a different symlist create a new model.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Ticker>

=cut
