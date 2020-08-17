use 5.010001;
use strict;
use warnings;

package BSON::Time;
# ABSTRACT: BSON type wrapper for date and time

use version;
our $VERSION = 'v1.12.2';

use Carp qw/croak/;
use Config;
use Time::HiRes qw/time/;
use Scalar::Util qw/looks_like_number/;

use if !$Config{use64bitint}, 'Math::BigInt';
use if !$Config{use64bitint}, 'Math::BigFloat';

use Moo;

#pod =attr value
#pod
#pod A integer representing milliseconds since the Unix epoch.  The default
#pod is 0.
#pod
#pod =cut

has 'value' => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

sub BUILDARGS {
    my $class = shift;
    my $n     = scalar(@_);

    my %args;
    if ( $n == 0 ) {
        if ( $Config{use64bitint} ) {
            $args{value} =  time() * 1000;
        }
        else {
            $args{value} = Math::BigFloat->new(time());
            $args{value}->bmul(1000);
            $args{value} = $args{value}->as_number('zero');
        }
    }
    elsif ( $n == 1 ) {
        croak "argument to BSON::Time::new must be epoch seconds, not '$_[0]'"
          unless looks_like_number( $_[0] );

        if ( !$Config{use64bitint} && ref($args{value}) ne 'Math::BigInt' ) {
            $args{value} = Math::BigFloat->new(shift);
            $args{value}->bmul(1000);
            $args{value} = $args{value}->as_number('zero');
        }
        else {
            $args{value} = 1000 * shift;
        }
    }
    elsif ( $n % 2 == 0 ) {
        %args = @_;
        if ( defined $args{value} ) {
            croak "argument to BSON::Time::new must be epoch seconds, not '$args{value}'"
              unless looks_like_number( $args{value} ) || overload::Overloaded($args{value});

            if ( !$Config{use64bitint} && ref($args{value}) ne 'Math::BigInt' ) {
                $args{value} = Math::BigInt->new($args{value});
            }
        }
        else {
            if ( !$Config{use64bitint} && ref($args{value}) ne 'Math::BigInt' ) {
                $args{value} = Math::BigFloat->new(shift);
                $args{value}->bmul(1000);
                $args{value} = $args{value}->as_number('zero');
            }
            else {
                $args{value} = 1000 * shift;
            }
        }
    }
    else {
        croak("Invalid number of arguments ($n) to BSON::Time::new");
    }

    # normalize all to integer ms
    $args{value} = int( $args{value} );

    return \%args;
}

#pod =method epoch
#pod
#pod Returns the number of seconds since the epoch (i.e. a floating-point value).
#pod
#pod =cut

sub epoch {
    my $self = shift;
    if ( $Config{use64bitint} ) {
        return $self->value / 1000;
    }
    else {
        require Math::BigFloat;
        my $upgrade = Math::BigFloat->new($self->value->bstr);
        return 0 + $upgrade->bdiv(1000)->bstr;
    }
}

#pod =method as_iso8601
#pod
#pod Returns the C<value> as an ISO-8601 formatted string of the form
#pod C<YYYY-MM-DDThh:mm:ss.sssZ>.  The fractional seconds will be omitted if
#pod they are zero.
#pod
#pod =cut

sub as_iso8601 {
    my $self = shift;
    my ($s, $m, $h, $D, $M, $Y) = gmtime($self->epoch);
    $M++;
    $Y+=1900;
    my $f = $self->{value} % 1000;
    return $f
      ? sprintf( "%4d-%02d-%02dT%02d:%02d:%02d.%03dZ", $Y, $M, $D, $h, $m, $s, $f )
      : sprintf( "%4d-%02d-%02dT%02d:%02d:%02dZ",      $Y, $M, $D, $h, $m, $s );
}

#pod =method as_datetime
#pod
#pod Loads L<DateTime> and returns the C<value> as a L<DateTime> object.
#pod
#pod =cut

sub as_datetime {
    require DateTime;
    return DateTime->from_epoch( epoch => $_[0]->{value} / 1000 );
}

#pod =method as_datetime_tiny
#pod
#pod Loads L<DateTime::Tiny> and returns the C<value> as a L<DateTime::Tiny>
#pod object.
#pod
#pod =cut

sub as_datetime_tiny {
    my ($s, $m, $h, $D, $M, $Y) = gmtime($_[0]->epoch);
    $M++;
    $Y+=1900;

    require DateTime::Tiny;
    return DateTime::Tiny->new(
        year => $Y, month => $M, day => $D,
        hour => $h, minute => $m, second => $s
    );
}

#pod =method as_mango_time
#pod
#pod Loads L<Mango::BSON::Time> and returns the C<value> as a L<Mango::BSON::Time>
#pod object.
#pod
#pod =cut

