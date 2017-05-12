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

package Astro::NED::Query::CoordExtinct;

use 5.006;
use strict;
use warnings;

use Astro::NED::Response::CoordExtinct;

our $VERSION = '0.30';


use base qw/ Astro::NED::Query::Objects Class::Accessor::Class /;

__PACKAGE__->mk_class_accessors( qw( Field ) );

__PACKAGE__->Field( { qw{
                InCoordSys      in_csys
                InEquinox       in_equinox
                Longitude       lon
                Latitude        lat
                RA              lon
                Dec             lat
                PA              pa
                OutCoordSys     out_csys
                OutEquinox      out_equinox
              }} );

__PACKAGE__->mk_accessors( keys %{__PACKAGE__->Field},
                         );

sub _init
{
    my ( $self ) = @_;

    $self->{_ua}->follow_link( text_regex => qr/coordinate transformation/i );

    return;
}

sub _query {}

sub _parse_query
{
  my $self = shift;

  # got something
  if ( $_[0] =~ /NED Coordinate & Extinction Calculator Results/i )
  {
    my $res = Astro::NED::Response::CoordExtinct->new;
    $res->parseHTML( $_[0] );

    return $res;
  }

  else
  {
    my $pfx = ref($self) . '->query: ';
    my @stuff;

    require HTML::Parser;
    my $p = HTML::Parser->new( text_h =>
                            [ sub { push @stuff,
                                      grep { ! /|(^\s*Search\ Results)
                                                |(^\s*NASA.*)
                                                |(^\s*Back to NED Home)
                                                |(^$)/x }
                                      split( /\n+/, shift ) }, 'dtext' ] );
    $p->unbroken_text(1);
    $p->parse( $_[0] );
    $p->eof;

    croak( $pfx, join( "\n$pfx", @stuff ), "\n" );
  }
}


1;
__END__

=head1 NAME

Astro::NED::Query::CoordExtinct - query NED for coordinate transforms and Galactic extinction

=head1 SYNOPSIS

  use Astro::NED::Query::CoordExtinct;

  $req = Astro::NED::Query::CoordExtinct->new( Field => value, ... );

  $req->Field( $value );

  # for fields which take multiple values
  $req->Field( $value1 => $state );
  $req->Field( $value2 => $state );

  # perform the query and get an Astro::NED::Response::CoordExtinct object
  $obj = $req->query;

=head1 DESCRIPTION

This class queries NED using the "Coordinate Transformation & Galactic
Extinction Calculator" interface.  It is a subclass of
B<Astro::NED::Query>, and thus shares all of its methods.

Class specific details are provided here.  See L<Astro::NED::Query>
for general information on the class methods (including those not
documented here) and how to set or get the search parameters.

=head2 Methods

=over

=item new

  $req = Astro::NED::Query::CoordExtinct->new( keyword1 => $value1,
                                   keyword2 => $value2, ... );


Queries are constructed using the B<new> method, which is passed a
list of keyword and value pairs.  The keywords may be the names of
single valued query parameters.

Search parameters may also be set or queried using the accessor methods;
see L<Astro::NED::Query>.

=item query

  $res = $req->query;

The B<query> method returns an instance of the
B<Astro::NED::Response::CoordExtract> class.  See
L<Astro::NED::Response::CoordExtract> for more info.

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

=item InCoordSys

The input coordinate system.  Use the B<possible_values> method
to determine which ones are available.

=item OutCoordSys

The output coordinate system.  Use the B<possible_values> method
to determine which ones are available.

=item InEquinox

The input coordinate system equinox.

=item OutEquinox

The output coordinate system equinox.

=item Longitude

The input longitude, if appropriate to the input coordinate system.

=item Latitude

The input latitude, if appropriate to the input coordinate system.

=item RA

The input right ascension, if appropriate to the input coordinate system.

=item Dec

The input declination, if appropriate to the input coordinate system.

=item PA

The input position angle.


=back

=head2 EXPORT

None by default.


=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (C) 2004 Smithsonian Astrophysical Observatory.
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
