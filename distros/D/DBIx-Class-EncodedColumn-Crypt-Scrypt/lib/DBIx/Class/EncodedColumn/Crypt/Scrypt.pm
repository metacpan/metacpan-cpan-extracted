use strict;
use warnings;

# ABSTRACT: scrypt support for DBIx::Class::EncodedColumn
package DBIx::Class::EncodedColumn::Crypt::Scrypt;

our $VERSION = '0.004'; # VERSION

use Encode qw(is_utf8 encode_utf8);
use Crypt::ScryptKDF 0.008 qw(scrypt_hash scrypt_hash_verify
    random_bytes);

sub power_of_2 {
    my ($x) = @_;

    while($x > 1) {
        return 0 if $x % 2 == 1;
        $x /= 2;
    }

    return $x == 1;
}

sub make_encode_sub {
    my ($class, $col, $args) = @_;

    $args->{cost}     //= 8;
    $args->{blocksz}  //= 8;
    $args->{parallel} //= 1;
    $args->{saltsz}   //= 32;
    $args->{keysz}    //= 32;

    die "Cost not a power of 2" unless power_of_2($args->{cost});

    sub {
        my ($text) = @_;
        $text = encode_utf8($text) if is_utf8($text);
        scrypt_hash(
            $text,
            random_bytes($args->{saltsz}),
            $args->{cost},
            $args->{blocksz},
            $args->{parallel},
            $args->{keysz});
    };
}

sub make_check_sub {
    my ($class, $col) = @_;

    sub {
        my ($result, $pass) = @_;
        $pass = encode_utf8($pass) if is_utf8($pass);
        scrypt_hash_verify($pass, $result->get_column($col));
    };
}

1;

=pod

=head1 NAME

DBIx::Class::EncodedColumn::Crypt::Scrypt - scrypt support for DBIx::Class::EncodedColumn

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  __PACKAGE__->add_columns(
      'password' => {
          data_type           => 'text',
          encode_column       => 1,
          encode_class        => 'Crypt::Scrypt',
          encode_args         => {
              cost  => 10,
              keysz => 64
          },
          encode_check_method => 'check_password',
      }
  )

=head1 DESCRIPTION

=head1 NAME

DBIx::Class::EncodedColumn::Crypt::Scrypt

=head1 ACCEPTED ARGUMENTS

=head2 cost

CPU/memory cost, as a power of 2. Give the exponent only. Default: 8

=head2 blocksz

Block size. Defaults to 8.

=head2 parallel

Parallelization parameter. Defaults to 1.

=head2 saltsz

Length of salt in bytes. Defaults to 32.

=head2 keysz

Length of derived key in bytes. Defaults to 32.

=head1 METHODS

=head2 make_encode_sub($column_name, \%encode_args)

Returns a coderef that accepts a plaintext value and returns an
encoded value.

=head2 make_check_sub($column_name, \%encode_args)

Returns a coderef that when given the row object and a plaintext value
will return a boolean if the plaintext matches the encoded value. This
is typically used for password authentication.

=head1 SEE ALSO

L<DBIx::Class::EncodedColumn>

=head1 AUTHOR

Forest Belton <forest@homolo.gy>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Forest Belton.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__;

