##################################################################################################
#    This is an unofficial port of Chris Veness' AES implementation                              #
#    (c) Chris Veness 2005-2011. Right of free use is                                            #
#    granted for all commercial or non-commercial use under CC-BY 3.0 licence. No warranty of    #
#    any form is offered.  More info at http://www.movable-type.co.uk/scripts/aes.html           #
##################################################################################################
package Crypt::AES::CTR;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Encode;
use POSIX;
use MIME::Base64;
use Time::HiRes;
use Math::BigInt;

use vars qw(@ISA @EXPORT_OK $VERSION $sBox $rCon $padding);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(encrypt decrypt);


=head1 NAME

Crypt::AES::CTR - This is a port of Chris Veness' AES implementation. 

=head1 VERSION

Version 0.03

=cut

$VERSION = '0.03';

$padding="\n";

# sBox is pre-computed multiplicative inverse in GF(2^8) used in subBytes and keyExpansion [§5.1.1]
$sBox=[
	0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
	0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
	0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
	0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
	0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
	0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
	0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
	0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
	0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
	0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
	0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
	0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
	0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
	0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
	0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
	0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
];

# rCon is Round Constant used for the Key Expansion [1st col is 2^(r-1) in GF(2^8)] [§5.2]
$rCon=[
                       
                [(0x00, 0x00, 0x00, 0x00)],
		[(0x01, 0x00, 0x00, 0x00)],
		[(0x02, 0x00, 0x00, 0x00)],
		[(0x04, 0x00, 0x00, 0x00)],
		[(0x08, 0x00, 0x00, 0x00)],
		[(0x10, 0x00, 0x00, 0x00)],
		[(0x20, 0x00, 0x00, 0x00)],
		[(0x40, 0x00, 0x00, 0x00)],
		[(0x80, 0x00, 0x00, 0x00)],
		[(0x1b, 0x00, 0x00, 0x00)],
		[(0x36, 0x00, 0x00, 0x00)] 
                       
];




=head1 SYNOPSIS

This module encrypts and decrypts AES strings using CTR and Chris Veness' AES implementation. It is compatible with PHP encrypting and decrypting.

    use Crypt::AES::CTR;
    
    my $plaintext 'string';
    my $ciphertext = Crypt::AES::CTR::encrypt($plaintext,'password',256);
    $plaintext = Crypt::AES::CTR::decrypt($ciphertext,'password',256);


=head1 SUBROUTINES/METHODS

=head2 encrypt($plaintext, $key, $nbits)

 Encrypt a text using AES encryption in Counter mode of operation
 
 Unicode multi-byte character safe
 
 $plaintext - plaintext Source text to be encrypted
 $key - The password to use to generate a key
 $nbits - Number of bits to be used in the key (128, 192, or 256)
 
 returns encrypted text string

=cut


