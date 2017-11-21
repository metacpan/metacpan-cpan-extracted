package Argon::Encryption;
# ABSTRACT: Role providing methods and attributes to encrypt Argon::Message traffic
$Argon::Encryption::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Crypt::CBC;
use Path::Tiny qw(path);
use Argon::Types;

my %CIPHER;


has keyfile => (
  is  => 'ro',
  isa => 'Ar::FilePath',
);


has key => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_key',
);

sub _build_key {
  my $self = shift;
  croak 'keyfile required if key is not specified'
    unless $self->keyfile;
  path($self->keyfile)->slurp_raw;
}

has cipher => (
  is      => 'ro',
  isa     => 'Crypt::CBC',
  lazy    => 1,
  builder => '_build_cipher',
  handles => {
    encrypt => 'encrypt_hex',
    decrypt => 'decrypt_hex',
  },
);

sub _build_cipher {
  my $self = shift;

  $CIPHER{$self->key} ||= Crypt::CBC->new(
    -key    => $self->key,
    -cipher => 'Rijndael',
    -salt   => 1,
  );

  $CIPHER{$self->key};
}


has token => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => 'create_token',
);

sub create_token {
  my $self = shift;
  unpack 'H*', $self->cipher->random_bytes(8);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Encryption - Role providing methods and attributes to encrypt Argon::Message traffic

=head1 VERSION

version 0.18

=head1 DESCRIPTION

Role that provides for encrypting messages in the Argon system. Notably
provides the C<keyfile>, C<key>, and C<token> attributes.

=head1 ATTRIBUTES

=head2 keyfile

The path to a file containing the encryption pass phrase. Either L</key> or
C<keyfile> must be provided when instantiating a class implementing
C<Argon::Encryption>.

=head2 key

The encryption pass phrase.

=head2 token

A string of random bytes used as a channel or service identifier.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
