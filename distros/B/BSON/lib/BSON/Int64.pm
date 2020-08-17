use 5.010001;
use strict;
use warnings;

package BSON::Int64;
# ABSTRACT: BSON type wrapper for Int64

use version;
our $VERSION = 'v1.12.2';

use Carp;
use Config;
use Moo;

#pod =attr value
#pod
#pod A numeric scalar.  It will be coerced to an integer.  The default is 0.
#pod
#pod =cut

has 'value' => (
    is => 'ro'
);

use if !$Config{use64bitint}, "Math::BigInt";

use namespace::clean -except => 'meta';

# With long doubles or a 32-bit integer perl, we're able to directly check
# if a value exceeds the maximum bounds of an int64_t.  On a 64-bit Perl
# with only regular doubles, the loss of precision for doubles makes an
# exact check against the negative boundary impossible from pure-Perl.
# (The positive boundary isn't an issue because Perl will upgrade
# internally to uint64_t to do the comparision).  Fortunately, we can take
# advantage of a quirk in pack(), where a float that is in the ambiguous
# negative zone or that is too negative to fit will get packed like the
# smallest negative int64_t.

BEGIN {
    my $max_int64 = $Config{use64bitint} ? 9223372036854775807 : Math::BigInt->new("9223372036854775807");
    my $min_int64 = $Config{use64bitint} ? -9223372036854775808 : Math::BigInt->new("-9223372036854775808");
    if ( $Config{nvsize} == 16 || ! $Config{use64bitint} ) {
        *BUILD = sub {
            my $self = shift;

            my $value = defined $self->{value} ? int($self->{value}) : 0;

            if ( $value > $max_int64 ) {
                $value = $max_int64;
            }
            elsif ( $value < $min_int64 ) {
                $value = $min_int64;
            }

            return $self->{value} = $value;
        }
    }
    else {
        my $packed_min_int64 = pack("q<", $min_int64);
        *BUILD = sub {
            my $self = shift;

            my $value = defined $self->{value} ? int($self->{value}) : 0;

            if ( $value >= 0 && $value > $max_int64 ) {
                $value = $max_int64;
            }
            elsif ( $value < 0 && pack("q<", $value) eq $packed_min_int64 ) {
                $value = $min_int64;
            }

            return $self->{value} = $value;
        }
    }
}

#pod =method TO_JSON
#pod
#pod On a 64-bit perl, returns the value as an integer.  On a 32-bit Perl, it
#pod will be returned as a Math::BigInt object, which will
#pod fail to serialize unless a C<TO_JSON> method is defined
#pod for that or in package C<universal>.
#pod
#pod If the C<BSON_EXTJSON> environment variable is true and the
#pod C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
#pod compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$numberLong" : "223372036854775807"}
#pod
#pod =cut

sub TO_JSON {
    return int($_[0]->{value}) if ! $ENV{BSON_EXTJSON} || $ENV{BSON_EXTJSON_RELAXED};
    return { '$numberLong' => "$_[0]->{value}" };
}

use overload (
    # Unary
    q{""} => sub { "$_[0]->{value}" },
    q{0+} => sub { $_[0]->{value} },
    q{~}  => sub { ~( $_[0]->{value} ) },
    # Binary
    ( map { $_ => eval "sub { return \$_[0]->{value} $_ \$_[1] }" } qw( + * ) ), ## no critic
    (
        map {
            $_ => eval ## no critic
              "sub { return \$_[2] ? \$_[1] $_ \$_[0]->{value} : \$_[0]->{value} $_ \$_[1] }"
        } qw( - / % ** << >> x <=> cmp & | ^ )
    ),
    (
        map { $_ => eval "sub { return $_(\$_[0]->{value}) }" } ## no critic
          qw( cos sin exp log sqrt int )
    ),
    q{atan2} => sub {
        return $_[2] ? atan2( $_[1], $_[0]->{value} ) : atan2( $_[0]->{value}, $_[1] );
    },

    # Special
    fallback => 1,
);

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Int64 - BSON type wrapper for Int64

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    bson_int64( $number );

=head1 DESCRIPTION

This module provides a BSON type wrapper for a numeric value that
would be represented in BSON as a 64-bit integer.

If the value won't fit in a 64-bit integer, an error will be thrown.

On a Perl without 64-bit integer support, the value must be a
L<Math::BigInt> object.

=head1 ATTRIBUTES

=head2 value

A numeric scalar.  It will be coerced to an integer.  The default is 0.

=head1 METHODS

=head2 TO_JSON

On a 64-bit perl, returns the value as an integer.  On a 32-bit Perl, it
will be returned as a Math::BigInt object, which will
fail to serialize unless a C<TO_JSON> method is defined
for that or in package C<universal>.

If the C<BSON_EXTJSON> environment variable is true and the
C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$numberLong" : "223372036854775807"}

=for Pod::Coverage BUILD

=head1 OVERLOADING

The numification operator, C<0+> is overloaded to return the C<value>,
the full "minimal set" of overloaded operations is provided (per L<overload>
documentation) and fallback overloading is enabled.

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
