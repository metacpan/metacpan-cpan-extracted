# Copyright 2007, 2008, 2009, 2010, 2011, 2015 Kevin Ryde

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


package App::Chart::Gtk2::WatchlistModel;
use 5.008;
use strict;
use warnings;
use Gtk2 1.190; # for working TreeModelFilter modify_func
use Carp;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::Symlist;

# uncomment this to run the ### lines
#use Devel::Comments;

use Gtk2::Ex::TreeModelFilter::Draggable;
use base 'Gtk2::Ex::TreeModelFilter::Change';
use Glib::Object::Subclass
  'Gtk2::Ex::TreeModelFilter::Draggable',
  properties => [ Glib::ParamSpec->object
                  ('symlist',
                   'symlist',
                   'The symlist to present.',
                   'App::Chart::Gtk2::Symlist',
                   ['readable']) ];

use constant { COL_SYMBOL   => 0,
               COL_BIDOFFER => 1,
               COL_LAST     => 2,
               COL_CHANGE   => 3,
               COL_HIGH     => 4,
               COL_LOW      => 5,
               COL_VOLUME   => 6,
               COL_WHEN     => 7,
               COL_NOTE     => 8,
               COL_COLOUR   => 9,
               COL_TOOLTIP  => 10,
               NUM_COLUMNS  => 11
             };

my $empty_symlist;
sub new {
  my ($class, $symlist) = @_;
  if (! defined $symlist) {
    require App::Chart::Gtk2::Symlist::Constructed;
    $symlist = ($empty_symlist ||= App::Chart::Gtk2::Symlist::Constructed->new);
  }

  my $self = $class->Gtk2::Ex::TreeModelFilter::Draggable::new ($symlist);
  $self->{'symlist'} = $symlist;
  $self->set_modify_func ([('Glib::String') x NUM_COLUMNS],
                          \&_model_filter_func);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('latest-changed', \&_do_latest_changed, $self);
  return $self;
}

# 'latest-changed' from DirBroadcast
sub _do_latest_changed {
  my ($self, $symbol_hash) = @_;
  ### WatchlistModel _do_latest_changed(): join(' ',keys %$symbol_hash)

  my $symlist = $self->{'symlist'};

  my $h = $symlist->hash;
  foreach my $symbol (keys %$symbol_hash) {
    if (exists $h->{$symbol}) {
      my $index = $h->{$symbol};
      my $path = Gtk2::TreePath->new_from_indices ($index);
      my $iter = $symlist->iter_nth_child (undef, $index)
        || next;  # oops, something not up-to-date
      $self->row_changed ($path, $iter);
    }
  }

  # much slower:
  #
  #   $symlist->foreach
  #     (sub {
  #        my ($self, $path, $iter) = @_;
  #        my $symbol = $self->get_value($iter,0);
  #        if (exists $symbol_hash->{$symbol}) {
  #          if (DEBUG >= 2) { print "WatchlistModel: changed $symbol ",
  #                              $path->to_string,"\n"; }
  #          $self->row_changed ($path, $iter);
  #        }
  #        return 0; # keep iterating
  #      });

  ### WatchlistModel _do_latest_changed() end ...
}

