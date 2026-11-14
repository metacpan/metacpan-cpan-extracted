package DBIO::EncodedColumn;
# ABSTRACT: One-way encode selected columns: passwords with Bcrypt or Argon2, tokens with Digest

use strict;
use warnings;

our $VERSION = '0.900005';

use base qw/DBIO::Base/;

use Digest ();
use MIME::Base64 ();
use Crypt::URandom ();
use DBIO::Carp;
use DBIO::Util qw(is_literal_value);
use namespace::clean;

__PACKAGE__->load_components(qw/FilterColumn/);



sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (ref $info eq 'HASH' && $info->{encode_column}) {
      $info = { %$info };
      $info->{is_serializable} = 0 unless exists $info->{is_serializable};
      $info->{_changelog_exclude} = 1
        unless exists $info->{changelog} || exists $info->{_changelog_exclude};
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}


sub register_column {
  my ($self, $column, $info, @rest) = @_;

  $self->next::method($column, $info, @rest);

  return unless $info->{encode_column};

  my $encode_info = $self->_encode_info_for($column, $info);

  $self->filter_column($column => {
    filter_from_storage => sub { $_[1] },
    filter_to_storage   => sub {
      my ($row, $value) = @_;

      return $value if !defined($value) || ref($value) || is_literal_value($value);

      return $row->_encode_column_value($value, $encode_info);
    },
  });

  $self->_install_check_method($column, $encode_info->{check_method}, $encode_info);

  return;
}

my %known_encode_args = (
  Bcrypt => { map { $_ => 1 } qw(cost accept_unencoded) },
  Argon2 => { map { $_ => 1 } qw(t_cost m_cost parallelism accept_unencoded) },
  Digest => { map { $_ => 1 } qw(algorithm salt_length accept_unencoded) },
);

my %class_module = (
  Bcrypt => 'Crypt::Bcrypt',
  Argon2 => 'Crypt::Argon2',
);

# What may be written; every other digest stays readable.
my $writable_digest = qr/\A(?:SHA-(?:256|384|512)|SHA3-(?:224|256|384|512))\z/;

sub _encode_info_for {
  my ($self, $column, $info) = @_;

  my $class_name = ref($self) || $self;
  my $where = "column '$column' of $class_name";

  my $class = defined $info->{encode_class} ? $info->{encode_class} : 'Bcrypt';
  $self->throw_exception(
    "encode_class '$class' of $where is not supported (known: "
    . join(', ', sort keys %known_encode_args) . ')'
  ) unless !ref($class) && $known_encode_args{$class};

  my $args = $info->{encode_args};
  $self->throw_exception("encode_args of $where must be a hashref")
    if defined $args && ref($args) ne 'HASH';
  $args = { %{ $args || {} } };

  my $known = $known_encode_args{$class};
  if (my @unknown = sort grep { !$known->{$_} } keys %$args) {
    $self->throw_exception(
      "Unknown encode_args key(s) of $where: " . join(', ', @unknown)
      . " (known for $class: " . join(', ', sort keys %$known) . ')'
    );
  }

  if (my $module = $class_module{$class}) {
    $self->throw_exception(
      "encode_class '$class' of $where needs $module, which is not installed"
    ) unless _module_loadable($module);
  }

  if ($class eq 'Bcrypt') {
    $args->{cost} = 12 unless defined $args->{cost};
    $self->throw_exception("encode_args cost of $where must be an integer from 4 to 31")
      unless !ref($args->{cost}) && $args->{cost} =~ /\A[0-9]+\z/
        && $args->{cost} >= 4 && $args->{cost} <= 31;
  }
  elsif ($class eq 'Argon2') {
    $args->{t_cost}      = 3     unless defined $args->{t_cost};
    $args->{m_cost}      = '32M' unless defined $args->{m_cost};
    $args->{parallelism} = 1     unless defined $args->{parallelism};

    for my $key (qw(t_cost parallelism)) {
      $self->throw_exception("encode_args $key of $where must be a positive integer")
        unless !ref($args->{$key}) && $args->{$key} =~ /\A[1-9][0-9]*\z/;
    }
    $self->throw_exception("encode_args m_cost of $where must be a positive number with an optional k, M or G suffix")
      unless !ref($args->{m_cost}) && $args->{m_cost} =~ /\A[1-9][0-9]*[kMG]?\z/;
  }
  else {
    $args->{algorithm} = 'SHA-256' unless defined $args->{algorithm};
    $self->throw_exception(
      "encode_args algorithm '$args->{algorithm}' of $where is not allowed for writing: "
      . 'SHA-256, SHA-384, SHA-512 and SHA3-224/256/384/512 are'
    ) unless !ref($args->{algorithm}) && $args->{algorithm} =~ $writable_digest;
    $self->throw_exception("Unknown encode_args algorithm '$args->{algorithm}' of $where")
      unless defined _digest_ctx($args->{algorithm});

    if (defined $args->{salt_length}) {
      $self->throw_exception("encode_args salt_length of $where must be a non-negative integer")
        unless !ref($args->{salt_length}) && $args->{salt_length} =~ /\A[0-9]+\z/;
    }
  }

  $args->{accept_unencoded} = $args->{accept_unencoded} ? 1 : 0;

  return {
    encode_class => $class,
    encode_args  => $args,
    check_method => $info->{encode_check_method} || "check_$column",
  };
}

