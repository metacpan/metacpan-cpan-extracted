use 5.010001;
use strict;
use warnings;

package BSON::Types;
# ABSTRACT: Helper functions to wrap BSON type classes

use version;
our $VERSION = 'v1.12.2';

use base 'Exporter';
our @EXPORT_OK = qw(
    bson_bool
    bson_bytes
    bson_code
    bson_dbref
    bson_decimal128
    bson_doc
    bson_array
    bson_double
    bson_int32
    bson_int64
    bson_maxkey
    bson_minkey
    bson_oid
    bson_raw
    bson_regex
    bson_string
    bson_time
    bson_timestamp
);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

use Carp;

use boolean;            # bson_bool
use BSON::Bytes;        # bson_bytes
use BSON::Code;         # bson_code
use BSON::DBRef;        # bson_dbref
use BSON::Decimal128;   # bson_decimal128
use BSON::Doc;          # bson_doc
use BSON::Array;        # bson_array
use BSON::Double;       # bson_double
use BSON::Int32;        # bson_int32
use BSON::Int64;        # bson_int64
use BSON::MaxKey;       # bson_maxkey
use BSON::MinKey;       # bson_minkey
use BSON::OID;          # bson_oid
use BSON::Raw;          # bson_raw
use BSON::Regex;        # bson_regex
use BSON::String;       # bson_string
use BSON::Time;         # bson_time
use BSON::Timestamp;    # bson_timestamp
use BSON::Symbol;
use BSON::DBPointer;

# deprecated, but load anyway
use BSON::Bool;
use BSON::Binary;
use BSON::ObjectId;

#pod =func bson_bytes
#pod
#pod     $bytes = bson_bytes( $byte_string );
#pod     $bytes = bson_bytes( $byte_string, $subtype );
#pod
#pod This function returns a L<BSON::Bytes> object wrapping the provided string.
#pod A numeric subtype may be provided as a second argument, but this is not
#pod recommended for new applications.
#pod
#pod =cut

sub bson_bytes {
    return BSON::Bytes->new(
        data => ( defined( $_[0] ) ? $_[0] : '' ),
        subtype => ( $_[1] || 0 ),
    );
}

#pod =func bson_code
#pod
#pod     $code = bson_code( $javascript );
#pod     $code = bson_code( $javascript, $hashref );
#pod
#pod This function returns a L<BSON::Code> object wrapping the provided Javascript
#pod code.  An optional hashref representing variables in scope for the function
#pod may be given as well.
#pod
#pod =cut

sub bson_code {
    return BSON::Code->new unless defined $_[0];
    return BSON::Code->new( code => $_[0] ) unless defined $_[1];
    return BSON::Code->new( code => $_[0], scope => $_[1] );
}

#pod =func bson_dbref
#pod
#pod     $dbref = bson_dbref( $object_id, $collection_name );
#pod
#pod This function returns a L<BSON::DBRef> object wrapping the provided Object ID
#pod and collection name.
#pod
#pod =cut

sub bson_dbref {
    croak "Arguments to bson_dbref must an id and collection name"
      unless @_ == 2;
    return BSON::DBRef->new( id => $_[0], ref => $_[1] );
}

#pod =func bson_decimal128
#pod
#pod     $decimal = bson_decimal128( "0.12" );
#pod     $decimal = bson_decimal128( "1.23456789101112131415116E-412" );
#pod
#pod This function returns a L<BSON::Decimal128> object wrapping the provided
#pod decimal B<string>.  Unlike floating point values, this preserves exact
#pod decimal precision.
#pod
#pod =cut

sub bson_decimal128 {
    return BSON::Decimal128->new( value => defined $_[0] ? $_[0] : 0 )
}

#pod =func bson_doc
#pod
#pod     $doc = bson_doc( first => "hello, second => "world" );
#pod
#pod This function returns a L<BSON::Doc> object, which preserves the order
#pod of the provided key-value pairs.
#pod
#pod =cut

sub bson_doc {
    return BSON::Doc->new( @_ );
}

#pod =func bson_array
#pod
#pod     $doc = bson_array(...);
#pod
#pod This function returns a L<BSON::Array> object, which preserves the order
#pod of the provided list of elements.
#pod
#pod =cut

sub bson_array {
    return BSON::Array->new( @_ );
}

#pod =func bson_double
#pod
#pod     $double = bson_double( 1.0 );
#pod
#pod This function returns a L<BSON::Double> object wrapping a native
#pod double value.  This ensures it serializes to BSON as a double rather
#pod than a string or integer given Perl's lax typing for scalars.
#pod
#pod =cut

sub bson_double {
    return BSON::Double->new( value => $_[0] )
}

#pod =func bson_int32
#pod
#pod     $int32 = bson_int32( 42 );
#pod
#pod This function returns a L<BSON::Int32> object wrapping a native
#pod integer value.  This ensures it serializes to BSON as an Int32 rather
#pod than a string or double given Perl's lax typing for scalars.
#pod
#pod =cut

sub bson_int32 {
    return BSON::Int32->new unless defined $_[0];
    return BSON::Int32->new( value => $_[0] )
}

