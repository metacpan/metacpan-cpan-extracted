package Crypt::CBC;
use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    my $self = \%args;
    bless $self, $class;
    return $self;
}

sub encrypt_hex {
    my ( $self, $plain_text ) = @_;
    my $mock_crypt_text = join q{:}, $self->{'-cipher'}, $self->{'-key'},$plain_text;
    my $as_hex = unpack 'H*', $mock_crypt_text; 
    return $as_hex;
}

sub decrypt_hex {
    my ($self, $hex_text) = @_;
    my $plain_text = pack 'H*', $hex_text;
    return $plain_text;
}

1;
