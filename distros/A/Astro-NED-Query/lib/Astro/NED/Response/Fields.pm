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

package Astro::NED::Response::Fields;

use Regexp::Common qw( RE_num_ALL );

use 5.006;
use strict;
use warnings;

our $VERSION = '0.30';

# mapping between HTML table column names and Object field names
my @Fields =
  (
 { name => 'No',
   re  => qr/row\s+no[.]/i,
   chk => qr/^\d+$/,
 },

 { name => 'Name',
   re  => qr/object name/i,
   chk => undef,
 },

 { name => 'Lat',
   re  => qr/lat$/i,
   chk => undef,
 },

 { name => 'Lon',
   re => qr/lon$/i,
   chk => undef,
 },

 { name => 'Type',
   re  => qr/object type/i,
   chk => undef,
 },

 { name => 'RA',
   re  => qr/RA$/,
   chk => qr/[-+]? \d{2}h \d{2}m \d{2}[.]\d s/ix,
 },

 { name => 'Dec',
   re  => qr/DEC$/,
   chk => qr/[-+]? \d{2}d \d{2}m \d{2} s/ix,
 },

 { name => 'Velocity',
   re  => qr{km/s}i,
   chk => RE_num_real(),
 },

 { name => 'Z',
   re  => qr/redshift z$/i,
   chk => RE_num_real(),
 },

 { name => 'VZQual',
   re  => qr/qual$/i,
   chk => undef,
 },

 { name => 'mag',
   re => qr/Filter$/,
   chk => undef
 },

 { name => 'Distance',
   re  => qr/distance/i,
   chk => RE_num_real(),
 },

 { name => 'NRefs',
   re  => qr/number of refs/i,
   chk => RE_num_int(),
 },

 { name => 'NNotes',
   re  => qr/number of notes/i,
   chk => RE_num_int(),
 },

 { name => 'NPhot',
   re  => qr/number of phot/i,
   chk => RE_num_int(),
 },

 { name => 'NPosn',
   re  => qr/number of posn/i,
   chk => RE_num_int(),
 },

 { name => 'NVel',
   re  => qr{number of vel/z}i,
   chk => RE_num_int(),
 },

 { name => 'NDiam',
   re  => qr/number of diam/i,
   chk => RE_num_int(),
 },

 { name => 'NAssoc',
   re  => qr/number of assoc/i,
   chk => RE_num_int(),
 },

 { name => 'Images',
   re  => qr/images/i,
   chk => undef,
 },

 { name => 'Spectra',
   re  => qr/spectra/i,
   chk => undef,
 },



  );

## no critic (AccessOfPrivateData)
# @Fields is a list of arrayrefs, not objects.

my @FieldNames = map { $_->{name} } @Fields;
my %Fields = map { ( $_->{name} => $_ ) } @Fields;

## use critic

sub fields { return @Fields };
sub names { return @FieldNames };

sub match
{
    my ( $colname ) = @_;

    ## no critic (AccessOfPrivateData)
    # @Fields is a list of refs, not objects.
    return grep { $colname =~ $_->{re} } @Fields;
    ## use critic
}

sub check
{
    my ( $data ) = @_;

    # reset internal iterator state
    keys %$data;

    while( my ( $name, $value ) = each %$data )
    {
        next unless defined $value;
        my $chk = $Fields{$name}{chk};
        eval {
            'CODE'   eq ref $chk && ! $chk->($value) and die;
            'Regexp' eq ref $chk && $value !~ $chk   and die;
        };
        $@ and die( "illegal value ($value) for column $name\n" );
    }

    return;
}


1;
__END__

=head1 NAME

Astro::NED::Response::Fields - Helper module for Astro::NED::Response::Object(s)

=head1 SYNOPSIS

  use Astro::NED::Response::Fields;

=head1 DESCRIPTION

This class is a helper class for B<Astro::NED::Query::Object(s)> query.

=head2 Class Methods

=over

=item fields

  @fields = Astro::NED::Response::Fields::names();

Returns a list of recognized fields.  Each field is an array
containing the field name and the regex used to match it.

=begin internals

=item match

  @matches = Astro::NED::Response::Fields::match( $colname );

Return a list of fields which match the passed NED column name.
I<internal use only>.

=item check

  Astro::NED::Response::Fields::check( \%data );

Checks the passed hashref for the validity of the data, which must
have been extracted from a NED response.  The keywords are the matched
column names (not the actual ones in the NED table).  B<die>'s upon
error.

I<internal use only>.

=end internals


=item names

  @names = Astro::NED::Response::Fields::names();

returns the list of recognized field names.  This should rarely, if
ever be used by user code.  Instead, use the query object's
B<fields> method.

=back

=head2 EXPORT

None.

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (C) 2007 Smithsonian Astrophysical Observatory.
All rights are of course reserved.

It is released under the GNU General Public License.  You may find a
copy at

   http://www.fsf.org/copyleft/gpl.html

=head1 SEE ALSO

L<Astro::NED::Response::Object>,
L<Astro::NED::Query::Objects>,
L<perl>.

=cut
