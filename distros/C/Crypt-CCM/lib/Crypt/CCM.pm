package Crypt::CCM;

use 5.008006;
use strict;
use warnings;
use Carp;
use POSIX qw(ceil);

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Crypt::CCM', $VERSION);


sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
        cipher => undef,
        aad    => $args{'-aad'} || '',
        nonce  => $args{'-nonce'},
        taglen => $args{'-tag_length'} || 128/8,
    }, $class;

    $args{'-cipher'} |= 'Crypt::Rijndael';
    if (exists $args{'-key'}) {
        eval "require $args{'-cipher'}";
        if ($@) {
            croak $@;
        }
        $self->set_cipher($args{'-cipher'}->new($args{'-key'}));
    }

    return $self;
}


sub set_cipher {
    my $self = shift;
    $self->{cipher} = shift;
}


sub set_nonce {
    my $self = shift;
    $self->{nonce} = shift;
}
*set_iv = \&set_nonce;


sub set_aad {
    my $self = shift;
    $self->{aad} = shift;
}


sub set_tag_length {
    my $self = shift;
    $self->{taglen} = shift;
}


sub encrypt {
    my $self = shift;
    my $P = shift;
    my $cipher = $self->{cipher};
    my $blocksize = $cipher->blocksize;

    # Step 1. Apply the formatting function to (N, A, P)
    my $B = $self->_formatting_NAP($self->{nonce}, $self->{aad}, $P, $self->{taglen});
    # Step 2. Set Y0 = CHIPk(B0)
    # Step 3. For i = 1 to r, do Yi = CHIPk(Bi ^ Yi-1)
    my $Y = pack 'C*', (0) x $blocksize;

    for (my $i = 0; $i < length $B; $i += $blocksize) {
        $Y = $cipher->encrypt(substr($B, $i, $blocksize) ^ $Y);
    }

    # Step 4. Set T = MSBtlen(Yr)
    my $T = substr $Y, 0, $self->{taglen};
    # Step 5. Apply the counter generation function
    my $ctr = $self->_generate_counter_block();

    # Step 6. For j=0 to m, do Sj = CHIPk(CTRj)
    # Step 7. Set S=Si|S2|...|Sm
    my $S0 = $cipher->encrypt($ctr);
    my $S = '';
    for (my $i = 0; $i <= ceil(length($P) / $blocksize); $i++) {
        for (my $j = 15; $j > 0; $j--) {
            my $n = unpack 'C', substr $ctr, $j, 1;
            substr($ctr, $j, 1) = $n = pack 'C', $n+1;
            last if $n ne "\0";
        }
        $S .= $cipher->encrypt($ctr);
    }

    # Step 8. Return C=(P^MSBplen(S)) | (T ^ MSBtlen(S0))
    my $C = ($P ^ substr($S, 0, length $P)). ($T ^ substr($S0, 0, length $T));
    return $C;
}


sub decrypt {
    my $self = shift;
    my $C = shift;
    my $cipher = $self->{cipher};
    my $blocksize = $cipher->blocksize;
    # Step 1. If Clen <= Tlen, then return Invalid
    if (length $C <= $self->{taglen}) {
        carp 'cipher text is short';
        return undef;
    }
    # Step 2. Apply the counter generation function
    my $ctr = $self->_generate_counter_block();
    # Step 3. For j=0 to m, do Sj = CIPHk(CTRj);
    # Step 4. Set S=S1|S2|...|Sm
    my $S0 = $cipher->encrypt($ctr);
    my $S = '';
    for (my $i = 0; $i <= ceil(length($C) / $blocksize); $i++) {
        for (my $j = 15; $j > 0; $j--) {
            my $n = unpack 'C', substr $ctr, $j, 1;
            substr($ctr, $j, 1) = $n = pack 'C', $n+1;
            last if $n ne "\0";
        }
        $S .= $cipher->encrypt($ctr);
    }
    # Step 5. Set P=MSBtlen(C) ^ MSBclen-tlen(S)
    my $plen = length($C) - $self->{taglen};
    my $P = substr($C, 0, $plen) ^ substr($S, 0, $plen);
    # Step 6. Set T=LSBtlen(C) ^ MSBtlen(S0)
    my $T = substr($C, $self->{taglen}*-1) ^ substr($S0, 0, $self->{taglen});
    # Step 7.
    my $B = $self->_formatting_NAP($self->{nonce}, $self->{aad}, $P, $self->{taglen});
    # Step 8. Set Y0=CIPHk(B0)
    # Step 9. For i = 1 to r, do Yj=CHIPk(Bi^Yi-1)
    my $Y = pack 'H*', '00000000000000000000000000000000';
    for (my $i = 0; $i < length $B; $i += $blocksize) {
        $Y = $cipher->encrypt(substr($B, $i, $blocksize) ^ $Y);
    }
    # Step 10. If T != MSBtlen(Yr), then return INVALID, else return P.
    if (substr($Y, 0, $self->{taglen}) ne $T) {
        carp 'invalid TAG';
        return undef;
    }
    return $P;
}



sub _formatting_NAP {
    my $self = shift;
    my $nonce      = shift; # N
    my $assoc_data = shift; # A
    my $plain_text = shift; # P
    my $TAG_LENGTH = shift; # TAG length
    my $payload = '';

#    if (!check_length($TAG_LENGTH, length $plain_text, length $nonce, length $assoc_data)) {
#        return undef;
#    }
    my $counter_block = $self->_format_header($nonce, length $plain_text, $TAG_LENGTH, length $assoc_data);

    $payload = sprintf '%s%s%s',
        $counter_block,
        $self->_format_associated_data($assoc_data),
        $self->_format_payload($plain_text);
    return $payload;
}


sub _format_header {
    my $self = shift;
    my $nonce = shift;
    my $payload_len = shift;
    my $tag_len = shift;
    my $a_len = shift;

    my $q_len = 15 - length $nonce;
#    if (!check_length($tag_len, $q_len, length $nonce, $a_len)) {
#        croak 'invalid length';
#    }

    # Formatting of the Flags Octet in B0
    my $flags = pack 'C', 0;                                  # 7 RESERVED;
    $flags   |= pack 'C', ($a_len > 0) ? 0x40 : 0x00;         # 6 Adata
    $flags   |= pack 'C', ((($tag_len - 2) / 2) & 0x07) << 3; # 5..3 [(t-2)/2]3
    $flags   |= pack 'C', ($q_len - 1) & 0x07;                # 2..0 [q-1]3

    my $Q = '';
    my $l = $payload_len;
    for (my $i = 0; $i < $q_len; $i++) {
        $Q = pack('C', $l). $Q;
        $l >>= 8;
    }

    return $flags. $nonce. $Q;
}


sub _format_associated_data {
    my $self = shift;
    my $A = shift;
    my $payload = '';
    my $blocksize = $self->{cipher}->blocksize;

    my $a_len = length $A;
    if ($a_len == 0) {
        $payload = '';
    }
    if ($a_len <= 0xFEFF) {
        $payload = pack 'n', $a_len; 
    }
    elsif ($a_len <= 0xFFFFFFFF) {
        $payload = pack 'nN', 0xFFFE, $a_len;
    }
    elsif ($a_len < 2**64) {
        $payload = pack 'nNN', 0xFFFF, ($a_len >> 32), $a_len;
    }
    else {
        croak 'invalid a data length';
    }
    return $payload. $A. pack 'C*', (0) x (($blocksize - ($a_len) % $blocksize)-length $payload);
}


sub _format_payload {
    my $self = shift;
    my $P = shift;
    my $blocksize = $self->{cipher}->blocksize;

    my $l = length $P;
    my $pad = $l % $blocksize;
    if ($pad > 0) {
        $P .= pack 'C*', (0) x ($blocksize - $pad);
    }
    return $P;
}


sub _generate_counter_block {
    my $self = shift;
    my $nonce = $self->{nonce};

    my $q_len = 15 - length $nonce;
    my $flags  = pack 'C', 0;                    # 7, 6 RESERVED;
                                                 # 5, 4, 3 0
    $flags    |= pack 'C', ($q_len - 1) & 0x07;  # 2..0 [q-1]3

    my $ctr = pack 'C*', (0) x $q_len;
    return $flags. $nonce. $ctr;
}


1;
__END__

=head1 NAME

Crypt::CCM - CCM Mode for symmetric key block ciphers

=head1 SYNOPSIS

  use Crypt::CCM;
  use strict;
  
  my $ccm = Crypt::CCM->new(-key => $key);
  $ccm->set_nonce($random_nonce);
  $ccm->set_aad($assoc_data);
  my $cipher_text = $ccm->encrypt($plain_text);

=head1 DESCRIPTION

The module implements the CCM Mode for Authentication and Confidentiality.

=head1 API

=head2 new(ARGS)

  my $cipher = Crypt::CCM->new(
      -key        => $secret_key,
      -cipher     => 'Crypt::Rijndael',
      -nonce      => $nonce,
      -aad        => $associated_data,
      -tag_length => 128/8,
  );

The new() method creates an new Crypt::CCM object. it accepts a list of -artument => value pairs selected form the following list:

  Argument    Description
  --------    -----------
  -key        The encryption/decryption key
  -cipher     The cipher algorithm module name
  -nonce      The nonce. 
  -aad        The associated data (default '')
  -tag_length The bytes length of the MAC (default 128/8)

=head2 set_cipher($cipher)

  $cipher->set_cipher(Crypt::Rijndael->new($key));

=head2 set_nonce($nonce)

  $cipher->set_nonce($nonce);

This allows you to change the 'nonce'. allow 7,8,9,10,11,12,13 byte string.

=head2 set_aad($associated_data)

=head2 set_tag_length($length)

This allows you to change the MAC length. allow 4,6,8,10,12,14,16 byte string.

=head2 encrypt($plain_text);

  my $cipher_text = $cipher->encrypt($plain_text);

=head2 decrypt($cipher_text)

  my $plain_text = $cipher->decrypt($cipher_text);

=head1 EXAMPLE

=head2 Encrypt

  use Crypt::CCM;
  use strict;
  
  my $key             = pack 'H*', '00000000000000000000000000000000'; 
  my $nonce           = pack 'H*', '0000000000000000';
  my $associated_data = 'this is associated data';
  my $plain_text      = 'Hello World!';
  my $c = Crypt::CCM->new(
      -key    => $key,
      -cipher => 'Crypt::Rijndael'
  );
  $c->set_nonce($nonce);
  $c->set_aad($associated_data);
  my $cipher_text = $c->encrypt($plain_text);
  printf qq{encrypt: %s (hex)\n}, unpack 'H*', $cipher_text;

=head2 Decrypt

  use Crypt::CCM;
  use strict;
  
  my $key             = pack 'H*', '00000000000000000000000000000000'; 
  my $nonce           = pack 'H*', '0000000000000000';
  my $associated_data = 'this is associated data';
  my $cipher_text     = pack 'H*', '08da066234def1e5c7481a5a40b6aa4319332731a184426ac77f47de';
  
  my $c = Crypt::CCM->new(
      -key => $key,
      -cipher => 'Crypt::Rijndael'
  );
  $c->set_nonce($nonce);
  $c->set_aad($associated_data);
  my $plain_text = $c->decrypt($cipher_text);
  printf qq{decrypt: %s\n}, $plain_text;

=head1 SEE ALSO

NIST Special Publication 800-38C - Recommendation for Block Cipher Modes of Operation: The CCM Mode for Authentication and Confidentiality.

L<http://csrc.nist.gov/CryptoToolkit/modes/800-38_Series_Publications/SP800-38C.pdf>

RFC 3610 - Counter with CBC-MAC (CCM)

L<http://tools.ietf.org/html/rfc3610>

=head1 AUTHOR

Hiroyuki OYAMA, E<lt>oyama@module.jp<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Hiroyuki OYAMA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
