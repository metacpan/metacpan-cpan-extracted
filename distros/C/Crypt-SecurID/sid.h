/*
 * sid.h - I.C. Wiener's SecurID emulator module, header
 *
 * $Id: sid.h,v 1.2 2003/01/22 01:14:00 pliam Exp $
 */

#ifndef SID_H
#define SID_H

/* 
 * Adaptation based code by I.C. Wiener.  Original copyright:
 */
/*
 * (c) 1999-3001 [sic] I.C. Wiener
 * Sample SecurID Token Emulator with Token Secret Import
 * Date: Dec 21 2000 3:12PM
 * I.C. Wiener <icwiener@mailru.com>
 */

typedef union _SID_OCTET {
    unsigned long long	Q[1];
    unsigned long		D[2];
    unsigned short		W[4];
    unsigned char		B[8];
}   SID_OCTET;

void securid_expand_key_to_4_bit_per_byte(
	const SID_OCTET source, char *target
);
void securid_expand_data_to_1_bit_per_byte(
	const SID_OCTET source, char *target
);
void securid_reassemble_64_bit_from_64_byte(
	const unsigned char *source, SID_OCTET *target
);
void securid_permute_data(SID_OCTET *data, const SID_OCTET key);
void securid_do_4_rounds(SID_OCTET *data, SID_OCTET *key);
void securid_convert_to_decimal(SID_OCTET *data, const SID_OCTET key);
void securid_hash_data(SID_OCTET *data, SID_OCTET key, unsigned char c2d);
void securid_hash_time(unsigned long time, SID_OCTET *hash, SID_OCTET key); 

#endif
