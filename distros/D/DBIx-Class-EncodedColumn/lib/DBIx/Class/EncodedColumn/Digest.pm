package DBIx::Class::EncodedColumn::Digest;

use strict;
use warnings;
use Digest;
use Encode qw( str2bytes );

our $VERSION = '0.00001';

my %digest_lengths =
  (
   'MD2'       => { base64 => 22, binary => 16, hex => 32  },
   'MD4'       => { base64 => 22, binary => 16, hex => 32  },
   'MD5'       => { base64 => 22, binary => 16, hex => 32  },

   'SHA-1'     => { base64 => 27, binary => 20, hex => 40  },
   'SHA-256'   => { base64 => 43, binary => 32, hex => 64  },
   'SHA-384'   => { base64 => 64, binary => 48, hex => 96  },
   'SHA-512'   => { base64 => 86, binary => 64, hex => 128 },

   'CRC-CCITT' => { base64 => 2,  binary => 3,  hex => 3   },
   'CRC-16'    => { base64 => 6,  binary => 5,  hex => 4   },
   'CRC-32'    => { base64 => 14, binary => 10, hex => 8   },

   'Adler-32'  => { base64 => 6,  binary => 4,  hex => 8   },
   'Whirlpool' => { base64 => 86, binary => 64, hex => 128 },
   'Haval-256' => { base64 => 44, binary => 32, hex => 64  },
  );
my @salt_pool = ('A' .. 'Z', 'a' .. 'z', 0 .. 9, '+','/','=');

sub make_encode_sub {
  my($class, $col, $args) = @_;
  my $for  = $args->{format}      ||= 'base64';
  my $alg  = $args->{algorithm}   ||= 'SHA-256';
  my $slen = $args->{salt_length} ||= 0;

  my $encode = $args->{charset};

 die("Valid Digest formats are 'binary', 'hex' or 'base64'. You used '$for'.")
   unless $for =~ /^(?:hex|base64|binary)$/;
  defined(my $object = eval{ Digest->new($alg) }) ||
    die("Can't use Digest algorithm ${alg}: $@");

  my $format_method = $for eq 'binary' ? 'digest' :
    ($for eq 'hex' ? 'hexdigest' : 'b64digest');
  #thanks Haval for breaking the standard. thanks!
  $format_method = 'base64digest 'if ($alg eq 'Haval-256' && $for eq 'base64');

  my $encoder = sub {
    my ($plain_text, $salt) = @_;
    $plain_text = str2bytes($encode, $plain_text,  Encode::FB_PERLQQ | Encode::LEAVE_SRC) if $encode;
    $salt ||= join('', map { $salt_pool[int(rand(65))] } 1 .. $slen);
    $object->reset()->add($plain_text.$salt);
    my $digest = $object->$format_method;
    #print "${plain_text}\t ${salt}:\t${digest}${salt}\n" if $salt;
    return $digest.$salt;
  };

  #in case i didn't prepopulate it
  $digest_lengths{$alg}{$for} ||= length($encoder->('test1'));
  return $encoder;
}

sub make_check_sub {
  my($class, $col, $args) = @_;

  #this is the digest length
  my $len = $digest_lengths{$args->{algorithm}}{$args->{format}};
  die("Unable to find digest length") unless defined $len;
  my $encode = $args->{charset} || '';

  #fast fast fast
  return eval qq^ sub {
    my \$col_v = \$_[0]->get_column('${col}');
    \$col_v = str2bytes('${encode}', \$col_v, Encode::FB_PERLQQ | Encode::LEAVE_SRC) if '${encode}';
    my \$salt   = substr(\$col_v, ${len});
    \$_[0]->_column_encoders->{${col}}->(\$_[1], \$salt) eq \$col_v;
  } ^ || die($@);
}

1;

__END__;

=head1 NAME

DBIx::Class::EncodedColumn::Digest - Digest backend

=head1 SYNOPSYS

  #SHA-1 / hex encoding / generate check method
  __PACKAGE__->add_columns(
    'password' => {
      data_type   => 'CHAR',
      size        => 40 + 10,
      encode_column => 1,
      encode_class  => 'Digest',
      encode_args   => {
          algorithm   => 'SHA-1',
          format      => 'hex',
          salt_length => 10,
          charset     => 'utf-8',
      },
      encode_check_method => 'check_password',
  }

  #SHA-256 / base64 encoding / generate check method
  __PACKAGE__->add_columns(
    'password' => {
      data_type   => 'CHAR',
      size        => 40,
      encode_column => 1,
      encode_class  => 'Digest',
      encode_check_method => 'check_password',
      #no  encode_args necessary because these are the defaults ...
  }


=head1 DESCRIPTION

=head1 ACCEPTED ARGUMENTS

=head2 format

The encoding to use for the digest. Valid values are 'binary', 'hex', and
'base64'. Will default to 'base64' if not specified.

=head2 algorithm

The digest algorithm to use for the digest. You may specify any valid L<Digest>
algorithm. Examples are L<MD5|Digest::MD5>, L<SHA-1|Digest::SHA>,
L<Whirlpool|Digest::Whirlpool> etc. Will default to 'SHA-256' if not specified.

See L<Digest> for supported digest algorithms.

=head2 salt_length

If you would like to use randomly generated salts to encode values make sure
this option is set to > 0. Salts will be automatically generated at encode time
and will be appended to the end of the digest. Please make sure that you
remember to make sure that to expand the size of your db column to have enough
space to store both the digest AND the salt. Please see list below for common
digest lengths.

=head2 charset

If the string is not restricted to ASCII, then you will need to
specify a character set encoding.

See L<Encode> for a list of encodings.

=head1 METHODS

=head2 make_encode_sub $column_name, \%encode_args

Returns a coderef that takes two arguments, a plaintext value and an optional
salt and returns the encoded value with the salt appended to the end of the
digest. If a salt is not provided and the salt_length option was greater than
zero it will be randomly generated.

=head2 make_check_sub $column_name, \%encode_args

Returns a coderef that takes the row object and a plaintext value and will
return a boolean if the plaintext matches the encoded value. This is typically
used for password authentication.

=head1 COMMON DIGEST LENGTHS

     CIPHER    | Binary | Base64 |  Hex
   ---------------------------------------
   | MD2       |   16   |   22   |  32  |
   | MD4       |   16   |   22   |  32  |
   | MD5       |   16   |   22   |  32  |
   | SHA-1     |   20   |   27   |  40  |
   | SHA-256   |   32   |   43   |  64  |
   | SHA-384   |   48   |   64   |  96  |
   | SHA-512   |   64   |   86   | 128  |
   | CRC-CCITT |    3   |    2   |   3  |
   | CRC-16    |    5   |    6   |   4  |
   | CRC-32    |   10   |   14   |   8  |
   | Adler-32  |    4   |    6   |   8  |
   | Whirlpool |   64   |   86   | 128  |
   | Haval-256 |   32   |   44   |  64  |
   ---------------------------------------

=head1 SEE ALSO

L<DBIx::Class::EncodedColumn::Crypt::Eksblowfish::Bcrypt>,
L<DBIx::Class::EncodedColumn>, L<Digest>

=head1 AUTHOR

Guillermo Roditi (groditi) <groditi@cpan.org>

Based on the Vienna WoC  ToDo manager code by Matt S trout (mst)

=head1 CONTRIBUTORS

See L<DBIx::Class::EncodedColumn>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