sub encrypt {
  my ($self,$plaintext,$password,$nBits,$keySchedule,$pad);

  if (ref($_[0]) eq 'Crypt::AES::CTR') { #check for oo
  $self=shift;
  $plaintext=shift;
  $password=shift||$self->{password};
  $nBits=shift||$self->{nbits};
  $keySchedule=$self->{keyschedule} if ($password eq $self->{password} and $nBits eq $self->{nbits});
  $pad=$self->{padding};
  } else {
  $plaintext=shift;
  $password=shift;
  $nBits=shift||0;
  $pad=$padding;
  }


  my $blockSize = 16;  # block size fixed at 16 bytes / 128 bits (Nb=4) for AES
  if (!($nBits==128 or $nBits==192 or $nBits==256)) { return ''; }  # standard allows 128/192/256 bit keys
  $plaintext =  Encode::encode_utf8($plaintext);
  $keySchedule=_key($password,$nBits) if !defined($keySchedule);

  # initialise 1st 8 bytes of counter block with nonce (NIST SP800-38A §B.2): [0-1] = millisec, 
  # [2-3] = random, [4-7] = seconds, together giving full sub-millisec uniqueness up to Feb 2106
  my @counterBlock = (('') x $blockSize);
  
  my $nonce = sprintf('%.3f',Time::HiRes::time());
  my ($nonceSec,$nonceMs) = split/\./, $nonce;
  my $nonceRnd = floor(rand(0.99999999)*0xffff);

  for (my $i=0; $i<2; $i++) { $counterBlock[$i]   = _urs($nonceMs , $i*8) & 0xff;}
  for (my $i=0; $i<2; $i++) { $counterBlock[$i+2] = _urs($nonceRnd , $i*8) & 0xff;}
  for (my $i=0; $i<4; $i++) { $counterBlock[$i+4] = _urs($nonceSec , $i*8) & 0xff;}

  # and convert it to a string to go on the front of the ciphertext
  my $ctrTxt = '';
  for (my $i=0; $i<8; $i++) { $ctrTxt .= chr($counterBlock[$i]); }

  # generate key schedule - an expansion of the key into distinct Key Rounds for each round
  my $blockCount = ceil(length($plaintext)/$blockSize);
  my @ciphertxt = ('') x $blockCount;  # ciphertext as array of strings
  
  for (my $b=0; $b<$blockCount; $b++) {
    # set counter (block #) in last 8 bytes of counter block (leaving nonce in 1st 8 bytes)
    # done in two stages for 32-bit ops: using two words allows us to go past 2^32 blocks (68GB)
    for (my $c=0; $c<4; $c++) { $counterBlock[15-$c] = _urs($b , $c*8) & 0xff; }
    for (my $c=0; $c<4; $c++) {
    #    $counterBlock[15-$c-4] = _urs($b/0x100000000 , $c*8);
        my $x = Math::BigInt->new($b);
        $x->bdiv('0x100000000');
        $counterBlock[15-$c-4] = _urs($x , $c*8);
    }
    my $cipherCntr = _cipher(\@counterBlock, $keySchedule,0);  # -- encrypt counter block --
    # block size is reduced on final block
    my $blockLength = $b<$blockCount-1 ? $blockSize : (length($plaintext)-1)%$blockSize+1;
    my @cipherChar = (('') x $blockLength);
    
    for (my $i=0; $i<$blockLength; $i++) {  # -- xor plaintext with ciphered counter char-by-char --
      $cipherChar[$i] = $cipherCntr->[$i] ^ ord(substr($plaintext, $b*$blockSize+$i, 1));
      $cipherChar[$i] = chr($cipherChar[$i]);
    }
    $ciphertxt[$b] = join('',@cipherChar);
 
   }
   my $ciphertext = $ctrTxt . join('',@ciphertxt);
   $ciphertext = MIME::Base64::encode_base64($ciphertext,$pad);  #// encode in base64
  
  
   return $ciphertext;
}


=head2 decrypt($ciphertext, $key, $nbits)

 Decrypt a text encrypted by AES in counter mode of operation
 
 $ciphertext - Source text to be decrypted
 $key - The password to use to generate a key
 $nbits - Number of bits to be used in the key (128, 192, or 256)
 
 returns decrypted text

=cut

