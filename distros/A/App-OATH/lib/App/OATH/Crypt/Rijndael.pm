package App::OATH::Crypt::Rijndael;
our $VERSION = '1.20151002'; # VERSION

use strict;
use warnings;
use Convert::Base32;
use Crypt::Rijndael;
use Digest::MD5;
use String::Random qw{ random_string };

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        'password' => $args->{'password'},
    };
    bless $self, $class;
    return $self;
}

sub _get_crypt_object {
    my ( $self ) = @_;
    my $password = $self->{'password'};

    my $md5 = Digest::MD5->new();
    $md5->add( $password );
    my $crypt_key = $md5->digest();

    my $crypt = Crypt::Rijndael->new( $crypt_key, Crypt::Rijndael::MODE_CBC() );
    return $crypt;
}

sub encrypt {
    my ( $self, $data ) = @_;
    my $worker = $self->_get_crypt_object();
    my $pad = random_string( '.' x ( 16 - ( length( $data ) % 16 ) ) );

    my $e = $worker->encrypt( $pad . $data );
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

App::OATH::Crypt::Rijndael - Crypto modules for Simple OATH authenticator

=head1 DESCRIPTION

Crypto modules for basic Rijndael

=head1 SYNOPSIS

Handles encryption and decryption for the basic Rijndael (not CBC) ciphers

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
  Crypt::Rijndael
  Digest::MD5
  String::Random

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

