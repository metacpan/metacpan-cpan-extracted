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


package App::Chart::Gtk2::Symlist::Glob;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Carp;

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;

use constant DEBUG => 0;

use Gtk2::Ex::TreeModelFilter::Draggable;
use Glib::Object::Subclass
  'Gtk2::Ex::TreeModelFilter::Draggable',
  properties => [Glib::ParamSpec->string
                 ('pattern',
                  'pattern',
                  '',
                  'Glob style pattern of symbols.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('key',
                  'key',
                  'The symlist database key.',
                  '',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('name',
                  'name',
                  'The symlist name.',
                  '', # default
                  Glib::G_PARAM_READWRITE) ];

use App::Chart::Gtk2::Symlist;
use base 'App::Chart::Gtk2::Symlist';

sub can_edit    { return 0; }
sub can_destroy { return 0; }

sub new {
  my ($class, $symlist, $pattern) = @_;
  return $class->Glib::Object::new (child_model => $symlist,
                                    pattern => $pattern);
}

my $counter = 0;

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'key'} = '_glob_' . $counter++;
  $self->{'regexp'} = qr//;
  $self->set_visible_func (\&_visible_func,
                           App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;

  if ($pname eq 'pattern') {
    require Text::Glob;
    $self->{'name'} = $newval;
    $self->{'regexp'} = Text::Glob::glob_to_regex ($newval);
    if (DEBUG) { print "regexp ",$self->{'regexp'},"\n"; }
    $self->refilter;
  }
}

sub _visible_func {
  my ($child_model, $child_iter, $ref_weak_self) = @_;
  if (DEBUG) { print "test ",$child_model->get_value($child_iter,0),"\n"; }
  my $self = $$ref_weak_self || return;
  return ($child_model->get_value($child_iter,0) =~ $self->{'regexp'});
}

1;
__END__

=for stopwords symlist globbed

=head1 NAME

App::Chart::Gtk2::Symlist::Glob -- pattern match symlist

=for test_synopsis my ($parentlist)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Symlist::Glob;
 my $symlist = App::Chart::Gtk2::Symlist::Glob->new ($parentlist, '*.NZ');

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Symlist::Glob> is a subclass of
C<Gtk2::Ex::TreeModelFilter::Draggable>,

    Glib::Object
      Gtk2::TreeModelFilter
        Gtk2::Ex::TreeModelFilter::Draggable
          App::Chart::Gtk2::Symlist::Glob

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Symlist::Glob> object filters a given child symlist according
to a glob style pattern like "C<*.NZ>".  The globbed list updates with the
child symlist, but is otherwise read-only and exists only in the current
process (it doesn't go into the database).

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Symlist::Glob->new ($child_symlist, $pattern) >>

Create and return a C<App::Chart::Gtk2::Symlist::Glob> which is C<$parent_symlist>
filtered by C<$pattern>.

=back

=head1 PROPERTIES

=over 4

=item C<pattern> (string)

A glob style pattern like "C<*.NZ>".

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Symlist>

=cut