sub decrypt {
  my ($self,$ciphertext,$password,$nBits,$keySchedule);
  
  if (ref($_[0]) eq 'Crypt::AES::CTR') { #check for oo
  $self=shift;
  $ciphertext=shift;
  $password=shift||$self->{password};
  $nBits=shift||$self->{nbits};
  $keySchedule=$self->{keyschedule} if ($password eq $self->{password} and $nBits eq $self->{nbits});
  } else {
  $ciphertext=shift;
  $password=shift;
  $nBits=shift||0;  
  }
  
    my $blockSize = 16;  # block size fixed at 16 bytes / 128 bits (Nb=4) for AES
    if (!($nBits==128 || $nBits==192 || $nBits==256)){
	return '';  # standard allows 128/192/256 bit keys
    }
    $ciphertext = MIME::Base64::decode_base64($ciphertext);
    $keySchedule=_key($password,$nBits) if !defined($keySchedule);
  
    # recover nonce from 1st element of ciphertext
    my @counterBlock = ();#array
    my $ctrTxt = substr($ciphertext, 0, 8);
    for (my $i=0; $i<8; $i++){
	$counterBlock[$i] = ord(substr($ctrTxt,$i,1));
    }

   
    # separate ciphertext into blocks (skipping past initial 8 bytes)
    my $nBlocks = ceil((length($ciphertext)-8) / $blockSize);
    my @ct = ('') x $nBlocks;#array
    for ($b=0; $b<$nBlocks; $b++){
	$ct[$b] = substr($ciphertext, 8+$b*$blockSize, 16);
    }
    my @ciphertext = @ct;  # ciphertext is now array of block-length strings

    # plaintext will get generated block-by-block into array of block-length strings
    my @plaintxt = ('') x $#ciphertext;#array

    for (my $b=0; $b<$nBlocks; $b++) {
	# set counter (block #) in last 8 bytes of counter block (leaving nonce in 1st 8 bytes)
	for (my $c=0; $c<4; $c++){
	    $counterBlock[15-$c] = _urs($b, $c*8) & 0xff;
	}
	for (my $c=0; $c<4; $c++){
	    #$counterBlock[15-$c-4] = _urs(($b+1)/0x100000000-1, $c*8) & 0xff;
            my $x = Math::BigInt->new(($b+1));
            $x->bdiv('0x100000000');
            $counterBlock[15-$c-4] = _urs($x, $c*8) & 0xff;
	}
        my $cipherCntr = _cipher(\@counterBlock, $keySchedule);  # encrypt counter block
	my @plaintxtByte = ('') x length($ciphertext[$b]);#array
	for (my $i=0; $i<length($ciphertext[$b]); $i++) {
	    # -- xor plaintext with ciphered counter byte-by-byte --
	    $plaintxtByte[$i] = $cipherCntr->[$i] ^ ord(substr($ciphertext[$b],$i,1));
	    $plaintxtByte[$i] = chr($plaintxtByte[$i]);
	}
	    $plaintxt[$b] = join('', @plaintxtByte); #php implode
    }
	  
    # join array of blocks into single plaintext string
    my $plaintext = join('',@plaintxt);
    $plaintext = Encode::decode_utf8($plaintext); #decode from UTF8 back to Unicode multi-byte chars
    return $plaintext;
}

=head2 aes_padding($padding)

 Override default padding(\n) for base64 encodes

=cut

sub aes_padding { $padding=shift; }

=head1 OO-INTERFACE

=head2 new

  my $crypt = Crypt::AES::CTR->new( key=>$key, nbits=>$nbits , padding => $padding  );

 #Unicode multi-byte character safe
 
 #$key - The password to use to generate a key
 #$nbits - Number of bits to be used in the key (128, 192, or 256)
 #$padding - What to use as padding for base64 encodes, default is \n (optional)
 
 #returns blessed reference
 
 $crypt->encrypt($plaintext); # use cached $key and $nbits from new declaration
 $crypt->encrypt($plaintext, $key, $nbits); #override $key and $nbits

 # see documentation above for encrypt function
 
 $crypt->decrypt($plaintext); # use cached $key and $nbits from new declaration
 $crypt->decrypt($plaintext, $key, $nbits); #override $key and $nbits

 # see documentation above for decrypt function 
 
=cut

# 00-style interface
sub new {
  my $class = shift;
  my $self = {};
  my %new = @_;
  bless($self, ($class||'Crypt::AES::CTR') );
  $self->{password}=$new{key};
  $self->{nbits}=$new{nbits}||0;
    if (!($self->{nbits}==128 || $self->{nbits}==192 || $self->{nbits}==256)){
	return '';  # standard allows 128/192/256 bit keys
    }  
  $self->{padding}=$new{padding}||$padding;
  $self->{keyschedule}=_key($self->{password},$self->{nbits});
  return $self;
}

# Unsigned right shift function, since Perl has neither >>> operator nor unsigned ints
#
# @param a  number to be shifted (32-bit integer)
# @param b  number of bits to shift a to the right (0..31)
# @return   a right-shifted and zero-filled by b bits
#
sub _urs {
	my($xa, $b) = @_;
	$xa &= 0xffffffff; $b &= 0x1f;  # (bounds check)
	if ($xa&0x80000000 && $b>0) {   # if left-most bit set
		$xa = ($xa>>1) & 0x7fffffff;   #   right-shift one bit & clear left-most bit
		$xa = $xa >> ($b-1);           #   remaining right-shifts
	} else {                       # otherwise
		$xa = ($xa>>$b);               #   use normal right-shift
	}
	return $xa;
}

