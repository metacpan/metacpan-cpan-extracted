package Test::Encoder;

use strict;
use warnings;

use utf8 ':all';

use parent 'Crypt::Passphrase::Validator';

sub new {
    return bless {}, shift;
}

sub accepts_hash {
    my ( $self, $hash ) = @_;
    return $hash =~ /^BAD/;
}

sub hash_password {
    my ( $self, $password ) = @_;
    return "BAD$password";
}

sub needs_rehash {
    my ( $self, $hash ) = @_;
}

sub verify_password {
    my ( $self, $password, $hash ) = @_;
    return $hash eq $self->hash_password($password);
}

1;
