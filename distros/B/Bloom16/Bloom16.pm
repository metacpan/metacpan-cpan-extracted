package Bloom16;

require 5.005_62;
use strict;
use vars qw( $VERSION );

use Digest::MD5 qw(md5);

$VERSION = '0.01';

use Inline C => 'DATA',
			VERSION => '0.01',
			NAME => 'Bloom16';

sub filter {
	my $self = shift;
	my $data = shift;
	return _filter( $self, md5($data) );
}

1;

__DATA__

=pod

=head1 NAME

Bloom16 - Perl extension for "threshold" Bloom filters

=head1 SYNOPSIS

  use Bloom16;
  $b = new Bloom16;

=head1 DESCRIPTION

Efficiently recognize how many times an item has been seen.

Bloom filters are a very nifty way of determining set membership to a high degree of accuracy with minimal storage requirements. Use it if a small number of false positives are compatible with your requirements.

The idea is to create a large bit vector and generate several hash codes for each data item. Flip all corresponding bits to "1", so that if any bit is "0" when entering an item, it is garuanteed to be new. If all bits are "1" it has already been seen (to a high probability). False positives are very low until a certain capacity has been reached, namely ~0.15N where N is the number of bits in the vector.

In other words, you need less than one byte for recognizing each item. This implementation adds a counter of 4 bits (bringing requirements to ~4 bytes per item) which is used to give the number of times an item has been seen (up to 15). This is useful if you need to output items only once but you don't want to have to store all seen items, and further that you only want to output them if they occur more than say 10 times. Simply output only in the case that the filter has seen them exactly 10 times.

The particular constants used in this implementation are:
K = number of hashes per item (4)
N = number of bits in hash (I*8) rounded to the next-highest power of 2.

This yields 4-8 megs per million items to store.


=head1 AUTHOR

bunghole@pobox.com

=head1 SEE ALSO

=cut


__C__

typedef struct {
	u_long length; //length in half-bytes.
	u_long onbits; 
	u_long threshold;
	int full;
	u_char* data;
} Bloom16;

SV* new( char* class, long bits ){

	SV* obj_ref = newSViv(0);
	SV* obj     = newSVrv(obj_ref, class);

	Bloom16* bloom;

	u_long len_ints;

	len_ints = (u_long) bits/(sizeof(u_char)*8);
    bloom = malloc( sizeof(Bloom16) );
	bloom->data = calloc(len_ints, sizeof(u_char));
	bloom->length = len_ints*2;
	bloom->onbits = 0;
	bloom->threshold = (u_long) bits/8;
	bloom->full = 0;

	sv_setiv(obj, (IV)bloom);
	SvREADONLY_on(obj);
	return obj_ref;
}

void DESTROY(SV* obj) {
    Bloom16* bloom = (Bloom16*)SvIV(SvRV(obj));
	//printf("DESTROYed a Bloom16 (%u)\n", isr->length);
    free(bloom->data);
	free(bloom);
}

int _filter(SV* obj, SV* md5){
	int slen;
	char* md5_str;
	int s = 0, i = 0;
	int min = 15;
	Bloom16* bloom = (Bloom16*)SvIV(SvRV(obj));;

// This is necessary to pass true perl strings to C...
	md5_str = SvPV(md5, slen);

// This for loop could be replaced with a memcpy if I knew 
// how to keep it from messing up.
	for( i = 0; i < 4; i++ ){
		u_char zeromask = 15;
		u_long n = 0;
		u_long j = 0;
		u_char q = 0;
		u_char p = 0;
		n |= (unsigned char) md5_str[s++]; n <<= 8;
		n |= (unsigned char) md5_str[s++]; n <<= 8;
		n |= (unsigned char) md5_str[s++]; n <<= 8;
		n |= (unsigned char) md5_str[s++];

//printf("Creating position %u from %u, %u, %u, %u\n", n, md5_str[s-4],md5_str[s-3],md5_str[s-2],md5_str[s-1]);



		n %= bloom->length; //table position overall.
		j = (u_long) n / 2; //integer position.
		q = (u_char) n % 2; //half-byte position within integer.
		p = (u_char) bloom->data[j]; // byte containing info.

		// q is either 0 or 1 depending on which half of the char holds 
		// the desired info.
		q *= 4;
		p <<= q;
		p >>= 4;
		
//printf("n = %u, j = %u, q = %u, p = %u\n", n,j,q,p);

		// now the lower half of p has the number we want.

		if( p < min ){
			min = p;
		}
		p++;
		if(p > 15){
			p = 15;
		}
		if(p == 1){
			bloom->onbits++;
		}
		if(q == 0){
			p <<= 4;
		}

		// replace the half-byte into data by zeroing the 
		// former part, then or-ing p into it.
		zeromask <<= q;
		bloom->data[j] &= zeromask;
		bloom->data[j] |= p;
//printf("n = %u, j = %u, q = %u, p = %u, min = %u\n\n",n,j,q,p,min);
	}

	return min;
}

int reset(SV* obj){
	Bloom16* bloom = (Bloom16*)SvIV(SvRV(obj));
	memset(bloom->data, 0, (size_t) (bloom->length/8) );
	bloom->onbits = 0;
	bloom->full = 0;
}

long length(SV* obj){
	return ((Bloom16*)SvIV(SvRV(obj)))->length;
}

long onbits(SV* obj){
	return ((Bloom16*)SvIV(SvRV(obj)))->onbits;
}

long threshold(SV* obj){
	return ((Bloom16*)SvIV(SvRV(obj)))->threshold;
}

int full(SV* obj){
	return ((Bloom16*)SvIV(SvRV(obj)))->full;
}



