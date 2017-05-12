/*
 * sid.c - I.C. Wiener's SecurID emulator module, implementation
 *
 * $Id: sid.c,v 1.4 2003/01/22 01:14:00 pliam Exp $
 */

#include "sid.h"

/* 
 * Adaptation based code by I.C. Wiener.  Original copyright:
 */
/*
 * (c) 1999-3001 [sic] I.C. Wiener
 * Sample SecurID Token Emulator with Token Secret Import
 * Date: Dec 21 2000 3:12PM
 * I.C. Wiener <icwiener@mailru.com>
 */

#define __int64 long long
#define __forceinline __inline__
#define _lrotr(x, n) ((((unsigned long)(x)) >> ((int) ((n) & 31))) | (((unsigned long)(x)) << ((int) ((-(n)) & 31))))
#define _lrotl(x, n) ((((unsigned long)(x)) << ((int) ((n) & 31))) | (((unsigned long)(x)) >> ((int) ((-(n)) & 31))))

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define ror32(x, n) _lrotr(x, n)
#define rol32(x, n) _lrotl(x, n)
#define bswap32(x) (rol32((unsigned long)(x), 8) & 0x00ff00ff | ror32 ((unsigned long)(x), 8) & 0xff00ff00)

static __forceinline unsigned char ror8 (const unsigned char x, const int n) { 
	return (x >> (n & 7)) | (x << ((-n) & 7)); 
}
static __forceinline unsigned __int64 rol64 (
	const unsigned __int64 x, const int n
) { 
	return (x << (n & 63)) | (x >> ((-n) & 63)); 
}

static __forceinline unsigned __int64 bswap64 (const unsigned __int64 x) { 
	unsigned long a = (unsigned long) x, b = (unsigned long) (x >> 32); return (((unsigned __int64) bswap32 (a)) << 32) | bswap32(b); 
}

void securid_expand_key_to_4_bit_per_byte (const SID_OCTET source, char *target) {
    int i;

    for (i = 0; i < 8; i++) {
        target[i*2  ] = source.B[i] >> 4;
        target[i*2+1] = source.B[i] & 0x0F;
    }
}

void securid_expand_data_to_1_bit_per_byte (const SID_OCTET source, char *target) {
    int     i, j, k;

    for (i = 0, k = 0; i < 8; i++) for (j = 7; j >= 0; j--) 
			target[k++] = (source.B[i] >> j) & 1;
}

void securid_reassemble_64_bit_from_64_byte (
	const unsigned char *source, SID_OCTET *target
) {
    int     i = 0, j, k = 0;

    for (target->Q[0] = 0; i < 8; i++) for (j = 7; j >= 0; j--) 
			target->B[i] |= source[k++] << j;
}

void securid_permute_data (SID_OCTET *data, const SID_OCTET key) {
    unsigned char bit_data[128];
    unsigned char hex_key[16];

    unsigned long i, k, b, m, bit;
    unsigned char j;
    unsigned char *hkw, *permuted_bit;

    memset(bit_data, 0, sizeof(bit_data));

    securid_expand_data_to_1_bit_per_byte (*data, bit_data);
    securid_expand_key_to_4_bit_per_byte (key, hex_key);

    for (bit = 32, hkw = hex_key, m = 0; bit <= 32; hkw += 8, bit -= 32) {
        permuted_bit = bit_data + 64 + bit;
        for (k = 0, b = 28; k < 8; k++, b -= 4) {
            for (j = hkw[k]; j; j--) {
                bit_data[(bit + b + m + 4) & 0x3F] = bit_data[m];
                m = (m + 1) & 0x3F;
            }

            for (i = 0; i < 4; i++) {
                permuted_bit[b + i] |= bit_data[(bit + b + m + i) & 0x3F];
            }
        }
    }

    securid_reassemble_64_bit_from_64_byte (bit_data + 64, data);
}

void securid_do_4_rounds (SID_OCTET *data, SID_OCTET *key) {
    unsigned char       round, i, j;
    unsigned char       t;

    for (round = 0; round < 4; round++) {
        for (i = 0; i < 8; i++) {
            for (j = 0; j < 8; j++) {
                if ((((key->B[i] >> (j ^ 7)) ^ (data->B[0] >> 7)) & 1) != 0) {
                    t = data->B[4];
                    data->B[4] = 100 - data->B[0];
                    data->B[0] = t;
                }
                else {
                    data->B[0] = (unsigned char)
   (ror8((unsigned char) (ror8(data->B[0],1) - 1),1) - 1) ^ data->B[4];
                }
                data->Q[0] = bswap64 (rol64 (bswap64 (data->Q[0]), 1));
            }
        }
        key->Q[0] ^= data->Q[0];
    }
}

void securid_convert_to_decimal (SID_OCTET *data, const SID_OCTET key) {
    unsigned long       i;
    unsigned char       c, hi, lo;

    c = (key.B[7] & 0x0F) % 5;

    for (i = 0; i < 8; i++)
    {
        hi = data->B[i] >>   4;
        lo = data->B[i] & 0x0F;
        c = (c + (key.B[i] >>   4)) % 5; 
		if (hi > 9) data->B[i] = ((hi = (hi - (c + 1) * 2) % 10) << 4) | lo;
        c = (c + (key.B[i] & 0x0F)) % 5; 
		if (lo > 9) data->B[i] = (lo = ((lo - (c + 1) * 2) % 10)) | (hi << 4);
    }
}

void securid_hash_data (
	SID_OCTET *data, 
	SID_OCTET key, 
	unsigned char convert_to_decimal
) {
	// data bits are permuted depending on th e key
    securid_permute_data(data, key); 
	// key changes as well
    securid_do_4_rounds(data, &key); 
	// final permutation is based on the new key
    securid_permute_data(data, key); 
    if (convert_to_decimal)
		// decimal conversion depends o n the key too
        securid_convert_to_decimal (data, key); 
}

void securid_hash_time (unsigned long time, SID_OCTET *hash, SID_OCTET key) {
    hash->B[0] = (unsigned char) (time >> 16);
    hash->B[1] = (unsigned char) (time >> 8);
    hash->B[2] = (unsigned char) time;
    hash->B[3] = (unsigned char) time;
    hash->B[4] = (unsigned char) (time >> 16);
    hash->B[5] = (unsigned char) (time >> 8);
    hash->B[6] = (unsigned char) time;
    hash->B[7] = (unsigned char) time;

    securid_hash_data(hash, key, 1);
}
