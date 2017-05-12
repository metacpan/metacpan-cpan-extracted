#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
   From: Kenneth Albanowski <kjahds@kjahds.com>
   Date: Mon, 9 Oct 1995 18:30:55 -0400 (EDT)
*/

MODULE = CookBookA::Ex_SDV		PACKAGE = CookBookA::Ex_SDV

void
SetDualVar(variable,string,number)
	SV *	variable
	SV *	string
	SV *	number
    CODE:
	{
	 SvPV(string,na);
	 if(!SvPOKp(string) || 
	    (!SvNOKp(number) && 
	    !SvIOKp(number)) ) {
	 	croak("Usage: SetDualVar variable,string,number");
	 }
	 	
	 sv_setsv(variable,string);
	 if(SvNOKp(number)) {
	 	sv_setnv(variable,SvNV(number));
	 } else {
	 	sv_setiv(variable,SvIV(number));
	 }
	 SvPOK_on(variable);
	}
