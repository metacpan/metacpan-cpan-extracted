package DNS::ZoneSerialNumber;

use 5.006000;
use strict;

use overload
 '>'   => \&gt,
 '>='  => \&gte,
 '<'   => \&lt,
 '<='  => \&lte,
 '=='  => \&eq,
 '!='  => \&ne,
 '<=>' => \&compare,
 '+='  => \&increment,
 '-='  => \&decrement,
 '='   => \&_copy,
 '+'   => \&next,
 '-'   => \&previous,
 '0+'  => \&serial,
 # Not sure why this is necessary and can't be generated from 0+, but it
 # it seems to be required by Test::More::is_deeply. It might need to change
 # some day to return an explicit string rather than relying on Perl to
 # convert.
 '""' => \&serial,
 ;

use Carp qw/croak/;
$Carp::Internal{ ( __PACKAGE__ ) }++;

use constant SERIAL_BITS   => 32;
use constant SERIAL_MAX    => ( 2**SERIAL_BITS ) - 1;
use constant SERIAL_HALF   => 2**( SERIAL_BITS - 1 );
use constant INCREMENT_MAX => ( 2**( SERIAL_BITS - 1 ) ) - 1;

our @ISA     = qw();
our $VERSION = '1.01';

=head1 NAME

DNS::ZoneSerialNumber - Manipulate DNS zone serial numbers.

=head1 SYNOPSIS

  use DNS::ZoneSerialNumber;
  my $zsn = DNS::ZoneSerialNumber->new(100);
  $zsn->increment();
  print "The new serial number is ", $zsn->serial, "\n";

=head1 DESCRIPTION

DNS::ZoneSerialNumber encapsulates a DNS zone serial number and provides RFC
1982, 1912, and 2136 compliant manipulation, comparison, and validation
methods. This module automatically handles serial number overflows, underflows,
and invalid comparisons, as well as simple increments and decrements.

=head1 METHODS

=head2 new

Constructor for the DNS::ZoneSerialNumber object. Accepts a single optional
parameter, the serial number that the object should represent. If not
specified, defaults to 1. If an invalid serial number is specified, the method
will L<croak>.

On success, returns the DNS::ZoneSerialNumber object.

=cut

sub new {
    my ( $class, $serial ) = @_;

    if ( defined $serial ) {
        if ( ref $serial eq 'DNS::ZoneSerialNumber' ) {
            $serial = $serial->serial;
        }
        __check_valid_serial_and_croak( $serial );
    } else {
        $serial = 1;
    }

    my $self = { serial => $serial, };

    bless $self, $class;
    return $self;
}

sub __check_valid_serial_and_croak {
    if ( !__check_valid_serial( @_ ) ) {
        croak 'Invalid serial (must be numeric, positive, non-zero, and <= ' . SERIAL_MAX . ')';
    }
}

sub __check_valid_serial {
    my ( $serial ) = @_;
    if (   ( !defined $serial )
        || ( $serial !~ /^\d+$/ )
        || ( $serial > SERIAL_MAX )
        || ( $serial == 0 ) )
    {
        return 0;
    }
    return 1;
}

sub __check_valid_increment_and_croak {
    my ( $serial ) = @_;
    if (   ( !defined $serial )
        || ( $serial !~ /^\d+$/ )
        || ( $serial > INCREMENT_MAX ) )
    {
        croak 'Invalid amount (must be numeric, positive, and <= ' . INCREMENT_MAX . ')';
    }
}

