
package DateTimeX::Lite::TimeZone::OffsetOnly;

use strict;

use DateTimeX::Lite::TimeZone;
use base 'DateTimeX::Lite::TimeZone';

use DateTimeX::Lite::TimeZone::UTC;

sub new {
    my ($class, %p) = @_;

    my $offset =
        DateTimeX::Lite::TimeZone::offset_as_seconds( $p{offset} );

    die "Invalid offset: $p{offset}\n" unless defined $offset;

    return DateTimeX::Lite::TimeZone::UTC->new unless $offset;

    my $self = { name   => DateTimeX::Lite::TimeZone::offset_as_string( $offset ),
                 offset => $offset,
               };

    return bless $self, $class;
}

sub is_dst_for_datetime { 0 }

sub offset_for_datetime { $_[0]->{offset} }
sub offset_for_local_datetime { $_[0]->{offset} }

sub is_utc { 0 }

sub short_name_for_datetime { $_[0]->name }

sub category { undef }

1;

__END__

=head1 NAME

DateTimeX::Lite::TimeZone::OffsetOnly - A DateTimeX::Lite::TimeZone object that just contains an offset

=head1 SYNOPSIS

  my $offset_tz = DateTimeX::Lite::TimeZone->new( name => '-0300' );

=head1 DESCRIPTION

This class is used to provide the DateTimeX::Lite::TimeZone API needed by
DateTime.pm, but with a fixed offset.  An object in this class always
returns the same offset as was given in its constructor, regardless of
the date.

=head1 USAGE

This class has the same methods as a real time zone object, but the
C<category()> method returns undef.

=head2 DateTimeX::Lite::TimeZone::OffsetOnly->new ( offset => $offset )

The value given to the offset parameter must be a string such as
"+0300".  Strings will be converted into numbers by the
C<DateTimeX::Lite::TimeZone::offset_as_seconds()> function.

=head2 $tz->offset_for_datetime( $datetime )

No matter what date is given, the offset provided to the constructor
is always used.

=head2 $tz->name()

=head2 $tz->short_name_for_datetime()

Both of these methods return the offset in string form.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2003-2008 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut