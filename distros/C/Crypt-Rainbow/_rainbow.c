/***************************************************** 
 * Rainbow Cipher header file for ANSI C             *
 *   Chang-Hyi Lee  and  Jeong-Soo Kim                *
 *   Digital Communication Lab.,                     *
 *   SAIT, Samsung Advanced Institute of Technology  *
 *****************************************************/

#undef BIG_ENDIAN
#ifndef LITTLE_ENDIAN   /* jcd */
#define LITTLE_ENDIAN
#endif

#include <stdio.h>
/* #include <stdlib.h> */
#include <time.h>
#include <memory.h>
/* #include <assert.h> */
#include <string.h>

/*  Defines:  */
#define     BITSPERBLOCK    128  /*  Number of bits in a cipher block  */
#define     BLOCKSIZE       (BITSPERBLOCK/8)  /* # bytes in a cipher block  */
#define     BLOCK_WSIZE     (BITSPERBLOCK/32) /* # WORD32's in a cipher block  */
#define     DIR_ENCRYPT     0    /*  Are we encrpyting?  */
#define     DIR_DECRYPT     1    /*  Are we decrpyting?  */
#define     MODE_ECB        1    /*  Are we ciphering in ECB mode?   */
#define     MODE_CBC        2    /*  Are we ciphering in CBC mode?   */
#define     MODE_CFB1       3    /*  Are we ciphering in 1-bit CFB mode? */
#define     R_TRUE            1
#define     R_FALSE           0


/*  Error Codes :  */
#define     BAD_KEY_DIR        -1  /*  Key direction is invalid, e.g.,
					unknown value */
#define     BAD_KEY_MAT        -2  /*  Key material not of correct 
					length */
#define     BAD_KEY_INSTANCE   -3  /*  Key passed is not valid  */
#define     BAD_KEY_LENGTH     -4  /*  Key size in bits is wrong */
#define     BAD_CIPHER_MODE    -5  /*  Params struct passed to 
					cipherInit invalid */
#define     BAD_CIPHER_STATE   -6  /*  Cipher in wrong state (e.g., not 
					initialized) */
#define     BAD_CIPHER_INPUT   -7  /*  Wrong cipher input length */

#define     MAX_KEY_SIZE	   32  /* # of ASCII char's needed to
					represent a key */
#define     MAX_IV_SIZE		   16  /* # bytes needed to
					represent an IV  */
#define     SCHEDULE_KEY_SIZE  16*2*(R+1) /* total size of scheduled key */

#define     R           7   /* proposed encryption round */


/*  Typedefs:  */
    typedef unsigned char	BYTE;	 /*  8 bit */
    typedef unsigned short	WORD16;	 /* 16 bit */
#ifdef __alpha
	typedef unsigned int	WORD32;	 /* 32 bit */
#else  /* !__alpha */
	typedef unsigned long	WORD32;	 /* 32 bit */
#endif /* :__alpha */


/*  The structure for key information */
typedef struct keyInstance {
      BYTE  direction;	/*  In our case this is negligible, since this
	      structure involve both enc/dec Keys */
      int   keyLen;	    /*  Length of the key  */
      char  keyMaterial[MAX_KEY_SIZE+1];  /*  Raw key data in ASCII */
      BYTE	KS_Enc[SCHEDULE_KEY_SIZE];     /*  encryption key */
	  BYTE	KS_Dec[SCHEDULE_KEY_SIZE];     /*  decryption key */
      } keyInstance;

/*  The structure for cipher information */
typedef struct cipherInstance {
      BYTE  mode;            /* MODE_ECB, MODE_CBC, or MODE_CFB1 */
      BYTE  IV[MAX_IV_SIZE]; /* A possible Initialization Vector for 
      					ciphering */
	  BYTE  RED[512];        /* The S-box table RED=[f]|[f^(-1)] */
      int   blockSize;    	 /* Here It is fixed : 128  */
      } cipherInstance;

/*  Function protoypes  */
int makeKey(keyInstance *key, BYTE direction, int keyLen,
			char *keyMaterial);

int cipherInit(cipherInstance *cipher, BYTE mode, char *IV);

int blockEncrypt(cipherInstance *cipher, keyInstance *key, BYTE *input, 
			int inputLen, BYTE *outBuffer);

int blockDecrypt(cipherInstance *cipher, keyInstance *key, BYTE *input,
			int inputLen, BYTE *outBuffer);


#define     WD(a)    ((WORD32 *)(a)) /* for utility */

/* platform endianness: */
#if !defined(LITTLE_ENDIAN) && !defined(BIG_ENDIAN)
#	if defined(_M_IX86) || defined(_M_I86) || defined(__alpha)
#		define LITTLE_ENDIAN
#	else
#		error "Either LITTLE_ENDIAN or BIG_ENDIAN must be defined"
#	endif
#elif defined(LITTLE_ENDIAN) && defined(BIG_ENDIAN)
#	error "LITTLE_ENDIAN and BIG_ENDIAN must not be simultaneously defined"
#endif /* !LITTLE_ENDIAN && !BIG_ENDIAN */


/* Microsoft C / Intel x86 optimizations: */
#if defined(_MSC_VER) && defined(_M_IX86) 
#	define HARDWARE_ROTATIONS
#	define ASSEMBLER_CORE
#endif  /* :(_MSC_VER && _M_IX86) */


#ifdef HARDWARE_ROTATIONS
#	define ROTL(x, s) (_lrotl ((x), (s)))
#	define ROTR(x, s) (_lrotr ((x), (s)))
#else  /* !HARDWARE_ROTATIONS */
#	define ROTL(x, s) (((x) << (s)) | ((x) >> (32 - (s))))
#	define ROTR(x, s) (((x) >> (s)) | ((x) << (32 - (s))))
#endif /* :HARDWARE_ROTATIONS */

#ifdef LITTLE_ENDIAN
#	ifdef MASKED_BYTE_EXTRACTION
#		define GETB0(x) (((x)      ) & 0xffU)
#		define GETB1(x) (((x) >>  8) & 0xffU)
#		define GETB2(x) (((x) >> 16) & 0xffU)
#		define GETB3(x) (((x) >> 24) & 0xffU)
#	else  /* !MASKED_BYTE_EXTRACTION */
#		define GETB0(x) ((BYTE)  ((x)      ))
#		define GETB1(x) ((BYTE)  ((x) >>  8))
#		define GETB2(x) ((BYTE)  ((x) >> 16))
#		define GETB3(x) ((BYTE)  ((x) >> 24))
#	endif /* :MASKED_BYTE_EXTRACTION */
#	define PUTB0(x) ((WORD32) (x)      )
#	define PUTB1(x) ((WORD32) (x) <<  8)
#	define PUTB2(x) ((WORD32) (x) << 16)
#	define PUTB3(x) ((WORD32) (x) << 24)
#else  /* !LITTLE_ENDIAN */
#	ifdef MASKED_BYTE_EXTRACTION
#		define GETB0(x) (((x) >> 24) & 0xffU)
#		define GETB1(x) (((x) >> 16) & 0xffU)
#		define GETB2(x) (((x) >>  8) & 0xffU)
#		define GETB3(x) (((x)      ) & 0xffU)
#	else  /* !MASKED_BYTE_EXTRACTION */
#		define GETB0(x) ((BYTE)  ((x) >> 24))
#		define GETB1(x) ((BYTE)  ((x) >> 16))
#		define GETB2(x) ((BYTE)  ((x) >>  8))
#		define GETB3(x) ((BYTE)  ((x)      ))
#	endif /* :MASKED_BYTE_EXTRACTION */
#	define PUTB0(x) ((WORD32) (x) << 24)
#	define PUTB1(x) ((WORD32) (x) << 16)
#	define PUTB2(x) ((WORD32) (x) <<  8)
#	define PUTB3(x) ((WORD32) (x)      )
#endif /* :LITTLE_ENDIAN */

#define COPY_BLOCK(trg, src) \
{ \
	(trg)[0] = (src)[0]; \
	(trg)[1] = (src)[1]; \
	(trg)[2] = (src)[2]; \
	(trg)[3] = (src)[3]; \
} /* COPY_BLOCK */ 


/******** from here, represented key generation ********/

static void rainbowMixing (WORD32 *roundKey)
{ /* key mixing procedure via rorarions and XOR operations */
	roundKey[0] = ROTR(roundKey[0],3)^
		ROTR(roundKey[1],5)^
		ROTR(roundKey[2],7)^
		ROTR(roundKey[3],11)^0xb7e15163;
	roundKey[1] = ROTR(roundKey[0],5)^
		ROTR(roundKey[1],7)^
		ROTR(roundKey[2],11)^
		ROTR(roundKey[3],3)^0xb7e15163;
	roundKey[2] = ROTR(roundKey[0],7)^
		ROTR(roundKey[1],11)^
		ROTR(roundKey[2],3)^
		ROTR(roundKey[3],5)^0xb7e15163;
	roundKey[3] = ROTR(roundKey[0],11)^
		ROTR(roundKey[1],3)^
		ROTR(roundKey[2],5)^
		ROTR(roundKey[3],7)^0xb7e15163;
} /* rainbowMixing */

/* make decryption key to satisfy the cipher's self reciprocality(self-invertable) */
#define SUB_KEY_SCROL(K_, K, M, i) \
{ \
	(K_)[i] = ((K)[0]&(M)[i])^((K)[1]&(M)[(i+1)%4])^   \
		((K)[2]&(M)[(i+2)%4])^((K)[3]&(M)[(i+3)%4]); \
}

int makeKey(keyInstance *key, BYTE direction, int keyLen,
			char *keyMaterial)
{
	WORD32 *get, *encKey, *decKey;	
	int i, j;


	if (key == NULL) return BAD_KEY_INSTANCE;
	i = keyLen%32;
	if (i != 0) return BAD_KEY_LENGTH;
	i = keyLen/8;
	if (!((16<=i)&&(i<=32))) return BAD_KEY_MAT;
		
	key->direction = direction;
	key->keyLen = keyLen;
	strncpy (key->keyMaterial, keyMaterial, keyLen);

	get = WD(keyMaterial);
	encKey = WD(key->KS_Enc);
	COPY_BLOCK(encKey, get); /* put the key material to the first key-block */

	i = (keyLen-128)/32;		
	encKey += 4;
    COPY_BLOCK(encKey, (encKey-4)); 
	
	get += 4;
	for (j=0; j<i; j++) encKey[j] ^= get[j]; 
	           /* to make it applicable to |key material|=128,160,192,...,256 in bits */
	rainbowMixing(encKey);

	for (i=2; i < 2*(R+1); i++) {
		/* apply the rainbowMixing function: */
		encKey += 4;
		COPY_BLOCK(encKey, encKey-4);
		rainbowMixing(encKey);
	}

	
	encKey = (WD(key->KS_Enc))+4;
	for (j = 0; j < R+1; j++) {
		encKey[0] = encKey[1]^encKey[2]^encKey[3]^0xffffffffL;
		encKey += 8;
	}  /* to make the key-masking be self-invertable */

	decKey = (WD(key->KS_Dec))+4;
	for (j = 0; j < R+1; j++) {
		encKey -= 8;
		COPY_BLOCK(decKey, encKey);
		decKey += 8;
	}

	encKey = (WD(key->KS_Enc)) + 8*R;
	decKey = WD(key->KS_Dec);

	/* to make the whole encryption process be self-reciprocal! */
	for (j = 0; j < R+1; j++) {
		SUB_KEY_SCROL(decKey,encKey,(encKey+4),0);
		SUB_KEY_SCROL(decKey,encKey,(encKey+4),1);
		SUB_KEY_SCROL(decKey,encKey,(encKey+4),2);
		SUB_KEY_SCROL(decKey,encKey,(encKey+4),3);
		decKey += 8;
		encKey -= 8;
	}


	return R_TRUE;
} /* rainbow-RoundKeys are generated*/

