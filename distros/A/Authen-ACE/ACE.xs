/* $Id: ACE.xs,v 1.2 1997/09/18 22:14:45 carrigad Exp $ */

/* Copyright (C), 1997, Interprovincial Pipe Line Inc. */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "sdi.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
	case 'A':
		if (strEQ(name, "ACM_OK")) return ACM_OK;
		if (strEQ(name, "ACM_ACCESS_DENIED")) return ACM_ACCESS_DENIED;
		if (strEQ(name, "ACM_NEXT_CODE_REQUIRED")) return ACM_NEXT_CODE_REQUIRED;
		if (strEQ(name, "ACM_NEW_PIN_REQUIRED")) return ACM_NEW_PIN_REQUIRED;
		if (strEQ(name, "ACM_NEW_PIN_ACCEPTED")) return ACM_NEW_PIN_ACCEPTED;
		if (strEQ(name, "ACM_NEW_PIN_REJECTED")) return ACM_NEW_PIN_REJECTED;
		break;
	case 'C':
		if (strEQ(name, "CANNOT_CHOOSE_PIN")) return CANNOT_CHOOSE_PIN;
		break;
	case 'M':
		if (strEQ(name, "MUST_CHOOSE_PIN")) return MUST_CHOOSE_PIN;
		break;
	case 'U':
		if (strEQ(name, "USER_SELECTABLE")) return USER_SELECTABLE;
		break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

union config_record configure;

MODULE = Authen::ACE		PACKAGE = Authen::ACE

PROTOTYPES: ENABLE

double
constant(name,arg)
	char *		name
	int		arg


int
creadcfg()

SDClient *
sd_init()
	CODE:
	SDClient *sd = (SDClient *)malloc(sizeof(SDClient));
	memset(sd, 0, sizeof(SDClient));
	if (sd) RETVAL = (sd_init(sd) == 0)? sd : NULL;

	OUTPUT:
	RETVAL

void
sd_auth(sd, username="")
	SDClient *	sd
	char *		username

	PPCODE:
	{
		int result;
		if (strlen(username)) strncpy(sd->username, username, LENACMNAME);
		EXTEND(sp, 1);
		result = sd_auth(sd);
		PUSHs(sv_2mortal(newSViv(result)));
		if (result == ACM_OK) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVpv(sd->shell, strlen(sd->shell))));
		}
	}

void
sd_check(password="", username, sd)
	char *		password
	char *		username
	SDClient *	sd

	PPCODE:
	{
		int result;
		result = sd_check(password, username, sd);

		EXTEND(sp, 1);
		PUSHs(sv_2mortal(newSViv(result)));

		switch (result) {
		case ACM_OK:
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVpv(sd->shell, strlen(sd->shell))));
			break;
		case ACM_ACCESS_DENIED:
			break;
		case ACM_NEXT_CODE_REQUIRED:
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSViv(sd->timeout)));
			break;
		case ACM_NEW_PIN_REQUIRED:
			EXTEND(sp, 5);
			PUSHs(sv_2mortal(newSVpv(sd->system_pin, strlen(sd->system_pin))));
			PUSHs(sv_2mortal(newSViv(sd->min_pin_len)));
			PUSHs(sv_2mortal(newSViv(sd->max_pin_len)));
			PUSHs(sv_2mortal(newSViv(sd->user_selectable)));
			PUSHs(sv_2mortal(newSViv(sd->alphanumeric)));
			break;
		}
	}

void 
sd_next(next, sd)
	char *		next
	SDClient *	sd

	PPCODE:
	{
		int result;
		EXTEND(sp, 1);
		result = sd_next(next, sd);
		PUSHs(sv_2mortal(newSViv(result)));
		if (result == ACM_OK) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVpv(sd->shell, strlen(sd->shell))));
		}
	}


int
sd_pin(pin, canceled, sd)
	char *		pin
	char		canceled
	SDClient *	sd

int
sd_close()
