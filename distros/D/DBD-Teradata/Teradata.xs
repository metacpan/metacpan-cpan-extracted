#ifdef __cplusplus
extern "C" {
#endif

#include "coptypes.h"
#include "dbcarea.h"
#include "coperr.h"
#include "parcel.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

I32 CliUsrLgnOn=0;
I32 CliPPsOn=0;

#define TDAT_HDR_SZ (52)
typedef unsigned char byte;
typedef unsigned short ushort;
typedef struct {
    ushort StatementNo;
    ushort Info;
    ushort Code;
    ushort Length;
    char Msg[255];
} error_fail_t;

typedef struct {
	I32 debug;
	DBCAREA dbc;
} dbc_ctx_t, *dbc_ctxptr_t;

STATIC char dummy_hdr[TDAT_HDR_SZ];

STATIC I32
tdcli_write_dbs_error(char *parcel, char *errstr)
{
	error_fail_t *Error_Fail = ((error_fail_t *) (parcel));

	memcpy(errstr, Error_Fail->Msg, Error_Fail->Length);
	errstr[Error_Fail->Length] = 0;

	return Error_Fail->Code;
}

MODULE = DBD::Teradata		PACKAGE = DBD::Teradata::Cli

void
tdxs_set_debug(dbc, val)
	SV * dbc
	SV * val
	PPCODE:
		dbc_ctxptr_t dbcp = INT2PTR(dbc_ctxptr_t, SvUV(dbc));
		dbcp->debug = SvTRUE(val) ? SvIV(val) : 0;
		ST(0) = &PL_sv_yes;
		XSRETURN(1);


void
tdxs_init_dbcarea(debug)
	SV * debug
	PPCODE:
		dbc_ctxptr_t dbc_ctx = NULL;
		DBCAREA *dbcp = NULL;
		SV *dbcarea = NULL;
		I32 result;
		char *cnta = NULL;
		Newz(0, dbc_ctx, 1, dbc_ctx_t);
		dbcp = &dbc_ctx->dbc;
	 	dbc_ctx->debug = SvTRUE(debug) ? SvIV(debug) : 0;
	 	ST(0) = sv_2mortal(newSVuv(PTR2UV(dbc_ctx)));
	 	dbcp->total_len = sizeof (DBCAREA);
		DBCHINI (&result, cnta, dbcp);
		if (result != EM_OK) {
			Perl_croak_nocontext("Cannot init, result is %d\n", result);
			Safefree(dbc_ctx);
			ST(0) = &PL_sv_undef;
		}
		XSRETURN(1);


void
tdxs_get_connection(dbcarea, logonstr, mode, runstring, logonsrc, charset)
	SV * dbcarea
	SV * logonstr
	SV * mode
	SV * runstring
	SV * logonsrc
	SV * charset
	PPCODE:
		I32 result;
		STRLEN logonlen;
		STRLEN runlen;
		STRLEN logonsrclen;
		char *mymode;
		char *cnta = NULL;
		dbc_ctxptr_t dbc_ctx = INT2PTR(dbc_ctxptr_t, SvUV(dbcarea));
		DBCAREA *dbcp = &dbc_ctx->dbc;
		byte charsetcode = (byte)(SvIV(charset));
		char relstr[7];
		char verstr[15];
		char errstr[256];
		I32 sessno = 0;
		I32 hostid = 0;
		I32 mylsn = 0;

		if (dbc_ctx->debug > 2)
			printf("Connect: dbcp is %p\n", dbcp);
		dbcp->change_opts = 'Y';
		dbcp->resp_mode = 'I';
		dbcp->use_presence_bits = 'N';
		dbcp->keep_resp = 'N';
		dbcp->wait_across_crash = 'N';
		dbcp->tell_about_crash = 'Y';
		dbcp->loc_mode = 'Y';
		dbcp->var_len_req = 'N';
		dbcp->var_len_fetch = 'N';
		dbcp->save_resp_buf = 'N';
		dbcp->two_resp_bufs = 'Y';
		dbcp->ret_time = 'N';
		dbcp->parcel_mode = 'Y';
		dbcp->wait_for_resp = 'Y';
		dbcp->req_proc_opt = 'E';
		dbcp->var_len_req = 'N';
		dbcp->maximum_parcel = 'H';
		dbcp->inter_ptr = &charsetcode;
		dbcp->charset_type = 'C';
		dbcp->connect_type = 'C';

		mymode = SvPV_nolen(mode);
		dbcp->tx_semantics = (! strcmp(mymode, "ANSI")) ? 'A' :
			(! strcmp(mymode, "TERADATA")) ? 'T' : 'D';
		dbcp->req_buf_len = 65536;
		dbcp->resp_buf_len = 63000;
		dbcp->logon_ptr = SvPV(logonstr, logonlen);
		dbcp->logon_len = logonlen;
		if (SvTRUE(runstring)) {
			dbcp->run_ptr = SvPV(runstring, runlen);
			dbcp->run_len = runlen;
		}
		if (SvTRUE(logonsrc)) {
			dbcp->using_data_ptr = SvPV(logonsrc, logonsrclen);
			dbcp->using_data_len = logonsrclen;
		}
		dbcp->func = DBFCON;

		if (dbc_ctx->debug)
			printf("get_connection: connecting\n");

		EXTEND(SP, 6);
		DBCHCL (&result, cnta, dbcp);
		if (result != EM_OK) {
			if (dbc_ctx->debug)
				printf("get_connection: connection failed\n");

			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(sv_2mortal(newSViv(result)));
			PUSHs(sv_2mortal(newSVpv(dbcp->msg_text, dbcp->msg_len)));
			Safefree(dbc_ctx);
			XSRETURN(5);
		}

		dbcp->i_req_id = dbcp->o_req_id;
		dbcp->i_sess_id = dbcp->o_sess_id;

		if (dbc_ctx->debug)
			printf("get_connection: fetching result\n");

		dbcp->func = DBFFET;
		result = EM_OK;
		while (result == EM_OK) {
			DBCHCL (&result, cnta, dbcp);
			if (result != EM_OK)
				break;

			switch (dbcp->fet_parcel_flavor) {
				case PclLSN:
					mylsn = *(I32 *)dbcp->fet_data_ptr;
					break;

				case PclSUCCESS:
					break;

				case PclFAILURE:
				case PclERROR:
					result = tdcli_write_dbs_error(dbcp->fet_data_ptr, errstr);
					sv_setiv(dbcarea, (IV)0);
					Safefree(dbc_ctx);
					PUSHs(&PL_sv_undef);
					PUSHs(&PL_sv_undef);
					PUSHs(&PL_sv_undef);
					PUSHs(&PL_sv_undef);
					PUSHs(sv_2mortal(newSViv(result)));
					PUSHs(sv_2mortal(newSVpv(errstr, strlen(errstr))));
					XSRETURN(5);

				case PclENDSTATEMENT:
				case PclENDREQUEST:
					break;

				default:
					break;
			}
		}

		if ((result != EM_OK) && (result != REQEXHAUST)) {

			if (dbc_ctx->debug)
				printf("get_connection: odd result\n");

			sv_setiv(dbcarea, (IV)0);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(sv_2mortal(newSViv(result)));
			PUSHs(sv_2mortal(newSVpv(dbcp->msg_text, dbcp->msg_len)));
			Safefree(dbc_ctx);
			XSRETURN(5);
		}
		sessno = dbcp->o_dbc_sess_id;
		hostid = dbcp->o_host_id;

		if (dbc_ctx->debug)
			printf("Connect: Session is %d\n", dbcp->o_dbc_sess_id);

		dbcp->func = DBFERQ;
		DBCHCL (&result, cnta, dbcp);
		dbcp->charset_type = 0;
		dbcp->connect_type = 0;
		dbcp->inter_ptr = NULL;
		DBCHREL(&result, cnta, dbcp->i_sess_id, relstr, verstr);

		if (dbc_ctx->debug > 2)
			printf("Connect exit: dbcp is %p\n", dbcp);
		PUSHs(sv_2mortal(newSViv(sessno)));
		PUSHs(sv_2mortal(newSViv(hostid)));
		PUSHs(sv_2mortal(newSVpv(verstr, strlen(verstr))));
		PUSHs(sv_2mortal(newSViv(mylsn)));
		PUSHs(sv_2mortal(newSViv(0)));
		PUSHs(&PL_sv_undef);
		XSRETURN(5);


void
tdxs_get_tdat_release(dbc)
	SV *dbc
	PPCODE:
		dbc_ctx_t *dbc_ctx = (dbc_ctx_t *)SvIV(dbc);
		DBCAREA *dbcp = &dbc_ctx->dbc;
		char relstr[7];
		char verstr[15];
		I32 result;
		char cnta[1];

		DBCHREL(&result, cnta, dbcp->i_sess_id, relstr, verstr);
		ST(0) = sv_2mortal(newSVpv(verstr, strlen(verstr)));
		XSRETURN(1);

void
tdxs_cleanup(dbc, errstr)
	SV *dbc
	SV *errstr
	PPCODE:
		dbc_ctxptr_t dbc_ctx = INT2PTR(dbc_ctxptr_t, SvUV(dbc));
		DBCAREA *dbcp = &dbc_ctx->dbc;
		I32 result;
		char *cnta = NULL;

		dbcp->func = DBFDSC;
		DBCHCL (&result, cnta, dbcp);

		if (result != EM_OK)
			sv_setpv(errstr, dbcp->msg_text);
		else
			sv_setsv(errstr, &PL_sv_undef);

		Safefree(dbc_ctx);
		sv_setsv(dbc, &PL_sv_undef);
		ST(0) = sv_2mortal(newSViv(result));
		XSRETURN(1);


void
tdxs_send_request(dbc, len, keepresp, buffer, resplen)
	SV * dbc
	SV * len
	SV * keepresp
	SV * buffer
	SV * resplen
	PPCODE:
		STRLEN buflen;
		STRLEN rlen;
		char *buf = SvPV(buffer, buflen) + TDAT_HDR_SZ;
		dbc_ctxptr_t dbc_ctx = INT2PTR(dbc_ctxptr_t, SvUV(dbc));
		DBCAREA *dbcp = &dbc_ctx->dbc;
		I32 result;
		char *cnta = NULL;

		buflen = SvIV(len);
		buflen -= TDAT_HDR_SZ;

		rlen = SvIV(resplen);
		rlen -= TDAT_HDR_SZ;

		if (dbc_ctx->debug > 2)
			printf("send_request: dbcp is %p\n", dbcp);
		dbcp->change_opts = 'Y';

		if (dbc_ctx->debug && SvTRUE(keepresp))
			printf("KEEPRESP requested\n");

		dbcp->keep_resp = (SvTRUE(keepresp) ? 'Y' : 'N');
		dbcp->request_mode = 'B';

		dbcp->loc_mode = 'Y';
		dbcp->parcel_mode = 'N';
		dbcp->req_proc_opt = 'E';
		dbcp->req_ptr = buf;
		dbcp->req_len = buflen;
		dbcp->req_buf_len = buflen + 100;
		dbcp->resp_buf_len = rlen;

		if (dbc_ctx->debug)
			printf("send_request: request length is %i\n", buflen);

		dbcp->func = DBFIRQ;
		DBCHCL (&result, cnta, dbcp);
		EXTEND(SP, 3);
		if (result != EM_OK) {
			PUSHs(&PL_sv_undef);
			PUSHs(sv_2mortal(newSViv(result)));
			PUSHs(sv_2mortal(newSVpv(dbcp->msg_text, dbcp->msg_len)));
			XSRETURN(2);
		}

		dbcp->i_req_id = dbcp->o_req_id;

		if (dbc_ctx->debug)
			printf("send_request: request sent; reqid %i\n", dbcp->o_req_id);

		PUSHs(sv_2mortal(newSViv(dbcp->o_req_id)));
		PUSHs(sv_2mortal(newSViv(0)));
		PUSHs(&PL_sv_undef);
		XSRETURN(2);


void
tdxs_wait_for_response()
	PPCODE:
		I32 result = EM_OK;
		I32 sessid = 0;
		I32 token = 0;
		char *cnta = NULL;
		DBCHWAT(&result, cnta, &sessid, &token);
		EXTEND(SP, 3);
		if (result != EM_OK) {
			PUSHs(&PL_sv_undef);
			PUSHs(sv_2mortal(newSViv(result)));
			PUSHs(&PL_sv_undef);
			XSRETURN(3);
		}
		PUSHs(sv_2mortal(newSViv(sessid)));
		PUSHs(sv_2mortal(newSViv(0)));
		PUSHs(&PL_sv_undef);
		XSRETURN(3);


void
tdxs_get_response(dbc, buffer, reqid, keepresp, wait_for_resp)
	SV *dbc
	SV *buffer
	SV *reqid
	SV *keepresp
	SV *wait_for_resp
	PPCODE:
		dbc_ctx_t *dbc_ctx = (dbc_ctx_t *)SvIV(dbc);
		DBCAREA *dbcp = &dbc_ctx->dbc;
		I32 result;
		char *cnta = NULL;
		char *fullbuf = NULL;
		SV *newbuf = NULL;

		if (dbc_ctx->debug > 2)
		 	printf("get_response: dbcp is %p\n", dbcp);
		dbcp->i_req_id = SvIV(reqid);
		dbcp->change_opts = 'Y';

		if (dbc_ctx->debug > 2)
			printf((SvTRUE(keepresp) ? "reqid %d KEEPRESP\n" : "reqid %d RESP\n"),
				dbcp->i_req_id);
		if ((dbc_ctx->debug > 2) && SvTRUE(keepresp))
			printf("KEEPRESP on req %d\n", dbcp->i_req_id);

		dbcp->keep_resp = (SvTRUE(keepresp) ? 'Y' : 'N');
	 	dbcp->wait_for_resp = (SvTRUE(wait_for_resp) ? 'Y' : 'N');

		if (dbc_ctx->debug)
		 	printf("Wait for resp is %c\n", dbcp->wait_for_resp);

		dbcp->loc_mode = 'Y';
		dbcp->parcel_mode = 'N';
		dbcp->request_mode = 'B';
		dbcp->resp_buf_len = 63000;

		dbcp->func = DBFFET;
		result = EM_OK;

		if (dbc_ctx->debug)
			printf("get_response: getting response for %d\n", SvIV(reqid));

		DBCHCL (&result, cnta, dbcp);
		EXTEND(SP, 2);
		if (result != EM_OK) {
			if (dbc_ctx->debug)
				printf("get_response: got error %d\n", result);

			PUSHs(sv_2mortal(newSViv(result)));
			if (SvTRUE(wait_for_resp) || (result != EM_NODATA))
				PUSHs(sv_2mortal(newSVpv(dbcp->msg_text, dbcp->msg_len)));
			else
				PUSHs(&PL_sv_undef);
			XSRETURN(2);
		}
		if (dbc_ctx->debug)
			printf("get_response: response length is %i\n", dbcp->fet_ret_data_len);

		sv_setpvn(buffer, dummy_hdr, TDAT_HDR_SZ);
		sv_catpvn(buffer, dbcp->fet_data_ptr, dbcp->fet_ret_data_len);
		PUSHs(sv_2mortal(newSViv(0)));
		PUSHs(&PL_sv_undef);
		XSRETURN(2);


void
tdxs_end_request(dbc, reqid)
	SV *dbc
	int reqid
	PPCODE:
		dbc_ctxptr_t dbc_ctx = INT2PTR(dbc_ctxptr_t, SvUV(dbc));
		DBCAREA *dbcp = &dbc_ctx->dbc;
		I32 result = EM_OK;
		char *cnta = NULL;
		if (dbc_ctx->debug)
			printf("EndReq: End request for %d\n", reqid);

		dbcp->i_req_id = reqid;
		dbcp->func = DBFERQ;
		DBCHCL (&result, cnta, dbcp);
		EXTEND(SP,2);
		if (result != EM_OK) {
			PUSHs(sv_2mortal(newSViv(result)));
			PUSHs(sv_2mortal(newSVpv(dbcp->msg_text, dbcp->msg_len)));
			XSRETURN(2);
		}

		PUSHs(sv_2mortal(newSViv(0)));
		PUSHs(&PL_sv_undef);
		XSRETURN(2);


void
tdxs_abort_request(dbc, reqid)
	SV * dbc
	int reqid
	PPCODE:
		dbc_ctxptr_t dbc_ctx = INT2PTR(dbc_ctxptr_t, SvUV(dbc));
		DBCAREA *dbcp = &dbc_ctx->dbc;
		I32 result = EM_OK;
		char *cnta = NULL;
		if (dbc_ctx->debug)
			printf("AbortReq: Abort request for %d\n", reqid);

		dbcp->i_req_id = reqid;
		dbcp->func = DBFABT;
		DBCHCL (&result, cnta, dbcp);
		EXTEND(SP,2);
		if (result != EM_OK) {
			PUSHs(sv_2mortal(newSViv(result)));
			PUSHs(sv_2mortal(newSVpv(dbcp->msg_text, dbcp->msg_len)));
			XSRETURN(2);
		}

		PUSHs(sv_2mortal(newSViv(0)));
		PUSHs(&PL_sv_undef);
		XSRETURN(2);


void
tdxs_test_leak(dbc, buffer, count)
	SV * dbc
	SV * buffer
	SV * count
	PPCODE:
		STRLEN buflen;
		char *buf = SvPV(buffer, buflen) + TDAT_HDR_SZ;
		dbc_ctx_t *dbc_ctx = (dbc_ctx_t *)SvIV(dbc);
		DBCAREA *dbcp = &dbc_ctx->dbc;
		I32 result;
		char *cnta = NULL;
		int i = SvIV(count);

		buflen -= TDAT_HDR_SZ;

		while (i > 0) {
			i--;

		 	if (dbc_ctx->debug > 2)
		 		printf("send_request: dbcp is %p\n", dbcp);
			dbcp->change_opts = 'Y';
			dbcp->request_mode = 'B';
			dbcp->keep_resp = 'N';
			dbcp->loc_mode = 'Y';
			dbcp->parcel_mode = 'N';
			dbcp->req_proc_opt = 'E';
			dbcp->req_ptr = buf;
			dbcp->req_len = buflen;
			dbcp->req_buf_len = 65536;
			dbcp->resp_buf_len = 63000;

			dbcp->func = DBFIRQ;
			DBCHCL (&result, cnta, dbcp);
			if (result != EM_OK) {
				printf("%s\n", dbcp->msg_text);
				ST(0) = sv_2mortal(newSViv(result));
				XSRETURN(1);
			}

			dbcp->i_req_id = dbcp->o_req_id;
			dbcp->i_sess_id = dbcp->o_sess_id;
			dbcp->change_opts = 'Y';
		 	dbcp->wait_for_resp = 'Y';
			dbcp->loc_mode = 'Y';
			dbcp->parcel_mode = 'N';
			dbcp->request_mode = 'B';
			dbcp->resp_buf_len = 63000;

			dbcp->func = DBFFET;
			result = EM_OK;

			DBCHCL (&result, cnta, dbcp);
			if (result != EM_OK) {
				printf("%s\n", dbcp->msg_text);
				ST(0) = sv_2mortal(newSViv(result));
				XSRETURN(1);
			}

			dbcp->func = DBFERQ;
			DBCHCL (&result, cnta, dbcp);
			if (result != EM_OK) {
				printf("%s\n", dbcp->msg_text);
				ST(0) = sv_2mortal(newSViv(result));
				XSRETURN(1);
			}
		}
		printf("test_leak comnpleted\n");
		ST(0) = sv_2mortal(newSViv(0));
		XSRETURN(1);
