/*
 * securid.cpp - SecurID class implementation
 *
 * $Id: securid.cpp,v 1.8 2003/01/27 03:00:48 pliam Exp $
 */

/*
 * Common code for: LEP-Gen, SecurID.pm
 * Copyright (c) 2003 John Pliam <pliam@atbash.com>
 * This is open-source software.
 * See file 'COPYING' in original distribution for complete details.
 */

/*
 * C++ wrapper around I.C. Wiener's code.  Original copyright:
 */
/*
 * (c) 1999-3001 [sic] I.C. Wiener
 * Sample SecurID Token Emulator with Token Secret Import
 * Date: Dec 21 2000 3:12PM
 * I.C. Wiener <icwiener@mailru.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "securid.h"

// some arithmetic defines from sid.c
#define sid_lrotr(x, n) ((((unsigned long)(x)) >> ((int) ((n) & 31))) | (((unsigned long)(x)) << ((int) ((-(n)) & 31))))
#define sid_lrotl(x, n) ((((unsigned long)(x)) << ((int) ((n) & 31))) | (((unsigned long)(x)) >> ((int) ((-(n)) & 31))))
#define sid_ror32(x, n) sid_lrotr(x, n)
#define sid_rol32(x, n) sid_lrotl(x, n)
#define sid_bswap32(x) (sid_rol32((unsigned long)(x), 8) & 0x00ff00ff | sid_ror32 ((unsigned long)(x), 8) & 0xff00ff00)

// constructors
SecurID::SecurID() : drft(0) { 
	if (setKey(NULL)) errmsg[0] = '\0';
}
SecurID::SecurID(const unsigned char *k) : drft(0) {
	int i;
	for (i = 0; i < 8; i++) {
		keyoct.B[i] = k[i];
		sprintf(&hexkey[2*i], "%02x", k[i]);
	}
	errmsg[0] = '\0';
}
SecurID::SecurID(const char *hk) : drft(0) { 
	if (setKey(hk)) errmsg[0] = '\0';
}

int SecurID::setKey(const char *hk) {
	int i;
	char hexbyte[3], *s;

	if (hk != NULL) {
		if (strlen(hk) != 16) {
			sprintf(errmsg, "ASCII key must be 64-bits (16 chars).");
			return 0;
		}
		hexbyte[2] = '\0'; // null-terminate
		for (i = 0; i < 8; i++) {
			strncpy(hexbyte, &hk[2*i], 2);
			keyoct.B[i] = strtoul(hexbyte, &s, 16);
			if (*s) {
				sprintf(errmsg, "ASCII key must be sequence of hex bytes.");
				return 0;
			}
		}
	}
	else 
		memset(&keyoct.Q[0], 0, 8);

	// set hex key (slightly safer than strcpy)
	for (i = 0; i < 8; i++)
		sprintf(&hexkey[2*i], "%02x", keyoct.B[i]);

	return 1;
}

// dump private data
const char *SecurID::key() { return hexkey; }
long SecurID::drift() { return drft; }

// compute display code
const char *SecurID::code(long tm) {
	long i, t;
	SID_OCTET h, outoct;

	t = (tm/60 - 0x806880) * 2;
	i = (t & -4);
	securid_hash_time(i, &h, keyoct);
	outoct.B[0] = h.B[2];
	outoct.B[1] = h.B[1];
	outoct.B[2] = h.B[0];
	outoct.B[3] = 0;
	sprintf(textcode, "%06lx", outoct.D[0]);

	return textcode;
}

// compute display code, based on current system time
const char *SecurID::code() { return code(time(NULL)); }

// validate a displayed code
int SecurID::validate(const char *code, long days_toler) {
	long i, j, k, t, tol;
	SID_OCTET hi, hj, codeoct;

	// although it's base-16, it's still just a decimal number as well
	codeoct.D[0] = strtoul(code, NULL, 16);

	// (t & -4) for 60 sec periods, (t & -8) for 120 sec periods, etc.
	t = (time(NULL)/60 - 0x806880) * 2;

	// changed this to agree with data
	// tol = (days_toler*24*30) & -4; // 1 int tick = 120 sec 
	tol = (days_toler*24*60*2) & -4; // 1 int tick = 120 sec 

	for (i = (t&-4), j = (t&-4) - 4; i < (t&-4) + tol; i += 4, j -= 4) {
		securid_hash_time(i, &hi, keyoct);
		securid_hash_time(j, &hj, keyoct);
		if ((hi.B[0] == codeoct.B[2]) 
				&& (hi.B[1] == codeoct.B[1]) 
				&& (hi.B[2] == codeoct.B[0])
		) {
			j = i; k = (i - (t & -4)) / 2;  break;
		} 
		else if ((hi.B[3] == codeoct.B[2]) 
				&& (hi.B[4] == codeoct.B[1]) 
				&& (hi.B[5] == codeoct.B[0])
		) {
			j = i; k = (i - (t & -4)) / 2 + 1; break;
		} 
		else if ((hj.B[0] == codeoct.B[2]) 
				&& (hj.B[1] == codeoct.B[1]) 
				&& (hj.B[2] == codeoct.B[0])
		) {
			i = j; k = (j - (t & -4)) / 2;  break;
		} 
		else if ((hj.B[3] == codeoct.B[2]) 
				&& (hj.B[4] == codeoct.B[1]) 
				&& (hj.B[5] == codeoct.B[0])
		) {
			i = j; k = (j - (t & -4)) / 2 + 1; break;
		}
	}

	if (i != j) return 0; // off by more than tolerance

	drft = k;
	return 1;
}

/*
 * methods to process pseudo-encrypted tokens
 */ 

