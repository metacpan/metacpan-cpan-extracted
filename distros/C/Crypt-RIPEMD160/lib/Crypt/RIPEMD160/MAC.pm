package Crypt::RIPEMD160::MAC;

use Crypt::RIPEMD160 0.03;

use strict;
use warnings;
use Carp;

our $VERSION = '0.12';

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
}

sub addfile
{
    no strict 'refs';
    my ($self, $handle) = @_;
    my ($package, $file, $line) = caller;
    my ($data);

    if (!ref($handle)) {
	$handle = $package . "::" . $handle unless ($handle =~ /(\:\:|\')/);
    }
    my $n;
    while ($n = read($handle, $data, 8192)) {
	$self->{'hash'}->add($data);
    }
    croak "addfile read failed: $!" unless defined $n;
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

A new MAC context is created with B<new>, passing the secret key as
argument. Data is fed into the context with B<add> (which accepts a
list of strings) or B<addfile> (which reads from a file handle).
The final MAC value is returned by B<mac> as a 20-byte binary string,
or by B<hexmac> as a human-readable hex string.

Note that both B<mac> and B<hexmac> are destructive, read-once
operations on the accumulated data. To compute another MAC with the
same key, call B<reset> and then B<add> new data.

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
