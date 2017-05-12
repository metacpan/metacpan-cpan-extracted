package Crypt::RNCryptor::V3;
use strict;
use warnings;
use parent 'Crypt::RNCryptor';
use Carp;
use Crypt::PBKDF2;
use Crypt::CBC;
use Digest::SHA qw(hmac_sha256);

use constant {
    VERSION => 3,
    # option
    OPTION_USE_PASSWORD => 1,
    OPTION_NOT_USE_PASSWORD => 0,
    # size
    VERSION_SIZE => 1,
    OPTIONS_SIZE => 1,
    ENCRYPTION_SALT_SIZE => 8,
    HMAC_SALT_SIZE => 8,
    IV_SIZE => 16,
    HMAC_SIZE => 32,
    # PBKDF2
    DEFAULT_PBKDF2_ITERATIONS => 10000,
    PBKDF2_OUTPUT_SIZE => 32,
};

use Class::Accessor::Lite (
    ro => [qw(
        password pbkdf2_iterations
        encryption_key hmac_key
    )],
);

sub new {
    my ($class, %opts) = @_;
    if ($opts{password} && ($opts{encryption_key} || $opts{hmac_key})) {
        confess 'Cannot set the "password" option with "encryption_key" or "hmac_key" option.';
    }
    if ($opts{pbkdf2_iterations}) {
        confess 'v3.1 is not supported still yet.';
    }
    bless {
        password => $opts{password},
        encryption_key => $opts{encryption_key},
        hmac_key => $opts{hmac_key},
        pbkdf2_iterations => DEFAULT_PBKDF2_ITERATIONS,
    }, $class;
}

sub pbkdf2 {
    my ($self, $password, $salt, $iterations) = @_;
    $iterations ||= $self->pbkdf2_iterations;
    Crypt::PBKDF2->new(
        hash_class => 'HMACSHA1',
        iterations => $iterations,
        output_len => PBKDF2_OUTPUT_SIZE,
    )->PBKDF2($salt, $password);
}

sub aes256cbc {
    my ($self, $encryption_key, $iv) = @_;
    Crypt::CBC->new(
        -literal_key => 1,
        -key => $encryption_key,
        -iv => $iv,
        -header => 'none',
        -cipher => 'Crypt::OpenSSL::AES',
    );
}

sub make_options {
    my ($self, $use_password, $pbkdf2_iterations) = @_;
    confess 'TODO';
}

sub encrypt {
    my $self = shift;
    return $self->encrypt_with_password(@_) if $self->password;
    return $self->encrypt_with_keys(@_) if $self->encryption_key && $self->hmac_key;
    confess 'Cannot encrypt.';
}

sub encrypt_with_password {
    my ($self, $plaintext, %opts) = @_;
    my $iv = $opts{iv} || Crypt::CBC->random_bytes(IV_SIZE);
    my $encryption_salt = $opts{encryption_salt} || Crypt::CBC->random_bytes(ENCRYPTION_SALT_SIZE);
    my $hmac_salt = $opts{hmac_salt} || Crypt::CBC->random_bytes(HMAC_SALT_SIZE);
    my $password = $opts{password} || $self->password;
    my $pbkdf2_iterations = $opts{pbkdf2_iterations} || $self->pbkdf2_iterations;

    my $encryption_key = $self->pbkdf2($password, $encryption_salt);
    my $hmac_key = $self->pbkdf2($password, $hmac_salt);

    # Header = 3 || 1 || EncryptionSalt || HMACSalt || IV
    my $header = pack('CCa*a*a*', VERSION, OPTION_USE_PASSWORD, $encryption_salt, $hmac_salt, $iv);
    # Ciphertext = AES256(plaintext, ModeCBC, IV, EncryptionKey)
    my $ciphertext = $self->aes256cbc($encryption_key, $iv)->encrypt($plaintext);
    my $cipherdata = pack('a*a*', $header, $ciphertext);
    # HMAC = HMAC(Header || Ciphertext, HMACKey, SHA-256)
    my $hmac = hmac_sha256($cipherdata, $hmac_key);
    # Message = Header || Ciphertext || HMAC
    pack('a*a*', $cipherdata, $hmac);
}

sub encrypt_with_keys {
    my ($self, $plaintext, %opts) = @_;
    my $iv = $opts{iv} || Crypt::CBC->random_bytes(IV_SIZE);
    my $encryption_key = $opts{encryption_key} || $self->encryption_key;
    my $hmac_key = $opts{hmac_key} || $self->hmac_key;
    # Header = 3 || 0 || IV
    my $header = pack('CCa*', VERSION, OPTION_NOT_USE_PASSWORD, $iv);
    # Ciphertext = AES256(plaintext, ModeCBC, IV, EncryptionKey)
    my $ciphertext = $self->aes256cbc($encryption_key, $iv)->encrypt($plaintext);
    my $cipherdata = pack('a*a*', $header, $ciphertext);
    # HMAC = HMAC(Header || Ciphertext, HMACKey, SHA-256)
    my $hmac = hmac_sha256($cipherdata, $hmac_key);
    # Message = Header || Ciphertext || HMAC
    pack('a*a*', $cipherdata, $hmac);
}