sub _compare {
    my ( $self, $i2, $swapped ) = @_;
    my $i1;

    if ( ref $i2 eq 'DNS::ZoneSerialNumber' ) {
        $i2 = $i2->serial;
    }
    __check_valid_serial_and_croak( $i2 );

    if ( $swapped ) {
        $i1 = $i2;
        $i2 = $self->{serial};
    } else {
        $i1 = $self->{serial};
    }

    if ( $i1 == $i2 ) { return 0; }

    # Logic taken from RFC 1982 (I know it's not pretty but it's meant to
    # resemble the RFC).
    if (   ( $i1 < $i2 && $i2 - $i1 < SERIAL_HALF )
        || ( $i1 > $i2 && $i1 - $i2 > SERIAL_HALF ) )
    {
        return -1;
    }

    if (   ( $i1 < $i2 && $i2 - $i1 > SERIAL_HALF )
        || ( $i1 > $i2 && $i1 - $i2 < SERIAL_HALF ) )
    {
        return 1;
    }
    # As per RFC 1982 there are value pairs that can not be logically compared.
    # They are neither less than, greater than, nor equal to, each other. If we
    # encounter one of these pairs, simply return undef. <=> returns undef when
    # comparing against NaN, so returning undef from a compare function is not
    # completely unheard of.
    return undef;
}

sub _copy {
    my ( $self ) = @_;
    return DNS::ZoneSerialNumber->new( $self->serial );
}

=head2 valid

Accepts a single parameter, the serial number to test for validity.

Returns true or false depending representing whether or not the specified
serial number represents a valid serial number. Valid serial numbers are
positive integers between 1 and SERIAL_MAX (inclusive). See L<CONSTANTS> for
details.

Note: This method may be called statically or as an instance method.

=cut

sub valid {
    my ( $self, $serial ) = @_;
    if ( !ref $self ) {
        $serial = $self;
    }
    if ( ref $serial eq 'DNS::ZoneSerialNumber' ) {
        $serial = $serial->serial;
    }
    return __check_valid_serial( $serial );
}

=head2 serial

Accepts no parameters. Returns the represented serial number as a Perl scalar.

Note: In string or numeric context, a DNS::ZoneSerialNumber object will return
an appropriate representation of its serial number automatically.

=cut

sub serial {
    my ( $self ) = @_;
    return $self->{serial};
}

=head2 set

Accepts a single parameter, the new serial number. Returns the
DNS::ZoneSerialNumber object with the updated serial number.

Sets the serial number represented by the object to the specified serial
number. If the specified serial number is invalid the method will L<croak>.

=cut

sub set {
    my ( $self, $newval ) = @_;
    if ( ref $newval eq 'DNS::ZoneSerialNumber' ) {
        $newval = $newval->serial;
    }
    __check_valid_serial_and_croak( $newval );
    $self->{serial} = $newval;
    return $self;
}

=head2 set_from_date

Accepts a single optional parameter, the revision count of the new date-based
serial number. If an invalid revision count is specified (< 0 or > 99), the
method will L<croak>. Returns the DNS::ZoneSerialNumber with the updated serial
number.

Sets the serial number represented by the object to a serial number based on
the current date in the format specified by RFC 1912 (YYYYMMDDnn). This format
allows for a two-digit revision count (nn) which defaults to "00" unless
specified.

=cut

sub set_from_date {
    my ( $self, $revisions ) = @_;
    if ( !defined $revisions ) { $revisions = 0; }
    if ( $revisions !~ /^\d+$/ || $revisions > 99 ) {
        croak 'Revision count invalid';
    }
    my @time = localtime();
    my $new_serial = sprintf( '%04d%02d%02d%02d', $time[5] + 1900, $time[4] + 1, $time[3], $revisions );
    return $self->set( $new_serial );
}

=head2 steps_to_set

Accepts a single parameter, the new serial number. If the specified serial
number is invalid, the method will L<croak>. In array context, returns an
in-order array of DNS::ZoneSerialNumber objects representing the serial numbers
that must be set in order to safely set the specified serial number. In scalar
context the number of required steps is returned.

