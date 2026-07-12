package DBIO::EncodedColumn;
# ABSTRACT: One-way encode selected columns (e.g. passwords)

use strict;
use warnings;

use base qw/DBIO::Base/;

use Digest ();
use MIME::Base64 ();
use DBIO::Util qw(is_literal_value);
use namespace::clean;

__PACKAGE__->load_components(qw/FilterColumn/);


sub register_column {
  my ($self, $column, $info, @rest) = @_;

  $self->next::method($column, $info, @rest);

  return unless $info->{encode_column};

  my $encode_info = {
    encode_class => $info->{encode_class} || 'Digest',
    encode_args  => (ref($info->{encode_args}) eq 'HASH' ? { %{ $info->{encode_args} } } : {}),
    check_method => $info->{encode_check_method} || "check_$column",
  };

  $info->{_encode_info} = $encode_info;

  $self->filter_column($column => {
    filter_from_storage => sub { $_[1] },
    filter_to_storage   => sub {
      my ($row, $value) = @_;

      return $value if !defined($value) || ref($value) || is_literal_value($value);
      return $value if $row->_encoded_value_is_hash($value);

      return $row->_encode_column_value($value, $encode_info);
    },
  });

  $self->_install_check_method($column, $encode_info->{check_method});

  return;
}

sub _install_check_method {
  my ($self, $column, $method) = @_;

  return if $self->can($method);

  no strict 'refs';
  *{"${self}::${method}"} = sub {
    my ($row, $candidate) = @_;

    my $stored = $row->get_column($column);
    return 0 unless defined $stored;

    return $row->_verify_encoded_value($stored, $candidate);
  };
}

sub _encode_column_value {
  my ($self, $value, $encode_info) = @_;

  my $args = $encode_info->{encode_args} || {};
  my ($ctx, $algorithm) = $self->_digest_ctx($args->{algorithm});

  my $salt_len = defined $args->{salt_length} ? int($args->{salt_length}) : 16;
  $salt_len = 0 if $salt_len < 0;

  my $salt = $salt_len ? $self->_random_bytes($salt_len) : '';

  $ctx->add($salt);
  $ctx->add($value);
  my $digest = $ctx->digest;

  return join(
    '$',
    'dbio',
    $algorithm,
    MIME::Base64::encode_base64($salt, ''),
    MIME::Base64::encode_base64($digest, ''),
  );
}

sub _verify_encoded_value {
  my ($self, $stored, $candidate) = @_;

  return 0 if !defined $candidate;

  return $stored eq $candidate unless $self->_encoded_value_is_hash($stored);

  my ($prefix, $algorithm, $salt_b64, $digest_b64) = split /\$/, $stored, 4;
  return 0 unless defined $digest_b64;

  my $salt = eval { MIME::Base64::decode_base64($salt_b64) };
  return 0 if $@;

  my $expected = eval { MIME::Base64::decode_base64($digest_b64) };
  return 0 if $@;

  my ($ctx) = $self->_digest_ctx($algorithm);
  $ctx->add($salt);
  $ctx->add($candidate);
  my $got = $ctx->digest;

  return _constant_time_eq($expected, $got);
}

sub _encoded_value_is_hash {
  my ($self, $value) = @_;

  return 0 unless defined $value && !ref($value);

  # Supported DBIO::EncodedColumn format
  return 1 if $value =~ /\Adbio\$[^\$]+\$[^\$]*\$[^\$]+\z/;

  # Common bcrypt prefix, accepted as pre-encoded passthrough
  return 1 if $value =~ /\A\$2[abxy]?\$/;

  return 0;
}

sub _digest_ctx {
  my ($self, $algorithm) = @_;

  my @try = grep { defined($_) && length($_) } ($algorithm, 'SHA-256', 'SHA-1');

  for my $alg (@try) {
    my $ctx = eval { Digest->new($alg) };
    return ($ctx, $alg) if $ctx;
  }

  $self->throw_exception('Unable to initialize a Digest algorithm (tried requested algorithm, SHA-256, SHA-1)');
}

sub _random_bytes {
  my ($self, $len) = @_;

  my $bytes;

  $bytes = _crypt_urandom($len);
  return $bytes if defined($bytes) && length($bytes) == $len;

  $bytes = _dev_urandom($len);
  return $bytes if defined($bytes) && length($bytes) == $len;

  return join '', map { chr(int(rand(256))) } 1 .. $len;
}

sub _crypt_urandom {
  my ($len) = @_;
  return unless eval { require Crypt::URandom; 1 };

  my $bytes = eval { Crypt::URandom::urandom($len) };
  return if $@;
  return $bytes;
}

sub _dev_urandom {
  my ($len) = @_;

  return unless -r '/dev/urandom';

  open my $fh, '<:raw', '/dev/urandom' or return;
  my $bytes = '';
  my $read = read($fh, $bytes, $len);
  close $fh;

  return unless defined $read && $read == $len;
  return $bytes;
}

sub _constant_time_eq {
  my ($a, $b) = @_;

  return 0 if !defined($a) || !defined($b);
  return 0 if length($a) != length($b);

  my $diff = 0;
  for my $i (0 .. length($a) - 1) {
    $diff |= ord(substr($a, $i, 1)) ^ ord(substr($b, $i, 1));
  }

  return $diff == 0 ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::EncodedColumn - One-way encode selected columns (e.g. passwords)

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);

  __PACKAGE__->add_columns(
    password => {
      data_type           => 'varchar',
      size                => 255,
      encode_column       => 1,
      encode_check_method => 'check_password',
      encode_args         => {
        algorithm   => 'SHA-256',
        salt_length => 16,
      },
    },
  );

  my $user = $schema->resultset('User')->new_result({ password => 's3cret' });
  $user->check_password('s3cret'); # true

See F<t/94encoded_column.t> for a runnable example.

=head1 DESCRIPTION

C<DBIO::EncodedColumn> implements one-way column encoding for values like
passwords.  Columns are marked with C<encode_column =E<gt> 1> in C<add_columns>.

The value is encoded on the way to storage. Reading a column returns the stored
(encoded) representation.

This component stores hashes using a stable format:

  dbio$<algorithm>$<salt_base64>$<digest_base64>

and auto-installs a verifier method per encoded column.

=head1 COLUMN OPTIONS

=over 4

=item C<encode_column>

Boolean; enables encoding for this column.

=item C<encode_check_method>

Method name to install for verification. Defaults to C<check_${column}>.

=item C<encode_args>

Hashref with optional settings:

=over 4

=item C<algorithm>

Digest algorithm name for L<Digest> (default: C<SHA-256>, fallback C<SHA-1>).

=item C<salt_length>

Salt size in bytes (default: C<16>, C<0> disables salting).

=back

=back

=head1 RANDOMNESS

Salt generation prefers C<Crypt::URandom> when installed, then C</dev/urandom>,
and finally falls back to Perl C<rand()> as a last resort.

For production password hashing, installing C<Crypt::URandom> is recommended.

=head1 SEE ALSO

=over 4

=item L<DBIO::FilterColumn>

=item L<DBIO::InflateColumn>

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
