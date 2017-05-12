package Data::IEEE754;

use strict;
use warnings;
use utf8;

our $VERSION = '0.02';

use Config;

use Exporter qw( import );

our @EXPORT_OK = qw(
    pack_double_be
    pack_float_be
    unpack_double_be
    unpack_float_be
);

# This code is all copied from Data::MessagePack::PP by Makamaka
# Hannyaharamitu, and was then tweaked by Dave Rolsky. Blame Dave for the
# bugs.
#
# Perl 5.10 introduced the ">" and "<" modifiers for pack which can be used to
# force a specific endianness.
if ( $] < 5.010 ) {
    my $bo_is_le = ( $Config{byteorder} =~ /^1234/ );

    if ($bo_is_le) {
        *pack_float_be = sub {
            return pack( 'N1', unpack( 'V1', pack( 'f', $_[0] ) ) );
        };
        *pack_double_be = sub {
            my @v = unpack( 'V2', pack( 'd', $_[0] ) );
            return pack( 'N2', @v[ 1, 0 ] );
        };

        *unpack_float_be = sub {
            my @v = unpack( 'v2', $_[0] );
            return unpack( 'f', pack( 'n2', @v[ 1, 0 ] ) );
        };
        *unpack_double_be = sub {
            my @v = unpack( 'V2', $_[0] );
            return unpack( 'd', pack( 'N2', @v[ 1, 0 ] ) );
        };
    }
    else {    # big endian
        *pack_float_be = sub {
            return pack 'f', $_[0];
        };
        *pack_double_be = sub {
            return pack 'd', $_[0];
        };

        *unpack_float_be
            = sub { return unpack( 'f', $_[0] ); };
        *unpack_double_be
            = sub { return unpack( 'd', $_[0] ); };
    }
}
else {
    *pack_float_be = sub {
        return pack 'f>', $_[0];
    };
    *pack_double_be = sub {
        return pack 'd>', $_[0];
    };

    *unpack_float_be = sub {
        return unpack( 'f>', $_[0] );
    };
    *unpack_double_be = sub {
        return unpack( 'd>', $_[0] );
    };
}

1;

# ABSTRACT: Pack and unpack big-endian IEEE754 floats and doubles

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::IEEE754 - Pack and unpack big-endian IEEE754 floats and doubles

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Data::IEEE754 qw( pack_double_be unpack_double_be );

  my $packed = pack_double_be(3.14);
  my $double = unpack_double_be($packed);

=head1 DESCRIPTION

This module provides some simple convenience functions for packing and
unpacking IEEE 754 floats and doubles.

If you can require Perl 5.10 or greater then this module is pointless. Just
use the C<< d> >> and C<< f> >> pack formats instead!

Currently this module only implements big-endian order. Patches to add
little-endian order subroutines are welcome.

=head1 EXPORTS

This module optionally exports the following four functions:

=over 4

=item * pack_float_be($number)

=item * pack_double_be($number)

=item * unpack_float_be($binary)

=item * unpack_double_be($binary)

=back

=head1 CREDITS

The code in this module is more or less copied and pasted from
L<Data::MessagePack>'s C<Data::MessagePack::PP> module. That module was
written by Makamaka Hannyaharamitu. The code was then tweaked by Dave Rolsky,
so blame him for the bugs.

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-IEEE754 or via email at
bug-data-ieee754@rt.cpan.org.

Bugs may be submitted through L<https://github.com/maxmind/Data-IEEE754/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Greg Oschwald

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