typedef BYTE base[8]; 

BYTE RDC[15]; /* polynomial,p(x), reduction table */
BYTE MTX[8]; /* basis changing matrix */

static BYTE field_mul (BYTE a, BYTE b);
static void make_MTX (base b1, base b2);
static BYTE coef_cnv (BYTE coef, base MATRIX);


int cipherInit(cipherInstance *cipher, BYTE mode, char *IV)
{
	BYTE *vector,irrpoly=0xa9, g, t1,t2,t3,t;
	base pb, nb;  /* pb: standard basis;  nb: normal basis */
	int i, j;


	if (cipher == NULL) return BAD_CIPHER_STATE;
	if (!((1<=mode)&&(mode<=3))) return BAD_CIPHER_MODE;

	vector = IV;

	cipher->mode = mode;
	cipher->blockSize = 16;  /* fixed here */
	strncpy(cipher->IV,vector,BLOCKSIZE);
//	for (i=0; i<BLOCKSIZE; i++) cipher->IV[i] = vector[i];

	/*---> start: make RDC */
	for (i=0;i<8;i++) RDC[i] = 1<<i;
	RDC[8] = irrpoly;  /* = 00011011 <- x^8 + x^4 + x^3 + x + 1 */

	for (i=9;i<15;i++) {
		if (RDC[i-1]&0x80) {
			RDC[i] = (BYTE)(RDC[i-1]<<1)^irrpoly;
		}
		else {
			RDC[i] = RDC[i-1]<<1;
		}
	} /* complete: make RDC */

	/* ----> start : make basis conversion matrix, MTX */
	for (i=0; i<8; i++) pb[i] = (1<<i);
	nb[0] = 2;
	for (j=1; j<8; j++) nb[j] = field_mul(nb[j-1], nb[j-1]);
	make_MTX(pb, nb);
	/* complete: make basis conversion matrix, MTX */

	/* final step for generating the S-box Table RED */
	cipher->RED[0]= cipher->RED[256]= 0;
	for (g=255; g>0; g--) {
		t1 = field_mul(g,g); 
		t2 = field_mul(t1,t1);
		t3 = field_mul(t2,g);
		t1 = field_mul(t2,t2);
		t2 = field_mul(t1,t1);
		t1 = field_mul(t2,t2);
		t  = coef_cnv(field_mul(t1,t3),MTX); /* coefficient changing to 
											  over normal basis */
		t1 = coef_cnv(g,MTX); /* convert g in normal basis coordinates */
		cipher->RED[t1] = t;  /* store g^(37) into RED[g] in normal basis 
		                    coordinates */
		cipher->RED[256+t] = t1; /* store its inverse = g^(193) in normal 
		                    basis coord.*/
	} /* The S-box, RED, has been generated */

	return R_TRUE;
}

/* this is the field multiplication function over GF(2^8) with 
   the field defining polynomial x^8 + x^4 + x^3 + x + 1 */
static BYTE field_mul (BYTE a, BYTE b)
{
	int cf_a, cf_b;
    BYTE w=0, cf;  

	for (cf_a=0; cf_a < 8; cf_a++) {
		for (cf_b=0; cf_b < 8; cf_b++) {
			cf = ((a>>cf_a)&(b>>cf_b))&1;
			if (cf) w ^= RDC[cf_a+cf_b];
		}
	}
	return w; 
}

/* generate the base conversion matrix of basis b1 to b2 */
static void make_MTX (base b1, base b2)
{
	unsigned short cf, i, j;
	BYTE tmp[8], d;

	for (i=0; i<8; i++) {
		for (cf=0; cf<256; cf++) {
			d = 0;
			for (j=0; j<8; j++) d ^= (((cf>>j)&1)*b2[j]);
			if (d == b1[i]) {
				tmp[i] = (BYTE)cf;
				cf = 257;
			}
		}
	}

	for (i=0; i<8; i++) {
		MTX[i] = 0;
		for (j=0; j<8; j++) MTX[i] ^= (((tmp[j]>>i)&1)<<j);
	}
	return;
}

#define PROD(C, A, B, k) /* inner product routine */ \
{ \
	C = A&B;     \
	C ^= (C>>4); \
	C ^= (C>>2); \
	C ^= (C>>1); \
	C &= 1;      \
}
/* coefficient conversion of coef via basis changing mtx, MTX */
static BYTE coef_cnv (BYTE coef, base MATRIX)
{
	BYTE t=0, w=0;
	int i;

	for (i=0; i<8; i++) {
		PROD(t, MATRIX[i], coef, i);
		w |= (t<<i);
	}
	return w;
}


#define     WD(a)    ((WORD32 *)(a)) /* for utility */


static void RB_Enc_ecb (BYTE *table, BYTE *cipherKey, BYTE *input, int inputLen, 
						BYTE *outBuffer);
static void RB_Enc_cbc (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, 
						int inputLen, BYTE *outBuffer);
static void RB_Enc_cfb1 (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, 
						 int inputLen, BYTE *outBuffer);


/* platform endianness: */
#if !defined(LITTLE_ENDIAN) && !defined(BIG_ENDIAN)
#	if defined(_M_IX86) || defined(_M_I86) || defined(__alpha)
#		define LITTLE_ENDIAN
#	else
#		error "Either LITTLE_ENDIAN or BIG_ENDIAN must be defined"
#	endif
#elif defined(LITTLE_ENDIAN) && defined(BIG_ENDIAN)
#	error "LITTLE_ENDIAN and BIG_ENDIAN must not be simultaneously defined"
#endif /* !LITTLE_ENDIAN && !BIG_ENDIAN */


