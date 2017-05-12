#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "const-c.inc"
#define ENCIPHER 0
#define DECIPHER 1
#define L_BLOCK 128
#define BPB 8
#ifndef EOS
#define EOS '\0'
#endif
#ifndef EOL
#define EOL '\n'
#endif
int m[L_BLOCK];
int k[L_BLOCK];
int o[8] = { 7, 6, 2, 1, 5, 0, 3, 4 };
int pr[8] = { 2, 5, 4, 0, 3, 1, 7, 6 };
int s0[16] = { 12, 15, 7, 10, 14, 13, 11, 0, 2, 6, 3, 1, 9, 4, 5, 8 };
int s1[16] = { 7, 2, 14, 9, 3, 11, 0, 4, 12, 13, 1, 10, 6, 15, 8, 5 };
_lucifer(int direction){
	int tcbindex, tcbcontrol;
	int round, hi, lo, h_0, h_1;
	register int bit, temp1;
	int byte, index, v, tr[BPB];
	h_0 = 0;
	h_1 = 1;
	if( direction == DECIPHER )
		tcbcontrol = 8;
	else
		tcbcontrol = 0;
	for( round=0; round<16; round += 1 )
	{
		if( direction == DECIPHER )
			tcbcontrol = (tcbcontrol+1) & 0xF;
		tcbindex = tcbcontrol;
		for( byte = 0; byte < 8; byte +=1 )
		{
			lo = (m[(h_1*64)+(BPB*byte)+7])*8
				+(m[(h_1*64)+(BPB*byte)+6])*4
				+(m[(h_1*64)+(BPB*byte)+5])*2
				+(m[(h_1*64)+(BPB*byte)+4]);
			hi = (m[(h_1*64)+(BPB*byte)+3])*8
				+(m[(h_1*64)+(BPB*byte)+2])*4
				+(m[(h_1*64)+(BPB*byte)+1])*2
				+(m[(h_1*64)+(BPB*byte)+0]);

			v = (s0[lo]+16*s1[hi])*(1-k[(BPB*tcbindex)+byte])
				+(s0[hi]+16*s1[lo])*k[(BPB*tcbindex)+byte];

			for( temp1 = 0; temp1 < BPB; temp1 += 1 )
			{
				tr[temp1] = v & 0x1;
				v = v>>1;
			}

			for( bit = 0; bit < BPB; bit += 1 )
			{
				index = (o[bit]+byte) & 0x7;
				temp1 = m[(h_0*64)+(BPB*index)+bit]
					+k[(BPB*tcbcontrol)+pr[bit]]
					+tr[pr[bit]];
				m[(h_0*64)+(BPB*index)+bit] = temp1 & 0x1;
			}
		
			if( byte<7 || direction == DECIPHER )
				tcbcontrol = (tcbcontrol+1) & 0xF;
		}

		temp1 = h_0;
		h_0 = h_1;
		h_1 = temp1;
	}
	for( byte = 0; byte < 8; byte += 1 )
	{
		for( bit = 0; bit < BPB; bit += 1 )
		{
			temp1 = m[(BPB*byte)+bit];
			m[(BPB*byte)+bit] = m[64+(BPB*byte)+bit];
			m[64+(BPB*byte)+bit] = temp1;
		}
	}
	return;
}
_setkey(char *key){
	int i,c,counter;
	if((i = strlen(key)) < 16){
		for( ; i < 16; i += 1 )
			key[i] = EOS;
}
	for(counter = 0; counter < 16; counter += 1 )
	{
		c = key[counter] & 0xFF;
		for( i = 0; i < BPB; i += 1 )
		{
			k[(BPB*counter)+i] = c & 0x1;
			c = c>>1;
		}
	}
}
_preluc(const char* input,SV* buff,int direction){
	int counter = 0,output,i,j;
	char c;
	for(j = 0;j < strlen(input);j++) //will be optimized by compiler
	{
		c = input[j];
		if( counter == 16 )
		{
			_lucifer( direction );
			for( counter = 0; counter < 16; counter += 1 )
			{
				output = 0;
				for( i = BPB-1; i >= 0; i -= 1 )
				{
					output = (output<<1) + m[(BPB*counter)+i];
				}
				sv_catpvn(buff,(const char *) &output,1);
			}
			counter = 0;

		}
		for( i = 0; i < BPB; i += 1 )
		{
			m[(BPB*counter)+i] = c & 0x1;
			c = c>>1;
		}
		counter += 1;
	}
	for( ;counter < 16; counter += 1 )
		for( i = 0; i < BPB; i += 1 )
			m[(BPB*counter)+i] = 0;

	_lucifer( direction );
	for( counter = 0; counter < 16; counter += 1 )
	{
		output = 0;
		for( i = BPB-1; i >= 0; i -= 1 )
		{
			output = (output<<1) + m[(BPB*counter)+i];
		}
		sv_catpvn(buff,(const char *)&output,1);
	}
}
MODULE = Crypt::Lucifer		PACKAGE = Crypt::Lucifer		

INCLUDE: const-xs.inc

void
setkey(key)
SV* key;
CODE:
	STRLEN key_length;
	_setkey((char*) SvPV(key,key_length));
OUTPUT:

SV*
luc_encrypt(input)
SV* input
CODE:
	RETVAL = newSVpv("",0);
	_preluc(sv_pv(input),RETVAL,ENCIPHER);
OUTPUT:
	RETVAL

SV*
luc_decrypt(input)
SV* input
CODE:
	RETVAL = newSVpv("",0);
	_preluc(sv_pv(input),RETVAL,DECIPHER);
OUTPUT:
	RETVAL