sub _model_filter_func {
  my ($self, $iter, $col) = @_;
  my $child_model = $self->get_model;
  my $child_iter = $self->convert_iter_to_child_iter ($iter);
  my $symbol = $child_model->get_value ($child_iter, 0);

  if ($col == COL_SYMBOL) {
    return $symbol;
  }
  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);

  my $cache = ($latest->{(__PACKAGE__)} ||= []);
  if (exists $cache->[$col]) { return $cache->[$col]; }
  my $str;

  if ($col == COL_BIDOFFER) {
    my $bid = $latest->{'bid'};
    my $offer = $latest->{'offer'};
    if (defined $bid || defined $offer) {
      $str = (defined $bid ? format_price($bid) : '--')
        . (defined $bid && defined $offer && $bid > $offer ? 'x' : '/')
          . (defined $offer ? format_price($offer) : '--');
    }

  } elsif ($col == COL_LAST) {
    $str = format_price ($latest->{'last'});

  } elsif ($col == COL_CHANGE) {
    $str = format_price ($latest->{'change'});

  } elsif ($col == COL_HIGH) {
    $str = format_price ($latest->{'high'});

  } elsif ($col == COL_LOW) {
    $str = format_price ($latest->{'low'});

  } elsif ($col == COL_VOLUME) {
    $str = $latest->formatted_volume;

  } elsif ($col == COL_WHEN) {
    $str = $latest->short_datetime;

  } elsif ($col == COL_NOTE) {
    my @notes = ();
    my $dividend = $latest->{'dividend'};
    if (defined $dividend) {
      push @notes, __x('ex {dividend}', dividend => $dividend);
    }
    if ($latest->{'halt'}) { push @notes, __('halt'); }
    if ($latest->{'limit_up'}) { push @notes, __('limit up'); }
    if ($latest->{'limit_down'}) { push @notes, __('limit down'); }
    if (my $note = $latest->{'note'}) { push @notes, $note; }
    if (my $error = $latest->{'error'}) { push @notes, $error; }
    $str = join (', ', @notes);

  } elsif ($col == COL_COLOUR) {
    require App::Chart::Gtk2::Job::Latest;
    if ($App::Chart::Gtk2::Job::Latest::inprogress{$symbol}) {
      $str = '#00007F';
    } else {
      my $change = $latest->{'change'};
      if (defined $change) {
        if ($change > 0) { $str = '#007F00'; }
        elsif ($change < 0) { $str = '#7F0000'; }
      }
    }

  } elsif ($col == COL_TOOLTIP) {
    $str = $symbol;
    require App::Chart::Database;
    if (my $name = ($latest->{'name'}
                    || App::Chart::Database->symbol_name ($symbol))) {
      $str .= ' - ' . $name;
    }
    $str .= "\n";

    if (my $quote_date = $latest->{'quote_date'}) {
      my $quote_time = $latest->{'quote_time'} || '';
      $str .= __x("Quote: {quote_date} {quote_time}",
                  quote_date => $quote_date,
                  quote_time => $quote_time);
      $str .= "\n";
    }

    if (my $last_date = $latest->{'last_date'}) {
      my $last_time = $latest->{'last_time'} || '';
      $str .= __x("Last:  {last_date} {last_time}",
                  last_date => $last_date,
                  last_time => $last_time);
      $str .= "\n";
    }

    require App::Chart::TZ;
    my $timezone = App::Chart::TZ->for_symbol($symbol);
    $str .= __x("{location} time; source {source}",
                location => $timezone->name,
                source   => $latest->{'source'});
    # tip is markup format, though that's not actually documented as of 2.12
    $str = Glib::Markup::escape_text ($str);
  }

  return ($cache->[$col] = $str);
}

sub format_price {
  my ($str) = @_;
  if (! defined $str) { return ''; }
  my $nf = App::Chart::number_formatter();
  return eval { $nf->format_number ($str, App::Chart::count_decimals($str), 1) }
    // __('[bad]');
}

sub get_symlist {
  my ($self) = @_;
  return $self->get_model;
}

1;
__END__

=for stopwords watchlist symlist ie

=head1 NAME

App::Chart::Gtk2::WatchlistModel -- watchlist data model object

=for test_synopsis my ($symlist)

=head1 SYNOPSIS

 use App::Chart::Gtk2::WatchlistModel;
 my $model = App::Chart::Gtk2::WatchlistModel->new ($symlist);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::WatchlistModel> is a subclass of C<Gtk2::TreeModelFilter>,

    Glib::Object
      Gtk2::TreeModelFilter
        App::Chart::Gtk2::WatchlistModel

=head1 DESCRIPTION

A C<App::Chart::Gtk2::WatchlistModel> object presents the data from a given
C<App::Chart::Gtk2::Symlist> in a form suitable for
C<App::Chart::Gtk2::WatchlistDialog> dialog.  Currently this is its sole
use.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::WatchlistModel->new ($symlist) >>

Create and return a C<App::Chart::Gtk2::WatchlistModel> object presenting the
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

L<App::Chart::Gtk2::WatchlistDialog>

=cut
