package Crypt::RNCryptor;
use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

our $DefaultRNCryptorVersion = '3';
our @SupportedRNCryptorVersions = qw(3);

sub new {
    my ($class, %opts) = @_;
    $opts{version} ||= $DefaultRNCryptorVersion;
    foreach my $v (@SupportedRNCryptorVersions) {
        if ($opts{version} eq $v) {
            my $Class = "Crypt::RNCryptor::V${v}";
            eval "require $Class";
            return $Class->new(%opts);
        }
    }
    my $v = $opts{version};
    confess "RNCryptor v$v is not supported.";
}

sub encrypt {
    confess 'This is an abstract method.';
}

sub decrypt {
    confess 'This is an abstract method.';
}

1;
__END__

=encoding utf-8

=head1 NAME

Crypt::RNCryptor - Perl implementation of L<RNCryptor|https://github.com/RNCryptor/RNCryptor>

=head1 SYNOPSIS

    use Crypt::RNCryptor;

    # generate password-based encryptor
    $cryptor = Crypt::RNCryptor->new(
        password => 'secret password',
    );

    # generate key-based encryptor
    $cryptor = Crypt::RNCryptor->new(
        encryption_key => '',
        hmac_key => '',
    );

    # encrypt
    $ciphertext = $cryptor->encrypt('plaintext');

    # decrypt
    $plaintext = $cryptor->decrypt($ciphertext);

=head1 DESCRIPTION

Crypt::RNCryptor is a Perl implementation of RNCryptor,
which is one of data format for AES-256 (CBC mode) encryption.

Crypt::RNCryptor class is the base of Crypt::RNCryptor::V* class
and declare some abstract methods.

=head1 METHODS

=head2 CLASS METHODS

=over 4

=item my $cryptor = Crypt::RNCryptor->new(%opts);

Create a cryptor instance.

    %opts = (
        # RNCryptor version. Currently support only version 3)
        version => $Crypt::RNCryptor::DefaultRNCryptorVersion,
        # See Crypt::RNCryptor::V*
        %version_dependent_opts
    );

=back

=head2 INSTANCE METHODS

=over 4

=item $ciphertext = $cryptor->encrypt($plaintext, %version_dependent_opts)

Encrypt plaintext with options.

=item $plaintext = $cryptor->decrypt($ciphertext, %version_dependent_opts)

Decrypt ciphertext with options.

=back

=head2 MODULE VARIABLES

=over 4

=item $Crypt::RNCryptor::DefaultRNCryptorVersion = '3'

Default RNCryptor version.

=item @Crypt::RNCryptor::DefaultRNCryptorVersion

List of supporting RNCryptor versions.

=back

=head1 LICENSE

Copyright (C) Shintaro Seki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shintaro Seki E<lt>s2pch.luck@gmail.comE<gt>

=cut
