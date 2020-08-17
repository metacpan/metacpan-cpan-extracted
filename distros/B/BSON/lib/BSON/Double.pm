use 5.010001;
use strict;
use warnings;

package BSON::Double;
# ABSTRACT: BSON type wrapper for Double

use version;
our $VERSION = 'v1.12.2';

use Carp;

#pod =attr value
#pod
#pod A numeric scalar (or the special strings "Inf", "-Inf" or "NaN").  This
#pod will be coerced to Perl's numeric type.  The default is 0.0.
#pod
#pod =cut

use Moo;

has 'value' => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

use constant {
    nInf  => unpack("d<",pack("H*","000000000000f0ff")),
    pInf  => unpack("d<",pack("H*","000000000000f07f")),
    NaN   => unpack("d<",pack("H*","000000000000f8ff")),
};

sub BUILD {
    my $self = shift;
    # coerce to NV internally
    $self->{value} = defined( $self->{value} ) ? $self->{value} / 1.0 : 0.0;
}

#pod =method TO_JSON
#pod
#pod Returns a double.
#pod
#pod If the C<BSON_EXTJSON> environment variable is true and the
#pod C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
#pod compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$numberDouble" : "42.0"}
#pod
#pod If C<BSON_EXTJSON> is false and the value is 'Inf', '-Inf' or 'NaN'
#pod (which are illegal in regular JSON), then an exception is thrown.
#pod
#pod =cut

my $use_win32_specials = ($^O eq 'MSWin32' && $] lt "5.022");

my $win32_specials = qr/-?1.\#IN[DF]/i;
my $unix_specials = qr/-?(?:inf|nan)/i;
my $illegal = $use_win32_specials ? qr/^$win32_specials/ : qr/^$unix_specials/;

my $is_inf = $use_win32_specials ? qr/^1.\#INF/i : qr/^inf/i;
my $is_ninf = $use_win32_specials ? qr/^-1.\#INF/i : qr/^-inf/i;
my $is_nan = $use_win32_specials ? qr/^-?1.\#(?:IND|QNAN)/i : qr/^-?nan/i;

sub TO_JSON {
    my $copy = "$_[0]->{value}"; # avoid changing value to PVNV

    if ($ENV{BSON_EXTJSON} && $ENV{BSON_EXTJSON_RELAXED}) {

        return { '$numberDouble' => 'Infinity' }
            if $copy =~ $is_inf;
        return { '$numberDouble' => '-Infinity' }
            if $copy =~ $is_ninf;
        return { '$numberDouble' => 'NaN' }
            if $copy =~ $is_nan;
    }

    if ($ENV{BSON_EXTJSON} && !$ENV{BSON_EXTJSON_RELAXED}) {

        return { '$numberDouble' => 'Infinity' }
            if $copy =~ $is_inf;
        return { '$numberDouble' => '-Infinity' }
            if $copy =~ $is_ninf;
        return { '$numberDouble' => 'NaN' }
            if $copy =~ $is_nan;
        my $value = $_[0]->{value}/1.0;
        return { '$numberDouble' => "$value" };
    }

    croak( "The value '$copy' is illegal in JSON" )
        if $copy =~ $illegal;

    return $_[0]->{value}/1.0;
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

BSON::Double - BSON type wrapper for Double

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    my $bytes = bson_double( $number );

=head1 DESCRIPTION

This module provides a BSON type wrapper for a numeric value that
would be represented in BSON as a double.

=head1 ATTRIBUTES

=head2 value

A numeric scalar (or the special strings "Inf", "-Inf" or "NaN").  This
will be coerced to Perl's numeric type.  The default is 0.0.

=head1 METHODS

=head2 TO_JSON

Returns a double.

If the C<BSON_EXTJSON> environment variable is true and the
C<BSON_EXTJSON_RELAXED> environment variable is false, returns a hashref
compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$numberDouble" : "42.0"}

If C<BSON_EXTJSON> is false and the value is 'Inf', '-Inf' or 'NaN'
(which are illegal in regular JSON), then an exception is thrown.

=for Pod::Coverage BUILD nInf pInf NaN

=head1 INFINITY AND NAN

Some Perls may not support converting "Inf" or "NaN" strings to their
double equivalent.  They are available as functions from the L<POSIX>
module, but as a lighter alternative to POSIX, the following functions are
available:

=over 4

=item *

BSON::Double::pInf() – positive infinity

=item *

BSON::Double::nInf() – negative infinity

=item *

BSON::Double::NaN() – not-a-number

=back

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
