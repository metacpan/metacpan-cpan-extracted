/*
   Copyright (c) 2000-2020 Greg Sabino Mullane and others: see the Changes file
   Copyright (c) 1997-2000 Edmund Mergl
   Portions Copyright (c) 1994-1997 Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

#include <wchar.h>

#ifdef WIN32
static int errno;
#include <string.h>
#define strcasecmp(s1,s2) stricmp((s1), (s2))
#else
#include <strings.h>
#endif

#define DBDPG_TRUE (bool)1
#define DBDPG_FALSE (bool)0
#define PG_ASYNC 1
#define PG_OLDQUERY_CANCEL 2
#define PG_OLDQUERY_WAIT 4
#define PG_UNKNOWN_VERSION 0

/* Force preprocessors to use this variable. Default to something valid yet noticeable */
#ifndef PGLIBVERSION
#define PGLIBVERSION 80009
#endif

#include "libkci_fe.h"

#ifndef INV_READ
#define INV_READ 0x00040000
#endif
#ifndef INV_WRITE
#define INV_WRITE 0x00020000
#endif

#ifndef PGRES_COPY_BOTH
#define PGRES_COPY_BOTH 8
#endif

#ifdef BUFSIZ
#undef BUFSIZ
#endif
/* this should improve I/O performance for large objects */
#define BUFSIZ 32768

#define NEED_DBIXS_VERSION 93

#define PERL_NO_GET_CONTEXT

#include <DBIXS.h>      /* installed by the DBI module */

#include <dbivport.h>   /* DBI portability macros */

#include <dbd_xsh.h>    /* installed by the DBI module */

DBISTATE_DECLARE;

#include "types.h"
#include "dbdimp.h"
#include "quote.h"

#define TLEVEL_slow	     (DBIS->debug & DBIc_TRACE_LEVEL_MASK)
#define TFLAGS_slow	     (DBIS->debug & DBIc_TRACE_FLAGS_MASK)

#define TSQL	     (TFLAGS_slow & 256) /* Defined in DBI */

#define FLAGS_LIBPQ    0x01000000
#define FLAGS_START    0x02000000
#define FLAGS_END      0x04000000
#define FLAGS_PREFIX   0x08000000
#define FLAGS_LOGIN    0x10000000

#define TFLIBPQ_slow      (TFLAGS_slow & FLAGS_LIBPQ)
#define TFSTART_slow      (TFLAGS_slow & FLAGS_START)
#define TFEND_slow        (TFLAGS_slow & FLAGS_END)
#define TFPREFIX_slow     (TFLAGS_slow & FLAGS_PREFIX)
#define TFLOGIN_slow      (TFLAGS_slow & FLAGS_LOGIN)

#define TRACE1_slow       (TLEVEL_slow >= 1) /* Avoid using directly: DBI only */
#define TRACE2_slow       (TLEVEL_slow >= 2) /* Avoid using directly: DBI only */
#define TRACE3_slow       (TLEVEL_slow >= 3) /* Basic debugging */
#define TRACE4_slow       (TLEVEL_slow >= 4) /* More detailed debugging */
#define TRACE5_slow       (TLEVEL_slow >= 5) /* Very detailed debugging */
#define TRACE6_slow       (TLEVEL_slow >= 6)
#define TRACE7_slow       (TLEVEL_slow >= 7)
#define TRACE8_slow       (TLEVEL_slow >= 8)

#define TLIBPQ_slow       (TRACE5_slow || TFLIBPQ_slow)
#define TSTART_slow       (TRACE4_slow || TFSTART_slow) /* Start of a major function */
#define TEND_slow         (TRACE4_slow || TFEND_slow)   /* End of a major function   */
#define TLOGIN_slow       (TRACE5_slow || TFLOGIN_slow) /* Connect and disconnect    */

#define TRACEWARN_slow    (TRACE1_slow) /* Non-fatal but serious problems */

/* Do we show a "dbdpg: " header? */
#define THEADER_slow      (TFPREFIX_slow) ? "dbdpg: " : ""

#define TRC (void)PerlIO_printf

