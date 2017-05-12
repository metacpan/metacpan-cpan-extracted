/*
      author: John Hughes (jhughes@frostburg.edu)
    modified: 3/16/02
*/

#include "platform.h"

/*
    function: rc6_generateKeySchedule

    description: This function takes a 16-, 24-, or 32-byte key and
                 generates the RC6 key schedule in array S.
*/

void rc6_generateKeySchedule(unsigned char* initKey,
                             unsigned int keyLength,
                             unsigned int S[]
                            )
{
	unsigned int L[8];  /* We need up to 32 bytes. */
    register unsigned int A, B, i, j, s, v;

    /* Point to the lowest byte of L. */

    unsigned char* bPtr = (unsigned char*)L;
    
    /* Move the bytes of initKey into L, little-endian fashion. */

    memcpy(bPtr, initKey, keyLength);

    /* Set S[0] to the constant P32, then generate the rest of S. */

    S[0] = 0xB7E15163;
    for (i = 1; i < 44; i++)
		S[i] = S[i - 1] + 0x9E3779B9;
    A = B = i = j = 0;
	v = 132;
    keyLength >>= 2; 
	for (s = 1; s <= v; s++)
	{
		A = S[i] = ROL(S[i] + A + B, 3);
		B = L[j] = ROL(L[j] + A + B, A + B);
		i = (i + 1) % 44;
		j = (j + 1) % keyLength;
	}
}

/*
    function: rc6_encrypt

    description: This function takes a 16-byte block and encrypts it into 
                 'output'.
*/

void rc6_encrypt(unsigned char* input, unsigned int S[], unsigned char* output)
{
    register unsigned int A, B, C, D;
    unsigned int regs[4];
    register unsigned int t, u, temp, j;
	unsigned char* regPtr;

    regPtr = (unsigned char*)&regs[0];
    memcpy(regPtr, input, 16);
    A = regs[0]; /* Cook up A, B, C, and D as our four 32-bit registers. */
    B = regs[1];
    C = regs[2];
    D = regs[3];
	B += S[0];
	D += S[1];
	for (j = 1; j <= 20; j++)  /* Perform 20 rounds. */
	{
	    t = ROL(B * ((B << 1) + 1), 5);
        u = ROL(D * ((D << 1) + 1), 5);
        A = ROL(A ^ t, u) + S[j << 1];
        C = ROL(C ^ u, t) + S[(j << 1) + 1];
		temp = A;
		A = B;
		B = C;
		C = D;
		D = temp;
    }
	A += S[42];
	C += S[43];
    regs[0] = A;
    regs[1] = B;
    regs[2] = C;
    regs[3] = D;
    memcpy(output, regPtr, 16);
}

/*
    function: rc6_decrypt

    description: This function takes a 16-byte block and decrypts it into 
                 'output.'
*/

void rc6_decrypt(unsigned char* input, unsigned int S[], unsigned char* output)
{
    register unsigned int A, B, C, D;
    unsigned int regs[4];
	register unsigned int t, u, temp, temp2, j;
	unsigned char* regPtr;

    regPtr = (unsigned char*)&regs[0];
    memcpy(regPtr, input, 16);
    A = regs[0];
    B = regs[1];
    C = regs[2];
    D = regs[3];
	C -= S[43];
	A -= S[42];
	for (j = 20; j >= 1; j--)
	{
	    temp = A;
		A = D;
		temp2 = B;
		B = temp;
		temp = C;
		C = temp2;
		D = temp;
		t = ROL(B * ((B << 1) + 1), 5);
		u = ROL(D * ((D << 1) + 1), 5);
		A = ROR(A - S[j << 1], u) ^ t;
		C = ROR(C - S[(j << 1) + 1], t) ^ u;
	}
	D -= S[1];
	B -= S[0];
    regs[0] = A;
    regs[1] = B;
    regs[2] = C;
    regs[3] = D;
    memcpy(output, regPtr, 16);
}

