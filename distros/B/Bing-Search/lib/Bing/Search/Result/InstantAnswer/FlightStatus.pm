package Bing::Search::Result::InstantAnswer::FlightStatus;
use Moose;
use Bing::Search::Result::InstantAnswer::FlightStatus::Airport;

extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';
with 'Bing::Search::Role::Types::DateType';

with qw(
   Bing::Search::Role::Result::DepartureTerminal
   Bing::Search::Role::Result::FlightNumber
   Bing::Search::Role::Result::ArrivalGate
   Bing::Search::Role::Result::ScheduledDeparture
   Bing::Search::Role::Result::OnTimeString
   Bing::Search::Role::Result::UpdatedDeparture
   Bing::Search::Role::Result::UpdatedArrival
   Bing::Search::Role::Result::DataFreshness
   Bing::Search::Role::Result::AirlineCode
   Bing::Search::Role::Result::DepartureGate
   Bing::Search::Role::Result::StatusCode
   Bing::Search::Role::Result::ScheduledArrival
   Bing::Search::Role::Result::ArrivalTerminal
   Bing::Search::Role::Result::FlightHistoryId
   Bing::Search::Role::Result::AirlineName
   Bing::Search::Role::Result::StatusString
   Bing::Search::Role::Result::FlightName
);

has [qw(OriginAirport DestinationAirport)] => ( 
   is => 'rw',
   isa => 'Bing::Search::Result::InstantAnswer::FlightStatus::Airport'
);

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $dest = delete $data->{DestinationAirport};
   my $orig = delete $data->{OriginAirport};
   my $obj_dest = Bing::Search::Result::InstantAnswer::FlightStatus::Airport->new( data => $dest );
   my $obj_orig = Bing::Search::Result::InstantAnswer::FlightStatus::Airport->new( data => $orig );
   $_->_populate() for ($obj_dest, $obj_orig);
   $self->DestinationAirport( $obj_dest );
   $self->OriginAirport( $obj_orig );
};

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::InstantAnswer::FlightStatus - Flight status from Bing

=head1 METHODS

=over 3

=item C<DepartureTerminal>

The departure terminal.

=item C<FlightNumber>

The flight number.

=item C<ArrivalGate>

The arrival gate.

=item C<ScheduledDeparture>

A L<DateTime> object representing the scheduled departure time.

=item C<OnTimeString>

A string indicating if the flight's on-time status.

=item C<UpdatedDeparture>

A L<DateTime> object representing the updated departure time, if any.

=item C<UpdatedArrival>

A L<DateTime> object representing the updated arrival time, if any.

=item C<DataFreshness>

An integer indicating how "fresh" the data is.

=item C<AirlineCode>

The airline code.  Usually two letters.  

=item C<DepartureGate>

The departure gate.

=item C<StatusCode>

A 2-digit code indicating the status of the flight.

=item C<ScheduledArrival>

A L<DateTime> object representing the scheduled arrival time.

=item C<ArrivalTerminal>

The arrival terminal.

=item C<FlightHistoryId>

A unique identifier for a specific instance of a flight.

=item C<AirlineName>

The name of the airline.

=item C<StatusString>

The status of the flight, in human-speak.

=item C<FlightName>

The full name of the flight, usually a combination of the airline code and
the flight number.

=item C<OriginAirport> and C<DestinationAirport>

Two objects representing the airports where the flight originated and 
is destined.  Each has a B<Code> (such as "SEA" for Seattle), a B<Name>
("Seattle"), and a B<TimezoneOffset> (a number, in seconds, from UTC).

=back

=head2 Unimplemented bits

Mostly because I didn't see these in the spec, and am just writing docs
right now, the following bits are not currently implemented, and therefor
will remain in the C<data> hash.

=over 3

=item * NextSegment/FlightHistoryId - Unique Id

=item * NextSegment/OriginAirport - Airport Code

=item * NextSegment/DestinationAirport - Airport Code

=item * The above three are repeated for "PreviousSegment"

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