sub as_mango_time {
    require Mango::BSON::Time;
    return Mango::BSON::Time->new( $_[0]->{value} );
}

#pod =method as_time_moment
#pod
#pod Loads L<Time::Moment> and returns the C<value> as a L<Time::Moment> object.
#pod
#pod =cut

sub as_time_moment {
    require Time::Moment;
    return Time::Moment->from_epoch( $_[0]->{value} / 1000 );
}

sub _num_cmp {
    my ( $self, $other ) = @_;
    if ( ref($other) eq ref($self) ) {
        return $self->{value} <=> $other->{value};
    }
    return 0+ $self <=> 0+ $other;
}

sub _str_cmp {
    my ( $self, $other ) = @_;
    if ( ref($other) eq ref($self) ) {
        return $self->{value} cmp $other->{value};
    }
    return "$self" cmp "$other";
}

sub op_eq {
    my ( $self, $other ) = @_;
    return( ($self <=> $other) == 0 );
}

use overload (
    q{""}    => \&epoch,
    q{0+}    => \&epoch,
    q{<=>}   => \&_num_cmp,
    q{cmp}   => \&_str_cmp,
    fallback => 1,
);

#pod =method TO_JSON
#pod
#pod Returns a string formatted by L</as_iso8601>.
#pod
#pod If the C<BSON_EXTJSON> option is true, it will instead be compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod
#pod If the C<BSON_EXTJSON> environment variable is true and the
#pod C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
#pod compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$date" : { "$numberLong": "22337203685477580" } }
#pod
#pod If the C<BSON_EXTJSON> and C<BSON_EXTJSON_RELAXED> environment variables are
#pod both true, then it will return a hashref with an ISO-8601 string for dates
#pod after the Unix epoch and before the year 10,000 and a C<$numberLong> style
#pod value otherwise.
#pod
#pod     {"$date" : "2012-12-24T12:15:30.500Z"}
#pod     {"$date" : { "$numberLong": "-10000000" } }
#pod
#pod =cut

sub TO_JSON {
    return $_[0]->as_iso8601
        if ! $ENV{BSON_EXTJSON};

    return { '$date' => { '$numberLong' => "$_[0]->{value}"} }
        if ! $ENV{BSON_EXTJSON_RELAXED};

    # Relaxed form is human readable for positive epoch to year 10k
    my $year = (gmtime($_[0]->epoch))[5];
    $year += 1900;
    if ($year >= 1970 and $year <= 9999) {
        return { '$date' => $_[0]->as_iso8601 };
    }
    else {
        return { '$date' => { '$numberLong' => "$_[0]->{value}" } };
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Time - BSON type wrapper for date and time

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    bson_time();        # now
    bson_time( $secs ); # floating point seconds since epoch

=head1 DESCRIPTION

This module provides a BSON type wrapper for a 64-bit date-time value in
the form of milliseconds since the Unix epoch (UTC only).

On a Perl without 64-bit integer support, the value must be a
L<Math::BigInt> object.

=head1 ATTRIBUTES

=head2 value

A integer representing milliseconds since the Unix epoch.  The default
is 0.

=head1 METHODS

=head2 epoch

Returns the number of seconds since the epoch (i.e. a floating-point value).

=head2 as_iso8601

Returns the C<value> as an ISO-8601 formatted string of the form
C<YYYY-MM-DDThh:mm:ss.sssZ>.  The fractional seconds will be omitted if
they are zero.

=head2 as_datetime

Loads L<DateTime> and returns the C<value> as a L<DateTime> object.

=head2 as_datetime_tiny

Loads L<DateTime::Tiny> and returns the C<value> as a L<DateTime::Tiny>
object.

=head2 as_mango_time

Loads L<Mango::BSON::Time> and returns the C<value> as a L<Mango::BSON::Time>
object.

=head2 as_time_moment

Loads L<Time::Moment> and returns the C<value> as a L<Time::Moment> object.

=head2 TO_JSON

Returns a string formatted by L</as_iso8601>.

If the C<BSON_EXTJSON> option is true, it will instead be compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

If the C<BSON_EXTJSON> environment variable is true and the
C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$date" : { "$numberLong": "22337203685477580" } }

If the C<BSON_EXTJSON> and C<BSON_EXTJSON_RELAXED> environment variables are
both true, then it will return a hashref with an ISO-8601 string for dates
after the Unix epoch and before the year 10,000 and a C<$numberLong> style
value otherwise.

    {"$date" : "2012-12-24T12:15:30.500Z"}
    {"$date" : { "$numberLong": "-10000000" } }

=for Pod::Coverage op_eq BUILDARGS

=head1 OVERLOADING

Both numification (C<0+>) and stringification (C<"">) are overloaded to
return the result of L</epoch>.  Numeric comparison and string comparison
are overloaded based on those and fallback overloading is enabled.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