sub _module_loadable {
  my ($module) = @_;
  (my $file = "$module.pm") =~ s{::}{/}g;
  return eval { require $file; 1 } ? 1 : 0;
}

sub _install_check_method {
  my ($self, $column, $method, $encode_info) = @_;

  return if $self->can($method);

  no strict 'refs';
  *{"${self}::${method}"} = sub {
    my ($row, $candidate) = @_;

    my $stored = $row->get_column($column);
    return 0 unless defined $stored;

    return $row->_verify_encoded_value($stored, $candidate, $encode_info, $column);
  };
}

# The bytes of the UTF-8 encoding of a value: what every method gets, on
# writing and on checking alike.
sub _utf8_bytes {
  my ($value) = @_;
  utf8::encode($value);
  return $value;
}

sub _assert_bcrypt_input {
  my ($self, $bytes) = @_;

  $self->throw_exception(
    'bcrypt takes at most 72 bytes and no NUL byte: use encode_class => \'Argon2\' for this column'
  ) unless _bcrypt_takes($bytes);
}

sub _bcrypt_takes {
  my ($bytes) = @_;
  return length($bytes) <= 72 && index($bytes, "\0") < 0;
}

sub _encode_column_value {
  my ($self, $value, $encode_info) = @_;

  my $class = $encode_info->{encode_class};
  my $args  = $encode_info->{encode_args} || {};
  my $bytes = _utf8_bytes($value);

  if ($class eq 'Bcrypt') {
    $self->_assert_bcrypt_input($bytes);
    return Crypt::Bcrypt::bcrypt($bytes, '2b', $args->{cost}, $self->_random_bytes(16));
  }

  if ($class eq 'Argon2') {
    return Crypt::Argon2::argon2id_pass(
      $bytes, $self->_random_bytes(16),
      $args->{t_cost}, $args->{m_cost}, $args->{parallelism}, 32,
    );
  }

  my $algorithm = $args->{algorithm};
  my $ctx = _digest_ctx($algorithm)
    or $self->throw_exception("Unknown encode_args algorithm '$algorithm'");

  my $salt_len = defined $args->{salt_length} ? int($args->{salt_length}) : 16;

  my $salt = $salt_len ? $self->_random_bytes($salt_len) : '';

  $ctx->add($salt);
  $ctx->add($bytes);
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
  my ($self, $stored, $candidate, $encode_info, $column) = @_;

  return 0 if !defined $candidate || ref $candidate;

  # no hash format at all: a plain value, accepted only on request
  unless ($self->_encoded_value_looks_like_hash($stored)) {
    return 0 unless $encode_info && $encode_info->{encode_args}{accept_unencoded};

    my $match = _constant_time_eq($stored, $candidate);
    $self->_rehash_unencoded($column, $stored, $candidate, $encode_info) if $match;

    return $match;
  }

  my ($format, @parts) = $self->_encoded_value_format($stored);
  return 0 unless $format;

  my $bytes = _utf8_bytes($candidate);

  if ($format eq 'bcrypt') {
    return 0 unless _bcrypt_takes($bytes);
    return $self->_bcrypt_check($bytes, $stored) ? 1 : 0;
  }

  if ($format eq 'argon2id') {
    return $self->_argon2_check($bytes, $stored) ? 1 : 0;
  }

  my ($algorithm, $salt, $expected) = @parts;
  my $ctx = _digest_ctx($algorithm) or return 0;
  $ctx->add($salt);
  $ctx->add($bytes);

  return _constant_time_eq($expected, $ctx->digest);
}