Due to the way RFC 1982 defines serial number comparisons, it is not possible
to simply set a zone's serial number to any number considered less than the
current serial number. If this is done, DNS servers will assume that the new
serial number is older than the prior serial number. In order to set the serial
number to a lower value without DNS servers believing the serial number is
lower, it must first be set to a higher number (and eventually overflowed) and
propagated out.  This method generates the list of serial numbers that must be
set, in order, to allow a serial number to be set to a lower value without DNS
servers believing the serial number is older. On success, this method
necessarily returns an array of 1 or 2 elements (or the numbers 1 or 2 in
scalar context).

If the specified serial number is greater than or equal to the represented
serial number, no additional steps are required and an array of a single
element (or the number 1 in scalar context) is returned.

Please note that because this module always avoids the serial number 0, it may
compute a different set of increments to arrive at the specified serial number
than other tools.

For more information see RFC 1982.

=cut

sub steps_to_set {
    my ( $self, $serial ) = @_;
    my $s = $self->{serial};

    if ( ref $serial eq 'DNS::ZoneSerialNumber' ) {
        $serial = $serial->serial;
    }
    __check_valid_serial_and_croak( $serial );

    my $cmp = $self->compare( $serial );
    if ( $self->lte( $serial ) ) {
        if ( wantarray ) {
            return ( DNS::ZoneSerialNumber->new( $serial ) );
        }
        return 1;
    }

    if ( wantarray ) {
        return (
            $self->next( INCREMENT_MAX ),    # Returns a DNS::ZoneSerialNumber
            DNS::ZoneSerialNumber->new( $serial )
        );
    }
    return 2;
}

=head2 incomparable

Accepts no parameters. Returns a DNS::ZoneSerialNumber object representing the
incomparable value for the currently represented serial number.

See RFC 1982 for more information about incomparable serial numbers.

=cut

sub incomparable {
    my ( $self ) = @_;
    my $r = DNS::ZoneSerialNumber->new( $self );
    # Work around increment limits.
    $r->increment( SERIAL_HALF - 1 );
    $r->increment();
    return $r;
}

=head2 is_incomparable

Accepts a single parameter, the serial number against which the represented
serial number should be checked for incomparability. If the specified serial
number is invalid, the method will L<croak>.

Returns true if the serial numbers are incomparable or false otherwise.

See RFC 1982 for more information about incomparable serial numbers.

=cut

sub is_incomparable {
    my ( $self, $serial ) = @_;
    if ( ref $serial eq 'DNS::ZoneSerialNumber' ) {
        $serial = $serial->serial;
    }
    __check_valid_serial_and_croak( $serial );
    if ( $self->incomparable()->eq( $serial ) ) {
        return 1;
    }
    return 0;
}

=head2 next

Accepts a single optional parameter, the amount to increment by (n). If no
parameter is specified, the amount defaults to 1. If an invalid amount is
specified, the method will L<croak>. Please see L<CONSTANTS> for details.
Returns the next nth serial number in sequence as a DNS::ZoneSerialNumber
object. The currently represented serial number is unchanged.

If the serial number overflows the serial maximum it will automatically roll
over through the serial minimum.

This method is also available as the overloaded operator "+". Please note that
the protections against invalid increments can be circumvented via compound
addition using the overloaded methods. For example, the following will succeed
even though it results in an invalid increment due to the fact the addition
was done in multiple steps:

 my $new_zsn = $zsn + DNS::ZoneSerialNumber::INCREMENT_MAX + 1;

However, the following will (correctly) generate an error:

 my $new_zsn = $zsn + ( DNS::ZoneSerialNumber::INCREMENT_MAX + 1 );

=cut

sub next {
    my ( $self, $amount ) = @_;
    my $s = $self->{serial};

    if ( !defined $amount ) { $amount = 1; }
    if ( ref $amount eq 'DNS::ZoneSerialNumber' ) {
        $amount = $amount->serial;
    }
    __check_valid_increment_and_croak( $amount );

    $s += $amount;
    if ( $s > SERIAL_MAX ) {
        # The off-by-one here is intentional to skip the serial number 0.
        $s -= SERIAL_MAX;
    }
    if ( $s == 0 ) {
        $s = 1;
    }
    return DNS::ZoneSerialNumber->new( $s );
}

