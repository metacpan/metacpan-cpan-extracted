#!/usr/bin/perl

package Data::UUID::LibUUID;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.05';

use Time::HiRes ();

use Sub::Exporter -setup => {
    exports => [qw(
        new_uuid_string new_uuid_binary
        
        uuid_to_binary uuid_to_string uuid_to_hex uuid_to_base64
        
        uuid_eq uuid_compare

        new_dce_uuid_string new_dce_uuid_binary

        new_uuid_str new_uuid_bin new_dce_uuid_bin new_dce_uuid_str

        ascending_ident
    )],
    groups => {
        default => [qw(new_uuid_string new_uuid_binary uuid_eq)],
    },
};

eval {
    require XSLoader;
    XSLoader::load('Data::UUID::LibUUID', $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap Data::UUID::LibUUID $VERSION;
};

# convenient aliases
*new_dce_uuid_bin = \&new_dce_uuid_binary;
*new_uuid_bin = \&new_uuid_binary;
*new_dce_uuid_str = \&new_dce_uuid_string;
*new_uuid_str = \&new_uuid_string;

sub uuid_to_base64 {
    require MIME::Base64;
    MIME::Base64::encode_base64(uuid_to_binary($_[0]), '');
}

my ( $last_s, $last_us, $i ) = ( 0, 0 );
sub ascending_ident {
    my ( $s, $us ) = Time::HiRes::gettimeofday;
    
    # usec is at most 20 bits (log 2 of 1 million), so we truncate the bottom 4
    # and use only 16 bits, with 16 more bits for a counter. decent hardware
    # can generate several of these per usec, bot not 65 thousand per 16 usecs =)

    # without $i but with a full 20 bits identifiers would be merely
    # monotonically increasing

    my $trunc_us = $us >> 4;

    if ( $last_us != $trunc_us or $last_s != $s ) {
        # the timer has increased, we can reset the counter
        $i = 0;
        $last_us = $trunc_us;
        $last_s  = $s;
    } else {
        # increment the timer, but truncate it to 16 bits

        # i've never seen it actually bigger than 2 so that gives a margin of
        # about 5 orders of magnitude. Hopefully Moore's law doesn't get me ;-)

        $i = $i+1 % 0xffff;
    }

    unpack("H*",pack("Nnn", $s, $trunc_us, $i)) . '-' . new_uuid_string();
}

__PACKAGE__

__END__

=pod

=head1 NAME

Data::UUID::LibUUID - F<uuid.h> based UUID generation (versions 2 and 4
depending on platform)

=head1 SYNOPSIS

    use Data::UUID::LibUUID;

    my $uuid = new_uuid_string();

=head1 DESCRIPTION

This module provides bindings for libuuid shipped with e2fsprogs or uuid-dev on
debian, and also works with the system F<uuid.h> on darwin.

=head1 EXPORTS

=over 4

=item new_uuid_string $version

=item new_uuid_binary $version

Returns a new UUID in string (dash separated hex) or binary (16 octets) format.

C<$version> can be either 2, or 4 and defaults to whatever the underlying
implementation prefers.

Version 1 is timestamp/MAC based UUIDs, like L<Data::UUID> provides. They
reveal time and host information, so they may be considered a security risk.

Version 2 is described here
L<http://www.opengroup.org/onlinepubs/9696989899/chap5.htm#tagcjh_08_02_01_01>.
It is similar to version 1 but considered more secure.

Version 4 is based just on random data. This is not guaranteed to be high
quality random data, but usually is supposed to be.

On MacOS X C<getpid> is called before UUID generation, to ensure UUIDs are
unique accross forks. Behavior on other platforms may vary.

=item uuid_to_binary $str_or_bin

Converts a UUID from string or binary format to binary format.

Returns undef on a non UUID argument.

=item uuid_to_string $str_or_bin

Converts a UUID from string or binary format to string format.

Returns undef on a non UUID argument.

=item uuid_eq $str_or_bin, $str_or_bin

Checks if two UUIDs are equivalent. Returns true if they are, or false if they aren't.

Returns undef on non UUID arguments.

=item uuid_compare $str_or_bin, $str_or_bin

Returns -1, 0 or 1 depending on the lexicographical order of the UUID. This
works like the C<cmp> builtin.

Returns undef on non UUID arguments.

=item new_dce_uuid_string

=item new_dce_uuid_binary

These two subroutines are a little hackish in that they take no arguments but
also do not validate the arguments, so they can be abused as methods:

    package MyFoo;

    use Data::UUID::LibUUID (
        new_dce_uuid_string => { -as "generate_uuid" },
    );

    sub yadda {
        my $self = shift;
        my $id = $self->generate_uuid;
    }

This allows the ID generation code to be subclassed, but still keeps the hassle
down to a minimum. DCE is UUID version two specification.

=item ascending_ident

Creates a lexically ascending identifier containing a UUID, high resolution
timestamp, and a counter.

This is not a UUID (it's longer), but if you can store variable length
identifier (and exposing the system clock is not an issue) they can be used to
create an identifier that is both universally unique, and lexically
increasing.

Note that while the identifiers are universally unique, there is no universal
ordering (that would require synchronization), so identifiers generated on
different machines or even different process/thread could have IDs which
interleave.

=back

=head1 TODO

=over 4

=item *

Consider bundling libuuid for when no system C<uuid.h> exists.

=back

=head1 SEE ALSO

L<Data::GUID>, L<Data::UUID>, L<UUID>, L<http://e2fsprogs.sourceforge.net/>

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008 Yuval Kogman. All rights reserved
    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut
