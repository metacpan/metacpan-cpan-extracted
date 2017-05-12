/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <phk@login.dknet.dk> wrote this file.  As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.   Poul-Henning Kamp
 * ----------------------------------------------------------------------------
 *
 * $FreeBSD: src/lib/libcrypt/crypt-md5.c,v 1.5.2.1 2001/05/24 12:20:02 markm Exp $
 * $DragonFly: src/lib/libcrypt/crypt-md5.c,v 1.3 2005/08/04 17:27:09 drhodus Exp $
 */

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include "md5.h"
#include "crypt_to64.h"

/*
 * UNIX password
 */

#define MD5_SIZE 16

char *
_cpx_crypt_md5(const char *pw, const char *salt, const char* magic)
{
	static char     passwd[120], *p;
	static const char *sp,*ep;
	unsigned char	final[MD5_SIZE];
	int sl,pl,i;
	md5_state_t ctx,ctx1;
	unsigned long l;

	/* Refine the Salt first */
	sp = salt;

	/* If it starts with the magic string, then skip that */
	if(!strncmp(sp,magic,strlen(magic)))
		sp += strlen(magic);

	/* It stops at the first '$', max 8 chars */
	for(ep=sp;*ep && *ep != '$' && ep < (sp+8);ep++)
		continue;

	/* get the length of the true salt */
	sl = ep - sp;

	md5_init(&ctx);

	/* The password first, since that is what is most unknown */
	md5_append(&ctx,pw,strlen(pw));

	/* Then our magic string */
	md5_append(&ctx,magic,strlen(magic));

	/* Then the raw salt */
	md5_append(&ctx,sp,sl);

	/* Then just as many characters of the MD5(pw,salt,pw) */
	md5_init(&ctx1);
	md5_append(&ctx1,pw,strlen(pw));
	md5_append(&ctx1,sp,sl);
	md5_append(&ctx1,pw,strlen(pw));
	md5_finish(&ctx1, final);
	for(pl = strlen(pw); pl > 0; pl -= MD5_SIZE)
		md5_append(&ctx,final,pl>MD5_SIZE ? MD5_SIZE : pl);

	/* Don't leave anything around in vm they could use. */
	memset(final,0,sizeof final);

	/* Then something really weird... */
	for (i = strlen(pw); i ; i >>= 1)
		if(i&1)
		    md5_append(&ctx, final, 1);
		else
		    md5_append(&ctx, pw, 1);

	/* Now make the output string */
	strcpy(passwd,magic);
	strncat(passwd,sp,sl);
	strcat(passwd,"$");

	md5_finish(&ctx,final);

	/*
	 * and now, just to make sure things don't run too fast
	 * On a 60 Mhz Pentium this takes 34 msec, so you would
	 * need 30 seconds to build a 1000 entry dictionary...
	 */
	for(i=0;i<1000;i++) {
		md5_init(&ctx1);
		if(i & 1)
			md5_append(&ctx1,pw,strlen(pw));
		else
			md5_append(&ctx1,final,MD5_SIZE);

		if(i % 3)
			md5_append(&ctx1,sp,sl);

		if(i % 7)
			md5_append(&ctx1,pw,strlen(pw));

		if(i & 1)
			md5_append(&ctx1,final,MD5_SIZE);
		else
			md5_append(&ctx1,pw,strlen(pw));
		md5_finish(&ctx1,final);
	}

	p = passwd + strlen(passwd);

	l = (final[ 0]<<16) | (final[ 6]<<8) | final[12];
	_crypt_to64(p,l,4); p += 4;
	l = (final[ 1]<<16) | (final[ 7]<<8) | final[13];
	_crypt_to64(p,l,4); p += 4;
	l = (final[ 2]<<16) | (final[ 8]<<8) | final[14];
	_crypt_to64(p,l,4); p += 4;
	l = (final[ 3]<<16) | (final[ 9]<<8) | final[15];
	_crypt_to64(p,l,4); p += 4;
	l = (final[ 4]<<16) | (final[10]<<8) | final[ 5];
	_crypt_to64(p,l,4); p += 4;
	l =                    final[11]                ;
	_crypt_to64(p,l,2); p += 2;
	*p = '\0';

	/* Don't leave anything around in vm they could use. */
	memset(final,0,sizeof final);

	return passwd;
}

/* For APR1 and MD5 crypt, the sole difference is the prefix string. */

static const char* md5_magic = "$1$";
static const char* apr1_magic= "$apr1$";

char *
cpx_crypt_apr1(const char *pw, const char *salt)
{
    return _cpx_crypt_md5(pw, salt, apr1_magic);
}

char *
cpx_crypt_md5(const char *pw, const char *salt)
{
    return _cpx_crypt_md5(pw, salt, md5_magic);
}

