package Blockchain::Ethereum::Keystore::File;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum keystore file abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.021';          # VERSION

use Carp;
use JSON::MaybeXS;
use Crypt::PRNG;
use Crypt::Mode::CTR;
use Crypt::Digest::Keccak256 qw(keccak256);
use Scalar::Util             qw(blessed);
use Data::UUID;

use Blockchain::Ethereum::Key;
use Blockchain::Ethereum::Keystore::KDF;

my $json = JSON::MaybeXS->new(
    utf8      => 1,
    pretty    => 1,
    canonical => 1
);

sub from_key {
    my ($class, $key) = @_;

    croak 'key must be a Blockchain::Ethereum::Key instance'
        unless blessed $key && $key->isa('Blockchain::Ethereum::Key');

    my $self = bless {private_key => $key}, $class;
    return $self;
}

sub from_file {
    my ($class, $file_path, $password) = @_;

    my $self = bless {}, $class;

    my $content;
    {
        open my $fh, '<:raw', $file_path
            or croak "Could not read file '$file_path': $!";
        local $/;    # Enable slurp mode
        $content = <$fh>;
        close $fh;
    }
    my $decoded = $json->decode(lc $content);

    croak 'Version not supported'                        unless $decoded->{version} && $decoded->{version} == 3;
    croak 'Password is required to decrypt the keystore' unless defined $password;
    $self->{password} = $password;

    return $self->_from_v3($decoded);
}

sub cipher {
    shift->{cipher} //= Crypt::Mode::CTR->new('AES', 1);
}

sub ciphertext {
    my $self = shift;
    $self->{ciphertext} //= $self->_generate_ciphertext;
}

sub mac {
    my $self = shift;
    $self->{mac} //= $self->_generate_mac;

}

sub version {
    shift->{version} //= 3;
}

sub iv {
    my $self = shift;
    $self->{iv} //= $self->_generate_random_iv;
}

sub kdf {
    my $self = shift;
    $self->{kdf} //= $self->_generate_kdf;
}

sub id {
    my $self = shift;
    $self->{id} //= $self->_generate_id;
}

sub private_key {
    shift->{private_key};
}

sub password {
    shift->{password};
}

sub _from_v3 {
    my ($self, $object) = @_;

    my $crypto = $object->{crypto};

    $self->{ciphertext} = $crypto->{ciphertext};
    $self->{mac}        = $crypto->{mac};
    $self->{iv}         = $crypto->{cipherparams}->{iv};
    $self->{version}    = $object->{version};
    $self->{id}         = $object->{id};

    my $header = $crypto->{kdfparams};

    $self->{kdf} = Blockchain::Ethereum::Keystore::KDF->new(
        algorithm => $crypto->{kdf},     #
        dklen     => $header->{dklen},
        n         => $header->{n},
        p         => $header->{p},
        r         => $header->{r},
        c         => $header->{c},
        prf       => $header->{prf},
        salt      => $header->{salt});

    $self->{private_key} = $self->_generate_private_key unless $self->private_key;
    $self->_verify_mac;

    return $self;
}

sub _verify_mac {
    my ($self) = @_;

    my $computed_mac = $self->_generate_mac;
    my $expected_mac = $self->mac;

    croak "Invalid password or corrupted keystore"
        unless lc $computed_mac eq lc $expected_mac;
}

sub _generate_mac {
    my ($self) = @_;

    my $derived_key = $self->kdf->decode($self->password);
    my $mac_key     = substr($derived_key, 16, 16);

    return unpack "H*", keccak256($mac_key . pack("H*", $self->ciphertext));
}

sub _generate_private_key {
    my ($self) = @_;

    my $derived_key = $self->kdf->decode($self->password);
    my $cipher_key  = substr($derived_key, 0, 16);

    my $key = $self->cipher->decrypt(pack("H*", $self->ciphertext), $cipher_key, pack("H*", $self->iv));

    return Blockchain::Ethereum::Key->new(private_key => $key);
}

sub _generate_random_iv {
    my $iv = Crypt::PRNG::random_bytes(16);
    return unpack "H*", $iv;
}

sub _generate_kdf {
    my ($self) = @_;

    my ($derived_key, $salt, $N, $r, $p) = Crypt::ScryptKDF::_scrypt_extra($self->password);
    return Blockchain::Ethereum::Keystore::KDF->new(
        algorithm => 'scrypt',
        dklen     => length $derived_key,
        n         => $N,
        p         => $p,
        r         => $r,
        salt      => unpack 'H*',
        $salt
    );
}

