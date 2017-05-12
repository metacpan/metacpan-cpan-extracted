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

package App::Chart::Gtk2::Symlist::Alphabetical;
use 5.010;
use strict;
use warnings;

use App::Chart::Gtk2::Symlist;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Symlist';

use constant DEBUG => 0;

# sub can_edit    { return 0; }
sub can_destroy { return 0; }

# override to always be alphabetical, no matter what $pos requested
sub insert_symbol_at_pos {
  my ($self, $symbol, $pos, $note) = @_;
  insert_symbol ($self, $symbol, $note);
}

sub insert_symbol {
  my ($self, $symbol, $note) = @_;
  if (DEBUG) { print "Alphabetical ",$self->{'key'},
                 " insert_symbol $symbol\n"; }

  my $hash = $self->hash;
  if (exists $hash->{$symbol}) {
    if (DEBUG >= 2) { print "  already in list\n"; }
    return;
  }

  my $found = 0;
  my $pos;
  $self->foreach (sub {
                    my ($self, $path, $iter) = @_;
                    my $this_symbol = $self->get_value($iter,0);
                    if (DEBUG) { print "  looking at ",$path->to_string,
                                   " $this_symbol\n";}
                    if ($this_symbol eq $symbol) {
                      # already in the list, do nothing
                      if (DEBUG) { print "  already in list\n"; }
                      $found = 1;
                      return 1; # stop iterating
                    }

                    if (App::Chart::symbol_cmp ($this_symbol, $symbol) > 0) {
                      if (DEBUG) { print "  stop '$this_symbol' gt new '$symbol'\n";}
                      ($pos) = $path->get_indices;
                      return 1; # stop iterating
                    }

                    return 0; # keep iterating
                  });
  if ($found) { return; }
  $pos //= $self->length;

  if (DEBUG) { print "  insert at $pos\n"; }
  $self->insert_with_values ($pos, 0=>$symbol, 1=>$note);
}

1;
__END__
