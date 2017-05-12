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

package App::Chart::Gtk2::Symlist::Join;
use 5.008;
use strict;
use warnings;
use Gtk2;

use App::Chart;

use Gtk2::Ex::ListModelConcat;
use Glib::Object::Subclass
  'Gtk2::Ex::ListModelConcat',

  properties => [ Glib::ParamSpec->string
                  ('key',
                   'key',
                   'The symlist database key.',
                   '',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('name',
                   'name',
                   'The symlist name.',
                   'Join ...', # default
                   Glib::G_PARAM_READWRITE) ];

use App::Chart::Gtk2::Symlist;
use base 'App::Chart::Gtk2::Symlist';


sub can_edit    { return 0; }
sub can_destroy { return 0; }

my $counter = 0;

sub new {
  my ($class, @symlists) = @_;
  my $self = Glib::Object::new ($class, models => \@symlists);
  $self->{'key'} = '_join_' . $counter++;
  return $self;
}


1;
__END__

=for stopwords symlists

=head1 NAME

App::Chart::Gtk2::Symlist::Join -- combine symlists

=head1 SYNOPSIS

 use App::Chart::Gtk2::Symlist::Join;
 my $symlist = App::Chart::Gtk2::Symlist::Join
     ('BHP.AX', App::Chart::Gtk2::Symlist->new_from_key('all'));

=head1 SEE ALSO

L<App::Chart::Gtk2::Symlist>

=cut
