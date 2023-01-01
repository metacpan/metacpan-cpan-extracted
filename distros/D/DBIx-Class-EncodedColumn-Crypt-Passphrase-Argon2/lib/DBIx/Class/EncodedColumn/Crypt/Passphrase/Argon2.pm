package DBIx::Class::EncodedColumn::Crypt::Passphrase::Argon2;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Crypt::Passphrase::Argon2 backend

use strict;
use warnings;

our $VERSION = '0.0107';

use Encode qw(encode_utf8);
use Crypt::Passphrase::Argon2 ();

sub make_encode_sub {
  my($class, $col, $args) = @_;

  my $passphrase = Crypt::Passphrase::Argon2->new(
    memory_cost => $args->{memory_cost},  # all parameters are given,
    time_cost   => $args->{time_cost},    # but the class defaults
    parallelism => $args->{parallelism},  # should suffice
    output_size => $args->{output_size},
    salt_size   => $args->{salt_size},
    subtype     => $args->{subtype},
  );

  return sub {
    my ($plain_text) = @_;
    return $passphrase->hash_password($plain_text);
  };
}

sub make_check_sub {
  my($class, $col, $args) = @_;

  my $passphrase = Crypt::Passphrase::Argon2->new(
    memory_cost => $args->{memory_cost},  # all parameters are given,
    time_cost   => $args->{time_cost},    # but the class defaults
    parallelism => $args->{parallelism},  # should suffice
    output_size => $args->{output_size},
    salt_size   => $args->{salt_size},
    subtype     => $args->{subtype},
  );

  return sub {
    my $col_v = $_[0]->get_column($col);
    return unless defined $col_v;
    return $passphrase->verify_password(encode_utf8($_[1]), $col_v);
  };
}

1;

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::EncodedColumn::Crypt::Passphrase::Argon2 - Crypt::Passphrase::Argon2 backend

=head1 VERSION

version 0.0107

=head1 SYNOPSIS

  # In your database class:

  __PACKAGE__->add_columns(
    password => {
      data_type           => 'CHAR',
      size                => 255,
      encode_column       => 1,
      encode_class        => 'Crypt::Passphrase::Argon2',
      encode_args         => { memory_cost => 256, etc => '...' },
      encode_check_method => 'check_password',
  });

  # In your program:

  my ($self, $user, $pass) = @_;
  my $result = $self->schema->resultset('Account')
    ->search({ user => $user })->first;
  return 1
    if $result && $result->check_password($pass);

=head1 DESCRIPTION

Use L<Crypt::Passphrase::Argon2> for an encoded password column.

=head1 ENCODE ARGUMENTS

=head2 memory_cost

Default: C<256>

=head2 time_cost

Default: C<3>

=head2 parallelism

Default: C<1>

=head2 output_size

Default: C<16>

=head2 salt_size

Default: C<16>

=head2 subtype

Default: C<argon2id>

=head1 METHODS

=head2 make_encode_sub

Return a coderef that accepts a plain text value and returns an encoded value.
This routine is used internally, to encrypt a given plain text password.

  $result = $self->schema->resultset('Account')
    ->create({ user => $user, password => $pass });

=head2 make_check_sub

Return a coderef that, when given a resultset object and a plain text value, will
return a boolean if the plain text matches the encoded value. This is typically
used for password authentication.

  $authed = $result->check_password($pass);

=head1 SEE ALSO

The F<t/01-methods.t> file

L<Crypt::Passphrase>

L<DBIx::Class::EncodedColumn>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__;