/* Fancy stuff for tracing of commonly used libkci functions */
#define TRACE_XX                   if (TLIBPQ_slow) TRC(DBILOGFP,
/* XXX every use of every one of these costs at least one call to DBIS
 * and possibly +1 for DBILOGFP and another for THEADER_slow!
 * A better approach may be something like DBD::Oracle's
 * http://cpansearch.perl.org/src/PYTHIAN/DBD-Oracle-1.42/ocitrace.h
 * #define PGfooBar_log_stat(imp_xxh, stat, a,b,c) ... where imp_xxh
 * is used to determine the logging and stat holds the result.
 * That makes the code uncluttered and gives good flexibility.
 */
#define TRACE_PQBACKENDPID         TRACE_XX "%sKCIConnectionGetBackendPid\n",          THEADER_slow)
#define TRACE_PQCANCEL             TRACE_XX "%sKCICancelSend\n",              THEADER_slow)
#define TRACE_PQCLEAR              TRACE_XX "%sKCIResultDealloc\n",               THEADER_slow)
#define TRACE_PQCMDSTATUS          TRACE_XX "%sKCIResultGetCommandStatus\n",           THEADER_slow)
#define TRACE_PQCMDTUPLES          TRACE_XX "%sKCIResultGetAffectedCount\n",           THEADER_slow)
#define TRACE_PQCONNECTDB          TRACE_XX "%sKCIConnectionCreate\n",           THEADER_slow)
#define TRACE_PQCONSUMEINPUT       TRACE_XX "%sKCIConnectionForceRead\n",        THEADER_slow)
#define TRACE_PQDB                 TRACE_XX "%sKCIConnectionGetDatabase\n",                  THEADER_slow)
#define TRACE_PQENDCOPY            TRACE_XX "%sKCICopySync\n",             THEADER_slow)
#define TRACE_PQERRORMESSAGE       TRACE_XX "%sKCIConnectionGetLastError\n",        THEADER_slow)
#define TRACE_PQEXEC               TRACE_XX "%sKCIStatementExecute\n",                THEADER_slow)
#define TRACE_PQEXECPARAMS         TRACE_XX "%sKCIStatementExecuteParams\n",          THEADER_slow)
#define TRACE_PQEXECPREPARED       TRACE_XX "%sKCIStatementExecutePrepared\n",        THEADER_slow)
#define TRACE_PQEXECPREPARED2      TRACE_XX "%sKCIStatementExecutePrepared2\n",        THEADER_slow)
#define TRACE_PQFINISH             TRACE_XX "%sKCIConnectionDestory\n",              THEADER_slow)
#define TRACE_PQFMOD               TRACE_XX "%sKCIResultGetColumnTypmod\n",                THEADER_slow)
#define TRACE_PQFNAME              TRACE_XX "%sKCIResultGetColumnName\n",               THEADER_slow)
#define TRACE_PQFREECANCEL         TRACE_XX "%sKCICancelDealloc\n",          THEADER_slow)
#define TRACE_PQFREEMEM            TRACE_XX "%sKCIFree\n",             THEADER_slow)
#define TRACE_PQFSIZE              TRACE_XX "%sKCIResultGetColumnLength\n",               THEADER_slow)
#define TRACE_PQFTABLECOL          TRACE_XX "%sKCIResultGetRelationOidOfColumnCol\n",           THEADER_slow)
#define TRACE_PQFTABLE             TRACE_XX "%sKCIResultGetRelationOidOfColumn\n",              THEADER_slow)
#define TRACE_PQFTYPE              TRACE_XX "%sKCIResultGetColumnType\n",               THEADER_slow)
#define TRACE_PQGETCANCEL          TRACE_XX "%sKCICancelAlloc\n",           THEADER_slow)
#define TRACE_PQGETCOPYDATA        TRACE_XX "%sKCICopyReceiveData\n",         THEADER_slow)
#define TRACE_PQGETISNULL          TRACE_XX "%sKCIResultColumnIsNull\n",           THEADER_slow)
#define TRACE_PQGETRESULT          TRACE_XX "%sKCIConnectionFetchResult\n",           THEADER_slow)
#define TRACE_PQGETLENGTH          TRACE_XX "%sKCIResultGetColumnValueLength\n",           THEADER_slow)
#define TRACE_PQGETVALUE           TRACE_XX "%sKCIResultGetColumnValue\n",            THEADER_slow)
#define TRACE_PQHOST               TRACE_XX "%sKCIConnectionGetHost\n",                THEADER_slow)
#define TRACE_PQISBUSY             TRACE_XX "%sKCIConnectionIsBusy\n",              THEADER_slow)
#define TRACE_PQNFIELDS            TRACE_XX "%sKCIResultGetColumnCount\n",             THEADER_slow)
#define TRACE_PQNOTIFIES           TRACE_XX "%sKCIGetNextNotification\n",            THEADER_slow)
#define TRACE_PQNTUPLES            TRACE_XX "%sKCIResultGetRowCount\n",             THEADER_slow)
#define TRACE_PQOIDVALUE           TRACE_XX "%sKCIResultInsertRowOid\n",            THEADER_slow)
#define TRACE_PQOPTIONS            TRACE_XX "%sKCIConnectionGetCommandLineOptions\n",             THEADER_slow)
#define TRACE_PQPARAMETERSTATUS    TRACE_XX "%sKCIConnectionGetParameterValue\n",     THEADER_slow)
#define TRACE_PQPASS               TRACE_XX "%sKCIConnectionGetPassword\n",                THEADER_slow)
#define TRACE_PQPORT               TRACE_XX "%sKCIConnectionGetPort\n",                THEADER_slow)
#define TRACE_PQPREPARE            TRACE_XX "%sKCIStatementPrepare\n",             THEADER_slow)
#define TRACE_PQPROTOCOLVERSION    TRACE_XX "%sKCIConnectionGetProtocolVersion\n",     THEADER_slow)
#define TRACE_PQPUTCOPYDATA        TRACE_XX "%sKCICopySendData\n",         THEADER_slow)
#define TRACE_PQPUTCOPYEND         TRACE_XX "%sKCICopySendEOF\n",          THEADER_slow)
#define TRACE_PQRESULTERRORFIELD   TRACE_XX "%sKCIResultGetErrorField\n",    THEADER_slow)
#define TRACE_PQRESULTSTATUS       TRACE_XX "%sKCIResultGetStatusCode\n",        THEADER_slow)
#define TRACE_PQSENDQUERY          TRACE_XX "%sKCIStatementSend\n",           THEADER_slow)
#define TRACE_PQSENDQUERYPARAMS    TRACE_XX "%sKCIStatementSendParams\n",     THEADER_slow)
#define TRACE_PQSENDQUERYPREPARED  TRACE_XX "%sKCIStatementSendPrepared\n",   THEADER_slow)
#define TRACE_PQSERVERVERSION      TRACE_XX "%sKCIConnectionGetServerVersion\n",       THEADER_slow)
#define TRACE_PQSETERRORVERBOSITY  TRACE_XX "%sKCISetVerbosity\n",   THEADER_slow)
#define TRACE_PQSETNOTICEPROCESSOR TRACE_XX "%sKCISetNoticeProcessor\n",  THEADER_slow)
#define TRACE_PQSOCKET             TRACE_XX "%sKCIConnectionGetSocket\n",              THEADER_slow)
#define TRACE_PQSTATUS             TRACE_XX "%sKCIConnectionGetStatus\n",              THEADER_slow)
#define TRACE_PQTRACE              TRACE_XX "%sKCISetLogFile\n",               THEADER_slow)
#define TRACE_PQTRANSACTIONSTATUS  TRACE_XX "%sKCIConnectionGetTransactionStatus\n",   THEADER_slow)
#define TRACE_PQUNTRACE            TRACE_XX "%sKCIResetLogFile\n",             THEADER_slow)
#define TRACE_PQUSER               TRACE_XX "%sKCIConnectionGetUser\n",                THEADER_slow)

/* end of KingBase.h */