/* Microsoft C / Intel x86 optimizations: */
#if defined(_MSC_VER) && defined(_M_IX86) 
#	define HARDWARE_ROTATIONS
#endif  /* :(_MSC_VER && _M_IX86) */


#ifdef HARDWARE_ROTATIONS
#	define ROTL(x, s) (_lrotl ((x), (s)))
#	define ROTR(x, s) (_lrotr ((x), (s)))
#else  /* !HARDWARE_ROTATIONS */
#	define ROTL(x, s) (((x) << (s)) | ((x) >> (32 - (s))))
#	define ROTR(x, s) (((x) >> (s)) | ((x) << (32 - (s))))
#endif /* :HARDWARE_ROTATIONS */

#ifdef LITTLE_ENDIAN
#	ifdef MASKED_BYTE_EXTRACTION
#		define GETB0(x) (((x)      ) & 0xffU)
#		define GETB1(x) (((x) >>  8) & 0xffU)
#		define GETB2(x) (((x) >> 16) & 0xffU)
#		define GETB3(x) (((x) >> 24) & 0xffU)
#	else  /* !MASKED_BYTE_EXTRACTION */
#		define GETB0(x) ((BYTE)  ((x)      ))
#		define GETB1(x) ((BYTE)  ((x) >>  8))
#		define GETB2(x) ((BYTE)  ((x) >> 16))
#		define GETB3(x) ((BYTE)  ((x) >> 24))
#	endif /* :MASKED_BYTE_EXTRACTION */
#	define PUTB0(x) ((WORD32) (x)      )
#	define PUTB1(x) ((WORD32) (x) <<  8)
#	define PUTB2(x) ((WORD32) (x) << 16)
#	define PUTB3(x) ((WORD32) (x) << 24)
#else  /* !LITTLE_ENDIAN */
#	ifdef MASKED_BYTE_EXTRACTION
#		define GETB0(x) (((x) >> 24) & 0xffU)
#		define GETB1(x) (((x) >> 16) & 0xffU)
#		define GETB2(x) (((x) >>  8) & 0xffU)
#		define GETB3(x) (((x)      ) & 0xffU)
#	else  /* !MASKED_BYTE_EXTRACTION */
#		define GETB0(x) ((BYTE)  ((x) >> 24))
#		define GETB1(x) ((BYTE)  ((x) >> 16))
#		define GETB2(x) ((BYTE)  ((x) >>  8))
#		define GETB3(x) ((BYTE)  ((x)      ))
#	endif /* :MASKED_BYTE_EXTRACTION */
#	define PUTB0(x) ((WORD32) (x) << 24)
#	define PUTB1(x) ((WORD32) (x) << 16)
#	define PUTB2(x) ((WORD32) (x) <<  8)
#	define PUTB3(x) ((WORD32) (x)      )
#endif /* :LITTLE_ENDIAN */

#define COPY_BLOCK(trg, src) \
{ \
	(trg)[0] = (src)[0]; \
	(trg)[1] = (src)[1]; \
	(trg)[2] = (src)[2]; \
	(trg)[3] = (src)[3]; \
} /* COPY_BLOCK */ 


/******** from here, represented the encryption routine ********/

#define G_function(RN) \
{ /* G-layer */ \
	data[0] ^= key[(RN)][0]; \
	data[1] ^= key[(RN)][1]; \
	data[2] ^= key[(RN)][2]; \
	data[3] ^= key[(RN)][3]; \
}

#define B_function(RN) \
{ /* B-layer */ \
	tmp[0] = (data[0] & key[(RN)][0])^\
		 (data[1] & key[(RN)][1])^    \
		 (data[2] & key[(RN)][2])^    \
		 (data[3] & key[(RN)][3]);    \
	tmp[1] = (data[0] & key[(RN)][1])^\
		  (data[1] & key[(RN)][2])^   \
		  (data[2] & key[(RN)][3])^   \
		  (data[3] & key[(RN)][0]);   \
	tmp[2] = (data[0] & key[(RN)][2])^\
		  (data[1] & key[(RN)][3])^   \
		  (data[2] & key[(RN)][0])^   \
		  (data[3] & key[(RN)][1]);   \
	tmp[3] = (data[0] & key[(RN)][3])^\
		  (data[1] & key[(RN)][0])^   \
		  (data[2] & key[(RN)][1])^   \
		  (data[3] & key[(RN)][2]);   \
}

#define R_function(TABLE) \
{ /* R-layer */ \
	data[0] = PUTB1((TABLE)[GETB0(tmp[0])])|  \
		PUTB0((TABLE)[256+GETB1(tmp[0])])|    \
		PUTB3((TABLE)[GETB2(tmp[0])])|        \
		PUTB2((TABLE)[256+GETB3(tmp[0])]);    \
	data[1] = PUTB2((TABLE)[GETB0(tmp[1])])|  \
		PUTB0((TABLE)[256+GETB2(tmp[1])])|    \
		PUTB3((TABLE)[GETB1(tmp[1])])|        \
		PUTB1((TABLE)[256+GETB3(tmp[1])]);    \
	data[2] = PUTB3((TABLE)[GETB0(tmp[2])])|  \
		PUTB0((TABLE)[256+GETB3(tmp[2])])|    \
		PUTB2((TABLE)[GETB1(tmp[2])])|        \
		PUTB1((TABLE)[256+GETB2(tmp[2])]);    \
	data[3] = PUTB2((TABLE)[GETB0(tmp[3])])|  \
		PUTB0((TABLE)[256+GETB2(tmp[3])])|    \
		PUTB3((TABLE)[GETB1(tmp[3])])|        \
		PUTB1((TABLE)[256+GETB3(tmp[3])]);    \
}

#define ROUND_function(key_num) \
{ /* one round process 'F_function' in the document */ \
	G_function(key_num);   \
	B_function(key_num+1); \
	R_function(SBox);      \
}

