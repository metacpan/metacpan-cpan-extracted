#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <cashcow.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	if (strEQ(name, "CASHCOW_H"))
#ifdef CASHCOW_H
	    return CASHCOW_H;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	if (strEQ(name, "POS_ECOMMERCE_PLAIN"))
#ifdef POS_ECOMMERCE_PLAIN
	    return POS_ECOMMERCE_PLAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "POS_ECOMMERCE_SSL"))
#ifdef POS_ECOMMERCE_SSL
	    return POS_ECOMMERCE_SSL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "POS_MAILORDER"))
#ifdef POS_MAILORDER
	    return POS_MAILORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "POS_PHONEORDER"))
#ifdef POS_PHONEORDER
	    return POS_PHONEORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "POS_PRESENT_MAGNETIC"))
#ifdef POS_PRESENT_MAGNETIC
	    return POS_PRESENT_MAGNETIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "POS_PRESENT_MANUAL"))
#ifdef POS_PRESENT_MANUAL
	    return POS_PRESENT_MANUAL;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Business::Cashcow		PACKAGE = Business::Cashcow		


double
constant(name,arg)
	char *		name
	int		arg

int
InitCashcow(pass,key)
	char *		pass
	char *		key
	CODE:
		RETVAL = InitCashcow(pass,key);
	OUTPUT:
		RETVAL

char *
RequestAuth(transaction,ticket,userkey)
	HV *		transaction
	SV *		ticket
	char *		userkey
	PREINIT:
		struct Transaction t;
		SV		**sv;
		int		ref;
		STRLEN len;
	CODE:
		sv = hv_fetch(transaction, "card_number", 11, 0);
		if (sv != NULL) {
			strncpy(t.card_number, SvPV(*sv, PL_na), 21);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "card_expirymonth", 16, 0);
		if (sv != NULL) {
			t.card_expirymonth = SvIV(*sv);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "card_expiryyear", 15, 0);
		if (sv != NULL) {
			t.card_expiryyear = SvIV(*sv);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "transaction_reference", 21, 0);
		if (sv != NULL) {
			strncpy(t.transaction_reference, SvPV(*sv, PL_na), 21);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "transaction_amount", 18, 0);
		if (sv != NULL) {
			t.transaction_amount = SvNV(*sv);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "transaction_currency", 20, 0);
		if (sv != NULL) {
			t.transaction_currency = SvIV(*sv);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_name", 13, 0);
		if (sv != NULL) {
			strncpy(t.merchant_name, SvPV(*sv, PL_na), 50);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_address", 16, 0);
		if (sv != NULL) {
			strncpy(t.merchant_address, SvPV(*sv, PL_na), 50);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_city", 13, 0);
		if (sv != NULL) {
			strncpy(t.merchant_city, SvPV(*sv, PL_na), 50);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_zip", 12, 0);
		if (sv != NULL) {
			strncpy(t.merchant_zip, SvPV(*sv, PL_na), 11);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_region", 15, 0);
		if (sv != NULL) {
			strncpy(t.merchant_region, SvPV(*sv, PL_na), 4);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_country", 16, 0);
		if (sv != NULL) {
			strncpy(t.merchant_country, SvPV(*sv, PL_na), 4);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_poscode", 16, 0);
		if (sv != NULL) {
			t.merchant_poscode = SvIV(*sv);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_number", 15, 0);
		if (sv != NULL) {
			strncpy(t.merchant_number, SvPV(*sv, PL_na), 16);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "merchant_terminalid", 19, 0);
		if (sv != NULL) {
			strncpy(t.merchant_terminalid, SvPV(*sv, PL_na), 9);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "result_action", 13, 0);
		if (sv != NULL) {
			t.result_action = SvIV(*sv);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "result_approval", 15, 0);
		if (sv != NULL) {
			strncpy(t.result_approval, SvPV(*sv, PL_na), 7);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "result_ticket", 13, 0);
		if (sv != NULL) {
			strncpy(t.result_ticket, SvPV(*sv, PL_na), 258);
		}
		else {
			XSRETURN_UNDEF;
		}
		sv = hv_fetch(transaction, "cashcow", 7, 0);
		if (sv != NULL) {
			strncpy(t.cashcow, SvPV(*sv, PL_na), 8);
		}
		else {
			XSRETURN_UNDEF;
		}
		len = 1000;
		sv_setpvn(ticket, "", len);
		memset(SvPV(ticket, PL_na),0,len);
		RETVAL = getactiontext(RequestAuth(&t, SvPV(ticket, PL_na), userkey));
	OUTPUT:
		transaction
		ticket
		RETVAL

char *
RequestCapture(ticket,userkey,actual_amount)
	SV *		ticket
	char *		userkey
	SV *		actual_amount
	CODE:
		RETVAL = getactiontext(RequestCapture(SvPV(ticket, PL_na), userkey, SvNV(actual_amount)));
	OUTPUT:
		RETVAL
