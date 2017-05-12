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

package Astro::NED::Query::ByName;

use 5.006;
use strict;
use warnings;

use base qw/ Astro::NED::Query::Objects Class::Accessor::Class /;

our $VERSION = '0.30';

__PACKAGE__->mk_class_accessors( qw( Field ) );

__PACKAGE__->Field( { qw{
                         ObjName        objname
                         Extend         extend
                         CoordSys       out_csys
                         Equinox        out_equinox
                         Sort           obj_sort
                         Format         of
                         ListLimit      list_limit
                         ZVBreaker      zv_breaker
                         ImageStamp     img_stamp
                     } } );

__PACKAGE__->mk_accessors( keys %{__PACKAGE__->Field},
                         );

sub _init
{
    my ( $self ) = @_;

    $self->{_ua}->follow_link( text_regex => qr/by name/i );

    return;
}

1;
__END__


=head1 NAME

Astro::NED::Query::ByName - query NED by object name

=head1 SYNOPSIS

  use Astro::NED::Query::ByName;

  $req = Astro::NED::Query::ByName->new( Field => $value, ... );

  $req->Field( $value );

  $objs = $req->query;

=head1 DESCRIPTION

This class queries NED using the "Objects By Name" interface.  It
is a subclass of B<Astro::NED::Query>, and thus shares all of its
methods.

Class specific details are provided here.  See L<Astro::NED::Query>
for general information on the class methods (including those not
documented here) and how to set or get the search parameters.

=head2 Methods

=over

=item new

  $req = Astro::NED::Query::ByName->new( keyword1 => $value1,
                                 keyword2 => $value2, ... );

Queries are constructed using the B<new> method, which is passed a
list of keyword and value pairs.  The keywords may be the names of
single valued query parameters.

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

The class accessor methods have the same names as the search parameters.
See L<Astro::NED::Query> on how to use them.

=over 8

=item ObjName

The object name.

=item Extend

Whether to perform an extended search.  Possible values are C<yes> and
C<no>.

=item CoordSys

The output coordinate system.  Use the B<possible_values> method
to determine which ones are available.

=item Equinox

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