# A plain stored value that matched: write the hash of the column's class back.
# Only this column, only while the database still holds the value that was
# compared; a row that is not in the database yet just takes the value.
sub _rehash_unencoded {
  my ($self, $column, $stored, $candidate, $encode_info) = @_;

  return unless defined $column;

  carp_unique(
    "Column '$column' held a value without hash format; it matched and is written back as "
    . $encode_info->{encode_class} . ' hash'
  );

  my $hash = $self->_encode_column_value($candidate, $encode_info);

  unless ($self->in_storage) {
    $self->set_column($column, $hash);
    return;
  }

  my $rs    = $self->result_source->resultset;
  my $alias = $rs->current_source_alias;

  my $updated = $rs->search({
    %{ $self->ident_condition($alias) },
    "$alias.$column" => $stored,
  })->update({ $column => \[ '?', [ $column => $hash ] ] });

  if ($updated && $updated > 0) {
    $self->store_column($column, $hash);
    delete $self->{_dirty_columns}{$column};
  }

  return;
}

# What a value claims to be: anything that starts like a dbio, a bcrypt or an
# argon2id hash.
sub _encoded_value_looks_like_hash {
  my ($self, $value) = @_;

  return 0 unless defined $value && !ref($value);

  return 1 if $value =~ /\Adbio\$[^\$]+\$[^\$]*\$[^\$]+\z/;
  return 1 if $value =~ /\A\$2[abxy]?\$/;
  return 1 if $value =~ /\A\$argon2id\$/;

  return 0;
}

# What a value is: () unless it is a complete, valid hash, else
# ('dbio', $algorithm, $salt, $digest), ('bcrypt') or ('argon2id').
sub _encoded_value_format {
  my ($self, $value) = @_;

  return unless defined $value && !ref($value);

  return ('bcrypt')
    if $value =~ m{\A\$2[abxy]\$(?:0[4-9]|[12][0-9]|3[01])\$[./A-Za-z0-9]{53}\z};

  return ('argon2id')
    if $value =~ m{\A\$argon2id\$v=[0-9]+\$m=[0-9]+,t=[0-9]+,p=[0-9]+\$[A-Za-z0-9+/]+\$[A-Za-z0-9+/]+\z};

  my ($prefix, $algorithm, $salt_b64, $digest_b64) = split /\$/, $value, 4;
  return unless defined $digest_b64 && $prefix eq 'dbio' && $value =~ /\Adbio\$[^\$]+\$[^\$]*\$[^\$]+\z/;
  return unless _is_canonical_base64($salt_b64) && _is_canonical_base64($digest_b64);

  my $ctx = _digest_ctx($algorithm) or return;

  my $salt   = MIME::Base64::decode_base64($salt_b64);
  my $digest = MIME::Base64::decode_base64($digest_b64);

  return unless length($digest) == length($ctx->digest);

  return ('dbio', $algorithm, $salt, $digest);
}

