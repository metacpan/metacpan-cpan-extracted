package Crypt::URandom::Token;

use strict;
use warnings;
use v5.20;

use Crypt::URandom qw(urandom);
use Carp qw(croak);
use Exporter qw(import);

our @EXPORT_OK = qw(urandom_token);

our $VERION = "0.003";

=head1 NAME

Crypt::URandom::Token - Generate secure strings for passwords, secrets and similar

=head1 SYNOPSIS

  use Crypt::URandom::Token qw(urandom_token);

  # generates a 44-character alphanumeric token (default)
  my $token = urandom_token();

  # generate a 6 digit numeric pin
  my $pin = urandom_token(6, [0..9]);

  # generate a 19 character lowercase alphanumeric password
  my $password = urandom_token(19, [a..z, 0..9]);


  # Object usage:
  my $obj = Crypt::URandom::Token->new(
      length   => 44,
      alphabet => [ A..Z, a..z, 0..9 ],
  );
  my $token = $obj->get;

=head1 DESCRIPTION

This module provides a secure way to generate a random token for passwords and
similar using L<Crypt::URandom> as the source of random bits.

By default, it generates a 44 character alphanumeric token with more than 256
bits of entropy. A custom alphabet with between 2 and 256 elements can be
provided.

Modulo reduction and rejection sampling is used to prevent modulus bias. Keep in
mind that bias will be introduced if duplicate elements are provided in the
alphabet.

=head1 FUNCTIONS

=head2 urandom_token($length = 44, $alphabet = [ A..Z, a..z, 0..9 ]);

Returns a string of C<$length> random characters from C<$alphabet>.

If C<$length> is not provided, it defaults to 44.

If C<$alphabet> is not provided, it defaults to uppercase letters, lowercase
letters, and digits. You can provide either a token of characters or an
arrayref.

=head1 METHODS

=head2 new

Creates a new token generator object. Accepts a hash or hashref with these
paramters:

=over 4

=item * C<length> - desired token length (defaults to 44)

=item * C<alphabet> - the set of characters to use. Can be a string of characters or an array reference. Defaults to C<[ A..Z, a..z, 0..9 ]>

=back

=head2 get

Generates and returns a random token as a token, using the object attributes for
length and alphabet.

=head1 AUTHOR

Stig Palmquist <stig@stig.io>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

sub new {
  my ($class, @args) = @_;
  if (@args == 1 && ref $args[0] eq 'HASH') {
    @args = %{ $args[0] };
  }
  my %args = @args;
  return bless \%args, $class;
}

sub get {
  my $self = shift;
  return urandom_token($self->{length}, $self->{alphabet});
}

sub _alphabet {
  my $in = shift;

  my @alphabet;
  if ( ref $in eq 'ARRAY' ) {
    @alphabet = @$in;
  } elsif (defined $in && !ref $in) {
    @alphabet = split("", ($in // ""));
  } else {
    @alphabet = ("A" .. "Z", "a" .. "z", "0" .. "9");
  }

  unless (@alphabet >= 2 && @alphabet <= 256) {
    croak "alphabet size must be between 2 and 256 elements";
  }

  return @alphabet;
}

sub urandom_token {
  my $length   = shift || 44;
  my @alphabet = _alphabet(shift);

  my $bias_lim = 256 % @alphabet;

  my (@bytes, @token);
  while (@token < $length) {
    @bytes = split "", urandom(64) unless @bytes;
    my $num = ord(shift @bytes);
    next if $num < $bias_lim;
    push @token, $alphabet[$num % @alphabet];
  }
  return join "", @token;
}

1;
