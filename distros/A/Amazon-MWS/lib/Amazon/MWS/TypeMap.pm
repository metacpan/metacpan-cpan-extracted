package Amazon::MWS::TypeMap;

use warnings;
use strict;

use DateTime;
use DateTime::Format::ISO8601;

use Exporter qw(import);
our @EXPORT_OK = qw(from_amazon to_amazon);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub identity { shift }

my %from_map = (
    'string' => \&identity,
    'boolean' => sub { lc(shift) eq 'true' },
    'nonNegativeInteger' => \&identity, 
    'datetime' => sub {
        return DateTime::Format::ISO8601->parse_datetime(shift);
     },
);

sub from_amazon {
    my ($type, $value) = @_;
    return $from_map{$type}->($value);
}

my %to_map = (
    'string'   => \&identity,
    'boolean'  => sub { $_[0] ? 'true' : 'false' },
    'nonNegativeInteger' => sub {
        my $int = int(shift);
        $int = 1 unless $int > 0;
        return $int;
    },
    'datetime' => sub { 
	return DateTime::Format::ISO8601->parse_datetime(shift);
    },
);

sub to_amazon {
    my ($type, $value) = @_;
    return $to_map{$type}->($value);
}

1;

__END__

=head1 NAME

Amazon::MWS::TypeMap

=head1 DESCRIPTION

Functions for mapping between types specified in the MWS API documentation and
perl datatypes.

=head1 EXPORTED FUNCTIONS

=head2 to_amazon ( type, value )

Converts from a perl datatype to a string for use as an MWS param.

=head2 from_amazon ( type, value )

Converts from a string supplied by MWS to a perl datatype.

=head1 TYPES

=head2 string

A plain perl string.

=head2 boolean

When sent by amazon, true is converted to 1 and false to the empty string.
When sent to amazon, any true value or false value will be properly converted.

=head2 datetime

Converted to and from DateTime objects.

=head1 AUTHOR

Paul Driver C<< frodwith@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Plain Black Corporation L<http://plainblack.com>.
All rights reserved

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See L<perlartistic>.
