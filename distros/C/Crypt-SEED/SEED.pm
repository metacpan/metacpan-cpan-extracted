package Crypt::SEED;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::SEED ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT_OK = ( );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

bootstrap Crypt::SEED $VERSION;

# Preloaded methods go here.

use constant BLOCKSIZE => 16;
use constant MAX_USER_KEYS => 99_999_999;

###
sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {
		rkeys => [], # idx => roundKey
		index=>{}, # userKey => idx
	};
	bless $self, $class;
	if(@_) {
		$self->addKeys(@_);
	}
	$self;
}

###
sub getIndex {
	my $this = shift;
	my $key = shift;

	if(length($key) == BLOCKSIZE) {
		# it must be a User Key, not an index.
		return defined($this->{index}->{$key}) ? $this->{index}->{$key} : undef;
	}
	defined($this->{rkeys}->[$key]) ? $key : undef;
}

###
sub encrypt {
	my $this = shift;
	my $data = shift;
	my $key = shift;
	my $idx = $this->getIndex($key);
	return undef unless defined $idx;

	my $len = length $data; # 16 bytes segment...
	#print "SEED Length=$len\n";
	my $cipher;

	my $i=0;
	while( $i < $len ) {
		my $buflen = ($len-$i)>BLOCKSIZE ? BLOCKSIZE : $len-$i;
		my $buf = substr($data, $i, $buflen);
		if($buflen<BLOCKSIZE) {
			$buf .= "\x00" x (BLOCKSIZE - $buflen);
		}
		my $cipbuf = _encrypt($buf,$this->{rkeys}->[$idx]);
		$cipher .= $cipbuf;
		$i += $buflen;
		#$len -= $buflen;
	}
	$cipher;
}

###
sub decrypt {
	my $this = shift;
	my $cipher = shift;
	my $key = shift;
	my $idx = $this->getIndex($key);
	return undef unless defined $idx;

	my $len = length $cipher;
	if($len % BLOCKSIZE) {
		eval { die "Cipher data corruption."; };
		return undef;
	}

	my $data;

	my $i=0;
	while( $i < $len ) {
		my $cipbuf = substr($cipher, $i, BLOCKSIZE);
		my $buf = _decrypt($cipbuf, $this->{rkeys}->[$idx]);
		$data .= $buf;
		$i += BLOCKSIZE;
		#$len -= BLOCKSIZE;
	}
	$data;
}

###
sub addKeys {
	my $this = shift;
	my $n = 0;
	foreach my $ukey (@_) {
		$n += ( $this->addKey($ukey)?1:0 );
	}
	$n;
}

###
sub addKey {
	my $this = shift;
	my $userKey = shift;
	my $cnt = @{ $this->{rkeys} };
	return undef if $cnt >=  MAX_USER_KEYS;

	if( length($userKey) != BLOCKSIZE ) {
		return undef; # eval { die "Invalid length of user key. (not 16)\n"; };
	}

	unless( defined $this->{index}->{$userKey} ) {
		$this->{index}->{$userKey} = $cnt;
		$this->{rkeys}->[$cnt] = _roundKey($userKey);
	}
	$this->{index}->{$userKey}; # return index;
}

###
sub removeKey {
	my $this = shift;
	my $userKey = shift;
	if( defined $this->{index}->{$userKey} ) {
		my $idx = $this->{index}->{$userKey};
		splice @{ $this->{rkeys} }, $idx, 1;
		delete $this->{index}->{$userKey};
		return $userKey;
	}
	undef;
}

###
sub replaceKey {
	my $this = shift;
	my $oldKey = shift;
	my $userKey = shift;

	if( length($userKey) != BLOCKSIZE || defined $this->{index}->{$userKey} ) {
		return undef; # eval { die "Invalid length of user key. (not 16)\n"; };
	}

	if( defined $this->{index}->{$oldKey} ) {
		my $idx = $this->{index}->{$oldKey};
		delete $this->{index}->{$oldKey};
		$this->{index}->{$userKey} = $idx;
		$this->{rkeys}->[$idx] = _roundKey($userKey);
		return $idx;
	}
	undef;
}

###
sub findUserKey {
	my $this = shift;
	my $idx = shift;
	if( $idx > $#{ $this->{rkeys} } or $idx =~ /\D/ ) {
		return undef;
	}

	foreach my $ukey ( keys %{ $this->{index} } ) {
		if( $this->{index}->{$ukey} == $idx ) {
			return $ukey;
		}
	}
	undef;
}

