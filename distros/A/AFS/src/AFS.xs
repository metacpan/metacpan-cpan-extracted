/***********************************************************************
 *
 * AFS.xs - AFS extensions for Perl
 *
 * RCS-Id: @(#)$RCS-Id: src/AFS.xs 73757dc Thu Oct 23 12:46:20 2014 +0200 Norbert E Gruener$
 *
 * Copyright (c) 2003, International Business Machines Corporation and others.
 *
 * This software has been released under the terms of the IBM Public
 * License.  For details, see the IBM-LICENSE file in the LICENCES
 * directory or online at http://www.openafs.org/dl/license10.html
 *
 * Contributors
 *    2004-2014: Norbert E. Gruener <nog@MPA-Garching.MPG.de>
 *         2003: Alf Wachsmann <alfw@slac.stanford.edu>
 *               Venkata Phani Kiran Achanta <neo_phani@hotmail.com>, and
 *               Norbert E. Gruener <nog@MPA-Garching.MPG.de>
 *    2001-2002: Norbert E. Gruener <nog@MPA-Garching.MPG.de>
 *
 * The original library was written by Roland Schemers <schemers@slapshot.stanford.edu>
 * and is covered by the following copyright:
 *
 * Copyright (c) 1994 Board of Trustees, Leland Stanford Jr. University
 * For conditions of distribution and use, see the copyright notice in
 * the Stanford-LICENCE file.
 *
 * The code for the original library were mainly taken from the AFS
 * source distribution, which comes with this message:
 *
 *    Copyright (C) 1989-1994 Transarc Corporation - All rights reserved
 *    P_R_P_Q_# (C) COPYRIGHT IBM CORPORATION 1987, 1988, 1989
 *
 ***********************************************************************/

#include "EXTERN.h"

#ifdef __sgi                    /* needed to get a clean compile */
#include <setjmp.h>
#endif

#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

#include <afs/param.h>
/* tired of seeing messages about TRUE/FALSE being redefined in rx/xdr.h */
#undef TRUE
#undef FALSE
#include <rx/xdr.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netdb.h>
#include <errno.h>
#include <stdio.h>
#include <netinet/in.h>
#include <sys/stat.h>
#undef INIT
#include <afs/stds.h>
#include <afs/afs.h>
#include <afs/vice.h>
#include <afs/venus.h>
#undef VIRTUE
#undef VICE
#include <afs/prs_fs.h>
#include <afs/afsint.h>

#include <afs/auth.h>
#include <afs/cellconfig.h>
#if defined(AFS_3_4)
#else
#include <afs/dirpath.h>
#endif
#include <ubik.h>
#include <rx/rxkad.h>
#include <afs/vldbint.h>
#include <afs/volser.h>
#ifndef RV_RDONLY
#define RV_FULLRST      0x000001
#define RV_OFFLINE      0x000002
#define RV_CRDUMP       0x000010
#define RV_CRKEEP       0x000020
#define RV_CRNEW        0x000040
#define RV_LUDUMP       0x000100
#define RV_LUKEEP       0x000200
#define RV_LUNEW        0x000400
#define RV_RDONLY       0x010000
#define RV_CPINCR       0x020000
#define RV_NOVLDB       0x040000
#define RV_NOCLONE      0x080000
#define RV_NODEL        0x100000
#endif
#include <afs/vlserver.h>
#include <afs/volint.h>
#include <afs/cmd.h>
#include <afs/usd.h>
#include <afs/ptclient.h>
#include <afs/pterror.h>
#include <afs/print.h>
#include <afs/kauth.h>
#include <afs/kautils.h>
#include <afs/bosint.h>
#include <afs/bnode.h>
#include <afs/ktime.h>
#if defined(AFS_OLD_COM_ERR)
#include <com_err.h>
#else
#include <afs/com_err.h>
#endif
#include <des.h>

#if defined(AFS_3_4) || defined(AFS_3_5)
#else
#define int32 afs_int32
#define uint32 afs_uint32
#endif

const char *const xs_version = "AFS.xs (Version 2.6.4)";

/* here because it seemed too painful to #define KERNEL before #inc afs.h */
struct VenusFid {
    int32 Cell;
    struct AFSFid Fid;
};

/* tpf nog 03/29/99 */
/* the following was added by leg@andrew, 10/9/96 */
/*#ifdef __hpux*//* only on hp700_ux90 systems */
#if defined(__hpux) || defined(_AIX) || defined(sun) || defined(__sun__) || defined(__sgi) || defined(__linux)
static int32 name_is_numeric(char *);
#endif

typedef SV *AFS__ACL;
typedef struct ktc_principal *AFS__KTC_PRINCIPAL;
typedef struct ktc_token *AFS__KTC_TOKEN;
typedef struct ktc_encryptionKey *AFS__KTC_EKEY;
typedef struct ubik_client *AFS__KAS;
typedef struct ubik_client *AFS__PTS;
typedef struct ubik_client *AFS__VLDB;
typedef struct ubik_client *AFS__VOS;
typedef struct rx_connection *AFS__BOS;

extern struct ubik_client *cstruct;
#include "afs_prototypes.h"
extern int afs_setpag();

static rxkad_level vsu_rxkad_level = rxkad_clear;
static struct ktc_token the_null_token;
static int32 convert_numeric_names = 1;
static int32 rx_initialized = 0;

#define MAXSIZE 2048
#define MAXINSIZE 1300

#ifndef MAXPATHLEN
#define MAXPATHLEN 1024
#endif

#define AFS_ASK   0
#define AFS_ABORT 1
#define AFS_FULL  2
#define AFS_INC   3

#ifdef AFS_PTHREAD_ENV
#undef clock_haveCurrentTime
#undef clock_UpdateTime
struct clock clock_now;
#endif /* AFS_PTHREAD_ENV*/

/* error handling macros */

#define ERROR_EXIT(code) {error=(code); goto error_exit;}

#define SETCODE(code) set_code(code)
#define BSETCODE(code, msg) bv_set_code(code, msg)
#define VSETCODE(code, msg) bv_set_code(code, msg)
#define KSETCODE(code, msg) k_set_code(code, msg)
#define PSETCODE(msg) p_set_code(msg)

static int32 raise_exception = 0;

void safe_hv_store (HV* ahv,char * key ,int i ,SV * asv,int j) {
   if (! hv_store(ahv, key, i, asv, j)) {
       fprintf(stderr,"Panic ... internal error. hv_store failed.\n");
       exit(1);
   }
   return;
}

static void bv_set_code(code, msg)
    int32 code;
    const char *msg;
{
    SV *sv = get_sv("AFS::CODE", TRUE);
    sv_setiv(sv, (IV) code);
/*   printf("BV_SET_CODE %s (%d)\n", msg, code); */
    if (code == 0) {
        sv_setpv(sv, "");
    }
    else {
        if (raise_exception) {
            char buffer[1024];
            sprintf(buffer, "AFS exception: %s (%d)", msg, code);
            croak(buffer);
        }
/*      printf("BV_SET_CODE %s (%d)\n", msg, code); */
        sv_setpv(sv, (char *) msg);
    }
    SvIOK_on(sv);
}

static void p_set_code(msg)
    const char *msg;
{
    int32 code = errno;
    SV *sv = get_sv("AFS::CODE", TRUE);
    sv_setiv(sv, (IV) code);
/*   printf("P_SET_CODE %s (%d)\n", msg, code); */
    if (code == 0) {
        sv_setpv(sv, "");
    }
    else {
        char buffer[1024];
        if (raise_exception) {
            sprintf(buffer, "AFS exception: %s (%s) (%d)", msg, error_message(code), code);
            croak(buffer);
        }
/*      printf("P_SET_CODE %s (%d)\n", msg, code); */
        sprintf(buffer, "%s: %s (%d)", msg, error_message(code), code);
        sv_setpv(sv, buffer);
    }
    SvIOK_on(sv);
}

static void k_set_code(code, msg)
    int32 code;
    const char *msg;
{
    SV *sv = get_sv("AFS::CODE", TRUE);
    sv_setiv(sv, (IV) code);
/*   printf("K_SET_CODE %s (%d)\n", msg, code); */
    if (code == 0) {
        sv_setpv(sv, "");
    }
    else {
        char buffer[1024];
        if (raise_exception) {
            sprintf(buffer, "AFS exception: %s (%s) (%d)", msg, error_message(code), code);
            croak(buffer);
        }
/*      printf("K_SET_CODE %s (%d)\n", msg, code); */
        sprintf(buffer, "%s: %s (%d)", msg, error_message(code), code);
        sv_setpv(sv, buffer);
    }
    SvIOK_on(sv);
}

static void set_code(code)
    int32 code;
{
    SV *sv = get_sv("AFS::CODE", TRUE);
    if (code == -1) { code = errno; }
/*     printf("SET_CODE %d\n", code); */
    sv_setiv(sv, (IV) code);
    if (code == 0) {
        sv_setpv(sv, "");
    }
    else {
        if (raise_exception) {
            char buffer[1024];
            sprintf(buffer, "AFS exception: %s (%d)", error_message(code), code);
            croak(buffer);
        }
        sv_setpv(sv, (char *) error_message(code));
    }
    SvIOK_on(sv);
}

/* taken from openafs-1.2.9  */
/* volser/vsprocs.c          */
int set_errbuff(buffer, errcode)
    char *buffer;
    int32 errcode;
{
    /*replace by a big switch statement */
    switch (errcode) {
      case 0:
          break;
      case -1:
          sprintf(buffer, "Possible communication failure\n");
          break;
      case VSALVAGE:
          sprintf(buffer, "Volume needs to be salvaged\n");
          break;
      case VNOVNODE:
          sprintf(buffer, "Bad vnode number quoted\n");
          break;
      case VNOVOL:
          sprintf(buffer, "Volume not attached, does not exist, or not on line\n");
          break;
      case VVOLEXISTS:
          sprintf(buffer, "Volume already exists\n");
          break;
      case VNOSERVICE:
          sprintf(buffer, "Volume is not in service\n");
          break;
      case VOFFLINE:
          sprintf(buffer, "Volume is off line\n");
          break;
      case VONLINE:
          sprintf(buffer, "Volume is already on line\n");
          break;
      case VDISKFULL:
          sprintf(buffer, "Partition is full\n");
          break;
      case VOVERQUOTA:
          sprintf(buffer, "Volume max quota exceeded\n");
          break;
      case VBUSY:
          sprintf(buffer, "Volume temporarily unavailable\n");
          break;
      case VMOVED:
          sprintf(buffer, "Volume has moved to another server\n");
          break;
      case VL_IDEXIST:
          sprintf(buffer, "VLDB: volume Id exists in the vldb\n");
          break;
      case VL_IO:
          sprintf(buffer, "VLDB: a read terminated too early\n");
          break;
      case VL_NAMEEXIST:
          sprintf(buffer, "VLDB: volume entry exists in the vldb\n");
          break;
      case VL_CREATEFAIL:
          sprintf(buffer, "VLDB: internal creation failure\n");
          break;
      case VL_NOENT:
          sprintf(buffer, "VLDB: no such entry\n");
          break;
      case VL_EMPTY:
          sprintf(buffer, "VLDB: vldb database is empty\n");
          break;
      case VL_ENTDELETED:
          sprintf(buffer, "VLDB: entry is deleted (soft delete)\n");
          break;
      case VL_BADNAME:
          sprintf(buffer, "VLDB: volume name is illegal\n");
          break;
      case VL_BADINDEX:
          sprintf(buffer, "VLDB: index was out of range\n");
          break;
      case VL_BADVOLTYPE:
          sprintf(buffer, "VLDB: bad volume type\n");
          break;
      case VL_BADSERVER:
          sprintf(buffer, "VLDB: illegal server number (not within limits)\n");
          break;
      case VL_BADPARTITION:
          sprintf(buffer, "VLDB: bad partition number\n");
          break;
      case VL_REPSFULL:
          sprintf(buffer, "VLDB: run out of space for replication sites\n");
          break;
      case VL_NOREPSERVER:
          sprintf(buffer, "VLDB: no such repsite server exists\n");
          break;
      case VL_DUPREPSERVER:
          sprintf(buffer, "VLDB: replication site server already exists\n");
          break;
      case VL_RWNOTFOUND:
          sprintf(buffer, "VLDB: parent r/w entry not found\n");
          break;
      case VL_BADREFCOUNT:
          sprintf(buffer, "VLDB: illegal reference count number\n");
          break;
      case VL_SIZEEXCEEDED:
          sprintf(buffer, "VLDB: vldb size for attributes exceeded\n");
          break;
      case VL_BADENTRY:
          sprintf(buffer, "VLDB: bad incoming vldb entry\n");
          break;
      case VL_BADVOLIDBUMP:
          sprintf(buffer, "VLDB: illegal max volid increment\n");
          break;
      case VL_IDALREADYHASHED:
          sprintf(buffer, "VLDB: (RO/BACK) Id already hashed\n");
          break;
      case VL_ENTRYLOCKED:
          sprintf(buffer, "VLDB: vldb entry is already locked\n");
          break;
      case VL_BADVOLOPER:
          sprintf(buffer, "VLDB: bad volume operation code\n");
          break;
      case VL_BADRELLOCKTYPE:
          sprintf(buffer, "VLDB: bad release lock type\n");
          break;
      case VL_RERELEASE:
          sprintf(buffer, "VLDB: status report: last release was aborted\n");
          break;
      case VL_BADSERVERFLAG:
          sprintf(buffer, "VLDB: invalid replication site server flag\n");
          break;
      case VL_PERM:
          sprintf(buffer, "VLDB: no permission access for call\n");
          break;
      case VOLSERREAD_DUMPERROR:
          sprintf(buffer, "VOLSER:  Problems encountered in reading the dump file !\n");
          break;
      case VOLSERDUMPERROR:
          sprintf(buffer, "VOLSER: Problems encountered in doing the dump !\n");
          break;
      case VOLSERATTACH_ERROR:
          sprintf(buffer, "VOLSER: Could not attach the volume\n");
          break;
      case VOLSERDETACH_ERROR:
          sprintf(buffer, "VOLSER: Could not detach the volume\n");
          break;
      case VOLSERILLEGAL_PARTITION:
          sprintf(buffer, "VOLSER: encountered illegal partition number\n");
          break;
      case VOLSERBAD_ACCESS:
          sprintf(buffer, "VOLSER: permission denied, not a super user\n");
          break;
      case VOLSERVLDB_ERROR:
          sprintf(buffer, "VOLSER: error detected in the VLDB\n");
          break;
      case VOLSERBADNAME:
          sprintf(buffer, "VOLSER: error in volume name\n");
          break;
      case VOLSERVOLMOVED:
          sprintf(buffer, "VOLSER: volume has moved\n");
          break;
      case VOLSERBADOP:
          sprintf(buffer, "VOLSER: illegal operation\n");
          break;
      case VOLSERBADRELEASE:
          sprintf(buffer, "VOLSER: release could not be completed\n");
          break;
      case VOLSERVOLBUSY:
          sprintf(buffer, "VOLSER: volume is busy\n");
          break;
      case VOLSERNO_MEMORY:
          sprintf(buffer, "VOLSER: volume server is out of memory\n");
          break;
      case VOLSERNOVOL:
          sprintf(buffer,
                  "VOLSER: no such volume - location specified incorrectly or volume does not exist\n");
          break;
      case VOLSERMULTIRWVOL:
          sprintf(buffer,
                  "VOLSER: multiple RW volumes with same ID, one of which should be deleted\n");
          break;
      case VOLSERFAILEDOP:
          sprintf(buffer, "VOLSER: not all entries were successfully processed\n");
          break;
      default:
          sprintf(buffer, "Unknown ERROR code\n");
          break;
    }
    return 0;
}

#ifdef AFS_PTHREAD_ENV
void IOMGR_Sleep (seconds)
  int seconds;
{
    double i,j;

    croak("DEBUG: IOMGR_Sleep not available ...\nPlease inform the author...");
    j = 0.0;
    i = 1.0/j;
}

void clock_UpdateTime ()
{
    double i,j;

    croak("DEBUG: clock_UpdateTime not available ...\nPlease inform the author..  .");
    j = 0.0;
    i = 1.0/j;
}

int clock_haveCurrentTime ()
{
    double i,j;

    croak("DEBUG: clock_haveCurrentTime not available...\nPlease inform the auth or...");
    j = 0.0;
    i = 1.0/j;
    return 1;
}
#endif /* AFS_PTHREAD_ENV*/

static int32 not_here(s)
    char *s;
{
    croak("%s not implemented on this architecture or under this AFS version", s);
    return -1;
}

int PrintDiagnostics(astring, acode)
    char *astring;
    afs_int32 acode;
{
    if (acode == EACCES) {
        fprintf(STDERR, "You are not authorized to perform the 'vos %s' command (%d)\n",
                astring, acode);
    }
    else {
        fprintf(STDERR, "Error in vos %s command.\n", astring);
        PrintError("", acode);
    }
    return 0;
}
/* end of error handling macros */


/* general helper functions */

static struct afsconf_dir *cdir = NULL;
static char *config_dir = NULL;

static int32 internal_GetConfigDir()
{
    if (cdir == NULL) {

        if (config_dir == NULL) {
#if defined(AFS_3_4)
            config_dir = (char *) safemalloc(strlen(AFSCONF_CLIENTNAME) + 1);
            strcpy(config_dir, AFSCONF_CLIENTNAME);
#else
            config_dir = (char *) safemalloc(strlen(AFSDIR_CLIENT_ETC_DIRPATH) + 1);
            strcpy(config_dir, AFSDIR_CLIENT_ETC_DIRPATH);
#endif
        }

        cdir = afsconf_Open(config_dir);
        if (!cdir) {
            char buffer[256];
            sprintf(buffer, "GetConfigDir: Can't open configuration directory (%s)", config_dir);
            PSETCODE(buffer);
            return errno;
        }
    }
    return 0;
}

static int32 internal_GetServerConfigDir()
{
    if (cdir == NULL) {

        if (config_dir == NULL) {
#if defined(AFS_3_4)
            config_dir = (char *) safemalloc(strlen(AFSCONF_SERVERNAME) + 1);
            strcpy(config_dir, AFSCONF_SERVERNAME);
#else
            config_dir = (char *) safemalloc(strlen(AFSDIR_SERVER_ETC_DIRPATH) + 1);
            strcpy(config_dir, AFSDIR_SERVER_ETC_DIRPATH);
#endif
        }

        cdir = afsconf_Open(config_dir);
        if (!cdir) {
            char buffer[256];
            sprintf(buffer, "GetServerConfigDir: Can't open configuration directory (%s)", config_dir);
            PSETCODE(buffer);
            return errno;
        }
    }
    return 0;
}

static int32 internal_GetCellInfo(cell, service, info)
    char *cell;
    char *service;
    struct afsconf_cell *info;
{
    int32 code;

    code = internal_GetConfigDir();
    if (code == 0) {
        code = afsconf_GetCellInfo(cdir, cell, service, info);
        if (code) {
            char buffer[256];
            sprintf(buffer, "GetCellInfo: ");
            KSETCODE(code, buffer);
        }
    }
    return code;
}

static char *internal_GetLocalCell(code)
    int32 *code;
{

    static char localcell[MAXCELLCHARS] = "";

    if (localcell[0]) {
        *code = 0;
    }
    else {
        *code = internal_GetConfigDir();
        if (*code)
            return NULL;
        *code = afsconf_GetLocalCell(cdir, localcell, sizeof(localcell));
        if (*code) {
            char buffer[256];
            sprintf(buffer, "GetLocalCell: Can't determine local cell name");
            PSETCODE(buffer);
            return NULL;
        }
    }
    return localcell;
}

static void stolower(s)
    char *s;
{
    while (*s) {
        if (isupper(*s))
            *s = tolower(*s);
        s++;
    }
}

/* return 1 if name is all '-' or digits. Used to remove orphan
     entries from ACls */
static int32 name_is_numeric(name)
    char *name;
{

    if (*name != '-' && !isdigit(*name))
        return 0;
    else
        name++;

    while (*name) {
        if (!isdigit(*name))
            return 0;
        name++;
    }

    return 1;                   /* name is (most likely numeric) */
}
/* end of general helper functions */


/* helper functions for PTS class: */

static struct ubik_client *internal_pts_new(code, sec, cell)
    int32 *code;
    int32 sec;
    char *cell;
{
    struct rx_connection *serverconns[MAXSERVERS];
    struct rx_securityClass *sc = NULL;
    struct ktc_token token;
    struct afsconf_cell info;
/*  tpf nog 03/29/99
 *  caused by changes in ubikclient.c,v 2.20 1996/12/10
 *            and     in ubikclient.c,v 2.24 1997/01/21
 * struct ubik_client *client;                             */
    struct ubik_client *client = 0;
    struct ktc_principal prin;
    int32 i;


    *code = internal_GetConfigDir();
    if (*code == 0)
        *code = internal_GetCellInfo(cell, "afsprot", &info);

    if (*code)
        return NULL;

    if (!rx_initialized) {
        /* printf("pts DEBUG rx_Init\n"); */
        *code = rx_Init(0);
        if (*code) {
            char buffer[256];
            sprintf(buffer, "AFS::PTS: could not initialize Rx (%d)\n", *code);
            BSETCODE(code, buffer);
            return NULL;
        }
        rx_initialized = 1;
    }

    if (sec > 0) {
        strcpy(prin.cell, info.name);
        prin.instance[0] = 0;
        strcpy(prin.name, "afs");
        *code = ktc_GetToken(&prin, &token, sizeof(token), NULL);
        if (*code) {
            if (sec == 2) {
                char buffer[256];
                sprintf(buffer, "AFS::PTS: failed to get token for service AFS (%d)\n", *code);
                BSETCODE(code, buffer);
                return NULL;    /* we want security or nothing */
            }
            sec = 0;
        }
        else {
            sc = (struct rx_securityClass *) rxkad_NewClientSecurityObject
                (rxkad_clear, &token.sessionKey, token.kvno,
                 token.ticketLen, token.ticket);
        }
    }

    if (sec == 0)
        sc = (struct rx_securityClass *) rxnull_NewClientSecurityObject();
    else
        sec = 2;

    bzero(serverconns, sizeof(serverconns));
    for (i = 0; i < info.numServers; i++) {
        serverconns[i] = rx_NewConnection(info.hostAddr[i].sin_addr.s_addr,
                                          info.hostAddr[i].sin_port, PRSRV, sc, sec);
    }

    *code = ubik_ClientInit(serverconns, &client);
    if (*code) {
        char buffer[256];
        sprintf(buffer, "AFS::PTS: Can't initialize ubik connection to Protection server (%d)\n", *code);
        BSETCODE(code, buffer);
        return NULL;
    }
    *code = rxs_Release(sc);
    return client;
}

static int32 internal_pr_name(server, id, name)
    int32 id;
    struct ubik_client *server;
    char *name;
{
    namelist lnames;
    idlist lids;
    register int32 code;

    lids.idlist_len = 1;
    lids.idlist_val = (int32 *) safemalloc(sizeof(int32));
    *lids.idlist_val = id;
    lnames.namelist_len = 0;
    lnames.namelist_val = NULL;
    code = ubik_Call(PR_IDToName, server, 0, &lids, &lnames);
    if (lnames.namelist_val) {
        strncpy(name, (char *) lnames.namelist_val, PR_MAXNAMELEN);
        if (lnames.namelist_val)
            free(lnames.namelist_val);
    }
    if (lids.idlist_val)
        safefree(lids.idlist_val);
    return code;
}

static int32 internal_pr_id(server, name, id, anon)
    struct ubik_client *server;
    char *name;
    int32 *id;
    int32 anon;
{
    namelist lnames;
    idlist lids;
    int32 code;

    if (convert_numeric_names && name_is_numeric(name)) {
        *id = atoi(name);
        return 0;
    }

    lids.idlist_len = 0;
    lids.idlist_val = 0;
    lnames.namelist_len = 1;
    lnames.namelist_val = (prname *) safemalloc(PR_MAXNAMELEN);
    stolower(name);
    strncpy((char *) lnames.namelist_val, name, PR_MAXNAMELEN);
    code = ubik_Call(PR_NameToID, server, 0, &lnames, &lids);
    if (lids.idlist_val) {
        *id = *lids.idlist_val;
        if (lids.idlist_val)
            free(lids.idlist_val);
    }
    if (lnames.namelist_val)
        safefree(lnames.namelist_val);

    if (code == 0 && anon == 0 && *id == ANONYMOUSID) {
        code = PRNOENT;
    }

    return code;
}

static int32 parse_pts_setfields(access, flags)
    char *access;
    int32 *flags;
{
    *flags = 0;
    if (strlen(access) != 5)
        return PRBADARG;

    if (access[0] == 'S')
        *flags |= 0x80;
    else if (access[0] == 's')
        *flags |= 0x40;
    else if (access[0] != '-')
        return PRBADARG;

    if (access[1] == 'O')
        *flags |= 0x20;
    else if (access[1] != '-')
        return PRBADARG;

    if (access[2] == 'M')
        *flags |= 0x10;
    else if (access[2] == 'm')
        *flags |= 0x08;
    else if (access[2] != '-')
        return PRBADARG;

    if (access[3] == 'A')
        *flags |= 0x04;
    else if (access[3] == 'a')
        *flags |= 0x02;
    else if (access[3] != '-')
        return PRBADARG;

    if (access[4] == 'r')
        *flags |= 0x01;
    else if (access[4] != '-')
        return PRBADARG;

    return 0;
}

static char *parse_flags_ptsaccess(flags)
    int32 flags;
{
    static char buff[6];
    strcpy(buff, "-----");
    if (flags & 0x01)
        buff[4] = 'r';
    if (flags & 0x02)
        buff[3] = 'a';
    if (flags & 0x04)
        buff[3] = 'A';
    if (flags & 0x08)
        buff[2] = 'm';
    if (flags & 0x10)
        buff[2] = 'M';
    if (flags & 0x20)
        buff[1] = 'O';
    if (flags & 0x40)
        buff[0] = 's';
    if (flags & 0x80)
        buff[0] = 'S';
    return buff;
}

static int parse_prcheckentry(server, stats, entry, lookupids, convertflags)
    struct ubik_client *server;
    HV *stats;
    struct prcheckentry *entry;
    int32 lookupids;
    int convertflags;
{
    int32 code;
    char name[PR_MAXNAMELEN];

    safe_hv_store(stats, "id", 2, newSViv(entry->id), 0);
    safe_hv_store(stats, "name", 4, newSVpv(entry->name, strlen(entry->name)), 0);
    if (convertflags) {
        safe_hv_store(stats, "flags", 5, newSVpv(parse_flags_ptsaccess(entry->flags), 5), 0);
    }
    else {
        safe_hv_store(stats, "flags", 5, newSViv(entry->flags), 0);
    }
    if (lookupids) {
        code = internal_pr_name(server, entry->owner, name);
        if (code)
            safe_hv_store(stats, "owner", 5, newSViv(entry->owner), 0);
        else
            safe_hv_store(stats, "owner", 5, newSVpv(name, strlen(name)), 0);
        code = internal_pr_name(server, entry->creator, name);
        if (code)
            safe_hv_store(stats, "creator", 7, newSViv(entry->creator), 0);
        else
            safe_hv_store(stats, "creator", 7, newSVpv(name, strlen(name)), 0);
    }
    else {
        safe_hv_store(stats, "owner", 5, newSViv(entry->owner), 0);
        safe_hv_store(stats, "creator", 7, newSViv(entry->creator), 0);
    }
    safe_hv_store(stats, "ngroups", 7, newSViv(entry->ngroups), 0);
/*  safe_hv_store(stats, "nusers",6, newSViv(entry->nusers),0);*/
    safe_hv_store(stats, "count", 5, newSViv(entry->count), 0);
/*
  safe_hv_store(stats, "reserved0",9, newSViv(entry->reserved[0]),0);
  safe_hv_store(stats, "reserved1",9, newSViv(entry->reserved[1]),0);
  safe_hv_store(stats, "reserved2",9, newSViv(entry->reserved[2]),0);
  safe_hv_store(stats, "reserved3",9, newSViv(entry->reserved[3]),0);
  safe_hv_store(stats, "reserved4",9, newSViv(entry->reserved[4]),0);
*/
    return 1;
}

static int parse_prdebugentry(server, stats, entry, lookupids, convertflags)
    struct ubik_client *server;
    HV *stats;
    struct prdebugentry *entry;
    int32 lookupids;
    int convertflags;
{
    int32 code;
    char name[PR_MAXNAMELEN];
    char buff[128];
    int i;

    safe_hv_store(stats, "id", 2, newSViv(entry->id), 0);
    safe_hv_store(stats, "name", 4, newSVpv(entry->name, strlen(entry->name)), 0);

    if (convertflags) {
        safe_hv_store(stats, "flags", 5, newSVpv(parse_flags_ptsaccess(entry->flags), 5), 0);
    }
    else {
        safe_hv_store(stats, "flags", 5, newSViv(entry->flags), 0);
    }

    if (lookupids) {
        code = internal_pr_name(server, entry->owner, name);
        if (code)
            safe_hv_store(stats, "owner", 5, newSViv(entry->owner), 0);
        else
            safe_hv_store(stats, "owner", 5, newSVpv(name, strlen(name)), 0);

        code = internal_pr_name(server, entry->creator, name);
        if (code)
            safe_hv_store(stats, "creator", 7, newSViv(entry->creator), 0);
        else
            safe_hv_store(stats, "creator", 7, newSVpv(name, strlen(name)), 0);

        for (i = 0; i < 10; i++) {
            sprintf(buff, "entries%d", i);
            code = internal_pr_name(server, entry->entries[i], name);
            if (code)
                safe_hv_store(stats, buff, strlen(buff), newSViv(entry->entries[i]), 0);
            else
                safe_hv_store(stats, buff, strlen(buff), newSVpv(name, strlen(name)), 0);

        }

    }
    else {
        safe_hv_store(stats, "owner", 5, newSViv(entry->owner), 0);
        safe_hv_store(stats, "creator", 7, newSViv(entry->creator), 0);
        for (i = 0; i < 10; i++) {
            sprintf(buff, "entries%d", i);
            safe_hv_store(stats, buff, strlen(buff), newSViv(entry->entries[i]), 0);
        }

    }
    safe_hv_store(stats, "cellid", 6, newSViv(entry->cellid), 0);
    safe_hv_store(stats, "next", 4, newSViv(entry->next), 0);
    safe_hv_store(stats, "nextID", 6, newSViv(entry->nextID), 0);
    safe_hv_store(stats, "nextname", 8, newSViv(entry->nextname), 0);
    safe_hv_store(stats, "ngroups", 7, newSViv(entry->ngroups), 0);
    safe_hv_store(stats, "nusers", 6, newSViv(entry->nusers), 0);
    safe_hv_store(stats, "count", 5, newSViv(entry->count), 0);
    safe_hv_store(stats, "instance", 8, newSViv(entry->instance), 0);
    safe_hv_store(stats, "owned", 5, newSViv(entry->owned), 0);
    safe_hv_store(stats, "nextOwned", 9, newSViv(entry->nextOwned), 0);
    safe_hv_store(stats, "parent", 6, newSViv(entry->parent), 0);
    safe_hv_store(stats, "sibling", 7, newSViv(entry->sibling), 0);
    safe_hv_store(stats, "child", 5, newSViv(entry->child), 0);
    safe_hv_store(stats, "reserved0", 9, newSViv(entry->reserved[0]), 0);
    safe_hv_store(stats, "reserved1", 9, newSViv(entry->reserved[1]), 0);
    safe_hv_store(stats, "reserved2", 9, newSViv(entry->reserved[2]), 0);
    safe_hv_store(stats, "reserved3", 9, newSViv(entry->reserved[3]), 0);
    safe_hv_store(stats, "reserved4", 9, newSViv(entry->reserved[4]), 0);

    return 1;
}

static int32 check_name_for_id(name, id)
    char *name;
    int32 id;
{
    char buff[32];
    sprintf(buff, "%d", id);
    return strcmp(buff, name) == 0;
}
/* end of helper functions for PTS class: */


/* helper functions for VOS && VLDB class: */
/* copy taken from <src/util/regex.c> OpenAFS-1.4.14.1 */
/*
 * constants for re's
 */
#define	CBRA	1
#define	CCHR	2
#define	CDOT	4
#define	CCL	6
#define	NCCL	8
#define	CDOL	10
#define	CEOF	11
#define	CKET	12
#define	CBACK	18

#define	CSTAR	01

#define	ESIZE	512
#define	NBRA	9

static char expbuf[ESIZE], *braslist[NBRA], *braelist[NBRA];
static char circf;

/* forward defs
*/

static int advance(register char *lp, register char *ep);
static int backref(register int i, register char *lp);
static int cclass(register char *set, register char c, int af);

/*
 * compile the regular expression argument into a dfa
 */
char *
re_comp(register char *sp)
{
    register int c;
    register char *ep = expbuf;
    int cclcnt, numbra = 0;
    char *lastep = 0;
    char bracket[NBRA];
    char *bracketp = &bracket[0];
    static char *retoolong = "Regular expression too long";

#define	comperr(msg) {expbuf[0] = 0; numbra = 0; return(msg); }

    if (sp == 0 || *sp == '\0') {
	if (*ep == 0)
	    return ("No previous regular expression");
	return (0);
    }
    if (*sp == '^') {
	circf = 1;
	sp++;
    } else
	circf = 0;
    for (;;) {
	if (ep >= &expbuf[ESIZE - 10 /* fudge factor */])
	    comperr(retoolong);
	if ((c = *sp++) == '\0') {
	    if (bracketp != bracket)
		comperr("unmatched \\(");
	    *ep++ = CEOF;
	    *ep++ = 0;
	    return (0);
	}
	if (c != '*')
	    lastep = ep;
	switch (c) {

	case '.':
	    *ep++ = CDOT;
	    continue;

	case '*':
	    if (lastep == 0 || *lastep == CBRA || *lastep == CKET)
		goto defchar;
	    *lastep |= CSTAR;
	    continue;

	case '$':
	    if (*sp != '\0')
		goto defchar;
	    *ep++ = CDOL;
	    continue;

	case '[':
	    *ep++ = CCL;
	    *ep++ = 0;
	    cclcnt = 1;
	    if ((c = *sp++) == '^') {
		c = *sp++;
		ep[-2] = NCCL;
	    }
	    do {
		if (c == '\0')
		    comperr("missing ]");
		if (c == '-' && ep[-1] != 0) {
		    if ((c = *sp++) == ']') {
			*ep++ = '-';
			cclcnt++;
			break;
		    }
		    while (ep[-1] < c) {
			*ep = ep[-1] + 1;
			ep++;
			cclcnt++;
			if (ep >= &expbuf[ESIZE - 10 /* fudge factor */])
			    comperr(retoolong);
		    }
		}
		*ep++ = c;
		cclcnt++;
		if (ep >= &expbuf[ESIZE - 10 /* fudge factor */])
		    comperr(retoolong);
	    } while ((c = *sp++) != ']');
	    lastep[1] = cclcnt;
	    continue;

	case '\\':
	    if ((c = *sp++) == '(') {
		if (numbra >= NBRA)
		    comperr("too many \\(\\) pairs");
		*bracketp++ = numbra;
		*ep++ = CBRA;
		*ep++ = numbra++;
		continue;
	    }
	    if (c == ')') {
		if (bracketp <= bracket)
		    comperr("unmatched \\)");
		*ep++ = CKET;
		*ep++ = *--bracketp;
		continue;
	    }
	    if (c >= '1' && c < ('1' + NBRA)) {
		*ep++ = CBACK;
		*ep++ = c - '1';
		continue;
	    }
	    *ep++ = CCHR;
	    *ep++ = c;
	    continue;

	  defchar:
	default:
	    *ep++ = CCHR;
	    *ep++ = c;
	}
    }
}

/* 
 * match the argument string against the compiled re
 */
int
re_exec(register char *p1)
{
    register char *p2 = expbuf;
    register int c;
    int rv;

    for (c = 0; c < NBRA; c++) {
	braslist[c] = 0;
	braelist[c] = 0;
    }
    if (circf)
	return ((advance(p1, p2)));
    /*
     * fast check for first character
     */
    if (*p2 == CCHR) {
	c = p2[1];
	do {
	    if (*p1 != c)
		continue;
	    if ((rv = advance(p1, p2)))
		return (rv);
	} while (*p1++);
	return (0);
    }
    /*
     * regular algorithm
     */
    do
	if ((rv = advance(p1, p2)))
	    return (rv);
    while (*p1++);
    return (0);
}

/* 
 * try to match the next thing in the dfa
 */
static int
advance(register char *lp, register char *ep)
{
    register char *curlp;
    int ct, i;
    int rv;

    for (;;)
	switch (*ep++) {

	case CCHR:
	    if (*ep++ == *lp++)
		continue;
	    return (0);

	case CDOT:
	    if (*lp++)
		continue;
	    return (0);

	case CDOL:
	    if (*lp == '\0')
		continue;
	    return (0);

	case CEOF:
	    return (1);

	case CCL:
	    if (cclass(ep, *lp++, 1)) {
		ep += *ep;
		continue;
	    }
	    return (0);

	case NCCL:
	    if (cclass(ep, *lp++, 0)) {
		ep += *ep;
		continue;
	    }
	    return (0);

	case CBRA:
	    braslist[*ep++] = lp;
	    continue;

	case CKET:
	    braelist[*ep++] = lp;
	    continue;

	case CBACK:
	    if (braelist[i = *ep++] == 0)
		return (-1);
	    if (backref(i, lp)) {
		lp += braelist[i] - braslist[i];
		continue;
	    }
	    return (0);

	case CBACK | CSTAR:
	    if (braelist[i = *ep++] == 0)
		return (-1);
	    curlp = lp;
	    ct = braelist[i] - braslist[i];
	    while (backref(i, lp))
		lp += ct;
	    while (lp >= curlp) {
		if (rv = advance(lp, ep))
		    return (rv);
		lp -= ct;
	    }
	    continue;

	case CDOT | CSTAR:
	    curlp = lp;
	    while (*lp++);
	    goto star;

	case CCHR | CSTAR:
	    curlp = lp;
	    while (*lp++ == *ep);
	    ep++;
	    goto star;

	case CCL | CSTAR:
	case NCCL | CSTAR:
	    curlp = lp;
	    while (cclass(ep, *lp++, ep[-1] == (CCL | CSTAR)));
	    ep += *ep;
	    goto star;

	  star:
	    do {
		lp--;
		if (rv = advance(lp, ep))
		    return (rv);
	    } while (lp > curlp);
	    return (0);

	default:
	    return (-1);
	}
}

static int
backref(register int i, register char *lp)
{
    register char *bp;

    bp = braslist[i];
    while (*bp++ == *lp++)
	if (bp >= braelist[i])
	    return (1);
    return (0);
}

static int
cclass(register char *set, register char c, int af)
{
    register int n;

    if (c == 0)
	return (0);
    n = *set++;
    while (--n)
	if (*set++ == c)
	    return (af);
    return (!af);
}

/* copy taken from <src/ubik/uinit.c> OpenAFS-1.4.14.1 */
static afs_int32
internal_ugen_ClientInit(int noAuthFlag, const char *confDir, char *cellName, afs_int32 sauth,
	       struct ubik_client **uclientp, int (*secproc) (),
	       char *funcName, afs_int32 gen_rxkad_level,
	       afs_int32 maxservers, char *serviceid, afs_int32 deadtime,
	       afs_uint32 server, afs_uint32 port, afs_int32 usrvid)
{
    afs_int32 code, scIndex, i;
    struct afsconf_cell info;
    struct afsconf_dir *tdir;
    struct ktc_principal sname;
    struct ktc_token ttoken;
    struct rx_securityClass *sc;
    /* This must change if VLDB_MAXSERVERS becomes larger than MAXSERVERS */
    static struct rx_connection *serverconns[MAXSERVERS];
    char cellstr[64];

    if (!rx_initialized) {
        /* printf("ugen DEBUG rx_Init\n"); */
        code = rx_Init(0);
        if (code) {
            char buffer[256];
            sprintf(buffer, "%s: could not initialize rx.\n", funcName);
            VSETCODE(code, buffer);
            return (code);
        }
        rx_initialized = 1;
    }
    rx_SetRxDeadTime(deadtime);

    if (sauth) {		/* -localauth */
	tdir = afsconf_Open(AFSDIR_SERVER_ETC_DIRPATH);
	if (!tdir) {
            char buffer[256];
            sprintf(buffer,
		    "%s: Could not process files in configuration directory (%s).\n",
		    funcName, AFSDIR_SERVER_ETC_DIRPATH);
	    code = -1;
            VSETCODE(code, buffer);
            return (code);
	}
	code = afsconf_ClientAuth(tdir, &sc, &scIndex);	/* sets sc,scIndex */
	if (code) {
	    afsconf_Close(tdir);
            char buffer[256];
            sprintf(buffer,
		    "%s: Could not get security object for -localAuth\n",
		    funcName);
            VSETCODE(code, buffer);
            return (code);
	}
	code = afsconf_GetCellInfo(tdir, tdir->cellName, serviceid, &info);
	if (code) {
	    afsconf_Close(tdir);
            char buffer[256];
            sprintf(buffer,
		    "%s: can't find cell %s's hosts in %s/%s\n",
		    funcName, cellName, AFSDIR_SERVER_ETC_DIRPATH,
		    AFSDIR_CELLSERVDB_FILE);
            VSETCODE(code, buffer);
            return (code);
	}
    } else {			/* not -localauth */
	tdir = afsconf_Open(confDir);
	if (!tdir) {
            char buffer[256];
            sprintf(buffer,
		    "%s: Could not process files in configuration directory (%s).\n",
		    funcName, confDir);
	    code = -1;
            VSETCODE(code, buffer);
            return (code);
	}

	if (!cellName) {
	    code = afsconf_GetLocalCell(tdir, cellstr, sizeof(cellstr));
	    if (code) {
                char buffer[256];
                sprintf(buffer,
			"%s: can't get local cellname, check %s/%s\n",
			funcName, confDir, AFSDIR_THISCELL_FILE);
                VSETCODE(code, buffer);
                return (code);
	    }
	    cellName = cellstr;
	}

	code = afsconf_GetCellInfo(tdir, cellName, serviceid, &info);
	if (code) {
            char buffer[256];
            sprintf(buffer,
		    "%s: can't find cell %s's hosts in %s/%s\n",
		    funcName, cellName, confDir, AFSDIR_CELLSERVDB_FILE);
            VSETCODE(code, buffer);
            return (code);
	}
	if (noAuthFlag)		/* -noauth */
	    scIndex = 0;
	else {			/* not -noauth */
	    strcpy(sname.cell, info.name);
	    sname.instance[0] = 0;
	    strcpy(sname.name, "afs");
	    code = ktc_GetToken(&sname, &ttoken, sizeof(ttoken), NULL);
	    if (code) {		/* did not get ticket */
		fprintf(stderr,
			"%s: Could not get afs tokens, running unauthenticated.\n",
			funcName);
		scIndex = 0;
	    } else {		/* got a ticket */
		scIndex = 2;
		if ((ttoken.kvno < 0) || (ttoken.kvno > 256)) {
		    fprintf(stderr,
			    "%s: funny kvno (%d) in ticket, proceeding\n",
			    funcName, ttoken.kvno);
		}
	    }
	}

        char buffer[256];
	switch (scIndex) {
	case 0:
	    sc = rxnull_NewClientSecurityObject();
	    break;
	case 2:
	    sc = rxkad_NewClientSecurityObject(gen_rxkad_level,
					       &ttoken.sessionKey,
					       ttoken.kvno, ttoken.ticketLen,
					       ttoken.ticket);
	    break;
	default:
            sprintf(buffer, "%s: unsupported security index %d\n",
		    funcName, scIndex);
	    code = 1;
            VSETCODE(code, buffer);
            return (code);
	    break;
	}
    }

    afsconf_Close(tdir);

    if (secproc)	/* tell UV module about default authentication */
	(*secproc) (sc, scIndex);
    if (server) {
	serverconns[0] = rx_NewConnection(server, port,
					  usrvid, sc, scIndex);
    } else {
	if (info.numServers > maxservers) {
            char buffer[256];
            sprintf(buffer,
		    "%s: info.numServers=%d (> maxservers=%d)\n",
		    funcName, info.numServers, maxservers);
	    code = 1;
            VSETCODE(code, buffer);
            return (code);
	}
	for (i = 0; i < info.numServers; i++) {
	    serverconns[i] =
		rx_NewConnection(info.hostAddr[i].sin_addr.s_addr,
				 info.hostAddr[i].sin_port, usrvid,
				 sc, scIndex);
	}
    }
    /* Are we just setting up connections, or is this really ubik stuff? */
    if (uclientp) {
	*uclientp = 0;
	code = ubik_ClientInit(serverconns, uclientp);
	if (code) {
            char buffer[256];
            sprintf(buffer, "%s: ubik client init failed.\n", funcName);
            VSETCODE(code, buffer);
            return (code);
	}
    }
    return 0;
}

/* copy taken from <src/volser/vsutils.c> OpenAFS-1.4.14.1 */
static afs_int32
internal_vsu_ClientInit(int noAuthFlag, const char *confDir, char *cellName, afs_int32 sauth,
	       struct ubik_client **uclientp, int (*secproc)())
{
    return internal_ugen_ClientInit(noAuthFlag, confDir, cellName, sauth, uclientp,
			   secproc, "internal_vsu_ClientInit", vsu_rxkad_level,
			   VLDB_MAXSERVERS, AFSCONF_VLDBSERVICE, 90,
			   0, 0, USER_SERVICE_ID);
}
/* end of helper functions for VOS && VLDB class */


/* helper functions for VOS class: */

#ifndef OpenAFS
void vsu_SetCrypt(cryptflag)
    int cryptflag;
{
    if (cryptflag) {
        vsu_rxkad_level = rxkad_crypt;
    }
    else {
        vsu_rxkad_level = rxkad_auth;
    }
}
#endif

int32 GetVolumeInfo(volid, server, part, voltype, rentry)
    afs_int32 volid, *server, *part, *voltype;
    register struct nvldbentry *rentry;
{
    afs_int32 vcode;
    int i, index = -1;

    vcode = VLDB_GetEntryByID(volid, -1, rentry);
    if (vcode) {
        char buffer[256];
        sprintf(buffer, "Could not fetch the entry for volume %u from VLDB \n", volid);
        VSETCODE(vcode, buffer);
        return (vcode);
    }
    MapHostToNetwork(rentry);
    if (volid == rentry->volumeId[ROVOL]) {
        *voltype = ROVOL;
        for (i = 0; i < rentry->nServers; i++) {
            if ((index == -1) && (rentry->serverFlags[i] & ITSROVOL) &&
                !(rentry->serverFlags[i] & RO_DONTUSE))
                index = i;
        }
        if (index == -1) {
            char buffer[256];
            sprintf(buffer, "RO volume is not found in VLDB entry for volume %u\n",
                    volid);
            VSETCODE(-1, buffer);
            return -1;
        }

        *server = rentry->serverNumber[index];
        *part = rentry->serverPartition[index];
        return 0;
    }

    index = Lp_GetRwIndex(rentry);
    if (index == -1) {
        char buffer[256];
        sprintf(buffer, "RW Volume is not found in VLDB entry for volume %u\n", volid);
        VSETCODE(-1, buffer);
        return -1;
    }
    if (volid == rentry->volumeId[RWVOL]) {
        *voltype = RWVOL;
        *server = rentry->serverNumber[index];
        *part = rentry->serverPartition[index];
        return 0;
    }
    if (volid == rentry->volumeId[BACKVOL]) {
        *voltype = BACKVOL;
        *server = rentry->serverNumber[index];
        *part = rentry->serverPartition[index];
        return 0;
    }
    /* should never reach this ? */
    printf("FIXME: reached end of control at %d\n",__LINE__);
    return -1;
}

static int VolNameOK(name)
    char *name;
{
    int total;


    total = strlen(name);
    if (!strcmp(&name[total - 9], ".readonly")) {
        return 0;
    }
    else if (!strcmp(&name[total - 7], ".backup")) {
        return 0;
    }
    else {
        return 1;
    }
}

static int IsNumeric(name)
    char *name;
{
    int result, len, i;
    char *ptr;

    result = 1;
    ptr = name;
    len = strlen(name);
    for (i = 0; i < len; i++) {
        if (*ptr < '0' || *ptr > '9') {
            result = 0;
            break;
        }
        ptr++;

    }
    return result;

}

int IsPartValid(partId, server, code)
    afs_int32 server, partId, *code;
{
    struct partList dummyPartList;
    int i, success, cnt;


    success = 0;
    *code = 0;

    *code = UV_ListPartitions(server, &dummyPartList, &cnt);
    if (*code)
        return success;
    for (i = 0; i < cnt; i++) {
        if (dummyPartList.partFlags[i] & PARTVALID)
            if (dummyPartList.partId[i] == partId)
                success = 1;
    }
    return success;
}

afs_int32 GetServer(aname)
    char *aname;
{
    register struct hostent *th;
    afs_int32 addr;
    int b1, b2, b3, b4;
    register afs_int32 code;
    char hostname[MAXHOSTCHARS];

    code = sscanf(aname, "%d.%d.%d.%d", &b1, &b2, &b3, &b4);
    if (code == 4) {
        addr = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
        addr = ntohl(addr);     /* convert to host order */
    }
    else {
        th = gethostbyname(aname);
        if (!th)
            return 0;
        /* memcpy(&addr, th->h_addr, sizeof(addr)); */
        Copy(th->h_addr, &addr, th->h_length, char);
    }

    if (addr == htonl(0x7f000001)) {    /* local host */
        code = gethostname(hostname, MAXHOSTCHARS);
        if (code)
            return 0;
        th = gethostbyname(hostname);   /* returns host byte order */
        if (!th)
            return 0;
        /* memcpy(&addr, th->h_addr, sizeof(addr)); */
        Copy(th->h_addr, &addr, th->h_length, char);
    }

    return (addr);
}

 /*sends the contents of file associated with <fd> and <blksize>  to Rx Stream 
    * associated  with <call> */
int SendFile(ufd, call, blksize)
    usd_handle_t ufd;
    register struct rx_call *call;
    long blksize;
{
    char *buffer = (char *) 0;
    afs_int32 error = 0;
    int done = 0;
    afs_uint32 nbytes;

    buffer = (char *) safemalloc(blksize);
    if (!buffer) {
        char buf[256];
        sprintf(buf, "malloc failed\n");
        VSETCODE(-1, buf);
        return -1;
    }

    while (!error && !done) {
#ifndef AFS_NT40_ENV            /* NT csn't select on non-socket fd's */
        fd_set in;
        FD_ZERO(&in);
        FD_SET((long) (ufd->handle), &in);
        /* don't timeout if read blocks */
#ifdef AFS_PTHREAD_ENV
        select(((long) (ufd->handle)) + 1, &in, 0, 0, 0);
#else
        IOMGR_Select(((long) (ufd->handle)) + 1, &in, 0, 0, 0); 
#endif /* AFS_PTHREAD_ENV*/
#endif
        error = USD_READ(ufd, buffer, blksize, &nbytes);
        if (error) {
            char buf[256];
            sprintf(buf, "File system read failed\n");
            VSETCODE(error, buf);
            break;
        }
        if (nbytes == 0) {
            done = 1;
            break;
        }
        if (rx_Write(call, buffer, nbytes) != nbytes) {
            error = -1;
            break;
        }
    }
    if (buffer)
        free(buffer);
    return error;
}

/* function invoked by UV_RestoreVolume, reads the data from rx_trx_stream and
 * writes it out to the volume. */
afs_int32 WriteData(call, rock)
    struct rx_call *call;
    char *rock;
{
    char *filename;
    usd_handle_t ufd;
    long blksize;
    afs_int32 error, code;
    int ufdIsOpen = 0;

    error = 0;

    filename = rock;
    if (!filename || !*filename) {
        usd_StandardInput(&ufd);
        blksize = 4096;
        ufdIsOpen = 1;
    }
    else {
        code = usd_Open(filename, USD_OPEN_RDONLY, 0, &ufd);
        if (code == 0) {
            ufdIsOpen = 1;
            code = USD_IOCTL(ufd, USD_IOCTL_GETBLKSIZE, &blksize);
        }
        if (code) {
            char buffer[256];
            sprintf(buffer, "Could not access file '%s'\n", filename);
            error = VOLSERBADOP;
            VSETCODE(error, buffer);
            goto wfail;
        }
    }
    code = SendFile(ufd, call, blksize);
    if (code) {
        error = code;
        goto wfail;
    }
  wfail:
    if (ufdIsOpen) {
        code = USD_CLOSE(ufd);
        if (code) {
            char buffer[256];
            sprintf(buffer, "Could not close dump file %s\n",
                    (filename && *filename) ? filename : "STDOUT");
            VSETCODE(code, buffer);
            if (!error)
                error = code;
        }
    }
    return error;
}

/* Receive data from <call> stream into file associated
 * with <fd> <blksize>
 */
int ReceiveFile(ufd, call, blksize)
    usd_handle_t ufd;
    struct rx_call *call;
    long blksize;
{
    char *buffer = (char *) 0;
    afs_int32 bytesread;
    afs_uint32 bytesleft, w;
    afs_int32 error = 0;

    buffer = (char *) safemalloc(blksize);
    if (!buffer) {
        char buf[256];
        sprintf(buf, "memory allocation failed\n");
        VSETCODE(-1, buf);
        ERROR_EXIT(-1);
    }

    while ((bytesread = rx_Read(call, buffer, blksize)) > 0) {
        for (bytesleft = bytesread; bytesleft; bytesleft -= w) {
#ifndef AFS_NT40_ENV            /* NT csn't select on non-socket fd's */
            fd_set out;
            FD_ZERO(&out);
            FD_SET((long) (ufd->handle), &out);
            /* don't timeout if write blocks */
#ifdef AFS_PTHREAD_ENV
            select(((long) (ufd->handle)) + 1, 0, &out, 0, 0);
#else
            IOMGR_Select(((long) (ufd->handle)) + 1, 0, &out, 0, 0); 
#endif /* AFS_PTHREAD_ENV*/
#endif
            error = USD_WRITE(ufd, &buffer[bytesread - bytesleft], bytesleft, &w);
            if (error) {
                char buf[256];
                sprintf(buf, "File system write failed\n");
                VSETCODE(-1, buf);
                ERROR_EXIT(-1);
            }
        }
    }

  error_exit:
    if (buffer)
        free(buffer);
    return (error);
}

afs_int32 DumpFunction(call, filename)
    struct rx_call *call;
    char *filename;
{
    usd_handle_t ufd;           /* default is to stdout */
    afs_int32 error = 0, code;
    afs_hyper_t size;
    long blksize;
    int ufdIsOpen = 0;

    /* Open the output file */
    if (!filename || !*filename) {
        usd_StandardOutput(&ufd);
        blksize = 4096;
        ufdIsOpen = 1;
    }
    else {
        code = usd_Open(filename, USD_OPEN_CREATE | USD_OPEN_RDWR, 0666, &ufd);
        if (code == 0) {
            ufdIsOpen = 1;
            hzero(size);
            code = USD_IOCTL(ufd, USD_IOCTL_SETSIZE, &size);
        }
        if (code == 0) {
            code = USD_IOCTL(ufd, USD_IOCTL_GETBLKSIZE, &blksize);
        }
        if (code) {
            char buffer[256];
            sprintf(buffer, "Could not create file '%s'\n", filename);
            VSETCODE(VOLSERBADOP, buffer);
            ERROR_EXIT(VOLSERBADOP);
        }
    }

    code = ReceiveFile(ufd, call, blksize);
    if (code)
        ERROR_EXIT(code);

  error_exit:
    /* Close the output file */
    if (ufdIsOpen) {
        code = USD_CLOSE(ufd);
        if (code) {
            char buffer[256];
            sprintf(buffer, "Could not close dump file %s\n",
                    (filename && *filename) ? filename : "STDIN");
            VSETCODE(code, buffer);
            if (!error)
                error = code;
        }
    }

    return (error);
}

struct tqElem {
    afs_int32 volid;
    struct tqElem *next;
};

struct tqHead {
    afs_int32 count;
    struct tqElem *next;
};

static struct tqHead busyHead, notokHead;

static void qInit(ahead)
    struct tqHead *ahead;
{
    Zero(ahead, 1, struct tqHead);
    return;
}

static void qPut(ahead, volid)
    struct tqHead *ahead;
    afs_int32 volid;
{
    struct tqElem *elem;

    elem = (struct tqElem *) safemalloc(sizeof(struct tqElem));
    elem->next = ahead->next;
    elem->volid = volid;
    ahead->next = elem;
    ahead->count++;
    return;
}

/* Kann vielleicht ganz raus ???    */
/* static void qGet(ahead, volid) */
/*     struct tqHead *ahead; */
/*     afs_int32 *volid; */
/* { */
/*     struct tqElem *tmp; */

/*     if (ahead->count <= 0) */
/*         return; */
/*     *volid = ahead->next->volid; */
/*     tmp = ahead->next; */
/*     ahead->next = tmp->next; */
/*     ahead->count--; */
/*     free(tmp); */
/*     return; */
/* } */

static int FileExists(filename)
    char *filename;
{
    usd_handle_t ufd;
    int code;
    afs_hyper_t size;

    code = usd_Open(filename, USD_OPEN_RDONLY, 0, &ufd);
    if (code) {
        return 0;
    }
    code = USD_IOCTL(ufd, USD_IOCTL_GETSIZE, &size);
    USD_CLOSE(ufd);
    if (code) {
        return 0;
    }
    return 1;
}

static void myDisplayFormat(vol, pntr, server, part, totalOK, totalNotOK, totalBusy, fast)
    HV *vol;
    volintInfo *pntr;
    afs_int32 server, part;
    int *totalOK, *totalNotOK, *totalBusy;
    int fast;
{
    char pname[10];
    char hostname[256];

    if (fast) {
        safe_hv_store(vol, "volid", 5, newSViv(pntr->volid), 0);
    }
    else {
        safe_hv_store(vol, "status", 6, newSViv(pntr->status), 0);
        safe_hv_store(vol, "volid", 5, newSViv(pntr->volid), 0);

        if (pntr->status == VOK) {
            safe_hv_store(vol, "name", 4,  newSVpv(pntr->name, strlen((char *) pntr->name)), 0);
            if (pntr->type == 0)
                safe_hv_store(vol, "type", 4, newSVpv("RW", 2), 0);
            if (pntr->type == 1)
                safe_hv_store(vol, "type", 4, newSVpv("RO", 2), 0);
            if (pntr->type == 2)
                safe_hv_store(vol, "type", 4, newSVpv("BK", 2), 0);

            safe_hv_store(vol, "size", 4, newSViv(pntr->size), 0);

            if (pntr->inUse == 1) {
                safe_hv_store(vol, "inUse", 5, newSVpv("On-line", 7), 0);
                *totalOK += 1;
            }
            else {
                safe_hv_store(vol, "inUse", 5, newSVpv("Off-line", 8), 0);
                *totalNotOK += 1;
            }

            MapPartIdIntoName(part, pname);
            strcpy(hostname, (char *) hostutil_GetNameByINet(server));
            safe_hv_store(vol, "server", 6, newSVpv(hostname, strlen((char *) hostname)), 0);
            safe_hv_store(vol, "backupID", 8, newSViv(pntr->backupID), 0);
            safe_hv_store(vol, "parentID", 8, newSViv(pntr->parentID), 0);
            safe_hv_store(vol, "cloneID", 7, newSViv(pntr->cloneID), 0);
            safe_hv_store(vol, "maxquota", 8, newSViv(pntr->maxquota), 0);
            safe_hv_store(vol, "creationDate", 12, newSViv(pntr->creationDate), 0);
#ifdef OpenAFS           /* copy taken from <src/volser/vos.c> OpenAFS-1.2.11 FULL_LISTVOL_SWITCH*/
            safe_hv_store(vol, "copyDate", 8, newSViv(pntr->copyDate), 0);
            if (!pntr->backupDate)
                safe_hv_store(vol, "backupDate", 10, newSVpv("Never", 5), 0);
            else
                safe_hv_store(vol, "backupDate", 10, newSViv(pntr->backupDate), 0);
            if (pntr->accessDate)
                safe_hv_store(vol, "accessDate", 10, newSViv(pntr->accessDate), 0);
#endif
            if (!pntr->updateDate)
                safe_hv_store(vol, "updateDate", 10, newSVpv("Never", 5), 0);
            else
                safe_hv_store(vol, "updateDate", 10, newSViv(pntr->updateDate), 0);

            safe_hv_store(vol, "dayUse", 6, newSViv(pntr->dayUse), 0);

        }
        else if (pntr->status == VBUSY) {
            *totalBusy += 1;
            qPut(&busyHead, pntr->volid);
        }
        else {
            *totalNotOK += 1;
            qPut(&notokHead, pntr->volid);
        }
    }
}

static void myXDisplayFormat(stats, a_xInfoP, a_servID, a_partID, a_totalOKP,
                             a_totalNotOKP, a_totalBusyP)
    HV *stats;
    volintXInfo *a_xInfoP;
    afs_int32 a_servID;
    afs_int32 a_partID;
    int *a_totalOKP;
    int *a_totalNotOKP;
    int *a_totalBusyP;

{                               /*XDisplayFormat */
    char hostname[256];
    char pname[10];

    HV *stat1 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat2 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat3 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat4 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat5 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat6 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat7 = (HV *) sv_2mortal((SV *) newHV());
    HV *stat8 = (HV *) sv_2mortal((SV *) newHV());

    /* Fully-detailed listing. */
    safe_hv_store(stats, "status", 6, newSViv(a_xInfoP->status), 0);
    safe_hv_store(stats, "volid", 5, newSViv(a_xInfoP->volid), 0);
    if (a_xInfoP->status == VOK) {
        /* Volume's status is OK - all the fields are valid. */

        if (a_xInfoP->type == 0)
            safe_hv_store(stats, "type", 4, newSVpv("RW", 2), 0);
        if (a_xInfoP->type == 1)
            safe_hv_store(stats, "type", 4, newSVpv("RO", 2), 0);
        if (a_xInfoP->type == 2)
            safe_hv_store(stats, "type", 4, newSVpv("BK", 2), 0);

        safe_hv_store(stats, "size", 4, newSViv(a_xInfoP->size), 0);
        safe_hv_store(stats, "filecount", 9, newSViv(a_xInfoP->filecount), 0);

        if (a_xInfoP->inUse == 1) {
            safe_hv_store(stats, "inUse", 5, newSVpv("On-line", 7), 0);
            (*a_totalOKP)++;
        }
        else {
            safe_hv_store(stats, "inUse", 5, newSVpv("Off-line", 8), 0);
            (*a_totalNotOKP)++;
        }

        MapPartIdIntoName(a_partID, pname);
        strcpy(hostname, (char *) hostutil_GetNameByINet(a_servID));
        safe_hv_store(stats, "server", 6, newSVpv(hostname, strlen((char *) hostname)), 0);
        safe_hv_store(stats, "partition", 9, newSVpv(pname, strlen(pname)), 0);
        safe_hv_store(stats, "parentID", 8, newSViv(a_xInfoP->parentID), 0);
        safe_hv_store(stats, "cloneID", 7, newSViv(a_xInfoP->cloneID), 0);
        safe_hv_store(stats, "backupID", 8, newSViv(a_xInfoP->backupID), 0);
        safe_hv_store(stats, "maxquota", 8, newSViv(a_xInfoP->maxquota), 0);
        safe_hv_store(stats, "creationDate", 12, newSViv(a_xInfoP->creationDate), 0);
#ifdef OpenAFS           /* copy taken from <src/volser/vos.c> OpenAFS-1.2.11 FULL_LISTVOL_SWITCH*/
            safe_hv_store(stats, "copyDate", 8, newSViv(a_xInfoP->copyDate), 0);
            if (!a_xInfoP->backupDate)
                safe_hv_store(stats, "backupDate", 10, newSVpv("Never", 5), 0);
            else
                safe_hv_store(stats, "backupDate", 10, newSViv(a_xInfoP->backupDate), 0);
            if (a_xInfoP->accessDate)
                safe_hv_store(stats, "accessDate", 10, newSViv(a_xInfoP->accessDate), 0);
#endif
        if (!a_xInfoP->updateDate) {
            safe_hv_store(stats, "updateDate", 10, newSVpv("Never", 5), 0);
        }
        else {
            safe_hv_store(stats, "updateDate", 10, newSViv(a_xInfoP->updateDate), 0);
        }

        safe_hv_store(stats, "dayUse", 6, newSViv(a_xInfoP->dayUse), 0);
        safe_hv_store(stat1, "samenet", 7,
                 newSViv(a_xInfoP->stat_reads[VOLINT_STATS_SAME_NET]), 0);
        safe_hv_store(stat1, "samenetauth", 11,
                 newSViv(a_xInfoP->stat_reads[VOLINT_STATS_SAME_NET_AUTH]), 0);
        safe_hv_store(stat1, "diffnet", 7,
                 newSViv(a_xInfoP->stat_reads[VOLINT_STATS_DIFF_NET]), 0);
        safe_hv_store(stat1, "diffnetauth", 11,
                 newSViv(a_xInfoP->stat_reads[VOLINT_STATS_DIFF_NET_AUTH]), 0);
        safe_hv_store(stats, "Reads", 5, newRV_inc((SV *) (stat1)), 0);

        safe_hv_store(stat2, "samenet", 7,
                 newSViv(a_xInfoP->stat_writes[VOLINT_STATS_SAME_NET]), 0);
        safe_hv_store(stat2, "samenetauth", 11,
                 newSViv(a_xInfoP->stat_writes[VOLINT_STATS_SAME_NET_AUTH]), 0);
        safe_hv_store(stat2, "diffnet", 7,
                 newSViv(a_xInfoP->stat_writes[VOLINT_STATS_DIFF_NET]), 0);
        safe_hv_store(stat2, "diffnetauth", 11,
                 newSViv(a_xInfoP->stat_writes[VOLINT_STATS_DIFF_NET_AUTH]), 0);
        safe_hv_store(stats, "Writes", 6, newRV_inc((SV *) (stat2)), 0);

        safe_hv_store(stat3, "fileSameAuthor", 12,
                 newSViv(a_xInfoP->stat_fileSameAuthor[VOLINT_STATS_TIME_IDX_0]), 0);
        safe_hv_store(stat3, "fileDiffAuthor", 12,
                 newSViv(a_xInfoP->stat_fileDiffAuthor[VOLINT_STATS_TIME_IDX_0]), 0);
        safe_hv_store(stat3, "dirSameAuthor", 11,
                 newSViv(a_xInfoP->stat_dirSameAuthor[VOLINT_STATS_TIME_IDX_0]), 0);
        safe_hv_store(stat3, "dirDiffAuthor", 11,
                 newSViv(a_xInfoP->stat_dirDiffAuthor[VOLINT_STATS_TIME_IDX_0]), 0);
        safe_hv_store(stats, "0-60sec", 7, newRV_inc((SV *) (stat3)), 0);

        safe_hv_store(stat4, "fileSameAuthor", 12,
                 newSViv(a_xInfoP->stat_fileSameAuthor[VOLINT_STATS_TIME_IDX_1]), 0);
        safe_hv_store(stat4, "fileDiffAuthor", 12,
                 newSViv(a_xInfoP->stat_fileDiffAuthor[VOLINT_STATS_TIME_IDX_1]), 0);
        safe_hv_store(stat4, "dirSameAuthor", 11,
                 newSViv(a_xInfoP->stat_dirSameAuthor[VOLINT_STATS_TIME_IDX_1]), 0);
        safe_hv_store(stat4, "dirDiffAuthor", 11,
                 newSViv(a_xInfoP->stat_dirDiffAuthor[VOLINT_STATS_TIME_IDX_1]), 0);
        safe_hv_store(stats, "1-10min", 7, newRV_inc((SV *) (stat4)), 0);

        safe_hv_store(stat5, "fileSameAuthor", 12,
                 newSViv(a_xInfoP->stat_fileSameAuthor[VOLINT_STATS_TIME_IDX_2]), 0);
        safe_hv_store(stat5, "fileDiffAuthor", 12,
                 newSViv(a_xInfoP->stat_fileDiffAuthor[VOLINT_STATS_TIME_IDX_2]), 0);
        safe_hv_store(stat5, "dirSameAuthor", 11,
                 newSViv(a_xInfoP->stat_dirSameAuthor[VOLINT_STATS_TIME_IDX_2]), 0);
        safe_hv_store(stat5, "dirDiffAuthor", 11,
                 newSViv(a_xInfoP->stat_dirDiffAuthor[VOLINT_STATS_TIME_IDX_2]), 0);
        safe_hv_store(stats, "10min-1hr", 9, newRV_inc((SV *) (stat5)), 0);

        safe_hv_store(stat6, "fileSameAuthor", 12,
                 newSViv(a_xInfoP->stat_fileSameAuthor[VOLINT_STATS_TIME_IDX_3]), 0);
        safe_hv_store(stat6, "fileDiffAuthor", 12,
                 newSViv(a_xInfoP->stat_fileDiffAuthor[VOLINT_STATS_TIME_IDX_3]), 0);
        safe_hv_store(stat6, "dirSameAuthor", 11,
                 newSViv(a_xInfoP->stat_dirSameAuthor[VOLINT_STATS_TIME_IDX_3]), 0);
        safe_hv_store(stat6, "dirDiffAuthor", 11,
                 newSViv(a_xInfoP->stat_dirDiffAuthor[VOLINT_STATS_TIME_IDX_3]), 0);
        safe_hv_store(stats, "1hr-1day", 8, newRV_inc((SV *) (stat6)), 0);

        safe_hv_store(stat7, "fileSameAuthor", 12,
                 newSViv(a_xInfoP->stat_fileSameAuthor[VOLINT_STATS_TIME_IDX_4]), 0);
        safe_hv_store(stat7, "fileDiffAuthor", 12,
                 newSViv(a_xInfoP->stat_fileDiffAuthor[VOLINT_STATS_TIME_IDX_4]), 0);
        safe_hv_store(stat7, "dirSameAuthor", 11,
                 newSViv(a_xInfoP->stat_dirSameAuthor[VOLINT_STATS_TIME_IDX_4]), 0);
        safe_hv_store(stat7, "dirDiffAuthor", 11,
                 newSViv(a_xInfoP->stat_dirDiffAuthor[VOLINT_STATS_TIME_IDX_4]), 0);
        safe_hv_store(stats, "1day-1wk", 8, newRV_inc((SV *) (stat7)), 0);

        safe_hv_store(stat8, "fileSameAuthor", 12,
                 newSViv(a_xInfoP->stat_fileSameAuthor[VOLINT_STATS_TIME_IDX_5]), 0);
        safe_hv_store(stat8, "fileDiffAuthor", 12,
                 newSViv(a_xInfoP->stat_fileDiffAuthor[VOLINT_STATS_TIME_IDX_5]), 0);
        safe_hv_store(stat8, "dirSameAuthor", 11,
                 newSViv(a_xInfoP->stat_dirSameAuthor[VOLINT_STATS_TIME_IDX_5]), 0);
        safe_hv_store(stat8, "dirDiffAuthor", 11,
                 newSViv(a_xInfoP->stat_dirDiffAuthor[VOLINT_STATS_TIME_IDX_5]), 0);
        safe_hv_store(stats, ">1wk", 4, newRV_inc((SV *) (stat8)), 0);
    }                       /*Volume status OK */
    else if (a_xInfoP->status == VBUSY) {
        (*a_totalBusyP)++;
        qPut(&busyHead, a_xInfoP->volid);
    }                       /*Busy volume */
    else {
        (*a_totalNotOKP)++;
        qPut(&notokHead, a_xInfoP->volid);
    }                       /*Screwed volume */
}                           /*myXDisplayFormat */

static void VolumeStats(volinfo, pntr, entry, server, part, voltype)
    HV *volinfo;
    volintInfo *pntr;
    struct nvldbentry *entry;
    int voltype;
    afs_int32 server, part;
{
    int totalOK, totalNotOK, totalBusy;

    myDisplayFormat(volinfo, pntr, server, part, &totalOK, &totalNotOK, &totalBusy, 0);
    return;
}

static void DisplayVolumes(partition, server, part, pntr, count, fast)
    HV *partition;
    afs_int32 server, part;
    volintInfo *pntr;
    afs_int32 count, fast;
{
    int totalOK, totalNotOK, totalBusy, i;
    char buff[32];

    totalOK = 0;
    totalNotOK = 0;
    totalBusy = 0;
    qInit(&busyHead);
    qInit(&notokHead);
    for (i = 0; i < count; i++) {
        HV *vol = (HV *) sv_2mortal((SV *) newHV());
        myDisplayFormat(vol, pntr, server, part, &totalOK, &totalNotOK, &totalBusy, fast);
        if (pntr->status == VOK) {
            safe_hv_store(partition, pntr->name, strlen(pntr->name), newRV_inc((SV *) (vol)), 0);
        }
        else if (pntr->status == VBUSY) {
            sprintf(buff, "volume_busy_%d", i);
            safe_hv_store(partition, buff, strlen(buff), newRV_inc((SV *) (vol)), 0);
            /* fprintf(STDERR, "DEBUG-1: %s %d\n", buff, strlen(buff)); */
        }
        else {
            sprintf(buff, "volume_notok_%d", i);
            safe_hv_store(partition, buff, strlen(buff), newRV_inc((SV *) (vol)), 0);
            /* fprintf(STDERR, "DEBUG-2: %s %d\n", buff, strlen(buff)); */
        }
        pntr++;
    }
    if (!fast) {
        safe_hv_store(partition, " totalOK", 8, newSViv(totalOK), 0);
        safe_hv_store(partition, " totalBusy", 10, newSViv(totalBusy), 0);
        safe_hv_store(partition, " totalNotOK", 11, newSViv(totalNotOK), 0);
    }
}

static void XDisplayVolumes(part, a_servID, a_partID, a_xInfoP, a_count)
    HV *part;
    afs_int32 a_servID;
    afs_int32 a_partID;
    volintXInfo *a_xInfoP;
    afs_int32 a_count;

{                               /*XDisplayVolumes */

    int totalOK;                /*Total OK volumes */
    int totalNotOK;             /*Total screwed volumes */
    int totalBusy;              /*Total busy volumes */
    int i;                      /*Loop variable */
    char buff[32];

    /* Initialize counters and (global!!) queues.*/
    totalOK = 0;
    totalNotOK = 0;
    totalBusy = 0;
    qInit(&busyHead);
    qInit(&notokHead);

    /* Display each volume in the list.*/
    for (i = 0; i < a_count; i++) {
        HV *vol = (HV *) sv_2mortal((SV *) newHV());
        myXDisplayFormat(vol,
                         a_xInfoP,
                         a_servID,
                         a_partID, &totalOK, &totalNotOK, &totalBusy);
        if (a_xInfoP->status == VOK) {
            safe_hv_store(part, a_xInfoP->name, strlen(a_xInfoP->name), newRV_inc((SV *) (vol)), 0);
        }
        else if (a_xInfoP->status == VBUSY) {
            sprintf(buff, "volume_busy_%d", i);
            safe_hv_store(part, buff, strlen(buff), newRV_inc((SV *) (vol)), 0);
            /* fprintf(STDERR, "DEBUG-1: %s %d\n", buff, strlen(buff)); */
        }
        else {
            sprintf(buff, "volume_notok_%d", i);
            safe_hv_store(part, buff, strlen(buff), newRV_inc((SV *) (vol)), 0);
            /* fprintf(STDERR, "DEBUG-2: %s %d\n", buff, strlen(buff)); */
        }
        a_xInfoP++;
    }

    /* If any volumes were found to be busy or screwed, display them.*/
    safe_hv_store(part, " totalOK", 8, newSViv(totalOK), 0);
    safe_hv_store(part, " totalBusy", 10, newSViv(totalBusy), 0);
    safe_hv_store(part, " totalNotOK", 11, newSViv(totalNotOK), 0);
}                               /*XDisplayVolumes */
/* end of helper functions for VOS class */


/* helper functions for VLDB class: */

void myEnumerateEntry(stats, entry)
    HV *stats;
    struct nvldbentry *entry;
{
    int i;
    char pname[10];
    char hostname[256];
    int isMixed = 0;
    AV *av = (AV *) sv_2mortal((SV *) newAV());

    if (entry->flags & RW_EXISTS)
        safe_hv_store(stats, "RWrite", 6, newSViv(entry->volumeId[RWVOL]), 0);
    if (entry->flags & RO_EXISTS)
        safe_hv_store(stats, "ROnly", 5, newSViv(entry->volumeId[ROVOL]), 0);
    if (entry->flags & BACK_EXISTS)
        safe_hv_store(stats, "Backup", 6, newSViv(entry->volumeId[BACKVOL]), 0);
    if ((entry->cloneId != 0) && (entry->flags & RO_EXISTS))
        safe_hv_store(stats, "cloneId", 7, newSViv(entry->cloneId), 0);

    safe_hv_store(stats, "nServers", 8, newSViv(entry->nServers), 0);

    for (i = 0; i < entry->nServers; i++) {
        if (entry->serverFlags[i] & NEW_REPSITE)
            isMixed = 1;
    }

    for (i = 0; i < entry->nServers; i++) {
        HV *server = (HV *) sv_2mortal((SV *) newHV());
        MapPartIdIntoName(entry->serverPartition[i], pname);
        strcpy(hostname, (char *) hostutil_GetNameByINet(entry->serverNumber[i]));
        safe_hv_store(server, "name", 4, newSVpv(hostname, strlen((char *) hostname)), 0);
        safe_hv_store(server, "partition", 9, newSVpv(pname, strlen((char *) pname)), 0);

        safe_hv_store(server, "serverFlags", 11, newSViv(entry->serverFlags[i]), 0);

        if (entry->serverFlags[i] & ITSRWVOL)
            safe_hv_store(server, "type", 4, newSVpv("RW", 2), 0);
        else
            safe_hv_store(server, "type", 4, newSVpv("RO", 2), 0);

        if (isMixed) {
            if (entry->serverFlags[i] & NEW_REPSITE)
                safe_hv_store(server, "release", 7, newSVpv("New release", 11), 0);
            else
                safe_hv_store(server, "release", 7, newSVpv("Old release", 11), 0);
        }
        else {
            if (entry->serverFlags[i] & RO_DONTUSE)
                safe_hv_store(server, "release", 7, newSVpv("Not released", 12), 0);
        }
        av_push(av, newRV_inc((SV *) (server)));
    }
    safe_hv_store(stats, "server", 6, newRV_inc((SV *) (av)), 0);

    safe_hv_store(stats, "flags", 5, newSViv(entry->flags), 0);
    if (entry->flags & VLOP_ALLOPERS)
        safe_hv_store(stats, "locked", 6, newSViv(entry->flags & VLOP_ALLOPERS), 0);

    return;
}

static int VolumeInfoCmd(stats, name)
    HV *stats;
    char *name;
{
    struct nvldbentry entry;
    afs_int32 vcode;

    /* printf("DEBUG-1-VolumeInfoCmd %s \n", name); */
    /* The vlserver will handle names with the .readonly
     * and .backup extension as well as volume ids.
     */
    vcode = VLDB_GetEntryByName(name, &entry);
    /* printf("DEBUG-2-VolumeInfoCmd %d \n", vcode); */
    if (vcode)
        return (vcode);

    /* printf("DEBUG-3-VolumeInfoCmd \n"); */
    MapHostToNetwork(&entry);
    /* printf("DEBUG-4-VolumeInfoCmd \n"); */
    myEnumerateEntry(stats, &entry);
    /* printf("DEBUG-5-VolumeInfoCmd \n"); */

    return 0;
}

/* static void PostVolumeStats_ZZZ(volinfo, entry) */
/*     HV *volinfo; */
/*     struct nvldbentry *entry; */
/* { */
/*     myEnumerateEntry(volinfo, entry); */
/*     /\* Check for VLOP_ALLOPERS *\/ */
/*     if (entry->flags & VLOP_ALLOPERS) */
/*         fprintf(STDOUT, "    Volume is currently LOCKED  \n"); */
/*     return; */
/* } */

static void myprint_addrs(addr, addrs, m_uuid, nentries, print, noresolve)
    HV * addr;
    const bulkaddrs * addrs;
    const afsUUID * m_uuid;
    int nentries;
    int print;
    int noresolve;
{
    afs_int32 vcode;
    afs_int32 i;
    afs_int32 *addrp;
    bulkaddrs m_addrs;
    ListAddrByAttributes m_attrs;
    afs_int32 m_unique, m_nentries, *m_addrp;
    afs_int32 base, index;
    char buf[1024];

#ifdef OpenAFS
    if (print) {
        afsUUID_to_string(m_uuid, buf, sizeof(buf));
        safe_hv_store(addr, "UUID", 4, newSVpv(buf, strlen(buf)), 0);
    }
#else
    noresolve = 0;
#endif

    /* print out the list of all the server */
    addrp = (afs_int32 *) addrs->bulkaddrs_val;
    for (i = 0; i < nentries; i++, addrp++) {
        char key[7];
        int j = i + 1;
        /* If it is a multihomed address, then we will need to 
         * get the addresses for this multihomed server from
         * the vlserver and print them.
         */
        if (((*addrp & 0xff000000) == 0xff000000) && ((*addrp) & 0xffff)) {
            /* Get the list of multihomed fileservers */
            base = (*addrp >> 16) & 0xff;
            index = (*addrp) & 0xffff;

            if ((base >= 0) && (base <= VL_MAX_ADDREXTBLKS) &&
                (index >= 1) && (index <= VL_MHSRV_PERBLK)) {
                AV *names = newAV();
                AV *IPs = newAV();

                m_attrs.Mask = VLADDR_INDEX;
                m_attrs.index = (base * VL_MHSRV_PERBLK) + index;
                m_nentries = 0;
                m_addrs.bulkaddrs_val = 0;
                m_addrs.bulkaddrs_len = 0;
                vcode = ubik_Call(VL_GetAddrsU, cstruct, 0,
                                  &m_attrs, &m_uuid, &m_unique, &m_nentries, &m_addrs);
                if (vcode) {
                    char buffer[256];
                    sprintf(buffer,
                            "AFS::VLDB: could not list the multi-homed server addresses\n");
                    VSETCODE(vcode, buffer);
                }

                /* Print the list */
                m_addrp = (afs_int32 *) m_addrs.bulkaddrs_val;
                for (j = 0; j < m_nentries; j++, m_addrp++) {
                    *m_addrp = htonl(*m_addrp);
#ifdef OpenAFS
                    if (noresolve) {
                        char hoststr[16];
                        sprintf(buf, "%s", afs_inet_ntoa_r(*m_addrp, hoststr));
                        av_push(IPs, newSVpv(buf, strlen(buf)));
                    }
                    else {
#endif
                        sprintf(buf, "%s", (char *) hostutil_GetNameByINet(*m_addrp));
                        av_push(names, newSVpv(buf, strlen(buf)));
#ifdef OpenAFS
                    }
#endif
                }               /* for loop */
                if (j == 0) {
                    printf("<unknown>\n");
                    av_push(names, newSVpv(NULL, 0));
                    av_push(IPs, newSVpv(NULL, 0));
                }

                continue;

                safe_hv_store(addr, "IP", 2, newRV_inc((SV *) (IPs)), 0);
                safe_hv_store(addr, "name", 4, newRV_inc((SV *) (names)), 0);
            }
        }

        /* Otherwise, it is a non-multihomed entry and contains
         * the IP address of the server - print it.
         */
        *addrp = htonl(*addrp);
#ifdef OpenAFS
        if (noresolve) {
            char hoststr[16];
            sprintf(key, "IP-%d", j);
            sprintf(buf, "%s", afs_inet_ntoa_r(*addrp, hoststr));
            safe_hv_store(addr, key, 4, newSVpv(buf, strlen(buf)), 0);
        }
        else {
#endif
            sprintf(key, "name-%d", j);
            sprintf(buf, "%s", (char *) hostutil_GetNameByINet(*addrp));
            safe_hv_store(addr, key, 6, newSVpv(buf, strlen(buf)), 0);
#ifdef OpenAFS
        }
#endif
    }                           /* for loop */

    return;
}

static void GetServerAndPart(entry, voltype, server, part, previdx)
    struct nvldbentry *entry;
    afs_int32 *server, *part;
    int voltype;
    int *previdx;
{
    int i, istart, vtype;


    *server = -1;
    *part = -1;


    /* Doesn't check for non-existance of backup volume */
    if ((voltype == RWVOL) || (voltype == BACKVOL)) {
        vtype = ITSRWVOL;
        istart = 0;             /* seach the entire entry */
    }
    else {
        vtype = ITSROVOL;
        /* Seach from beginning of entry or pick up where we left off */
        istart = ((*previdx < 0) ? 0 : *previdx + 1);
    }


    for (i = istart; i < entry->nServers; i++) {
        if (entry->serverFlags[i] & vtype) {
            *server = entry->serverNumber[i];
            *part = entry->serverPartition[i];
            *previdx = i;
            return;
        }
    }


    /* Didn't find any, return -1 */
    *previdx = -1;
    return;
}
/* end of helper functions for VLDB class */


/* helper functions for BOS class */

#ifndef OpenAFS
/* is this a digit or a digit-like thing? */
static int ismeta(ac, abase)
    register int abase;
    register int ac;
{
/*    if (ac == '-' || ac == 'x' || ac == 'X') return 1; */
    if (ac >= '0' && ac <= '7')
        return 1;
    if (abase <= 8)
        return 0;
    if (ac >= '8' && ac <= '9')
        return 1;
    if (abase <= 10)
        return 0;
    if (ac >= 'a' && ac <= 'f')
        return 1;
    if (ac >= 'A' && ac <= 'F')
        return 1;
    return 0;
}

/* given that this is a digit or a digit-like thing, compute its value */
static int getmeta(ac)
    register int ac;
{
    if (ac >= '0' && ac <= '9')
        return ac - '0';
    if (ac >= 'a' && ac <= 'f')
        return ac - 'a' + 10;
    if (ac >= 'A' && ac <= 'F')
        return ac - 'A' + 10;
    return 0;
}

afs_uint32 GetUInt32(as, aval)
    register char *as;
    afs_uint32 *aval;
{
    register afs_uint32 total;
    register int tc;
    int base;

    total = 0;                  /* initialize things */

    /* skip over leading spaces */
    while ((tc = *as)) {
        if (tc != ' ' && tc != '\t')
            break;
    }

    /* compute the base */
    if (*as == '0') {
        as++;
        if (*as == 'x' || *as == 'X') {
            base = 16;
            as++;
        }
        else
            base = 8;
    }
    else
        base = 10;

    /* compute the # itself */
    while ((tc = *as)) {
        if (!ismeta(tc, base))
            return -1;
        total *= base;
        total += getmeta(tc);
        as++;
    }

    *aval = total;
    return 0;
}
#endif

/* keep those lines small */
static char *em(acode)
    afs_int32 acode;
{
    if (acode == -1)
        return "communications failure (-1)";
    else if (acode == -3)
        return "communications timeout (-3)";
    else
        return (char *) error_message(acode);
}

static struct rx_connection *internal_bos_new(code, hostname, localauth, noauth, aencrypt,
                                              tname)
    int32 *code;
    char *hostname;
    int localauth;
    int noauth;
    int aencrypt;
    char *tname;
{
    struct hostent *th;
    register struct rx_connection *tconn;
    struct rx_securityClass *sc[3];
    int scIndex;
    afs_int32 addr;
    int encryptLevel;
    struct ktc_principal sname;
    struct ktc_token ttoken;

    /* printf("bos DEBUG-1: %s \n", cdir); */
    th = (struct hostent *) hostutil_GetHostByName(hostname);
    if (!th) {
        char buffer[256];
        sprintf(buffer, "AFS::BOS: can't find address for host '%s'\n", hostname);
        *code = -1;
        BSETCODE(code, buffer);
/*         printf("bos DEBUG-1: %s\n", buffer); */
        return NULL;
    }
    /* Copy(th->h_addr, &addr, sizeof(afs_int32), afs_int32); */
    Copy(th->h_addr, &addr, th->h_length, char);

    /* get tokens for making authenticated connections */
    if (!rx_initialized) {
        /* printf("bos DEBUG rx_Init\n"); */
        *code = rx_Init(0);
        if (*code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: could not initialize rx (%d)\n", *code);
            BSETCODE(code, buffer);
/*          printf("bos DEBUG-2\n"); */
            return NULL;
        }
    }
    rx_initialized = 1;

    *code = ka_Init(0);
    if (*code) {
        char buffer[256];
        sprintf(buffer, "AFS::BOS: could not initialize ka (%d)\n", *code);
        BSETCODE(code, buffer);
/*          printf("bos DEBUG-3\n"); */
        return NULL;
    }

    if (localauth)
        internal_GetServerConfigDir();
    else
        internal_GetConfigDir();
    /* printf("bos DEBUG-2: %s\n", cdir->name); */

    if (!cdir) {
        *code = errno;
        SETCODE(code);
/*         printf("bos DEBUG-4\n"); */
        return NULL;
    }

    struct afsconf_cell info;

    /* next call expands cell name abbrevs for us and handles looking up
     * local cell */
    *code = internal_GetCellInfo(tname, (char *) 0, &info);
    if (*code) {
        char buffer[256];
        sprintf(buffer, "AFS::BOS %d (can't find cell '%s' in cell database)",
                *code, (tname ? tname : "<default>"));
        BSETCODE(code, buffer);
        /*             printf("bos DEBUG-5\n"); */
        return NULL;
    }

    strcpy(sname.cell, info.name);
    sname.instance[0] = 0;
    strcpy(sname.name, "afs");
    sc[0] = (struct rx_securityClass *) rxnull_NewClientSecurityObject();
    sc[1] = 0;
    sc[2] = (struct rx_securityClass *) NULL;
    scIndex = 0;

    if (!noauth) {              /* not -noauth */
        if (localauth) {        /* -localauth */
            *code = afsconf_GetLatestKey(cdir, 0, 0);
            if (*code)
                fprintf(stderr, "AFS::BOS %d (getting key from local KeyFile)", *code);
            else {
                if (aencrypt)
                    *code = afsconf_ClientAuthSecure(cdir, &sc[2], &scIndex);
                else
                    *code = afsconf_ClientAuth(cdir, &sc[2], &scIndex);
                if (*code)
                    fprintf(stderr, "AFS::BOS %d (calling ClientAuth)", *code);
                else if (scIndex != 2)  /* this shouldn't happen */
                    sc[scIndex] = sc[2];
            }
        }
        else {                  /* not -localauth, check for tickets */
            *code = ktc_GetToken(&sname, &ttoken, sizeof(ttoken), NULL);
            if (*code == 0) {
                /* have tickets, will travel */
                if (ttoken.kvno >= 0 && ttoken.kvno <= 256);
                else {
                    fprintf(stderr,
                            "AFS::BOS: funny kvno (%d) in ticket, proceeding\n",
                            ttoken.kvno);
                }
                /* kerberos tix */
                if (aencrypt)
                    encryptLevel = rxkad_crypt;
                else
                    encryptLevel = rxkad_clear;
                sc[2] = (struct rx_securityClass *)
                    rxkad_NewClientSecurityObject
                    (encryptLevel, &ttoken.sessionKey,
                     ttoken.kvno, ttoken.ticketLen, ttoken.ticket);
                scIndex = 2;
            }
            else
                fprintf(stderr, "AFS::BOS %d (getting tickets)", *code);
        }
        if ((scIndex == 0) || (sc[scIndex] == 0)) {
            fprintf(stderr, "AFS::BOS: running unauthenticated\n");
            scIndex = 0;
        }
    }
    tconn = rx_NewConnection(addr, htons(AFSCONF_NANNYPORT), 1, sc[scIndex], scIndex);
    if (!tconn) {
        char buffer[256];
        sprintf(buffer, "AFS::BOS: could not create rx connection\n");
        *code = -1;
        BSETCODE(code, buffer);
/*         printf("bos DEBUG-7\n"); */
        return NULL;
    }
    rxs_Release(sc[scIndex]);

    return tconn;
}

static int DoStat(stats, aname, aconn, aint32p, firstTime)
    HV *stats;
    IN char *aname;
    IN register struct rx_connection *aconn;
    IN int aint32p;
    IN int firstTime;           /* true iff first instance in cmd */
{
    afs_int32 temp;
    char buffer[500];
    register afs_int32 code;
    register afs_int32 i;
    struct bozo_status istatus;
    char *tp;
    char *is1, *is2, *is3, *is4;        /* instance strings */
    char info[255];

    tp = buffer;
    code = BOZO_GetInstanceInfo(aconn, aname, &tp, &istatus);
    if (code) {
        char buf[256];
        sprintf(buf, "AFS::BOS: failed to get instance info for '%s' (%s)\n",
                aname, em(code));
        BSETCODE(code, buf);
        return -1;
    }
    if (firstTime && aint32p && (istatus.flags & BOZO_BADDIRACCESS)) {
        char buf[256];
        sprintf(buf, "Bosserver reports inappropriate access on server directories\n");
        BSETCODE(-1, buf);
    }
    /*printf("Instance %s, ", aname); */
    if (aint32p) {
        /* printf("(type is %s) ", buffer); */
        safe_hv_store(stats, "type", 4, newSVpv(buffer, strlen(buffer)), 0);
    }

    sprintf(info, "%s", "");
    if (istatus.fileGoal == istatus.goal) {
        if (!istatus.goal)
            sprintf(info, "%s", "disabled");
    }
    else {
        if (istatus.fileGoal)
            sprintf(info, "%s", "temporarily disabled");
        else
            sprintf(info, "%s", "temporarily enabled");
    }
    safe_hv_store(stats, "info", 4, newSVpv(info, strlen(info)), 0);
    safe_hv_store(stats, "goal", 4, newSViv(istatus.goal), 0);
    safe_hv_store(stats, "fileGoal", 8, newSViv(istatus.fileGoal), 0);

    if (istatus.flags & BOZO_ERRORSTOP) {
        /* printf("stopped for too many errors, "); */
        safe_hv_store(stats, "status", 6, newSViv(BOZO_ERRORSTOP), 0);
    }
    if (istatus.flags & BOZO_HASCORE) {
        /* printf("has core file, "); */
        safe_hv_store(stats, "status", 6, newSViv(BOZO_HASCORE), 0);
    }
    safe_hv_store(stats, "flags", 5, newSViv(istatus.flags), 0);

    tp = buffer;
    code = BOZO_GetStatus(aconn, aname, &temp, &tp);
    if (code) {
        char buf[256];
        sprintf(buf, "AFS::BOS: failed to get status for instance '%s' (%s)\n",
                aname, em(code));
        BSETCODE(code, buf);
    }
    else {
        /* printf("currently ", aname); */
        /* if (temp == BSTAT_NORMAL) printf("running normally.\n"); */
        /* else if (temp == BSTAT_SHUTDOWN) printf("shutdown.\n"); */
        /* else if (temp == BSTAT_STARTINGUP) printf("starting up.\n"); */
        /* else if (temp == BSTAT_SHUTTINGDOWN) printf("shutting down.\n"); */
        safe_hv_store(stats, "status", 6, newSViv(temp), 0);
        if (buffer[0] != 0) {
            /* printf("    Auxiliary status is: %s.\n", buffer); */
            safe_hv_store(stats, "aux_status", 10, newSVpv(buffer, strlen(buffer)), 0);
        }
    }

    /* are we done yet? */
    if (!aint32p)
        return 0;

    if (istatus.procStartTime) {
        /* printf("    Process last started at %s (%d proc starts)\n", */
        /*        DateOf(istatus.procStartTime), istatus.procStarts); */
        safe_hv_store(stats, "procStartTime", 13, newSViv(istatus.procStartTime), 0);
        safe_hv_store(stats, "procStarts", 10, newSViv(istatus.procStarts), 0);
    }
    if (istatus.lastAnyExit) {
        /* printf("    Last exit at %s\n", DateOf(istatus.lastAnyExit)); */
        safe_hv_store(stats, "lastAnyExit", 11, newSViv(istatus.lastAnyExit), 0);
    }
    if (istatus.lastErrorExit) {
        is1 = is2 = is3 = is4 = (char *) 0;
        /* printf("    Last error exit at %s, ", DateOf(istatus.lastErrorExit)); */
        safe_hv_store(stats, "lastErrorExit", 13, newSViv(istatus.lastErrorExit), 0);
        code = BOZO_GetInstanceStrings(aconn, aname, &is1, &is2, &is3, &is4);
        /* don't complain about failing call, since could simply mean
         * interface mismatch.
         */
        if (code == 0) {
            if (*is1 != 0) {
                /* non-null instance string */
                /* printf("by %s, ", is1); */
                safe_hv_store(stats, "by", 2, newSVpv(is1, strlen(is1)), 0);
            }
            if (is1)
                free(is1);
            if (is2)
                free(is2);
            if (is3)
                free(is3);
            if (is4)
                free(is4);
        }
        if (istatus.errorSignal) {
            /* if (istatus.errorSignal == SIGTERM) */
            /*    printf("due to shutdown request\n"); */
            /* else */
            /*    printf("due to signal %d\n", istatus.errorSignal); */
            safe_hv_store(stats, "errorSignal", 11, newSViv(istatus.errorSignal), 0);
        }
        else {
            /* printf("by exiting with code %d\n", istatus.errorCode); */
            safe_hv_store(stats, "errorCode", 9, newSViv(istatus.errorCode), 0);
        }
    }

    if (aint32p > 1) {
        AV *av = (AV *) sv_2mortal((SV *) newAV());

        /* try to display all the parms */
        for (i = 0;; i++) {
            tp = buffer;
            code = BOZO_GetInstanceParm(aconn, aname, i, &tp);
            if (code)
                break;
            /* fprintf(stderr, "    Command %d is '%s'\n", i+1, buffer); */
            av_push(av, newSVpv(buffer, strlen(buffer)));
        }
        safe_hv_store(stats, "command", 7, newRV_inc((SV *) (av)), 0);

        tp = buffer;
        code = BOZO_GetInstanceParm(aconn, aname, 999, &tp);
        if (!code) {
            /* Any type of failure is treated as not having a notifier program */
            /* printf("    Notifier  is '%s'\n", buffer); */
            safe_hv_store(stats, "notifier", 8, newSVpv(buffer, strlen(buffer)), 0);
        }
        /* printf("\n"); */
    }
    return 0;
}

static afs_int32 GetServerGoal(aconn, aname)
    char *aname;
    struct rx_connection *aconn;
{
    char buffer[500];
    char *tp;
    register afs_int32 code;
    struct bozo_status istatus;

    tp = buffer;
    code = BOZO_GetInstanceInfo(aconn, aname, &tp, &istatus);
    if (code) {
        printf("AFS::BOS: failed to get instance info for '%s' (%s)\n", aname, em(code));
        /* if we can't get the answer, assume its running */
        return BSTAT_NORMAL;
    }
    if (istatus.goal == 0)
        return BSTAT_SHUTDOWN;
    else
        return BSTAT_NORMAL;
}

#define PARMBUFFERSSIZE 32

static struct SalvageParms {
    afs_int32 Optdebug;
    afs_int32 Optnowrite;
    afs_int32 Optforce;
    afs_int32 Optoktozap;
    afs_int32 Optrootfiles;
    afs_int32 Optsalvagedirs;
    afs_int32 Optblockreads;
    afs_int32 OptListResidencies;
    afs_int32 OptSalvageRemote;
    afs_int32 OptSalvageArchival;
    afs_int32 OptIgnoreCheck;
    afs_int32 OptForceOnLine;
    afs_int32 OptUseRootDirACL;
    afs_int32 OptTraceBadLinkCounts;
    afs_int32 OptDontAskFS;
    afs_int32 OptLogLevel;
    afs_int32 OptRxDebug;
    afs_uint32 OptResidencies;
} mrafsParm;

static int DoSalvage(aconn, aparm1, aparm2, aoutName, showlog, parallel, atmpDir, orphans)
    struct rx_connection *aconn;
    char *aoutName;
    char *aparm1;
    char *aparm2;
    afs_int32 showlog;
    char *parallel;
    char *atmpDir;
    char *orphans;
{
    register afs_int32 code;
    char *parms[6];
    char buffer;
    char tbuffer[BOZO_BSSIZE];
    struct bozo_status istatus;
    struct rx_call *tcall;
    char *tp;
    FILE *outFile;
    int closeIt = 0;
    char partName[20];          /* canonical name for partition */
    char pbuffer[PARMBUFFERSSIZE];
    afs_int32 partNumber;
    char *notifier = NONOTIFIER;

    /* if a partition was specified, canonicalize the name, since
       the salvager has a stupid partition ID parser */
    if (aparm1) {
        partNumber = volutil_GetPartitionID(aparm1);
        if (partNumber < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: could not parse partition ID '%s'\n", aparm1);
            BSETCODE(EINVAL, buffer);
            return EINVAL;
        }
        tp = (char *) volutil_PartitionName(partNumber);
        if (!tp) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: internal error parsing partition ID '%s'\n",
                    aparm1);
            BSETCODE(EINVAL, buffer);
            return EINVAL;
        }
        strcpy(partName, tp);
    }
    else
        partName[0] = 0;

    /* open the file name */
    if (aoutName) {
        outFile = fopen(aoutName, "w");
        if (!outFile) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: can't open specified SalvageLog file '%s'\n",
                    aoutName);
            BSETCODE(ENOENT, buffer);
            return ENOENT;
        }
        closeIt = 1;            /* close this file later */
    }
    else {
        outFile = stdout;
        closeIt = 0;            /* don't close this file later */
    }

    for (code = 2; code < 6; code++)
        parms[code] = "";
    if (!aparm2)
        aparm2 = "";
    /* MUST pass canonical (wire-format) salvager path to bosserver */
    strncpy(tbuffer, AFSDIR_CANONICAL_SERVER_SALVAGER_FILEPATH, BOZO_BSSIZE);
    if (*aparm2 != 0) {
        if ((strlen(tbuffer) + 1 + strlen(partName) + 1 + strlen(aparm2) + 1) >
            BOZO_BSSIZE) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: command line too big\n");
            BSETCODE(E2BIG, buffer);
            return (E2BIG);
        }
        strcat(tbuffer, " ");
        strcat(tbuffer, partName);
        strcat(tbuffer, " ");
        strcat(tbuffer, aparm2);
    }
    else {
        if ((strlen(tbuffer) + 4 + strlen(partName) + 1) > BOZO_BSSIZE) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: command line too big\n");
            BSETCODE(E2BIG, buffer);
            return (E2BIG);
        }
        strcat(tbuffer, " -f ");
        strcat(tbuffer, partName);
    }

    /* add the parallel option if given */
    if (parallel != (char *) 0) {
        if ((strlen(tbuffer) + 11 + strlen(parallel) + 1) > BOZO_BSSIZE) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: command line too big\n");
            BSETCODE(E2BIG, buffer);
            return (E2BIG);
        }
        strcat(tbuffer, " -parallel ");
        strcat(tbuffer, parallel);
    }

    /* add the tmpdir option if given */
    if (atmpDir != (char *) 0) {
        if ((strlen(tbuffer) + 9 + strlen(atmpDir) + 1) > BOZO_BSSIZE) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: command line too big\n");
            BSETCODE(E2BIG, buffer);
            return (E2BIG);
        }
        strcat(tbuffer, " -tmpdir ");
        strcat(tbuffer, atmpDir);
    }

    /* add the orphans option if given */
    if (orphans != (char *) 0) {
        if ((strlen(tbuffer) + 10 + strlen(orphans) + 1) > BOZO_BSSIZE) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: command line too big\n");
            BSETCODE(E2BIG, buffer);
            return (E2BIG);
        }
        strcat(tbuffer, " -orphans ");
        strcat(tbuffer, orphans);
    }

    if (mrafsParm.Optdebug)
        strcat(tbuffer, " -debug");
    if (mrafsParm.Optnowrite)
        strcat(tbuffer, " -nowrite");
    if (mrafsParm.Optforce)
        strcat(tbuffer, " -force");
    if (mrafsParm.Optoktozap)
        strcat(tbuffer, " -oktozap");
    if (mrafsParm.Optrootfiles)
        strcat(tbuffer, " -rootfiles");
    if (mrafsParm.Optsalvagedirs)
        strcat(tbuffer, " -salvagedirs");
    if (mrafsParm.Optblockreads)
        strcat(tbuffer, " -blockreads");
    if (mrafsParm.OptListResidencies)
        strcat(tbuffer, " -ListResidencies");
    if (mrafsParm.OptSalvageRemote)
        strcat(tbuffer, " -SalvageRemote");
    if (mrafsParm.OptSalvageArchival)
        strcat(tbuffer, " -SalvageArchival");
    if (mrafsParm.OptIgnoreCheck)
        strcat(tbuffer, " -IgnoreCheck");
    if (mrafsParm.OptForceOnLine)
        strcat(tbuffer, " -ForceOnLine");
    if (mrafsParm.OptUseRootDirACL)
        strcat(tbuffer, " -UseRootDirACL");
    if (mrafsParm.OptTraceBadLinkCounts)
        strcat(tbuffer, " -TraceBadLinkCounts");
    if (mrafsParm.OptDontAskFS)
        strcat(tbuffer, " -DontAskFS");
    if (mrafsParm.OptLogLevel) {
        sprintf(pbuffer, " -LogLevel %d", mrafsParm.OptLogLevel);
        strcat(tbuffer, pbuffer);
    }
    if (mrafsParm.OptRxDebug)
        strcat(tbuffer, " -rxdebug");
    if (mrafsParm.OptResidencies) {
        sprintf(pbuffer, " -Residencies %u", mrafsParm.OptResidencies);
        strcat(tbuffer, pbuffer);
    }

    parms[0] = tbuffer;
    parms[1] = "now";           /* when to do it */
    code = BOZO_CreateBnode(aconn, "cron", "salvage-tmp", parms[0], parms[1],
                            parms[2], parms[3], parms[4], notifier);
    if (code) {
        char buffer[256];
        sprintf(buffer, "AFS::BOS: failed to start 'salvager' (%s)\n", em(code));
        BSETCODE(code, buffer);
        goto done;
    }
    /* now wait for bnode to disappear */
    while (1) {
#ifdef AFS_PTHREAD_ENV
        sleep(5);
#else
        IOMGR_Sleep(5);
#endif /* AFS_PTHREAD_ENV*/
        tp = tbuffer;
        code = BOZO_GetInstanceInfo(aconn, "salvage-tmp", &tp, &istatus);
        if (code)
            break;
        /* fprintf(stderr, "AFS::BOS: waiting for salvage to complete.\n"); */
    }
    if (code != BZNOENT) {
        char buffer[256];
        sprintf(buffer, "AFS::BOS: salvage failed (%s)\n", em(code));
        BSETCODE(code, buffer);
        goto done;
    }
    code = 0;

    /* now print the log file to the output file */
    /* fprintf(stderr, "AFS::BOS: salvage completed\n"); */
    if (aoutName || showlog) {
        fprintf(outFile, "SalvageLog:\n");
        tcall = rx_NewCall(aconn);
        /* MUST pass canonical (wire-format) salvager log path to bosserver */
        code = StartBOZO_GetLog(tcall, AFSDIR_CANONICAL_SERVER_SLVGLOG_FILEPATH);
        if (code) {
            rx_EndCall(tcall, code);
            goto done;
        }
        /* copy data */
        while (1) {
            code = rx_Read(tcall, &buffer, 1);
            if (code != 1)
                break;
            putc(buffer, outFile);
            if (buffer == 0)
                break;          /* the end delimeter */
        }
        code = rx_EndCall(tcall, 0);
        /* fall through into cleanup code */
    }

  done:
    if (closeIt && outFile)
        fclose(outFile);
    return code;
}
/* end of helper functions for BOS class */


/* helper functions for FS class: */

static int32 isafs(path, follow)
    char *path;
    int32 follow;
{
    struct ViceIoctl vi;
    register int32 code;
    char space[MAXSIZE];

    vi.in_size = 0;
    vi.out_size = MAXSIZE;
    vi.out = space;

    code = pioctl(path, VIOC_FILE_CELL_NAME, &vi, follow);
    if (code) {
        if ((errno == EINVAL) || (errno == ENOENT))
            return 0;
        if (errno == ENOSYS)
            return 0;
    }
    return 1;
}

static char *format_rights(rights)
    int32 rights;
{
    static char buff[32];
    char *p;

    p = buff;

    if (rights & PRSFS_READ) {
        *p++ = 'r';
    }
    if (rights & PRSFS_LOOKUP) {
        *p++ = 'l';
    }
    if (rights & PRSFS_INSERT) {
        *p++ = 'i';
    }
    if (rights & PRSFS_DELETE) {
        *p++ = 'd';
    }
    if (rights & PRSFS_WRITE) {
        *p++ = 'w';
    }
    if (rights & PRSFS_LOCK) {
        *p++ = 'k';
    }
    if (rights & PRSFS_ADMINISTER) {
        *p++ = 'a';
    }
    if (rights & PRSFS_USR0) {
        *p++ = 'A';
    }
    if (rights & PRSFS_USR1) {
        *p++ = 'B';
    }
    if (rights & PRSFS_USR2) {
        *p++ = 'C';
    }
    if (rights & PRSFS_USR3) {
        *p++ = 'D';
    }
    if (rights & PRSFS_USR4) {
        *p++ = 'E';
    }
    if (rights & PRSFS_USR5) {
        *p++ = 'F';
    }
    if (rights & PRSFS_USR6) {
        *p++ = 'G';
    }
    if (rights & PRSFS_USR7) {
        *p++ = 'H';
    }
    *p = 0;

    return buff;
}

static int32 parse_rights(buffer, rights)
    char *buffer;
    int32 *rights;
{
    char *p;

    *rights = 0;

    p = buffer;

    while (*p) {
        switch (*p) {
          case 'r':
              *rights |= PRSFS_READ;
              break;
          case 'w':
              *rights |= PRSFS_WRITE;
              break;
          case 'i':
              *rights |= PRSFS_INSERT;
              break;
          case 'l':
              *rights |= PRSFS_LOOKUP;
              break;
          case 'd':
              *rights |= PRSFS_DELETE;
              break;
          case 'k':
              *rights |= PRSFS_LOCK;
              break;
          case 'a':
              *rights |= PRSFS_ADMINISTER;
              break;
          case 'A':
              *rights |= PRSFS_USR0;
              break;
          case 'B':
              *rights |= PRSFS_USR1;
              break;
          case 'C':
              *rights |= PRSFS_USR2;
              break;
          case 'D':
              *rights |= PRSFS_USR3;
              break;
          case 'E':
              *rights |= PRSFS_USR4;
              break;
          case 'F':
              *rights |= PRSFS_USR5;
              break;
          case 'G':
              *rights |= PRSFS_USR6;
              break;
          case 'H':
              *rights |= PRSFS_USR7;
              break;
          default:
              return EINVAL;
        }
        p++;
    }
    return 0;
}

static int32 canonical_parse_rights(buffer, rights)
    char *buffer;
    int32 *rights;
{
    char *p;

    *rights = 0;

    p = buffer;

    if (strcmp(p, "read") == 0)
        p = "rl";
    else if (strcmp(p, "write") == 0)
        p = "rlidwk";
    else if (strcmp(p, "all") == 0)
        p = "rlidwka";
    else if (strcmp(p, "mail") == 0)
        p = "lik";
    else if (strcmp(p, "none") == 0)
        p = "";

    return parse_rights(p, rights);
}

static int32 parse_acl(p, ph, nh)
    char *p;
    HV *ph, *nh;
{
    int32 pos, neg, acl;
    char *facl;
    char user[MAXSIZE];

    if (sscanf(p, "%d", &pos) != 1)
        return 0;
    while (*p && *p != '\n')
        p++;
    if (*p == '\n')
        p++;
    if (sscanf(p, "%d", &neg) != 1)
        return 0;
    while (*p && *p != '\n')
        p++;
    if (*p == '\n')
        p++;
    while (pos--) {
        if (sscanf(p, "%s %d", user, &acl) != 2)
            return 0;
        facl = format_rights(acl);
        safe_hv_store(ph, user, strlen(user), newSVpv(facl, strlen(facl)), 0);
        while (*p && *p != '\n')
            p++;
        if (*p == '\n')
            p++;
    }
    while (neg--) {
        if (sscanf(p, "%s %d", user, &acl) != 2)
            return 0;
        facl = format_rights(acl);
        safe_hv_store(nh, user, strlen(user), newSVpv(facl, strlen(facl)), 0);
        while (*p && *p != '\n')
            p++;
        if (*p == '\n')
            p++;
    }
    return 1;
}

static int parse_volstat(stats, space)
    HV *stats;
    char *space;
{
    struct VolumeStatus *status;
    char *name, *offmsg, *motd;
    char type[32];
    status = (VolumeStatus *) space;
    name = (char *) status + sizeof(*status);
    offmsg = name + strlen(name) + 1;
    motd = offmsg + strlen(offmsg) + 1;
    safe_hv_store(stats, "Name", 4, newSVpv(name, strlen(name)), 0);
    safe_hv_store(stats, "OffMsg", 6, newSVpv(offmsg, strlen(offmsg)), 0);
    safe_hv_store(stats, "Motd", 4, newSVpv(motd, strlen(motd)), 0);
    safe_hv_store(stats, "Vid", 3, newSViv(status->Vid), 0);
    safe_hv_store(stats, "ParentId", 8, newSViv(status->ParentId), 0);
    safe_hv_store(stats, "Online", 6, newSViv(status->Online), 0);
    safe_hv_store(stats, "InService", 9, newSViv(status->InService), 0);
    safe_hv_store(stats, "Blessed", 7, newSViv(status->Blessed), 0);
    safe_hv_store(stats, "NeedsSalvage", 12, newSViv(status->NeedsSalvage), 0);
    if (status->Type == ReadOnly)
        strcpy(type, "ReadOnly");
    else if (status->Type == ReadWrite)
        strcpy(type, "ReadWrite");
    else
        sprintf(type, "%d", status->Type);
    safe_hv_store(stats, "Type", 4, newSVpv(type, strlen(type)), 0);
    safe_hv_store(stats, "MinQuota", 8, newSViv(status->MinQuota), 0);
    safe_hv_store(stats, "MaxQuota", 8, newSViv(status->MaxQuota), 0);
    safe_hv_store(stats, "BlocksInUse", 11, newSViv(status->BlocksInUse), 0);
    safe_hv_store(stats, "PartBlocksAvail", 15, newSViv(status->PartBlocksAvail), 0);
    safe_hv_store(stats, "PartMaxBlocks", 13, newSViv(status->PartMaxBlocks), 0);
    return 1;
}
/* end of helper functions for FS class: */


/* helper functions for KAS class: */
static int parse_kaentryinfo(stats, ka)
    HV *stats;
    struct kaentryinfo *ka;
{
    char buffer[sizeof(struct kaident)];

    sprintf(buffer, "%s%s%s", ka->modification_user.name,
            ka->modification_user.instance[0] ? "." : "", ka->modification_user.instance);

    safe_hv_store(stats, "modification_user", 17, newSVpv(buffer, strlen(buffer)), 0);
    safe_hv_store(stats, "minor_version", 13, newSViv(ka->minor_version), 0);
    safe_hv_store(stats, "flags", 5, newSViv(ka->flags), 0);
    safe_hv_store(stats, "user_expiration", 15, newSViv(ka->user_expiration), 0);
    safe_hv_store(stats, "modification_time", 17, newSViv(ka->modification_time), 0);
    safe_hv_store(stats, "change_password_time", 20, newSViv(ka->change_password_time), 0);
    safe_hv_store(stats, "max_ticket_lifetime", 19, newSViv(ka->max_ticket_lifetime), 0);
    safe_hv_store(stats, "key_version", 11, newSViv(ka->key_version), 0);
    safe_hv_store(stats, "keyCheckSum", 11, newSVuv(ka->keyCheckSum), 0);
    safe_hv_store(stats, "misc_auth_bytes", 15, newSVuv(ka->misc_auth_bytes), 0);
    safe_hv_store(stats, "passwd_reuse", 12, newSViv(ka->reserved3), 0);
    /*               1234567890123456789012345 */
    return 1;
}

static int parse_ka_getstats(stats, dstats, kas, kad)
    HV *stats;
    HV *dstats;
    struct kasstats *kas;
    struct kadstats *kad;
{
    safe_hv_store(stats, "minor_version", 13, newSViv(kas->minor_version), 0);
    safe_hv_store(stats, "allocs", 6, newSViv(kas->allocs), 0);
    safe_hv_store(stats, "frees", 5, newSViv(kas->frees), 0);
    safe_hv_store(stats, "cpws", 4, newSViv(kas->cpws), 0);
    safe_hv_store(stats, "reserved1", 9, newSViv(kas->reserved1), 0);
    safe_hv_store(stats, "reserved2", 9, newSViv(kas->reserved2), 0);
    safe_hv_store(stats, "reserved3", 9, newSViv(kas->reserved3), 0);
    safe_hv_store(stats, "reserved4", 9, newSViv(kas->reserved4), 0);

    /* dynamic stats */

    safe_hv_store(dstats, "minor_version", 13, newSViv(kad->minor_version), 0);

    safe_hv_store(dstats, "host", 4, newSViv(kad->host), 0);
    safe_hv_store(dstats, "start_time", 10, newSViv(kad->start_time), 0);
    safe_hv_store(dstats, "hashTableUtilization", 20, newSViv(kad->hashTableUtilization), 0);
    safe_hv_store(dstats, "string_checks", 13, newSViv(kad->string_checks), 0);
    safe_hv_store(dstats, "reserved1", 9, newSViv(kad->reserved1), 0);
    safe_hv_store(dstats, "reserved2", 9, newSViv(kad->reserved2), 0);
    safe_hv_store(dstats, "reserved3", 9, newSViv(kad->reserved3), 0);
    safe_hv_store(dstats, "reserved4", 9, newSViv(kad->reserved4), 0);
    safe_hv_store(dstats, "Authenticate_requests", 21, newSViv(kad->Authenticate.requests), 0);
    safe_hv_store(dstats, "Authenticate_aborts", 19, newSViv(kad->Authenticate.aborts), 0);
    safe_hv_store(dstats, "ChangePassword_requests", 23,
             newSViv(kad->ChangePassword.requests), 0);
    safe_hv_store(dstats, "ChangePassword_aborts", 21, newSViv(kad->ChangePassword.aborts), 0);
    safe_hv_store(dstats, "GetTicket_requests", 18, newSViv(kad->GetTicket.requests), 0);
    safe_hv_store(dstats, "GetTicket_aborts", 16, newSViv(kad->GetTicket.aborts), 0);
    safe_hv_store(dstats, "CreateUser_requests", 19, newSViv(kad->CreateUser.requests), 0);
    safe_hv_store(dstats, "CreateUser_aborts", 17, newSViv(kad->CreateUser.aborts), 0);
    safe_hv_store(dstats, "SetPassword_requests", 20, newSViv(kad->SetPassword.requests), 0);
    safe_hv_store(dstats, "SetPassword_aborts", 18, newSViv(kad->SetPassword.aborts), 0);
    safe_hv_store(dstats, "SetFields_requests", 18, newSViv(kad->SetFields.requests), 0);
    safe_hv_store(dstats, "SetFields_aborts", 16, newSViv(kad->SetFields.aborts), 0);
    safe_hv_store(dstats, "DeleteUser_requests", 19, newSViv(kad->DeleteUser.requests), 0);
    safe_hv_store(dstats, "DeleteUser_aborts", 17, newSViv(kad->DeleteUser.aborts), 0);
    safe_hv_store(dstats, "GetEntry_requests", 17, newSViv(kad->GetEntry.requests), 0);
    safe_hv_store(dstats, "GetEntry_aborts", 15, newSViv(kad->GetEntry.aborts), 0);
    safe_hv_store(dstats, "ListEntry_requests", 18, newSViv(kad->ListEntry.requests), 0);
    safe_hv_store(dstats, "ListEntry_aborts", 16, newSViv(kad->ListEntry.aborts), 0);
    safe_hv_store(dstats, "GetStats_requests", 17, newSViv(kad->GetStats.requests), 0);
    safe_hv_store(dstats, "GetStats_aborts", 15, newSViv(kad->GetStats.aborts), 0);
    safe_hv_store(dstats, "GetPassword_requests", 20, newSViv(kad->GetPassword.requests), 0);
    safe_hv_store(dstats, "GetPassword_aborts", 18, newSViv(kad->GetPassword.aborts), 0);
    safe_hv_store(dstats, "GetRandomKey_requests", 21, newSViv(kad->GetRandomKey.requests), 0);
    safe_hv_store(dstats, "GetRandomKey_aborts", 19, newSViv(kad->GetRandomKey.aborts), 0);
    safe_hv_store(dstats, "Debug_requests", 14, newSViv(kad->Debug.requests), 0);
    safe_hv_store(dstats, "Debug_aborts", 12, newSViv(kad->Debug.aborts), 0);
    safe_hv_store(dstats, "UAuthenticate_requests", 22,
             newSViv(kad->UAuthenticate.requests), 0);
    safe_hv_store(dstats, "UAuthenticate_aborts", 20, newSViv(kad->UAuthenticate.aborts), 0);
    safe_hv_store(dstats, "UGetTicket_requests", 19, newSViv(kad->UGetTicket.requests), 0);
    safe_hv_store(dstats, "UGetTicket_aborts", 17, newSViv(kad->UGetTicket.aborts), 0);
    safe_hv_store(dstats, "Unlock_requests", 15, newSViv(kad->Unlock.requests), 0);
    safe_hv_store(dstats, "Unlock_aborts", 13, newSViv(kad->Unlock.aborts), 0);
    safe_hv_store(dstats, "LockStatus_requests", 19, newSViv(kad->LockStatus.requests), 0);
    safe_hv_store(dstats, "LockStatus_aborts", 17, newSViv(kad->LockStatus.aborts), 0);
    /*               1234567890123456789012345 */
    return 1;
}

static int parse_ka_debugInfo(stats, ka)
    HV *stats;
    struct ka_debugInfo *ka;
{
    char buff[1024];
    int i;

    safe_hv_store(stats, "lastOperation", 13,
             newSVpv(ka->lastOperation, strlen(ka->lastOperation)), 0);

    safe_hv_store(stats, "lastAuth", 7, newSVpv(ka->lastAuth, strlen(ka->lastAuth)), 0);
    safe_hv_store(stats, "lastUAuth", 9, newSVpv(ka->lastUAuth, strlen(ka->lastUAuth)), 0);

    safe_hv_store(stats, "lastTGS", 7, newSVpv(ka->lastTGS, strlen(ka->lastTGS)), 0);
    safe_hv_store(stats, "lastUTGS", 8, newSVpv(ka->lastUTGS, strlen(ka->lastUTGS)), 0);

    safe_hv_store(stats, "lastAdmin", 9, newSVpv(ka->lastAdmin, strlen(ka->lastAdmin)), 0);
    safe_hv_store(stats, "lastTGSServer", 13,
             newSVpv(ka->lastTGSServer, strlen(ka->lastTGSServer)), 0);
    safe_hv_store(stats, "lastUTGSServer", 14,
             newSVpv(ka->lastUTGSServer, strlen(ka->lastUTGSServer)), 0);

    safe_hv_store(stats, "minorVersion", 12, newSViv(ka->minorVersion), 0);
    safe_hv_store(stats, "host", 4, newSViv(ka->host), 0);
    safe_hv_store(stats, "startTime", 9, newSViv(ka->startTime), 0);
    safe_hv_store(stats, "noAuth", 6, newSViv(ka->noAuth), 0);
    safe_hv_store(stats, "lastTrans", 9, newSViv(ka->lastTrans), 0);
    safe_hv_store(stats, "nextAutoCPW", 11, newSViv(ka->nextAutoCPW), 0);
    safe_hv_store(stats, "updatesRemaining", 16, newSViv(ka->updatesRemaining), 0);
    safe_hv_store(stats, "dbHeaderRead", 12, newSViv(ka->dbHeaderRead), 0);

    safe_hv_store(stats, "dbVersion", 9, newSViv(ka->dbVersion), 0);
    safe_hv_store(stats, "dbFreePtr", 9, newSViv(ka->dbFreePtr), 0);
    safe_hv_store(stats, "dbEofPtr", 8, newSViv(ka->dbEofPtr), 0);
    safe_hv_store(stats, "dbKvnoPtr", 9, newSViv(ka->dbKvnoPtr), 0);

    safe_hv_store(stats, "dbSpecialKeysVersion", 20, newSViv(ka->dbSpecialKeysVersion), 0);

    safe_hv_store(stats, "cheader_lock", 12, newSViv(ka->cheader_lock), 0);
    safe_hv_store(stats, "keycache_lock", 13, newSViv(ka->keycache_lock), 0);
    safe_hv_store(stats, "kcVersion", 9, newSViv(ka->kcVersion), 0);
    safe_hv_store(stats, "kcSize", 6, newSViv(ka->kcSize), 0);

    safe_hv_store(stats, "reserved1", 9, newSViv(ka->reserved1), 0);
    safe_hv_store(stats, "reserved2", 9, newSViv(ka->reserved2), 0);
    safe_hv_store(stats, "reserved3", 9, newSViv(ka->reserved3), 0);
    safe_hv_store(stats, "reserved4", 9, newSViv(ka->reserved4), 0);

    if (ka->kcUsed > KADEBUGKCINFOSIZE) {
        safe_hv_store(stats, "actual_kcUsed", 13, newSViv(ka->kcUsed), 0);
        ka->kcUsed = KADEBUGKCINFOSIZE;
    }

    safe_hv_store(stats, "kcUsed", 6, newSViv(ka->kcUsed), 0);

    for (i = 0; i < ka->kcUsed; i++) {
        sprintf(buff, "kcInfo_used%d", i);
        safe_hv_store(stats, buff, strlen(buff), newSViv(ka->kcInfo[i].used), 0);

        sprintf(buff, "kcInfo_kvno%d", i);
        safe_hv_store(stats, buff, strlen(buff), newSViv(ka->kcInfo[i].kvno), 0);

        sprintf(buff, "kcInfo_primary%d", i);
        safe_hv_store(stats, buff, strlen(buff),
                 newSViv((unsigned char) ka->kcInfo[i].primary), 0);

        sprintf(buff, "kcInfo_keycksum%d", i);
        safe_hv_store(stats, buff, strlen(buff),
                 newSViv((unsigned char) ka->kcInfo[i].keycksum), 0);

        sprintf(buff, "kcInfo_principal%d", i);
        safe_hv_store(stats, buff, strlen(buff),
                 newSVpv(ka->kcInfo[i].principal, strlen(ka->kcInfo[i].principal)), 0);
    }
    /*               1234567890123456789012345 */
    return 1;
}
/* end of helper functions for KAS class: */



/************************ Start of XS stuff **************************/
/* PROTOTYPES: DISABLE added by leg@andrew, 10/7/96 */

MODULE = AFS    PACKAGE = AFS   PREFIX = fs_
VERSIONCHECK: DISABLE
PROTOTYPES: DISABLE

void
fs_pioctl(path,setpath,op,in,setin,setout,follow)
        char *  path
        int32   setpath
        int32   op
        SV *    in
        int32   setin
        int32   setout
        int32   follow
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        STRLEN insize;

        if (!setpath)
            path = NULL;
        if (setout) {
            space[0] = '\0';
            vi.out_size = MAXSIZE;
            vi.out = space;
        }
        else {
            vi.out_size = 0;
            vi.out = 0;
        }

        if (setin) {
            vi.in = (char *) SvPV(ST(2), insize);
            vi.in_size = insize;
        }
        else {
            vi.in = 0;
            vi.in_size = 0;
        }

        code = pioctl(path, op, &vi, follow);
        SETCODE(code);
        if (code == 0 && setout) {
            EXTEND(sp, 1);
            printf("out_size = %d\n", vi.out_size);
            PUSHs(sv_2mortal(newSVpv(vi.out, vi.out_size)));
        }
    }

void
fs_getvolstats(dir,follow=1)
        char *  dir
        int32   follow
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        HV *stats;

        vi.out_size = MAXSIZE;
        vi.in_size = 0;
        vi.out = space;
        code = pioctl(dir, VIOCGETVOLSTAT, &vi, follow);
        SETCODE(code);
        if (code == 0) {
            stats = newHV();
            if (parse_volstat(stats, space)) {
                EXTEND(sp, 1);
                PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
            }
            else {
                hv_undef(stats);
            }
        }
    }

void
fs_whereis(dir,ip=0,follow=1)
        char *  dir
        int32   ip
        int32   follow
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];

        vi.out_size = MAXSIZE;
        vi.in_size = 0;
        vi.out = space;
        code = pioctl(dir, VIOCWHEREIS, &vi, follow);
        SETCODE(code);
        if (code == 0) {
            struct in_addr *hosts = (struct in_addr *) space;
            struct hostent *ht;
            int i;
            char *h;
            for (i = 0; i < MAXHOSTS; i++) {
                if (hosts[i].s_addr == 0)
                    break;
                if (ip == 0) {
                    ht = gethostbyaddr((const char *) &hosts[i], sizeof(struct in_addr), AF_INET);
                    if (ht == NULL)
                        h = (char *) inet_ntoa(hosts[i]);
                    else
                        h = ht->h_name;
                }
                else {
                    h = (char *) inet_ntoa(hosts[i]);
                }
                XPUSHs(sv_2mortal(newSVpv(h, strlen(h))));
            }

        }
    }

void
fs_checkservers(fast,cell=0,ip=0)
        int32   fast
        char *  cell
        int32   ip
    PPCODE:
    {
        struct chservinfo checkserv;
        struct ViceIoctl vi;
        int32 code, *num;
        char space[MAXSIZE];

        checkserv.magic = 0x12345678;
        checkserv.tflags = 2;
        if (fast)
            checkserv.tflags |= 0x1;
        if (cell) {
            checkserv.tflags &= ~2;
            strcpy(checkserv.tbuffer, cell);
            checkserv.tsize = strlen(cell);
        }
        checkserv.tinterval = -1;

        vi.out_size = MAXSIZE;
        vi.in_size = sizeof(checkserv);
        vi.in = (char *) &checkserv;
        vi.out = space;

        code = pioctl(0, VIOCCKSERV, &vi, 1);
        num = (int32 *) space;
        SETCODE(code);
        if (code == 0 && *num > 0) {
            struct in_addr *hosts = (struct in_addr *) (space + sizeof(int32));
            struct hostent *ht;
            int i;
            char *h;
            for (i = 0; i < MAXHOSTS; i++) {
                if (hosts[i].s_addr == 0)
                    break;
                if (ip == 0) {
                    ht = gethostbyaddr((const char *) &hosts[i], sizeof(struct in_addr), AF_INET);
                    if (ht == NULL)
                        h = (char *) inet_ntoa(hosts[i]);
                    else
                        h = ht->h_name;
                }
                else {
                    h = (char *) inet_ntoa(hosts[i]);
                }
                XPUSHs(sv_2mortal(newSVpv(h, strlen(h))));
            }

        }
    }

void
fs_getcell(in_index,ip=0)
        int32   in_index
        int32   ip
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code, max = OMAXHOSTS;
        int32 *lp;
        char space[MAXSIZE];

        lp = (int32 *) space;
        *lp++ = in_index;
        *lp = 0x12345678;
        vi.in_size = sizeof(int32) * 2;
        vi.in = (char *) space;
        vi.out_size = MAXSIZE;
        vi.out = space;
        code = pioctl(NULL, VIOCGETCELL, &vi, 1);
        SETCODE(code);
        if (code == 0) {
            struct in_addr *hosts = (struct in_addr *) space;
            /* int32 *magic = (int32 *) space; */
            struct hostent *ht;
            int i;
            char *h;
            /*if (*magic == 0x12345678) { */
            max = MAXHOSTS;
            /*            hosts++; */
            /*    } */
            h = (char *) hosts + max * sizeof(int32);
            XPUSHs(sv_2mortal(newSVpv(h, strlen(h))));
            for (i = 0; i < max; i++) {
                if (hosts[i].s_addr == 0)
                    break;
                if (ip == 0) {
                    ht = gethostbyaddr((const char *) &hosts[i], sizeof(struct in_addr), AF_INET);
                    if (ht == NULL)
                        h = (char *) inet_ntoa(hosts[i]);
                    else
                        h = ht->h_name;
                }
                else {
                    h = (char *) inet_ntoa(hosts[i]);
                }
                XPUSHs(sv_2mortal(newSVpv(h, strlen(h))));
            }

        }
    }

void
fs__get_server_version(port,hostName="localhost",verbose=0)
        short port
        char *hostName
        int32 verbose
    CODE:
    {
#if defined(AFS_3_4)
        not_here("AFS::Utils::get_server_version");
#else
        struct sockaddr_in taddr;
        struct in_addr hostAddr;
        struct hostent *th;
        int32 host;
        short port_num = htons(port);
        int32 length = 64;
        int32 code;
        char version[64];
        int s;

          /* lookup host */
        if (hostName) {
            th = (struct hostent *) hostutil_GetHostByName(hostName);
            if (!th) {
                warn("rxdebug: host %s not found in host table\n", hostName);
                SETCODE(EFAULT);
                XSRETURN_UNDEF;
            }
            /* bcopy(th->h_addr, &host, sizeof(int32)); */
            Copy(th->h_addr, &host, th->h_length, char);
        }
        else
            host = htonl(0x7f000001);   /* IP localhost */

        hostAddr.s_addr = host;
        if (verbose)
            printf("Trying %s (port %d):\n", inet_ntoa(hostAddr), ntohs(port_num));

        s = socket(AF_INET, SOCK_DGRAM, 0);
        taddr.sin_family = AF_INET;
        taddr.sin_port = 0;
        taddr.sin_addr.s_addr = 0;

        code = bind(s, (struct sockaddr *) &taddr, sizeof(struct sockaddr_in));
        SETCODE(code);
        if (code) {
            perror("bind");
            XSRETURN_UNDEF;
        }

        code = rx_GetServerVersion(s, host, port_num, length, version);
        ST(0) = sv_newmortal();
        if (code < 0) {
            SETCODE(code);
        }
        else {
            sv_setpv(ST(0), version);
        }
#endif
    }

void
fs_get_syslib_version()
    CODE:
    {
        extern char *AFSVersion;

        ST(0) = sv_newmortal();
        sv_setpv(ST(0), AFSVersion);
    }

void
fs_XSVERSION()
    CODE:
    {
        ST(0) = sv_newmortal();
        sv_setpv(ST(0), xs_version);
    }

void
fs_sysname(newname=0)
        char *  newname
    CODE:
    {
        struct ViceIoctl vi;
        int32 code, set;
        char space[MAXSIZE];

        set = (newname && *newname);

        vi.in = space;
        bcopy(&set, space, sizeof(set));
        vi.in_size = sizeof(set);
        if (set) {
            strcpy(space + sizeof(set), newname);
            vi.in_size += strlen(newname) + 1;
        }
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(NULL, VIOC_AFS_SYSNAME, &vi, 0);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setpv(ST(0), space + sizeof(set));
        }
    }

void
fs_getcrypt()
    CODE:
    {
#ifdef VIOC_GETRXKCRYPT
        struct ViceIoctl vi;
        int32 code, flag;
        char space[MAXSIZE];

        vi.in_size = 0;
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(0, VIOC_GETRXKCRYPT, &vi, 1);
        SETCODE(code);

        ST(0) = sv_newmortal();
        if (code == 0) {
            bcopy((char *) space, &flag, sizeof(int32));
            sv_setiv(ST(0), flag);
        }
#else
        not_here("AFS::CM::getcrypt");
#endif
    }

int32
fs_setcrypt(as)
        char *as
    CODE:
    {
#ifdef VIOC_SETRXKCRYPT
        struct ViceIoctl vi;
        int32 code, flag;

        if (strcmp(as, "on") == 0)
            flag = 1;
        else if (strcmp(as, "off") == 0)
            flag = 0;
        else {
            warn("setcrypt: %s must be \"on\" or \"off\".\n", as);
            SETCODE(EINVAL);
            XSRETURN_UNDEF;
        }

        vi.in = (char *) &flag;
        vi.in_size = sizeof(flag);
        vi.out_size = 0;
        code = pioctl(0, VIOC_SETRXKCRYPT, &vi, 1);
        SETCODE(code);
        RETVAL = (code == 0);
#else
        not_here("AFS::CM::setcrypt");
#endif
    }
    OUTPUT:
        RETVAL

void
fs_whichcell(dir,follow=1)
        char *  dir
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];

        vi.in_size = 0;
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(dir, VIOC_FILE_CELL_NAME, &vi, follow);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setpv(ST(0), space);
        }
    }

void
fs_lsmount(path,follow=1)
        char *  path
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        char *dir, *file;
        char parent[1024];

        if (strlen(path) > (sizeof(parent) - 1))
            code = EINVAL;
        else {
            strcpy(parent, path);
            file = strrchr(parent, '/');
            if (file) {
                dir = parent;
                *file++ = '\0';
            }
            else {
                dir = ".";
                file = parent;
            }

            vi.in_size = strlen(file) + 1;
            vi.in = file;
            vi.out_size = MAXSIZE;
            vi.out = (caddr_t) space;
            code = pioctl(dir, VIOC_AFS_STAT_MT_PT, &vi, follow);
        }

        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setpv(ST(0), space);
        }
    }

int32
fs_rmmount(path)
        char *  path
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char *file, *dir;
        char parent[1024];

        if (strlen(path) > (sizeof(parent) - 1))
            code = EINVAL;
        else {
            strcpy(parent, path);
            file = strrchr(parent, '/');
            if (file) {
                dir = parent;
                *file++ = '\0';
            }
            else {
                dir = ".";
                file = parent;
            }

            vi.in_size = strlen(file) + 1;
            vi.in = file;
            vi.out_size = 0;
            code = pioctl(dir, VIOC_AFS_DELETE_MT_PT, &vi, 0);
        }

        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_flushvolume(path,follow=1)
        char *  path
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];

        vi.in_size = 0;
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(path, VIOC_FLUSHVOLUME, &vi, follow);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_flush(path,follow=1)
        char *  path
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];

        vi.in_size = 0;
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(path, VIOCFLUSH, &vi, follow);

        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_flushcb(path,follow=1)
        char *  path
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];

        vi.in_size = 0;
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(path, VIOCFLUSHCB, &vi, follow);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_setquota(path,newquota,follow=1)
        char *  path
        int32   newquota
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        struct VolumeStatus *status;
        char *input;

        vi.in_size = sizeof(*status) + 3;
        vi.in = space;
        vi.out_size = MAXSIZE;
        vi.out = space;
        status = (VolumeStatus *) space;
        status->MinQuota = -1;
        status->MaxQuota = newquota;

        input = (char *) status + sizeof(*status);
        *(input++) = '\0';              /* never set name: this call doesn't change vldb */
        *(input++) = '\0';              /* offmsg  */
        *(input++) = '\0';              /* motd  */

        code = pioctl(path, VIOCSETVOLSTAT, &vi, follow);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

void
fs_getquota(path,follow=1)
        char *  path
        int32   follow
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        struct VolumeStatus *status;

        vi.out_size = MAXSIZE;
        vi.in_size = 0;
        vi.in = 0;
        vi.out = space;

        code = pioctl(path, VIOCGETVOLSTAT, &vi, follow);
        SETCODE(code);
        if (code == 0) {
            status = (VolumeStatus *)space;
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSViv(status->MaxQuota)));
        }
    }

int32
fs_mkmount(mountp,volume,rw=0,cell=0)
        char *  mountp
        char *  volume
        int32   rw
        char *  cell
    CODE:
    {
        char buffer[1024];
        char parent[1024];
        int32 code = 0;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        if (strlen(mountp) > (sizeof(parent) - 1))
            code = EINVAL;
        else {
            char *p;
            strcpy(parent, mountp);
            p = strrchr(parent, '/');
            if (p)
                *p = 0;
            else
                strcpy(parent, ".");
            if (!isafs(parent))
                code = EINVAL;
        }

        if (code == 0) {
            sprintf(buffer, "%c%s%s%s.",
                    rw ? '%' : '#', cell ? cell : "", cell ? ":" : "", volume);
            code = symlink(buffer, mountp);
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_checkvolumes()
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;

        vi.in_size = 0;
        vi.out_size = 0;
        code = pioctl(NULL, VIOCCKBACK, &vi, 0);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_checkconn()
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        int32 status;

        vi.in_size = 0;
        vi.out_size = sizeof(status);
        vi.out = (caddr_t) & status;
        code = pioctl(NULL, VIOCCKCONN, &vi, 0);
        SETCODE(code);
        RETVAL = (status == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_getcacheparms()
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        int32 stats[16];

        vi.in_size = 0;
        vi.in = 0;
        vi.out_size = sizeof(stats);
        vi.out = (char *) stats;
        code = pioctl(NULL, VIOCGETCACHEPARMS, &vi, 0);

        SETCODE(code);
        if (code == 0) {
            EXTEND(sp, 2);
            PUSHs(sv_2mortal(newSViv(stats[0])));
            PUSHs(sv_2mortal(newSViv(stats[1])));
        }
    }

int32
fs_setcachesize(size)
        int32   size
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;

        vi.in_size = sizeof(size);;
        vi.in = (char *) &size;
        vi.out_size = 0;
        vi.out = 0;
        code = pioctl(NULL, VIOCSETCACHESIZE, &vi, 0);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_unlog()
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;

        vi.in_size = 0;
        vi.out_size = 0;
        code = pioctl(NULL, VIOCUNLOG, &vi, 0);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_getfid(path,follow=1)
        char *  path
        int32   follow
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        struct VenusFid vf;

        vi.in_size = 0;
        vi.out_size = sizeof(vf);
        vi.out = (char *) &vf;
        code = pioctl(path, VIOCGETFID, &vi, follow);
        SETCODE(code);
        if (code == 0) {
            EXTEND(sp, 4);
            PUSHs(sv_2mortal(newSViv(vf.Cell)));
            PUSHs(sv_2mortal(newSViv(vf.Fid.Volume)));
            PUSHs(sv_2mortal(newSViv(vf.Fid.Vnode)));
            PUSHs(sv_2mortal(newSViv(vf.Fid.Unique)));
        }
    }

int32
fs_isafs(path,follow=1)
        char *  path
        int32   follow
    CODE:
    {
        int32 code;
        RETVAL = isafs(path, follow);
        if (!RETVAL)
            code = errno;
        else
            code = 0;
        SETCODE(code);
    }
    OUTPUT:
        RETVAL

int32
fs_cm_access(path,perm="read",follow=1)
        char *  path
        char *  perm
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        int32 rights;

        code = canonical_parse_rights(perm, &rights);
        if (code == 0) {
            code = vi.in_size = sizeof(rights);
            vi.in = (char *) &rights;
            vi.out_size = 0;
            vi.out = 0;
            code = pioctl(path, VIOCACCESS, &vi, follow);
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
fs_ascii2rights(perm)
        char *  perm
    CODE:
    {
        int32 code, rights = -1;

        code = canonical_parse_rights(perm, &rights);
        SETCODE(code);

        if (code != 0)
            rights = -1;
        RETVAL = rights;
    }
    OUTPUT:
        RETVAL

void
fs_rights2ascii(perm)
       int32   perm
    CODE:
    {
        char *p;
        p = format_rights(perm);

        SETCODE(0);

        ST(0) = sv_newmortal();
        sv_setpv(ST(0), p);
    }

void
fs_crights(perm)
        char *  perm
    CODE:
    {
        int32 code;
        int32 rights;

        code = canonical_parse_rights(perm, &rights);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setpv(ST(0), format_rights(rights));
        }
    }

void
fs_getcellstatus(cell=0)
        char *  cell
    PPCODE:
    {
        struct ViceIoctl vi;
        struct afsconf_cell info;
        int32 code, flags;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        code = internal_GetCellInfo(cell, 0, &info);
        if (code != 0) {
            XSRETURN_UNDEF;
        }
        else {
            vi.in_size = strlen(info.name) + 1;
            vi.in = info.name;
            vi.out_size = sizeof(flags);
            vi.out = (char *) &flags;
            code = pioctl(0, VIOC_GETCELLSTATUS, &vi, 0);
            SETCODE(code);
            if (code == 0) {
                EXTEND(sp, 1);
                PUSHs(sv_2mortal(newSViv((flags & 0x2) == 0)));
                XSRETURN(1);
            }
            else {
                XSRETURN_UNDEF;
            }
        }
    }

int32
fs_setcellstatus(setuid_allowed,cell=0)
        int32   setuid_allowed
        char *  cell
    PPCODE:
    {
        struct ViceIoctl vi;
        struct afsconf_cell info;
        int32 code;
        struct set_status {
            int32 status;
            int32 reserved;
            char cell[MAXCELLCHARS];
        } set;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        code = internal_GetCellInfo(cell, 0, &info);
        if (code != 0) {
            XSRETURN_UNDEF;
        }
        else {
            set.reserved = 0;
            strcpy(set.cell, info.name);
            if (setuid_allowed)
                set.status = 0;
            else
                set.status = 0x2;
            vi.in_size = sizeof(set);
            vi.in = (char *) &set;
            vi.out_size = 0;
            vi.out = (char *) 0;
            code = pioctl(0, VIOC_SETCELLSTATUS, &vi, 0);
            SETCODE(code);
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSViv(code == 0)));
        }
    }

void
fs_wscell()
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];

        vi.in_size = 0;
        vi.out_size = MAXSIZE;
        vi.out = (caddr_t) space;
        code = pioctl(NULL, VIOC_GET_WS_CELL, &vi, 0);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setpv(ST(0), space);
        }
    }

void
fs__getacl(dir,follow=1)
        char *  dir
        int32   follow
    PPCODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        HV *ph, *nh;
        vi.out_size = MAXSIZE;
        vi.in_size = 0;
        vi.out = space;
        code = pioctl(dir, VIOCGETAL, &vi, follow);
        SETCODE(code);

        if (code == 0) {
            ph = newHV();
            nh = newHV();

            if (parse_acl(space, ph, nh)) {
                AV *acl;
                acl = newAV();
                av_store(acl, 0, newRV_noinc((SV *) ph));
                av_store(acl, 1, newRV_noinc((SV *) nh));
                EXTEND(sp, 1);
                PUSHs(sv_bless(sv_2mortal(newRV_noinc((SV *) acl)), gv_stashpv("AFS::ACL", 1)));
            }
            else {
                hv_undef(ph);
                hv_undef(nh);
            }
        }
    }

int32
fs_setacl(dir,acl,follow=1)
        char *  dir
        SV *    acl
        int32   follow
    CODE:
    {
        struct ViceIoctl vi;
        int32 code;
        char space[MAXSIZE];
        char acls[MAXSIZE], *p;
        HV *ph, *nh;
        AV *object;
        SV **sv;
        HE *he;
        int plen, nlen;
        int32 rights;
        char *name, *perm;

        if (sv_isa(acl, "AFS::ACL") && SvROK(acl)
            && (SvTYPE(SvRV(acl)) == SVt_PVAV)
            ) {
            object = (AV *) SvRV(acl);
        }
        else {
            croak("acl is not of type AFS::ACL");
        }

        ph = nh = NULL;
        sv = av_fetch(object, 0, 0);

        if (sv) {
            SV *sph = *sv;
            if (SvROK(sph) && (SvTYPE(SvRV(sph)) == SVt_PVHV)) {
                ph = (HV *) SvRV(sph);
            }
        }

        sv = av_fetch(object, 1, 0);

        if (sv) {
            SV *snh = *sv;
            if (SvROK(snh) && (SvTYPE(SvRV(snh)) == SVt_PVHV)) {
                nh = (HV *) SvRV(snh);
            }
        }

        plen = nlen = 0;

        p = acls;
        *p = 0;
        code = 0;

        if (ph) {
            hv_iterinit(ph);

            while ((code == 0) && (he = hv_iternext(ph))) {
                I32 len;
                name = hv_iterkey(he, &len);
                perm = SvPV(hv_iterval(ph, he), PL_na);
                code = canonical_parse_rights(perm, &rights);
                if (code == 0 && rights && !name_is_numeric(name)) {
                    sprintf(p, "%s\t%d\n", name, rights);
                    p += strlen(p);
                    plen++;
                }
            }
        }

        if (code == 0 && nh) {
            hv_iterinit(nh);
            while ((code == 0) && (he = hv_iternext(nh))) {
                I32 len;
                name = hv_iterkey(he, &len);
                perm = SvPV(hv_iterval(nh, he), PL_na);
                code = canonical_parse_rights(perm, &rights);
                if (code == 0 && rights && !name_is_numeric(name)) {
                    sprintf(p, "%s\t%d\n", name, rights);
                    p += strlen(p);
                    nlen++;
                }
            }
        }

        if (code == 0) {
            sprintf(space, "%d\n%d\n%s", plen, nlen, acls);
            vi.in_size = strlen(space) + 1;
            vi.in = space;
            vi.out_size = 0;
            vi.out = 0;
            code = pioctl(dir, VIOCSETAL, &vi, follow);
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL


MODULE = AFS            PACKAGE = AFS::KTC_PRINCIPAL    PREFIX = ktcp_

AFS::KTC_PRINCIPAL
ktcp__new(class,name,...)
        char *  class
        char *  name
    PPCODE:
    {
        struct ktc_principal *p;
        int32 code;

        if (items != 2 && items != 4)
            croak("Usage: AFS::KTC_PRINCIPAL->new(USER.INST@CELL) or AFS::KTC_PRINCIPAL->new(USER, INST, CELL)");

        p = (struct ktc_principal *) safemalloc(sizeof(struct ktc_principal));
        p->name[0] = '\0';
        p->instance[0] = '\0';
        p->cell[0] = '\0';

        if (items == 2) {
            code = ka_ParseLoginName(name, p->name, p->instance, p->cell);
        }
        else {
            STRLEN nlen, ilen, clen;
            char *i = (char *) SvPV(ST(2), ilen);
            char *c = (char *) SvPV(ST(3), clen);
            nlen = strlen(name);
            if (nlen > MAXKTCNAMELEN - 1 || ilen > MAXKTCNAMELEN - 1 || clen > MAXKTCREALMLEN - 1)
                code = KABADNAME;
            else {
                strcpy(p->name, name);
                strcpy(p->instance, i);
                strcpy(p->cell, c);
                code = 0;
            }
        }

        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setref_pv(ST(0), "AFS::KTC_PRINCIPAL", (void *) p);
        }
        else {
            safefree(p);
        }

        XSRETURN(1);
    }

void
ktcp_set(p,name,...)
        AFS::KTC_PRINCIPAL      p
        char *  name
    PPCODE:
    {
        int32 code;

        if (items != 2 && items != 4)
            croak("Usage: set($user.$inst@$cell) or set($user,$inst,$cell)");

        if (items == 2) {
            code = ka_ParseLoginName(name, p->name, p->instance, p->cell);
        }
        else {
            STRLEN nlen, ilen, clen;
            char *i = (char *) SvPV(ST(2), ilen);
            char *c = (char *) SvPV(ST(3), clen);
            nlen = strlen(name);
            if (nlen > MAXKTCNAMELEN - 1 || ilen > MAXKTCNAMELEN - 1 || clen > MAXKTCREALMLEN - 1)
                code = KABADNAME;
            else {
                strcpy(p->name, name);
                strcpy(p->instance, i);
                strcpy(p->cell, c);
                code = 0;
            }
        }

        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

int32 
ktcp_DESTROY(p)
        AFS::KTC_PRINCIPAL      p
    CODE:
    {
        safefree(p);
        # SETCODE(0);   this spoils the ERROR code
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

void
ktcp_name(p,name=0)
        AFS::KTC_PRINCIPAL      p
        char *  name
    PPCODE:
    {
        int32 code = 0;

        if (name != 0) {
            int nlen = strlen(name);
            if (nlen > MAXKTCNAMELEN - 1)
                code = KABADNAME;
            else
                strcpy(p->name, name);
            SETCODE(code);
        }
        if (code == 0) {
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSVpv(p->name, strlen(p->name))));
        }
    }

void
ktcp_instance(p,instance=0)
        AFS::KTC_PRINCIPAL      p
        char *  instance
    PPCODE:
    {
        int32 code = 0;

        if (instance != 0) {
            int ilen = strlen(instance);
            if (ilen > MAXKTCNAMELEN - 1)
                code = KABADNAME;
            else
                strcpy(p->instance, instance);
            SETCODE(code);
        }

        if (code == 0) {
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSVpv(p->instance, strlen(p->instance))));
        }
    }

void
ktcp_cell(p,cell=0)
        AFS::KTC_PRINCIPAL      p
        char *  cell
    PPCODE:
    {
        int32 code = 0;

        if (cell != 0) {
            int clen = strlen(cell);
            if (clen > MAXKTCREALMLEN - 1)
                code = KABADNAME;
            else
                strcpy(p->cell, cell);
            SETCODE(code);
        }
        if (code == 0) {
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSVpv(p->cell, strlen(p->cell))));
        }
    }

void
ktcp_principal(p)
        AFS::KTC_PRINCIPAL      p
    PPCODE:
    {
        int32 code = 0;

        char buffer[MAXKTCNAMELEN + MAXKTCNAMELEN + MAXKTCREALMLEN + 3];
        sprintf(buffer, "%s%s%s%s%s", p->name,
                p->instance[0] ? "." : "", p->instance, p->cell[0] ? "@" : "", p->cell);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSVpv(buffer, strlen(buffer))));
        SETCODE(code);
    }


MODULE = AFS            PACKAGE = AFS::KTC_TOKEN        PREFIX = ktct_

int32
ktct_DESTROY(t)
        AFS::KTC_TOKEN  t
    CODE:
    {
        if (t && t != &the_null_token) safefree(t);
        # SETCODE(0);   this spoils the ERROR code
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

int32
ktct_startTime(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSViv(t->startTime)));
    }

int32
ktct_endTime(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSViv(t->endTime)));
    }

int32
ktct_kvno(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSViv(t->kvno)));
    }

int32
ktct_ticketLen(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSViv(t->ticketLen)));
    }

void
ktct_ticket(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv(t->ticket,t->ticketLen)));
    }

void
ktct_sessionKey(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        struct ktc_encryptionKey *key;
        SV *sv;
        key = (struct ktc_encryptionKey *) safemalloc(sizeof(*key));

        *key = t->sessionKey;
        sv = sv_newmortal();
        EXTEND(sp, 1);
        sv_setref_pv(sv, "AFS::KTC_EKEY", (void *) key);
        PUSHs(sv);
    }

void
ktct_string(t)
        AFS::KTC_TOKEN  t
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char*)t,sizeof(*t))));
    }


MODULE = AFS            PACKAGE = AFS::KTC_EKEY         PREFIX = ktck_

int32
ktck_DESTROY(k)
        AFS::KTC_EKEY   k
    CODE:
    {
        safefree(k);
        # SETCODE(0);   this spoils the ERROR code
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

void
ktck_string(k)
        AFS::KTC_EKEY   k
    PPCODE:
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char*)k,sizeof(*k))));
    }


MODULE = AFS     PACKAGE = AFS::VOS       PREFIX = vos_

AFS::VOS
vos_new(class=0, verb=Nullsv, timeout=Nullsv, noauth=Nullsv, localauth=Nullsv, tcell=NULL, crypt=Nullsv)
        char * class
        SV *   verb
        SV *   timeout
        SV *   noauth
        SV *   localauth
        char * tcell
        SV *   crypt
    PREINIT:
        int32 code;
        extern int verbose;
        int itimeout, inoauth, ilocalauth, icrypt;

    PPCODE:
    {
        if (!verb) {
            verb = newSViv(0);
        }
        if (!timeout) {
            timeout = newSViv(90);
        }
        if (!noauth) {
            noauth = newSViv(0);
        }
        if (!localauth) {
            localauth = newSViv(0);
        }
        if (!crypt) {
            crypt = newSViv(0);
        }
        if (tcell && (tcell[0] == '\0' || tcell[0] == '0'))
            tcell = NULL;
        if ((verb) && (!SvIOKp(verb))) {
            char buffer[256];
            sprintf(buffer, "Flag \"verb\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        verbose = SvIV(verb);

        if ((timeout) && (!SvIOKp(timeout))) {
            char buffer[256];
            sprintf(buffer, "Flag \"timeout\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        itimeout = SvIV(timeout);

        if ((noauth) && (!SvIOKp(noauth))) {
            char buffer[256];
            sprintf(buffer, "Flag \"noauth\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        inoauth = SvIV(noauth);

        if ((localauth) && (!SvIOKp(localauth))) {
            char buffer[256];
            sprintf(buffer, "Flag \"localauth\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        ilocalauth = SvIV(localauth);

        if ((crypt) && (!SvIOKp(crypt))) {
            char buffer[256];
            sprintf(buffer, "Flag \"crypt\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        icrypt = SvIV(crypt);

                /* Initialize the ubik_client connection */
        rx_SetRxDeadTime(itimeout);      /* timeout seconds inactivity before declared dead */

        cstruct = (struct ubik_client *) 0;

        if (icrypt)                      /* -crypt specified */
            vsu_SetCrypt(1);
        code = internal_vsu_ClientInit((inoauth != 0),
                                       AFSDIR_CLIENT_ETC_DIRPATH, tcell, ilocalauth,
                                       &cstruct, UV_SetSecurity);
        if (code == 0) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AFS::VOS", (void *) cstruct);
            XSRETURN(1);
        }
        else {
            XSRETURN_UNDEF;
        }
    } 

int32
vos__DESTROY(self)
        AFS::VOS self
    PREINIT:
        int32 code;
    CODE:
    {
        code = ubik_ClientDestroy((struct ubik_client *) self);
        /* printf("DEBUG-23 %d \n", code); */
        SETCODE(code);
                /* printf("DEBUG-24 \n"); */
        RETVAL = (code == 0);
                /* printf("DEBUG-25 \n"); */
    }
    OUTPUT:
        RETVAL

void
vos_status(cstruct, aserver)
        AFS::VOS cstruct
        char *aserver
    PREINIT:
        afs_int32 server, code;
        transDebugInfo *pntr;
        afs_int32 count;
        char buffer[256];
    CODE:
    {
        server = GetServer(aserver);
        if (!server) {
            sprintf(buffer, "AFS::VOS: host '%s' not found in host table\n", aserver);
            VSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        code = UV_VolserStatus(server, &pntr, &count);
        if (code) {
            PrintDiagnostics("status", code);
            SETCODE(1);
            XSRETURN_UNDEF;
        }
        ST(0) = sv_newmortal();
        SETCODE(0);
        if (count == 0) {
            sprintf(buffer, "No active transactions on %s\n", aserver);
            sv_setpv(ST(0), buffer);
        }
        else {
            sprintf(buffer, "Total transactions: %d\n", count);
            sv_setpv(ST(0), buffer);
        }
        XSRETURN(1);
    }

int32
vos_release(cstruct, name, force=Nullsv)
        AFS::VOS cstruct
        char *name
        SV *  force
    PREINIT:
        struct nvldbentry entry;
        afs_int32 avolid, aserver, apart, vtype, code, err;
        int iforce;
    CODE:
    {
        if (!force) {
            force = newSViv(0);
        }
        if (!SvIOKp(force)) {
            char buffer[256];
            sprintf(buffer, "Flag \"force\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        iforce = SvIV(force);
        RETVAL = 0;
        avolid = vsu_GetVolumeID(name, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VOS: can't find volume '%s'\n", name);
            VSETCODE(err ? err : ENOENT, buffer);
            goto done;
        }
        code = GetVolumeInfo(avolid, &aserver, &apart, &vtype, &entry);
        if (code) {
            SETCODE(code);
            goto done;
        }
        if (vtype != RWVOL) {
            char buffer[256];
            sprintf(buffer, "%s not a RW volume\n", name);
            VSETCODE(ENOENT, buffer);
            goto done;
        }

        if (!ISNAMEVALID(entry.name)) {
            char buffer[256];
            sprintf(buffer, "Volume name %s is too long, rename before releasing\n", entry.name);
            VSETCODE(E2BIG, buffer);
            goto done;
        }

        code = UV_ReleaseVolume(avolid, aserver, apart, iforce);
        if (code) {
            PrintDiagnostics("release", code);
            SETCODE(code);
            goto done;
        }
        #fprintf(STDOUT, "Released volume %s successfully\n", name);
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_create(cstruct, server, partition, name, maxquota=Nullsv, vid=Nullsv, rovid=Nullsv)
        AFS::VOS cstruct
        char *server
        char *partition
        char *name
        SV * maxquota
        SV * vid
        SV * rovid
    PREINIT:
        int32 pnum;
        int32 code;
        struct nvldbentry entry;
        int32 vcode;
        int32 quota = 5000;
        afs_int32 tserver;
#ifdef OpenAFS_1_4_12
        afs_uint32 volid = 0, rovolid = 0, bkvolid = 0;
        afs_uint32 *arovolid = NULL;
#else
        afs_int32 volid = 0;
#endif
    CODE:
    {
        if (!maxquota)
            maxquota = newSViv(0);
        if (!vid)
            vid = newSViv(0);
        if (!rovid)
            rovid = newSViv(0);

        RETVAL = 0;
        /* printf("vos-create DEBUG-1 server %s part %s vol %s maxq %d vid %d rovid %d \n", server, partition, name, SvIV(maxquota), SvIV(vid), SvIV(rovid)); */

        tserver = GetServer(server);
        if (!tserver) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: host '%s' not found in host table\n", server);
            VSETCODE(ENOENT, buffer);
            goto done;
        }

        pnum = volutil_GetPartitionID(partition);
        if (pnum < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", partition);
            VSETCODE(ENOENT, buffer);
            goto done;
        }
        if (!IsPartValid(pnum, tserver, &code)) {      /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n",
                        partition);
            VSETCODE(code ? code : ENOENT, buffer);
            goto done;
        }
        if (!ISNAMEVALID(name)) {
            char buffer[256];
            sprintf(buffer,
                    "AFS::VOS: the name of the root volume %s exceeds the size limit of %d\n",
                    name, VOLSER_OLDMAXVOLNAME - 10);
            VSETCODE(E2BIG, buffer);
            goto done;
        }
        if (!VolNameOK(name)) {
            char buffer[256];
            sprintf(buffer, "Illegal volume name %s, should not end in .readonly or .backup\n",
                    name);
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        if (IsNumeric(name)) {
            char buffer[256];
            sprintf(buffer, "Illegal volume name %s, should not be a number\n", name);
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        vcode = VLDB_GetEntryByName(name, &entry);
        if (!vcode) {
            char buffer[256];
            sprintf(buffer, "Volume %s already exists\n", name);
            #PrintDiagnostics("create", code);
            VSETCODE(EEXIST, buffer);
            goto done;
        }
        /* printf("vos-create DEBUG-2 server %d part %d vol %s maxq %d vid %d rovid %d \n", tserver, pnum, name, SvIV(maxquota), SvIV(vid), SvIV(rovid)); */

        if ((maxquota) && (!SvIOKp(maxquota))) {
            char buffer[256];
            sprintf(buffer, "Initial quota should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        quota = SvIV(maxquota);
        /* printf("vos-create DEBUG-3 quota %d \n", quota); */
#ifdef OpenAFS_1_4_12
        if ((vid) && (!SvIOKp(vid))) {
            /* printf("vos-create DEBUG-4  vid %d \n", SvIV(vid)); */
            char buffer[256];
            sprintf(buffer, "Given volume ID should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        /* printf("vos-create DEBUG-5  vid %d \n", SvIV(vid)); */
        volid = SvIV(vid);
        /* printf("vos-create DEBUG-6 volid %d \n", volid); */

        if ((rovid) && (!SvIOKp(rovid))) {
            /* printf("vos-create DEBUG-7  rovid %d \n", SvIV(rovid)); */
            char buffer[256];
            sprintf(buffer, "Given RO volume ID should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        /* printf("vos-create DEBUG-8  rovid %d \n", SvIV(rovid)); */
        arovolid = &rovolid;
        rovolid = SvIV(rovid);
        /* printf("vos-create DEBUG-9 rovolid %d \n", rovolid); */

        if (rovolid == 0) {
            arovolid = NULL;
        }
        code = UV_CreateVolume3(tserver, pnum, name, quota, 0, 0, 0, 0, &volid, arovolid, &bkvolid);
#else
        code = UV_CreateVolume2(tserver, pnum, name, quota, 0, 0, 0, 0, &volid);
#endif
        if (code) {
            #PrintDiagnostics("create", code);
            SETCODE(code);
            goto done;
        }

        SETCODE(0);
        RETVAL = (int32)volid;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_backup(cstruct, name)
        AFS::VOS cstruct
        char *name
    PREINIT:
        int32 avolid, aserver, apart, vtype, code, err;
        int32 buvolid, buserver, bupart, butype;
        struct nvldbentry entry;
        struct nvldbentry buentry;
    CODE:
    {
        RETVAL = 0;
        avolid = vsu_GetVolumeID(name, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VOS: can't find volume ID or name '%s'\n", name);
            VSETCODE(err ? err : ENOENT, buffer);
            goto done;
        }
        code = GetVolumeInfo(avolid, &aserver, &apart, &vtype, &entry);
        if (code) {
            SETCODE(code);
            goto done;
        }
                /* verify this is a readwrite volume */

        if (vtype != RWVOL) {
            char buffer[256];
            sprintf(buffer, "%s not RW volume\n", name);
            VSETCODE(-1, buffer);
            goto done;
        }

                /* is there a backup volume already? */

        if (entry.flags & BACK_EXISTS) {
            /* yep, where is it? */

            buvolid = entry.volumeId[BACKVOL];
            code = GetVolumeInfo(buvolid, &buserver, &bupart, &butype, &buentry);
            if (code) {
                SETCODE(code);
                goto done;
            }
            /* is it local? */
            code = VLDB_IsSameAddrs(buserver, aserver, &err);
            if (err) {
                char buffer[256];
                sprintf(buffer,
                        "Failed to get info about server's %d address(es) from vlserver; aborting call!\n",
                        buserver);
                VSETCODE(err, buffer);
                goto done;
            }
            if (!code) {
                char buffer[256];
                sprintf(buffer, "FATAL ERROR: backup volume %u exists on server %u\n",
                        buvolid, buserver);
                VSETCODE(-1, buffer);
                goto done;
            }
        }
                /* nope, carry on */

        code = UV_BackupVolume(aserver, apart, avolid);

        if (code) {
            PrintDiagnostics("backup", code);
            SETCODE(0);
            goto done;
        }
        #fprintf(STDOUT, "Created backup volume for %s \n", name);
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_remove(cstruct, name, servername=NULL, parti=NULL)
        AFS::VOS cstruct
        char *name
        char *servername
        char *parti
    PREINIT:
        afs_int32 err, code = 0;
        afs_int32 server = 0, partition = -1, volid;
        afs_int32 idx, j;
    CODE:
    {
        RETVAL = 0;
        if (servername && strlen(servername) != 0) {
            server = GetServer(servername);
            if (!server) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", servername);
                VSETCODE(ENOENT, buffer);
                goto done;
            }
        }

        if (parti && strlen(parti) != 0) {
            partition = volutil_GetPartitionID(parti);
            if (partition < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", parti);
                VSETCODE(EINVAL, buffer);
                goto done;
            }

            /* Check for validity of the partition */
            if (!IsPartValid(partition, server, &code)) {
                char buffer[256];
                if (code)
                    set_errbuff(buffer, code);
                else
                    sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n",
                            parti);
                VSETCODE(ENOENT, buffer);
                goto done;
            }
        }

        volid = vsu_GetVolumeID(name, cstruct, &err);
        if (volid == 0) {
            char buffer[256];
            sprintf(buffer, "Can't find volume name '%s' in VLDB\n", name);
            if (err)
                set_errbuff(buffer, err);
            VSETCODE(ENOENT, buffer);
            goto done;
        }

            /* If the server or partition option are not complete, try to fill
             * them in from the VLDB entry.
             */
        if ((partition == -1) || !server) {
            struct nvldbentry entry;

            code = VLDB_GetEntryByID(volid, -1, &entry);
            if (code) {
                char buffer[256];
                sprintf(buffer, "Could not fetch the entry for volume %u from VLDB\n", volid);
                VSETCODE(code, buffer);
                goto done;
            }

            if (((volid == entry.volumeId[RWVOL]) && (entry.flags & RW_EXISTS)) ||
                ((volid == entry.volumeId[BACKVOL]) && (entry.flags & BACK_EXISTS))) {
                idx = Lp_GetRwIndex(&entry);
                if ((idx == -1) ||
                    (server && (server != entry.serverNumber[idx])) ||
                    ((partition != -1) && (partition != entry.serverPartition[idx]))) {
                    char buffer[256];
                    sprintf(buffer, "AFS::VOS: Volume '%s' no match\n", name);
                    VSETCODE(ENOENT, buffer);
                    goto done;
                }
            }
            else if ((volid == entry.volumeId[ROVOL]) && (entry.flags & RO_EXISTS)) {
                for (idx = -1, j = 0; j < entry.nServers; j++) {
                    if (entry.serverFlags[j] != ITSROVOL)
                        continue;

                    if (((server == 0) || (server == entry.serverNumber[j])) &&
                        ((partition == -1) || (partition == entry.serverPartition[j]))) {
                        if (idx != -1) {
                            char buffer[256];
                            sprintf(buffer, "AFS::VOS: Volume '%s' matches more than one RO\n",
                                    name);
                            VSETCODE(ENOENT, buffer);
                            goto done;
                        }
                        idx = j;
                    }
                }
                if (idx == -1) {
                    char buffer[256];
                    sprintf(buffer, "AFS::VOS: Volume '%s' no match\n", name);
                    VSETCODE(ENOENT, buffer);
                    goto done;
                }
            }
            else {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: Volume '%s' no match\n", name);
                VSETCODE(ENOENT, buffer);
                goto done;
            }

            server = htonl(entry.serverNumber[idx]);
            partition = entry.serverPartition[idx];
        }

        code = UV_DeleteVolume(server, partition, volid);
        if (code) {
            PrintDiagnostics("remove", code);
            SETCODE(code);
            goto done;
        }

        SETCODE(0);
        RETVAL = volid;

        done:
        ;
    }
    OUTPUT: 
        RETVAL

int32
vos_rename(cstruct,oldname,newname)
        AFS::VOS cstruct
        char * oldname
        char * newname
    PREINIT:
        afs_int32 code1, code2, code;
        struct nvldbentry entry;
    CODE:
    {
        RETVAL = 0;
        code1 = VLDB_GetEntryByName(oldname, &entry);
        if (code1) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: Could not find entry for volume %s\n", oldname);
            VSETCODE(-1, buffer);
            goto done;
        }
        code2 = VLDB_GetEntryByName(newname, &entry);
        if ((!code1) && (!code2)) {     /*the newname already exists */
            char buffer[256];
            sprintf(buffer, "AFS::VOS: volume %s already exists\n", newname);
            VSETCODE(-1, buffer);
            goto done;
        }

        if (code1 && code2) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: Could not find entry for volume %s or %s\n", oldname,
                    newname);
            VSETCODE(-1, buffer);
            goto done;
        }
        if (!VolNameOK(oldname)) {
            char buffer[256];
            sprintf(buffer, "Illegal volume name %s, should not end in .readonly or .backup\n",
                    oldname);
            VSETCODE(-1, buffer);
            goto done;
        }
        if (!ISNAMEVALID(newname)) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: the new volume name %s exceeds the size limit of %d\n",
                    newname, VOLSER_OLDMAXVOLNAME - 10);
            VSETCODE(-1, buffer);
            goto done;
        }
        if (!VolNameOK(newname)) {
            char buffer[256];
            sprintf(buffer, "Illegal volume name %s, should not end in .readonly or .backup\n",
                    newname);
            VSETCODE(-1, buffer);
            goto done;
        }
        if (IsNumeric(newname)) {
            char buffer[256];
            sprintf(buffer, "Illegal volume name %s, should not be a number\n", newname);
            VSETCODE(-1, buffer);
            goto done;
        }
        MapHostToNetwork(&entry);
        code = UV_RenameVolume(&entry, oldname, newname);
        if (code) {
            PrintDiagnostics("rename", code);
            SETCODE(code);
            goto done;
        }
        #fprintf(STDOUT, "Renamed volume %s to %s\n", oldname, newname);

        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos__setfields(cstruct, name, mquota=Nullsv, clearuse=Nullsv)
        AFS::VOS cstruct
        char *name
        SV * mquota
        SV * clearuse
    PREINIT:
#ifdef OpenAFS
        struct nvldbentry entry;
        volintInfo info;
        int32 volid;
        int32 clear, code, err;
        int32 aserver, apart;
        int previdx = -1;
#endif
    CODE:
    {
#ifdef OpenAFS
        if (!mquota)
            mquota = newSViv(-1);
        if (!clearuse)
            clearuse = newSViv(0);
        if ((!SvIOKp(mquota))) {     /* -max <quota> */
            char buffer[256];
            sprintf(buffer, "invalid quota value\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        if ((!SvIOKp(clearuse))) {     /* -clearuse */
            char buffer[256];
            sprintf(buffer, "flag \"clearuse\" is not an integer\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }

        /* printf("vos-setfields DEBUG-1 name %s mquota %d clearuse %d \n", name, (int)SvIV(mquota), (int)SvIV(clearuse)); */
        RETVAL = 0;
        volid = vsu_GetVolumeID(name, cstruct, &err);   /* -id */
        if (volid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "Unknown volume ID or name '%s'\n", name);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }

        code = VLDB_GetEntryByID(volid, RWVOL, &entry);
        if (code) {
            char buffer[256];
            sprintf(buffer, "Could not fetch the entry for volume number %u from VLDB \n", volid);
            VSETCODE(code, buffer);
            goto done;
        }
        MapHostToNetwork(&entry);

        GetServerAndPart(&entry, RWVOL, &aserver, &apart, &previdx);
        if (previdx == -1) {
            char buffer[256];
            sprintf(buffer, "Volume %s does not exist in VLDB\n\n", name);
            VSETCODE(ENOENT, buffer);
            goto done;
        }

        Zero(&info, 1, volintInfo);

        info.volid = volid;
        info.type = RWVOL;
        info.creationDate = -1;
        info.updateDate = -1;
        info.dayUse = -1;
        info.maxquota = -1;
        info.flags = -1;
        info.spare0 = -1;
        info.spare1 = -1;
        info.spare2 = -1;
        info.spare3 = -1;

        info.maxquota = SvIV(mquota);

        clear = SvIV(clearuse);
        if (clear)
            info.dayUse = 0;
        code = UV_SetVolumeInfo(aserver, apart, volid, &info);
        if (code) {
            char buffer[256];
            sprintf(buffer, "Could not update volume info fields for volume number %u\n", volid);
            VSETCODE(code, buffer);
        }
        else
            SETCODE(code);
        RETVAL = 1;

        done:
        ;
#else
        not_here("AFS::VOS::setfields");
#endif
    }
    OUTPUT:
        RETVAL

int32
vos_restore(cstruct,server,partition,name,file=NULL,id=NULL,inter=Nullsv,overwrite=NULL,offline=Nullsv,readonly=Nullsv)
        AFS::VOS cstruct
        char *server
        char *partition
        char *name
        char *file
        char *id
        SV *  inter
        char *overwrite
        SV *  offline
        SV *  readonly
    PREINIT:
        afs_int32 avolid, aparentid, aserver, apart, code, vcode, err;
        afs_int32 aoverwrite = AFS_ASK;
        int restoreflags, voltype = RWVOL, ireadonly = 0, ioffline = 0;
        char afilename[NameLen], avolname[VOLSER_MAXVOLNAME +1];
        char volname[VOLSER_MAXVOLNAME +1];
        struct nvldbentry entry;
    CODE:
    {
        aparentid = 0;
        if (!inter) {
            inter = newSViv(0);
        }
        if (!offline) {
            offline = newSViv(0);
        }
        if (!readonly) {
            readonly = newSViv(0);
        }
        if ((!SvIOKp(inter))) {
            char buffer[256];
            sprintf(buffer, "Flag \"inter\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            aoverwrite = AFS_ASK;
        if ((!SvIOKp(offline))) {
            char buffer[256];
            sprintf(buffer, "Flag \"offline\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            ioffline = SvIV(offline);
        if ((!SvIOKp(readonly))) {
            char buffer[256];
            sprintf(buffer, "Flag \"readonly\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            ireadonly = SvIV(readonly);

        if (id && strlen(id) != 0) {
            avolid = vsu_GetVolumeID(id, cstruct, &err);
            if (avolid == 0) {
                char buffer[256];
                if (err)
                    set_errbuff(buffer, err);
                else
                    sprintf(buffer, "AFS::VOS: can't find volume '%s'\n", id);
                VSETCODE(err ? err : -1, buffer);
                RETVAL = 0;
                goto done;
            }
        }
        else
            avolid = 0;

        if (overwrite && strlen(overwrite) != 0) {
            if ((strcmp(overwrite, "a") == 0) || (strcmp(overwrite, "abort") == 0)) {
                aoverwrite = AFS_ABORT;
            }
            else if ((strcmp(overwrite, "f") == 0) || (strcmp(overwrite, "full") == 0)) {
                aoverwrite = AFS_FULL;
            }
            else if ((strcmp(overwrite, "i") == 0) ||
                     (strcmp(overwrite, "inc") == 0) ||
                     (strcmp(overwrite, "increment") == 0) ||
                     (strcmp(overwrite, "incremental") == 0)) {
                aoverwrite = AFS_INC;
            }
            else {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: %s is not a valid OVERWRITE argument\n",
                        overwrite);
                VSETCODE(-1, buffer);
                RETVAL = 0;
                goto done;
            }
        }
        if ((ireadonly))
            voltype = ROVOL;

        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            RETVAL = 0;
            goto done;
        }
        apart = volutil_GetPartitionID(partition);
        if (apart < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", partition);
            VSETCODE(-1, buffer);
            RETVAL = 0;
            goto done;
        }
        if (!IsPartValid(apart, aserver, &code)) {      /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n",
                        partition);
            VSETCODE(code ? code : -1, buffer);
            RETVAL = 0;
            goto done;
        }
        strcpy(avolname, name);
        if (!ISNAMEVALID(avolname)) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: the name of the volume %s exceeds the size limit\n",
                    avolname);
            VSETCODE(-1, buffer);
            RETVAL = 0;
            goto done;
        }
        if (!VolNameOK(avolname)) {
            char buffer[256];
            sprintf(buffer, "Illegal volume name %s, should not end in .readonly or .backup\n",
                    avolname);
            VSETCODE(-1, buffer);
            RETVAL = 0;
            goto done;
        }
        if (file && strlen(file) != 0) {
            strcpy(afilename, file);
            if (!FileExists(afilename)) {
                char buffer[256];
                sprintf(buffer, "Can't access file %s\n", afilename);
                VSETCODE(-1, buffer);
                RETVAL = 0;
                goto done;
            }
        }
        else {
            strcpy(afilename, "");
        }

                /* Check if volume exists or not */

        vsu_ExtractName(volname, avolname);
        vcode = VLDB_GetEntryByName(volname, &entry);
        if (vcode) {                    /* no volume - do a full restore */
            restoreflags = RV_FULLRST;
            if ((aoverwrite == AFS_INC) || (aoverwrite == AFS_ABORT)) {
                char buffer[256];
                sprintf(buffer, "Volume does not exist; Will perform a full restore\n");
                VSETCODE(vcode, buffer);
            }
        }
        else if ((!ireadonly && Lp_GetRwIndex(&entry) == -1)     /* RW volume does not exist - do a full */
                 ||(ireadonly && !Lp_ROMatch(0, 0, &entry))) {   /* RO volume does not exist - do a full */
            restoreflags = RV_FULLRST;
            if ((aoverwrite == AFS_INC) || (aoverwrite == AFS_ABORT))
                fprintf(stderr, "%s Volume does not exist; Will perform a full restore\n",
                        ireadonly ? "RO" : "RW");

            if (avolid == 0) {
                avolid = entry.volumeId[voltype];
            }
            else if (entry.volumeId[voltype] != 0 && entry.volumeId[voltype] != avolid) {
                avolid = entry.volumeId[voltype];
            }
            aparentid = entry.volumeId[RWVOL];
        }
        else {                 /* volume exists - do we do a full incremental or abort */
            int Oserver, Opart, Otype, vol_elsewhere = 0;
            struct nvldbentry Oentry;
            int c, dc;

            if (avolid == 0) {
                avolid = entry.volumeId[voltype];
            }
            else if (entry.volumeId[voltype] != 0 && entry.volumeId[voltype] != avolid) {
                avolid = entry.volumeId[voltype];
            }
            aparentid = entry.volumeId[RWVOL];

            /* A file name was specified  - check if volume is on another partition */
            vcode = GetVolumeInfo(avolid, &Oserver, &Opart, &Otype, &Oentry);
            if (vcode) {
                SETCODE(0);
                RETVAL = 0;
                goto done;
            }

            vcode = VLDB_IsSameAddrs(Oserver, aserver, &err);
            if (err) {
                char buffer[256];
                sprintf(buffer,
                        "Failed to get info about server's %d address(es) from vlserver (err=%d); aborting call!\n",
                        Oserver, err);
                VSETCODE(err, buffer);
                RETVAL = 0;
                goto done;
            }
            if (!vcode || (Opart != apart))
                vol_elsewhere = 1;

            if (aoverwrite == AFS_ASK) {
                if (strcmp(afilename, "") == 0) {       /* The file is from standard in */
                    char buffer[256];
                    sprintf(buffer,
                            "Volume exists and no OVERWRITE argument specified; Aborting restore command\n");
                    VSETCODE(-1, buffer);
                    RETVAL = 0;
                    goto done;
                }

                /* Ask what to do */
                if (vol_elsewhere) {
                    char buffer[256];
                    sprintf(buffer,
                            "The volume %s %u already exists on a different server/part\n",
                            volname, entry.volumeId[voltype]);
                    VSETCODE(-1, buffer);
                    fprintf(stderr, "Do you want to do a full restore or abort? [fa](a): ");
                }
                else {
                    char buffer[256];
                    sprintf(buffer, "The volume %s %u already exists in the VLDB\n",
                            volname, entry.volumeId[voltype]);
                    VSETCODE(-1, buffer);
                    fprintf(stderr,
                            "Do you want to do a full/incremental restore or abort? [fia](a): ");
                }
                dc = c = getchar();
                while (!(dc == EOF || dc == '\n'))
                    dc = getchar();     /* goto end of line */
                if ((c == 'f') || (c == 'F'))
                    aoverwrite = AFS_FULL;
                else if ((c == 'i') || (c == 'I'))
                    aoverwrite = AFS_INC;
                else
                    aoverwrite = AFS_ABORT;
            }

            if (aoverwrite == AFS_ABORT) {
                char buffer[256];
                sprintf(buffer, "Volume exists; Aborting restore command\n");
                VSETCODE(-1, buffer);
                RETVAL = 0;
                goto done;
            }
            else if (aoverwrite == AFS_FULL) {
                restoreflags = RV_FULLRST;
                fprintf(stderr, "Volume exists; Will delete and perform full restore\n");
            }
            else if (aoverwrite == AFS_INC) {
                restoreflags = 0;
                if (vol_elsewhere) {
                    char buffer[256];
                    sprintf(buffer,
                            "%s volume %u already exists on a different server/part; not allowed\n",
                            ireadonly ? "RO" : "RW", avolid);
                    VSETCODE(-1, buffer);
                    RETVAL = 0;
                    goto done;
                }
            }
        }

        if ((ioffline))
            restoreflags |= RV_OFFLINE;
        if (ireadonly)
            restoreflags |= RV_RDONLY;

        /* restoreflags |= RV_CRNEW; */
        /* restoreflags |= RV_LUDUMP; */
#ifdef OpenAFS_1_4_05
        code = UV_RestoreVolume2(aserver, apart, avolid, aparentid, avolname,
                                 restoreflags, WriteData, afilename);
#else
        code = UV_RestoreVolume(aserver, apart, avolid, avolname,
                                restoreflags, WriteData, afilename);
#endif
        if (code) {
            PrintDiagnostics("restore", code);
            SETCODE(code);
            RETVAL = 0;
            goto done;
        }

        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_dump(cstruct, id, time=NULL, file=NULL, server=NULL, partition=NULL, clone=Nullsv, omit=Nullsv)
        AFS::VOS cstruct
        char *id
        char *time
        char *file
        char *server
        char *partition
        SV *  clone
        SV *  omit
    PREINIT:
        afs_int32 avolid, aserver, apart, voltype, fromdate=0, code=0, err, i;
        char filename[NameLen];
        struct nvldbentry entry;
        afs_int32 omitdirs = 0;
    CODE:
    {
        if (!clone)
            clone = newSViv(0);
        if (!omit)
            omit = newSViv(0);
        if ((!SvIOKp(omit))) {
            char buffer[256];
            sprintf(buffer, "Flag \"omit\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            omitdirs = SvIV(omit);     /* -omit */
        /* printf("vos_dump DEBUG-1 clone = %d omit = %d omitdirs = %d \n", clone, omit, omitdirs); */
        RETVAL = 0;
        rx_SetRxDeadTime(60 * 10);
        for (i = 0; i < MAXSERVERS; i++) {
            struct rx_connection *rxConn = ubik_GetRPCConn((struct ubik_client *) cstruct, i);
            if (rxConn == 0)
                break;
            rx_SetConnDeadTime(rxConn, rx_connDeadTime);
            if (rxConn->service)
                rxConn->service->connDeadTime = rx_connDeadTime;
        }

        avolid = vsu_GetVolumeID(id, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VOS: can't find volume '%s'\n", id);
            VSETCODE(err ? err : ENOENT, buffer);
            goto done;
        }

        if ((server && (strlen(server) != 0)) || (partition && (strlen(partition) != 0))) {
            if (!(server && (strlen(server) != 0)) || !(partition && (strlen(partition) != 0))) {
                char buffer[256];
                sprintf(buffer, "Must specify both SERVER and PARTITION arguments\n");
                VSETCODE(-1, buffer);
                goto done;
            }
            aserver = GetServer(server);
            if (aserver == 0) {
                char buffer[256];
                sprintf(buffer, "Invalid server name\n");
                VSETCODE(-1, buffer);
                goto done;
            }
            apart = volutil_GetPartitionID(partition);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "Invalid partition name\n");
                VSETCODE(-1, buffer);
                goto done;
            }
        }
        else {
            code = GetVolumeInfo(avolid, &aserver, &apart, &voltype, &entry);
            if (code) {
                SETCODE(code);
                goto done;
            }
        }

        if (time && strcmp(time, "0")) {
            code = ktime_DateToInt32(time, &fromdate);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: failed to parse date '%s' (error=%d))\n", time, code);
                VSETCODE(code, buffer);
                goto done;
            }
        }
        if (file && (strlen(file) != 0)) {
            strcpy(filename, file);
        }
        else {
            strcpy(filename, "");
        }
#ifdef OpenAFS_1_4_05
        int iclone = 0;
    retry_dump:
        /* printf("vos_dump DEBUG-2 clone = %d omitdirs = %d \n", clone, omitdirs); */
        if ((!SvIOKp(clone))) {
            char buffer[256];
            sprintf(buffer, "Flag \"clone\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            iclone = SvIV(clone);
        if (iclone) {
            /* printf("vos_dump DEBUG-2-1 clone = %d omitdirs = %d \n", clone, omitdirs); */
            code = UV_DumpClonedVolume(avolid, aserver, apart, fromdate,
                                       DumpFunction, filename, omitdirs);
        } else {
            /* printf("vos_dump DEBUG-2-2 clone = %d omitdirs = %d \n", clone, omitdirs); */
            code = UV_DumpVolume(avolid, aserver, apart, fromdate, DumpFunction,
                                 filename, omitdirs);
        }
        /* printf("vos_dump DEBUG-3 code = %d \n", code); */
        if ((code == RXGEN_OPCODE) && (omitdirs)) {
            omitdirs = 0;
            goto retry_dump;
        }
#else
        /* printf("vos_dump DEBUG-4 \n"); */
        code = UV_DumpVolume(avolid, aserver, apart, fromdate, DumpFunction, filename);
        /* printf("vos_dump DEBUG-5 code = %d \n", code); */
#endif
        if (code) {
            PrintDiagnostics("dump", code);
            SETCODE(code);
            goto done;
        }

        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

void
vos_partinfo(cstruct, server, partname=NULL)
        AFS::VOS cstruct
        char *server
        char *partname
    PREINIT:
        afs_int32 apart;
        afs_int32 aserver, code;
        char pname[10];
#ifdef OpenAFS_1_4_64
        struct diskPartition64 partition;
#else
        struct diskPartition partition;
#endif
        struct partList dummyPartList;
        int i, cnt;
        HV *partlist = (HV*)sv_2mortal((SV*)newHV());
    PPCODE:
    {
        apart = -1;
        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        if (partname && (strlen(partname) != 0)) {
            apart = volutil_GetPartitionID(partname);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", partname);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            dummyPartList.partId[0] = apart;
            dummyPartList.partFlags[0] = PARTVALID;
            cnt = 1;
        }
        if (apart != -1) {
            if (!IsPartValid(apart, aserver, &code)) {  /*check for validity of the partition */
                char buffer[256];
                if (code)
                    set_errbuff(buffer, code);
                else
                    sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n",
                            partname);
                VSETCODE(code ? code : -1, buffer);
                XSRETURN_UNDEF;
            }
        }
        else {
            code = UV_ListPartitions(aserver, &dummyPartList, &cnt);
            if (code) {
                PrintDiagnostics("listpart", code);
                SETCODE(code);
                XSRETURN_UNDEF;
            }
        }

        for (i = 0; i < cnt; i++) {
            if (dummyPartList.partFlags[i] & PARTVALID) {
                HV *part = (HV *) sv_2mortal((SV *) newHV());
                MapPartIdIntoName(dummyPartList.partId[i], pname);
#ifdef OpenAFS_1_4_64
                code = UV_PartitionInfo64(aserver, pname, &partition);
#else
                code = UV_PartitionInfo(aserver, pname, &partition);
#endif
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "Could not get information on partition %s\n", pname);
                    VSETCODE(code, buffer);
                    XSRETURN_UNDEF;
                }
                safe_hv_store(part, "free", 4, newSViv(partition.free), 0);
                safe_hv_store(part, "minFree", 7, newSViv(partition.minFree), 0);

                safe_hv_store(partlist, pname, strlen(pname), newRV_inc((SV *) (part)), 0);
            }
        }

        SETCODE(0);
        ST(0) = sv_2mortal(newRV_inc((SV *) partlist));
        XSRETURN(1);
    }

void
vos_listvol(cstruct, server, partname=NULL, fast=Nullsv, extended=Nullsv)
        AFS::VOS cstruct
        char *server
        char *partname
        SV *  fast
        SV *  extended
  PREINIT:
        afs_int32 apart = -1, aserver, code = 0;
        volintInfo *pntr = (volintInfo *)0;
        afs_int32 count;
        int i;
        volintXInfo *xInfoP = (volintXInfo *)0; /*Ptr to current/orig extended vol info*/
        int wantExtendedInfo=0;                 /*Do we want extended vol info?*/

        char pname[10];
        struct partList dummyPartList;
        int all, cnt, ifast=0;

        HV *vollist = (HV*)sv_2mortal((SV*)newHV());
    PPCODE:
    {
        if (!fast)
            fast = newSViv(0);
        if (!extended)
            extended = newSViv(0);

        if ((!SvIOKp(fast))) {
            char buffer[256];
            sprintf(buffer, "Flag \"fast\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        else
            ifast = SvIV(fast);              /* -fast */
        if ((!SvIOKp(extended))) {
            char buffer[256];
            sprintf(buffer, "Flag \"extended\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        else
            wantExtendedInfo = SvIV(extended);   /* -extended */
        if (ifast && wantExtendedInfo) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS:  FAST and EXTENDED flags are mutually exclusive\n");
            VSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }

        /* printf ("vos_listvol DEBUG-1 pntr %p \n", pntr); */
        /* printf ("vos_listvol DEBUG-1 xInfoP %p \n", xInfoP); */
        if (ifast)
            all = 0;
        else
            all = 1;

        if (partname && (strlen(partname) != 0)) {
            apart = volutil_GetPartitionID(partname);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", partname);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            dummyPartList.partId[0] = apart;
            dummyPartList.partFlags[0] = PARTVALID;
            cnt = 1;
        }

        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }

        if (apart != -1) {
            if (!IsPartValid(apart, aserver, &code)) {  /*check for validity of the partition */
                char buffer[256];
                if (code)
                    set_errbuff(buffer, code);
                else
                    sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n",
                            partname);
                VSETCODE(code ? code : -1, buffer);
                XSRETURN_UNDEF;
            }
        }
        else {
            code = UV_ListPartitions(aserver, &dummyPartList, &cnt);
            if (code) {
                PrintDiagnostics("listvol", code);
                SETCODE(-1);
                XSRETURN_UNDEF;
            }
        }

        for (i = 0; i < cnt; i++) {
            if (dummyPartList.partFlags[i] & PARTVALID) {
                /*HV *part = (HV*)sv_2mortal((SV*)newHV()); */
                HV *part = newHV();
                if (wantExtendedInfo)
                    code = UV_XListVolumes(aserver,
                                           dummyPartList.partId[i], all, &xInfoP, &count);
                else
                    code = UV_ListVolumes(aserver, dummyPartList.partId[i], all, &pntr, &count);
                /* printf ("vos_listvol DEBUG-2 xInfoP %p %d \n", xInfoP, code); */
                /* printf ("vos_listvol DEBUG-2 pntr %p %d \n", pntr, code); */
                if (code) {
                    PrintDiagnostics("listvol", code);
                    if (pntr)
                        free(pntr);
                    SETCODE(-1);
                    XSRETURN_UNDEF;
                }

                MapPartIdIntoName(dummyPartList.partId[i], pname);
                if (wantExtendedInfo) {
                    XDisplayVolumes(part,
                                    aserver,
                                    dummyPartList.partId[i],
                                    xInfoP, count);
                    /* printf ("vos_listvol DEBUG-3 xInfoP %p \n", xInfoP); */
                    if (xInfoP)
                        free(xInfoP);
                    xInfoP = (volintXInfo *) 0;
                }
                else {
                    DisplayVolumes(part,
                                   aserver,
                                   dummyPartList.partId[i],
                                   pntr, count, ifast);
                    /* printf ("vos_listvol DEBUG-4 pntr %p \n", pntr); */
                    if (pntr)
                        free(pntr);
                    pntr = (volintInfo *) 0;
                }
                safe_hv_store(vollist, pname, strlen(pname), newRV_inc((SV *) (part)), 0);
            }
        }

        SETCODE(0);
        ST(0) = sv_2mortal(newRV_inc((SV *) vollist));
        XSRETURN(1);
    }

int32
vos_move(cstruct, id, froms, fromp, tos, top)
        AFS::VOS cstruct
        char *id
        char *froms
        char *fromp
        char *tos
        char *top
    PREINIT:
        afs_int32 volid, fromserver, toserver, frompart, topart,code, err;
        char fromPartName[10], toPartName[10];
#ifdef OpenAFS_1_4_64
        struct diskPartition64 partition;   /* for space check */
#else
        struct diskPartition partition;         /* for space check */
#endif
        volintInfo *p;
    CODE:
    {
        RETVAL = 0;
        volid = vsu_GetVolumeID(id, cstruct, &err);
        if (volid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VOS: can't find volume ID or name '%s'\n", id);
            VSETCODE(err ? err : ENOENT, buffer);
            goto done;
        }
        fromserver = GetServer(froms);
        if (fromserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", froms);
            VSETCODE(ENOENT, buffer);
            goto done;
        }
        toserver = GetServer(tos);
        if (toserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", tos);
            VSETCODE(ENOENT, buffer);
            goto done;
        }
        frompart = volutil_GetPartitionID(fromp);
        if (frompart < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", fromp);
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        if (!IsPartValid(frompart, fromserver, &code)) {        /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n", fromp);
            VSETCODE(code ? code : ENOENT, buffer);
            goto done;
        }
        topart = volutil_GetPartitionID(top);
        if (topart < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", top);
            VSETCODE(EINVAL, buffer);
            goto done;
        }
        if (!IsPartValid(topart, toserver, &code)) {    /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n", top);
            VSETCODE(code ? code : ENOENT, buffer);
            goto done;
        }

                /*
                   check source partition for space to clone volume
                 */

        MapPartIdIntoName(topart, toPartName);
        MapPartIdIntoName(frompart, fromPartName);

                /*
                   check target partition for space to move volume
                 */
#ifdef OpenAFS_1_4_64
        code = UV_PartitionInfo64(toserver, toPartName, &partition);
#else
        code = UV_PartitionInfo(toserver, toPartName, &partition);
#endif
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: cannot access partition %s\n", toPartName);
            VSETCODE(code, buffer);
            goto done;
        }

        p = (volintInfo *) 0;
        code = UV_ListOneVolume(fromserver, frompart, volid, &p);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS:cannot access volume %u\n", volid);
            free(p);
            VSETCODE(code, buffer);
            goto done;
        }
        if (partition.free <= p->size) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: no space on target partition %s to move volume %u\n",
                    toPartName, volid);
            VSETCODE(-1, buffer);
            if (p)
                free(p);
            goto done;
        }
        if (p)
            free(p);

                /* successful move still not guaranteed but shoot for it */

        code = UV_MoveVolume(volid, fromserver, frompart, toserver, topart);
        if (code) {
            PrintDiagnostics("move", code);
            SETCODE(code);
            goto done;
        }

        #SETCODE(1);  ???
        SETCODE(0);
        RETVAL = volid;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_zap(cstruct, servername, parti, id, force=Nullsv, backup=Nullsv)
        AFS::VOS cstruct
        char *servername
        char *parti
        char *id
        SV *  force
        SV *  backup
    PREINIT:
        struct nvldbentry entry;
        int32 volid, code, server, part, iforce=0, zapbackupid=0, backupid=0, err;
    CODE:
    {
        if (!force)
            force = newSViv(0);
        if (!backup)
            backup = newSViv(0);
        if ((!SvIOKp(force))) {
            char buffer[256];
            sprintf(buffer, "Flag \"force\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            iforce = 1;             /* -force */
        if ((!SvIOKp(backup))) {
            char buffer[256];
            sprintf(buffer, "Flag \"backup\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            zapbackupid = 1;           /* -backup */
         RETVAL = 0;

        volid = vsu_GetVolumeID(id, cstruct, &err);
        if (volid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VOS: can't find volume '%s'\n", id);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }
        part = volutil_GetPartitionID(parti);
        if (part < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", parti);
            VSETCODE(-1, buffer);
            goto done;
        }
        server = GetServer(servername);
        if (!server) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: host '%s' not found in host table\n", servername);
            VSETCODE(-1, buffer);
            goto done;
        }

        if (iforce) {        /* -force  */
            code = UV_NukeVolume(server, part, volid);
            if (code) {
                PrintDiagnostics("zap", code);
                SETCODE(code);
                goto done;
            }
            SETCODE(0);
            RETVAL = volid;
            goto done;
        }

        if (!IsPartValid(part, server, &code)) {        /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VOS: partition %s does not exist on the server\n",
                        servername);
            VSETCODE(code ? code : -1, buffer);
            goto done;
        }
        code = VLDB_GetEntryByID(volid, -1, &entry);
        if (!code) {
            if (volid == entry.volumeId[RWVOL])
                backupid = entry.volumeId[BACKVOL];
            #fprintf(stderr,
            #        "Warning: Entry for volume number %u exists in VLDB (but we're zapping it anyway!)\n",
            #        volid);
        }
        if (zapbackupid) {
            volintInfo *pntr = (volintInfo *) 0;

            if (!backupid) {
                code = UV_ListOneVolume(server, part, volid, &pntr);
                if (!code) {
                    if (volid == pntr->parentID)
                        backupid = pntr->backupID;
                    if (pntr)
                        free(pntr);
                }
            }
            if (backupid) {
                code = UV_VolumeZap(server, part, backupid);
                if (code) {
                    PrintDiagnostics("zap", code);
                    SETCODE(code);
                    goto done;
                }
                fprintf(STDOUT, "Backup Volume %u deleted\n", backupid);
            }
        }
        code = UV_VolumeZap(server, part, volid);
        if (code) {
            PrintDiagnostics("zap", code);
            SETCODE(code);
            goto done;
        }
        #fprintf(STDOUT, "Volume %u deleted\n", volid);
        SETCODE(0);
        RETVAL = volid;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_offline(cstruct, servername, parti, id, busy=Nullsv, sleep=Nullsv)
        AFS::VOS cstruct
        char* servername
        char* parti
        char *id
        SV *  busy
        SV *  sleep
    PREINIT:
        int32 server, partition, volid;
        int32 code, err=0;
        int32 ibusy=0, isleep=0, transflag, transdone;
    CODE:
    {
        if (!busy)
            busy = newSViv(0);
        if (!sleep)
            sleep = newSViv(0);
        if ((!SvIOKp(busy))) {
            char buffer[256];
            sprintf(buffer, "Flag \"busy\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            ibusy = SvIV(busy);         /* -busy */
        if ((!SvIOKp(sleep))) {
            char buffer[256];
            sprintf(buffer, "Flag \"sleep\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            RETVAL = 0;
            goto done;
        }
        else
            isleep = SvIV(sleep);       /* -sleep */
        RETVAL = 0;
        server = GetServer(servername);
        if (server == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", servername);
            VSETCODE(-1, buffer);
            goto done;
        }

        partition = volutil_GetPartitionID(parti);
        if (partition < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", parti);
            VSETCODE(ENOENT, buffer);
            goto done;
        }

        volid = vsu_GetVolumeID(id, cstruct, &err);     /* -id */
        if (!volid) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "Unknown volume ID or name '%s'\n", servername);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }

        transflag = (ibusy ? ITBusy : ITOffline);
        transdone = (isleep ? 0 /*online */ : VTOutOfService);
        if (ibusy && !isleep) {
            char buffer[256];
            sprintf(buffer, "SLEEP argument must be used with BUSY flag\n");
            VSETCODE(-1, buffer);
            goto done;
        }

        code = UV_SetVolume(server, partition, volid, transflag, transdone, isleep);
        if (code) {
            char buffer[256];
            sprintf(buffer, "Failed to set volume. Code = %d\n", code);
            VSETCODE(code, buffer);
            goto done;
        }
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vos_online(cstruct, servername, parti, id)
        AFS::VOS cstruct
        char* servername
        char* parti
        char *id
    PREINIT:
        int32 server, partition, volid;
        int32 code, err=0;
    CODE:
    {
        RETVAL = 0;
        server = GetServer(servername);
        if (server == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", servername);
            VSETCODE(-1, buffer);
            goto done;
        }

        partition = volutil_GetPartitionID(parti);
        if (partition < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", parti);
            VSETCODE(ENOENT, buffer);
            goto done;
        }

        volid = vsu_GetVolumeID(id, cstruct, &err);     /* -id */
        if (!volid) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "Unknown volume ID or name '%s'\n", servername);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }

        code = UV_SetVolume(server, partition, volid, ITOffline, 0 /*online */ , 0 /*sleep */ );
        if (code) {
            char buffer[256];
            sprintf(buffer, "Failed to set volume. Code = %d\n", code);
            VSETCODE(code, buffer);
            goto done;
        }
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

void
vos__backupsys(cstruct, seenprefix=Nullsv, servername=NULL, partition=NULL, exclude=Nullsv, seenxprefix=Nullsv, noaction=Nullsv)
        AFS::VOS cstruct
        SV *  seenprefix
        char *servername
        char *partition
        SV *  exclude
        SV *  seenxprefix
        SV *  noaction
    PREINIT:
        int32 apart=0, avolid;
        int32 aserver=0, code, aserver1, apart1;
        int32 vcode, iexclude=0, inoaction=0;
        struct VldbListByAttributes attributes;
        nbulkentries arrayEntries;
        register struct nvldbentry *vllist;
        int32 nentries;
        int j, i, len, verbose = 1;
        afs_int32 totalBack=0;
        afs_int32 totalFail=0;
        int previdx=-1, error, same;
        char *ccode, *itp;
        int match = 0;
        STRLEN prfxlength=0;
        SV *regex;
        AV *av;
        AV *av1 = (AV*)sv_2mortal((SV*)newAV());
        AV *av2 = (AV*)sv_2mortal((SV*)newAV());
    PPCODE:
    {
        /* printf("vos-backupsys DEBUG-1 server %s part %s exclude %d noaction %d \n", servername, partition, (int)SvIV(exclude), (int)SvIV(noaction)); */
        if (!exclude)
            exclude = newSViv(0);
        if (!noaction)
            noaction = newSViv(0);
        if ((!SvIOKp(exclude))) {
            char buffer[256];
            sprintf(buffer, "Flag \"exclude\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        else
            iexclude = SvIV(exclude);         /* -exclude */
        /* printf("vos-backupsys DEBUG-2: iexclude = %d \n", iexclude); */
        if ((!SvIOKp(noaction))) {
            char buffer[256];
            sprintf(buffer, "Flag \"noaction\" should be numeric.\n");
            VSETCODE(EINVAL, buffer);
            XSRETURN_UNDEF;
        }
        else
            inoaction = SvIV(noaction);       /* -noaction */

        Zero(&attributes, 1, VldbListByAttributes);
        attributes.Mask = 0;
        /* printf("vos-backupsys DEBUG-3\n"); */

        if (servername && (strlen(servername) != 0)) {  /* -server */
            /* printf("vos-backupsys DEBUG-4\n"); */
            aserver = GetServer(servername);
            if (aserver == 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", servername);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            attributes.server = ntohl(aserver);
            attributes.Mask |= VLLIST_SERVER;
        }
        else {
            servername = NULL;
        }

        /* printf("vos-backupsys DEBUG-5\n"); */
        if (partition && (strlen(partition) != 0)) {    /* -partition */
            /* printf("vos-backupsys DEBUG-6\n"); */
            apart = volutil_GetPartitionID(partition);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VOS: could not interpret partition name '%s'\n", partition);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            attributes.partition = apart;
            attributes.Mask |= VLLIST_PARTITION;
        }
        else {
            partition = NULL;
        }

        /* printf("vos-backupsys DEBUG-7\n"); */
            /* Check to make sure the prefix and xprefix expressions compile ok */
        if (seenprefix && (prfxlength = sv_len(seenprefix)) == 0)
            seenprefix = NULL;
        /* printf("vos-backupsys DEBUG-7-1 PrfxLen %d\n", prfxlength); */

        if (seenprefix && (! (SvTYPE(SvRV(seenprefix)) == SVt_PVAV))) {
            VSETCODE(-1, "AFS::VOS: PREFIX not an array reference");
            XSRETURN_UNDEF;
        }

        if (seenprefix) {
            av = (AV *) SvRV(seenprefix);
            len = av_len(av);
            /* printf("vos-backupsys DEBUG-7-2 Len %d\n", len); */
            if (len != -1) {
                for (j = 0; j <= len; j++) {
                    regex = *av_fetch(av, j, 0);
                    itp = SvPV_nolen(regex);
                    if (strncmp(itp, "^", 1) == 0) {
                        ccode = (char *) re_comp(itp);
                        if (ccode) {
                            char buffer[256];
                            sprintf(buffer,
                                    "Unrecognizable PREFIX regular expression: '%s': %s\n", itp,
                                    ccode);
                            VSETCODE(ccode, buffer);
                            XSRETURN_UNDEF;
                        }
                    }
                }                       /*for loop */
            /* printf("vos-backupsys DEBUG-8 RE %s \n", itp); */
            }
        }

        /* printf("vos-backupsys DEBUG-9\n"); */
        if (seenxprefix && (prfxlength = sv_len(seenxprefix)) == 0)
            seenxprefix = NULL;
        /* printf("vos-backupsys DEBUG-10\n"); */

        if (seenxprefix && (! (SvTYPE(SvRV(seenxprefix)) == SVt_PVAV))) {
            VSETCODE(-1, "AFS::VOS: XPREFIX not an array reference");
            XSRETURN_UNDEF;
        }
        if (seenxprefix) {
            /* printf("vos-backupsys DEBUG-11\n"); */
            av = (AV *) SvRV(seenxprefix);
            len = av_len(av);
            if (len != -1) {
                for (j = 0; j <= len; j++) {
                    regex = *av_fetch(av, j, 0);
                    itp = SvPV_nolen(regex);
                    if (strncmp(itp, "^", 1) == 0) {
                        ccode = (char *) re_comp(itp);
                        if (ccode) {
                            char buffer[256];
                            sprintf(buffer,
                                    "Unrecognizable XPREFIX regular expression: '%s': %s\n", itp,
                                    ccode);
                            VSETCODE(ccode, buffer);
                            XSRETURN_UNDEF;
                        }
                    }
                }                       /*for */
            }
        }

        /* printf("vos-backupsys DEBUG-12\n"); */
        Zero(&arrayEntries, 1, nbulkentries);   /* initialize to hint the stub to alloc space */
        vcode = VLDB_ListAttributes(&attributes, &nentries, &arrayEntries);
        if (vcode) {
            VSETCODE(vcode, "Could not access the VLDB for attributes");
            XSRETURN_UNDEF;
        }

            /* a bunch of output generation code deleted. A.W. */

        /* printf("vos-backupsys DEBUG-13\n"); */
        for (j = 0; j < nentries; j++) {        /* process each vldb entry */
            vllist = &arrayEntries.nbulkentries_val[j];
            /* printf("vos-backupsys DEBUG-13-1 Name %s\n", vllist->name); */

            if (seenprefix) {
                av = (AV *) SvRV(seenprefix);
                len = av_len(av);
                /* printf("vos-backupsys DEBUG-14 Len %d\n", len); */
                for (i = 0; i <= len; i++) {
                    regex = *av_fetch(av, i, 0);
                    itp = SvPV_nolen(regex);
                    /* printf("vos-backupsys DEBUG-14-1 RE %s \n", itp); */
                    if (strncmp(itp, "^", 1) == 0) {
                        ccode = (char *) re_comp(itp);
                        if (ccode) {
                            char buffer[256];
                            sprintf(buffer, "Error in PREFIX regular expression: '%s': %s\n",
                                    itp, ccode);
                            VSETCODE(ccode, buffer);
                            XSRETURN_UNDEF;
                        }
                        match = (re_exec(vllist->name) == 1);
                    }
                    else {
                        match = (strncmp(vllist->name, itp, strlen(itp)) == 0);
                    }
                    if (match)
                        break;
                }
            }
            else {
                match = 1;
                /* printf("vos-backupsys DEBUG-15 MATCH %d\n", match); */
            }

            /* Without the -exclude flag: If it matches the prefix, then
             *    check if we want to exclude any from xprefix.
             * With the -exclude flag: If it matches the prefix, then
             *    check if we want to add any from xprefix.
             */
            if (match && seenxprefix) {
                av = (AV *) SvRV(seenxprefix);
                len = av_len(av);
                for (i = 0; i <= len; i++) {
                    regex = *av_fetch(av, i, 0);
                    itp = SvPV_nolen(regex);
                    if (strncmp(itp, "^", 1) == 0) {
                        ccode = (char *) re_comp(itp);
                        if (ccode) {
                            char buffer[256];
                            sprintf(buffer, "Error in PREFIX regular expression: '%s': %s\n",
                                    itp, ccode);
                            VSETCODE(ccode, buffer);
                            XSRETURN_UNDEF;
                        }
                        if (re_exec(vllist->name) == 1) {
                            match = 0;
                            break;
                        }
                    }
                    else {
                        if (strncmp(vllist->name, itp, strlen(itp)) == 0) {
                            match = 0;
                            break;
                        }
                    }
                }
            }

            /* printf("vos-backupsys DEBUG-16-1: exclude %d match %d\n", iexclude, match); */
            if (iexclude)
                match = !match;         /* -exclude will reverse the match */
            if (!match)
                continue;               /* Skip if no match */

            /* printf("vos-backupsys DEBUG-16-2: noaction %d match %d\n", inoaction, match); */
            /* Print list of volumes to backup */
            if (inoaction) {
                av_push(av1, newSVpv(vllist->name, strlen(vllist->name)));
                continue;
            }

            /* printf("vos-backupsys DEBUG-17\n"); */
            if (!(vllist->flags & RW_EXISTS)) {
                if (verbose) {
                    fprintf(STDOUT, "Omitting to backup %s since RW volume does not exist \n",
                            vllist->name);
                    fprintf(STDOUT, "\n");
                }
                fflush(STDOUT);
                continue;
            }

            /* printf("vos-backupsys DEBUG-18\n"); */
            avolid = vllist->volumeId[RWVOL];
            MapHostToNetwork(vllist);
            GetServerAndPart(vllist, RWVOL, &aserver1, &apart1, &previdx);
            if (aserver1 == -1 || apart1 == -1) {
                av_push(av2, newSVpv(vllist->name, strlen(vllist->name)));
                fprintf(STDOUT, "could not backup %s, invalid VLDB entry\n", vllist->name);
                totalFail++;
                continue;
            }
            /* printf("vos-backupsys DEBUG-19\n"); */
            if (aserver) {
                same = VLDB_IsSameAddrs(aserver, aserver1, &error);
                if (error) {
                    av_push(av2, newSVpv(vllist->name, strlen(vllist->name)));
                    fprintf(stderr,
                            "Failed to get info about server's %d address(es) from vlserver (err=%d); aborting call!\n",
                            aserver, error);
                    totalFail++;
                    continue;
                }
            }
            /* printf("vos-backupsys DEBUG-20\n"); */
            if ((aserver && !same) || (apart && (apart != apart1))) {
                if (verbose) {
                    fprintf(STDOUT,
                            "Omitting to backup %s since the RW is in a different location\n",
                            vllist->name);
                }
                continue;
            }
            if (verbose) {
                time_t now = time(0);
                fprintf(STDOUT, "Creating backup volume for %s on %s", vllist->name, ctime(&now));
                fflush(STDOUT);
            }

            /* printf("vos-backupsys DEBUG-21\n"); */
            code = UV_BackupVolume(aserver1, apart1, avolid);
            if (code) {
                av_push(av2, newSVpv(vllist->name, strlen(vllist->name)));
                fprintf(STDOUT, "Could not backup %s\n", vllist->name);
                totalFail++;
            }
            else {
                av_push(av1, newSVpv(vllist->name, strlen(vllist->name)));
                totalBack++;
            }
        }                               /* process each vldb entry */

        /* printf("vos-backupsys DEBUG-22: Succ %d   Fail %d\n", totalBack, totalFail); */
        if (arrayEntries.nbulkentries_val)
            free(arrayEntries.nbulkentries_val);

        SETCODE(0);
        XPUSHs(sv_2mortal(newRV_inc((SV *) (av1))));
        XPUSHs(sv_2mortal(newRV_inc((SV *) (av2))));
        XSRETURN(2);
    }

void
vos_listpart(cstruct, server)
        AFS::VOS cstruct
        char *server
    PREINIT:
        int32 aserver, code;
        struct partList dummyPartList;
        int i, total, cnt;
        char pname[10];
    PPCODE:
    {
        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VOS: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        code = UV_ListPartitions(aserver, &dummyPartList, &cnt);
        if (code) {
            PrintDiagnostics("listpart", code);
            XSRETURN_UNDEF;
        }
        total = 0;
        for (i = 0; i < cnt; i++) {
            if (dummyPartList.partFlags[i] & PARTVALID) {
                Zero(pname, 10, char);
                MapPartIdIntoName(dummyPartList.partId[i], pname);
                XPUSHs(sv_2mortal(newSVpv(pname, strlen(pname))));
                total++;
            }
        }

        SETCODE(0);
        XSRETURN(total);
    }

void
vos_listvolume(cstruct, name)
        AFS::VOS cstruct
        char *name
    PREINIT:
        struct nvldbentry entry;
        afs_int32 vcode = 0;
        volintInfo *pntr = (volintInfo *)0;
        afs_int32 volid;
        afs_int32 code, err;
        int voltype, foundserv = 0, foundentry = 0;
        afs_int32 aserver, apart;
        char apartName[10];
        int previdx = -1;
        HV *volinfo = (HV*)sv_2mortal((SV*)newHV());
    PPCODE:
    {
        volid = vsu_GetVolumeID(name, cstruct, &err);   /* -id */
        if (volid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "Unknown volume ID or name '%s'\n", name);
            VSETCODE(err ? err : -1, buffer);
            XSRETURN_UNDEF;
        }
        vcode = VLDB_GetEntryByID(volid, -1, &entry);
        if (vcode) {
            char buffer[256];
            sprintf(buffer, "Could not fetch the entry for volume number %u from VLDB \n", volid);
            VSETCODE(vcode, buffer);
            XSRETURN_UNDEF;
        }
        MapHostToNetwork(&entry);
        if (entry.volumeId[RWVOL] == volid)
            voltype = RWVOL;
        else if (entry.volumeId[BACKVOL] == volid)
            voltype = BACKVOL;
        else                            /* (entry.volumeId[ROVOL] == volid) */
            voltype = ROVOL;

        do {                            /* do {...} while (voltype == ROVOL) */
            /* Get the entry for the volume. If its a RW vol, get the RW entry.
             * It its a BK vol, get the RW entry (even if VLDB may say the BK doen't exist).
             * If its a RO vol, get the next RO entry.
             */
            GetServerAndPart(&entry, ((voltype == ROVOL) ? ROVOL : RWVOL), &aserver, &apart,
                             &previdx);
            if (previdx == -1) {        /* searched all entries */
                if (!foundentry) {
                    char buffer[256];
                    sprintf(buffer, "Volume %s does not exist in VLDB\n\n", name);
                    VSETCODE(ENOENT, buffer);
                    XSRETURN_UNDEF;
                }
                break;
            }
            foundentry = 1;

            /* Get information about the volume from the server */
            code = UV_ListOneVolume(aserver, apart, volid, &pntr);

            if (code) {
                char buffer[256];
                if (code == ENODEV) {
                    if ((voltype == BACKVOL) && !(entry.flags & BACK_EXISTS)) {
                        /* The VLDB says there is no backup volume and its not on disk */
                        sprintf(buffer, "Volume %s does not exist\n", name);
                    }
                    else {
                        sprintf(buffer,
                                "Volume does not exist on server %s as indicated by the VLDB\n",
                                hostutil_GetNameByINet(aserver));
                    }
                }
                else {
                    sprintf(buffer, "examine");
                }
                if (pntr)
                    free(pntr);
                VSETCODE(code, buffer);
                XSRETURN_UNDEF;
            }
            else {
                foundserv = 1;
                MapPartIdIntoName(apart, apartName);
                /* safe_hv_store(volinfo, "name", 4, newSVpv(name, strlen((char *) name)), 0); */
                safe_hv_store(volinfo, "partition", 9, newSVpv(apartName, strlen((char *) apartName)), 0);
                VolumeStats(volinfo, pntr, &entry, aserver, apart, voltype);

                if ((voltype == BACKVOL) && !(entry.flags & BACK_EXISTS)) {
                    /* The VLDB says there is no backup volume yet we found one on disk */
                    char buffer[256];
                    sprintf(buffer, "Volume %s does not exist in VLDB\n", name);
                    if (pntr)
                        free(pntr);
                    VSETCODE(ENOENT, buffer);
                    XSRETURN_UNDEF;
                }
            }

            if (pntr)
                free(pntr);
        } while (voltype == ROVOL);

        SETCODE(0);
        ST(0) = sv_2mortal(newRV_inc((SV *) volinfo));
        XSRETURN(1);
    }


MODULE = AFS     PACKAGE = AFS::VLDB       PREFIX = vldb_

AFS::VLDB
vldb_new(class=0, verb=0, timeout=90, noauth=0, localauth=0, tcell=NULL, crypt=0)
        char *  class
        int     verb
        int     timeout
        int     noauth
        int     localauth
        char *  tcell
        int     crypt
    PREINIT:
        int32 code = -1;
        extern int verbose;
    PPCODE:
    {
        if (tcell && (tcell[0] == '\0' || tcell[0] == '0'))
            tcell = NULL;

                /* Initialize the ubik_client connection */
        rx_SetRxDeadTime(timeout);      /* timeout seconds inactivity before declared dead */
        cstruct = (struct ubik_client *) 0;
        verbose = verb;
        if (crypt)                      /* -crypt specified */
            vsu_SetCrypt(1);
        code = internal_vsu_ClientInit((noauth != 0),
                                       AFSDIR_CLIENT_ETC_DIRPATH, tcell, localauth,
                                       &cstruct, UV_SetSecurity);
        if (code == 0) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AFS::VLDB", (void *) cstruct);
            XSRETURN(1);
        }
        else
            XSRETURN_UNDEF;
    }

int32
vldb__DESTROY(self)
        AFS::VLDB self
    PREINIT:
        int32 code = 0;
    CODE:
    {
        code = ubik_ClientDestroy(self);
                /* printf("DEBUG-23 %d \n", code); */
        SETCODE(code);
                /* printf("DEBUG-24 \n"); */
        RETVAL = (code == 0);
                /* printf("DEBUG-25 \n"); */
    }
    OUTPUT:
        RETVAL

int32
vldb_addsite(cstruct, server, partition, id, roid=NULL, valid=0)
       AFS::VLDB cstruct
       char *server
       char *partition
       char *id
       char *roid
       int  valid
    PREINIT:
       int32 code = 1;
    CODE:
    {
        afs_int32 avolid, aserver, apart, err, arovolid=0;
        char avolname[VOLSER_MAXVOLNAME + 1];
        if (roid && (roid[0] == '\0' || roid[0] == '0'))
            roid = NULL;
        RETVAL = 0;
        /* printf("vldb_addsite DEBUG-1 server %s part %s Vol/Id %s RO-Vol/ID %s ValID %d \n", server, partition, id, roid, valid); */
#ifdef OpenAFS_1_4
        vsu_ExtractName(avolname, id);
#else
        strcpy(avolname, id);
#endif
        /* printf("vldb_addsite DEBUG-2 id %s avolname %s \n", id, avolname); */
        avolid = vsu_GetVolumeID(avolname, cstruct, &err);
        /* printf("vldb_addsite DEBUG-3 Vol-Nam %s Vol-ID %d \n", avolname, avolid); */
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VLDB: can't find volume '%s'\n", id);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }
#ifdef OpenAFS_1_4_12
        if (roid) {
            /* printf("vldb_addsite DEBUG-4 Roid %s AROVolid %d\n", roid, arovolid); */
            vsu_ExtractName(avolname, roid);
            arovolid = vsu_GetVolumeID(avolname, cstruct, &err);
            /* printf("vldb_addsite DEBUG-5 Roid %s AROVolid %d\n", roid, arovolid); */
            if (!arovolid) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: invalid ro volume id '%s'\n", roid);
                VSETCODE(-1, buffer);
                goto done;
            }
        }
#endif
        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            goto done;
        }
        apart = volutil_GetPartitionID(partition);
        if (apart < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n", partition);
            VSETCODE(-1, buffer);
            goto done;
        }
        if (!IsPartValid(apart, aserver, &code)) {      /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VLDB: partition %s does not exist on the server\n",
                        partition);
            VSETCODE(code ? code : -1, buffer);
            goto done;
        }
#if defined(OpenAFS_1_4_12)
        code = UV_AddSite2(aserver, apart, avolid, arovolid, valid);
#else
#if defined(OpenAFS_1_4_07)
        code = UV_AddSite(aserver, apart, avolid, valid);
#else
        code = UV_AddSite(aserver, apart, avolid);
#endif
#endif
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: addsite didn't work\n");
            VSETCODE(code, buffer);
            goto done;
        }
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb_changeloc(cstruct, id, server, partition)
        AFS::VLDB cstruct
        char *id
        char *server
        char *partition
    PREINIT:
#ifdef OpenAFS
        afs_int32 avolid, aserver, apart, code, err;
#endif
    CODE:
    {
#ifdef OpenAFS
        /* printf("DEBUG-1\n"); */
        RETVAL = 0;
        avolid = vsu_GetVolumeID(id, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VLDB: can't find volume '%s'\n", id);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }
        /* printf("DEBUG-2\n"); */
        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            goto done;
        }
        /* printf("DEBUG-3\n"); */
        apart = volutil_GetPartitionID(partition);
        if (apart < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n", partition);
            VSETCODE(-1, buffer);
            /* printf("DEBUG-3.1\n"); */
            goto done;
        }
        /* printf("DEBUG-4\n"); */
        if (!IsPartValid(apart, aserver, &code)) {      /*check for validity of the partition */
            char buffer[256];
            if (code)
                set_errbuff(buffer, code);
            else
                sprintf(buffer, "AFS::VLDB: partition %s does not exist on the server\n", server);
            VSETCODE(code ? code : -1, buffer);
            goto done;
        }
        /* printf("DEBUG-5\n"); */
        code = UV_ChangeLocation(aserver, apart, avolid);
        if (code) {
            VSETCODE(code, "changeloc");
            goto done;
        }
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
#else
        not_here("AFS::VLDB::changeloc");
#endif
    }
    OUTPUT:
        RETVAL

void
vldb__listvldb(cstruct, name=NULL, servername=NULL, parti=NULL, lock=0)
        AFS::VLDB cstruct
        char *name
        char *servername
        char *parti
        int lock
    PREINIT:
        afs_int32 apart;
        afs_int32 aserver, code;
        afs_int32 vcode;
        struct VldbListByAttributes attributes;
        nbulkentries arrayEntries;
        struct nvldbentry *vllist;
        afs_int32 centries, nentries = 0;
        int j;
        afs_int32 thisindex, nextindex;
        HV *status, *stats;
    PPCODE:
    {
        status = (HV *) sv_2mortal((SV *) newHV());
        if (name && strlen(name) == 0)
            name = NULL;
        if (servername && strlen(servername) == 0)
            servername = NULL;
        if (parti && strlen(parti) == 0)
            parti = NULL;

        /* printf("DEBUG-0 name %s, server %s, part %s lock %d \n", name, servername, parti,  */

        aserver = 0;
        apart = 0;

        attributes.Mask = 0;
        /* printf("DEBUG-1 \n"); */

            /* If the volume name is given, Use VolumeInfoCmd to look it up
             * and not ListAttributes.
             */
        if (name) {
          /* printf("DEBUG-2 \n"); */
            if (lock) {
                char buffer[256];
                /*     printf("DEBUG-3 \n"); */
                sprintf(buffer,
                        "AFS::VLDB: illegal use of '-locked' switch, need to specify server and/or partition\n");
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            /* printf("DEBUG-4 \n"); */
            stats = (HV *) sv_2mortal((SV *) newHV());
            code = VolumeInfoCmd(stats, name);
            if (code) {
                char buffer[256];
                set_errbuff(buffer, code);
                VSETCODE(code, buffer);
                XSRETURN_UNDEF;
            }
            /* printf("DEBUG-5 \n"); */
            safe_hv_store(status, name, strlen(name), newRV_inc((SV *) (stats)), 0);
            goto finish;
        }

            /* Server specified */
        /* printf("DEBUG-6 \n"); */
        if (servername) {
            /* printf("DEBUG-7 \n"); */
            aserver = GetServer(servername);
            if (aserver == 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: server '%s' not found in host table\n", servername);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            attributes.server = ntohl(aserver);
            attributes.Mask |= VLLIST_SERVER;
        }

            /* Partition specified */
        /* printf("DEBUG-8 \n"); */
        if (parti) {
            /* printf("DEBUG-9 \n"); */
            apart = volutil_GetPartitionID(parti);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n", parti);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            attributes.partition = apart;
            attributes.Mask |= VLLIST_PARTITION;
        }

        /* printf("DEBUG-10 \n"); */
        if (lock) {
            /* printf("DEBUG-11 \n"); */
            attributes.Mask |= VLLIST_FLAG;
            attributes.flag = VLOP_ALLOPERS;
        }

        /* printf("DEBUG-12 \n"); */
        for (thisindex = 0; (thisindex != -1); thisindex = nextindex) {
             /* printf("DEBUG-13 \n"); */
            /* memset(&arrayEntries, 0, sizeof(arrayEntries)); */
            /* Zero(&arrayEntries, sizeof(arrayEntries), nbulkentries);  ??? nog ???  */
            Zero(&arrayEntries, 1, nbulkentries);
            /* printf("DEBUG-14 \n"); */
            centries = 0;
            nextindex = -1;

            vcode = VLDB_ListAttributesN2(&attributes, 0, thisindex,
                                          &centries, &arrayEntries, &nextindex);
            /* printf("DEBUG-15 \n"); */
            if (vcode == RXGEN_OPCODE) {
                /* Vlserver not running with ListAttributesN2. Fall back */
                vcode = VLDB_ListAttributes(&attributes, &centries, &arrayEntries);
                nextindex = -1;
            }
            /* printf("DEBUG-16 \n"); */
            if (vcode) {
                char buffer[256];
                sprintf(buffer, "Could not access the VLDB for attributes\n");
                VSETCODE(vcode, buffer);
                XSRETURN_UNDEF;
            }
            nentries += centries;

            /* We don't sort, so just print the entries now */
            /* printf("DEBUG-17 \n"); */
            for (j = 0; j < centries; j++) {    /* process each entry */
                /* printf("DEBUG-18 \n"); */
                vllist = &arrayEntries.nbulkentries_val[j];
                MapHostToNetwork(vllist);
                stats = newHV();
                myEnumerateEntry(stats, vllist);
                safe_hv_store(status, vllist->name, strlen(vllist->name), newRV_inc((SV *) (stats)),
                         0);
            }
            if (arrayEntries.nbulkentries_val)
                free(arrayEntries.nbulkentries_val);
        }

        finish:
        /* printf("DEBUG-19 \n"); */
        SETCODE(0);
        ST(0) = sv_2mortal(newRV_inc((SV *) status));
        XSRETURN(1);
    }

void
vldb_listaddrs(cstruct, host=NULL, uuid=NULL, noresolve=0, printuuid=0)
        AFS::VLDB cstruct
        char *host
        char *uuid
        int noresolve
        int printuuid
    PREINIT:
        afs_int32 vcode;
        afs_int32 i, j;
        afs_int32            nentries;
        bulkaddrs            m_addrs;
        ListAddrByAttributes m_attrs;
        afsUUID              m_uuid, askuuid;
        afs_int32            m_unique, m_nentries;
    PPCODE:
    {
        Zero(&m_attrs, 1, ListAddrByAttributes);
        m_attrs.Mask = VLADDR_INDEX;

        Zero(&m_addrs, 1, bulkaddrs);
        Zero(&askuuid, 1, afsUUID);
#ifdef OpenAFS
        if (uuid && strlen(uuid) != 0) {
            /* -uuid */
            afsUUID_from_string(uuid, &askuuid);
            m_attrs.Mask = VLADDR_UUID;
            m_attrs.uuid = askuuid;
        }
        else
#endif
            uuid = NULL;

        if (host && strlen(host) != 0) {
            /* -host */
            struct hostent *he;
            afs_int32 saddr;
            he = (struct hostent *) hostutil_GetHostByName(host);
            if (he == (struct hostent *) 0) {
                char buffer[256];
                sprintf(buffer, "Can't get host info for '%s'\n", host);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            /*memcpy(&saddr, he->h_addr, 4); */
            /* Copy(he->h_addr, &saddr, sizeof(afs_int32), afs_int32); */
            Copy(he->h_addr, &saddr, he->h_length, char);
            m_attrs.Mask = VLADDR_IPADDR;
            m_attrs.ipaddr = ntohl(saddr);
        }
        else
            host = NULL;

        m_addrs.bulkaddrs_val = 0;
        m_addrs.bulkaddrs_len = 0;

        vcode = ubik_Call_New(VL_GetAddrs, cstruct, 0, 0, 0, &m_unique, &nentries, &m_addrs);
        if (vcode) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: could not list the server addresses\n");
            VSETCODE(vcode, buffer);
            XSRETURN_UNDEF;
        }

        m_nentries = 0;
        m_addrs.bulkaddrs_val = 0;
        m_addrs.bulkaddrs_len = 0;
        i = 1;
        j = 0;
        while (1) {
            HV *addr = (HV *) sv_2mortal((SV *) newHV());
            m_attrs.index = i;

            vcode = ubik_Call_New(VL_GetAddrsU, cstruct, 0, &m_attrs, &m_uuid,
                                  &m_unique, &m_nentries, &m_addrs);
            if (vcode == VL_NOENT) {
                i++;
                nentries++;
                continue;
            }

            if (vcode == VL_INDEXERANGE) {
                vcode = 0;
                break;
            }

            if (vcode) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: could not list the server addresses\n");
                VSETCODE(vcode, buffer);
                XSRETURN_UNDEF;
            }

            myprint_addrs(addr, &m_addrs, &m_uuid, m_nentries, printuuid, noresolve);
            XPUSHs(sv_2mortal(newRV_inc((SV *) (addr))));
            i++;
            j++;

            if (host || uuid || (i > nentries))
                break;
        }

        SETCODE(vcode);
        XSRETURN(j);
    }

void
vldb__delentry(cstruct, volume=NULL, prfx=NULL, server=NULL, partition=NULL, noexecute=0)
        AFS::VLDB cstruct
        SV* volume
        char *prfx
        char *server
        char *partition
        int noexecute
    PREINIT:
        afs_int32 apart;
        afs_int32 avolid;
        afs_int32 vcode = 0;
        struct VldbListByAttributes attributes;
        nbulkentries arrayEntries;
        register struct nvldbentry *vllist;
        SV *vol;
        char *itp;
        afs_int32 nentries;
        int j;
        char prefix[VOLSER_MAXVOLNAME+1];
        int seenprefix=0;
        STRLEN volumelength=0;
        afs_int32 totalBack=0, totalFail=0, err;
        AV *av;
    PPCODE:
    {
        if (prfx && strlen(prfx) == 0)
            prfx = NULL;
        if (partition && strlen(partition) == 0)
            partition = NULL;
        if (server && strlen(server) == 0)
            server = NULL;

        if (volume && (volumelength = sv_len(volume)) == 0)
            volume = NULL;

        if (volume && (! (SvTYPE(SvRV(volume)) == SVt_PVAV))) {
            VSETCODE(-1, "AFS::VLDB: VOLUME not array reference");
            XSRETURN_UNDEF;
        }

        if (volume) {                       /* -id */
            int len;
            if (prfx || server || partition) {
                VSETCODE(-1, "You cannot use SERVER, PARTITION, or PREFIX with the VOLUME argument");
                XSRETURN_UNDEF;
            }
            av = (AV *) SvRV(volume);
            len = av_len(av);
            if (len != -1) {
                for (j = 0; j <= len; j++) {
                    vol = *av_fetch(av, j, 0);
                    itp = SvPV_nolen(vol);
                    if (itp) {
                        avolid = vsu_GetVolumeID(itp, cstruct, &err);
                        if (avolid == 0) {
                            char buffer[256];
                            if (err)
                                set_errbuff(buffer, err);
                            else
                                sprintf(buffer, "AFS::VLDB: can't find volume '%s'\n", itp);
                            VSETCODE(err ? err : -1, buffer);
                            continue;
                        }
                        if (noexecute) {        /* -noexecute */
                            fprintf(STDOUT, "Would have deleted VLDB entry for %s \n", itp);
                            fflush(STDOUT);
                            continue;
                        }
                        vcode = ubik_Call(VL_DeleteEntry, cstruct, 0, avolid, RWVOL);
                        if (vcode) {
                            char buffer[256];
                            sprintf(buffer, "Could not delete entry for volume %s\n"
                                    "You must specify a RW volume name or ID "
                                    "(the entire VLDB entry will be deleted)\n", itp);
                            VSETCODE(vcode, buffer);
                            totalFail++;
                            continue;
                        }
                        totalBack++;
                    }
                }                       /* for */
            }                           /* len */
            EXTEND(sp, 2);
            PUSHs(sv_2mortal(newSViv(totalBack)));
            PUSHs(sv_2mortal(newSViv(totalFail)));
            goto done;
        }                               /* id */

        if (!prfx && !server && !partition) {
            VSETCODE(-1, "You must specify an argument");
            XSRETURN_UNDEF;
        }

            /* Zero out search attributes */
        Zero(&attributes, 1, VldbListByAttributes);

        if (prfx) {                     /* -prefix */
            strncpy(prefix, prfx, VOLSER_MAXVOLNAME);
            seenprefix = 1;
            if (!server && !partition) {        /* a single entry only */
                VSETCODE(-1, "You must provide SERVER with the PREFIX argument");
                XSRETURN_UNDEF;
            }
        }

        if (server) {                   /* -server */
            afs_int32 aserver;
            aserver = GetServer(server);
            if (aserver == 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: server '%s' not found in host table\n", server);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            attributes.server = ntohl(aserver);
            attributes.Mask |= VLLIST_SERVER;
        }

        if (partition) {                /* -partition */
            if (!server) {
                VSETCODE(-1, "You must provide SERVER with the PARTITION argument");
                XSRETURN_UNDEF;
            }
            apart = volutil_GetPartitionID(partition);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n",
                        partition);
                VSETCODE(-1, buffer);
                XSRETURN_UNDEF;
            }
            attributes.partition = apart;
            attributes.Mask |= VLLIST_PARTITION;
        }

            /* Print status line of what we are doing */
        #fprintf(STDOUT, "Deleting VLDB entries for ");
        #if (server) {
        #    fprintf(STDOUT, "server %s ", server);
        #}
        #if (partition) {
        #    char pname[10];
        #    MapPartIdIntoName(apart, pname);
        #    fprintf(STDOUT, "partition %s ", pname);
        #}
        #if (seenprefix) {
        #    fprintf(STDOUT, "which are prefixed with %s ", prefix);
        #}
        #fprintf(STDOUT, "\n");
        #fflush(STDOUT);

            /* Get all the VLDB entries on a server and/or partition */
        Zero(&arrayEntries, 1, nbulkentries);
        vcode = VLDB_ListAttributes(&attributes, &nentries, &arrayEntries);
        if (vcode) {
            VSETCODE(vcode, "Could not access the VLDB for attributes");
            XSRETURN_UNDEF;
        }

            /* Process each entry */
        for (j = 0; j < nentries; j++) {
            vllist = &arrayEntries.nbulkentries_val[j];
            if (seenprefix) {
                /* It only deletes the RW volumes */
                if (strncmp(vllist->name, prefix, strlen(prefix))) {
                    fflush(STDOUT);
                    continue;
                }
            }

            if (noexecute) {            /* -noexecute */
                fprintf(STDOUT, "Would have deleted VLDB entry for %s \n", vllist->name);
                fflush(STDOUT);
                continue;
            }

            /* Only matches the RW volume name */
            avolid = vllist->volumeId[RWVOL];
            vcode = ubik_Call(VL_DeleteEntry, cstruct, 0, avolid, RWVOL);
            if (vcode) {
                fprintf(STDOUT, "Could not delete VDLB entry for  %s\n", vllist->name);
                totalFail++;
                PrintError("", vcode);
                continue;
            }
            else {
                totalBack++;
            }
            fflush(STDOUT);
        }                               /*for */

        EXTEND(sp, 2);
        PUSHs(sv_2mortal(newSViv(totalBack)));
        PUSHs(sv_2mortal(newSViv(totalFail)));

        if (arrayEntries.nbulkentries_val)
            free(arrayEntries.nbulkentries_val);

        done:
        ;
    }

int32
vldb_lock(cstruct, id)
        AFS::VLDB cstruct
        char *id
    PREINIT:
        afs_int32 avolid, vcode, err;
    CODE:
    {
        RETVAL = 0;
        avolid = vsu_GetVolumeID(id, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VLDB: can't find volume '%s'\n", id);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }
        vcode = ubik_Call(VL_SetLock, cstruct, 0, avolid, -1, VLOP_DELETE);
        if (vcode) {
            char buffer[256];
            sprintf(buffer, "Could not lock VLDB entry for volume %s\n", id);
            VSETCODE(vcode, buffer);
            goto done;
        }
            /*     fprintf(STDOUT, "Locked VLDB entry for volume %s\n", id); */
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb_unlock(cstruct, id)
        AFS::VLDB cstruct
        char *id
    PREINIT:
        afs_int32 avolid, code, err;
    CODE:
    {
        RETVAL = 0;
        avolid = vsu_GetVolumeID(id, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VLDB: can't find volume '%s'\n", id);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }

        code = UV_LockRelease(avolid);
        if (code) {
            VSETCODE(code, "unlock");
            goto done;
        }
                /* fprintf(STDOUT,"Released lock on vldb entry for volume %s\n",id); */
        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb_unlockvldb(cstruct, server=NULL, partition=NULL)
        AFS::VLDB cstruct
        char *server
        char *partition
    PREINIT:
        afs_int32 apart = -1;
        afs_int32 aserver = 0,code;
        afs_int32 vcode;
        struct VldbListByAttributes attributes;
        nbulkentries arrayEntries;
        register struct nvldbentry *vllist;
        afs_int32 nentries;
        int j;
        afs_int32 volid;
        afs_int32 totalE = 0;
    CODE:
    {
        RETVAL = 0;
        attributes.Mask = 0;

        if (server && (strlen(server) != 0)) {  /* server specified */
            aserver = GetServer(server);
            if (aserver == 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: server '%s' not found in host table\n", server);
                VSETCODE(-1, buffer);
                goto done;
            }
            attributes.server = ntohl(aserver);
            attributes.Mask |= VLLIST_SERVER;
        }

        if (partition && (strlen(partition) != 0)) {    /* partition specified */
            apart = volutil_GetPartitionID(partition);
            if (apart < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n",
                        partition);
                VSETCODE(-1, buffer);
                goto done;
            }
            if (!IsPartValid(apart, aserver, &code)) {  /*check for validity of the partition */
                char buffer[256];
                if (code)
                    set_errbuff(buffer, code);
                else
                    sprintf(buffer, "AFS::VLDB: partition %s does not exist on the server\n",
                            partition);
                VSETCODE(code ? code : -1, buffer);
                goto done;
            }
            attributes.partition = apart;
            attributes.Mask |= VLLIST_PARTITION;
        }
        attributes.flag = VLOP_ALLOPERS;
        attributes.Mask |= VLLIST_FLAG;
        Zero(&arrayEntries, 1, nbulkentries);   /*initialize to hint the stub  to alloc space */
        vcode = VLDB_ListAttributes(&attributes, &nentries, &arrayEntries);
        if (vcode) {
            char buffer[256];
            sprintf(buffer, "Could not access the VLDB for attributes\n");
            VSETCODE(vcode, buffer);
            goto done;
        }
        for (j = 0; j < nentries; j++) {        /* process each entry */
            vllist = &arrayEntries.nbulkentries_val[j];
            volid = vllist->volumeId[RWVOL];
            vcode =
                ubik_Call(VL_ReleaseLock, cstruct, 0, volid, -1,
                          LOCKREL_OPCODE | LOCKREL_AFSID | LOCKREL_TIMESTAMP);
            if (vcode) {
                char buffer[256];
                sprintf(buffer, "Could not unlock entry for volume %s\n", vllist->name);
                VSETCODE(vcode, buffer);
                totalE++;
            }

        }

        if (totalE)
            fprintf(STDOUT, "Could not unlock %u VLDB entries of %u locked entries\n", totalE,
                nentries);

        if (arrayEntries.nbulkentries_val)
            free(arrayEntries.nbulkentries_val);

        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb__syncvldb(cstruct, server=NULL, partition=NULL, volname=NULL)
        AFS::VLDB cstruct
        char *server
        char *partition
        char *volname
    PREINIT:
        afs_int32 pname = 0, code;        /* part name */
        int flags = 0;
        afs_int32 tserver = 0;
    CODE:
    {
        RETVAL = 0;
        /* printf("server %s, part %s volume %s \n", server, partition, volname); */
        if (server && (strlen(server) != 0)) {
            tserver = GetServer(server);
            if (!tserver) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: host '%s' not found in host table\n", server);
                VSETCODE(-1, buffer);
                goto done;
            }
        }

        if (partition && (strlen(partition) != 0)) {
            pname = volutil_GetPartitionID(partition);
            if (pname < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n",
                        partition);
                VSETCODE(-1, buffer);
                goto done;
            }
            if (!tserver) {
                char buffer[256];
                sprintf(buffer, "The PARTITION argument requires a SERVER argument\n");
                VSETCODE(-1, buffer);
                goto done;
            }

            if (!IsPartValid(pname, tserver, &code)) {  /*check for validity of the partition */
                char buffer[256];
                if (code)
                    set_errbuff(buffer, code);
                else
                    sprintf(buffer, "AFS::VLDB: partition %s does not exist on the server\n",
                            partition);
                VSETCODE(code ? code : -1, buffer);
                goto done;
            }
            flags = 1;
        }

        if (volname && (strlen(volname) != 0)) {
            /* Synchronize an individual volume */
            code = UV_SyncVolume(tserver, pname, volname, flags);
        }
        else {
            if (!tserver) {
                char buffer[256];
                sprintf(buffer, "Without a VOLUME argument, the server argument is required\n");
                VSETCODE(-1, buffer);
                goto done;
            }
            code = UV_SyncVldb(tserver, pname, flags, 0 /*unused */ );
        }

        if (code) {
            char buffer[256];
            set_errbuff(buffer, code);
            VSETCODE(code, buffer);
            #PrintDiagnostics("syncvldb", code);
            #SETCODE(code);
            goto done;
        }
        else
            SETCODE(0);

        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb__changeaddr(cstruct, oldip, newip, remove=0)
        AFS::VLDB cstruct
        char *oldip
        char *newip
        int32 remove
    PREINIT:
        int32 ip1, ip2, vcode;
    CODE:
    {
        RETVAL = 0;

        ip1 = GetServer(oldip);
        if (!ip1) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: invalid host address\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }

        if ((newip && (strlen(newip)) && remove) || (!newip && !remove)) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: Must specify either 'NEWADDR <addr>' or 'REMOVE' flag\n");
            VSETCODE(EINVAL, buffer);
            goto done;
        }

        if (newip && (strlen(newip)) != 0) {
            ip2 = GetServer(newip);
            if (!ip2) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: invalid host address\n");
                VSETCODE(EINVAL, buffer);
                goto done;
            }
        }
        else {
            /* Play a trick here. If we are removing an address, ip1 will be -1
             * and ip2 will be the original address. This switch prevents an
             * older revision vlserver from removing the IP address.
             */
            remove = 1;
            ip2 = ip1;
            ip1 = 0xffffffff;
        }

        vcode = ubik_Call_New(VL_ChangeAddr, cstruct, 0, ntohl(ip1), ntohl(ip2));
        if (vcode) {
            char buffer[256];
            if (remove) {
                char buff[80];
                sprintf(buff, "Could not remove server %s from the VLDB", oldip);
                if (vcode == VL_NOENT) {
                    sprintf(buffer, "%s\nvlserver does not support the REMOVE flag or VLDB: no such entry", buff);
                }
                else {
                    sprintf(buffer, "%s\n", buff);
                }
            }
            else {
                sprintf(buffer, "Could not change server %s to server %s\n", oldip, newip);
            }
            VSETCODE(vcode, buffer);
            goto done;
        }

        if (remove) {
            fprintf(STDOUT, "Removed server %s from the VLDB\n", oldip);
        }
        else {
            fprintf(STDOUT, "Changed server %s to server %s\n", oldip, newip);
        }

        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb_remsite(cstruct,server,partition,name)
        AFS::VLDB cstruct
        char *server
        char *partition
        char *name
    PREINIT:
        afs_int32 avolid, aserver, apart, code = 1, err;
        char avolname[VOLSER_MAXVOLNAME + 1];
    CODE:
    {
        RETVAL = 0;
#ifdef OpenAFS_1_4
        vsu_ExtractName(avolname, name);
#else
        strcpy(avolname, name);
#endif
        avolid = vsu_GetVolumeID(avolname, cstruct, &err);
        if (avolid == 0) {
            char buffer[256];
            if (err)
                set_errbuff(buffer, err);
            else
                sprintf(buffer, "AFS::VLDB: can't find volume '%s'\n", avolname);
            VSETCODE(err ? err : -1, buffer);
            goto done;
        }
        aserver = GetServer(server);
        if (aserver == 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: server '%s' not found in host table\n", server);
            VSETCODE(-1, buffer);
            goto done;
        }
        apart = volutil_GetPartitionID(partition);
        if (apart < 0) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n", partition);
            VSETCODE(-1, buffer);
            goto done;
        }
        code = UV_RemoveSite(aserver, apart, avolid);
        printf("\n");
        if (code) {
            PrintDiagnostics("remsite", code);
            SETCODE(code);
            goto done;
        }
        RETVAL = 1;
        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
vldb_syncserv(cstruct, servername, parti=NULL)
        AFS::VLDB cstruct
        char *servername
        char *parti
    PREINIT:
        afs_int32 pname = 0, code;       /* part name */
        afs_int32 tserver;
        int flags = 0;
    CODE:
    {
        RETVAL = 0;
        tserver = GetServer(servername);
        if (!tserver) {
            char buffer[256];
            sprintf(buffer, "AFS::VLDB: host '%s' not found in host table\n", servername);
            VSETCODE(-1, buffer);
            goto done;
        }
        if (parti && (strlen(parti) != 0)) {
            pname = volutil_GetPartitionID(parti);
            if (pname < 0) {
                char buffer[256];
                sprintf(buffer, "AFS::VLDB: could not interpret partition name '%s'\n", parti);
                VSETCODE(-1, buffer);
                goto done;
            }
            if (!IsPartValid(pname, tserver, &code)) {  /*check for validity of the partition */
                char buffer[256];
                if (code)
                    set_errbuff(buffer, code);
                else
                    sprintf(buffer, "AFS::VLDB: partition %s does not exist on the server\n",
                            parti);
                VSETCODE(code ? code : -1, buffer);
                goto done;
            }
            flags = 1;
        }

        code = UV_SyncServer(tserver, pname, flags, 0 /*unused */ );
        if (code) {
            PrintDiagnostics("syncserv", code);
            SETCODE(code);
            goto done;
        }

        SETCODE(0);
        RETVAL = 1;

        done:
        ;
    }
    OUTPUT:
        RETVAL


MODULE = AFS            PACKAGE = AFS::BOS      PREFIX = bos_

AFS::BOS
bos_new(class=0, servname, noauth=0, localauth=0, cell=0, aencrypt=1)
        char *  class
        char *servname
        int noauth
        int localauth
        char *cell
        int aencrypt
    PREINIT:
        int32 code = -1;
        AFS__BOS server;
    PPCODE:
    {
        /* printf("bos new DEBUG-1 \n"); */
        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        /* printf("bos new call internal_new DEBUG-2 \n"); */
        server = internal_bos_new(&code, servname, localauth, noauth, aencrypt, cell);
            /* SETCODE(code); */
        /* printf("bos new return internal_new DEBUG-3 \n"); */

        if (code == 0) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AFS::BOS", (void *) server);
            XSRETURN(1);
        }
        else
            XSRETURN_UNDEF;
    }

int32
bos__DESTROY(self)
        AFS::BOS self
    CODE:
    {
        rx_DestroyConnection(self);
        /* printf("bos DEBUG rx_Destroy\n"); */
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

void
bos__status(self, lng=0, object=NULL)
        AFS::BOS self
        int lng
        SV* object
    PREINIT:
        int i;
        afs_int32 code = 0;
        char ibuffer[BOZO_BSSIZE];
        char *tp;
        int int32p;
        HV *status, *stats;
    PPCODE:
    {
        int32p = (lng != 0 ? 2 : 0);
        status = (HV *) sv_2mortal((SV *) newHV());

        if (object && (! (SvTYPE(SvRV(object)) == SVt_PVAV))) {
            BSETCODE(-1, "AFS::BOS: SERVER not an array reference\n");
            XSRETURN_UNDEF;
            goto done;
        }

        if (object && (SvTYPE(SvRV(object)) == SVt_PVAV)) {
            AV *av;
            SV *sv;
            char *instance;
            STRLEN namelen;
            int i, len;
            int firstTime = 1;

            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                        stats = (HV *) sv_2mortal((SV *) newHV());
                        instance = (char *) safemalloc(BOZO_BSSIZE);
                        instance = SvPV(sv, namelen);
                        code = DoStat(stats, instance, self, int32p, firstTime);
                        if (code) {
                            XSRETURN_UNDEF;
                            goto done;
                        }
                        safe_hv_store(status, instance, strlen(instance), newRV_inc((SV *) (stats)),
                                 0);
                        firstTime = 0;
                    }
                }
            }
        }
        else {
            for (i = 0;; i++) {
                /* for each instance */
                tp = ibuffer;
                code = BOZO_EnumerateInstance(self, i, &tp);
                if (code == BZDOM) {
                    code = 0;
                    break;
                }
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: failed to contact host's bosserver (%s).\n",
                            em(code));
                    BSETCODE(code, buffer);
                    break;
                }
                stats = (HV *) sv_2mortal((SV *) newHV());
                code = DoStat(stats, ibuffer, self, int32p, (i == 0));
                if (code) {
                    XSRETURN_UNDEF;
                    goto done;
                }
                safe_hv_store(status, ibuffer, strlen(ibuffer), newRV_inc((SV *) (stats)), 0);
            }
        }

        ST(0) = sv_2mortal(newRV_inc((SV *) status));
        SETCODE(0);
        XSRETURN(1);

        done:
        ;
  }

int32
bos_setauth(self, tp)
        AFS::BOS self
        char *tp
    PREINIT:
        int32 code = 0;
        int32 flag;
    CODE: 
    {
        not_here("AFS::BOS::setauth");

        RETVAL = 42;
        if (strcmp(tp, "on") == 0)
            flag = 0;                   /* auth req.: noauthflag is false */
        else if (strcmp(tp, "off") == 0)
            flag = 1;
        else {
            char buffer[256];
            sprintf(buffer,
                    "AFS::BOS: illegal authentication specifier '%s', must be 'off' or 'on'.\n",
                    tp);
            BSETCODE(-1, buffer);
            RETVAL = 0;
        }

        if (RETVAL == 42) {
            code = BOZO_SetNoAuthFlag(self, flag);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS %d (failed to set authentication flag)", code);
                BSETCODE(code, buffer);
            }
            SETCODE(code);
            RETVAL = (code == 0);
        }
    }
    OUTPUT:
        RETVAL

int32
bos_exec(self, cmd)
        AFS::BOS self
        char *cmd
    PREINIT:
        int32 code = 0;
    CODE:
    {
        code = BOZO_Exec(self, cmd);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to execute command (%s)\n", em(code));
            BSETCODE(code, buffer);
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos_addhost(self, object, clone=Nullsv)
        AFS::BOS self
        SV* object
        SV *  clone
    PREINIT:
        int32 code = 0;
            int len, i;
            AV *av;
            SV *sv;
            char *host;
            int iclone;
            STRLEN namelen;
    CODE:
    {

        if (!clone) {
            clone = newSViv(0);
        }
        if (!SvIOKp(clone)) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: Flag \"clone\" should be numeric.\n");
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        iclone = SvIV(clone);

        RETVAL = 0;
        if (!SvROK(object)) {
            av = newAV();
            av_push(av,object);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            av = (AV *) SvRV(object);
        }
        else {
            BSETCODE(-1, "AFS::BOS: HOST not an array reference\n");
            XSRETURN_UNDEF;
        }

            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                 if (sv && !SvROK(sv)) {
                        host = SvPV(sv, namelen);
                        if (iclone) {
                            char name[MAXHOSTCHARS];
                            if (namelen > MAXHOSTCHARS - 3) {
                                char buffer[80];
                                sprintf(buffer, "AFS::BOS: host name too long\n");
                                BSETCODE(E2BIG, buffer);
                                goto done;
                            }
                            name[0] = '[';
                            strcpy(&name[1], host);
                            strcat((char *) &name, "]");
                            code = BOZO_AddCellHost(self, name);
                        }
                        else {
                            code = BOZO_AddCellHost(self, host);
                        }
                        if (code) {
                            char buffer[240];
                            sprintf(buffer, "AFS::BOS: failed to add host '%s' (%s)\n", host,
                                    em(code));
                            BSETCODE(code, buffer);
                        }
                    }
                }                       /* for loop */
            }
        SETCODE(code);
        RETVAL = (code == 0);

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
bos_removehost(self, object)
        AFS::BOS self
        SV* object
    PREINIT:
        int32 code = 0;
        char *host;
        int len, i;
        AV *av;
        SV *sv;
    CODE:
    {
        if (!SvROK(object)) {
            av = newAV();
            av_push(av,object);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            av = (AV *) SvRV(object);
        }
        else {
            BSETCODE(-1, "AFS::BOS: HOST not an array reference\n");
            XSRETURN_UNDEF;
        }

        len = av_len(av);
        if (len != -1) {
            for (i = 0; i <= len; i++) {
                sv = *av_fetch(av, i, 0);
                if (sv && !SvROK(sv)) {
                    host = SvPV_nolen(sv);
                    code = BOZO_DeleteCellHost(self, host);
                    if (code) {
                        char buffer[240];
                        sprintf(buffer, "AFS::BOS: failed to delete host '%s' (%s)\n", host,
                                em(code));
                        BSETCODE(code, buffer);
                    }
                }
            }                       /* for loop */
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos_prune(self, all=0, bak=0, old=0, core=0)
        AFS::BOS self
        int all
        int bak
        int old
        int core
    PREINIT:
        int32 code = 0, flags = 0;
    CODE: 
    {
        if (bak)
            flags |= BOZO_PRUNEBAK;
        if (old)
            flags |= BOZO_PRUNEOLD;
        if (core)
            flags |= BOZO_PRUNECORE;
        if (all)
            flags |= 0xff;

        if (!flags) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS nothing to prune");
            BSETCODE(999, buffer);
            RETVAL = 0;
        }
        else {
            code = BOZO_Prune(self, flags);
            if (code) {
              char buffer[256];
              sprintf(buffer, "AFS::BOS has failed to prune server files");
              BSETCODE(code, buffer);
            }
            SETCODE(code);
            RETVAL = (code == 0);
        }
    }
    OUTPUT:
        RETVAL

int32
bos_adduser(self, object)
        AFS::BOS self
        SV * object
    PREINIT:
        int32 code = 0;
        char *name;
        int len, i;
        AV *av;
        SV *sv;
    CODE:
    {
        if (!SvROK(object)) {
            av = newAV();
            av_push(av,object);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            av = (AV *) SvRV(object);
        }
        else {
            BSETCODE(-1, "AFS::BOS: USER not an array reference\n");
            XSRETURN_UNDEF;
        }

        len = av_len(av);
        if (len != -1) {
            for (i = 0; i <= len; i++) {
                sv = *av_fetch(av, i, 0);
                if (sv && !SvROK(sv)) {
                    name = SvPV_nolen(sv);
                    code = BOZO_AddSUser(self, name);
                    if (code) {
                        char buffer[240];
                        sprintf(buffer, "AFS::BOS: failed to add user '%s' (%s)\n", name,
                                em(code));
                        BSETCODE(code, buffer);
                    }
                }
            }                       /* for loop */
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos_removeuser(self, object)
        AFS::BOS self
        SV* object
    PREINIT:
        int32 code = 0;
        char *name;
        int len, i;
        AV *av;
        SV *sv;
    CODE:
    {
        if (!SvROK(object)) {
            av = newAV();
            av_push(av,object);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            av = (AV *) SvRV(object);
        }
        else {
            BSETCODE(-1, "AFS::BOS: USER not an array reference\n");
            XSRETURN_UNDEF;
        }

        len = av_len(av);
        if (len != -1) {
            for (i = 0; i <= len; i++) {
                sv = *av_fetch(av, i, 0);
                if (sv && !SvROK(sv)) {
                    name = SvPV_nolen(sv);
                    code = BOZO_DeleteSUser(self, name);
                    if (code) {
                        char buffer[240];
                        sprintf(buffer, "AFS::BOS: failed to delete user");
                        if (code == ENOENT)
                            sprintf(buffer, "%s (no such user)\n", buffer);
                        else
                            sprintf(buffer, "%s (%s)\n", em(code), buffer);
                        BSETCODE(code, buffer);
                    }
                }
            }                       /* for loop */
        }
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL


int32
bos_addkey(self, kvno, string=NULL)
        AFS::BOS self
        int32 kvno
        char *string
    PREINIT:
        int32 code = 0;
        struct ktc_encryptionKey tkey;
        char *tcell = (char *) 0;    /* use current cell */
        char buf[BUFSIZ], ver[BUFSIZ];
    CODE:
    {
        not_here("AFS::BOS::addkey");

        Zero(&tkey, 1, struct ktc_encryptionKey);

        RETVAL = 42;
        if (string)
            strcpy(buf, string);
        else {
            /* prompt for key */
            code = des_read_pw_string(buf, sizeof(buf), "input key: ", 0);
            if (code || strlen(buf) == 0) {
                char buffer[256];
                sprintf(buffer, "Bad key: \n");
                BSETCODE(code ? code : -1, buffer);
                RETVAL = 0;
            }
            code = des_read_pw_string(ver, sizeof(ver), "Retype input key: ", 0);
            if (code || strlen(ver) == 0) {
                char buffer[256];
                sprintf(buffer, "Bad key: \n");
                BSETCODE(code ? code : -1, buffer);
                RETVAL = 0;
            }
            if (strcmp(ver, buf) != 0) {
                char buffer[256];
                sprintf(buffer, "\nInput key mismatch\n");
                BSETCODE(-1, buffer);
                RETVAL = 0;
            }
        }

        if (RETVAL == 42) {
            if (kvno == 999) {
                /* bcrypt key */
                strcpy((char *) &tkey, buf);
            }
            else {                      /* kerberos key */
                ka_StringToKey(buf, tcell, &tkey);
            }

            code = BOZO_AddKey(self, kvno, &tkey);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: failed to set key %d (%s)\n", kvno, em(code));
                BSETCODE(code, buffer);
            }

            SETCODE(code);
            RETVAL = (code == 0);
        }
        if (tcell)
            free(tcell);
    }
    OUTPUT:
        RETVAL

int32
bos_removekey(self, object)
        AFS::BOS self
        SV* object
    PREINIT:
        int32 code = 0;
        int32 temp;
    CODE:
    {
        not_here("AFS::BOS::removekey");

        if (SvIOK(object)) {
            temp = (int32) SvIV(object);
            code = BOZO_DeleteKey(self, temp);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            /* object is array ref */
            int len, i;
            AV *av;
            SV *sv;

            av = (AV *) SvIV(object);
            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                        temp = SvIV(sv);
                        code = BOZO_DeleteKey(self, temp);
                        if (code) {
                            char buffer[256];
                            sprintf(buffer, "AFS::BOS: failed to deletekey");
                            BSETCODE(code, buffer);
                        }
                    }
                }                       /* for loop */
            }
        }
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos__create(self, name, type, object, notifier=NULL)
        AFS::BOS self
        char *name
        char *type
        SV *object
        char *notifier
    PREINIT:
        int32 i, len, code = 0;
        char *parms[6];
        AV *av; SV *sv;
        STRLEN namelen;
    CODE:
    {
        if (SvTYPE(SvRV(object)) != SVt_PVAV) {
            code = -1;
            BSETCODE(code, "AFS::BOS COMMAND not an array reference\n");
            goto done;
        }

        for (i = 0; i < 6; i++)
            parms[i] = "";

        av = (AV *) SvRV(object);
        len = av_len(av);
        if (len != -1) {
            for (i = 0; i <= len && i < 6; i++) {
                sv = *av_fetch(av, i, 0);
                if (sv)
                    parms[i] = SvPV(sv, namelen);
            }
        }

        if (notifier == NULL)
            notifier = NONOTIFIER;

        code = BOZO_CreateBnode(self, type, name, parms[0], parms[1], parms[2],
                                parms[3], parms[4], notifier);
        if (code) {
            char buffer[256];
            sprintf(buffer,
                    "AFS::BOS: failed to create new server instance %s of type '%s' (%s)\n", name,
                    type, em(code));
            BSETCODE(code, buffer);
            goto done;
        }

        SETCODE(code);
        done:
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos__restart(self, bosserver=0, all=0, object=NULL)
        AFS::BOS self
        int bosserver
        int all
        SV *object
    PREINIT:
        int32 code = 0;
    CODE:
    {
        if (bosserver) {
            if (object != NULL) {
                char buffer[256];
                sprintf(buffer,
                        "AFS::BOS: can't specify both 'bosserver' and specific servers to restart.\n");
                BSETCODE(-1, buffer);
                RETVAL = 0;
                goto done;
            }
            code = BOZO_ReBozo(self);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: failed to restart bosserver (%s)\n", em(code));
                BSETCODE(code, buffer);
            }
            RETVAL = (code == 0);
            goto done;
        }

        if (object == NULL) {
            if (all) {
                code = BOZO_RestartAll(self);
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: failed to restart servers (%s)\n", em(code));
                    BSETCODE(code, buffer);
                }
            }
            else {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: To restart all processes please specify 'all'\n");
                BSETCODE(-1, buffer);
            }
            RETVAL = (code == 0);
            goto done;
        }
        else {
            if (all) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: Can't use 'all' along with individual instances\n");
                BSETCODE(-1, buffer);
                RETVAL = 0;
                goto done;
            }
            else {
                AV *av;
                SV *sv;
                STRLEN namelen;
                char *instance;
                int i, len;

                if (SvTYPE(SvRV(object)) != SVt_PVAV) {
                    BSETCODE(-1, "AFS::BOS: SERVER not an array reference\n");
                    RETVAL = 0;
                    goto done;
                }

                av = (AV *) SvRV(object);
                len = av_len(av);
                if (len != -1) {
                    for (i = 0; i <= len && i < 6; i++) {
                        sv = *av_fetch(av, i, 0);
                        if (sv) {
                            instance = (char *) safemalloc(BOZO_BSSIZE);
                            instance = SvPV(sv, namelen);
                            code = BOZO_Restart(self, instance);
                            if (code) {
                                char buffer[256];
                                sprintf(buffer, "AFS::BOS: failed to restart instance %s (%s)\n",
                                        instance, em(code));
                                BSETCODE(code, buffer);
                            }
                        }
                    }                   /* for loop */
                    SETCODE(code);
                    RETVAL = (code == 0);
                }
            }
        }

        done:
        ;
    }
    OUTPUT:
        RETVAL

int32
bos_setrestart(self, time, general=Nullsv, newbinary=Nullsv)
        AFS::BOS self
        char *time
        SV *  general
        SV *  newbinary
    PREINIT:
        int32 code = 0, count = 0;
        struct ktime restartTime;
        afs_int32 type;
        int igeneral;
        int inewbinary;
    CODE:
    {
        if (!general) {
            general = newSViv(0);
        }
        if (!SvIOKp(general)) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: Flag \"general\" should be numeric.\n");
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        if (!newbinary) {
            newbinary = newSViv(0);
        }
        if (!SvIOKp(newbinary)) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: Flag \"newbinary\" should be numeric.\n");
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        igeneral = SvIV(general);
        inewbinary = SvIV(newbinary);
        if (igeneral) {
            count++;
            type = 1;
        }
        if (inewbinary) {
            count++;
            type = 2;
        }
        if (count > 1) {
            char buffer[80];
            sprintf(buffer, "AFS::BOS: can't specify more than one restart time at a time\n");
            BSETCODE(-1, buffer);
            goto done;
        }
        if (count == 0)
            type = 1;                   /* by default set general restart time */

        if (code = ktime_ParsePeriodic(time, &restartTime)) {
            char buffer[240];
            sprintf(buffer, "AFS::BOS: failed to parse '%s' as periodic restart time(%s)\n",
                    time, em(code));
            BSETCODE(code, buffer);
            goto done;
        }

        code = BOZO_SetRestartTime(self, type, &restartTime);
        if (code) {
            char buffer[240];
            sprintf(buffer, "AFS::BOS: failed to set restart time at server (%s)\n", em(code));
            BSETCODE(code, buffer);
            goto done;
        }
        code = 0;
        SETCODE(code);

        done:
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

void
bos_getrestart(self)
        AFS::BOS self
    PREINIT:
        int32 code = 0;
        struct ktime generalTime, newBinaryTime;
        char messageBuffer[256];
    PPCODE:
    {
        code = BOZO_GetRestartTime(self, 1, &generalTime);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to retrieve restart information (%s)\n", em(code));
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
        }
        code = BOZO_GetRestartTime(self, 2, &newBinaryTime);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to retrieve restart information (%s)\n", em(code));
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
        }

        code = ktime_DisplayString(&generalTime, messageBuffer);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to decode restart time (%s)\n", em(code));
            BSETCODE(code, buffer);
            strcpy(messageBuffer, "");
        }
        XPUSHs(sv_2mortal(newSVpv(messageBuffer, strlen(messageBuffer))));

        code = ktime_DisplayString(&newBinaryTime, messageBuffer);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to decode restart time (%s)\n", em(code));
            BSETCODE(code, buffer);
            strcpy(messageBuffer, "");
        }
        XPUSHs(sv_2mortal(newSVpv(messageBuffer, strlen(messageBuffer))));

        XSRETURN(2);
    }

void
bos_listusers(self)
        AFS::BOS self
    PREINIT:
        int i;
        int32 code = 0;
        char tbuffer[256];
        char *tp;
    PPCODE:
    {
        for (i = 0;; i++) {
            tp = tbuffer;
            code = BOZO_ListSUsers(self, i, &tp);
            if (code)
                break;
            XPUSHs(sv_2mortal(newSVpv(tbuffer, strlen(tbuffer))));
        }

        if (code != 1) {
            /* a real error code, instead of scanned past end */
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to retrieve super-user list (%s)\n", em(code));
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
        }
        else {
            SETCODE(0);
            XSRETURN(i);
        }
    }

void
bos_listhosts(self)
        AFS::BOS self
    PREINIT:
        int32 i, code = 0;
        char tbuffer[256];
        char *tp;
        AV *av = (AV*)sv_2mortal((SV*)newAV());
    PPCODE:
    {
        tp = tbuffer;
        code = BOZO_GetCellName(self, &tp);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to get cell name (%s)\n", em(code));
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
        }
            /* printf("Cell name is %s\n", tbuffer); */
        XPUSHs(sv_2mortal(newSVpv(tbuffer, strlen(tbuffer))));

        for (i = 0;; i++) {
            code = BOZO_GetCellHost(self, i, &tp);
            if (code == BZDOM)
                break;
            if (code != 0) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: failed to get cell host %d (%s)\n", i, em(code));
                BSETCODE(code, buffer);
                XSRETURN_UNDEF;
            }
            /* printf("    Host %d is %s\n", i+1, tbuffer); */
            av_push(av, newSVpv(tbuffer, strlen(tbuffer)));
        }

        XPUSHs(sv_2mortal(newRV_inc((SV *) (av))));

        SETCODE(0);
        XSRETURN(2);
    }

int32
bos_delete(self, object)
        AFS::BOS self
        SV* object
    PREINIT:
        int32 code = 0, len, i;
        AV *av; SV *sv;
        char *name;
        STRLEN namelen;
    CODE:
    {
/*         printf("DEBUG-bos-delete-1 \n");  */
        if (!SvROK(object)) {
/*         printf("DEBUG-bos-delete-2 \n"); */
            name = (char *) SvPV_nolen(object);
            code = BOZO_DeleteBnode(self, name);
            if (code) {
                char buffer[256];
/*         printf("DEBUG-bos-delete-3 %d \n", code); */
                if (code == BZBUSY)
                    sprintf(buffer, "AFS::BOS: can't delete running instance '%s'\n", name);
                else
                    sprintf(buffer, "AFS::BOS: failed to delete instance '%s' (%s)\n", name,
                            em(code));
                BSETCODE(code, buffer);
/*         printf("DEBUG-bos-delete-4 %s \n", buffer); */
                goto done;
            }
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
/*         printf("DEBUG-bos-delete-5 \n"); */
            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
/*         printf("DEBUG-bos-delete-6 \n"); */
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                        name = (char *) safemalloc(BOZO_BSSIZE);
                        name = SvPV(sv, namelen);
/*         printf("DEBUG-bos-delete-7 %s\n", name); */
                        code = BOZO_DeleteBnode(self, name);
/*         printf("DEBUG-bos-delete-8 %d \n", code); */
                        if (code) {
                            char buffer[256];
                            if (code == BZBUSY)
                                sprintf(buffer, "AFS::BOS: can't delete running instance '%s'\n",
                                        name);
                            else
                                sprintf(buffer, "AFS::BOS: failed to delete instance '%s' (%s)\n",
                                        name, em(code));
                            BSETCODE(code, buffer);
                            goto done;
                        }
                    }
                }                       /* for loop */
            }
        }
        SETCODE(0);
/*         printf("DEBUG-bos-delete-9 \n"); */

        done:
        RETVAL = (code == 0);
/*         printf("DEBUG-bos-delete-10 \n"); */
/*         if (name) */
/*             Safefree(name); */
/*         printf("DEBUG-bos-delete-11 \n"); */
    }
    OUTPUT:
        RETVAL

void
bos_getlog(self, file)
        AFS::BOS self
        char* file
    PREINIT:
        register struct rx_call *tcall;
        int32 code = 0;
        char buf, c[255];
        int error, num = 0, i = 0;
    PPCODE:
    {
        tcall = rx_NewCall(self);
        code = StartBOZO_GetLog(tcall, file);
        if (code) {
            char buffer[256];
            rx_EndCall(tcall, code);
            sprintf(buffer, "AFS::BOS error %d (while reading log)\n", code);
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
        }

            /* copy data */
        error = 0;
        while (1) {
            code = rx_Read(tcall, &buf, 1);
            if (code != 1) {
                error = EIO;
                break;
            }
            if (buf == 0)
                break;                  /* the end delimeter */
            /* putchar(buf); */
            c[i++] = buf;
            if (buf == '\n') {
                XPUSHs(sv_2mortal(newSVpv(c, i)));
                i = 0;
                num++;
            }
        }

        code = rx_EndCall(tcall, error);
        #if (tcall)
        #    Safefree(tcall);
            /* fall through into cleanup code */
        XSRETURN(num);
    }

int32
bos__start(self, object=NULL)
        AFS::BOS self
        SV * object
    PREINIT:
        int32 code = 0;
    CODE:
    {
        if (object && (! (SvTYPE(SvRV(object)) == SVt_PVAV))) {
            code = -1;
            BSETCODE(code, "AFS::BOS: SERVER not an array reference\n");
            goto done;
        }

        if (object && (SvTYPE(SvRV(object)) == SVt_PVAV)) {
            AV *av;
            SV *sv;
            char *instance;
            STRLEN namelen;
            int i, len;

            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                      /* instance = (char *) safemalloc(BOZO_BSSIZE); */
                        Newx(instance, BOZO_BSSIZE, char);
                        instance = SvPV(sv, namelen);
                        code = BOZO_SetStatus(self, instance, BSTAT_NORMAL);
                        if (code) {
                            char buffer[256];
                            sprintf(buffer, "AFS::BOS: failed to start instance %s (%s)\n",
                                    instance, em(code));
                            BSETCODE(code, buffer);
                            goto done;
                        }
                        /*if (instance) */
                        /*    Safefree(instance); */
                    }
                }                       /* for loop */
            }
        }

        SETCODE(code);
        done:
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos__startup(self, object=NULL)
        AFS::BOS self
        SV * object
    PREINIT:
        int32 code = 0;
    CODE:
    {
        if (object && (! (SvTYPE(SvRV(object)) == SVt_PVAV))) {
            code = -1;
            BSETCODE(code, "AFS::BOS: SERVER not an array reference\n");
            goto done;
        }

        if (object && (SvTYPE(SvRV(object)) == SVt_PVAV)) {
            AV *av;
            SV *sv;
            char *instance;
            STRLEN namelen;
            int i, len;

            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                      /* instance = (char *) safemalloc(BOZO_BSSIZE); */
                        Newx(instance, BOZO_BSSIZE, char);
                        instance = SvPV(sv, namelen);
                        code = BOZO_SetTStatus(self, instance, BSTAT_NORMAL);
                        if (code) {
                            char buffer[256];
                            sprintf(buffer, "AFS::BOS: failed to start instance %s (%s)\n",
                                    instance, em(code));
                            BSETCODE(code, buffer);
                            goto done;
                        }
                        /*if (instance) */
                        /*    Safefree(instance); */
                    }
                }                       /* for loop */
            }
        }
        else {
            code = BOZO_StartupAll(self);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: failed to startup servers (%s)\n", em(code));
                BSETCODE(code, buffer);
                goto done;
            }
        }

        SETCODE(code);
        done:
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos__stop(self, object=NULL, wait=0)
        AFS::BOS self
        SV * object
        int wait
    PREINIT:
        int32 code = 0;
    CODE:
    {
      /*                printf("DEBUG-XS-bos-stop-1 \n"); */
        if (object && (! (SvTYPE(SvRV(object)) == SVt_PVAV))) {
            code = -1;
            BSETCODE(code, "AFS::BOS: SERVER not an array reference\n");
            goto done;
        }

       /*                 printf("DEBUG-XS-bos-stop-2 \n"); */
        if (object && (SvTYPE(SvRV(object)) == SVt_PVAV)) {
            AV *av;
            SV *sv;
            char *instance;
            STRLEN namelen;
            int i, len;

            /*                      printf("DEBUG-XS-bos-stop-3 \n"); */
            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                      /* instance = (char *) safemalloc(BOZO_BSSIZE); */
                        Newx(instance, BOZO_BSSIZE, char);
                        instance = SvPV(sv, namelen);
                        /*                      printf("DEBUG-XS-bos-stop-3-1 %d %s\n", len, instance); */
                        code = BOZO_SetStatus(self, instance, BSTAT_SHUTDOWN); 
                       /*                      printf("DEBUG-XS-bos-stop-3-2 %d \n", code); */
                        if (code) {
                            char buffer[256];
                            sprintf(buffer, "AFS::BOS: failed to change stop instance %s (%s)\n",
                                    instance, em(code));
                            BSETCODE(code, buffer);
                            goto done;
                        }
                        /*if (instance) */
                        /*    Safefree(instance); */
                    }
                }                       /* for loop */
            }
            /*                      printf("DEBUG-XS-bos-stop-4 \n"); */
        }

        /*         printf("DEBUG-XS-bos-stop-5 \n"); */
        if (wait) {
          /*                  printf("DEBUG-XS-bos-stop-5-1 \n"); */
            code = BOZO_WaitAll(self);
/*                  printf("DEBUG-XS-bos-stop-5-2 %d \n", code); */
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: can't wait for processes to shutdown (%s)\n",
                        em(code));
                BSETCODE(code, buffer);
                goto done;
            }
        }
        /*                  printf("DEBUG-XS-bos-stop-6 \n"); */
        SETCODE(code);
        done:
        /*                  printf("DEBUG-XS-bos-stop-7 \n"); */
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos__shutdown(self, object=NULL, wait=0)
        AFS::BOS self
        SV * object
        int wait
    PREINIT:
        int32 code = 0;
    CODE:
    {
        if (object && (! (SvTYPE(SvRV(object)) == SVt_PVAV))) {
            code = -1;
            BSETCODE(code, "AFS::BOS: SERVER not an array reference\n");
            goto done;
        }

        if (object && (SvTYPE(SvRV(object)) == SVt_PVAV)) {
            AV *av;
            SV *sv;
            char *instance;
            STRLEN namelen;
            int i, len;

            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                      /* instance = (char *) safemalloc(BOZO_BSSIZE); */
                        Newx(instance, BOZO_BSSIZE, char);
                        instance = SvPV(sv, namelen);
                        code = BOZO_SetTStatus(self, instance, BSTAT_SHUTDOWN);
                        if (code) {
                            char buffer[256];
                            sprintf(buffer, "AFS::BOS: failed to shutdown instance %s (%s)\n",
                                    instance, em(code));
                            BSETCODE(code, buffer);
                            goto done;
                        }
                        /*if (instance) */
                        /*    Safefree(instance); */
                    }
                }                       /* for loop */
            }
        }
        else {
            code = BOZO_ShutdownAll(self);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: failed to shutdown servers (%s)\n", em(code));
                BSETCODE(code, buffer);
                goto done;
            }
        }

        if (wait) {
            code = BOZO_WaitAll(self);
            if (code) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: can't wait for processes to shutdown (%s)\n",
                        em(code));
                BSETCODE(code, buffer);
                goto done;
            }
        }
        SETCODE(code);
        done:
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

int32
bos_setcellname(self, name)
        AFS::BOS self
        char *name
    PREINIT:
        int32 code = 0;   
    CODE:
    {
        not_here("AFS::BOS::setcellname");

        code = BOZO_SetCellName(self, name);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to set cell (%s)\n", em(code));
            BSETCODE(code, buffer);
        }
    }
    OUTPUT:
        RETVAL

void
bos_listkeys(self, showkey=0)
        AFS::BOS self
        int showkey
    PREINIT:
        afs_int32 i, kvno, code = 0;
        struct ktc_encryptionKey tkey;
        struct bozo_keyInfo keyInfo;
        int everWorked = 0;
        char index[5];
        HV *list = (HV*)sv_2mortal((SV*)newHV());
    PPCODE:
    {
        for (i = 0;; i++) {
            HV *key = (HV *) sv_2mortal((SV *) newHV());
            code = BOZO_ListKeys(self, i, &kvno, &tkey, &keyInfo);
            if (code)
                break;
            everWorked = 1;
            /* first check if key is returned */
            if ((!ka_KeyIsZero((char *) &tkey, sizeof(tkey))) && showkey) {
                /* ka_PrintBytes ((char *)&tkey, sizeof(tkey)); */
                safe_hv_store(key, "key", 3, newSVpv((char *) &tkey, sizeof(tkey)), 0);
            }
            else {
                if (keyInfo.keyCheckSum == 0) { /* shouldn't happen */
                    /* printf ("key version is %d\n", kvno); */
                }
                else {
                    safe_hv_store(key, "keyCheckSum", 11, newSVuv(keyInfo.keyCheckSum), 0);
                }
            }
            sprintf(index, "%d", kvno);
            safe_hv_store(list, index, strlen(index), newRV_inc((SV *) (key)), 0);
        }                               /* for loop */

        if (everWorked) {
            /* fprintf(stderr, "Keys last changed on %d.\n", keyInfo.mod_sec); */
            EXTEND(sp, 2);
            PUSHs(sv_2mortal(newSViv(keyInfo.mod_sec)));
            PUSHs(newRV_inc((SV *) (list)));
        }
        if (code != BZDOM) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: %s error encountered while listing keys\n", em(code));
            BSETCODE(code, buffer);
        }
        else {
            code = 0;
        }

        if (everWorked) {
            XSRETURN(2);
        }
        else {
            XSRETURN_EMPTY;
            hv_undef(list);
        }
    }

int32
bos_getrestricted(self)
        AFS::BOS self
    CODE:
    {
#ifdef BOS_RESTRICTED_MODE
        int32 val, code;
        RETVAL = 0;
        code = BOZO_GetRestrictedMode(self, &val);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to get restricted mode (%s)\n", em(code));
            BSETCODE(code, buffer);
        }
        RETVAL = val;
#else
        RETVAL = 0;
        not_here("AFS::BOS::getrestricted");
#endif
    }
    OUTPUT:
        RETVAL

int32
bos_setrestricted(self, mode)
        AFS::BOS self
        char *mode
    CODE:
    {
#ifdef BOS_RESTRICTED_MODE
        int32 val, code;
        util_GetInt32(mode, &val);
        code = BOZO_SetRestrictedMode(self, val);
        if (code) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: failed to set restricted mode (%s)\n", em(code));
            BSETCODE(code, buffer);
        }
        RETVAL = (code == 0);
#else
        RETVAL = 0;
        not_here("AFS::BOS::setrestricted");
#endif
    }
    OUTPUT:
        RETVAL

int32
bos_salvage(self, partition=NULL, volume=NULL, all=0, outName=NULL, showlog=0, parallel=NULL, tmpDir=NULL, orphans=NULL, localauth=0, tmpname=NULL, debug=0, nowrite=0, force=0, oktozap=0, rootfiles=0, salvagedirs=0, blockreads=0, ListResidencies=0, SalvageRemote=0, SalvageArchival=0, IgnoreCheck=0, ForceOnLine=0, UseRootDirACL=0, TraceBadLinkCounts=0, DontAskFS=0, LogLevel=0, rxdebug=0, Residencies=0)
        AFS::BOS self
        char *partition
        char *volume
        int32 all
        char *outName
        int32 showlog
        char *parallel
        char *tmpDir
        char *orphans
        int32 localauth
        char *tmpname
        int32 debug
        int32 nowrite
        int32 force
        int32 oktozap
        int32 rootfiles
        int32 salvagedirs
        int32 blockreads
        int32 ListResidencies
        int32 SalvageRemote
        int32 SalvageArchival
        int32 IgnoreCheck
        int32 ForceOnLine
        int32 UseRootDirACL
        int32 TraceBadLinkCounts
        int32 DontAskFS
        int32 LogLevel
        int32 rxdebug
        int32 Residencies
    PREINIT:
        afs_int32 code = 0, rc;
        char tname[BOZO_BSSIZE];
        afs_int32 newID;
        extern struct ubik_client *cstruct;
        afs_int32 curGoal, mrafs = 0;
        char *tp;
    CODE:
    {
        not_here("AFS::BOS::salvage");

        if (partition && strlen(partition) == 0)
            partition = NULL;
        if (volume && strlen(volume) == 0)
            volume = NULL;
        if (outName && strlen(outName) == 0)
            outName = NULL;
        if (parallel && strlen(parallel) == 0)
            parallel = NULL;
        if (tmpDir && strlen(tmpDir) == 0)
            tmpDir = NULL;
        if (orphans && strlen(orphans) == 0)
            orphans = NULL;

        Zero(&mrafsParm, 1, mrafsParm);

            /* Find out whether fileserver is running MR-AFS (has a scanner instance) */
            /* XXX this should really be done some other way, potentially by RPC */
        tp = (char *) &tname;
        if ((code = BOZO_GetInstanceParm(self, "fs", 3, &tp) == 0))
            mrafs = 1;

            /* we can do a volume, a partition or the whole thing, but not mixtures
             * thereof */
        if (!partition && volume) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: must specify partition to salvage individual volume.\n");
            BSETCODE(-1, buffer);
            goto done;
        }
        if (showlog && outName) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: can not specify both -file and -showlog.\n");
            BSETCODE(-1, buffer);
            goto done;
        }
        if (all && (partition || volume)) {
            char buffer[256];
            sprintf(buffer, "AFS::BOS: can not specify ALL with other flags.\n");
            BSETCODE(-1, buffer);
            goto done;
        }

        if (orphans && mrafs) {
            char buffer[256];
            sprintf(buffer, "Can't specify -orphans for MR-AFS fileserver\n");
            BSETCODE(EINVAL, buffer);
            goto done;
        }

        if (mrafs) {
            if (debug)
                mrafsParm.Optdebug = 1;
            if (nowrite)
                mrafsParm.Optnowrite = 1;
            if (force)
                mrafsParm.Optforce = 1;
            if (oktozap)
                mrafsParm.Optoktozap = 1;
            if (rootfiles)
                mrafsParm.Optrootfiles = 1;
            if (salvagedirs)
                mrafsParm.Optsalvagedirs = 1;
            if (blockreads)
                mrafsParm.Optblockreads = 1;
            if (ListResidencies)
                mrafsParm.OptListResidencies = 1;
            if (SalvageRemote)
                mrafsParm.OptSalvageRemote = 1;
            if (SalvageArchival)
                mrafsParm.OptSalvageArchival = 1;
            if (IgnoreCheck)
                mrafsParm.OptIgnoreCheck = 1;
            if (ForceOnLine)
                mrafsParm.OptForceOnLine = 1;
            if (UseRootDirACL)
                mrafsParm.OptUseRootDirACL = 1;
            if (TraceBadLinkCounts)
                mrafsParm.OptTraceBadLinkCounts = 1;
            if (DontAskFS)
                mrafsParm.OptDontAskFS = 1;
            if (LogLevel)
                mrafsParm.OptLogLevel = LogLevel;
            if (rxdebug)
                mrafsParm.OptRxDebug = 1;
            if (Residencies) {
                if (SalvageRemote || SalvageArchival) {
                    char buffer[256];
                    sprintf(buffer,
                            "Can't specify -Residencies with -SalvageRemote or -SalvageArchival\n");
                    BSETCODE(EINVAL, buffer);
                    goto done;
                }
/* muss naeher ueberprueft werden !!!  */
/* #if defined(OpenAFS_1_2) */
/*                 code = GetUInt32(Residencies, &mrafsParm.OptResidencies); */
/* #else */
/* #if defined(OpenAFS_1_3) || defined(OpenAFS_1_4) || defined(OpenAFS_1_5) */
/*                 code = util_GetUInt32(Residencies, &mrafsParm.OptResidencies); */
/* #endif */
/* #endif */
/*                 if (code) { */
/*                     char buffer[256]; */
/*                     sprintf(buffer, "AFS::BOS: '%d' is not a valid residency mask.\n", TraceBadLinkCounts);     /\* this doesn't really make sense to me AW *\/ */
/*                     BSETCODE(code, buffer); */
/*                     goto done; */
/*                 } */
/* muss naeher ueberprueft werden !!!  */
                mrafsParm.OptResidencies = Residencies;
            }
        }
        else {
            if (debug || nowrite || force || oktozap || rootfiles || salvagedirs || blockreads ||
                ListResidencies || SalvageRemote || SalvageArchival || IgnoreCheck ||
                ForceOnLine || UseRootDirACL || TraceBadLinkCounts || DontAskFS || LogLevel ||
                rxdebug || Residencies) {
                char buffer[256];
                sprintf(buffer, "Parameter only possible for MR-AFS fileserver.\n");
                BSETCODE(-1, buffer);
                goto done;
            }
        }

        if (all) {
            /* salvage whole enchilada */
            curGoal = GetServerGoal(self, "fs");
            if (curGoal == BSTAT_NORMAL) {
                fprintf(stderr, "AFS::BOS: shutting down fs.\n");
                code = BOZO_SetTStatus(self, "fs", BSTAT_SHUTDOWN);
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: failed to stop 'fs' (%s)\n", em(code));
                    BSETCODE(code, buffer);
                    goto done;
                }
                code = BOZO_WaitAll(self);    /* wait for shutdown to complete */
                if (code) {
                    char buffer[256];
                    sprintf(buffer,
                            "AFS::BOS: failed to wait for file server shutdown, continuing.\n");
                    BSETCODE(code, buffer);
                }
            }
            /* now do the salvage operation */
            /* fprintf(stderr, "Starting salvage of everything.\n"); */
            rc = DoSalvage(self, (char *) 0, (char *) 0, outName, showlog, parallel, tmpDir,
                           orphans);
            if (curGoal == BSTAT_NORMAL) {
                /* fprintf(stderr, "AFS::BOS: restarting fs.\n"); */
                code = BOZO_SetTStatus(self, "fs", BSTAT_NORMAL);
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: failed to restart 'fs' (%s)\n", em(code));
                    BSETCODE(code, buffer);
                    goto done;
                }
            }
            if (rc) {
                code = rc;
                goto done;
            }
        }
        else if (!volume) {
            if (!partition) {
                char buffer[256];
                sprintf(buffer, "AFS::BOS: must specify ALL switch to salvage all partitions.\n");
                BSETCODE(-1, buffer);
                goto done;
            }
            if (volutil_GetPartitionID(partition) < 0) {
                /* can't parse volume ID, so complain before shutting down
                 * file server.
                 */
                char buffer[256];
                sprintf(buffer, "AFS::BOS: can't interpret %s as partition ID.\n", partition);
                BSETCODE(-1, buffer);
                goto done;
            }
            curGoal = GetServerGoal(self, "fs");
            /* salvage a whole partition (specified by parms[1]) */
            if (curGoal == BSTAT_NORMAL) {
                /* fprintf(stderr, "AFS::BOS: shutting down fs.\n"); */
                code = BOZO_SetTStatus(self, "fs", BSTAT_SHUTDOWN);
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: can't stop 'fs' (%s)\n", em(code));
                    BSETCODE(code, buffer);
                    goto done;
                }
                code = BOZO_WaitAll(self);    /* wait for shutdown to complete */
                if (code) {
                    char buffer[256];
                    sprintf(buffer,
                            "AFS::BOS: failed to wait for file server shutdown, continuing.\n");
                    BSETCODE(code, buffer);
                }
            }
            /* now do the salvage operation */
            /* fprintf(stderr, "Starting salvage of partition %s.\n", partition); */
            rc = DoSalvage(self, partition, (char *) 0,
                           outName, showlog, parallel, tmpDir, orphans);
            if (curGoal == BSTAT_NORMAL) {
                /* fprintf(stderr, "AFS::BOS: restarting fs.\n"); */
                code = BOZO_SetTStatus(self, "fs", BSTAT_NORMAL);
                if (code) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: failed to restart 'fs' (%s)\n", em(code));
                    BSETCODE(code, buffer);
                    goto done;
                }
            }
            if (rc) {
                code = rc;
                goto done;
            }
        }
        else {
            /* salvage individual volume (don't shutdown fs first), just use
             * single-shot cron bnode.  Must leave server running when using this
             * option, since salvager will ask file server for the volume */
            afs_int32 err;
            const char *confdir;

            confdir = (localauth ? AFSDIR_SERVER_ETC_DIRPATH : AFSDIR_CLIENT_ETC_DIRPATH);
            code = internal_vsu_ClientInit( /* noauth */ 1, confdir, tmpname,
                                  /* server auth */ 0, &cstruct, (int (*)()) 0);
            if (code == 0) {
                newID = vsu_GetVolumeID(volume, cstruct, &err);
                if (newID == 0) {
                    char buffer[256];
                    sprintf(buffer, "AFS::BOS: can't interpret %s as volume name or ID\n",
                            volume);
                    BSETCODE(-1, buffer);
                    goto done;
                }
                sprintf(tname, "%u", newID);
            }
            else {
                char buffer[256];
                sprintf(buffer,
                        "AFS::BOS: can't initialize volume system client (code %d), trying anyway.\n",
                        code);
                BSETCODE(code, buffer);
                strncpy(tname, volume, sizeof(tname));
            }
            if (volutil_GetPartitionID(partition) < 0) {
                /* can't parse volume ID, so complain before shutting down
                 * file server.
                 */
                char buffer[256];
                sprintf(buffer, "AFS::BOS: can't interpret %s as partition ID.\n", partition);
                BSETCODE(-1, buffer);
                goto done;
            }
            /* fprintf(stderr, "Starting salvage of volume %d on partition %s.\n",
               newID, partition); */
            rc = DoSalvage(self, partition, tname, outName, showlog, parallel, tmpDir, orphans);
            if (rc) {
                code = rc;
                goto done;
            }
        }

        code = 0;
        SETCODE(code);

        done:
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL


MODULE = AFS            PACKAGE = AFS::PTS      PREFIX = pts_

AFS::PTS
pts__new(class=0, sec=1, cell=0)
        char *  class
        int32   sec
        char *  cell
    PREINIT:
        int32 code = -1;
        AFS__PTS server;
    PPCODE:
    {
        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        server = internal_pts_new(&code, sec, cell);
        # SETCODE(code);  wird tiefer gesetzt...

        if (code == 0) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AFS::PTS", (void *) server);
            XSRETURN(1);
        }
        else
            XSRETURN_UNDEF;
    }

int32
pts__DESTROY(server)
        AFS::PTS server
    CODE:
    {
        int32 code;
        /* printf("pts DEBUG ubik_ClientDestroy\n"); */
        code = ubik_ClientDestroy(server);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL  

void
pts_id(server,object,anon=1)
        AFS::PTS server
        SV *    object
        int32   anon
    PPCODE:
    {
        if (!SvROK(object)) {
            int32 code, id;
            char *name;
            name = (char *) SvPV(object, PL_na);
            code = internal_pr_id(server, name, &id, anon);
            ST(0) = sv_newmortal();
            SETCODE(code);
            if (code == 0)
                sv_setiv(ST(0), id);
            XSRETURN(1);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            int32 code, id;
            int i, len;
            AV *av;
            SV *sv;
            char *name;
            STRLEN namelen;
            namelist lnames;
            idlist lids;

            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                lnames.namelist_len = len + 1;
                lnames.namelist_val = (prname *) safemalloc(PR_MAXNAMELEN * (len + 1));
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                        name = SvPV(sv, namelen);
                        strncpy(lnames.namelist_val[i], name, PR_MAXNAMELEN);
                    }
                }
                lids.idlist_len = 0;
                lids.idlist_val = 0;

                code = ubik_Call(PR_NameToID, server, 0, &lnames, &lids);
                SETCODE(code);
                if (code == 0 && lids.idlist_val) {
                    EXTEND(sp, lids.idlist_len);
                    for (i = 0; i < lids.idlist_len; i++) {
                        id = lids.idlist_val[i];
                        if (id == ANONYMOUSID && !anon) {
                            PUSHs(sv_newmortal());
                        }
                        else {
                            PUSHs(sv_2mortal(newSViv(id)));
                        }
                    }
                    if (lids.idlist_val)
                        free(lids.idlist_val);
                }
                if (lnames.namelist_val)
                    safefree(lnames.namelist_val);
                PUTBACK;
                return;
            }
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVHV) {
            int32 code = 0, id;
            int i, len;
            HV *hv;
            HE *he;
            namelist lnames;
            idlist lids;
            char *key;
            I32 keylen;

            hv = (HV *) SvRV(object);
            len = 0;

            hv_iterinit(hv);
            while (hv_iternext(hv))
                len++;
            if (len != 0) {
                lnames.namelist_len = len;
                lnames.namelist_val = (prname *) safemalloc(PR_MAXNAMELEN * len);
                hv_iterinit(hv);
                i = 0;
                while ((he = hv_iternext(hv))) {
                    key = hv_iterkey(he, &keylen);
                    strncpy(lnames.namelist_val[i], key, PR_MAXNAMELEN);
                    i++;
                }
                lids.idlist_len = 0;
                lids.idlist_val = 0;

                code = ubik_Call(PR_NameToID, server, 0, &lnames, &lids);
                SETCODE(code);
                if (code == 0 && lids.idlist_val) {
                    hv_iterinit(hv);
                    i = 0;
                    while ((he = hv_iternext(hv))) {
                        key = hv_iterkey(he, &keylen);
                        id = lids.idlist_val[i];
                        if (id == ANONYMOUSID && !anon) {
                            safe_hv_store(hv, key, keylen, newSVsv(&PL_sv_undef), 0);
                        }
                        else {
                            safe_hv_store(hv, key, keylen, newSViv(id), 0);
                        }
                        i++;
                    }
                    if (lids.idlist_val)
                        free(lids.idlist_val);
                }
                if (lnames.namelist_val)
                    safefree(lnames.namelist_val);
            }
            if (code == 0) {
                ST(0) = sv_2mortal(newRV_inc((SV *) hv));
            }
            else {
                ST(0) = sv_newmortal();
            }

            XSRETURN(1);
        }
        else {
            croak("object is not a scaler, ARRAY reference, or HASH reference");
        }
    }

void
pts_PR_NameToID(server,object)
        AFS::PTS server
        SV *    object
    PPCODE:
    {
        int32 code, id;
        int i, len;
        AV *av;
        SV *sv;
        char *name;
        STRLEN namelen;
        namelist lnames;
        idlist lids;

        if (!SvROK(object) || SvTYPE(SvRV(object)) != SVt_PVAV) {
            croak("object is not an ARRAY reference");
        }

        av = (AV *) SvRV(object);
        len = av_len(av);
        if (len != -1) {
            lnames.namelist_len = len + 1;
            lnames.namelist_val = (prname *) safemalloc(PR_MAXNAMELEN * (len + 1));
            for (i = 0; i <= len; i++) {
                sv = *av_fetch(av, i, 0);
                if (sv) {
                    name = SvPV(sv, namelen);
                    strncpy(lnames.namelist_val[i], name, PR_MAXNAMELEN);
                }
            }
            lids.idlist_len = 0;
            lids.idlist_val = 0;

            code = ubik_Call(PR_NameToID, server, 0, &lnames, &lids);
            SETCODE(code);
            if (code == 0 && lids.idlist_val) {
                EXTEND(sp, lids.idlist_len);
                for (i = 0; i < lids.idlist_len; i++) {
                    id = lids.idlist_val[i];
                    PUSHs(sv_2mortal(newSViv(id)));
                }
                if (lids.idlist_val)
                    free(lids.idlist_val);
            }
            if (lnames.namelist_val)
                safefree(lnames.namelist_val);
            PUTBACK;
            return;
        }
    }

void
pts_name(server,object,anon=1)
        AFS::PTS server
        SV *    object
        int32   anon
    PPCODE:
    {
        if (!SvROK(object)) {
            int32 code, id;
            char name[PR_MAXNAMELEN];
            id = SvIV(object);
            code = internal_pr_name(server, id, name);
            SETCODE(code);
            ST(0) = sv_newmortal();
            if (code == 0) {
                if (!anon && check_name_for_id(name, id)) {
                    /* return undef */
                }
                else {
                    sv_setpv(ST(0), name);
                }
            }
            XSRETURN(1);
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVAV) {
            int32 code;
            int i, len;
            AV *av;
            SV *sv;
            char *name;
            namelist lnames;
            idlist lids;

            av = (AV *) SvRV(object);
            len = av_len(av);
            if (len != -1) {
                lids.idlist_len = len + 1;
                lids.idlist_val = (int32 *) safemalloc(sizeof(int32) * (len + 1));
                lnames.namelist_len = 0;
                lnames.namelist_val = 0;
                for (i = 0; i <= len; i++) {
                    sv = *av_fetch(av, i, 0);
                    if (sv) {
                        lids.idlist_val[i] = SvIV(sv);
                    }
                }
                code = ubik_Call(PR_IDToName, server, 0, &lids, &lnames);
                SETCODE(code);
                if (code == 0 && lnames.namelist_val) {
                    EXTEND(sp, lnames.namelist_len);
                    for (i = 0; i < lnames.namelist_len; i++) {
                        name = lnames.namelist_val[i];
                        if (!anon && check_name_for_id(name, lids.idlist_val[i])) {
                            PUSHs(sv_newmortal());
                        }
                        else {
                            PUSHs(sv_2mortal(newSVpv(name, strlen(name))));
                        }
                    }
                    if (lnames.namelist_val)
                        free(lnames.namelist_val);
                }
                if (lids.idlist_val)
                    safefree(lids.idlist_val);
                PUTBACK;
                return;
            }
        }
        else if (SvTYPE(SvRV(object)) == SVt_PVHV) {
            int32 code = 0;
            int i, len;
            HV *hv;
            SV *sv;
            HE *he;
            char *name;
            namelist lnames;
            idlist lids;
            char *key;
            I32 keylen;

            hv = (HV *) SvRV(object);
            len = 0;

            hv_iterinit(hv);
            while (hv_iternext(hv))
                len++;
            if (len != 0) {
                lids.idlist_len = len;
                lids.idlist_val = (int32 *) safemalloc(sizeof(int32) * len);
                lnames.namelist_len = 0;
                lnames.namelist_val = 0;

                hv_iterinit(hv);
                i = 0;
                sv = sv_newmortal();
                while ((he = hv_iternext(hv))) {
                    key = hv_iterkey(he, &keylen);
                    sv_setpvn(sv, key, keylen);
                    lids.idlist_val[i] = SvIV(sv);
                    i++;
                }

                code = ubik_Call(PR_IDToName, server, 0, &lids, &lnames);
                SETCODE(code);
                if (code == 0 && lnames.namelist_val) {
                    hv_iterinit(hv);
                    i = 0;
                    while ((he = hv_iternext(hv))) {
                        key = hv_iterkey(he, &keylen);
                        name = lnames.namelist_val[i];
                        if (!anon && check_name_for_id(name, lids.idlist_val[i])) {
                            safe_hv_store(hv, key, keylen, newSVsv(&PL_sv_undef), 0);
                        }
                        else {
                            safe_hv_store(hv, key, keylen, newSVpv(name, strlen(name)), 0);
                        }
                        i++;
                    }
                    if (lnames.namelist_val)
                        free(lnames.namelist_val);
                }
                if (lids.idlist_val)
                    safefree(lids.idlist_val);
            }
            if (code == 0) {
                ST(0) = sv_2mortal(newRV_inc((SV *) hv));
            }
            else {
                ST(0) = sv_newmortal();
            }
            XSRETURN(1);
        }
        else {
            croak("object is not a scaler, ARRAY reference, or HASH reference");
        }
    }

void
pts_PR_IDToName(server,object)
        AFS::PTS server
        SV *    object
    PPCODE:
    {
        int32 code;
        int i, len;
        AV *av;
        SV *sv;
        char *name;
        namelist lnames;
        idlist lids;

        if (!SvROK(object) || SvTYPE(SvRV(object)) != SVt_PVAV) {
            croak("object is not an ARRAY reference");
        }

        av = (AV *) SvRV(object);
        len = av_len(av);
        if (len != -1) {
            lids.idlist_len = len + 1;
            lids.idlist_val = (int32 *) safemalloc(sizeof(int32) * (len + 1));
            lnames.namelist_len = 0;
            lnames.namelist_val = 0;
            for (i = 0; i <= len; i++) {
                sv = *av_fetch(av, i, 0);
                if (sv) {
                    lids.idlist_val[i] = SvIV(sv);
                }
            }
            code = ubik_Call(PR_IDToName, server, 0, &lids, &lnames);
            SETCODE(code);
            if (code == 0 && lnames.namelist_val) {
                EXTEND(sp, lnames.namelist_len);
                for (i = 0; i < lnames.namelist_len; i++) {
                    name = lnames.namelist_val[i];
                    PUSHs(sv_2mortal(newSVpv(name, strlen(name))));
                }
                if (lnames.namelist_val)
                    free(lnames.namelist_val);
            }
            if (lids.idlist_val)
                safefree(lids.idlist_val);
            PUTBACK;
            return;
        }
    }

void
pts_members(server,name,convertids=1,over=0)
        AFS::PTS server
        char *  name
        int32   convertids
        int32   over
    PPCODE:
    {
        int32 code, wentover, id;
        int i;
        prlist list;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0) {
            list.prlist_val = 0;
            list.prlist_len = 0;
            code = ubik_Call(PR_ListElements, server, 0, id, &list, &wentover);
            if (items == 4)
                sv_setiv(ST(3), (IV) wentover);
            if (code == 0) {
                if (convertids) {
                    namelist lnames;
                    lnames.namelist_len = 0;
                    lnames.namelist_val = 0;
                    code = ubik_Call(PR_IDToName, server, 0, &list, &lnames);
                    if (code == 0 && lnames.namelist_val) {
                        EXTEND(sp, lnames.namelist_len);
                        for (i = 0; i < lnames.namelist_len; i++) {
                            name = lnames.namelist_val[i];
                            PUSHs(sv_2mortal(newSVpv(name, strlen(name))));
                        }
                        if (lnames.namelist_val)
                            free(lnames.namelist_val);
                    }
                }
                else {
                    EXTEND(sp, list.prlist_len);
                    for (i = 0; i < list.prlist_len; i++) {
                        PUSHs(sv_2mortal(newSViv(list.prlist_val[i])));
                    }
                }
            }
            if (list.prlist_val)
                free(list.prlist_val);
        }
        else {
            if (items == 4)
                sv_setiv(ST(3), (IV) 0);
        }

        SETCODE(code);
     }

void
pts_PR_ListElements(server,id,over)
        AFS::PTS server
        int32   id
        int32   over
    PPCODE:
    {
        int32 code, wentover;
        int i;
        prlist list;

        list.prlist_val = 0;
        list.prlist_len = 0;
        code = ubik_Call(PR_ListElements, server, 0, id, &list, &wentover);
        sv_setiv(ST(2), (IV) wentover);
        if (code == 0) {
            EXTEND(sp, list.prlist_len);
            for (i = 0; i < list.prlist_len; i++) {
                PUSHs(sv_2mortal(newSViv(list.prlist_val[i])));
            }
        }
        if (list.prlist_val)
            free(list.prlist_val);
        SETCODE(code);
     }

void
pts_getcps(server,name,convertids=1,over=0)
        AFS::PTS server
        char *  name
        int32   convertids
        int32   over
    PPCODE:
    {
        int32 code, wentover, id;
        int i;
        prlist list;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0) {
            list.prlist_val = 0;
            list.prlist_len = 0;
            code = ubik_Call(PR_GetCPS, server, 0, id, &list, &wentover);
            if (items == 4)
                sv_setiv(ST(3), (IV) wentover);
            if (code == 0) {
                if (convertids) {
                    namelist lnames;
                    lnames.namelist_len = 0;
                    lnames.namelist_val = 0;
                    code = ubik_Call(PR_IDToName, server, 0, &list, &lnames);
                    if (code == 0 && lnames.namelist_val) {
                        EXTEND(sp, lnames.namelist_len);
                        for (i = 0; i < lnames.namelist_len; i++) {
                            name = lnames.namelist_val[i];
                            PUSHs(sv_2mortal(newSVpv(name, strlen(name))));
                        }
                        if (lnames.namelist_val)
                            free(lnames.namelist_val);
                    }
                }
                else {
                    EXTEND(sp, list.prlist_len);
                    for (i = 0; i < list.prlist_len; i++) {
                        PUSHs(sv_2mortal(newSViv(list.prlist_val[i])));
                    }
                }
            }
            if (list.prlist_val)
                free(list.prlist_val);
        }
        else {
            if (items == 4)
                sv_setiv(ST(3), (IV) 0);
        }

        SETCODE(code);
     }

void
pts_PR_GetCPS(server,id,over)
        AFS::PTS server
        int32   id
        int32   over
    PPCODE:
    {
        int32 code, wentover;
        int i;
        prlist list;

        list.prlist_val = 0;
        list.prlist_len = 0;
        code = ubik_Call(PR_GetCPS, server, 0, id, &list, &wentover);
        sv_setiv(ST(2), (IV) wentover);
        if (code == 0) {
            EXTEND(sp, list.prlist_len);
            for (i = 0; i < list.prlist_len; i++) {
                PUSHs(sv_2mortal(newSViv(list.prlist_val[i])));
            }
        }
        if (list.prlist_val)
            free(list.prlist_val);
        SETCODE(code);
     }

void
pts_owned(server,name,convertids=1,over=0)
        AFS::PTS server
        char *  name
        int32   convertids
        int32   over
    PPCODE:
    {
        int32 code, wentover, id;
        int i;
        prlist list;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0) {
            list.prlist_val = 0;
            list.prlist_len = 0;
            code = ubik_Call(PR_ListOwned, server, 0, id, &list, &wentover);
            if (items == 4)
                sv_setiv(ST(3), (IV) wentover);
            if (code == 0) {
                if (convertids) {
                    namelist lnames;
                    lnames.namelist_len = 0;
                    lnames.namelist_val = 0;
                    code = ubik_Call(PR_IDToName, server, 0, &list, &lnames);
                    if (code == 0 && lnames.namelist_val) {
                        EXTEND(sp, lnames.namelist_len);
                        for (i = 0; i < lnames.namelist_len; i++) {
                            name = lnames.namelist_val[i];
                            PUSHs(sv_2mortal(newSVpv(name, strlen(name))));
                        }
                        if (lnames.namelist_val)
                            free(lnames.namelist_val);
                    }
                }
                else {
                    EXTEND(sp, list.prlist_len);
                    for (i = 0; i < list.prlist_len; i++) {
                        PUSHs(sv_2mortal(newSViv(list.prlist_val[i])));
                    }
                }
            }
            if (list.prlist_val)
                free(list.prlist_val);
        }
        else {
            if (items == 4)
                sv_setiv(ST(3), (IV) 0);
        }

        SETCODE(code);
     }

void
pts_PR_ListOwned(server,id,over)
        AFS::PTS server
        int32   id
        int32   over
    PPCODE:
    {
        int32 code, wentover;
        int i;
        prlist list;

        list.prlist_val = 0;
        list.prlist_len = 0;
        code = ubik_Call(PR_ListOwned, server, 0, id, &list, &wentover);
        sv_setiv(ST(2), (IV) wentover);
        if (code == 0) {
            EXTEND(sp, list.prlist_len);
            for (i = 0; i < list.prlist_len; i++) {
                PUSHs(sv_2mortal(newSViv(list.prlist_val[i])));
            }
        }
        if (list.prlist_val)
            free(list.prlist_val);
        SETCODE(code);
    }

void
pts_createuser(server,name,id=0)
        AFS::PTS server
        char *  name
        int32   id
    CODE:
    {
        int32 code;

        if (id) {
            code = ubik_Call(PR_INewEntry, server, 0, name, id, 0);
        }
        else {
            code = ubik_Call(PR_NewEntry, server, 0, name, PRUSER, 0, &id);
        }

        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setiv(ST(0), id);
        }
    }

void
pts_PR_NewEntry(server,name,flag,oid)
        AFS::PTS server
        char *  name
        int32   flag
        int32   oid
    CODE:
    {
        int32 code, id;

        code = ubik_Call(PR_NewEntry, server, 0, name, flag, oid, &id);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setiv(ST(0), id);
        }
    }

void
pts_PR_INewEntry(server,name,id,oid)
        AFS::PTS server
        char *  name
        int32   id
        int32   oid
    CODE:
    {
        int32 code;

        code = ubik_Call(PR_INewEntry, server, 0, name, id, oid);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setiv(ST(0), id);
        }
    }

void
pts_creategroup(server,name,owner=0,id=0)
        AFS::PTS server
        char *  name
        char *  owner
        int32   id
    CODE:
    {
        int32 code = 0;
        int32 oid = 0;

        if (owner && strcmp(owner, "0") && strcmp(owner, "")) {
            code = internal_pr_id(server, owner, &oid, 0);
        }
        if (code == 0) {
            if (id)
                code = ubik_Call(PR_INewEntry, server, 0, name, id, oid);
            else
                code = ubik_Call(PR_NewEntry, server, 0, name, PRGRP, oid, &id);
        }
        SETCODE(code);

        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setiv(ST(0), id);
        }
    }

void
pts_listentry(server,name,lookupids=1,convertflags=1)
        AFS::PTS server
        char *  name
        int32   lookupids
        int32   convertflags
    PPCODE:
    {
        int32 code;
        int32 id;
        struct prcheckentry entry;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = ubik_Call(PR_ListEntry, server, 0, id, &entry);

        SETCODE(code);

        if (code == 0) {
            HV *stats;
            stats = newHV();
            parse_prcheckentry(server, stats, &entry, lookupids, convertflags);
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
        }
    }

void
pts_PR_ListEntry(server,id)
        AFS::PTS server
        int32   id
    PPCODE:
    {
        int32 code;
        struct prcheckentry entry;

        code = ubik_Call(PR_ListEntry, server, 0, id, &entry);

        SETCODE(code);

        if (code == 0) {
            HV *stats;
            stats = newHV();
            parse_prcheckentry(server, stats, &entry, 0, 0);
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
        }
    }

void
pts_dumpentry(server,pos,lookupids=1,convertflags=1)
        AFS::PTS server
        int32   pos
        int32   lookupids
        int32   convertflags
    PPCODE:
    {
        int32 code;
        struct prdebugentry entry;

        code = ubik_Call(PR_DumpEntry, server, 0, pos, &entry);

        SETCODE(code);

        if (code == 0) {
            HV *stats;
            stats = newHV();
            parse_prdebugentry(server, stats, &entry, lookupids, convertflags);
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
        }
    }

void
pts_PR_DumpEntry(server,pos)
        AFS::PTS server
        int32   pos
    PPCODE:
    {
        int32 code;
        struct prdebugentry entry;

        code = ubik_Call(PR_DumpEntry, server, 0, pos, &entry);

        SETCODE(code);

        if (code == 0) {
            HV *stats;
            stats = newHV();
            parse_prdebugentry(server, stats, &entry, 0, 0);
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
        }
    }

void
pts_rename(server,name,newname)
        AFS::PTS server
        char *  name
        char *  newname
    PPCODE:
    {
        int32 code;
        int32 id;

        code = internal_pr_id(server, name, &id, 0);

        if (code == 0)
            code = ubik_Call(PR_ChangeEntry, server, 0, id, newname, 0, 0);

        SETCODE(code);
        ST(0) = sv_2mortal(newSViv(code == 0));
        XSRETURN(1);
    }

void
pts_chown(server,name,owner)
        AFS::PTS server
        char *  name
        char *  owner
    PPCODE:
    {
        int32 code;
        int32 id, oid;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = internal_pr_id(server, owner, &oid, 0);
        if (code == 0)
            code = ubik_Call(PR_ChangeEntry, server, 0, id, "", oid, 0);
        SETCODE(code);
        ST(0) = sv_2mortal(newSViv(code == 0));
        XSRETURN(1);
    }

void
pts_chid(server,name,newid)
        AFS::PTS server
        char *  name
        int32   newid
    PPCODE:
    {
        int32 code;
        int32 id;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = ubik_Call(PR_ChangeEntry, server, 0, id, "", 0, newid);
        SETCODE(code);
        ST(0) = sv_2mortal(newSViv(code == 0));
        XSRETURN(1);
    }

void
pts_PR_ChangeEntry(server,id,name,oid,newid)
        AFS::PTS server
        int32   id
        char *  name
        int32   oid
        int32   newid
    PPCODE:
    {
        int32 code;

        if (name && !*name)
            name = NULL;

        code = ubik_Call(PR_ChangeEntry, server, 0, id, name, oid, newid);

        SETCODE(code);
        ST(0) = sv_2mortal(newSViv(code == 0));
        XSRETURN(1);
    }

void
pts_adduser(server,name,group)
        AFS::PTS server
        char *  name
        char *  group
    PPCODE:
    {
        int32 code, id, gid;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = internal_pr_id(server, group, &gid, 0);
        if (code == 0)
            code = ubik_Call(PR_AddToGroup, server, 0, id, gid);
        SETCODE(code);

        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_PR_AddToGroup(server,uid,gid)
        AFS::PTS server
        int32   uid
        int32   gid
    PPCODE:
    {
        int32 code;
        code = ubik_Call(PR_AddToGroup, server, 0, uid, gid);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_removeuser(server,name,group)
        AFS::PTS server
        char *  name
        char *  group
    PPCODE:
    {
        int32 code, id, gid;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = internal_pr_id(server, group, &gid, 0);
        if (code == 0)
            code = ubik_Call(PR_RemoveFromGroup, server, 0, id, gid);
        SETCODE(code);

        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_PR_RemoveFromGroup(server,uid,gid)
        AFS::PTS server
        int     uid
        int     gid
    PPCODE:
    {
        int32 code;

        code = ubik_Call(PR_RemoveFromGroup, server, 0, uid, gid);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_delete(server,name)
        AFS::PTS server
        char *  name
    PPCODE:
    {
        int32 code, id;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = ubik_Call(PR_Delete, server, 0, id);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_PR_Delete(server,id)
        AFS::PTS server
        int32   id
    PPCODE:
    {
        int32 code;

        code = ubik_Call(PR_Delete, server, 0, id);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_whereisit(server,name)
        AFS::PTS server
        char *  name
    PPCODE:
    {
        int32 code, id, pos;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = ubik_Call(PR_WhereIsIt, server, 0, id, &pos);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0)
            sv_setiv(ST(0), pos);
        XSRETURN(1);
    }

void
pts_PR_WhereIsIt(server,id)
        AFS::PTS server
        int32   id
    PPCODE:
    {
        int32 code,pos;

        code = ubik_Call(PR_WhereIsIt, server, 0, id, &pos);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0)
            sv_setiv(ST(0), pos);
        XSRETURN(1);
    }

void
pts_listmax(server)
        AFS::PTS server
    PPCODE:
    {
        int32 code, uid, gid;

        code = ubik_Call(PR_ListMax, server, 0, &uid, &gid);
        SETCODE(code);
        if (code == 0) {
            EXTEND(sp, 2);
            PUSHs(sv_2mortal(newSViv(uid)));
            PUSHs(sv_2mortal(newSViv(gid)));
        }
    }

void
pts_PR_ListMax(server)
        AFS::PTS server
    PPCODE:
    {
        int32 code, uid, gid;

        code = ubik_Call(PR_ListMax, server, 0, &uid, &gid);
        SETCODE(code);
        if (code == 0) {
            EXTEND(sp, 2);
            PUSHs(sv_2mortal(newSViv(uid)));
            PUSHs(sv_2mortal(newSViv(gid)));
        }
    }

void
pts_setmax(server,id,isgroup=0)
        AFS::PTS server
        int32   id
        int32   isgroup
    PPCODE:
    {
        int32 code, flag;

        flag = 0;
        if (isgroup)
            flag |= PRGRP;
        code = ubik_Call(PR_SetMax, server, 0, id, flag);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_PR_SetMax(server,id,gflag)
        AFS::PTS server
        int32   id
        int32   gflag
    PPCODE:
    {
        int32 code;

        code = ubik_Call(PR_SetMax, server, 0, id, gflag);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_setgroupquota(server,name,ngroups)
        AFS::PTS server
        char *  name
        int32   ngroups
    PPCODE:
    {
        int32 code, id, mask;

        code = internal_pr_id(server, name, &id, 0);

        if (code == 0) {
            mask = PR_SF_NGROUPS;
            code = ubik_Call(PR_SetFieldsEntry, server, 0, id, mask, 0, ngroups, 0, 0, 0);
        }
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_PR_SetFieldsEntry(server,id,mask,flags,ngroups,nusers,spare1,spare2)
        AFS::PTS server
        int32   id
        int32   mask
        int32   flags
        int32   ngroups
        int32   nusers
        int32   spare1
        int32   spare2
    PPCODE:
    {
        int32 code;

        code = ubik_Call(PR_SetFieldsEntry, server, 0,
                         id, mask, flags, ngroups, nusers, spare1, spare2);
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_setaccess(server,name,access)
        AFS::PTS server
        char *  name
        char *  access
    PPCODE:
    {
        int32 code, id, flags, mask;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = parse_pts_setfields(access, &flags);
        if (code == 0) {
            mask = PR_SF_ALLBITS;
            code = ubik_Call(PR_SetFieldsEntry, server, 0, id, mask, flags, 0, 0, 0, 0);
        }
        SETCODE(code);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), (code == 0));
        XSRETURN(1);
    }

void
pts_ismember(server,name,group)
        AFS::PTS server
        char *  name
        char *  group
    PPCODE:
    {
        int32 code, id, gid, flag;

        code = internal_pr_id(server, name, &id, 0);
        if (code == 0)
            code = internal_pr_id(server, group, &gid, 0);
        if (code == 0)
            code = ubik_Call(PR_IsAMemberOf, server, 0, id, gid, &flag);
        SETCODE(code);

        ST(0) = sv_newmortal();
        if (code == 0)
            sv_setiv(ST(0), (flag != 0));
        XSRETURN(1);
    }

void
pts_PR_IsAMemberOf(server,uid,gid)
        AFS::PTS server
        int32   uid
        int32   gid
    PPCODE:
    {
        int32 code, flag;

        code = ubik_Call(PR_IsAMemberOf, server, 0, uid, gid, &flag);
        SETCODE(code);
        ST(0) = sv_newmortal();
        if (code == 0)
            sv_setiv(ST(0), (flag != 0));
        XSRETURN(1);
    }


MODULE = AFS            PACKAGE = AFS::KAS      PREFIX = kas_

int32
kas__DESTROY(server)
        AFS::KAS server
    CODE:
    {
        int32 code;
        code = ubik_ClientDestroy(server);
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL  

void
kas_KAM_GetEntry(server,user,inst)
        AFS::KAS        server
        char *  user
        char *  inst
    PPCODE:
    {
        int32 code;
        struct kaentryinfo entry;

        code = ubik_Call(KAM_GetEntry, server, 0, user, inst, KAMAJORVERSION, &entry);
        SETCODE(code);
        if (code == 0) {
            HV *stats = newHV();
            if (parse_kaentryinfo(stats, &entry)) {
                EXTEND(sp, 1);
                PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
            }
            else {
                hv_undef(stats);
            }
        }
    }

void
kas_KAM_Debug(server,version)
        AFS::KAS        server
        int32   version
    PPCODE:
    {
        int32 code;
        struct ka_debugInfo entry;

        code = ubik_Call(KAM_Debug, server, 0, version, 0, &entry);
        SETCODE(code);
        if (code == 0) {
            HV *stats = newHV();
            if (parse_ka_debugInfo(stats, &entry)) {
                EXTEND(sp, 1);
                PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
            }
            else {
                hv_undef(stats);
            }
        }
    }

void
kas_KAM_GetStats(server,version)
        AFS::KAS        server
        int32   version
    PPCODE:
    {
        int32 code;
        int32 admin_accounts;
        struct kasstats kas;
        struct kadstats kad;

        code = ubik_Call(KAM_GetStats, server, 0, version, &admin_accounts, &kas, &kad);
        SETCODE(code);
        if (code == 0) {
            HV *stats = newHV();
            HV *dstats = newHV();
            if (parse_ka_getstats(stats, dstats, &kas, &kad)) {
                EXTEND(sp, 3);
                PUSHs(sv_2mortal(newSViv(admin_accounts)));
                PUSHs(sv_2mortal(newRV_noinc((SV *) stats)));
                PUSHs(sv_2mortal(newRV_noinc((SV *) dstats)));
            }
            else {
                hv_undef(stats);
                hv_undef(dstats);
            }
        }
    }

void
kas_KAM_GetRandomKey(server)
        AFS::KAS        server
    PPCODE:
    {
        int32 code;
        struct ktc_encryptionKey *key;

        key = (struct ktc_encryptionKey *) safemalloc(sizeof(*key));

        code = ubik_Call(KAM_GetRandomKey, server, 0, key);

        SETCODE(code);
        if (code == 0) {
            SV *st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_EKEY", (void *) key);
            PUSHs(st);
        }
        else {
            safefree(key);
        }
    }

void
kas_KAM_CreateUser(server,user,inst,key)
        AFS::KAS        server
        char *  user
        char *  inst
        AFS::KTC_EKEY   key
    PPCODE:
    {
        int32 code;

        code = ubik_Call(KAM_CreateUser, server, 0, user, inst, *key);

        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

void
kas_KAM_SetPassword(server,user,inst,kvno,key)
        AFS::KAS        server
        char *  user
        char *  inst
        int32   kvno
        AFS::KTC_EKEY   key
    PPCODE:
    {
        int32 code;

        code = ubik_Call(KAM_SetPassword, server, 0, user, inst, kvno, *key);

        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

void
kas_KAM_DeleteUser(server,user,inst)
        AFS::KAS        server
        char *  user
        char *  inst
    PPCODE:
    {
        int32 code;

        code = ubik_Call(KAM_DeleteUser, server, 0, user, inst);
        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

void
kas_KAM_ListEntry(server,previous,index,count)
        AFS::KAS        server
        int32   previous
        int32   index
        int32   count
    PPCODE:
    {
        int32 code;
        struct kaident ki;

        code = ubik_Call(KAM_ListEntry, server, 0, previous, &index, &count, &ki);
        sv_setiv(ST(2), (IV) index);
        sv_setiv(ST(3), (IV) count);
        SETCODE(code);
        if (code == 0 && count >= 0) {
            EXTEND(sp, 2);
            PUSHs(sv_2mortal(newSVpv(ki.name, strlen(ki.name))));
            PUSHs(sv_2mortal(newSVpv(ki.instance, strlen(ki.instance))));
        }
    }

void
kas_KAM_SetFields(server,name,instance,flags,user_expire,max_ticket_life, maxAssoc, misc_auth_bytes, spare2=0)
        AFS::KAS        server
        char *  name
        char *  instance
        int32   flags
        int32   user_expire
        int32   max_ticket_life
        int32   maxAssoc
        uint32  misc_auth_bytes
        int32   spare2
    PPCODE:
    {
        int32 code;

        #  tpf nog 03/29/99
        #  wrong argument list: max_ticket_life was missing
        #       code = ubik_Call(KAM_SetFields, server, 0, name, instance,
        #               flags, user_expire, maxAssoc, spare1,spare2);
        code = ubik_Call(KAM_SetFields, server, 0, name, instance,
                         flags, user_expire, max_ticket_life, maxAssoc, misc_auth_bytes, spare2);
        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

void
kas_ka_ChangePassword(server,name,instance,oldkey,newkey)
        AFS::KAS        server
        char *  name
        char *  instance
        AFS::KTC_EKEY   oldkey
        AFS::KTC_EKEY   newkey
    PPCODE:
    {
        int32 code;

        code = ka_ChangePassword(name, instance, server, oldkey, newkey);
        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

void
kas_ka_GetToken(server,name,instance,start,end,auth_token,auth_domain="")
        AFS::KAS        server
        char *  name
        char *  instance
        int32   start
        int32   end
        AFS::KTC_TOKEN  auth_token
        char *  auth_domain
    PPCODE:
    {
        int32 code;
        struct ktc_token *t;
#if defined(AFS_3_4)
#else
        char *cname = NULL;
        char *cinst = NULL;
        char *cell = NULL;
#endif

        t = (struct ktc_token *) safemalloc(sizeof(struct ktc_token));
#if defined(AFS_3_4)
        code = ka_GetToken(name, instance, server, start, end, auth_token, auth_domain, t);
#else
        if (cell == 0) {
            cell = internal_GetLocalCell(&code);
            if (code)
                XSRETURN_UNDEF;
        }
        code = ka_GetToken(name, instance, cell, cname, cinst, server,
                           start, end, auth_token, auth_domain, t);
#endif
        if (code == 0) {
            SV *st;
            EXTEND(sp, 1);
            st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_TOKEN", (void *) t);
            PUSHs(st);
            XSRETURN(1);
        }
        else {
            char buffer[256];
            sprintf(buffer, "AFS::KTC_TOKEN: ");
            KSETCODE(code, buffer);
            safefree(t);
            XSRETURN_UNDEF;
        }
    }

void
kas_ka_Authenticate(server,name,instance,service,key,start,end,pwexpires=-1)
        AFS::KAS        server
        char *  name
        char *  instance
        int32   service
        AFS::KTC_EKEY   key
        int32   start
        int32   end
        int32   pwexpires
    PPCODE:
    {
        int32 code;
        int32 pw;
        struct ktc_token *t;
#if defined(AFS_3_4)
#else
        char *cell = NULL;
#endif

        t = (struct ktc_token *) safemalloc(sizeof(struct ktc_token));
#if defined(AFS_3_4)
        code = ka_Authenticate(name, instance, server, service, key, start, end, t, &pw);
#else
        if (cell == 0) {
            cell = internal_GetLocalCell(&code);
            if (code)
                XSRETURN_UNDEF;
        }
        code = ka_Authenticate(name, instance, cell, server, service, key, start, end, t, &pw);
#endif
        if (code == 0) {
            SV *st;
            EXTEND(sp, 1);
            st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_TOKEN", (void *) t);
            PUSHs(st);
            if (pwexpires != -1)
                sv_setiv(ST(7), (IV) pw);
            XSRETURN(1);
        }
        else {
            char buffer[256];
            sprintf(buffer, "AFS::KTC_TOKEN: ");
            KSETCODE(code, buffer);
            safefree(t);
            XSRETURN_UNDEF;
        }
    }


MODULE = AFS    PACKAGE = AFS   PREFIX = afs_

BOOT:
    initialize_bz_error_table();
    initialize_vols_error_table();
    initialize_vl_error_table();
    initialize_u_error_table();
    initialize_pt_error_table();
    initialize_ka_error_table();
    initialize_acfg_error_table();
    initialize_ktc_error_table();
    initialize_rxk_error_table();
/*     initialize_cmd_error_table(); */
/*     initialize_budb_error_table(); */
/*     initialize_butm_error_table(); */
/*     initialize_butc_error_table(); */

void
afs__finalize()
    CODE:
    {
        if (rx_initialized) {
            rx_Finalize();
            /* printf("AFS DEBUG rx_Finalize\n"); */
        }
    }

int32
afs_ascii2ptsaccess(access)
        char *  access
    CODE:
    {
        int32 code, flags;

        code = parse_pts_setfields(access, &flags);
        SETCODE(code);

        if (code != 0)
            flags = 0;
        RETVAL = flags;
    }
    OUTPUT:
        RETVAL

void
afs_ptsaccess2ascii(flags)
        int32   flags
    CODE:
    {
        SETCODE(0);
        ST(0) = sv_newmortal();
        sv_setpv(ST(0), parse_flags_ptsaccess(flags));
    }

void
afs_ka_ParseLoginName(login)
        char *  login
    PPCODE:
    {
        int32 code;
        char name[MAXKTCNAMELEN];
        char inst[MAXKTCNAMELEN];
        char cell[MAXKTCREALMLEN];

        code = ka_ParseLoginName(login, name, inst, cell);
        SETCODE(code);
        if (code == 0) {
            EXTEND(sp, 3);
            PUSHs(sv_2mortal(newSVpv(name, strlen(name))));
            PUSHs(sv_2mortal(newSVpv(inst, strlen(inst))));
            PUSHs(sv_2mortal(newSVpv(cell, strlen(cell))));
        }
    }

void
afs_ka_StringToKey(str,cell)
        char *  str
        char *  cell
    PPCODE:
    {
        struct ktc_encryptionKey *key;
        SV *st;

        key = (struct ktc_encryptionKey *) safemalloc(sizeof(*key));

        ka_StringToKey(str, cell, key);

        SETCODE(0);
        EXTEND(sp, 1);
        st = sv_newmortal();
        sv_setref_pv(st, "AFS::KTC_EKEY", (void *) key);
        PUSHs(st);
    }

void
afs_ka_UserAthenticateGeneral(p,pass,life,flags,pwexpires=-1,reason=0)
        AFS::KTC_PRINCIPAL      p
        char *  pass
        int32   life
        int32   flags
        int32   pwexpires
        char *  reason
    PPCODE:
    {
        int32 code, pw = 255;
        char *r;
        code = ka_UserAuthenticateGeneral(flags,
                                          p->name, p->instance, p->cell, pass, life, &pw, 0, &r);
        if (pwexpires != -1)
            sv_setiv(ST(4), (IV) pw);
        if (reason)
            sv_setpv(ST(5), r);
        SETCODE(code);
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));
    }

void
afs_ka_ReadPassword(prompt,verify=0,cell=0)
        char *  prompt
        int32   verify
        char *  cell
    PPCODE:
    {
        int32 code = 0;
        struct ktc_encryptionKey *key;
        SV *st;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        if (cell == 0) {
            cell = internal_GetLocalCell(&code);
            if (code)
                XSRETURN_UNDEF;
        }

        key = (struct ktc_encryptionKey *) safemalloc(sizeof(*key));
        code = ka_ReadPassword(prompt, verify, cell, key);
        if (code == 0) {
            EXTEND(sp, 1);
            st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_EKEY", (void *) key);
            PUSHs(st);
            XSRETURN(1);
        }
        else {
            char buffer[256];
            sprintf(buffer, "AFS::KTC_EKEY: ");
            KSETCODE(code, buffer);
            safefree(key);
            XSRETURN_UNDEF;
        }
    }

void
afs_ka_UserReadPassword(prompt,reason=0)
        char *  prompt
        char *  reason
    PPCODE:
    {
        int32 code;
        char buffer[1024];
        char *r;
        code = ka_UserReadPassword(prompt, buffer, sizeof(buffer) - 1, &r);
        SETCODE(code);
        if (reason)
            sv_setpv(ST(1), r);
        if (code == 0) {
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSVpv(buffer, strlen(buffer))));
        }
    }

void
afs_ka_GetAdminToken(p,key,lifetime,newt=1,reason=0)
        AFS::KTC_PRINCIPAL  p
        AFS::KTC_EKEY       key
        int32               lifetime
        int32               newt
        char *  reason
    PPCODE:
    {
        int32 code;
        struct ktc_token *t;
        char *message;

        t = (struct ktc_token *) safemalloc(sizeof(struct ktc_token));

        code = ka_GetAdminToken(p->name, p->instance, p->cell, key, lifetime, t, newt);
        SETCODE(code);

        if (code == 0) {
            SV *st;
            EXTEND(sp, 1);
            st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_TOKEN", (void *) t);
            PUSHs(st);
        }
        else {
            safefree(t);
            switch (code) {
              case KABADREQUEST:
                  message = "password was incorrect";
                  break;
              case KAUBIKCALL:
                  message = "Authentication Server was unavailable";
                  break;
              default:
                  message = (char *) error_message(code);
            }
            sv_setpv(ST(4), message);
        }

    }


void
afs_ka_GetAuthToken(p,key,lifetime,pwexpires=-1)
        AFS::KTC_PRINCIPAL p
        AFS::KTC_EKEY      key
        int32              lifetime
        int32              pwexpires
    PPCODE:
    {
        int32 code;
        int32 pw;

        code = ka_GetAuthToken(p->name, p->instance, p->cell, key, lifetime, &pw);
        SETCODE(code);
        if (code == 0) {
            if (pwexpires != -1)
                sv_setiv(ST(3), (IV) pw);
        }
        EXTEND(sp, 1);
        PUSHs(sv_2mortal(newSViv(code == 0)));

    }


void
afs_ka_GetServerToken(p,lifetime,newt=1)
        AFS::KTC_PRINCIPAL      p
        int32                   lifetime
        int32                   newt
    PPCODE:
    {
        int32 code;
        struct ktc_token *t;
#if defined(AFS_3_4)
#else
        int32 dosetpag;
#endif

        t = (struct ktc_token *) safemalloc(sizeof(struct ktc_token));
#if defined(AFS_3_4)
        code = ka_GetServerToken(p->name, p->instance, p->cell, lifetime, t, newt);
#else
        dosetpag = 0;
        code = ka_GetServerToken(p->name, p->instance, p->cell, lifetime, t, newt, dosetpag);
#endif
        SETCODE(code);

        if (code == 0) {
            SV *st;
            EXTEND(sp, 1);
            st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_TOKEN", (void *) t);
            PUSHs(st);
        }
        else {
            safefree(t);
        }
    }

void
afs_ka_nulltoken()
    PPCODE:
    {
        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), "AFS::KTC_TOKEN", (void *) &the_null_token);
        XSRETURN(1);
    }

void
afs_ka_AuthServerConn(token,service,cell=0)
        AFS::KTC_TOKEN  token
        int32           service
        char *          cell
    PPCODE:
    {
        int32 code;
        AFS__KAS server;

        if (token == &the_null_token)
            token = NULL;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        code = ka_AuthServerConn(cell, service, token, &server);
        SETCODE(code);

        if (code == 0) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AFS::KAS", (void *) server);
            XSRETURN(1);
        }
    }

void
afs_ka_SingleServerConn(host,token,service,cell=0)
        char *          host
        AFS::KTC_TOKEN  token
        int32           service
        char *          cell
    PPCODE:
    {
        int32 code;
        AFS__KAS server;

        if (token == &the_null_token)
            token = NULL;

        code = ka_SingleServerConn(cell, host, service, token, &server);
        SETCODE(code);

        if (code == 0) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AFS::KAS", (void *) server);
            XSRETURN(1);
        }
    }

void
afs_ka_des_string_to_key(str)
        char *  str
    PPCODE:
    {
        struct ktc_encryptionKey *key;
        SV *st;

        key = (struct ktc_encryptionKey *) safemalloc(sizeof(*key));

        des_string_to_key(str, key);
        SETCODE(0);
        EXTEND(sp, 1);
        st = sv_newmortal();
        sv_setref_pv(st, "AFS::KTC_EKEY", (void *) key);
        PUSHs(st);
    }

int32
afs_setpag()
    CODE:
    {
        int32 code;

        code = setpag();
        SETCODE(code);
        RETVAL = (code == 0);
    }
    OUTPUT:
        RETVAL

void
afs_expandcell(cell)
        char *  cell
    PPCODE:
    {
        int32 code;
        struct afsconf_cell info;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        code = internal_GetCellInfo(cell, 0, &info);
        if (code != 0) {
            XSRETURN_UNDEF;
        }
        else {
            SETCODE(code);  /* fuer Fehler wird tiefer gesetzt... */
            ST(0) = sv_newmortal();
            sv_setpv(ST(0), info.name);
            XSRETURN(1);
        }
    }

void
afs_localcell()
    PPCODE:
    {
        int32 code;
        char *cell;

        cell = internal_GetLocalCell(&code);

        if (! code) SETCODE(code);  /* fuer Fehler wird tiefer gesetzt... */
        ST(0) = sv_newmortal();
        sv_setpv(ST(0), cell);
        XSRETURN(1);
    }

void
afs_getcellinfo(cell=0,ip=0)
        char *  cell
        int32   ip
    PPCODE:
    {
        int32 code;
        struct afsconf_cell info;

        if (cell && (cell[0] == '\0' || cell[0] == '0'))
            cell = NULL;

        code = internal_GetCellInfo(cell, 0, &info);
        if (code != 0) {
            XSRETURN_UNDEF;
        }
        else {
            int i;
            char *h;
            SETCODE(code);  /* fuer Fehler wird tiefer gesetzt... */
            XPUSHs(sv_2mortal(newSVpv(info.name, strlen(info.name))));
            for (i = 0; i < info.numServers; i++) {
                if (ip == 1) {
                    h = (char *) inet_ntoa(info.hostAddr[i].sin_addr);
                }
                else {
                    h = info.hostName[i];
                }
                XPUSHs(sv_2mortal(newSVpv(h, strlen(h))));
            }
            XSRETURN(i+1);
        }
    }

int32
afs_convert_numeric_names(...)
    CODE:
    {
        int32 flag;

        if (items > 1)
            croak("Usage: AFS::convert_numeric_names(flag)");
        if (items == 1) {
            flag = (int) SvIV(ST(0));
            convert_numeric_names = (flag != 0);
        }
        RETVAL = convert_numeric_names;
    }
    OUTPUT:
        RETVAL

int32
afs_raise_exception(...)
    CODE:
    {
        int32 flag;

        if (items > 1)
            croak("Usage: AFS::raise_exception(flag)");
        if (items == 1) {
            flag = (int) SvIV(ST(0));
            raise_exception = (flag != 0);
        }
        RETVAL = raise_exception;
    }
    OUTPUT:
        RETVAL

void
afs_configdir(...)
    PPCODE:
    {
        char *value;
        int32 code;

        if (items > 1)
            croak("Usage: AFS::configdir(dir)");

        if (items == 1) {
            STRLEN len;
            value = (char *) SvPV(ST(0), len);
            if (config_dir != NULL)
                safefree(config_dir);
            if (cdir != NULL) {
                afsconf_Close(cdir);
                cdir = NULL;
            }
            config_dir = (char *) safemalloc(len + 1);
            strcpy(config_dir, value);
            code = internal_GetConfigDir();
            # SETCODE(code);  wird tiefer gesetzt...
            ST(0) = sv_newmortal();
            sv_setiv(ST(0), (code == 0));
            XSRETURN(1);
        }
        else {
            code = internal_GetConfigDir();
            # SETCODE(code);  wird tiefer gesetzt...
            if (code == 0) {
                ST(0) = sv_newmortal();
                sv_setpv(ST(0), config_dir);
                XSRETURN(1);
            }
            else 
                XSRETURN_UNDEF;
        }
    }

  /* KTC routines */

AFS::KTC_PRINCIPAL
afs_ktc_ListTokens(context)
        int32   context
    PPCODE:
    {
        int32 code;
        struct ktc_principal *p;

        p = (struct ktc_principal *) safemalloc(sizeof(struct ktc_principal));
        code = ktc_ListTokens(context, &context, p);
        SETCODE(code);
        sv_setiv(ST(0), (IV) context);
        ST(0) = sv_newmortal();
        if (code == 0) {
            sv_setref_pv(ST(0), "AFS::KTC_PRINCIPAL", (void *) p);
        }
        else {
            safefree(p);
        }

        XSRETURN(1);
    }

void
afs_ktc_GetToken(server)
        AFS::KTC_PRINCIPAL      server
    PPCODE:
    {
        int32 code;
        struct ktc_principal *c;
        struct ktc_token *t;

        c = (struct ktc_principal *) safemalloc(sizeof(struct ktc_principal));
        t = (struct ktc_token *) safemalloc(sizeof(struct ktc_token));

        code = ktc_GetToken(server, t, sizeof(*t), c);
        SETCODE(code);

        if (code == 0) {
            SV *st, *sc;
            EXTEND(sp, 2);
            st = sv_newmortal();
            sv_setref_pv(st, "AFS::KTC_TOKEN", (void *) t);
            PUSHs(st);
            sc = sv_newmortal();
            sv_setref_pv(sc, "AFS::KTC_PRINCIPAL", (void *) c);
            PUSHs(sc);
        }
        else {
            safefree(c);
            safefree(t);
        }
    }

void
afs_ktc_FromString(s)
        SV *s
    PPCODE:
    {
        SV *sv;
        STRLEN len;
        char *str;
        struct ktc_token *t;

        str = SvPV(s, len);
        EXTEND(sp, 1);
        if (len == sizeof(struct ktc_token)) {
            t = (struct ktc_token *) safemalloc(sizeof(struct ktc_token));
            memcpy((void *) t, (void *) str, sizeof(struct ktc_token));

            sv = sv_newmortal();
            sv_setref_pv(sv, "AFS::KTC_TOKEN", (void *) t);
            PUSHs(sv);
        }
        else {
            PUSHs(&PL_sv_undef);
        }
    }

void
afs_ktc_SetToken(server,token,client,flags=0)
        AFS::KTC_PRINCIPAL   server
        AFS::KTC_TOKEN       token
        AFS::KTC_PRINCIPAL   client
        int32                flags
    PPCODE:
    {
        int32 code;
        code = ktc_SetToken(server, token, client, flags);
        SETCODE(code);
        ST(0) = sv_2mortal(newSViv(code == 0));
        XSRETURN(1);
    }

void
afs_ktc_ForgetAllTokens()
    PPCODE:
    {
        int32 code;
        code = ktc_ForgetAllTokens();
        SETCODE(code);
        ST(0) = sv_2mortal(newSViv(code == 0));
        XSRETURN(1);
    }

void
afs_error_message(code)
        int32   code
    PPCODE:
    {
        ST(0) = sv_newmortal();
        sv_setpv(ST(0), (char *) error_message(code));
        XSRETURN(1);
    }


  /* this function is generated automatically by constant_gen */
  /* You didn't think I would type in this crap did you? */
  /* thats what perl is for :-) */

#if defined(AFS_3_4)

void
constant(name, arg=0)
        char *  name
        int     arg
   PPCODE:
   {
  ST(0) = sv_newmortal();

  errno = EINVAL;

  switch (name[0]) {
  case 'A':
        switch (name[1]) {
        case 'F':
                switch (name[2]) {
                case 'S':
                if (strEQ(name,"AFSCONF_FAILURE")) sv_setiv(ST(0),AFSCONF_FAILURE);
                else if (strEQ(name,"AFSCONF_FULL")) sv_setiv(ST(0),AFSCONF_FULL);
                else if (strEQ(name,"AFSCONF_NOCELL")) sv_setiv(ST(0),AFSCONF_NOCELL);
                else if (strEQ(name,"AFSCONF_NODB")) sv_setiv(ST(0),AFSCONF_NODB);
                else if (strEQ(name,"AFSCONF_NOTFOUND")) sv_setiv(ST(0),AFSCONF_NOTFOUND);
                else if (strEQ(name,"AFSCONF_SYNTAX")) sv_setiv(ST(0),AFSCONF_SYNTAX);
                else if (strEQ(name,"AFSCONF_UNKNOWN")) sv_setiv(ST(0),AFSCONF_UNKNOWN);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'N':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"ANONYMOUSID")) sv_setiv(ST(0),ANONYMOUSID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'Y':
                if (strEQ(name,"ANYUSERID")) sv_setiv(ST(0),ANYUSERID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'U':
                switch (name[2]) {
                case 'T':
                if (strEQ(name,"AUTHUSERID")) sv_setiv(ST(0),AUTHUSERID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'C':
        switch (name[1]) {
        case 'O':
                switch (name[2]) {
                case 'S':
                if (strEQ(name,"COSIZE")) sv_setiv(ST(0),COSIZE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'R':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"CROSS_CELL")) sv_setiv(ST(0),CROSS_CELL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'K':
        switch (name[1]) {
        case 'A':
                switch (name[2]) {
                case 'A':
                if (strEQ(name,"KAANSWERTOOLONG")) sv_setiv(ST(0),KAANSWERTOOLONG);
                else if (strEQ(name,"KAASSOCUSER")) sv_setiv(ST(0),KAASSOCUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'B':
                if (strEQ(name,"KABADARGUMENT")) sv_setiv(ST(0),KABADARGUMENT);
                else if (strEQ(name,"KABADCMD")) sv_setiv(ST(0),KABADCMD);
                else if (strEQ(name,"KABADCPW")) sv_setiv(ST(0),KABADCPW);
                else if (strEQ(name,"KABADCREATE")) sv_setiv(ST(0),KABADCREATE);
                else if (strEQ(name,"KABADINDEX")) sv_setiv(ST(0),KABADINDEX);
                else if (strEQ(name,"KABADKEY")) sv_setiv(ST(0),KABADKEY);
                else if (strEQ(name,"KABADNAME")) sv_setiv(ST(0),KABADNAME);
                else if (strEQ(name,"KABADPROTOCOL")) sv_setiv(ST(0),KABADPROTOCOL);
                else if (strEQ(name,"KABADREQUEST")) sv_setiv(ST(0),KABADREQUEST);
                else if (strEQ(name,"KABADSERVER")) sv_setiv(ST(0),KABADSERVER);
                else if (strEQ(name,"KABADTICKET")) sv_setiv(ST(0),KABADTICKET);
                else if (strEQ(name,"KABADUSER")) sv_setiv(ST(0),KABADUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'C':
                if (strEQ(name,"KACLOCKSKEW")) sv_setiv(ST(0),KACLOCKSKEW);
                else if (strEQ(name,"KACREATEFAIL")) sv_setiv(ST(0),KACREATEFAIL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'D':
                if (strEQ(name,"KADATABASEINCONSISTENT")) sv_setiv(ST(0),KADATABASEINCONSISTENT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'E':
                if (strEQ(name,"KAEMPTY")) sv_setiv(ST(0),KAEMPTY);
                else if (strEQ(name,"KAEXIST")) sv_setiv(ST(0),KAEXIST);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'F':
                if (strEQ(name,"KAFADMIN")) sv_setiv(ST(0),KAFADMIN);
                else if (strEQ(name,"KAFASSOC")) sv_setiv(ST(0),KAFASSOC);
                else if (strEQ(name,"KAFASSOCROOT")) sv_setiv(ST(0),KAFASSOCROOT);
                else if (strEQ(name,"KAFFREE")) sv_setiv(ST(0),KAFFREE);
                else if (strEQ(name,"KAFNEWASSOC")) sv_setiv(ST(0),KAFNEWASSOC);
                else if (strEQ(name,"KAFNOCPW")) sv_setiv(ST(0),KAFNOCPW);
                else if (strEQ(name,"KAFNORMAL")) sv_setiv(ST(0),KAFNORMAL);
                else if (strEQ(name,"KAFNOSEAL")) sv_setiv(ST(0),KAFNOSEAL);
                else if (strEQ(name,"KAFNOTGS")) sv_setiv(ST(0),KAFNOTGS);
                else if (strEQ(name,"KAFOLDKEYS")) sv_setiv(ST(0),KAFOLDKEYS);
                else if (strEQ(name,"KAFSPECIAL")) sv_setiv(ST(0),KAFSPECIAL);
                else if (strEQ(name,"KAF_SETTABLE_FLAGS")) sv_setiv(ST(0),KAF_SETTABLE_FLAGS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'I':
                if (strEQ(name,"KAINTERNALERROR")) sv_setiv(ST(0),KAINTERNALERROR);
                else if (strEQ(name,"KAIO")) sv_setiv(ST(0),KAIO);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'K':
                if (strEQ(name,"KAKEYCACHEINVALID")) sv_setiv(ST(0),KAKEYCACHEINVALID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'L':
                if (strEQ(name,"KALOCKED")) sv_setiv(ST(0),KALOCKED);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'M':
                if (strEQ(name,"KAMAJORVERSION")) sv_setiv(ST(0),KAMAJORVERSION);
                else if (strEQ(name,"KAMINORVERSION")) sv_setiv(ST(0),KAMINORVERSION);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'N':
                if (strEQ(name,"KANOAUTH")) sv_setiv(ST(0),KANOAUTH);
                else if (strEQ(name,"KANOCELL")) sv_setiv(ST(0),KANOCELL);
                else if (strEQ(name,"KANOCELLS")) sv_setiv(ST(0),KANOCELLS);
                else if (strEQ(name,"KANOENT")) sv_setiv(ST(0),KANOENT);
                else if (strEQ(name,"KANOKEYS")) sv_setiv(ST(0),KANOKEYS);
                else if (strEQ(name,"KANORECURSE")) sv_setiv(ST(0),KANORECURSE);
                else if (strEQ(name,"KANOTICKET")) sv_setiv(ST(0),KANOTICKET);
                else if (strEQ(name,"KANOTSPECIAL")) sv_setiv(ST(0),KANOTSPECIAL);
                else if (strEQ(name,"KANULLPASSWORD")) sv_setiv(ST(0),KANULLPASSWORD);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'O':
                if (strEQ(name,"KAOLDINTERFACE")) sv_setiv(ST(0),KAOLDINTERFACE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'P':
                if (strEQ(name,"KAPWEXPIRED")) sv_setiv(ST(0),KAPWEXPIRED);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'R':
                if (strEQ(name,"KAREADPW")) sv_setiv(ST(0),KAREADPW);
                else if (strEQ(name,"KAREUSED")) sv_setiv(ST(0),KAREUSED);
                else if (strEQ(name,"KARXFAIL")) sv_setiv(ST(0),KARXFAIL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'T':
                if (strEQ(name,"KATOOMANYKEYS")) sv_setiv(ST(0),KATOOMANYKEYS);
                else if (strEQ(name,"KATOOMANYUBIKS")) sv_setiv(ST(0),KATOOMANYUBIKS);
                else if (strEQ(name,"KATOOSOON")) sv_setiv(ST(0),KATOOSOON);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'U':
                if (strEQ(name,"KAUBIKCALL")) sv_setiv(ST(0),KAUBIKCALL);
                else if (strEQ(name,"KAUBIKINIT")) sv_setiv(ST(0),KAUBIKINIT);
                else if (strEQ(name,"KAUNKNOWNKEY")) sv_setiv(ST(0),KAUNKNOWNKEY);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case '_':
                if (strEQ(name,"KA_ADMIN_INST")) sv_setpv(ST(0),KA_ADMIN_INST);
                else if (strEQ(name,"KA_ADMIN_NAME")) sv_setpv(ST(0),KA_ADMIN_NAME);
                else if (strEQ(name,"KA_AUTHENTICATION_SERVICE")) sv_setiv(ST(0),KA_AUTHENTICATION_SERVICE);
                else if (strEQ(name,"KA_ISLOCKED")) sv_setiv(ST(0),KA_ISLOCKED);
                else if (strEQ(name,"KA_MAINTENANCE_SERVICE")) sv_setiv(ST(0),KA_MAINTENANCE_SERVICE);
                else if (strEQ(name,"KA_NOREUSEPW")) sv_setiv(ST(0),KA_NOREUSEPW);
                else if (strEQ(name,"KA_REUSEPW")) sv_setiv(ST(0),KA_REUSEPW);
                else if (strEQ(name,"KA_TGS_NAME")) sv_setpv(ST(0),KA_TGS_NAME);
                else if (strEQ(name,"KA_TICKET_GRANTING_SERVICE")) sv_setiv(ST(0),KA_TICKET_GRANTING_SERVICE);
                else if (strEQ(name,"KA_USERAUTH_DOSETPAG")) sv_setiv(ST(0),KA_USERAUTH_DOSETPAG);
                else if (strEQ(name,"KA_USERAUTH_DOSETPAG2")) sv_setiv(ST(0),KA_USERAUTH_DOSETPAG2);
                else if (strEQ(name,"KA_USERAUTH_VERSION")) sv_setiv(ST(0),KA_USERAUTH_VERSION);
                else if (strEQ(name,"KA_USERAUTH_VERSION_MASK")) sv_setiv(ST(0),KA_USERAUTH_VERSION_MASK);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'T':
                switch (name[2]) {
                case 'C':
                if (strEQ(name,"KTC_TIME_UNCERTAINTY")) sv_setiv(ST(0),KTC_TIME_UNCERTAINTY);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'M':
        switch (name[1]) {
        case 'A':
                switch (name[2]) {
                case 'X':
                if (strEQ(name,"MAXKAKVNO")) sv_setiv(ST(0),MAXKAKVNO);
                else if (strEQ(name,"MAXKTCNAMELEN")) sv_setiv(ST(0),MAXKTCNAMELEN);
                else if (strEQ(name,"MAXKTCREALMLEN")) sv_setiv(ST(0),MAXKTCREALMLEN);
                else if (strEQ(name,"MAXKTCTICKETLEN")) sv_setiv(ST(0),MAXKTCTICKETLEN);
                else if (strEQ(name,"MAXKTCTICKETLIFETIME")) sv_setiv(ST(0),MAXKTCTICKETLIFETIME);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'I':
                switch (name[2]) {
                case 'N':
                if (strEQ(name,"MINKTCTICKETLEN")) sv_setiv(ST(0),MINKTCTICKETLEN);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'N':
        switch (name[1]) {
        case 'E':
                switch (name[2]) {
                case 'V':
                if (strEQ(name,"NEVERDATE")) sv_setiv(ST(0),NEVERDATE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'P':
        switch (name[1]) {
        case 'R':
                switch (name[2]) {
                case 'A':
                if (strEQ(name,"PRACCESS")) sv_setiv(ST(0),PRACCESS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'B':
                if (strEQ(name,"PRBADARG")) sv_setiv(ST(0),PRBADARG);
                else if (strEQ(name,"PRBADID")) sv_setiv(ST(0),PRBADID);
                else if (strEQ(name,"PRBADNAM")) sv_setiv(ST(0),PRBADNAM);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'C':
                if (strEQ(name,"PRCELL")) sv_setiv(ST(0),PRCELL);
                else if (strEQ(name,"PRCONT")) sv_setiv(ST(0),PRCONT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'D':
                if (strEQ(name,"PRDBADDR")) sv_setiv(ST(0),PRDBADDR);
                else if (strEQ(name,"PRDBBAD")) sv_setiv(ST(0),PRDBBAD);
                else if (strEQ(name,"PRDBFAIL")) sv_setiv(ST(0),PRDBFAIL);
                else if (strEQ(name,"PRDBVERSION")) sv_setiv(ST(0),PRDBVERSION);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'E':
                if (strEQ(name,"PREXIST")) sv_setiv(ST(0),PREXIST);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'F':
                if (strEQ(name,"PRFOREIGN")) sv_setiv(ST(0),PRFOREIGN);
                else if (strEQ(name,"PRFREE")) sv_setiv(ST(0),PRFREE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'G':
                if (strEQ(name,"PRGROUPEMPTY")) sv_setiv(ST(0),PRGROUPEMPTY);
                else if (strEQ(name,"PRGRP")) sv_setiv(ST(0),PRGRP);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'I':
                if (strEQ(name,"PRIDEXIST")) sv_setiv(ST(0),PRIDEXIST);
                else if (strEQ(name,"PRINCONSISTENT")) sv_setiv(ST(0),PRINCONSISTENT);
                else if (strEQ(name,"PRINST")) sv_setiv(ST(0),PRINST);
                else if (strEQ(name,"PRIVATE_SHIFT")) sv_setiv(ST(0),PRIVATE_SHIFT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'N':
                if (strEQ(name,"PRNOENT")) sv_setiv(ST(0),PRNOENT);
                else if (strEQ(name,"PRNOIDS")) sv_setiv(ST(0),PRNOIDS);
                else if (strEQ(name,"PRNOMORE")) sv_setiv(ST(0),PRNOMORE);
                else if (strEQ(name,"PRNOTGROUP")) sv_setiv(ST(0),PRNOTGROUP);
                else if (strEQ(name,"PRNOTUSER")) sv_setiv(ST(0),PRNOTUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'P':
                if (strEQ(name,"PRPERM")) sv_setiv(ST(0),PRPERM);
                else if (strEQ(name,"PRP_ADD_ANY")) sv_setiv(ST(0),PRP_ADD_ANY);
                else if (strEQ(name,"PRP_ADD_MEM")) sv_setiv(ST(0),PRP_ADD_MEM);
                else if (strEQ(name,"PRP_GROUP_DEFAULT")) sv_setiv(ST(0),PRP_GROUP_DEFAULT);
                else if (strEQ(name,"PRP_MEMBER_ANY")) sv_setiv(ST(0),PRP_MEMBER_ANY);
                else if (strEQ(name,"PRP_MEMBER_MEM")) sv_setiv(ST(0),PRP_MEMBER_MEM);
                else if (strEQ(name,"PRP_OWNED_ANY")) sv_setiv(ST(0),PRP_OWNED_ANY);
                else if (strEQ(name,"PRP_REMOVE_MEM")) sv_setiv(ST(0),PRP_REMOVE_MEM);
                else if (strEQ(name,"PRP_STATUS_ANY")) sv_setiv(ST(0),PRP_STATUS_ANY);
                else if (strEQ(name,"PRP_STATUS_MEM")) sv_setiv(ST(0),PRP_STATUS_MEM);
                else if (strEQ(name,"PRP_USER_DEFAULT")) sv_setiv(ST(0),PRP_USER_DEFAULT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'Q':
                if (strEQ(name,"PRQUOTA")) sv_setiv(ST(0),PRQUOTA);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'S':
                if (strEQ(name,"PRSFS_ADMINISTER")) sv_setiv(ST(0),PRSFS_ADMINISTER);
                else if (strEQ(name,"PRSFS_DELETE")) sv_setiv(ST(0),PRSFS_DELETE);
                else if (strEQ(name,"PRSFS_INSERT")) sv_setiv(ST(0),PRSFS_INSERT);
                else if (strEQ(name,"PRSFS_LOCK")) sv_setiv(ST(0),PRSFS_LOCK);
                else if (strEQ(name,"PRSFS_LOOKUP")) sv_setiv(ST(0),PRSFS_LOOKUP);
                else if (strEQ(name,"PRSFS_READ")) sv_setiv(ST(0),PRSFS_READ);
                else if (strEQ(name,"PRSFS_USR0")) sv_setiv(ST(0),PRSFS_USR0);
                else if (strEQ(name,"PRSFS_USR1")) sv_setiv(ST(0),PRSFS_USR1);
                else if (strEQ(name,"PRSFS_USR2")) sv_setiv(ST(0),PRSFS_USR2);
                else if (strEQ(name,"PRSFS_USR3")) sv_setiv(ST(0),PRSFS_USR3);
                else if (strEQ(name,"PRSFS_USR4")) sv_setiv(ST(0),PRSFS_USR4);
                else if (strEQ(name,"PRSFS_USR5")) sv_setiv(ST(0),PRSFS_USR5);
                else if (strEQ(name,"PRSFS_USR6")) sv_setiv(ST(0),PRSFS_USR6);
                else if (strEQ(name,"PRSFS_USR7")) sv_setiv(ST(0),PRSFS_USR7);
                else if (strEQ(name,"PRSFS_WRITE")) sv_setiv(ST(0),PRSFS_WRITE);
                else if (strEQ(name,"PRSIZE")) sv_setiv(ST(0),PRSIZE);
                else if (strEQ(name,"PRSUCCESS")) sv_setiv(ST(0),PRSUCCESS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'T':
                if (strEQ(name,"PRTOOMANY")) sv_setiv(ST(0),PRTOOMANY);
                else if (strEQ(name,"PRTYPE")) sv_setiv(ST(0),PRTYPE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'U':
                if (strEQ(name,"PRUSER")) sv_setiv(ST(0),PRUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case '_':
                if (strEQ(name,"PR_HIGHEST_OPCODE")) sv_setiv(ST(0),PR_HIGHEST_OPCODE);
                else if (strEQ(name,"PR_LOWEST_OPCODE")) sv_setiv(ST(0),PR_LOWEST_OPCODE);
                else if (strEQ(name,"PR_MAXGROUPS")) sv_setiv(ST(0),PR_MAXGROUPS);
                else if (strEQ(name,"PR_MAXLIST")) sv_setiv(ST(0),PR_MAXLIST);
                else if (strEQ(name,"PR_MAXNAMELEN")) sv_setiv(ST(0),PR_MAXNAMELEN);
                else if (strEQ(name,"PR_NUMBER_OPCODES")) sv_setiv(ST(0),PR_NUMBER_OPCODES);
                else if (strEQ(name,"PR_REMEMBER_TIMES")) sv_setiv(ST(0),PR_REMEMBER_TIMES);
                else if (strEQ(name,"PR_SF_ALLBITS")) sv_setiv(ST(0),PR_SF_ALLBITS);
                else if (strEQ(name,"PR_SF_NGROUPS")) sv_setiv(ST(0),PR_SF_NGROUPS);
                else if (strEQ(name,"PR_SF_NUSERS")) sv_setiv(ST(0),PR_SF_NUSERS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'R':
        switch (name[1]) {
        case 'X':
                switch (name[2]) {
                case 'K':
                if (strEQ(name,"RXKADBADKEY")) sv_setiv(ST(0),RXKADBADKEY);
                else if (strEQ(name,"RXKADBADTICKET")) sv_setiv(ST(0),RXKADBADTICKET);
                else if (strEQ(name,"RXKADDATALEN")) sv_setiv(ST(0),RXKADDATALEN);
                else if (strEQ(name,"RXKADEXPIRED")) sv_setiv(ST(0),RXKADEXPIRED);
                else if (strEQ(name,"RXKADILLEGALLEVEL")) sv_setiv(ST(0),RXKADILLEGALLEVEL);
                else if (strEQ(name,"RXKADINCONSISTENCY")) sv_setiv(ST(0),RXKADINCONSISTENCY);
                else if (strEQ(name,"RXKADLEVELFAIL")) sv_setiv(ST(0),RXKADLEVELFAIL);
                else if (strEQ(name,"RXKADNOAUTH")) sv_setiv(ST(0),RXKADNOAUTH);
                else if (strEQ(name,"RXKADOUTOFSEQUENCE")) sv_setiv(ST(0),RXKADOUTOFSEQUENCE);
                else if (strEQ(name,"RXKADPACKETSHORT")) sv_setiv(ST(0),RXKADPACKETSHORT);
                else if (strEQ(name,"RXKADSEALEDINCON")) sv_setiv(ST(0),RXKADSEALEDINCON);
                else if (strEQ(name,"RXKADTICKETLEN")) sv_setiv(ST(0),RXKADTICKETLEN);
                else if (strEQ(name,"RXKADUNKNOWNKEY")) sv_setiv(ST(0),RXKADUNKNOWNKEY);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case '_':
                if (strEQ(name,"RX_SCINDEX_KAD")) sv_setiv(ST(0),RX_SCINDEX_KAD);
                else if (strEQ(name,"RX_SCINDEX_NULL")) sv_setiv(ST(0),RX_SCINDEX_NULL);
                else if (strEQ(name,"RX_SCINDEX_VAB")) sv_setiv(ST(0),RX_SCINDEX_VAB);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'S':
        switch (name[1]) {
        case 'Y':
                switch (name[2]) {
                case 'S':
                if (strEQ(name,"SYSADMINID")) sv_setiv(ST(0),SYSADMINID);
                else if (strEQ(name,"SYSBACKUPID")) sv_setiv(ST(0),SYSBACKUPID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'U':
        switch (name[1]) {
        case 'B':
                switch (name[2]) {
                case 'A':
                if (strEQ(name,"UBADHOST")) sv_setiv(ST(0),UBADHOST);
                else if (strEQ(name,"UBADLOCK")) sv_setiv(ST(0),UBADLOCK);
                else if (strEQ(name,"UBADLOG")) sv_setiv(ST(0),UBADLOG);
                else if (strEQ(name,"UBADTYPE")) sv_setiv(ST(0),UBADTYPE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'D':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"UDONE")) sv_setiv(ST(0),UDONE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'E':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"UEOF")) sv_setiv(ST(0),UEOF);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'I':
                switch (name[2]) {
                case 'N':
                if (strEQ(name,"UINTERNAL")) sv_setiv(ST(0),UINTERNAL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'O':
                if (strEQ(name,"UIOERROR")) sv_setiv(ST(0),UIOERROR);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'L':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"ULOGIO")) sv_setiv(ST(0),ULOGIO);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'N':
                switch (name[2]) {
                case 'H':
                if (strEQ(name,"UNHOSTS")) sv_setiv(ST(0),UNHOSTS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'O':
                if (strEQ(name,"UNOENT")) sv_setiv(ST(0),UNOENT);
                else if (strEQ(name,"UNOQUORUM")) sv_setiv(ST(0),UNOQUORUM);
                else if (strEQ(name,"UNOSERVERS")) sv_setiv(ST(0),UNOSERVERS);
                else if (strEQ(name,"UNOTSYNC")) sv_setiv(ST(0),UNOTSYNC);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'S':
                switch (name[2]) {
                case 'Y':
                if (strEQ(name,"USYNC")) sv_setiv(ST(0),USYNC);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'T':
                switch (name[2]) {
                case 'W':
                if (strEQ(name,"UTWOENDS")) sv_setiv(ST(0),UTWOENDS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'V':
        switch (name[1]) {
        case 'I':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"VIOCACCESS")) sv_setiv(ST(0),VIOCACCESS);
                else if (strEQ(name,"VIOCCKBACK")) sv_setiv(ST(0),VIOCCKBACK);
                else if (strEQ(name,"VIOCCKCONN")) sv_setiv(ST(0),VIOCCKCONN);
                else if (strEQ(name,"VIOCCKSERV")) sv_setiv(ST(0),VIOCCKSERV);
                else if (strEQ(name,"VIOCDISGROUP")) sv_setiv(ST(0),VIOCDISGROUP);
                else if (strEQ(name,"VIOCENGROUP")) sv_setiv(ST(0),VIOCENGROUP);
                else if (strEQ(name,"VIOCFLUSH")) sv_setiv(ST(0),VIOCFLUSH);
                else if (strEQ(name,"VIOCFLUSHCB")) sv_setiv(ST(0),VIOCFLUSHCB);
                else if (strEQ(name,"VIOCGETAL")) sv_setiv(ST(0),VIOCGETAL);
                else if (strEQ(name,"VIOCGETCACHEPARMS")) sv_setiv(ST(0),VIOCGETCACHEPARMS);
                else if (strEQ(name,"VIOCGETCELL")) sv_setiv(ST(0),VIOCGETCELL);
                else if (strEQ(name,"VIOCGETFID")) sv_setiv(ST(0),VIOCGETFID);
                else if (strEQ(name,"VIOCGETTIME")) sv_setiv(ST(0),VIOCGETTIME);
                else if (strEQ(name,"VIOCGETTOK")) sv_setiv(ST(0),VIOCGETTOK);
                else if (strEQ(name,"VIOCGETVCXSTATUS")) sv_setiv(ST(0),VIOCGETVCXSTATUS);
                else if (strEQ(name,"VIOCGETVOLSTAT")) sv_setiv(ST(0),VIOCGETVOLSTAT);
                else if (strEQ(name,"VIOCLISTGROUPS")) sv_setiv(ST(0),VIOCLISTGROUPS);
                else if (strEQ(name,"VIOCNEWCELL")) sv_setiv(ST(0),VIOCNEWCELL);
                else if (strEQ(name,"VIOCNOP")) sv_setiv(ST(0),VIOCNOP);
                else if (strEQ(name,"VIOCPREFETCH")) sv_setiv(ST(0),VIOCPREFETCH);
                else if (strEQ(name,"VIOCSETAL")) sv_setiv(ST(0),VIOCSETAL);
                else if (strEQ(name,"VIOCSETCACHESIZE")) sv_setiv(ST(0),VIOCSETCACHESIZE);
                else if (strEQ(name,"VIOCSETTOK")) sv_setiv(ST(0),VIOCSETTOK);
                else if (strEQ(name,"VIOCSETVOLSTAT")) sv_setiv(ST(0),VIOCSETVOLSTAT);
                else if (strEQ(name,"VIOCSTAT")) sv_setiv(ST(0),VIOCSTAT);
                else if (strEQ(name,"VIOCUNLOG")) sv_setiv(ST(0),VIOCUNLOG);
                else if (strEQ(name,"VIOCUNPAG")) sv_setiv(ST(0),VIOCUNPAG);
                else if (strEQ(name,"VIOCWAITFOREVER")) sv_setiv(ST(0),VIOCWAITFOREVER);
                else if (strEQ(name,"VIOCWHEREIS")) sv_setiv(ST(0),VIOCWHEREIS);
                else if (strEQ(name,"VIOC_AFS_DELETE_MT_PT")) sv_setiv(ST(0),VIOC_AFS_DELETE_MT_PT);
                else if (strEQ(name,"VIOC_AFS_MARINER_HOST")) sv_setiv(ST(0),VIOC_AFS_MARINER_HOST);
                else if (strEQ(name,"VIOC_AFS_STAT_MT_PT")) sv_setiv(ST(0),VIOC_AFS_STAT_MT_PT);
                else if (strEQ(name,"VIOC_AFS_SYSNAME")) sv_setiv(ST(0),VIOC_AFS_SYSNAME);
                else if (strEQ(name,"VIOC_EXPORTAFS")) sv_setiv(ST(0),VIOC_EXPORTAFS);
                else if (strEQ(name,"VIOC_FILE_CELL_NAME")) sv_setiv(ST(0),VIOC_FILE_CELL_NAME);
                else if (strEQ(name,"VIOC_FLUSHVOLUME")) sv_setiv(ST(0),VIOC_FLUSHVOLUME);
                else if (strEQ(name,"VIOC_GAG")) sv_setiv(ST(0),VIOC_GAG);
                else if (strEQ(name,"VIOC_GETCELLSTATUS")) sv_setiv(ST(0),VIOC_GETCELLSTATUS);
                else if (strEQ(name,"VIOC_GETSPREFS")) sv_setiv(ST(0),VIOC_GETSPREFS);
                else if (strEQ(name,"VIOC_GET_PRIMARY_CELL")) sv_setiv(ST(0),VIOC_GET_PRIMARY_CELL);
                else if (strEQ(name,"VIOC_GET_WS_CELL")) sv_setiv(ST(0),VIOC_GET_WS_CELL);
                else if (strEQ(name,"VIOC_SETCELLSTATUS")) sv_setiv(ST(0),VIOC_SETCELLSTATUS);
                else if (strEQ(name,"VIOC_SETSPREFS")) sv_setiv(ST(0),VIOC_SETSPREFS);
                else if (strEQ(name,"VIOC_TWIDDLE")) sv_setiv(ST(0),VIOC_TWIDDLE);
                else if (strEQ(name,"VIOC_VENUSLOG")) sv_setiv(ST(0),VIOC_VENUSLOG);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  default:
        ST(0) = ST(1) = &PL_sv_undef;
        return;
  }

  errno = 0;
  XSRETURN(1);
  return;
 }

#else

void
constant(name, arg=0)
        char *  name
        int     arg
   PPCODE:
   {
  ST(0) = sv_newmortal();

  errno = EINVAL;

  switch (name[0]) {
  case 'A':
        switch (name[1]) {
        case 'F':
                switch (name[2]) {
                case 'S':
                if (strEQ(name,"AFSCONF_FAILURE")) sv_setiv(ST(0),AFSCONF_FAILURE);
                else if (strEQ(name,"AFSCONF_FULL")) sv_setiv(ST(0),AFSCONF_FULL);
                else if (strEQ(name,"AFSCONF_NOCELL")) sv_setiv(ST(0),AFSCONF_NOCELL);
                else if (strEQ(name,"AFSCONF_NODB")) sv_setiv(ST(0),AFSCONF_NODB);
                else if (strEQ(name,"AFSCONF_NOTFOUND")) sv_setiv(ST(0),AFSCONF_NOTFOUND);
                else if (strEQ(name,"AFSCONF_SYNTAX")) sv_setiv(ST(0),AFSCONF_SYNTAX);
                else if (strEQ(name,"AFSCONF_UNKNOWN")) sv_setiv(ST(0),AFSCONF_UNKNOWN);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'N':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"ANONYMOUSID")) sv_setiv(ST(0),ANONYMOUSID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'Y':
                if (strEQ(name,"ANYUSERID")) sv_setiv(ST(0),ANYUSERID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'U':
                switch (name[2]) {
                case 'T':
                if (strEQ(name,"AUTHUSERID")) sv_setiv(ST(0),AUTHUSERID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'C':
        switch (name[1]) {
        case 'O':
                switch (name[2]) {
                case 'S':
                if (strEQ(name,"COSIZE")) sv_setiv(ST(0),COSIZE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'K':
        switch (name[1]) {
        case 'A':
                switch (name[2]) {
                case 'A':
                if (strEQ(name,"KAANSWERTOOLONG")) sv_setiv(ST(0),KAANSWERTOOLONG);
                else if (strEQ(name,"KAASSOCUSER")) sv_setiv(ST(0),KAASSOCUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'B':
                if (strEQ(name,"KABADARGUMENT")) sv_setiv(ST(0),KABADARGUMENT);
                else if (strEQ(name,"KABADCMD")) sv_setiv(ST(0),KABADCMD);
                else if (strEQ(name,"KABADCPW")) sv_setiv(ST(0),KABADCPW);
                else if (strEQ(name,"KABADCREATE")) sv_setiv(ST(0),KABADCREATE);
                else if (strEQ(name,"KABADINDEX")) sv_setiv(ST(0),KABADINDEX);
                else if (strEQ(name,"KABADKEY")) sv_setiv(ST(0),KABADKEY);
                else if (strEQ(name,"KABADNAME")) sv_setiv(ST(0),KABADNAME);
                else if (strEQ(name,"KABADPROTOCOL")) sv_setiv(ST(0),KABADPROTOCOL);
                else if (strEQ(name,"KABADREQUEST")) sv_setiv(ST(0),KABADREQUEST);
                else if (strEQ(name,"KABADSERVER")) sv_setiv(ST(0),KABADSERVER);
                else if (strEQ(name,"KABADTICKET")) sv_setiv(ST(0),KABADTICKET);
                else if (strEQ(name,"KABADUSER")) sv_setiv(ST(0),KABADUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'C':
                if (strEQ(name,"KACLOCKSKEW")) sv_setiv(ST(0),KACLOCKSKEW);
                else if (strEQ(name,"KACREATEFAIL")) sv_setiv(ST(0),KACREATEFAIL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'D':
                if (strEQ(name,"KADATABASEINCONSISTENT")) sv_setiv(ST(0),KADATABASEINCONSISTENT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'E':
                if (strEQ(name,"KAEMPTY")) sv_setiv(ST(0),KAEMPTY);
                else if (strEQ(name,"KAEXIST")) sv_setiv(ST(0),KAEXIST);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'F':
                if (strEQ(name,"KAFADMIN")) sv_setiv(ST(0),KAFADMIN);
                else if (strEQ(name,"KAFASSOC")) sv_setiv(ST(0),KAFASSOC);
                else if (strEQ(name,"KAFASSOCROOT")) sv_setiv(ST(0),KAFASSOCROOT);
                else if (strEQ(name,"KAFFREE")) sv_setiv(ST(0),KAFFREE);
                else if (strEQ(name,"KAFNEWASSOC")) sv_setiv(ST(0),KAFNEWASSOC);
                else if (strEQ(name,"KAFNOCPW")) sv_setiv(ST(0),KAFNOCPW);
                else if (strEQ(name,"KAFNORMAL")) sv_setiv(ST(0),KAFNORMAL);
                else if (strEQ(name,"KAFNOSEAL")) sv_setiv(ST(0),KAFNOSEAL);
                else if (strEQ(name,"KAFNOTGS")) sv_setiv(ST(0),KAFNOTGS);
                else if (strEQ(name,"KAFOLDKEYS")) sv_setiv(ST(0),KAFOLDKEYS);
                else if (strEQ(name,"KAFSPECIAL")) sv_setiv(ST(0),KAFSPECIAL);
                else if (strEQ(name,"KAF_SETTABLE_FLAGS")) sv_setiv(ST(0),KAF_SETTABLE_FLAGS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'I':
                if (strEQ(name,"KAINTERNALERROR")) sv_setiv(ST(0),KAINTERNALERROR);
                else if (strEQ(name,"KAIO")) sv_setiv(ST(0),KAIO);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'K':
                if (strEQ(name,"KAKEYCACHEINVALID")) sv_setiv(ST(0),KAKEYCACHEINVALID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'L':
                if (strEQ(name,"KALOCKED")) sv_setiv(ST(0),KALOCKED);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'M':
                if (strEQ(name,"KAMAJORVERSION")) sv_setiv(ST(0),KAMAJORVERSION);
                else if (strEQ(name,"KAMINORVERSION")) sv_setiv(ST(0),KAMINORVERSION);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'N':
                if (strEQ(name,"KANOAUTH")) sv_setiv(ST(0),KANOAUTH);
                else if (strEQ(name,"KANOCELL")) sv_setiv(ST(0),KANOCELL);
                else if (strEQ(name,"KANOCELLS")) sv_setiv(ST(0),KANOCELLS);
                else if (strEQ(name,"KANOENT")) sv_setiv(ST(0),KANOENT);
                else if (strEQ(name,"KANOKEYS")) sv_setiv(ST(0),KANOKEYS);
                else if (strEQ(name,"KANORECURSE")) sv_setiv(ST(0),KANORECURSE);
                else if (strEQ(name,"KANOTICKET")) sv_setiv(ST(0),KANOTICKET);
                else if (strEQ(name,"KANOTSPECIAL")) sv_setiv(ST(0),KANOTSPECIAL);
                else if (strEQ(name,"KANULLPASSWORD")) sv_setiv(ST(0),KANULLPASSWORD);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'O':
                if (strEQ(name,"KAOLDINTERFACE")) sv_setiv(ST(0),KAOLDINTERFACE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'P':
                if (strEQ(name,"KAPWEXPIRED")) sv_setiv(ST(0),KAPWEXPIRED);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'R':
                if (strEQ(name,"KAREADPW")) sv_setiv(ST(0),KAREADPW);
                else if (strEQ(name,"KAREUSED")) sv_setiv(ST(0),KAREUSED);
                else if (strEQ(name,"KARXFAIL")) sv_setiv(ST(0),KARXFAIL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'T':
                if (strEQ(name,"KATOOMANYKEYS")) sv_setiv(ST(0),KATOOMANYKEYS);
                else if (strEQ(name,"KATOOMANYUBIKS")) sv_setiv(ST(0),KATOOMANYUBIKS);
                else if (strEQ(name,"KATOOSOON")) sv_setiv(ST(0),KATOOSOON);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'U':
                if (strEQ(name,"KAUBIKCALL")) sv_setiv(ST(0),KAUBIKCALL);
                else if (strEQ(name,"KAUBIKINIT")) sv_setiv(ST(0),KAUBIKINIT);
                else if (strEQ(name,"KAUNKNOWNKEY")) sv_setiv(ST(0),KAUNKNOWNKEY);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case '_':
                if (strEQ(name,"KA_ADMIN_INST")) sv_setpv(ST(0),KA_ADMIN_INST);
                else if (strEQ(name,"KA_ADMIN_NAME")) sv_setpv(ST(0),KA_ADMIN_NAME);
                else if (strEQ(name,"KA_AUTHENTICATION_SERVICE")) sv_setiv(ST(0),KA_AUTHENTICATION_SERVICE);
                else if (strEQ(name,"KA_ISLOCKED")) sv_setiv(ST(0),KA_ISLOCKED);
                else if (strEQ(name,"KA_MAINTENANCE_SERVICE")) sv_setiv(ST(0),KA_MAINTENANCE_SERVICE);
                else if (strEQ(name,"KA_NOREUSEPW")) sv_setiv(ST(0),KA_NOREUSEPW);
                else if (strEQ(name,"KA_REUSEPW")) sv_setiv(ST(0),KA_REUSEPW);
                else if (strEQ(name,"KA_TGS_NAME")) sv_setpv(ST(0),KA_TGS_NAME);
                else if (strEQ(name,"KA_TICKET_GRANTING_SERVICE")) sv_setiv(ST(0),KA_TICKET_GRANTING_SERVICE);
                else if (strEQ(name,"KA_USERAUTH_DOSETPAG")) sv_setiv(ST(0),KA_USERAUTH_DOSETPAG);
                else if (strEQ(name,"KA_USERAUTH_DOSETPAG2")) sv_setiv(ST(0),KA_USERAUTH_DOSETPAG2);
                else if (strEQ(name,"KA_USERAUTH_VERSION")) sv_setiv(ST(0),KA_USERAUTH_VERSION);
                else if (strEQ(name,"KA_USERAUTH_VERSION_MASK")) sv_setiv(ST(0),KA_USERAUTH_VERSION_MASK);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'T':
                switch (name[2]) {
                case 'C':
                if (strEQ(name,"KTC_TIME_UNCERTAINTY")) sv_setiv(ST(0),KTC_TIME_UNCERTAINTY);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'M':
        switch (name[1]) {
        case 'A':
                switch (name[2]) {
                case 'X':
                if (strEQ(name,"MAXKAKVNO")) sv_setiv(ST(0),MAXKAKVNO);
                else if (strEQ(name,"MAXKTCNAMELEN")) sv_setiv(ST(0),MAXKTCNAMELEN);
                else if (strEQ(name,"MAXKTCREALMLEN")) sv_setiv(ST(0),MAXKTCREALMLEN);
                else if (strEQ(name,"MAXKTCTICKETLEN")) sv_setiv(ST(0),MAXKTCTICKETLEN);
                else if (strEQ(name,"MAXKTCTICKETLIFETIME")) sv_setiv(ST(0),MAXKTCTICKETLIFETIME);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'I':
                switch (name[2]) {
                case 'N':
                if (strEQ(name,"MINKTCTICKETLEN")) sv_setiv(ST(0),MINKTCTICKETLEN);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'N':
        switch (name[1]) {
        case 'E':
                switch (name[2]) {
                case 'V':
                if (strEQ(name,"NEVERDATE")) sv_setiv(ST(0),NEVERDATE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'P':
        switch (name[1]) {
        case 'R':
                switch (name[2]) {
                case 'A':
                if (strEQ(name,"PRACCESS")) sv_setiv(ST(0),PRACCESS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'B':
                if (strEQ(name,"PRBADARG")) sv_setiv(ST(0),PRBADARG);
                else if (strEQ(name,"PRBADID")) sv_setiv(ST(0),PRBADID);
                else if (strEQ(name,"PRBADNAM")) sv_setiv(ST(0),PRBADNAM);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'C':
                if (strEQ(name,"PRCELL")) sv_setiv(ST(0),PRCELL);
                else if (strEQ(name,"PRCONT")) sv_setiv(ST(0),PRCONT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'D':
                if (strEQ(name,"PRDBADDR")) sv_setiv(ST(0),PRDBADDR);
                else if (strEQ(name,"PRDBBAD")) sv_setiv(ST(0),PRDBBAD);
                else if (strEQ(name,"PRDBFAIL")) sv_setiv(ST(0),PRDBFAIL);
                else if (strEQ(name,"PRDBVERSION")) sv_setiv(ST(0),PRDBVERSION);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'E':
                if (strEQ(name,"PREXIST")) sv_setiv(ST(0),PREXIST);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'F':
                if (strEQ(name,"PRFOREIGN")) sv_setiv(ST(0),PRFOREIGN);
                else if (strEQ(name,"PRFREE")) sv_setiv(ST(0),PRFREE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'G':
                if (strEQ(name,"PRGROUPEMPTY")) sv_setiv(ST(0),PRGROUPEMPTY);
                else if (strEQ(name,"PRGRP")) sv_setiv(ST(0),PRGRP);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'I':
                if (strEQ(name,"PRIDEXIST")) sv_setiv(ST(0),PRIDEXIST);
                else if (strEQ(name,"PRINCONSISTENT")) sv_setiv(ST(0),PRINCONSISTENT);
                else if (strEQ(name,"PRINST")) sv_setiv(ST(0),PRINST);
                else if (strEQ(name,"PRIVATE_SHIFT")) sv_setiv(ST(0),PRIVATE_SHIFT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'N':
                if (strEQ(name,"PRNOENT")) sv_setiv(ST(0),PRNOENT);
                else if (strEQ(name,"PRNOIDS")) sv_setiv(ST(0),PRNOIDS);
                else if (strEQ(name,"PRNOMORE")) sv_setiv(ST(0),PRNOMORE);
                else if (strEQ(name,"PRNOTGROUP")) sv_setiv(ST(0),PRNOTGROUP);
                else if (strEQ(name,"PRNOTUSER")) sv_setiv(ST(0),PRNOTUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'P':
                if (strEQ(name,"PRPERM")) sv_setiv(ST(0),PRPERM);
                else if (strEQ(name,"PRP_ADD_ANY")) sv_setiv(ST(0),PRP_ADD_ANY);
                else if (strEQ(name,"PRP_ADD_MEM")) sv_setiv(ST(0),PRP_ADD_MEM);
                else if (strEQ(name,"PRP_GROUP_DEFAULT")) sv_setiv(ST(0),PRP_GROUP_DEFAULT);
                else if (strEQ(name,"PRP_MEMBER_ANY")) sv_setiv(ST(0),PRP_MEMBER_ANY);
                else if (strEQ(name,"PRP_MEMBER_MEM")) sv_setiv(ST(0),PRP_MEMBER_MEM);
                else if (strEQ(name,"PRP_OWNED_ANY")) sv_setiv(ST(0),PRP_OWNED_ANY);
                else if (strEQ(name,"PRP_REMOVE_MEM")) sv_setiv(ST(0),PRP_REMOVE_MEM);
                else if (strEQ(name,"PRP_STATUS_ANY")) sv_setiv(ST(0),PRP_STATUS_ANY);
                else if (strEQ(name,"PRP_STATUS_MEM")) sv_setiv(ST(0),PRP_STATUS_MEM);
                else if (strEQ(name,"PRP_USER_DEFAULT")) sv_setiv(ST(0),PRP_USER_DEFAULT);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'Q':
                if (strEQ(name,"PRQUOTA")) sv_setiv(ST(0),PRQUOTA);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'S':
                if (strEQ(name,"PRSFS_ADMINISTER")) sv_setiv(ST(0),PRSFS_ADMINISTER);
                else if (strEQ(name,"PRSFS_DELETE")) sv_setiv(ST(0),PRSFS_DELETE);
                else if (strEQ(name,"PRSFS_INSERT")) sv_setiv(ST(0),PRSFS_INSERT);
                else if (strEQ(name,"PRSFS_LOCK")) sv_setiv(ST(0),PRSFS_LOCK);
                else if (strEQ(name,"PRSFS_LOOKUP")) sv_setiv(ST(0),PRSFS_LOOKUP);
                else if (strEQ(name,"PRSFS_READ")) sv_setiv(ST(0),PRSFS_READ);
                else if (strEQ(name,"PRSFS_USR0")) sv_setiv(ST(0),PRSFS_USR0);
                else if (strEQ(name,"PRSFS_USR1")) sv_setiv(ST(0),PRSFS_USR1);
                else if (strEQ(name,"PRSFS_USR2")) sv_setiv(ST(0),PRSFS_USR2);
                else if (strEQ(name,"PRSFS_USR3")) sv_setiv(ST(0),PRSFS_USR3);
                else if (strEQ(name,"PRSFS_USR4")) sv_setiv(ST(0),PRSFS_USR4);
                else if (strEQ(name,"PRSFS_USR5")) sv_setiv(ST(0),PRSFS_USR5);
                else if (strEQ(name,"PRSFS_USR6")) sv_setiv(ST(0),PRSFS_USR6);
                else if (strEQ(name,"PRSFS_USR7")) sv_setiv(ST(0),PRSFS_USR7);
                else if (strEQ(name,"PRSFS_WRITE")) sv_setiv(ST(0),PRSFS_WRITE);
                else if (strEQ(name,"PRSIZE")) sv_setiv(ST(0),PRSIZE);
                else if (strEQ(name,"PRSUCCESS")) sv_setiv(ST(0),PRSUCCESS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'T':
                if (strEQ(name,"PRTOOMANY")) sv_setiv(ST(0),PRTOOMANY);
                else if (strEQ(name,"PRTYPE")) sv_setiv(ST(0),PRTYPE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'U':
                if (strEQ(name,"PRUSER")) sv_setiv(ST(0),PRUSER);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case '_':
                if (strEQ(name,"PR_HIGHEST_OPCODE")) sv_setiv(ST(0),PR_HIGHEST_OPCODE);
                else if (strEQ(name,"PR_LOWEST_OPCODE")) sv_setiv(ST(0),PR_LOWEST_OPCODE);
                else if (strEQ(name,"PR_MAXGROUPS")) sv_setiv(ST(0),PR_MAXGROUPS);
                else if (strEQ(name,"PR_MAXLIST")) sv_setiv(ST(0),PR_MAXLIST);
                else if (strEQ(name,"PR_MAXNAMELEN")) sv_setiv(ST(0),PR_MAXNAMELEN);
                else if (strEQ(name,"PR_NUMBER_OPCODES")) sv_setiv(ST(0),PR_NUMBER_OPCODES);
                else if (strEQ(name,"PR_REMEMBER_TIMES")) sv_setiv(ST(0),PR_REMEMBER_TIMES);
                else if (strEQ(name,"PR_SF_ALLBITS")) sv_setiv(ST(0),PR_SF_ALLBITS);
                else if (strEQ(name,"PR_SF_NGROUPS")) sv_setiv(ST(0),PR_SF_NGROUPS);
                else if (strEQ(name,"PR_SF_NUSERS")) sv_setiv(ST(0),PR_SF_NUSERS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'R':
        switch (name[1]) {
        case 'X':
                switch (name[2]) {
                case 'K':
                if (strEQ(name,"RXKADBADKEY")) sv_setiv(ST(0),RXKADBADKEY);
                else if (strEQ(name,"RXKADBADTICKET")) sv_setiv(ST(0),RXKADBADTICKET);
                else if (strEQ(name,"RXKADDATALEN")) sv_setiv(ST(0),RXKADDATALEN);
                else if (strEQ(name,"RXKADEXPIRED")) sv_setiv(ST(0),RXKADEXPIRED);
                else if (strEQ(name,"RXKADILLEGALLEVEL")) sv_setiv(ST(0),RXKADILLEGALLEVEL);
                else if (strEQ(name,"RXKADINCONSISTENCY")) sv_setiv(ST(0),RXKADINCONSISTENCY);
                else if (strEQ(name,"RXKADLEVELFAIL")) sv_setiv(ST(0),RXKADLEVELFAIL);
                else if (strEQ(name,"RXKADNOAUTH")) sv_setiv(ST(0),RXKADNOAUTH);
                else if (strEQ(name,"RXKADOUTOFSEQUENCE")) sv_setiv(ST(0),RXKADOUTOFSEQUENCE);
                else if (strEQ(name,"RXKADPACKETSHORT")) sv_setiv(ST(0),RXKADPACKETSHORT);
                else if (strEQ(name,"RXKADSEALEDINCON")) sv_setiv(ST(0),RXKADSEALEDINCON);
                else if (strEQ(name,"RXKADTICKETLEN")) sv_setiv(ST(0),RXKADTICKETLEN);
                else if (strEQ(name,"RXKADUNKNOWNKEY")) sv_setiv(ST(0),RXKADUNKNOWNKEY);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case '_':
                if (strEQ(name,"RX_SCINDEX_KAD")) sv_setiv(ST(0),RX_SCINDEX_KAD);
                else if (strEQ(name,"RX_SCINDEX_NULL")) sv_setiv(ST(0),RX_SCINDEX_NULL);
                else if (strEQ(name,"RX_SCINDEX_VAB")) sv_setiv(ST(0),RX_SCINDEX_VAB);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'S':
        switch (name[1]) {
        case 'Y':
                switch (name[2]) {
                case 'S':
                if (strEQ(name,"SYSADMINID")) sv_setiv(ST(0),SYSADMINID);
                else if (strEQ(name,"SYSBACKUPID")) sv_setiv(ST(0),SYSBACKUPID);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'U':
        switch (name[1]) {
        case 'B':
                switch (name[2]) {
                case 'A':
                if (strEQ(name,"UBADHOST")) sv_setiv(ST(0),UBADHOST);
                else if (strEQ(name,"UBADLOCK")) sv_setiv(ST(0),UBADLOCK);
                else if (strEQ(name,"UBADLOG")) sv_setiv(ST(0),UBADLOG);
                else if (strEQ(name,"UBADTYPE")) sv_setiv(ST(0),UBADTYPE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'D':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"UDONE")) sv_setiv(ST(0),UDONE);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'E':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"UEOF")) sv_setiv(ST(0),UEOF);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'I':
                switch (name[2]) {
                case 'N':
                if (strEQ(name,"UINTERNAL")) sv_setiv(ST(0),UINTERNAL);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'O':
                if (strEQ(name,"UIOERROR")) sv_setiv(ST(0),UIOERROR);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'L':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"ULOGIO")) sv_setiv(ST(0),ULOGIO);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'N':
                switch (name[2]) {
                case 'H':
                if (strEQ(name,"UNHOSTS")) sv_setiv(ST(0),UNHOSTS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                case 'O':
                if (strEQ(name,"UNOENT")) sv_setiv(ST(0),UNOENT);
                else if (strEQ(name,"UNOQUORUM")) sv_setiv(ST(0),UNOQUORUM);
                else if (strEQ(name,"UNOSERVERS")) sv_setiv(ST(0),UNOSERVERS);
                else if (strEQ(name,"UNOTSYNC")) sv_setiv(ST(0),UNOTSYNC);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'S':
                switch (name[2]) {
                case 'Y':
                if (strEQ(name,"USYNC")) sv_setiv(ST(0),USYNC);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        case 'T':
                switch (name[2]) {
                case 'W':
                if (strEQ(name,"UTWOENDS")) sv_setiv(ST(0),UTWOENDS);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  case 'V':
        switch (name[1]) {
        case 'I':
                switch (name[2]) {
                case 'O':
                if (strEQ(name,"VIOCACCESS")) sv_setiv(ST(0),VIOCACCESS);
                else if (strEQ(name,"VIOCCKBACK")) sv_setiv(ST(0),VIOCCKBACK);
                else if (strEQ(name,"VIOCCKCONN")) sv_setiv(ST(0),VIOCCKCONN);
                else if (strEQ(name,"VIOCCKSERV")) sv_setiv(ST(0),VIOCCKSERV);
                else if (strEQ(name,"VIOCDISGROUP")) sv_setiv(ST(0),VIOCDISGROUP);
                else if (strEQ(name,"VIOCENGROUP")) sv_setiv(ST(0),VIOCENGROUP);
                else if (strEQ(name,"VIOCFLUSH")) sv_setiv(ST(0),VIOCFLUSH);
                else if (strEQ(name,"VIOCFLUSHCB")) sv_setiv(ST(0),VIOCFLUSHCB);
                else if (strEQ(name,"VIOCGETAL")) sv_setiv(ST(0),VIOCGETAL);
                else if (strEQ(name,"VIOCGETCACHEPARMS")) sv_setiv(ST(0),VIOCGETCACHEPARMS);
                else if (strEQ(name,"VIOCGETCELL")) sv_setiv(ST(0),VIOCGETCELL);
                else if (strEQ(name,"VIOCGETFID")) sv_setiv(ST(0),VIOCGETFID);
                else if (strEQ(name,"VIOCGETTIME")) sv_setiv(ST(0),VIOCGETTIME);
                else if (strEQ(name,"VIOCGETTOK")) sv_setiv(ST(0),VIOCGETTOK);
                else if (strEQ(name,"VIOCGETVCXSTATUS")) sv_setiv(ST(0),VIOCGETVCXSTATUS);
                else if (strEQ(name,"VIOCGETVOLSTAT")) sv_setiv(ST(0),VIOCGETVOLSTAT);
                else if (strEQ(name,"VIOCLISTGROUPS")) sv_setiv(ST(0),VIOCLISTGROUPS);
                else if (strEQ(name,"VIOCNEWCELL")) sv_setiv(ST(0),VIOCNEWCELL);
                else if (strEQ(name,"VIOCNOP")) sv_setiv(ST(0),VIOCNOP);
                else if (strEQ(name,"VIOCPREFETCH")) sv_setiv(ST(0),VIOCPREFETCH);
                else if (strEQ(name,"VIOCSETAL")) sv_setiv(ST(0),VIOCSETAL);
                else if (strEQ(name,"VIOCSETCACHESIZE")) sv_setiv(ST(0),VIOCSETCACHESIZE);
                else if (strEQ(name,"VIOCSETTOK")) sv_setiv(ST(0),VIOCSETTOK);
                else if (strEQ(name,"VIOCSETVOLSTAT")) sv_setiv(ST(0),VIOCSETVOLSTAT);
                else if (strEQ(name,"VIOCSTAT")) sv_setiv(ST(0),VIOCSTAT);
                else if (strEQ(name,"VIOCUNLOG")) sv_setiv(ST(0),VIOCUNLOG);
                else if (strEQ(name,"VIOCUNPAG")) sv_setiv(ST(0),VIOCUNPAG);
                else if (strEQ(name,"VIOCWAITFOREVER")) sv_setiv(ST(0),VIOCWAITFOREVER);
                else if (strEQ(name,"VIOCWHEREIS")) sv_setiv(ST(0),VIOCWHEREIS);
                else if (strEQ(name,"VIOC_AFS_DELETE_MT_PT")) sv_setiv(ST(0),VIOC_AFS_DELETE_MT_PT);
                else if (strEQ(name,"VIOC_AFS_MARINER_HOST")) sv_setiv(ST(0),VIOC_AFS_MARINER_HOST);
                else if (strEQ(name,"VIOC_AFS_STAT_MT_PT")) sv_setiv(ST(0),VIOC_AFS_STAT_MT_PT);
                else if (strEQ(name,"VIOC_AFS_SYSNAME")) sv_setiv(ST(0),VIOC_AFS_SYSNAME);
                else if (strEQ(name,"VIOC_EXPORTAFS")) sv_setiv(ST(0),VIOC_EXPORTAFS);
                else if (strEQ(name,"VIOC_FILE_CELL_NAME")) sv_setiv(ST(0),VIOC_FILE_CELL_NAME);
                else if (strEQ(name,"VIOC_FLUSHVOLUME")) sv_setiv(ST(0),VIOC_FLUSHVOLUME);
                else if (strEQ(name,"VIOC_GAG")) sv_setiv(ST(0),VIOC_GAG);
                else if (strEQ(name,"VIOC_GETCELLSTATUS")) sv_setiv(ST(0),VIOC_GETCELLSTATUS);
                else if (strEQ(name,"VIOC_GETSPREFS")) sv_setiv(ST(0),VIOC_GETSPREFS);
                else if (strEQ(name,"VIOC_GET_PRIMARY_CELL")) sv_setiv(ST(0),VIOC_GET_PRIMARY_CELL);
                else if (strEQ(name,"VIOC_GET_WS_CELL")) sv_setiv(ST(0),VIOC_GET_WS_CELL);
                else if (strEQ(name,"VIOC_SETCELLSTATUS")) sv_setiv(ST(0),VIOC_SETCELLSTATUS);
                else if (strEQ(name,"VIOC_SETSPREFS")) sv_setiv(ST(0),VIOC_SETSPREFS);
                else if (strEQ(name,"VIOC_TWIDDLE")) sv_setiv(ST(0),VIOC_TWIDDLE);
                else if (strEQ(name,"VIOC_VENUSLOG")) sv_setiv(ST(0),VIOC_VENUSLOG);
                else {
                     ST(0) = ST(1) = &PL_sv_undef;
                     return;
                }
                break;
                default:
                        ST(0) = ST(1) = &PL_sv_undef;
                        return;
                }
                break;
        default:
                ST(0) = ST(1) = &PL_sv_undef;
                return;
        }
        break;
  default:
        ST(0) = ST(1) = &PL_sv_undef;
        return;
  }

  errno = 0;
  XSRETURN(1);
  return;
 }

#endif