// import key from a secret token file
int SecurID::importToken(const char *f, const char *sernum) {
	long curser, serial;
	SID_OCTET data[5];
	FILE *fi;
	char *s;
	int i, r;

	// open file
	fi = fopen(f, "rt");
	if (fi == NULL) {
		sprintf(errmsg, "Cannot open file '%s' for reading.", f);
		return 0;
	}

	// process serial number
	serial = strtoul(sernum, &s, 16); // base-16 decimal number
	if (*s) {
		sprintf(errmsg, "%s: %s.",
			"Bad serial number",
			"must be sequence of decimal digits"
		);
		return 0;
	}
	serial = sid_bswap32(serial);

	// scan file for the given serial number
	for (;;) {
		if ((r = read_line(fi, data)) < 0) break; // eof
		if (!r) return 0; // reading error
		curser = data->D[1]; 
		if ((r = read_line(fi, data)) < 0) { // eof
			sprintf(errmsg, "No matching key line for serial number");
			return 0;
		}
		if (!r) return 0; // reading error
		if (curser == serial) {
			keyoct.Q[0] = data->Q[0];
			break;
		}
	}
	fclose(fi);

	if (curser != serial) {
		sprintf(errmsg, "Token not found corresponding to serial number.");
		return 0;
	}

	// if all is good, form the hexkey and return
	for (i = 0; i < 8; i++)
		sprintf(&hexkey[2*i], "%02x", keyoct.B[i]);
	return 1;
}

// export key to a secret token file
int SecurID::exportToken(const char *f, const char *sernum) {
	struct stat statbuf;
	FILE *fo;
	long i, serial;
	SID_OCTET data[5];
	char outs[80], *s;
	unsigned int l;

	// stat and bail if file exists
	if (!stat(f, &statbuf)) {
		sprintf(errmsg, "Cannot export to existing file: '%s'.", f);
		return 0;
	}

	// open file, creating if necessary
	fo = fopen(f, "w+");
	if (fo == NULL) {
		sprintf(errmsg, "Cannot create token secret file: '%s'.", f);
		return 0;
	}

	// process serial number
	serial = strtoul(sernum, &s, 16); // base-16 decimal number
	if (*s) {
		sprintf(errmsg, "%s: %s.",
			"Bad serial number",
			"must be sequence of decimal digits"
		);
		return 0;
	}
	serial = sid_bswap32(serial);
	memset(data, 0, sizeof(data));
	data->D[1] = serial;

	// write serial number line
	for (i = 0; i < 9; i++) // pseudo-encrypt
		data->D[i] = sid_ror32(data->D[i] ^ 0x88BF88BF, 16);
	for (i = 0; i < 38; i++) // encode as hex
		sprintf(&outs[2*i], "%02x", data->B[i]);
	l = fprintf(fo, "%s\n", outs); // write line of output
	if (l != strlen(outs) + 1) {
		sprintf(errmsg, "Unknown problem printing to file.");
		return 0;
	}

	// process key 
	memset(data, 0, sizeof(data));
	for (i = 0; i < 2; i++)
		data->D[i] = keyoct.D[i];

	// write key line
	for (i = 0; i < 9; i++) // pseudo-encrypt
		data->D[i] = sid_ror32(data->D[i] ^ 0x88BF88BF, 16);
	for (i = 0; i < 38; i++) // encode as hex
		sprintf(&outs[2*i], "%02x", data->B[i]);
	l = fprintf(fo, "%s\n", outs); // write line of output
	if (l != strlen(outs) + 1) {
		sprintf(errmsg, "Unknown problem printing.");
		return 0;
	}
	fclose(fo);

	return 1;
}

// return human readable string error message
const char *SecurID::error() { return errmsg; }

/*
 * private members functions (utilities)
 */

// read a line of the secret token file
int SecurID::read_line(FILE *fi, SID_OCTET *data) {
	unsigned long i;
	char ins[80], hex[3], *p, *s;

	// read line from file
	if (!fgets(ins, sizeof(ins), fi))
		return -1; // EOF

	// process it
	p = ins;
	if (*p == '#') p++;
	if (strncmp(ins, "0000:", 5) == 0) {
		sprintf(errmsg, "Leading '%s' not permitted, (but why?).", "0000:");
		return 0;
	}
	hex[2] = '\0'; 
	for (i = 0; i < 38; i++) {
		strncpy(hex, p, 2);
		data->B[i] = strtoul(hex, &s, 16);
		if (*s) {
			sprintf(errmsg,
				"Secret token input line contains non-hex: 0x%x.", *p
			);
			return 0;
		}
		p += 2;
	}

	// pseudo-decrypt it
	for (i = 0; i < 9; i++) 
		data->D[i] = sid_rol32(data->D[i], 16) ^ 0x88BF88BF;

	return 1;
}
