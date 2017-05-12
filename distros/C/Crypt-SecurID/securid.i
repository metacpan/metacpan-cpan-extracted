/*
 * securid.i - SWIG interface declaration to SecurID class
 *
 * $Id: securid.i,v 1.6 2003/01/27 04:12:57 pliam Exp $
 */

/*
 * Copyright (c) 2003 John Pliam <pliam@atbash.com>
 * This is open-source software.
 * See file 'COPYING' in original distribution for complete details.
 */

// %module "Crypt::SecurID"
// %module "securid"
// %module "Crypt"
%module "Crypt::securid"
%{
#include "securid.h"
%}

class SecurID {
public:
	SecurID();
%name(SecurIDbin) SecurID(const unsigned char *k);
%name(SecurIDhex) SecurID(const char *hk);
	int setKey(const char *hk);
	const char *key();
	long drift();
	const char *code(long tm);
%name(codeNow)	const char *code();
	int validate(const char *code, long days_toler = 30);
	int importToken(const char *f, const char *sernum); 
	int exportToken(const char *f, const char *sernum); 

	const char *error();
};

/* 
 * version string modified by cvs in .i file
 */ 

%insert("pm") %{
# version string
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", (q$Name: SecurID_Release_0_04 $ =~ /\d+/g));
# some minimal docs
=head1 NAME

Crypt::securid - this is a low-level module which you shouldn't use

=cut
%}
