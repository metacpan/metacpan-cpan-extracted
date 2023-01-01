package DBIx::Class::EncodedColumn::Crypt::Passphrase::Bcrypt;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Crypt::Passphrase::Bcrypt backend

use strict;
use warnings;

our $VERSION = '0.0110';

use Encode qw(encode_utf8);
use Crypt::Passphrase::Bcrypt ();

sub make_encode_sub {
  my($class, $col, $args) = @_;

  my $cost = _get_cost($args->{cost});

  my $passphrase = Crypt::Passphrase::Bcrypt->new(
    cost    => $cost,
    hash    => $args->{hash} || 'sha256',
    subtype => $args->{subtype},
  );

  return sub {
    my ($plain_text) = @_;
    return $passphrase->hash_password($plain_text);
  };
}

sub make_check_sub {
  my($class, $col, $args) = @_;

  my $cost = _get_cost($args->{cost});

  my $passphrase = Crypt::Passphrase::Bcrypt->new(
    cost    => $cost,
    hash    => $args->{hash} || 'sha256',
    subtype => $args->{subtype},
  );

  return sub {
    my $col_v = $_[0]->get_column($col);
    return unless defined $col_v;
    return $passphrase->verify_password(encode_utf8($_[1]), $col_v);
  };
}

sub _get_cost {
  my ($cost) = @_;

  $cost = defined $cost ? $cost : 8;

  die("Valid cost is a 1 or 2 digit integer. You used '$cost'.")
    unless $cost =~ /^\d\d?$/;

  $cost = sprintf '%02i', 0 + $cost;

  return $cost;
}

1;

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::EncodedColumn::Crypt::Passphrase::Bcrypt - Crypt::Passphrase::Bcrypt backend

=head1 VERSION

version 0.0110

=head1 SYNOPSIS

  # In your database class:

  __PACKAGE__->add_columns(
    password => {
      data_type           => 'CHAR',
      size                => 255,
      encode_column       => 1,
      encode_class        => 'Crypt::Passphrase::Bcrypt',
      encode_args         => { cost => 6 },
      encode_check_method => 'check_password',
  });

  # In your program:

  my ($self, $user, $pass) = @_;
  my $result = $self->schema->resultset('Account')
    ->search({ user => $user })->first;
  return 1
    if $result && $result->check_password($pass);

=head1 DESCRIPTION

Use L<Crypt::Passphrase::Bcrypt> for an encoded password column.

=head1 ENCODE ARGUMENTS

=head2 cost

A single or double digit non-negative integer representing the cost of the
hash function.

Default: C<8>

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