# Handle key and keyschedule
sub _key {
  my $password = shift;
  my $nBits = shift;
  $password = Encode::encode_utf8($password);
  
  # use AES itself to encrypt password to get cipher key (using plain password as source for key 
  # expansion) - gives us well encrypted key (though hashed key might be preferred for prod'n use)
  my $nBytes = $nBits/8;  # no bytes in key (16/24/32)
  my @pwBytes = ('') x $nBytes;
  for (my $i=0; $i<$nBytes; $i++) {  # use 1st 16/24/32 chars of password for key
    $pwBytes[$i] = ($i>=length($password)) ? 0:ord(substr($password,$i,1));
  }
  
  my $key = _cipher(\@pwBytes, _keyExpansion(\@pwBytes));  # gives us 16-byte key
  
  #$key = [ @{$key},splice($key,0, $nBytes-16) ];  # expand key to 16/24/32 bytes long
  $key = [ @{$key}, map{ $key->[$_] } (0..($nBytes-16-1)) ]; # expand key to 16/24/32 bytes long
  
  # generate key schedule - an expansion of the key into distinct Key Rounds for each round
  my $keySchedule = _keyExpansion($key);

  return $keySchedule;
}

# AES Cipher function: encrypt 'input' with Rijndael algorithm
#
# @param input message as byte-array (16 bytes)
# @param w     key schedule as 2D byte-array (Nr+1 x Nb bytes) - 
#              generated from the cipher key by keyExpansion()
# @return      ciphertext as byte-array (16 bytes)
#
sub _cipher {    # main cipher function [§5.1]
    my $input = shift;
    my $w = shift;

    my $Nb = 4;                 # block size (in words): no of columns in state (fixed at 4 for AES)
    my $Nr = scalar(@{$w})/$Nb - 1; # no of rounds: 10/12/14 for 128/192/256-bit keys

    my $state = [[],[],[],[]];  # initialise 4xNb byte-array 'state' with input [§3.4]
    for(my $i=0; $i<4*$Nb; $i++){
	$state->[$i%4][floor($i/4)] = $input->[$i];
    }

    $state = _addRoundKey($state, $w, 0, $Nb);
    for(my $round=1; $round<$Nr; $round++) {  # apply Nr rounds
	$state = _subBytes($state, $Nb);
	$state = _shiftRows($state, $Nb);
	$state = _mixColumns($state, $Nb);
	$state = _addRoundKey($state, $w, $round, $Nb);
    }
    $state = _subBytes($state, $Nb);
    $state = _shiftRows($state, $Nb);
    $state = _addRoundKey($state, $w, $Nr, $Nb);
    my @output = ('') x (4*$Nb);  # convert state to 1-d array before returning [§3.4]
    for (my $i=0; $i<4*$Nb; $i++){
	$output[$i] = $state->[$i%4][floor($i/4)];
    }

    return \@output;
}

# Key expansion for Rijndael cipher(): performs key expansion on cipher key
# to generate a key schedule
#
# @param key cipher key byte-array (16 bytes)
# @return    key schedule as 2D byte-array (Nr+1 x Nb bytes)
#

sub _keyExpansion {  # generate Key Schedule from Cipher Key [§5.2]
    my $key = shift;
    my $Nb = 4;              # block size (in words): no of columns in state (fixed at 4 for AES)
    my $Nk = scalar(@{$key})/4;  # key length (in words): 4/6/8 for 128/192/256-bit keys
    my $Nr = $Nk + 6;        # no of rounds: 10/12/14 for 128/192/256-bit keys

    my @w = ('') x ($Nb*($Nr+1));#array
    for(my $i=0; $i<$Nb*($Nr+1); $i++){
	$w[$i] = 0;
    }
    my @temp = ('0') x 4;#array
    for(my $i=0; $i<$Nk; $i++) {
	my $r = [$key->[4*$i], $key->[4*$i+1], $key->[4*$i+2], $key->[4*$i+3]];
	$w[$i] = $r;
    }


    for (my $i=$Nk; $i<($Nb*($Nr+1)); $i++) {
	$w[$i] = [(('0') x 4)];#array

	for (my $t=0; $t<4; $t++){
	    $temp[$t] = $w[$i-1][$t];
	} 
	if($i % $Nk == 0){
            my $temp1 = _rotWord(\@temp);
	    my $temp2 = _subWord($temp1);
	    @temp = @$temp2;

	
	    for (my $t=0; $t<4; $t++){
                $temp[$t] ^= $rCon->[$i/$Nk][$t];
	    }

	} elsif ($Nk > 6 and ($i % $Nk) == 4) {

	    my $temp2 = _subWord(\@temp);
	    @temp = @$temp2;


	}
	for (my $t=0; $t<4; $t++){
	    $w[$i][$t] = $w[$i-$Nk][$t] ^ $temp[$t];
	}

    }
    
    return \@w;
}




