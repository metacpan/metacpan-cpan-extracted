package Crypt::Present;

use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.02';


use Carp;

my @SBoxBits;
my @SBoxByte;
my @SBoxByteRev;
my @V5Bits;
my @pLVec;
BEGIN {
  my @SBox = ( 0xC, 0x5, 0x6, 0xB, 0x9, 0x0, 0xA, 0xD, 0x3, 0xE, 0xF, 0x8, 0x4, 0x7, 0x1, 0x2 );
  @SBoxBits = map unpack('B4',chr($_<<4)), @SBox;
  @SBoxByte = map { my $h = ( $_ & 0xF0 ) >> 4;
		    my $l = ( $_ & 0x0F );
                    chr( ( $SBox[$h] << 4 ) | $SBox[$l] );
		  } ( 0 .. 255 );
  foreach ( 0 .. 255 ) { $SBoxByteRev[ord($SBoxByte[$_])] = chr $_; }

  push @V5Bits, unpack('B5',chr($_<<3)) foreach (0..31);

  my @pLayer; # ( 0, 16, 32, 48, ... );
  for ( my $i = 0; $i < 16; $i++ ) {
    $pLayer[$i*4+0] = $i;
    $pLayer[$i*4+1] = $i + 16;
    $pLayer[$i*4+2] = $i + 32;
    $pLayer[$i*4+3] = $i + 48;
  }
  for my $i ( 0 .. 63 ) {
    my $p  =  $pLayer[$i];
    my $iv =  int($i/8)*8+(7-($i%8));
    my $pv =  int($p/8)*8+(7-($p%8));
    $pLVec[$iv] = $pv;
  }
}


sub usage
{
  my ($package, $filename, $line, $subr) = caller(1);
  $Carp::CarpLevel = 2;
  croak "Usage: $subr(@_)";
}


sub blocksize   {   8; }
sub keysize     { my $k = $_[0]->{KEY}; return defined($k) ? length($k) : [ 80, 128 ]; }
sub min_keysize {  80; }
sub max_keysize { 128; }

my $genRoundKeys = sub ($) {
  my $self = shift;

  my $key = $self->{KEY};

  my @roundKeys;

  if ( length($key) == 10 ) {

    push @roundKeys, substr( $key, 0, 8 );
    $key = unpack('B*',$key);
    for ( my $i = 1; $i <= 31; $i++ ) {
      $key = $SBoxBits[ord(pack('B8','0000'.substr( $key, 61, 4 )))] . substr( $key, 65, 15 ) . substr( $key, 0, 61 );
      $key = substr( $key, 0, 60 ) . $V5Bits[(ord(pack("B5",substr( $key, 60, 5 )))>>3)^$i] . substr( $key, 65, 15 );
      push @roundKeys, substr( pack('B*',$key), 0, 8 );
    }

  } elsif ( length($key) == 16 ) {

    push @roundKeys, substr( $key, 0, 8 );
    $key = unpack('B*',$key);
    for ( my $i = 1; $i <= 31; $i++ ) {
      $key = $SBoxBits[ord(pack('B8','0000'.substr( $key, 61, 4 )))] . $SBoxBits[ord(pack('B8','0000'.substr( $key, 65, 4 )))] . substr( $key, 69, 59 ) . substr( $key, 0, 61 );
      $key = substr( $key, 0, 61 ) . $V5Bits[(ord(pack("B5",substr( $key, 61, 5 )))>>3)^$i] . substr( $key, 66, 62 );
      push @roundKeys, substr( pack('B*',$key), 0, 8 );
    }

  } else {
    die 'key size must be 80 or 128 but not '.(8 * length $key);
  }

  return $self->{ROUND_KEYS} = \@roundKeys;
};


sub new ($;$) {
  usage("new Present key") unless @_ == 2;
  my $class = shift;
  my $key   = shift;

  my $self = bless { KEY => $key }, $class;
  &$genRoundKeys($self);
  return $self;
}


my $null64 = "\x00" x 8; # 64 bit null value


sub encrypt ($$) {
  usage("encrypt data[8 bytes]") unless @_ == 2;
  my $self = shift;
  my $data = shift; # plaintext

  my $roundKeys = $self->{ROUND_KEYS}; # $roundKeys = &$genRoundKeys($self) if !defined $roundKeys;

  for ( my $i = 0; $i <= 30; $i++ ) {
    $data = $data ^ $roundKeys->[$i];
    $data = join '', map { $SBoxByte[ord($_)]; } split //, $data;
    { # permutate
      my $c = $null64;
      #foreach ( 0 .. 63 ) { vec( $c, $pLVec[$_], 1 ) = 1 if vec( $b, $_, 1 ); }
      for ( my $j = 64; $j--; ) { vec( $c, $pLVec[$j], 1 ) = 1 if vec( $data, $j, 1 ); }
      $data = $c;
    }
  }
  $data = $data ^ $roundKeys->[31];

  return $data;
}


sub decrypt ($$) {
  usage("decrypt data[8 bytes]") unless @_ == 2;
  my $self = shift;
  my $data = shift; # ciphertext

  my $roundKeys = $self->{ROUND_KEYS}; # $roundKeys = &$genRoundKeys($self) if !defined $roundKeys;

  $data = $data ^ $roundKeys->[31];
  for ( my $i = 30; $i >= 0; $i-- ) {
    { # permutate
      my $c = $null64;
      #foreach ( 0 .. 63 ) { vec( $c, $_, 1 ) = 1 if vec( $data, $pLVec[$_], 1 ); }
      for ( my $j = 64; $j--; ) { vec( $c, $j, 1 ) = 1 if vec( $data, $pLVec[$j], 1 ); }
      $data = $c;
    }
    $data = join '', map { $SBoxByteRev[ord($_)]; } split //, $data;
    $data = $data ^ $roundKeys->[$i];
  }

  return $data;
}


1;

__END__


=head1 NAME

Crypt::Present - Perl extension for Ultra-Lightweight PRESENT 64 bit block encryption module

=head1 SYNOPSIS

  use Crypt::Present;
  my $cipher = new Crypt::Present $key;
  my $ciphertext = $cipher->encrypt($plaintext);
  my $plaintext  = $cipher->decrypt($ciphertext);

  You probably want to use this in conjunction with
  a block chaining module like Crypt::CBC.

=head1 DESCRIPTION

Present is a ultra lightweight block encryption and can use key sizes of
80 or 128 bit (10 or 16 byte key). It is developed for use in RFID hardware
with minimum numer of cricuits.

Crypt::Present has the following methods:

=over 4

 blocksize()
 keysize()
 encrypt()
 decrypt()

=back

=head1 FUNCTIONS

=over 4

=item blocksize

Returns the size (in bytes) of the block cipher.

Crypt::Present::keysize returns [ 10, 16 ] due to its ability
to use 10 or 16 byte keys.b  More accurately, it shouldn't,
but it does anyway to play nicely with others.

=item new

        my $cipher = new Crypt::Present $key;

This creates a new Crypt::Present BlockCipher object, using $key,
where $key is a key of C<keysize()> bytes (10 or 16 bytes).

=item encrypt

        my $cipher = new Crypt::Present $key;
        my $ciphertext = $cipher->encrypt($plaintext);

This function encrypts $plaintext and returns the $ciphertext
where $plaintext and $ciphertext must be of C<blocksize()> bytes.
(hint:  Present is an 8 byte block cipher)

=item decrypt

        my $cipher = new Crypt::Present $key;
        my $plaintext = $cipher->decrypt($ciphertext);

This function decrypts $ciphertext and returns the $plaintext
where $plaintext and $ciphertext must be of C<blocksize()> bytes.
(hint:  see previous hint)

=back

=head1 EXAMPLE

        my $key = pack("H20", "0123456789");  # min. 8 bytes
        my $cipher = new Crypt::Present $key;
        my $ciphertext = $cipher->encrypt("plaintex");  # SEE NOTES
        print unpack("H16", $ciphertext), "\n";

=head1 PLATFORMS

        Since this is non endianess pure perl code, it will run under all plattforms.

=head1 NOTES

The module is capable of being used with Crypt::CBC.  You're
encouraged to read the perldoc for Crypt::CBC if you intend to
use this module for Cipher Block Chaining modes.  In fact, if
you have any intentions of encrypting more than eight bytes of
data with this, or any other block cipher, you're going to need
B<some> type of block chaining help.  Crypt::CBC tends to be
very good at this.  If you're not going to encrypt more than
eight bytes, your data B<must> be B<exactly> eight bytes long.
If need be, do your own padding. "\0" as a null byte is perfectly
valid to use for this.

=head1 SEE ALSO

PRESENT: An Ultra-Lightweight Block Cipher
 A. Bogdanov1, L.R. Knudsen2 , G. Leander1 , C. Paar1, A. Poschmann1,
     M.J.B. Robshaw3 , Y. Seurin3 , and C. Vikkelsoe2
 1 Horst-Görtz-Institute for IT-Security, Ruhr-University Bochum, Germany
 2 Technical University Denmark, DK-2800 Kgs. Lyngby, Denmark
 3 France Telecom R&D, Issy les Moulineaux, France

leander@rub.de, {abogdanov,cpaar,poschmann}@crypto.rub.de
                   lars@ramkilde.com, chv@mat.dtu.dk
          {matt.robshaw,yannick.seurin}@orange-ftgroup.com
http://www.emsec.rub.de/media/crypto/attachments/files/2010/04/present_ches2007.pdf

Crypt::CBC

=head1 COPYRIGHT

The implementation of the Present algorithm was developed by,
and is copyright of, Eduard Gode.

=head1 AUTHOR

Original algorithm, A. Bogdanov1, L.R. Knudsen2 , G. Leander1 , C. Paar1, A. Poschmann1,
M.J.B. Robshaw3 , Y. Seurin3 , and C. Vikkelsoe2.

Original implementation, Eduard Gode.

Current revision and maintainer:  Gduard Gode <eduard.gode@gode.de>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Eduard Gode

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12 or,
at your option, any later version of Perl 5 you may have available.


=cut