sub _is_canonical_base64 {
  my ($b64) = @_;
  return 0 unless defined $b64;
  return $b64 =~ m{\A(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\z} ? 1 : 0;
}

# A Digest context for exactly this algorithm, or undef. Never a substitute.
sub _digest_ctx {
  my ($algorithm) = @_;

  return unless defined $algorithm && $algorithm =~ m{\A[A-Za-z0-9][A-Za-z0-9/-]*\z};

  return eval { Digest->new($algorithm) };
}

sub _bcrypt_check {
  my ($self, $bytes, $hash) = @_;

  $self->throw_exception(
    'Checking a bcrypt hash needs Crypt::Bcrypt, which is not installed '
    . '(dependency group encoded_column)'
  ) unless _module_loadable('Crypt::Bcrypt');

  return Crypt::Bcrypt::bcrypt_check($bytes, $hash);
}

sub _argon2_check {
  my ($self, $bytes, $hash) = @_;

  $self->throw_exception(
    'Checking an argon2id hash needs Crypt::Argon2, which is not installed '
    . '(dependency group encoded_column)'
  ) unless _module_loadable('Crypt::Argon2');

  return Crypt::Argon2::argon2id_verify($hash, $bytes);
}

sub _random_bytes {
  my ($self, $len) = @_;

  my $bytes = eval { Crypt::URandom::urandom($len) };

  $self->throw_exception('no secure random source -- install Crypt::URandom')
    unless defined($bytes) && length($bytes) == $len;

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

DBIO::EncodedColumn - One-way encode selected columns: passwords with Bcrypt or Argon2, tokens with Digest

=head1 VERSION

version 0.900005

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
    },
    api_token => {
      data_type     => 'varchar',
      size          => 255,
      encode_column => 1,
      encode_class  => 'Digest',
      encode_args   => { algorithm => 'SHA-256' },
    },
  );

  my $user = $schema->resultset('User')->new_result({ password => 's3cret' });
  $user->check_password('s3cret'); # true

See F<t/94encoded_column.t> for a runnable example.

=head1 DESCRIPTION

C<DBIO::EncodedColumn> implements one-way column encoding. Columns are marked
with C<encode_column =E<gt> 1> in C<add_columns>.

The value is encoded on the way to storage. Reading a column returns the stored
(encoded) representation. A verifier method per encoded column is installed.

=head2 Classes

C<encode_class> chooses the method:

=over 4

=item C<Bcrypt> (default)

Passwords. L<Crypt::Bcrypt>, variant C<2b>, C<cost> 12 unless C<encode_args>
says otherwise. The stored value is the C<$2b$...> string. bcrypt takes values
of up to 72 bytes without a NUL byte; a longer value or one with a NUL byte is
refused with an exception that points to C<Argon2>.

=item C<Argon2>

Passwords. L<Crypt::Argon2>, argon2id, with C<t_cost>, C<m_cost> and
C<parallelism> from C<encode_args>. The stored value is the C<$argon2id$...>
string.

=item C<Digest>

Tokens and values that are compared by their digest. A salted L<Digest> of
SHA-256, SHA-384, SHA-512 or SHA3-224, SHA3-256, SHA3-384, SHA3-512, stored as

  dbio$<algorithm>$<salt_base64>$<digest_base64>

=back

The module of the chosen class has to be installed: a class whose module is
missing does not load, and the exception names the module.

Every value goes into the method as the bytes of its UTF-8 encoding, when it is
written and when it is checked.

=head2 What is encoded and what passes through

A value handed to an encoded column through the accessor, C<new>, C<create> or
C<update> is encoded, whatever it looks like: a defined value that is neither a
reference nor a literal SQL value is always taken as a password. That includes a
value that only B<looks> like a hash (C<$2a$my-own-password>, C<dbio$a$b$c>) and
the value read from the row itself -- C<< $row->password($row->password) >>
encodes the stored hash a second time. To leave a stored value as it is, do not
set it, or use C<set_column>. C<copy> carries the stored value over as it is.

=head2 Storing a finished hash

A hash made elsewhere (importing accounts with their hashes) goes past the
filter explicitly, with C<set_column>, which the filter does not act on, or
with a literal in C<new>/C<create>:

  $user->set_column(password => $hash);

  $schema->resultset('User')->create({
    name     => 'alice',
    password => \[ '?', $hash ],
  });

