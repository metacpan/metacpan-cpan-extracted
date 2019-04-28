#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <u2f.h>

#include "const-c.inc"

MODULE = Crypt::U2F::Server		PACKAGE = Crypt::U2F::Server		

INCLUDE: const-xs.inc

char *
u2fclib_calcAuthenticationChallenge(ctx)
	void *	ctx

char *
u2fclib_calcRegistrationChallenge(ctx)
	void *	ctx

int
u2fclib_deInit()

int
u2fclib_free_context(ctx)
	void *	ctx

char *
u2fclib_getError()

void *
u2fclib_get_context()

int
u2fclib_init(debug)
	int	debug

int
u2fclib_setAppID(ctx, appid)
	void *	ctx
	char *	appid

int
u2fclib_setChallenge(ctx, challenge)
	void *	ctx
	char *	challenge

int
u2fclib_setKeyHandle(ctx, buf)
	void *	ctx
	char *	buf

int
u2fclib_setOrigin(ctx, origin)
	void *	ctx
	char *	origin

int
u2fclib_setPublicKey(ctx, buf)
	void *	ctx
	char *	buf

int
u2fclib_verifyAuthentication(ctx, buf)
	void *	ctx
	char *	buf

void
u2fclib_verifyRegistration(ctx, buf)
		void *	ctx
		char *	buf
	INIT:
		char* pk[65];
		char kh[1000];
		char* result;
	PPCODE:
		result = u2fclib_verifyRegistration(ctx, buf, pk);
		if(!result) {
			XSRETURN_UNDEF;
		}
		else {
			strncpy(kh,result,1000);
			XPUSHs(sv_2mortal(newSVpvn(pk,65)));
			XPUSHs(sv_2mortal(newSVpvn(kh,strlen(kh))));
		}