###
sub hasAKey {
	my $this = shift;
	defined $this->{index}->{$_[0]} ? 1 : undef;
}

###
sub userKeys {
	my $this = shift;
	sort { $this->{index}->{$a} <=> $this->{index}->{$b} } keys %{ $this->{index} };
}

###
sub keyIndex {
	my $this = shift;
	defined $this->{index}->{$_[0]} ? $this->{index}->{$_[0]} : undef;
}

###
sub count { $#{ shift->{rkeys} } + 1; }

1;

__END__

=head1 NAME

Crypt::SEED - Perl extension for SEED encryption/decryption algorithm.

=head1 SYNOPSIS

  use Crypt::SEED;

  my $seed = new Crypt::SEED();
  $seed->addKeys( @user_keys );
  # or
  my $seed = new Crypt::SEED( @user_keys );
  # Each key must be in 16 bytes in length
  my $seed = new Crypt::SEED( '0123456789ABCDEF' ); # userkey.

  my $cipher = $seed->encrypt( $source_data, '0123456789ABCDEF' );
  my $cipher = $seed->encrypt( $source_data, 3 );
  # 3 above is an user key index. starting from 0.
  my $recall = $seed->decrypt( $cipher, '0123456789ABCDEF' ); # by user key.
  my $recall = $seed->decrypt( $cipher, 3 ); # by index

  if( !$seed->hasAKey( $userKey ) ) {
  	$seed->addKey( $userKey );
  }
  my $index = $seed->replaceKey($userKey, $newKey);
  my $number_of_keys = $seed->count();
  my $idx = $seed->keyIndex($userKey);
  my $userKey = $seed->findUserKey($idx);
 
=head1 DESCRIPTION

This module provides the Perl community with the SEED encryption 
algorithm which has been made by Korean Information Security Agency(KISA,
http://www.kisa.or.kr).

SEED encryption/decryption uses a 'round key' which translated from a user key.
Whenever you add user keys to the module using new or addKey or addKeys, the
module will translate them to round keys and store them inside the module
with user keys. (Of course, in hash)
And, whenever you use the user key with encrypt, decrypt methods, the module
look for the matching round key from inside the module to do real job.

=head2 Important notes on Encoding

Please, E<lt>DO NOT use encoding 'blah';.E<gt>
I could not figure out how to restore those decoded bytes into an SV variable
in the script where 'use encoding...' inserted.
Do you know ? Let me know, please.

=head2 EXPORT

None by default.

=head1 Subroutines

=over

=item new

=over

  my $seed = new Crypt::SEED();
  my $seed = new Crypt::SEED('0123456789ABCDEF');
  my $seed = new Crypt::SEED( LIST or Array );

This will create an object of Crypt::SEED.
It can accept any number of user keys as its parameter.
An user key is consist of 16 characters exactly.
Every objects have its own key set.

=back

=item addKey

=over

  my $idx = $seed->addKey( $userKey );
  my $cipher_data = $seed->encrypt($plain_text, $idx);
  ...
  print SOCKET "$idx:$cipher_data\n"; # Do not send user key !!

You must add a key or more to the object before encryption or decryption.
An user key must be a 16 bytes long string.
Returns the index number of the key.
You can use this index number as an 'index' :-) and then you can deliver it
to the counter part who shares the same user key set.
(And do not deliver the user key itself for the sake of security.)
You can add user keys up to 99_999_999. (It is sufficient, isn't it? ;-)
Index number starts from 0, not 1.

=back

=item addKeys

=over

  $seed->addKeys( a list of user keys );

This method simply calls $seed->addKey as many as it has beed requested.
Returns the number of user keys actually added.(including the keys which
exists already)

=back


=item removeKey

=over

  $seed->removeKey($userKey) ne $userKey && warn "No such key";

This method removes the user key given from its key set and returns
the same user key string. If it does not find the key, returns undef.
Do not user index number. It will accept only user key. If you don't
know that, use findUserKey method as below;

  $seed->removeKey( $seed->findUserKey($idx) );

=back

=item replaceKey

=over

  $seed->replaceKey($oldKey, $newKey);

This will change an old key with a new key if exists.
Returns the index number or undef if it can not find the old key or if
it find the `$newKey' exists already.

=back

=item encrypt

=over

  my $cipher = $seed->encrypt($plain_text, $userKey);
  or
  my $cipher = $seed->encrypt($plain_text, $userKeyIndex);

Put the original data with a user key or index. You will get
encrypted data. The $cipher's length will be n-times of 16 exactly.
This can cause some confusion to the receiver outside because he
can not figure out the original length of $plain_text.
So, you should have to deliver the original length of $plain_text
to the receiver of $cipher if you and the partner concern about it.
Returns undef if the user key or index is wrong.

=back

=item decrypt

=over

  my $plain_text = $seed->decrypt($cipher, $userKey);
  or
  my $plain_text = $seed->decrypt($cipher, $userKeyIndex);

Reverse of encrypt. Again, you may get some garbage (series of 0x00)
at the end of $plain_text. If you know the original length of data,
you can chop it (or them).
Returns undef if the user key or index is wrong.

=back

=item findUserKey

=over

  my $userKey = $seed->findUserKey($idx);

Converts a key index to the matching user key string.
If it can not find the key, it will return undef value.

=back

=item hasAKey

=over

  if( !$seed->findUserKey($userKey) ) { ... }

Check if the user key exists and returns 1 or undef.

=back

=item keyIndex

=over

  my $idx = $seed->keyIndex($userKey);

Find the user key and returns matching index number.

=back

=item userKeys

=over

  my @userKeys = $seed->userKeys();

Returns every user key strings in the order of index numbers.

=back

=item count

=over

  $seed->count();

Returns the number of user keys added.

=back

=back

=head1 Rebuilding test set.

Test script test.pl uses SEED_VERIFY.txt for verification which
has been made using make_test_set.c.
You may want to rebuild the test set. If you want, you just
compile the c source file and run it (but after you run `make' once);

  $ vi make_test_set.c
  $ gcc -c make_test_set.c
  $ gcc -o make_test_set make_test_set.o SEED_KISA.o
  $ ./make_test_set > SEED_VERIFY.txt

Open make_test_set.c file using your ascii editor and edit `printVerificationData'
function call's second and third parameter. The second parameter is a user key 
and the third one is a string to encrypt.
Please make sure both strings are exactly 16 characters long.
Also keep the number of the function calls remains 5 times or more. (Now, there
are 66 calls)

=head1 About SEED (Quoted from an old document)

SEED is a symmetric encryption algorithm developed by KISA (Korea
Information Security Agency) and a group of experts since 1998.  The
input/output block size and key length of SEED is 128-bits.  SEED has
the 16-round Feistel structure.  A 128-bit input is divided into two
64-bit blocks and the right 64-bit block is an input to the round
function, with a 64-bit subkey generated from the key scheduling.

SEED is easily implemented in various software and hardware because
it takes less memory to implement than other algorithms and generates
keys without degrading the security of the algorithm.  In particular,
it can be effectively adopted in a computing environment with a
restricted resources, such as mobile devices and smart cards.

SEED is robust against known attacks including DC (Differential
cryptanalysis), LC (Linear cryptanalysis), and related key attacks.
SEED has gone through wide public scrutinizing procedures.  It has
been evaluated and is considered cryptographically secure by credible
organizations such as ISO/IEC JTC 1/SC 27 and Japan CRYPTREC
(Cryptography Research and Evaluation Committees)
[ISOSEED][CRYPTREC].

=head1 ENDIAN Matters...

This module contains codes affected by endian in SEED_KISA.c file,
the bytes order of multibyte data type such as integer, long, short, etc.
In almost all cases, the Makefile.PL file will handle this
matter for you.
But, test-failure cases are on which systems which have neither `Little Endian'
nore `Big Endian'.
In this cases, you may have to edit the SEED_KISA.c file by yourself to
modify `EndianChange', `GetB0', `GetB1', `GetB2' and `GetB3' macros `#define'd.
If you have tested on such a system, please let me know how-to.

=head1 AUTHOR

Jongpil Jeon, E<lt>blueabi@hanmail.netE<gt>.
Copyright (C) 2008 Jongpil Jeon. Perl "Artistic License" applied.


=head1 SEE ALSO

L<perl>.
ISO/IEC 18033-3 : Information technology - Security techniques 
  - Encryption algorithms - Part 3 : Block ciphers
IETF RFC 4269 : The SEED Encryption Algorithm

=cut

