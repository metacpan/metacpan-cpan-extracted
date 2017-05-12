# --8<--8<--8<--8<--
#
# Copyright (C) 2007 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::NED::Query
#
# Astro::NED::Query is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Astro::NED::Response::Objects;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.30';

use Astro::NED::Response::Fields;
use Astro::NED::Response::Object;


#---------------------------------------------------------------------------

sub new
{
  my $class = shift;
  $class = ref $class || $class;

  my $self = {
	      curr_object => -1,
	      objects => [],
	     };
  bless $self, $class;

  return $self;
}

#---------------------------------------------------------------------------

sub objects {
    my ( $self ) = @_;

    return @{$self->{objects}};
 }

sub nobjects {
    my ( $self ) = @_;

    return scalar @{$self->{objects}};
}

sub addobject
{
  my ( $self, @objects )  = @_;

  croak( __PACKAGE__, '->addobject: object is not of type Astro::NED::Response::Object' )
    if grep { ! $_->isa( 'Astro::NED::Response::Object' ) } @objects;

  push @{$self->{objects}}, @objects;

  return $self->nobjects;
}


#---------------------------------------------------------------------------


sub parseHTML
{
  require HTML::LinkExtor;
  require HTML::TableParser;

  my $self = shift;

  # don't do this, as we don't want to copy the passed data.
  # my $html = shift;

  # first get list of links
  my $p = HTML::LinkExtor->new;
  $p->parse( $_[0]);

  ## no critic (AccessOfPrivateData)
  # HTML::LinkExtor returns a list of arrayrefs, not objects.
  my @links = grep { /search_type=Obj_id/i } map { $_->[2] } $p->links ;
  ## use critic

  my @cols;
  my @colnames;

  # HTML::Parser does its own funky handling of exceptions, which causes
  # exceptions in handlers to be printed and then rethrown. work around
  # that by keeping track of our exceptions excplicily and by using
  # $p->eof;
  my $error;

  $p = HTML::TableParser->new(
     [{
       cols => qr/Object Type/,
       DecodeNBSP => 1,

       hdr => sub {

         my %used;
	 for my $colname ( @{$_[2]} )
	 {
	   ## no critic (AccessOfPrivateData)
	   # @Fields is a list of arrayrefs, not objects.
	   my @matches = Astro::NED::Response::Fields::match( $colname );
	   ## use critic

           # A table column can't match more than one field, unless
           # it's the Row No. column, which is in there twice.
	   if ( 1 == @matches )
	   {
               my $match = $matches[0];
               ## no critic (AccessOfPrivateData)
               my $name = $match->{name};
               ## use critic

               if ( exists $used{$name} && $name ne 'No' )
               {
                   $error =  "internal error; matched $match->{name} to more than one column in NED table: " .
                     "$used{$name}, $colname \n";
                   $p->eof;
               }

               $used{$name} = $colname;
               push @colnames, $name;
           }
           else
           {
               if ( 0 == @matches )
               {
                   $error = "internal error: could not recognize column '$colname' in NED table\n";
                   $p->eof;
               }
               else
               {
                   ## no critic (AccessOfPrivateData)
                   $error = "internal error: multiple matches for column '$colname' in NED table: " . 
                                join (", ", map { $_->{name} } @matches ) . "\n";
                   $p->eof;
                   ## use critic
               }

	   }

	 }
       },

       row => sub {
	 my %data;
	 @data{@colnames} = map { $_ eq '' || $_ eq '...' ? undef : $_ } @{$_[2]};
	 $data{InfoLink} = shift @links;
	 $data{Name} =~ s/^[*]//;

         my $object = Astro::NED::Response::Object->new( \%data );

         eval {
             Astro::NED::Response::Fields::check( \%data );
         };

         if ( $@ )
         {
             $error = "error parsing NED output: $@" . "for object:\n" . $object->dumpstr("\t");
             $@ = '';
             $p->eof;
         }

	 push @{$self->{objects}}, $object;
       },

       Trim => 1,
      }]
  );

  eval { $p->parse( $_[0] ) };
  if ( $@ || $error )
  {
      $error .= $@;
      Carp::croak( __PACKAGE__, ': ', $error );
  }

  return;
}

#---------------------------------------------------------------------------


1;
__END__

=head1 NAME

Astro::NED::Response::Objects - a container for NED Object query objects 

=head1 SYNOPSIS

  use Astro::NED::Response::Objects;

  # create an empty container.
  my $objs = Astro::NED::Response::Objects->new();

  # add an object of type Astro::NED::Response::Object
  $objs->addobject( $obj );

  # parse a NED object query and add the objects to the container
  $objs->parseHTML( $html );

  # get the number of objects
  my $nobj = $objs->nobjects;

  # get the objects as a list
  my @objs = $objs->objects;

=head1 DESCRIPTION

This class implements a container for Astronomical objects returned by
an B<Astro::NED::Query::Objects> query.  The objects are stored as
B<Astro::NED::Response::Object> objects.

The most useful methods for the general user are the B<nobjects> and
B<objects> methods.

=head2 Object Methods

=over

=item new

  $objs = Astro::NED::Response::Objects->new();

creates an empty container

=item parseHTML

  $objs->parseHTML( $html );

parse the HTML response from a NED "Objects" query and add the objects
to the container.

=item addobject

  $objs->addobject( $obj );

add an object of type B<Astro::NED::Response::Object>.

=item nobjects

  $nobjs = $objs->nobjects;

returns the number of objects in the container

=item objects

  @objects = $objs->objects;

returns the objects as a Perl list.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (C) 2003 Smithsonian Astrophysical Observatory.
All rights are of course reserved.

It is released under the GNU General Public License.  You may find a
copy at

   http://www.fsf.org/copyleft/gpl.html

=head1 SEE ALSO

L<Astro::NED::Response::Object>,
L<Astro::NED::Query::Objects>,
L<perl>.

=cut