#pod =func bson_int64
#pod
#pod     $int64 = bson_int64( 0 ); # 64-bit zero
#pod
#pod This function returns a L<BSON::Int64> object, wrapping a native
#pod integer value.  This ensures it serializes to BSON as an Int64 rather
#pod than a string or double given Perl's lax typing for scalars.
#pod
#pod =cut

sub bson_int64 {
    return BSON::Int64->new unless defined $_[0];
    return BSON::Int64->new( value => $_[0] )
}

#pod =func bson_maxkey
#pod
#pod     $maxkey = bson_maxkey();
#pod
#pod This function returns a singleton representing the "maximum key"
#pod BSON type.
#pod
#pod =cut

sub bson_maxkey {
    return BSON::MaxKey->new;
}

#pod =func bson_minkey
#pod
#pod     $minkey = bson_minkey();
#pod
#pod This function returns a singleton representing the "minimum key"
#pod BSON type.
#pod
#pod =cut

sub bson_minkey {
    return BSON::MinKey->new;
}

#pod =func bson_oid
#pod
#pod     $oid = bson_oid();         # generate a new one
#pod     $oid = bson_oid( $bytes ); # from 12-byte packed OID
#pod     $oid = bson_oid( $hex   ); # from 24 hex characters
#pod
#pod This function returns a L<BSON::OID> object wrapping a 12-byte MongoDB Object
#pod ID.  With no arguments, a new, unique Object ID is generated instead.  If
#pod 24 hexadecimal characters are given, they will be packed into a 12-byte
#pod Object ID.
#pod
#pod =cut

sub bson_oid {
    return BSON::OID->new unless defined $_[0];
    return BSON::OID->new( oid => $_[0] ) if length( $_[0] ) == 12;
    return BSON::OID->new( oid => pack( "H*", $_[0] ) )
      if $_[0] =~ m{\A[0-9a-f]{24}\z}i;
    croak "Arguments to bson_oid must be 12 packed bytes or 24 bytes of hex";
}

#pod =func bson_raw
#pod
#pod     $raw = bson_raw( $bson_encoded );
#pod
#pod This function returns a L<BSON::Raw> object wrapping an already BSON-encoded
#pod document.
#pod
#pod =cut

sub bson_raw {
    return BSON::Raw->new( bson => $_[0] );
}

#pod =func bson_regex
#pod
#pod     $regex = bson_regex( $pattern );
#pod     $regex = bson_regex( $pattern, $flags );
#pod
#pod This function returns a L<BSON::Regex> object wrapping a PCRE pattern and
#pod optional flags.
#pod
#pod =cut

sub bson_regex {
    return BSON::Regex->new unless defined $_[0];
    return BSON::Regex->new( pattern => $_[0] ) unless defined $_[1];
    return BSON::Regex->new( pattern => $_[0], flags => $_[1] );
}

#pod =func bson_string
#pod
#pod     $string = bson_string( "08544" );
#pod
#pod This function returns a L<BSON::String> object, wrapping a native
#pod string value.  This ensures it serializes to BSON as a UTF-8 string rather
#pod than an integer or double given Perl's lax typing for scalars.
#pod
#pod =cut

sub bson_string {
    return BSON::String->new( value => $_[0] );
}

#pod =func bson_time
#pod
#pod     $time = bson_time( $seconds_from_epoch );
#pod
#pod This function returns a L<BSON::Time> object representing a UTC date and
#pod time to millisecond precision.  The argument must be given as a number of
#pod seconds relative to the Unix epoch (positive or negative).  The number may
#pod be a floating point value for fractional seconds.  If no argument is
#pod provided, the current time from L<Time::HiRes> is used.
#pod
#pod =cut

sub bson_time {
    return BSON::Time->new unless defined $_[0];
    # Old constructor format handles floating point math right on
    # 32-bit platforms.
    return BSON::Time->new( $_[0] );
}

#pod =func bson_timestamp
#pod
#pod     $timestamp = bson_timestamp( $seconds_from_epoch, $increment );
#pod
#pod This function returns a L<BSON::Timestamp> object.  It is not recommended
#pod for general use.
#pod
#pod =cut

sub bson_timestamp {
    return BSON::Timestamp->new unless defined $_[0];
    return BSON::Timestamp->new( seconds => $_[0] ) unless defined $_[1];
    return BSON::Timestamp->new( seconds => $_[0], increment => $_[1] );
}

#pod =func bson_bool (DISCOURAGED)
#pod
#pod     # for consistency with other helpers
#pod     $bool = bson_bool( $expression );
#pod
#pod     # preferred for efficiency
#pod     use boolean;
#pod     $bool = boolean( $expression );
#pod
#pod This function returns a L<boolean> object (true or false) based on the
#pod provided expression (or false if no expression is provided).  It is
#pod provided for consistency so that all BSON types have a corresponding helper
#pod function.
#pod
#pod For efficiency, use C<boolean::boolean()> directly, instead.
#pod
#pod =cut

