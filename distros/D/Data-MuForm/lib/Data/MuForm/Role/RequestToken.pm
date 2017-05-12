package Data::MuForm::Role::RequestToken;
# ABSTRACT: Role to incluse a token for csrf protection
use Moo::Role;
use Data::MuForm::Meta;

use Crypt::CBC;
use MIME::Base64 ('decode_base64', 'encode_base64');
use Try::Tiny;

has 'token_expiration_time' => ( is => 'rw', lazy => 1, builder => 'build_token_expiration_time' );
sub build_token_expiration_time { '3600' }
has 'token_prefix' => ( is => 'rw', builder => 'build_token_prefix' );
sub build_token_prefix { '' }
has 'crypto_key' => ( is => 'rw', lazy => 1, builder => 'build_crypto_key' );
sub build_crypto_key {  }
has 'crypto_cipher_type' => ( is => 'rw', buider => 'build_crypto_cipher_type' );
sub build_crypto_cipher_type { 'Blowfish' }
has 'cipher' => ( is => 'ro', lazy => 1, builder => 'build_cipher' );
sub build_cipher {
  my $self = shift;
  return Crypt::CBC->new(
    -key    => $self->crypto_key,
    -cipher => $self->crypto_cipher_type,
    -salt   => 1,
    -header => 'salt',
  );
}

has_field '_token' => (
  type => 'Hidden',
  required => 1,
  order => 100,
);

sub default__token {
  my $self = shift;
  return $self->get_token;
}

sub validate__token {
  my ( $self, $field ) = @_;

  unless ( $self->verify_token($field->value) ) {
    $field->add_error();
  }
}

sub verify_token {
  my ($self, $token) = @_;

  return undef unless($token);

  my $value = undef;
  try {
    $value = $self->cipher->decrypt(decode_base64($token));
    if ( my $prefix = $self->token_prefix ) {
      return undef unless ($value =~ s/^\Q$prefix\E//);
    }
  }
  catch {};

  return undef unless defined($value);
  return undef unless ( $value =~ /^\d+$/ );
  return undef if ( time() > $value );

  return 1;
}

sub get_token {
  my $self = shift;

  my $value = $self->token_prefix . (time() + $self->token_expiration_time);
  my $token = encode_base64($self->cipher->encrypt($value));
  $token =~ s/[\s\r\n]+//g;
  return $token;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Role::RequestToken - Role to incluse a token for csrf protection

=head1 VERSION

version 0.04

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
