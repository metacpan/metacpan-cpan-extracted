/* -*-C-*- */

/* $Id: Sybase.xs,v 1.19 2011/04/25 08:59:17 mpeppler Exp $
   Copyright (c) 1997-2011 Michael Peppler

   Uses from Driver.xst
   Copyright (c) 1994,1995,1996,1997  Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

#include "Sybase.h"

DBISTATE_DECLARE;

MODULE = DBD::Sybase    PACKAGE = DBD::Sybase

I32
constant()
    ALIAS:
    CS_ROW_RESULT           = CS_ROW_RESULT
    CS_CURSOR_RESULT        = CS_CURSOR_RESULT
    CS_PARAM_RESULT         = CS_PARAM_RESULT
    CS_STATUS_RESULT        = CS_STATUS_RESULT
    CS_MSG_RESULT           = CS_MSG_RESULT
    CS_COMPUTE_RESULT       = CS_COMPUTE_RESULT
    CODE:
    if (!ix) {
	char *what = GvNAME(CvGV(cv));
	croak("Unknown DBD::Sybase constant '%s'", what);
    }
    else RETVAL = ix;
    OUTPUT:
    RETVAL


void
timeout(value)
    int		value
    CODE:
    ST(0) = sv_2mortal(newSViv(syb_set_timeout(value)));

void
thread_enabled()
    CODE:
    ST(0) = sv_2mortal(newSViv(syb_thread_enabled()));

void
set_cslib_cb(cb)
    SV *        cb
    CODE:
    ST(0) = sv_2mortal(newSVsv(syb_set_cslib_cb(cb)));


MODULE = DBD::Sybase    PACKAGE = DBD::Sybase::db

void
_isdead(dbh)
    SV *	dbh
  ALIAS:
    syb_isdead     = 1
    CODE:
    D_imp_dbh(dbh);
    ST(0) = sv_2mortal(newSViv(imp_dbh->isDead));

void
_date_fmt(dbh, fmt)
    SV *	dbh
    char *	fmt
    ALIAS:
    syb_date_fmt     = 1
    CODE:
    D_imp_dbh(dbh);
    ST(0) = syb_db_date_fmt(dbh, imp_dbh, fmt) ? &PL_sv_yes : &PL_sv_no;

void
ping(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    ST(0) = sv_2mortal(newSViv(syb_ping(dbh, imp_dbh)));


MODULE = DBD::Sybase    PACKAGE = DBD::Sybase::st

void
cancel(sth)
    SV *	sth
  ALIAS:
    syb_cancel     = 1
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_st_cancel(sth, imp_sth) ? &PL_sv_yes : &PL_sv_no;

void
ct_get_data(sth, column, bufrv, buflen=0)
    SV *	sth
    int		column
    SV *	bufrv
    int		buflen
    ALIAS:
    syb_ct_get_data    = 1
    CODE:
    {
    D_imp_sth(sth);
    int len = syb_ct_get_data(sth, imp_sth, column, bufrv, buflen);
    ST(0) = sv_2mortal(newSViv(len));
    }

void
ct_data_info(sth, action, column, attr=&PL_sv_undef)
    SV *	sth
    char *	action
    int		column
    SV *	attr
    ALIAS:
    syb_ct_data_info   =   1
    CODE:
    {
    D_imp_sth(sth);
    int sybaction;
    if(strEQ(action, "CS_SET")) {
	sybaction = CS_SET;
    } else if (strEQ(action, "CS_GET")) {
	sybaction = CS_GET;
    }
    ST(0) = syb_ct_data_info(sth, imp_sth, sybaction, column, attr) ? &PL_sv_yes : &PL_sv_no;
    }

void
ct_send_data(sth, buffer, size)
    SV *	sth
    char *	buffer
    int		size
    ALIAS:
    syb_ct_send_data    =  1
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_ct_send_data(sth, imp_sth, buffer, size) ? &PL_sv_yes : &PL_sv_no;

void
ct_prepare_send(sth)
    SV *	sth
    ALIAS:
    syb_ct_prepare_send   = 1
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_ct_prepare_send(sth, imp_sth) ? &PL_sv_yes : &PL_sv_no;

void
ct_finish_send(sth)
    SV *	sth
    ALIAS:
    syb_ct_finish_send    = 1
    CODE:
    D_imp_sth(sth);
    ST(0) = syb_ct_finish_send(sth, imp_sth) ? &PL_sv_yes : &PL_sv_no;

void
syb_describe(sth, doAssoc = 0)
	SV *	sth
	int	doAssoc
  PPCODE:
{
    D_imp_sth(sth);
    int i, k;
    HV *hv;
    SV *sv;
    char statbuff[255];
    struct {
	int stat;
	char name[30];
    } stat[] = { { CS_CANBENULL, "CS_CANBENULL" }, 
		 { CS_HIDDEN, "CS_HIDDEN" },
		 { CS_IDENTITY, "CS_IDENTITY" },
		 { CS_KEY, "CS_KEY" },
		 { CS_VERSION_KEY, "CS_VERSION_KEY" },
		 { CS_TIMESTAMP, "CS_TIMESTAMP" },
		 { CS_UPDATABLE, "CS_UPDATABLE" },
		 { CS_UPDATECOL, "CS_UPDATECOL" },
		 { CS_RETURN, "CS_RETURN" },
		 { 0, "" }
    };

    /* lifted almost verbatim from Sybase::CTlib's CTlib.xs file... */
    for(i = 0; i < imp_sth->numCols; ++i)
    {
	hv = newHV();

	hv_store(hv, "NAME", 4, newSVpv(imp_sth->datafmt[i].name,0), 0);
	hv_store(hv, "TYPE", 4, newSViv(imp_sth->datafmt[i].datatype), 0);
	hv_store(hv, "MAXLENGTH", 9, newSViv(imp_sth->datafmt[i].maxlength), 0);
	hv_store(hv, "SYBMAXLENGTH", 12, newSViv(imp_sth->coldata[i].realLength), 0);
	hv_store(hv, "SYBTYPE", 7, newSViv(imp_sth->coldata[i].realType), 0);
	hv_store(hv, "SCALE", 5, newSViv(imp_sth->datafmt[i].scale), 0);
	hv_store(hv, "PRECISION", 9, newSViv(imp_sth->datafmt[i].precision), 0);
	statbuff[0] = 0;
	for(k = 0; stat[k].stat > 0; ++k) {
	    if(imp_sth->datafmt[i].status & stat[k].stat) {
		strcat(statbuff, stat[k].name);
		strcat(statbuff, " ");
	    }
	}
	hv_store(hv, "STATUS", 6, newSVpv(statbuff, 0), 0);
	sv = newRV_noinc((SV*)hv);

	if(doAssoc)
	    XPUSHs(sv_2mortal(newSVpv(imp_sth->datafmt[i].name, 0)));
	XPUSHs(sv_2mortal(sv));
    }
}




MODULE = DBD::Sybase	PACKAGE = DBD::Sybase

INCLUDE: Sybase.xsi
