# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Perl DateTime extension for creating a custom time zone for local solar mean time
#     Copyright (C) 2003, 2016 Rick Measham and Jean Forget
#
#     See the license in the embedded documentation below.
#
package DateTime::TimeZone::LMT;

use strict;
use warnings;
use vars qw( $VERSION );

$VERSION = '1.01';

use Params::Validate qw( validate validate_pos SCALAR ARRAYREF BOOLEAN );
use Carp;
use DateTime;
use DateTime::TimeZone;

sub new {
	my $class = shift;
	my %p = validate( @_, { 
		longitude => { type => SCALAR },
		name =>      { type => SCALAR, optional => 1 }
	});
        croak("Your longitude '$p{longitude}' must be between numeric")
          unless $p{longitude} =~ /^[-+]?\d+(\.\d+)?$/;
	croak("Your longitude must be between -180 and +180") unless $p{longitude} <= 180 and $p{longitude} >= -180;

	my %self = (
		longitude => $p{longitude},
		offset => offset_at_longitude($p{longitude}),
	);
        if (exists $p{name}) {
          $self{name} = $p{name};
          make_alias(\%self, $p{name});
        }
        else {
          $self{name} = '';
        }

	return bless \%self, $class;
}

sub offset_for_datetime{
	my ($self, $dt) = @_;
	return DateTime::TimeZone::offset_as_seconds($self->{offset})
}

sub offset_for_local_datetime{
	my ($self, $dt) = @_;
	return DateTime::TimeZone::offset_as_seconds($self->{offset})
}

sub offset { $_[0]->{offset} }

sub short_name_for_datetime { 'LMT' }
sub name { 
	my $self = shift;
	my $new_name = shift;
	$self->{name} = $new_name if $new_name;
	return $self->{name} 
}

sub longitude { 
	my $self = shift;
	my $new_longitude = shift;
	if ($new_longitude) {
                croak("Your longitude '$new_longitude' must be between numeric")
                  unless $new_longitude =~ /^[-+]?\d+(\.\d+)?$/;
		croak("Your longitude must be between -180 and +180") 
			unless $new_longitude <= 180 and $new_longitude >= -180;

		$self->{longitude} = $new_longitude;
		$self->{offset} = offset_at_longitude($new_longitude);

	}
	return $self->{longitude} 
} 


# No, we're not floating (unless on a boat, in which case you'll 
# have to continually modify your longitude. Unless, of course,
# you're heading due north or due south. In which case your
# longitude will not change.
sub is_floating { 0 }

# Not this either. Unless we're on the Prime Meridian (0 deg long)
# in which case we're still not UTC, although we're the same as.
sub is_utc { 0 }

# Nup, these aren't olsons either
sub is_olson { 0 }

# No such thing as DST so we're never in DST
sub is_dst_for_datetime { 0 }

# We're a solar based zone, so for the sake of returning something
# I'm returning 'solar'. If I return 'Local' it could be confused
# with DateTime::TimeZone::Local
sub category  { 'Solar' }

sub make_alias {
  my $self = shift;
  my $name = shift || 'LMT';

  # Devel::Cover will mention a missed line. It is unavoidable. But be assured that
  # I have tested both in two different runs in a sandbox
  my $vers = $DateTime::TimeZone::VERSION;
  if ($vers lt '0.80') {
    $DateTime::TimeZone::LINKS{ $name } = $self->{offset};
  }
  else {
    $DateTime::TimeZone::Catalog::LINKS{ $name } = $self->{offset};
  }
}

#
# Functions
#

sub offset_at_longitude {
	# A function, not a class method

	my $longitude = shift;

	my $offset_seconds = ( $longitude / 180 ) * (12 * 60 * 60);

	return DateTime::TimeZone::offset_as_string( $offset_seconds );
}

# A module should not end with a "false" value. So, traditionally,
# modules end with an insipid, colourless, odourless, tasteless and boring "1;"
# But this module is meant to (more or less) align times with the course 
# of the sun. So instead of that, let us sing together:
"For tomorrow may rain, so I'll follow the sun";

__END__

=encoding utf8

=head1 NAME

DateTime::TimeZone::LMT - A Local Mean Time time zone for DateTime

=head1 VERSION

This documentation refers to DateTime::TimeZone::LMT version 1.01.

=head1 SYNOPSIS

  use DateTime::TimeZone::LMT;

  # Somewhere in Hawaii
  my $tz_lmt = DateTime::TimeZone::LMT->new( 
    longitude => -174.2342
  );

  $now = DateTime->now( time_zone => $tz_lmt );

  my $tz_office = DateTime::TimeZone::LMT->new(
    name => 'Office',
    longitude => -174.2343
  );

  $tz_office->make_alias;
  
  $now = DateTime->now( time_zone => 'Office' );

  $tz_office->name;
  # Office

  # Relocate office to the neighbourhood of Volgograd
  $tz_office->longitude( 45.123 );
  # 45.123

  $tz_office->longitude;
  # 45.123
  