sub decrypt {
    my $self = shift;
    return $self->decrypt_with_password(@_) if $self->password;
    return $self->decrypt_with_keys(@_) if $self->encryption_key && $self->hmac_key;
    confess 'Cannot decrypt.';
}

sub decrypt_with_password {
    my ($self, $message, %opts) = @_;
    my $password = $opts{password} || $self->password;
    my ($header, $ciphertext, $hmac) = do {
        my $header_size = VERSION_SIZE + OPTIONS_SIZE + ENCRYPTION_SALT_SIZE + HMAC_SALT_SIZE + IV_SIZE;
        my $fmt = sprintf('a%da%da%d',
            $header_size,
            length($message) - $header_size - HMAC_SIZE,
            HMAC_SIZE);
        unpack($fmt, $message);
    };
    my ($version, $options, $encryption_salt, $hmac_salt, $iv) = do {
        my $fmt = sprintf('CCa%da%da%d', ENCRYPTION_SALT_SIZE, HMAC_SALT_SIZE, IV_SIZE);
        unpack($fmt, $header);
    };

    # compare HMAC
    my $hmac_key = $self->pbkdf2($password, $hmac_salt);
    my $computed_hmac = hmac_sha256(pack('a*a*', $header, $ciphertext), $hmac_key);
    die "HMAC is not matched.\n" unless $computed_hmac eq $hmac;

    # decrypt
    my $encryption_key = $self->pbkdf2($password, $encryption_salt);
    $self->aes256cbc($encryption_key, $iv)->decrypt($ciphertext);
}

sub decrypt_with_keys {
    my ($self, $message, %opts) = @_;
    my $encryption_key = $opts{encryption_key} || $self->encryption_key;
    my $hmac_key = $opts{hmac_key} || $self->hmac_key;

    my ($header, $ciphertext, $hmac) = do {
        my $header_size = VERSION_SIZE + OPTIONS_SIZE + IV_SIZE;
        my $fmt = sprintf('a%da%da%d',
            $header_size,
            length($message) - $header_size - HMAC_SIZE,
            HMAC_SIZE);
        unpack($fmt, $message);
    };
    my ($version, $options, $iv) = do {
        my $fmt = sprintf('CCa%d', IV_SIZE);
        unpack($fmt, $header);
    };

    # compare HMAC
    my $computed_hmac = hmac_sha256(pack('a*a*', $header, $ciphertext), $hmac_key);
    die "HMAC is not matched.\n" unless $computed_hmac eq $hmac;

    # Plaintext = AES256Decrypt(Ciphertext, ModeCBC, IV, EncryptionKey)
    $self->aes256cbc($encryption_key, $iv)->decrypt($ciphertext);
}

1;

__END__

=encoding utf-8

=head1 NAME

Crypt::RNCryptor::V3 - Implementation of RNCyrptor v3.

=head1 SYNOPSIS

    use Crypt::RNCryptor::V3;

    # generate password-based encryptor
    $cryptor = Crypt::RNCryptor::V3->new(
        password => 'secret password',
    );

    # generate key-based encryptor
    $cryptor = Crypt::RNCryptor::V3->new(
        encryption_key => '',
        hmac_key => '',
    );

    # encrypt
    $ciphertext = $cryptor->encrypt('plaintext');

    # decrypt
    $plaintext = $cryptor->decrypt($ciphertext);

=head1 METHODS

=head2 CLASS METHODS

=over 4

=item my $cryptor = Crypt::RNCryptor->new(%opts);

Create a cryptor instance.

    %opts = (
        password => 'any length password',
        pbkdf2_iterations => DEFAULT_PBKDF2_ITERATIONS,
        # or
        encryption_key => '32 length key',
        hmac_key => '32 length key',
    );

=back

=head2 INSTANCE METHODS

=over 4

=item $ciphertext = $cryptor->encrypt($plaintext)

Encrypt plaintext with options.

=item $plaintext = $cryptor->decrypt($ciphertext)

Decrypt ciphertext with options.

=back

=head1 LICENSE

Copyright (C) Shintaro Seki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shintaro Seki E<lt>s2pch.luck@gmail.comE<gt>

=head1 SEE ALSO

L<RNCryptor-Spec-v3|https://github.com/RNCryptor/RNCryptor-Spec/blob/master/RNCryptor-Spec-v3.md>,
L<RNCryptor-Spec-v3.1 Draft|https://github.com/RNCryptor/RNCryptor-Spec/blob/master/draft-RNCryptor-Spec-v3.1.md>

=cut
