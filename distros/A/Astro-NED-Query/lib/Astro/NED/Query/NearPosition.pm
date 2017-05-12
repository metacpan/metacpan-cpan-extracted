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

package Astro::NED::Query::NearPosition;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.30';

use base qw/ Astro::NED::Query::Objects Class::Accessor::Class /;

__PACKAGE__->mk_class_accessors( qw( Field ) );

__PACKAGE__->Field( { qw{
                         InCoordSys     in_csys
                         InEquinox      in_equinox
                         Longitude      lon
                         Latitude       lat
                         RA             lon
                         Dec            lat
                         Radius         radius
                         OutCoordSys    out_csys
                         OutEquinox     out_equinox
                         Sort           obj_sort
                         Format         of
                         ZVBreaker      zv_breaker
                         ListLimit      list_limit
                         ImageStamp     img_stamp
                         ZConstraint    z_constraint
                         ZValue1        z_value1
                         ZValue2        z_value2
                         ZUnit          z_unit
                         ObjTypeInclude ot_include
                         NamePrefixOp   nmp_op
                     }  });

__PACKAGE__->mk_accessors( keys %{__PACKAGE__->Field},
                         );

__PACKAGE__->_mkMultipleAccessor ( qw/ IncObjType ExcObjType NamePrefix / );

sub _init
{
    my ( $self ) = @_;

    $self->{_ua}->follow_link( text_regex => qr/near position/i );
    $self->_setupMultiple( 'option', IncObjType => qr/^in_objtypes\d+$/ );
    $self->_setupMultiple( 'option', ExcObjType => qr/^ex_objtypes\d+$/ );
    $self->_setupMultiple( 'option', NamePrefix => qr/^name_prefix\d+$/ );

    return;
}

1;
__END__

=head1 NAME

Astro::NED::Query::NearPosition - query NED for objects near a specified position

=head1 SYNOPSIS

  use Astro::NED::Query::NearPosition;

  $req = Astro::NED::Query::NearPosition->new( Field => value, ... );

  $req->Field( $value );

  # for fields which take multiple values
  $req->Field( $value1 => $state );
  $req->Field( $value2 => $state );

  $objs = $req->query;

=head1 DESCRIPTION

This class queries NED using the "Objects Near Position" interface.  It is
a subclass of B<Astro::NED::Query>, and thus shares all of its
methods.

Class specific details are provided here.  See L<Astro::NED::Query>
for general information on the class methods (including those not
documented here) and how to set or get the search parameters.

=head2 Methods

=over

=item new

  $req = Astro::NED::Query::NearPosition->new( keyword1 => $value1,
                                   keyword2 => $value2, ... );

Queries are constructed using the B<new> method, which is passed a
list of keyword and value pairs.  The keywords may be the names of
single valued query parameters.

Fields which may have mutiple concurrent values (such as
B<IncObjType>) cannot be specified in the call to B<new>; use the
field accessor method, and specify the value and whether it should be
selected or not:

  $req->IncObjType( 'Galaxies' => 1 )
  $req->IncObjType( 'XRay' => 1 )

Search parameters may also be set or queried using the accessor methods;
see L<Astro::NED::Query>.

=item query

  $res = $req->query;

The B<query> method returns an instance of the
B<Astro::NED::Response::Objects> class, which contains the results of
the query.  At present it returns I<only> the summary table, not the
detailed information on each object.  See
L<Astro::NED::Response::Object> for more info.

If an error ocurred an exception is thrown via B<croak>.

=back

=head2 Search Parameters

Please note that for fields which take specific enumerated values, the
values are often I<not> those which are displayed by a web browser.
It's best to initially use the B<possible_values> method to determine
acceptable values.  Usually it's pretty obvious what they correspond
to.

=over 8

=item InCoordSys

The input coordinate system.  Use the B<possible_values> method
to determine which ones are available.

=item InEquinox

The input coordinate system equinox.

=item Longitude

The longitude of the search position, if applicable.
(Internally this is the same as the B<RA> field.)

=item Latitude

The latitude of the search position, if applicable.
(Internally this is the same as the B<Dec> field.)

=item RA

The Right Ascension of the search position, if applicable.
(Internally this is the same as the B<Longitude> field.)

=item Dec

The Declination of the search position, if applicable.
(Internally this is the same as the B<Latitude> field.)

=item Radius

The search radius in arcminutes

=item OutCoordSys

The output coordinate system.  Use the B<possible_values> method
to determine which ones are available.

=item OutEquinox

The output coordinate system equinox.

=item Sort

The output sort order.   Use the B<possible_values> method
to determine which ones are available.

=item Format

Whether the output is formatted as an HTML table or plain text.
This will always be forced to HTML.

=item ListLimit

The upper limit to the number of objects with detailed information.
This is always set to force no detailed information

=item ZVBreaker

The maximum redshift velocity which will be displayed as km/s.

=item ImageStamp

Whether or not to return an image preview.  Always forced off.

=item ZConstraint

Constraints on the redshifts of the objects.  Used in conjunction
with the B<ZValue1> and B<ZValue2> fields.

Use the B<possible_values> method to determine which constraints are
available.

=item ZValue1, ZValue2

Values for the redshift constraints.

=item ZUnit

Either C<km/s> or C<z>.

=item ObjTypeInclude

Whether to objects must have C<ANY> or C<ALL> of the types in
the B<IncObjType> field.  Takes the values C<ANY> or C<ALL>.

=item IncObjType

This specifies the types of objects to include.  This is a multi-valued
field, meaning that it can hold more than one type of object concurrently.
As such, it cannot be initialized in the object constructor.  The
accessor method must be used instead:

  $obj->IncObjType( Galaxies => 1 );
  $obj->IncObjType( GPairs => 1 );

Use the B<possible_values> method to determine which object types are
available.

=item ExcObjType

This specifies the types of objects to exclude.  This is a multi-valued
field, meaning that it can hold more than one type of object concurrently.
As such, it cannot be initialized in the object constructor.  The
accessor method must be used instead:

  $obj->ExcObjType( Galaxies => 1 );
  $obj->ExcObjType( GPairs => 1 );

Use the B<possible_values> method to determine which object types are
available.

=item NamePrefixOp

This specifies how to handle objects with name prefixes specified with
the B<NamePrefix> field.  This is so complicated there's an extra
documentation link on the NED site, so I suggest you look there:
L<http://nedwww.ipac.caltech.edu/help/object_help.html#exclcat>.

Use the B<possible_values> method to determine which object types are
available.

=item NamePrefix

This specifies the types of name prefix used with B<NamePrefixOp>.
This is a multi-valued field, meaning that it can hold more than one
type of object concurrently.  As such, it cannot be initialized in the
object constructor.  The accessor method must be used instead:

  $obj->NamePrefix( ABELL => 1 );
  $obj->NamePrefix( 'ABELL S' => 1 );

Use the B<possible_values> method to determine which prefixes are
available.

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

L<Astro::NED::Query>,
L<Astro::NED::Response::Objects>,
L<Astro::NED::Response::Object>,
L<perl>.

=cut