=head1 DESCRIPTION

This module provides a 'Local Mean Time' timezone for DateTime. Using
it you can determine the Mean Time for any location on Earth. Note
however that the Mean Time and the Apparent Time (where the sun is
in the sky) differ from day to day. This module may account for
Local Apparent Time in the future but then again, the Solar:: modules
will probably be a better bet.

If you want more information on the difference between LMT and LAT,
search the www for 'equation of time', 'analemma' or 'ephemeris'.

(Shameless plug-in) You can for example take a look at the example
text F<sun.pdf> in the repository
L<https://github.com/jforget/metaperlualatex>.

=head1 CONSTRUCTORS

This module has the following constructor:

=over 4

=item * new( longitude => $longitude_float, name => $name_string )

Creates a new time zone object usable by DateTime. The zone is calculated
to the second for the given longitude. 

Eastern longitudes are positive: 0 to +180.

Western longitudes are negative: -180 to 0.

An optional name can be given in order to distinguish between multiple 
instances. This is the long name accessable via DateTime.

=back

=head1 ACCESSORS

C<DateTime::TimeZone::LMT> objects provide the following accessor methods:

=over 4

=item * offset_for_datetime( $datetime )

Given an object which implements the DateTime.pm API, this method
returns the offset in seconds for the given datetime. For Olson time
zones, this takes into account historical time zone information, as
well as Daylight Saving Time.  The offset is determined by looking
at the object's UTC Rata Die days and seconds. For LMT time zones,
the historical data and DST are irrelevant.

=item * offset_for_local_datetime( $datetime )

Given an object which implements the DateTime.pm API, this method
returns the offset in seconds for the given datetime.  Unlike the
previous method, this method uses the local time's Rata Die days and
seconds.  This should only be done when the corresponding UTC time is
not yet known, because local times can be ambiguous due to Daylight
Saving Time rules.

=item * name( $new_name_string )

Returns the name of the time zone.  This is "Local Mean Time" unless
the contructor specifies a different name.

If a new name is given, then the object will be changed before being 
returned.

=item * longitude( $new_longitude_float )

Returns the longitude of the time zone.  This is the value specified
in the constructor.

If a new longitude is given, then the object will be changed before
being returned.

=item * short_name_for_datetime( $datetime )

Returns 'LMT' in all circumstances.

It is B<strongly> recommended that you do not rely on short names for
anything other than display. 

=item * create_alias( $alias_name );

Creates an alias that can be called as a string by DateTime methods.

This means you can C<< $dt = DateTime->new( time_zone => 'LMT' ) >> 
or C<< $dt = DateTime->new( time_zone => 'my alias' ) >> rather
than the normal C<< $dt = DateTime->new( time_zone => $lmt ) >>. This is of
little benefit unless you're accepting a time zone name from a user.

If the optional C<$alias_name> is provided then that will be the alias 
created. Otherwise the alias is 'LMT'. Multiple aliases can be created
from the one object.

If the longitude is changed after an alias is created, then the alias 
B<I<WILL NOT CHANGE>>. The alias does not behave as an instance of 
C<DateTime::TimeZone::LMT>.

=back

=head2 Compatability methods

The following methods always return the same value. They exist in order
to make the LMT time zone compatible with the default C<DateTime::TimeZone>
modules.

=over 4

=item * is_floating

Returns false (0) in all circumstances.

=item * is_utc

Returns false (0) in all circumstances.

=item * is_olson

Returns false (0) in all circumstances.

=item * category

Returns 'Solar' in all circumstances.

=back

=head1 Functions

This class also contains the following function:

=over 4

=item * offset_at_longitude( $longitude )

Given a longitude, this method returns a string offset.

=back

=head1 DEPENDENCIES

This module depends on basic DateTime modules: L<DateTime> and L<DateTime::TimeZone>.
It depends also on L<Params::Validate>.

=head1 BUGS AND LIMITATIONS

No known bugs.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See L<http://lists.perl.org/> for more details.

Please submit bugs to the CPAN RT system at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=datetime%3A%3Atimezone%3A%3Almt>
or via email at bug-datetime-timezone-lmt@rt.cpan.org.

=head1 AUTHOR

Rick Measham <rickm@cpan.org> with parts taken from DateTime::TimeZone
by Dave Rolsky <autarch@urth.org>.

Co-maintainer: Jean Forget (JFORGET at cpan dot org).

=head1 COPYRIGHT

Copyright (C) 2003, 2016 Rick Measham and Jean Forget.  All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself: GNU Public
License version 1 or later and Perl Artistic License.

The full text of the license can be found in the F<LICENSE> file included
with this module or at
L<http://www.perlfoundation.org/artistic_license_1_0> and
L<http://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You  should have received  a copy  of the  GNU General  Public License
along with this program; if not, see <http://www.gnu.org/licenses/> or
write to the Free Software Foundation, Inc., L<http://fsf.org>.

=head1 SEE ALSO

datetime@perl.org mailing list

L<http://datetime.perl.org/>


=cut
