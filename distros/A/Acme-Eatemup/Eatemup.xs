#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

XS(XS_Acme__Eatemup_eatemup)
{
	(void)POPMARK;
	PL_stack_sp--;
	return;
}

MODULE = Acme::Eatemup	PACKAGE = Acme::Eatemup

BOOT:
    (void)newXSproto("Acme::Eatemup::eatemup",
			       XS_Acme__Eatemup_eatemup, "Eatemup.c", "");