=head2 previous

Accepts a single optional parameter, the amount to decrement by (n). If no
parameter is specified, the amount defaults to 1. If an invalid amount is
specified, the method will L<croak>. Please see L<CONSTANTS> for details.
Returns the prior nth serial number in sequence as a DNS::ZoneSerialNumber
object. The currently represented serial number is unchanged.

If the serial number underflows the serial minimum it will automatically roll
over through the serial maximum.

This method is also available as the overloaded operator "-".

=cut

sub previous {
    my ( $self, $amount, $swapped ) = @_;
    my $s;

    if ( !defined $amount ) { $amount = 1; }
    if ( ref $amount eq 'DNS::ZoneSerialNumber' ) {
        $amount = $amount->serial;
    }
    __check_valid_increment_and_croak( $amount );

    if ( $swapped ) {
        $s      = $amount;
        $amount = $self->{serial};
    } else {
        $s = $self->{serial};
    }

    $s -= $amount;
    if ( $s < 1 ) {
        # The off-by-one here is intentional to skip the serial number 0.
        $s += SERIAL_MAX;
    }
    if ( $s == 0 ) {
        $s = SERIAL_MAX;
    }
    return DNS::ZoneSerialNumber->new( $s );
}

=head2 increment

Accepts a single optional parameter, the amount to increment by (n). If no
parameter is specified, the amount defaults to 1. If an invalid amount is
specified, the method will L<croak>. Please see L<CONSTANTS> for details. Sets
the currently represented serial number to the nth next serial number in
sequence and returns the DNS::ZoneSerialNumber object with the updated value.

If the serial number overflows the serial maximum it will automatically roll
over through the serial minimum.

This method is also available as the overloaded operator "++".

=cut

sub increment {
    my ( $self, $amount ) = @_;

    $self->{serial} = $self->next( $amount )->serial;
    return $self;
}

=head2 decrement

Accepts a single optional parameter, the amount to decrement by (n). If no
parameter is specified, the amount defaults to 1. If an invalid amount is
specified, the method will L<croak>. Please see L<CONSTANTS> for details. Sets
the currently represented serial number to the nth prior serial number in
sequence and returns the DNS::ZoneSerialNumber object with the updated value.

If the serial number underflows the serial minimum it will automatically roll
over through the serial maximum.

This method is also available as the overloaded operator "--".

=cut

sub decrement {
    my ( $self, $amount ) = @_;

    $self->{serial} = $self->previous( $amount )->serial;
    return $self;
}

=head2 compare

Accepts a single parameter, the serial number to be compared against the one
represented by the DNS::ZoneSerialNumber object. If the supplied serial number
is invalid, the method will L<croak>.

This method's behavior is the same as the L<<=>> operator, however in the case
of incomparable numbers undef is returned. This method is also available as the
overloaded operator "<=>".

=cut

sub compare {
    my ( $self, $i2, $swapped ) = @_;
    return $self->_compare( $i2, $swapped );
}

=head2 Overloaded Comparison Methods

All of the following methods accept a single argument, the serial number to be
compared against the one represented by the DNS::ZoneSerialNumber object. If
the supplied serial number is invalid, the method will L<croak>.

Each method true or false as a result of the comparison. In the case of
incomparable numbers, false is returned by all methods except L<ne (!=)>. All
of the following methods are also available as overloaded comparison operators.

The comparison is performed with the encapsulated serial number treated as the
left operand. For example:

 $zsn->gt(100)

Is the equivalent of writing:

 $zsn > 100

The following methods are available:

=head3 gt (>)

=head3 gte (>=)

=head3 lt (<)

=head3 lte (<=)

=head3 eq (==)

=head3 ne (!=)

=cut