#define ONEBLOCK_CIPH /* here : only for the blockLen=16bytes */ \
{ /* one block encryption */ \
	ROUND_function(0);  \
	ROUND_function(2);  \
	ROUND_function(4);  \
	ROUND_function(6);  \
	ROUND_function(8);  \
	ROUND_function(10); \
	ROUND_function(12); \
	G_function(14);     \
	B_function(15);     \
	COPY_BLOCK(data,tmp);\
}

int blockEncrypt (cipherInstance *cipher, keyInstance *keys, BYTE *input,
				 int inputLen, BYTE *outBuffer)
{
	if (cipher == NULL) return BAD_CIPHER_STATE;
	if (keys == NULL) return BAD_KEY_INSTANCE;
	if (inputLen%128) return BAD_CIPHER_INPUT;

	if (cipher->mode == MODE_ECB) {
		RB_Enc_ecb (cipher->RED, keys->KS_Enc, input, inputLen, outBuffer);
		return R_TRUE;
	}
	if (cipher->mode == MODE_CBC) {
		RB_Enc_cbc (cipher->RED, keys->KS_Enc,cipher->IV, input, inputLen, outBuffer);
		return R_TRUE;
	}
	if (cipher->mode == MODE_CFB1) {
		RB_Enc_cfb1 (cipher->RED, keys->KS_Enc,cipher->IV, input, inputLen, outBuffer);
		return R_TRUE;
	}
	return BAD_CIPHER_MODE;
}

/* ECB-mode encryption */
static void RB_Enc_ecb (BYTE *table, BYTE *cipherKey, BYTE *input, int inputLen, 
						BYTE *outBuffer)
{
	WORD32 tmp[4], data[4], key[2*(R+1)][4];
	WORD32 *scan, *tar;
	BYTE *SBox;
	int i, ib;

	SBox = table;
	scan = WD(cipherKey);
	for (i=0; i<2*(R+1); i++) {
		COPY_BLOCK(key[i], scan);
		scan += 4;
	}

	ib = inputLen/BITSPERBLOCK;  /* check # of cyphering blocks */
	scan = WD(input);
	tar = WD(outBuffer);

	for (i=0; i<ib; i++) {
		COPY_BLOCK(data, scan);
		ONEBLOCK_CIPH; /* encrypt */
		COPY_BLOCK(tar, data);
		scan += BLOCK_WSIZE;
		tar += BLOCK_WSIZE;
	}
}

#define BLOCK_XOR(B, A) \
{ \
	B[0] ^= A[0];\
	B[1] ^= A[1];\
	B[2] ^= A[2];\
	B[3] ^= A[3];\
}
/* CBC-mode encryption */
static void RB_Enc_cbc (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, int inputLen, 
					BYTE *outBuffer)
{
	WORD32 tmp[4], data[4], key[2*(R+1)][4];
	WORD32 *scan, *tar;
	BYTE *SBox;
	int i, ib;

	SBox = table;
	scan = WD(cipherKey);
	for (i=0; i<2*(R+1); i++) {
		COPY_BLOCK(key[i], scan);
		scan += 4;
	}

	ib = inputLen/BITSPERBLOCK;  /* check # of cyphering blocks */
	scan = WD(input);
	tar = WD(outBuffer);

	COPY_BLOCK(data, scan);
	BLOCK_XOR(data, WD(iv));  /* added initial vector */
	ONEBLOCK_CIPH; /* encrypt */
	COPY_BLOCK(tar, data);

	for (i=1; i<ib; i++) {
		scan += BLOCK_WSIZE;
		tar += BLOCK_WSIZE;
		BLOCK_XOR(data, scan);  /* cipher block chaining */
		ONEBLOCK_CIPH; /* encrypt */
		COPY_BLOCK(tar, data);
	}
}

#define LSHIFT_PAST(D, b) \
{ /* shift by 1bit of and paste 1bit to cipher input data */ \
	dt = D[0]>>31;       \
	D[0] = (D[0]<<1)|b;  \
	df = (D[1]<<1)|dt;   \
	dt = D[1]>>31;       \
	D[1] = df;           \
	df = (D[2]<<1)|dt;   \
	dt = D[2]>>31;       \
	D[2] = df;           \
	D[3] = (D[3]<<1)|dt; \
}

/* CFB1-mode encryption */
static void RB_Enc_cfb1 (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, int inputLen, 
					BYTE *outBuffer)
{
	WORD32 tmp[4], data[4], feed[4], key[2*(R+1)][4], df,dt, *cnv;
	BYTE *scan, *tar, *SBox;
	register BYTE grab, bit, fback;
	int i, j;

	SBox = table;
	cnv = WD(cipherKey);
	for (i=0; i<2*(R+1); i++) {
		COPY_BLOCK (key[i], cnv);
		cnv += 4;
	}
	scan = input;
	tar = outBuffer;

	COPY_BLOCK(feed, WD(iv));
	COPY_BLOCK(data, feed);
	ONEBLOCK_CIPH ; /* encrypt */
	bit = (BYTE)(data[3]>>31);

	for (i=0; i<inputLen/8; i++) {
		grab = 0;  /* when the BYTE 'grab' being filled, 
		          hand over to outBuffer */
		for (j=0; j<8; j++) {
			fback = ((*scan>>j)&1)^bit;  /* preparing feedback bit */
			grab |= (fback<<j);
			LSHIFT_PAST(feed, fback);  /* preparing cipher input block */
			COPY_BLOCK(data, feed);
			ONEBLOCK_CIPH ; /* decrypt */
			bit = (BYTE)(data[3]>>31);
		}
		*tar = grab;
		scan++;
		tar++;
	}
}


#define     WD(a)    ((WORD32 *)(a)) /* for utility */


static void RB_Dec_ecb (BYTE *table, BYTE *cipherKey, BYTE *input, int inputLen, 
						BYTE *outBuffer);
