/*
 * securid.h - SecurID class declaration
 *
 * $Id: securid.h,v 1.5 2003/01/25 00:01:57 pliam Exp $
 */

/*
 * common code for: LEP-Gen, SecurID.pm
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

#ifndef SECURID_H
#define SECURID_H

#include <stdio.h>

extern "C" {
#include "sid.h"
}

class SecurID {
public:
	SecurID();
	SecurID(const unsigned char *k);
	SecurID(const char *hk);
	int setKey(const char *hk);
	const char *key();
	long drift();
	const char *code(long tm);
	const char *code();
	int validate(const char *code, long days_toler = 30);
	int importToken(const char *f, const char *sernum); 
	int exportToken(const char *f, const char *sernum); 

	const char *error();

private:
	SID_OCTET keyoct; // private key as internal octet structure
	char hexkey[17];  // private key as hex string
	char textcode[9]; // assumes 8-digit code (not currently implemented)
	long drft;		  // drift in minutes, computed when code() is called
	char errmsg[128]; // last error message 

	// private methods
	int read_line(FILE *fi, SID_OCTET *data);
};

#endif // SECURID_H
