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

package App::Chart::Gtk2::Symlist::Constructed;
use 5.010;
use strict;
use warnings;

use App::Chart::Gtk2::Symlist;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Symlist';

my $keynum = 0;

sub new  {
  my ($class, @symbols) = @_;
  my $self = $class->SUPER::new (key => "_constructed_$keynum");

  local $self->{'reading_database'} = 1;
  my $pos = 0;
  foreach my $symbol (@symbols) {
    $self->insert_with_values ($pos++, 0 => $symbol);
  }
  return $self;
}

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub can_edit    { return 0; }
sub can_destroy { return 0; }

sub _reread {
}

# sub name {
#   my ($self) = @_;
#   return $self->{'name'} || $self->SUPER::name;
# }
# sub symbol_list {
#   my ($self) = @_;
#   return $self->{'symbol_list'};
# }

1;
__END__
