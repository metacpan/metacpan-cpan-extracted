package App::OATH::Crypt::CBC;
our $VERSION = '1.20151002'; # VERSION

use strict;
use warnings;
use Convert::Base32;
use Crypt::CBC;
use Digest::MD5;

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        'password' => $args->{'password'},
        'type'     => $args->{'type'},
    };
    bless $self, $class;
    return $self;
}

sub _get_crypt_object {
    my ( $self ) = @_;
    my $password = $self->{'password'};

    my $crypt = Crypt::CBC->new({
        'key'    => $password,
        'cipher' => $self->{'type'},
        'salt'   => 1,
    });
    return $crypt;
}

sub encrypt {
    my ( $self, $data ) = @_;
    my $worker = $self->_get_crypt_object();
    my $e = $worker->encrypt( $data );
    $e = encode_base32( $e );
    return $e;
}

sub decrypt {
    my ( $self, $data ) = @_;
    my $worker = $self->_get_crypt_object();
    my $e = decode_base32( $data );
    my $u = $worker->decrypt($e);
    return $u;
}

1;

__END__

=head1 NAME

App::OATH::Crypt::CBC - Crypto modules for Simple OATH authenticator

=head1 DESCRIPTION

Crypto modules for CBC methods, this includes Rijndael and Blowfish

=head1 SYNOPSIS

Handles encryption and decryption for CBC Rijndael and Blowfish ciphers

=head1 METHODS

=over

=item I<new()>

Instantiate a new object

=item I<encrypt($data)>

Encrypt the given data

=item I<decrypt($data)>

Decrypt the given data

=back

=head1 DEPENDENCIES

  Convert::Base32
  Crypt::Blowfish
  Crypt::CBC
  Crypt::Rijndael
  Digest::MD5
  String::Random

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

