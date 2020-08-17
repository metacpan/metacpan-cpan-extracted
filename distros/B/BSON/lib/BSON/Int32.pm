use 5.010001;
use strict;
use warnings;

package BSON::Int32;
# ABSTRACT: BSON type wrapper for Int32

use version;
our $VERSION = 'v1.12.2';

use Carp;
use Moo;

#pod =attr value
#pod
#pod A numeric scalar.  It will be coerced to an integer.  The default is 0.
#pod
#pod =cut

has 'value' => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

my $max_int32 = 2147483647;
my $min_int32 = -2147483648;

sub BUILD {
    my $self = shift;
    # coerce to IV internally
    $self->{value} = defined( $self->{value} ) ? int( $self->{value} ) : 0;
    if ( $self->{value} > $max_int32 || $self->{value} < $min_int32 ) {
        croak("The value '$self->{value}' can't fit in a signed Int32");
    }
}

#pod =method TO_JSON
#pod
#pod Returns the value as an integer.
#pod
#pod If the C<BSON_EXTJSON> environment variable is true and the
#pod C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
#pod compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$numberInt" : "42"}
#pod
#pod =cut

sub TO_JSON {
    return int($_[0]->{value}) if ! $ENV{BSON_EXTJSON} || $ENV{BSON_EXTJSON_RELAXED};
    return { '$numberInt' => "$_[0]->{value}" };
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

BSON::Int32 - BSON type wrapper for Int32

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    bson_int32( $number );

=head1 DESCRIPTION

This module provides a BSON type wrapper for a numeric value that
would be represented in BSON as a 32-bit integer.

If the value won't fit in a 32-bit integer, an error will be thrown.

=head1 ATTRIBUTES

=head2 value

A numeric scalar.  It will be coerced to an integer.  The default is 0.

=head1 METHODS

=head2 TO_JSON

Returns the value as an integer.

If the C<BSON_EXTJSON> environment variable is true and the
C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$numberInt" : "42"}

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