#  ---- remaining routines are private, not called externally ----

sub _subBytes {    # apply SBox to state S [§5.1.1]
    my $s = shift;
    my $Nb = shift;

    for (my $r=0; $r<4; $r++) {
	for (my $c=0; $c<$Nb; $c++){
	    $s->[$r][$c] = $sBox->[$s->[$r][$c]];
	}
    }
    return $s;
}

sub _shiftRows {    # shift row r of state S left by r bytes [§5.1.2]
    my $s = shift;
    my $Nb = shift;

    my @t = ('') x 4;#array
    for (my $r=1; $r<4; $r++) {
	for(my $c=0; $c<4; $c++){
	    $t[$c] = $s->[$r][($c+$r)%$Nb];  # shift into temp copy
	}
	for(my $c=0; $c<4; $c++){
	    $s->[$r][$c] = $t[$c];           # and copy back
	}
	}# note that this will work for Nb=4,5,6, but not 7,8 (always 4 for AES):
    return $s;  # see fp.gladman.plus.com/cryptography_technology/rijndael/aes.spec.311.pdf 
}

sub _mixColumns {   # combine bytes of each col of state S [§5.1.3]
    my $s = shift;
    my $Nb = shift;
    
    for(my $c=0; $c<4; $c++) {
	my @a = ('') x 4;  # 'a' is a copy of the current column from 's'
	my @b = ('') x 4;  # 'b' is a•{02} in GF(2^8)
	for(my $i=0; $i<4; $i++) {
	    $a[$i] = $s->[$i][$c];
	    $b[$i] = $s->[$i][$c]&0x80 ? $s->[$i][$c]<<1 ^ 0x011b : $s->[$i][$c]<<1;

	}
	# a[n] ^ b[n] is a•{03} in GF(2^8) #MYFIXED $xb
	$s->[0][$c] = $b[0] ^ $a[1] ^ $b[1] ^ $a[2] ^ $a[3]; # 2*a0 + 3*a1 + a2 + a3
	$s->[1][$c] = $a[0] ^ $b[1] ^ $a[2] ^ $b[2] ^ $a[3]; # a0 * 2*a1 + 3*a2 + a3
	$s->[2][$c] = $a[0] ^ $a[1] ^ $b[2] ^ $a[3] ^ $b[3]; # a0 + a1 + 2*a2 + 3*a3
	$s->[3][$c] = $a[0] ^ $b[0] ^ $a[1] ^ $a[2] ^ $b[3]; # 3*a0 + a1 + a2 + 2*a3



    }
    return $s;
}

sub _addRoundKey {  # xor Round Key into state S [§5.1.4]
    my($state, $w, $rnd, $Nb) = @_;

    for (my $r=0; $r<4; $r++) {
	for (my $c=0; $c<$Nb; $c++){
	    $state->[$r][$c] ^= $w->[$rnd*4+$c][$r];
	}
    }

    return $state;
}


sub _subWord {    # apply SBox to 4-byte word w
    my $w = shift;
    for(my $i=0; $i<4; $i++){
	$w->[$i] = $sBox->[$w->[$i]];
    }
    return $w;
}

sub _rotWord {    # rotate 4-byte word w left by one byte
    my $w = shift;

    my $tmp = $w->[0];
    for(my $i=0; $i<3; $i++){
	$w->[$i] = $w->[$i+1];
    }
    $w->[3] = $tmp;
    return $w;
}






=head1 AUTHOR

KnowZero

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-aes-ctr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-AES-CTR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::AES::CTR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-AES-CTR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-AES-CTR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-AES-CTR>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-AES-CTR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This is an unofficial port of Chris Veness' AES implementation
Copyright (C) Chris Veness 2005-2011. Right of free use is granted for all commercial or non-commercial use under CC-BY 3.0 licence. No warranty of any form is offered. 

Released under the
L<http://creativecommons.org/licenses/by/3.0/>
Creative Commons Attribution 3.0 Unported License

For more information:
L<http://www.movable-type.co.uk/scripts/aes.html>

=cut

1; # End of Crypt::AES::CTR