sub bson_bool {
    return boolean($_[0]);
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Types - Helper functions to wrap BSON type classes

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    $int32   = bson_int32(42);
    $double  = bson_double(3.14159);
    $decimal = bson_decimal("24.01");
    $time    = bson_time(); # now
    ...

=head1 DESCRIPTION

This module provides helper functions for BSON type wrappers.  Type
wrappers use objects corresponding to BSON types to represent data that
would have ambiguous type or don't have a native Perl representation

For example, because Perl scalars can represent strings, integers or
floating point numbers, the serialization rules depend on various
heuristics.  By wrapping a Perl scalar with a class, such as
L<BSON::Int32>, users can specify exactly how a scalar should serialize to
BSON.

=head1 FUNCTIONS

=head2 bson_bytes

    $bytes = bson_bytes( $byte_string );
    $bytes = bson_bytes( $byte_string, $subtype );

This function returns a L<BSON::Bytes> object wrapping the provided string.
A numeric subtype may be provided as a second argument, but this is not
recommended for new applications.

=head2 bson_code

    $code = bson_code( $javascript );
    $code = bson_code( $javascript, $hashref );

This function returns a L<BSON::Code> object wrapping the provided Javascript
code.  An optional hashref representing variables in scope for the function
may be given as well.

=head2 bson_dbref

    $dbref = bson_dbref( $object_id, $collection_name );

This function returns a L<BSON::DBRef> object wrapping the provided Object ID
and collection name.

=head2 bson_decimal128

    $decimal = bson_decimal128( "0.12" );
    $decimal = bson_decimal128( "1.23456789101112131415116E-412" );

This function returns a L<BSON::Decimal128> object wrapping the provided
decimal B<string>.  Unlike floating point values, this preserves exact
decimal precision.

=head2 bson_doc

    $doc = bson_doc( first => "hello, second => "world" );

This function returns a L<BSON::Doc> object, which preserves the order
of the provided key-value pairs.

=head2 bson_array

    $doc = bson_array(...);

This function returns a L<BSON::Array> object, which preserves the order
of the provided list of elements.

=head2 bson_double

    $double = bson_double( 1.0 );

This function returns a L<BSON::Double> object wrapping a native
double value.  This ensures it serializes to BSON as a double rather
than a string or integer given Perl's lax typing for scalars.

=head2 bson_int32

    $int32 = bson_int32( 42 );

This function returns a L<BSON::Int32> object wrapping a native
integer value.  This ensures it serializes to BSON as an Int32 rather
than a string or double given Perl's lax typing for scalars.

=head2 bson_int64

    $int64 = bson_int64( 0 ); # 64-bit zero

This function returns a L<BSON::Int64> object, wrapping a native
integer value.  This ensures it serializes to BSON as an Int64 rather
than a string or double given Perl's lax typing for scalars.

=head2 bson_maxkey

    $maxkey = bson_maxkey();

This function returns a singleton representing the "maximum key"
BSON type.

=head2 bson_minkey

    $minkey = bson_minkey();

This function returns a singleton representing the "minimum key"
BSON type.

=head2 bson_oid

    $oid = bson_oid();         # generate a new one
    $oid = bson_oid( $bytes ); # from 12-byte packed OID
    $oid = bson_oid( $hex   ); # from 24 hex characters

This function returns a L<BSON::OID> object wrapping a 12-byte MongoDB Object
ID.  With no arguments, a new, unique Object ID is generated instead.  If
24 hexadecimal characters are given, they will be packed into a 12-byte
Object ID.

=head2 bson_raw

    $raw = bson_raw( $bson_encoded );

This function returns a L<BSON::Raw> object wrapping an already BSON-encoded
document.

=head2 bson_regex

    $regex = bson_regex( $pattern );
    $regex = bson_regex( $pattern, $flags );

This function returns a L<BSON::Regex> object wrapping a PCRE pattern and
optional flags.

=head2 bson_string

    $string = bson_string( "08544" );

This function returns a L<BSON::String> object, wrapping a native
string value.  This ensures it serializes to BSON as a UTF-8 string rather
than an integer or double given Perl's lax typing for scalars.

=head2 bson_time

    $time = bson_time( $seconds_from_epoch );

This function returns a L<BSON::Time> object representing a UTC date and
time to millisecond precision.  The argument must be given as a number of
seconds relative to the Unix epoch (positive or negative).  The number may
be a floating point value for fractional seconds.  If no argument is
provided, the current time from L<Time::HiRes> is used.

=head2 bson_timestamp

    $timestamp = bson_timestamp( $seconds_from_epoch, $increment );

This function returns a L<BSON::Timestamp> object.  It is not recommended
for general use.

=head2 bson_bool (DISCOURAGED)

    # for consistency with other helpers
    $bool = bson_bool( $expression );

    # preferred for efficiency
    use boolean;
    $bool = boolean( $expression );

This function returns a L<boolean> object (true or false) based on the
provided expression (or false if no expression is provided).  It is
provided for consistency so that all BSON types have a corresponding helper
function.

For efficiency, use C<boolean::boolean()> directly, instead.

=for Pod::Coverage BUILD

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
