package Bing::Search::Result::InstantAnswer::FlightStatus::Airport;
use Moose;

extends 'Bing::Search::Result';


with qw(
   Bing::Search::Role::Result::Code
   Bing::Search::Role::Result::TimeZoneOffset
   Bing::Search::Role::Result::Name
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::InstantAnswer::FlightStatus::Airport - An airport!

=head1 METHODS

=over 3

=item C<Code>

The airport code ("SEA")

=item C<TimeZoneOffset>

The offset, in seconds, from UTC for the airport

=item C<Name>

The name of the airport.  ("Seattle")

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
