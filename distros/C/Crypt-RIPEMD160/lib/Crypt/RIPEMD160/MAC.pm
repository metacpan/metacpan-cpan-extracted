package Crypt::RIPEMD160::MAC;

use Crypt::RIPEMD160 0.03;

use strict;
use warnings;
use Carp;

our $VERSION = '0.13';

sub new {
    my($pkg, $key) = @_;

    # Hash long keys per RFC 2104
    if (length($key) > 64) {
	$key = Crypt::RIPEMD160->hash($key);
    }

    my $k_ipad = chr(0x36) x 64;
    my $k_opad = chr(0x5c) x 64;
    $k_ipad ^= $key;
    $k_opad ^= $key;

    my $self = {
	'key' => $key,
	'hash' => Crypt::RIPEMD160->new,
	'k_ipad' => $k_ipad,
	'k_opad' => $k_opad,
	};

    bless $self, $pkg;

    $self->{'hash'}->add($self->{'k_ipad'});

    return $self;
}

sub reset {
    my($self) = @_;

    $self->{'hash'}->reset();
    $self->{'hash'}->add($self->{'k_ipad'});

    return $self;
}

sub add {
    my($self, @data) = @_;

    $self->{'hash'}->add(@data);

    return $self;
}

sub addfile
{
    my ($self, $handle) = @_;

    binmode($handle);
    $self->{'hash'}->addfile($handle);

    return $self;
}

sub DESTROY {
    my($self) = @_;

    # Best-effort zeroing of key material in Perl scalars.
    # Not as reliable as C-level secure_memzero (Perl may keep
    # copies via COW or realloc), but better than leaving keys
    # in memory until GC reclaims the storage.
    for my $field (qw(key k_ipad k_opad)) {
        if (defined $self->{$field}) {
            $self->{$field} = "\x00" x length($self->{$field});
            $self->{$field} = '';
        }
    }
}

sub mac {
    my($self) = @_;

    my($inner) = $self->{'hash'}->digest();

    return Crypt::RIPEMD160->hash($self->{'k_opad'}.$inner);
}

sub hexmac {
    my($self) = @_;

    my($inner) = $self->{'hash'}->digest();

    return Crypt::RIPEMD160->hexhash($self->{'k_opad'}.$inner);
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Crypt::RIPEMD160::MAC - Perl extension for RIPEMD-160 MAC function

=head1 SYNOPSIS

    use Crypt::RIPEMD160::MAC;
    
    $key = "This is the secret key";

    $mac = Crypt::RIPEMD160::MAC->new($key);

    $mac->reset();
    
    $mac->add(LIST);
    $mac->addfile(HANDLE);
    
    $digest = $mac->mac();
    $string = $mac->hexmac();

=head1 DESCRIPTION

The B<Crypt::RIPEMD160::MAC> module implements HMAC-RIPEMD-160 message
authentication codes as described in RFC 2104. It uses
L<Crypt::RIPEMD160> as the underlying hash function.

=head1 METHODS

=head2 new

    my $mac = Crypt::RIPEMD160::MAC->new($key);

Creates and returns a new HMAC-RIPEMD-160 context keyed with C<$key>.
Keys longer than 64 bytes are hashed with RIPEMD-160 before use, as
specified by RFC 2104.

=head2 reset

    $mac->reset();

Reinitializes the context for a new computation while retaining the
original key. Must be called after B<mac> or B<hexmac> before reusing
the same context.

=head2 add

    $mac->add(LIST);

Appends the strings in I<LIST> to the message. Multiple calls are
equivalent to a single call with the concatenation of all arguments.

=head2 addfile

    $mac->addfile(HANDLE);

Reads from the open file-handle in 8192 byte blocks and adds the
contents to the context. The handle can be a lexical filehandle, a
type-glob reference, or a bare name.

=head2 mac

    my $digest = $mac->mac();

Returns the final MAC value as a 20-byte binary string. This is a
destructive, read-once operation: call B<reset> before computing
another MAC with the same key.

=head2 hexmac

    my $string = $mac->hexmac();

Like B<mac>, but returns the result as a printable string of
hexadecimal digits in five space-separated groups of eight characters.

=head1 EXAMPLES

    use Crypt::RIPEMD160::MAC;

    $mac = Crypt::RIPEMD160::MAC->new("secret key");
    $mac->add("some data");
    $digest = $mac->mac();

    print("MAC is " . unpack("H*", $digest) . "\n");

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl you may have available.

See L<https://dev.perl.org/licenses/> for more information.

=head1 AUTHOR

The RIPEMD-160 interface was written by Christian H. Geuer
(C<christian.geuer@crypto.gun.de>).

=head1 SEE ALSO

L<Crypt::RIPEMD160>

=cut
