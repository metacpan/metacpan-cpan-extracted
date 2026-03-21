package Crypt::RIPEMD160::MAC;

use Crypt::RIPEMD160 0.03;

use strict;
use warnings;

our $VERSION = '0.09';

sub new {
    my($pkg, $key) = @_;

    my $self = {
	'key' => $key,
	'hash' => Crypt::RIPEMD160->new,
	'k_ipad' => chr(0x36) x 64,
	'k_opad' => chr(0x5c) x 64,
	};

    bless $self, $pkg;

    if (length($self->{'key'}) > 64) {
	$self->{'key'} = Crypt::RIPEMD160->hash($self->{'key'});
    }

    $self->{'k_ipad'} ^= $self->{'key'};
    $self->{'k_opad'} ^= $self->{'key'};

    $self->{'hash'}->add($self->{'k_ipad'});

    return $self;
}

sub reset {
    my($self) = @_;

    $self->{'hash'}->reset();
    $self->{'k_ipad'} = chr(0x36) x 64;
    $self->{'k_opad'} = chr(0x5c) x 64;

    if (length($self->{'key'}) > 64) {
	$self->{'key'} = Crypt::RIPEMD160->hash($self->{'key'});
    }

    $self->{'k_ipad'} ^= $self->{'key'};
    $self->{'k_opad'} ^= $self->{'key'};

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
    while (read($handle, $data, 8192)) {
	$self->{'hash'}->add($data);
    }
}

sub mac {
    my($self) = @_;

    my($inner) = $self->{'hash'}->digest();

    my($outer) = Crypt::RIPEMD160->hash($self->{'k_opad'}.$inner);

    $self->{'key'} = "";
    $self->{'k_ipad'} = "";
    $self->{'k_opad'} = "";

    return($outer);
}

sub hexmac {
    my($self) = @_;

    my($inner) = $self->{'hash'}->digest();

    my($outer) = Crypt::RIPEMD160->hexhash($self->{'k_opad'}.$inner);

    $self->{'key'} = "";
    $self->{'k_ipad'} = "";
    $self->{'k_opad'} = "";

    return($outer);
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

Note that both B<mac> and B<hexmac> are destructive operations that
clear the key material. To compute another MAC, create a new context
or call B<reset>.

=head1 EXAMPLES

    use Crypt::RIPEMD160::MAC;

    $mac = Crypt::RIPEMD160::MAC->new("secret key");
    $mac->add("some data");
    $digest = $mac->mac();

    print("MAC is " . unpack("H*", $digest) . "\n");

=head1 AUTHOR

The RIPEMD-160 interface was written by Christian H. Geuer 
(C<christian.geuer@crypto.gun.de>).

=head1 SEE ALSO

MD5(3pm) and SHA(1).

=cut
