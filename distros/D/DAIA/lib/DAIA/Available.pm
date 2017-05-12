use strict;
use warnings;
package DAIA::Available;
#ABSTRACT: Information about a service that is currently unavailable
our $VERSION = '0.43'; #VERSION

use base 'DAIA::Availability';

our %PROPERTIES = (
    %DAIA::Availability::PROPERTIES,
    delay => { 
        filter => sub {
            return 'unknown' if lc("$_[0]") eq 'unknown';
            return DAIA::Availability::normalize_duration( $_[0] );
        },
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DAIA::Available - Information about a service that is currently unavailable

=head1 VERSION

version 0.43

=head1 DESCRIPTION

This class is derived from L<DAIA::Availability> - see that class for details.
In addition there is the property C<delay> that holds an XML Schema duration
value or the special value C<unknown>.  Obviously the C<status> property of
a C<DAIA::Unavailable> object is always C<1>.

=head1 PROPERTIES

=over

=item href

An URL to perform, register or reserve the service.

=item limitation

An array reference with limitations (L<DAIA::Limitation> objects).

=item message

An array reference with L<DAIA::Message> objects about this specific service.

=item delay

A delay as duration string (XML Schema C<xs:duration>). To get the
delay as L<DateTime::Duration> object, use the C<parse_duration>
function that can be exported on request.

=back

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