static void RB_Dec_cbc (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, 
						int inputLen, BYTE *outBuffer);
static void RB_Dec_cfb1 (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, 
						 int inputLen, BYTE *outBuffer);



/* platform endianness: */
#if !defined(LITTLE_ENDIAN) && !defined(BIG_ENDIAN)
#	if defined(_M_IX86) || defined(_M_I86) || defined(__alpha)
#		define LITTLE_ENDIAN
#	else
#		error "Either LITTLE_ENDIAN or BIG_ENDIAN must be defined"
#	endif
#elif defined(LITTLE_ENDIAN) && defined(BIG_ENDIAN)
#	error "LITTLE_ENDIAN and BIG_ENDIAN must not be simultaneously defined"
#endif /* !LITTLE_ENDIAN && !BIG_ENDIAN */


/* Microsoft C / Intel x86 optimizations: */
#if defined(_MSC_VER) && defined(_M_IX86) 
#	define HARDWARE_ROTATIONS
#	define ASSEMBLER_CORE
#endif  /* :(_MSC_VER && _M_IX86) */


#ifdef HARDWARE_ROTATIONS
#	define ROTL(x, s) (_lrotl ((x), (s)))
#	define ROTR(x, s) (_lrotr ((x), (s)))
#else  /* !HARDWARE_ROTATIONS */
#	define ROTL(x, s) (((x) << (s)) | ((x) >> (32 - (s))))
#	define ROTR(x, s) (((x) >> (s)) | ((x) << (32 - (s))))
#endif /* :HARDWARE_ROTATIONS */

#ifdef LITTLE_ENDIAN
#	ifdef MASKED_BYTE_EXTRACTION
#		define GETB0(x) (((x)      ) & 0xffU)
#		define GETB1(x) (((x) >>  8) & 0xffU)
#		define GETB2(x) (((x) >> 16) & 0xffU)
#		define GETB3(x) (((x) >> 24) & 0xffU)
#	else  /* !MASKED_BYTE_EXTRACTION */
#		define GETB0(x) ((BYTE)  ((x)      ))
#		define GETB1(x) ((BYTE)  ((x) >>  8))
#		define GETB2(x) ((BYTE)  ((x) >> 16))
#		define GETB3(x) ((BYTE)  ((x) >> 24))
#	endif /* :MASKED_BYTE_EXTRACTION */
#	define PUTB0(x) ((WORD32) (x)      )
#	define PUTB1(x) ((WORD32) (x) <<  8)
#	define PUTB2(x) ((WORD32) (x) << 16)
#	define PUTB3(x) ((WORD32) (x) << 24)
#else  /* !LITTLE_ENDIAN */
#	ifdef MASKED_BYTE_EXTRACTION
#		define GETB0(x) (((x) >> 24) & 0xffU)
#		define GETB1(x) (((x) >> 16) & 0xffU)
#		define GETB2(x) (((x) >>  8) & 0xffU)
#		define GETB3(x) (((x)      ) & 0xffU)
#	else  /* !MASKED_BYTE_EXTRACTION */
#		define GETB0(x) ((BYTE)  ((x) >> 24))
#		define GETB1(x) ((BYTE)  ((x) >> 16))
#		define GETB2(x) ((BYTE)  ((x) >>  8))
#		define GETB3(x) ((BYTE)  ((x)      ))
#	endif /* :MASKED_BYTE_EXTRACTION */
#	define PUTB0(x) ((WORD32) (x) << 24)
#	define PUTB1(x) ((WORD32) (x) << 16)
#	define PUTB2(x) ((WORD32) (x) <<  8)
#	define PUTB3(x) ((WORD32) (x)      )
#endif /* :LITTLE_ENDIAN */

#define COPY_BLOCK(trg, src) \
{ \
	(trg)[0] = (src)[0]; \
	(trg)[1] = (src)[1]; \
	(trg)[2] = (src)[2]; \
	(trg)[3] = (src)[3]; \
} /* COPY_BLOCK */ 


/******** from here, represented the decryption routine ********/

#define G_function(RN) \
{ /* G-layer */ \
	data[0] ^= key[(RN)][0]; \
	data[1] ^= key[(RN)][1]; \
	data[2] ^= key[(RN)][2]; \
	data[3] ^= key[(RN)][3]; \
}

#define B_function(RN) \
{ /* B-layer */ \
	tmp[0] = (data[0] & key[(RN)][0])^\
		 (data[1] & key[(RN)][1])^    \
		 (data[2] & key[(RN)][2])^    \
		 (data[3] & key[(RN)][3]);    \
	tmp[1] = (data[0] & key[(RN)][1])^\
		  (data[1] & key[(RN)][2])^   \
		  (data[2] & key[(RN)][3])^   \
		  (data[3] & key[(RN)][0]);   \
	tmp[2] = (data[0] & key[(RN)][2])^\
		  (data[1] & key[(RN)][3])^   \
		  (data[2] & key[(RN)][0])^   \
		  (data[3] & key[(RN)][1]);   \
	tmp[3] = (data[0] & key[(RN)][3])^\
		  (data[1] & key[(RN)][0])^   \
		  (data[2] & key[(RN)][1])^   \
		  (data[3] & key[(RN)][2]);   \
}

