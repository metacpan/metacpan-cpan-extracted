package DBIx::Class::EncodedColumn::Crypt::Eksblowfish::Bcrypt;

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt ();
use Encode qw(is_utf8 encode_utf8);

our $VERSION = '0.00001';

sub make_encode_sub {
  my($class, $col, $args) = @_;
  my $cost = exists $args->{cost}    ? $args->{cost}    : 8;
  my $nul  = exists $args->{key_nul} ? $args->{key_nul} : 1;

  die("Valid 'key_null' values are '1' and '0'. You used '${nul}'.")
    unless $nul =~ /^[01]$/;
  die("Valid 'cost' are 1 or 2 digit integers. You used '${cost}'.")
    unless $cost =~ /^\d\d?$/;

  $nul = $nul ? 'a' : '';
  $cost = sprintf("%02i", 0+$cost);

  # It must begin with "$2",  optional "a", "$", two digits, "$"
  my $settings_base = join('','$2',$nul,'$',$cost, '$');

  my $encoder = sub {
    my ($plain_text, $settings_str) = @_;
    if ( is_utf8($plain_text) ) {
      #  Bcrypt expects octets
      $plain_text = encode_utf8($plain_text);
    }
    unless ( $settings_str ) {
      my $salt = join('', map { chr(int(rand(256))) } 1 .. 16);
      $salt = Crypt::Eksblowfish::Bcrypt::en_base64( $salt );
      $settings_str =  $settings_base.$salt;
    }
    return Crypt::Eksblowfish::Bcrypt::bcrypt($plain_text, $settings_str);
  };

  return $encoder;
}

sub make_check_sub {
  my($class, $col, $args) = @_;

  #fast fast fast
  return eval qq^ sub {
    my \$col_v = \$_[0]->get_column('${col}');
    return unless defined \$col_v;
    \$_[0]->_column_encoders->{${col}}->(\$_[1], \$col_v) eq \$col_v;
  } ^ || die($@);
}

1;

__END__;

=head1 NAME

DBIx::Class::EncodedColumn::Crypt::Eksblowfish::Bcrypt - Eksblowfish bcrypt backend

=head1 SYNOPSYS

  #Eksblowfish bcrypt / cost of 8/ no key_nul / generate check method
  __PACKAGE__->add_columns(
    'password' => {
      data_type => 'CHAR',
      size      => 59,
      encode_column => 1,
      encode_class  => 'Crypt::Eksblowfish::Bcrypt',
      encode_args   => { key_nul => 0, cost => 8 },
      encode_check_method => 'check_password',
  }

=head1 DESCRIPTION

=head1 ACCEPTED ARGUMENTS

=head2 key_nul => [01]

Defaults to true.

From the L<Crypt::Eksblowfish::Bcrypt> docs

    Boolean: whether to append a NUL to the password before using it as a key.
    The algorithm as originally devised does not do this, but it was later
    modified to do it. The version that does append NUL is to be preferred;
    not doing so is supported only for backward compatibility.

=head2 cost => \d\d?

A single or  double digit non-negative integer representing the cost of the
hash function. Defaults to 8.

=head1 METHODS

=head2 make_encode_sub $column_name, \%encode_args

Returns a coderef that accepts a plaintext value and returns an encoded value

=head2 make_check_sub $column_name, \%encode_args

Returns a coderef that when given the row object and a plaintext value will
return a boolean if the plaintext matches the encoded value. This is typically
used for password authentication.

=head1 SEE ALSO

L<DBIx::Class::EncodedColumn::Digest>, L<DBIx::Class::EncodedColumn>,
L<Crypt::Eksblowfish::Bcrypt>

=head1 AUTHOR

Guillermo Roditi (groditi) <groditi@cpan.org>

Based on the Vienna WoC  ToDo manager code by Matt S trout (mst)

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