sub gt {
    my ( $self, $i2, $swapped ) = @_;
    my $r = $self->_compare( $i2, $swapped );
    if ( defined $r && $r == 1 ) { return 1; }
    return 0;
}

sub gte {
    my ( $self, $i2, $swapped ) = @_;
    my $r = $self->_compare( $i2, $swapped );
    if ( defined $r && $r >= 0 ) { return 1; }
    return 0;
}

sub lt {
    my ( $self, $i2, $swapped ) = @_;
    my $r = $self->_compare( $i2, $swapped );
    if ( defined $r && $r == -1 ) { return 1; }
    return 0;
}

sub lte {
    my ( $self, $i2, $swapped ) = @_;
    my $r = $self->_compare( $i2, $swapped );
    if ( defined $r && $r <= 0 ) { return 1; }
    return 0;
}

sub eq {
    my ( $self, $i2, $swapped ) = @_;
    my $r = $self->_compare( $i2, $swapped );
    if ( defined $r && $r == 0 ) { return 1; }
    return 0;
}

sub ne {
    my ( $self, $i2, $swapped ) = @_;
    my $r = $self->_compare( $i2, $swapped );
    if ( !defined $r || $r != 0 ) { return 1; }
    return 0;
}

1;

=head1 CONSTANTS

DNS::ZoneSerialNumber contains the following internal constants representing
definitions and rules used by DNS::ZoneSerialNumber and RFC 1982. These
constants are not exported but are available if accessed via the full
namespace (eg, DNS::ZoneSerialNumber::SERIAL_BITS).

=head2 SERIAL_BITS

The number of bits used to represent a DNS zone serial number. Set at 32.

=head2 SERIAL_MAX

The maximum value a serial number of SERIAL_BITS size can store. Computed as:

 ( 2 ** SERIAL_MAX ) - 1

=head2 SERIAL_HALF

Approximately half the serial maximum value as used in RFC 1982 equality
calculations. This value is used in serial number comparisons and in
calculating incomparable serial numbers. Computed as:

 2 ** ( SERIAL_BITS - 1 )

=head2 INCREMENT_MAX

The maximum amount by which a serial number can be incremented in a single
step. If incremented by more than this amount, the serial number would appear
to have gone "backwards", see RFC 1982 for details. Computed as: 

 ( 2 ** ( SERIAL_BITS - 1 ) ) - 1

=head1 SERIAL NUMBER 0

As per RFC 2136, the serial number 0 is not used and is skipped for all
additive and subtractive calculations. For example, if a DNS::ZoneSerialNumber
object representing the serial number SERIAL_MAX is then incremented by 1, the
new serial number will be set to 1 rather than 0.

Comparisons will still take serial number 0 into account as expected.

=head1 INVALID COMPARISONS

The serial number logic provided by RFC 1982 defines two serial numbers with a
difference of ( 2 ** SERIAL_MAX ) to be considered neither greater than, less
than, nor equal to each other. The RFC provides no recommendations on how to
handle comparisons of these numbers and suggests they not be compared directly
or used together in the same environment. DNS::ZoneSerialNumber attempts to
compare these serial numbers using the same logic that BIND uses: all
comparison methods will return false for any comparison of these serial number
pairs, except for L<ne (!=)> which returns true, and L<compare> (<=>) which
returns undef.

=head1 OPERATOR OVERLOADING

DNS::ZoneSerialNumber provides overloaded operators for many of its provided
methods. The author is currently unsure as to whether or not this is a good
idea. If it proves to be problematic, the overloads may be removed (or made
optional) in a future version.

=head1 CHANGES

=head2 1.01 - 20120120, jeagle

Minor documentation updates.

=head2 1.00 - 20120118, jeagle

Initial release to CPAN.

=head1 SEE ALSO

DNS::ZoneParse, Net::DNS, RFC 1982, RFC 1912, RFC 2136

=head1 AUTHOR

John Eaglesham

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by John Eaglesham

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