//#define R_function(TABLE) 
#define R_function(TABLE) \
{ /* R-layer */ \
	data[0] = PUTB1((TABLE)[GETB0(tmp[0])])|  \
		PUTB0((TABLE)[256+GETB1(tmp[0])])|    \
		PUTB3((TABLE)[GETB2(tmp[0])])|        \
		PUTB2((TABLE)[256+GETB3(tmp[0])]);    \
	data[1] = PUTB2((TABLE)[GETB0(tmp[1])])|  \
		PUTB0((TABLE)[256+GETB2(tmp[1])])|    \
		PUTB3((TABLE)[GETB1(tmp[1])])|        \
		PUTB1((TABLE)[256+GETB3(tmp[1])]);    \
	data[2] = PUTB3((TABLE)[GETB0(tmp[2])])|  \
		PUTB0((TABLE)[256+GETB3(tmp[2])])|    \
		PUTB2((TABLE)[GETB1(tmp[2])])|        \
		PUTB1((TABLE)[256+GETB2(tmp[2])]);    \
	data[3] = PUTB2((TABLE)[GETB0(tmp[3])])|  \
		PUTB0((TABLE)[256+GETB2(tmp[3])])|    \
		PUTB3((TABLE)[GETB1(tmp[3])])|        \
		PUTB1((TABLE)[256+GETB3(tmp[3])]);    \
}

/*
#define ROUND_function(key_num) \
{ \
	G_function((key_num));   \
	B_function((key_num+1)); \
	R_function(SBox);        \
}
*/
#define ONEBLOCK_CIPH /* here : only for the blockLen=16bytes */\
{ /* one block encryption */ \
	ROUND_function(0);  \
	ROUND_function(2);  \
	ROUND_function(4);  \
	ROUND_function(6);  \
	ROUND_function(8);  \
	ROUND_function(10); \
	ROUND_function(12); \
	G_function(14);     \
	B_function(15);     \
	COPY_BLOCK(data,tmp);\
}

int blockDecrypt (cipherInstance *cipher, keyInstance *keys, BYTE *input,
				 int inputLen, BYTE *outBuffer)
{
	if (cipher == NULL) return BAD_CIPHER_STATE;
	if (keys == NULL) return BAD_KEY_INSTANCE;
	if (inputLen%128) return BAD_CIPHER_INPUT;

	if (cipher->mode == MODE_ECB) {
		RB_Dec_ecb (cipher->RED, keys->KS_Dec, input, inputLen, outBuffer);
		return R_TRUE;
	}
	if (cipher->mode == MODE_CBC) {
		RB_Dec_cbc (cipher->RED, keys->KS_Dec, cipher->IV, input, inputLen, outBuffer);
		return R_TRUE;
	}
	if (cipher->mode == MODE_CFB1) {
		RB_Dec_cfb1 (cipher->RED, keys->KS_Enc,cipher->IV, input, inputLen, outBuffer);
		return R_TRUE;
	}
	return BAD_CIPHER_MODE;
}

/* ECB-mode encryption */
static void RB_Dec_ecb (BYTE *table, BYTE *cipherKey, BYTE *input, int inputLen, BYTE *outBuffer)
{
	WORD32 tmp[4], data[4],key[2*(R+1)][4];
	WORD32 *scan, *tar;
	BYTE *SBox;
	int i, ib;

	SBox = table;
	scan = WD(cipherKey);
	for (i=0; i<2*(R+1); i++) {
		COPY_BLOCK (key[i], scan);
		scan += 4;
	}

	ib = inputLen/BITSPERBLOCK;  /* check # of cyphering blocks */
	scan = WD(input);
	tar = WD(outBuffer);

	for (i=0; i<ib; i++) {
		COPY_BLOCK (data, scan);
		ONEBLOCK_CIPH ;
		COPY_BLOCK (tar, data);
		scan += BLOCK_WSIZE;
		tar += BLOCK_WSIZE;
	}
}

/*
#define BLOCK_XOR(B, A) \
{ \
	B[0] ^= A[0]; \
	B[1] ^= A[1]; \
	B[2] ^= A[2]; \
	B[3] ^= A[3]; \
}
*/
/* CBC-mode encryption */
static void RB_Dec_cbc (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, int inputLen, 
					BYTE *outBuffer)
{
	WORD32 tmp[4], data[4], key[2*(R+1)][4], pred[4];
	WORD32 *scan, *tar;
	BYTE *SBox;
	int i, ib;

	SBox = table;
	scan = WD(cipherKey);
	for (i=0; i<2*(R+1); i++) {
		COPY_BLOCK (key[i], scan);
		scan += 4;
	}

	ib = inputLen/BITSPERBLOCK;  /* check # of cyphering blocks */
	scan = WD(input);
	tar = WD(outBuffer);

	COPY_BLOCK(data, scan);
	COPY_BLOCK(pred, data); /* grab into 'pred' to recover 
	             the next ciphertext */
	ONEBLOCK_CIPH;  /* decrypt */
	BLOCK_XOR(data, WD(iv));  /* added initial vector to recover
	             original plaintext */
	COPY_BLOCK(tar, data);

	for (i=1; i<ib; i++) {
		scan += BLOCK_WSIZE;
		tar += BLOCK_WSIZE;
		COPY_BLOCK(data, scan);
		ONEBLOCK_CIPH;  /* decrypt */
		BLOCK_XOR(data, pred);  /* recover plaintext using predecessor */
		COPY_BLOCK(tar, data);
		COPY_BLOCK(pred, scan);
	}
}

