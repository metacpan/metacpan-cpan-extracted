# Copyright 2007, 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::Gtk2::Symlist::Alerts;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use App::Chart;

use App::Chart::Gtk2::Symlist::Alphabetical;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Symlist::Alphabetical';

sub name { return __('Alerts') }

sub instance {
  my ($class) = @_;
  return $class->new_from_key ('alerts');
}

sub interested_symbols {
  my ($self) = @_;
  ref $self or $self = $self->instance;

  # all current alerts list contents
  my @symbols = $self->symbols;

  # anything with an alert level and in the all list (so exclude historical
  # symbols, and symbols deleted from the database but user notes remaining)
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $aref = $dbh->selectcol_arrayref ('SELECT symbol FROM alert');
  require App::Chart::Gtk2::Symlist::All;
  my $all_hash = App::Chart::Gtk2::Symlist::All->instance->hash;
  push @symbols, grep {exists $all_hash->{$_}} @$aref;

  require List::MoreUtils;
  @symbols = List::MoreUtils::uniq (@symbols);

  @symbols = sort { App::Chart::symbol_cmp($a,$b) } @symbols;
  return @symbols;
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::Symlist::Alerts -- symbol list of Alerts

=head1 SYNOPSIS

 use App::Chart::Gtk2::Symlist::Alerts;
 my $symlist = App::Chart::Gtk2::Symlist::Alerts->instance;

=head1 FUNCTIONS

=over 4

=item C<< @symbols = $symlist->interested_symbols() >>

The "interested" symbols is everything with an alert level.

=back

=cut