sub _generate_ciphertext {
    my ($self) = @_;

    my $derived_key = $self->kdf->decode($self->password);
    my $cipher_key  = substr($derived_key, 0, 16);

    my $encrypted = $self->cipher->encrypt($self->private_key->export, $cipher_key, pack("H*", $self->iv));
    return unpack "H*", $encrypted;
}

sub _generate_id {
    my $uuid = Data::UUID->new->create_str();
    $uuid =~ s/-//g;    # Remove hyphens for Ethereum format
    return lc($uuid);
}

sub write_to_file {
    my ($self, $file_path, $password) = @_;

    if ($password) {
        $self->{password} = $password;

        # regenerate required fields for password change
        delete $self->{$_} for qw(kdf iv ciphertext mac);
    }

    croak 'Password is required to encrypt the keystore'
        unless defined $self->password;

    my $file = {
        "crypto" => {
            "cipher"       => 'aes-128-ctr',
            "cipherparams" => {"iv" => $self->iv},
            "ciphertext"   => $self->ciphertext,
            "kdf"          => $self->kdf->algorithm,
            "kdfparams"    => {
                "dklen" => $self->kdf->dklen,
                "n"     => $self->kdf->n,
                "p"     => $self->kdf->p,
                "r"     => $self->kdf->r,
                "salt"  => $self->kdf->salt
            },
            "mac" => $self->mac
        },
        "id"      => $self->id,
        "version" => 3
    };

    open my $fh, '>:raw', $file_path
        or croak "Could not write to file '$file_path': $!";
    print $fh $json->encode($file);
    close $fh;

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore::File - Ethereum keystore file abstraction

=head1 VERSION

version 0.021

=head1 SYNOPSIS

    use Blockchain::Ethereum::Keystore::File;
    use Blockchain::Ethereum::Key;

    # Create a new keystore from a private key
    my $private_key = Blockchain::Ethereum::Key->new(
        private_key => $key_bytes
    );
    
    my $keystore = Blockchain::Ethereum::Keystore::File->new(
        private_key => $private_key,
        password    => 'my_secure_password'
    );

    # Save to file
    $keystore->write_to_file('/path/to/keystore.json');

    # Load from existing keystore file
    my $loaded = Blockchain::Ethereum::Keystore::File->from_file(
        '/path/to/keystore.json', 
        'my_secure_password'
    );

    # Change password and save
    $loaded->write_to_file('/path/to/new_keystore.json', 'new_password');

    # Access keystore properties
    my $private_key = $loaded->private_key;
    my $address = $private_key->address;

=head1 OVERVIEW

This module provides a way to create, read, and write Ethereum keystore files (version 3).
Ethereum keystores are encrypted JSON files that securely store private keys using 
password-based encryption with scrypt key derivation and AES-128-CTR cipher.

The module supports:

=over 4

=item * Creating new keystores from private keys

=item * Loading existing keystore files

=item * Password verification and changing

=item * Proper MAC validation for security

=back

=head1 METHODS

=head2 from_key

Load a keystore from an existing private key.

    my $key = Blockchain::Ethereum::Key->new(
        private_key => $key_bytes
    );
    my $keystore = Blockchain::Ethereum::Keystore::File->from_key($key);

=over 4

=item * C<key> - A Blockchain::Ethereum::Key instance (required)

=back

Returns a keystore object with the loaded private key and parameters.

=head2 from_file

Load a keystore from an existing file.

    my $keystore = Blockchain::Ethereum::Keystore::File->from_file(
        '/path/to/keystore.json',
        'password'
    );

=over 4

=item * C<file_path> - Path to the keystore JSON file (required)

=item * C<password> - Password to decrypt the keystore (required)

=back

Returns a keystore object with the loaded private key and parameters.

=head2 write_to_file

Write the keystore to a file, optionally with a new password.

    # Write with current password
    $keystore->write_to_file('/path/to/output.json');

    # Write with new password
    $keystore->write_to_file('/path/to/output.json', 'new_password');

=over 4

=item * C<file_path> - Path where to save the keystore file (required)

=item * C<password> - New password to encrypt with (optional)

=back

If a new password is provided, the keystore will be re-encrypted with the new password
while keeping the same private key.

Returns true on success, throws an exception on failure.

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