#define LSHIFT_PAST(D, b) \
{ /* shift by 1bit of and paste 1bit to cipher input data */ \
	dt = D[0]>>31;       \
	D[0] = (D[0]<<1)|b;  \
	df = (D[1]<<1)|dt;   \
	dt = D[1]>>31;       \
	D[1] = df;           \
	df = (D[2]<<1)|dt;   \
	dt = D[2]>>31;       \
	D[2] = df;           \
	D[3] = (D[3]<<1)|dt; \
}
/* CFB1-mode encryption */
static void RB_Dec_cfb1 (BYTE *table, BYTE *cipherKey, BYTE *iv, BYTE *input, int inputLen, 
					BYTE *outBuffer)
{
	WORD32 tmp[4], data[4],feed[4], key[2*(R+1)][4], df,dt, *cnv;
	BYTE *scan, *tar, *SBox;
	register BYTE grab, bit, pred;
	int i, j;

	SBox = table;
	cnv = WD(cipherKey);
	for (i=0; i<2*(R+1); i++) {
		COPY_BLOCK (key[i], cnv);
		cnv += 4;
	}
	scan = input;
	tar = outBuffer;

	COPY_BLOCK(feed, WD(iv));
	COPY_BLOCK(data, feed);
	ONEBLOCK_CIPH;  /* decrypt */
	bit = (BYTE)(data[3]>>31);
	for (i=0; i<inputLen/8; i++) {
		grab = 0;  /* when the BYTE 'grab' being filled, 
		          hand over to outBuffer */
		for (j=0; j<8; j++) {
			pred = (*scan>>j)&1;  /* preparing feedback bit */
			grab |= ((pred^bit)<<j);
			LSHIFT_PAST(feed, pred);  /* preparing cipher input block */
			COPY_BLOCK(data, feed);
			ONEBLOCK_CIPH ;  /* decrypt */
			bit =(BYTE)(data[3]>>31);
		}
		*tar = grab;		
		scan++;
		tar++;
	}
}

#define ITERATIONS 1024

void blockPrint(char *buf, int length);
static void cipher_correct_test(void);
static void cipher_speed_test(void);


static const BYTE plainSrc[1024] = {0, };



int main (void)
{
	cipher_correct_test();
	cipher_speed_test();
	return 0;
}

void cipher_correct_test(void)
{
	keyInstance keys;
	cipherInstance ciph;
	BYTE ptext[1024], ctext[1024], keySrc[MAX_KEY_SIZE], inV[MAX_IV_SIZE];
	int i, textLen=1024*8, keySrcLen=16*8, status;


	for (i=0; i<1024; i++) {
		ptext[i] = 0;
		ctext[i] = 0;
	}
	for (i=0; i<MAX_KEY_SIZE; i++) keySrc[i] = 0;
	for (i=0; i<MAX_IV_SIZE; i++) inV[i] = 1; 

	status = makeKey(&keys, DIR_ENCRYPT, keySrcLen, (char *)keySrc);
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}
	/* ECB TEST start-- */
	status = cipherInit(&ciph, MODE_ECB, (char *)inV); 
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}
	status =blockEncrypt(&ciph, &keys, (BYTE *)ptext, textLen,(BYTE *)ctext);
	status =blockDecrypt(&ciph, &keys, (BYTE *)ctext, textLen,(BYTE *)ptext);
	if (strncmp(plainSrc,ptext,1024)==0) printf("----ECB : OK!----\n");
	else printf("----ECB : FAIL!-----\n");

	/* CBC TEST start--- */
	status = cipherInit(&ciph, MODE_CBC, (char *)inV); 
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}
	status =blockEncrypt(&ciph, &keys, (BYTE *)ptext, textLen,(BYTE *)ctext);
	status =blockDecrypt(&ciph, &keys, (BYTE *)ctext, textLen,(BYTE *)ptext);
	if (strncmp(plainSrc,ptext,1024)==0) printf("----CBC : OK!----\n");
	else printf("----CBC : FAIL!-----\n");

	/* CFB1 TEST start--- */
	status = cipherInit(&ciph, MODE_CFB1, (char *)inV); 
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}
	status =blockEncrypt(&ciph, &keys, (BYTE *)ptext, textLen,(BYTE *)ctext); 
	status =blockDecrypt(&ciph, &keys, (BYTE *)ctext, textLen,(BYTE *)ptext); 
	if (strncmp(plainSrc,ptext,1024)==0) printf("----CFB1 : OK!----\n");
	else printf("----CFB1 : FAIL!-----\n");
}

void blockPrint(char *buf, int length)
{
	int i;

	for (i=0; i<length; i++) {
		printf("%02x",buf[i]&0xff);
	}
	printf("\n");
}

static void cipher_speed_test(void)
{
	keyInstance keys;
	cipherInstance ciph;
	BYTE ptext[1024], ctext[1024], keySrc[MAX_KEY_SIZE], inV[MAX_IV_SIZE];
	int i, textLen=1024*8, keySrcLen=16*8, status;
	clock_t elapsed;
	double sec;

	for (i=0; i<1024; i++) {
		ptext[i] = 0;
		ctext[i] = 0;
	}
	for (i=0; i<MAX_KEY_SIZE; i++) keySrc[i] = 0;
	for (i=0; i<MAX_IV_SIZE; i++) inV[i] = 1; 

	status = makeKey(&keys, DIR_ENCRYPT, keySrcLen, (char *)keySrc);
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}

	status = cipherInit(&ciph, MODE_ECB, (char *)inV); 
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}
	elapsed = -clock();
	for (i=0; i<ITERATIONS; i++) {
		status =blockEncrypt(&ciph, &keys, (BYTE *)ptext, textLen,(BYTE *)ctext);
		strncpy (ctext, ptext, 1024);
	}
	elapsed += clock ();
	sec = elapsed ? (double) elapsed / CLOCKS_PER_SEC : 1.0;
	printf("****ECB_speed.... ");
	printf (" %.4f sec(1Mbytes), %.4f Mbytes/sec.\n",
		sec, 1./sec);

	status = cipherInit(&ciph, MODE_CBC, (char *)inV); 
	if (status != R_TRUE) {
		printf("Error Occured!__er_code=%d\n",status);
		exit(1);
	}
	elapsed = -clock();
	for (i=0; i<ITERATIONS; i++) {
		status =blockEncrypt(&ciph, &keys, (BYTE *)ptext, textLen,(BYTE *)ctext);
		strncpy (ctext, ptext, 1024);
	}
	elapsed += clock ();
	sec = elapsed ? (double) elapsed / CLOCKS_PER_SEC : 1.0;
	printf("****CBC_speed.... ");
	printf (" %.4f sec(1Mbytes), %.4f Mbytes/sec.\n",
		sec, 1./sec);
}