C<check_password> verifies such a value like any stored one.

=head2 Verification

The stored value names its method and the check uses exactly that one:
C<$2...$> values (bcrypt) are checked with L<Crypt::Bcrypt>, C<$argon2id$...>
values with L<Crypt::Argon2>, C<dbio$...> values with the algorithm the value
names (a name this installation cannot build gives C<0>; digests of MD5 and
SHA-1 that exist in a column stay checkable). The module a check needs has to be
installed; without it the check method throws an exception naming the module. A
candidate that bcrypt cannot take (over 72 bytes, or with a NUL byte) gives C<0>.

A stored value that has no hash format at all never matches
(C<accept_unencoded> is C<0>). With C<accept_unencoded =E<gt> 1> in
C<encode_args> a stored value that equals the candidate matches (compared in
constant time, answer C<1> or C<0>) and is written back as a hash of the
column's class: the check method updates this one column of the row, only while
the database still holds the value that was compared, and warns once. A row that
is not in the database yet gets the hash as its column value. A value that
claims a hash format but is not a valid one never matches, in either setting.

=head2 Serializing and the changelog

A column with C<encode_column> has C<< is_serializable =E<gt> 0 >> (it is not part
of C<TO_JSON>) and C<< changelog =E<gt> 0 >> (L<DBIO::ChangeLog> leaves it out),
unless the column definition says otherwise.

=head2 Trace

The bind values of an encoded column appear as C<***> in the SQL trace; see
L<DBIO::Storage::DBI/redact_bind_value>.

=head1 METHODS

=head2 add_columns

Component override: gives every column with C<encode_column> the column
settings C<< is_serializable =E<gt> 0 >> and C<< changelog =E<gt> 0 >> unless
the definition names them, then delegates to C<next::method>. The changelog
setting is handed on as the marker L<DBIO::ChangeLog> reads, so it holds in
either order of C<load_components>. Called the same way as the plain
C<add_columns>; not normally called directly.

=head2 register_column

Component override: after delegating to C<next::method>, checks C<$info> for
C<encode_column> and, if present, installs a L<DBIO::FilterColumn>
C<filter_to_storage> hook that hashes the value on write (skipping C<undef>,
references and literal SQL values) plus a
check method (C<check_$column> by default, or C<encode_check_method>).
An unknown C<encode_class>, the module of the class missing, an unknown
C<encode_args> key or an algorithm outside the Digest list throws here, when the
class is loaded.
Called the same way as the plain C<register_column>; not normally called
directly.

=head1 COLUMN OPTIONS

=over 4

=item C<encode_column>

Boolean; enables encoding for this column.

=item C<encode_check_method>

Method name to install for verification. Defaults to C<check_${column}>.

=item C<encode_class>

C<Bcrypt> (default), C<Argon2> or C<Digest>. Any other class is refused when
the class is loaded.

=item C<encode_args>

Hashref with optional settings. A key the class does not know is refused when
the class is loaded.

=over 4

=item C<cost> (Bcrypt)

Integer from 4 to 31, default C<12>.

=item C<t_cost>, C<m_cost>, C<parallelism> (Argon2)

Time cost (positive integer, default C<3>), memory cost (a number with an
optional C<k>, C<M> or C<G> suffix, default C<32M>) and parallelism (positive
integer, default C<1>).

=item C<algorithm> (Digest)

SHA-256 (default), SHA-384, SHA-512, SHA3-224, SHA3-256, SHA3-384 or SHA3-512;
another name is refused when the class is loaded.

=item C<salt_length> (Digest)

Salt size in bytes, a non-negative integer (default: C<16>, C<0> disables
salting).

=item C<accept_unencoded> (every class)

Boolean, default C<0>. See L</Verification>.

=back

=back

=head1 RANDOMNESS

Salts come from L<Crypt::URandom>, a required module. Where it cannot deliver
the bytes, encoding throws C<no secure random source -- install
Crypt::URandom>.

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
