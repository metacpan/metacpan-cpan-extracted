/***********************************************************************
 *
 * AFS.xs - AFS extensions for Perl
 *
 * RCS-Id: @(#)$Id: Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $
 *
 * Copyright (c) 2003, International Business Machines Corporation and others.
 *
 * This software has been released under the terms of the IBM Public
 * License.  For details, see the IBM-LICENSE file in the LICENCES
 * directory or online at http://www.openafs.org/dl/license10.html
 *
 * Contributors
 *         2004-2006: Elizabeth Cassell <e_a_c@mailsnare.net>
 *                    Alf Wachsmann <alfw@slac.stanford.edu>
 *
 * The code for the original library were mainly taken from the AFS
 * source distribution, which comes with this message:
 *
 *    Copyright (C) 1989-1994 Transarc Corporation - All rights reserved
 *    P_R_P_Q_# (C) COPYRIGHT IBM CORPORATION 1987, 1988, 1989
 *
 ***********************************************************************/

#include "EXTERN.h"

#ifdef __sgi    /* needed to get a clean compile */
#include <setjmp.h>
#endif

#include <stdarg.h>

#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <afs/afsint.h>

#include <afs/kautils.h>

#include <afs/xstat_fs.h>
#include <afs/xstat_cm.h>
#include "afsmon-labels.h"  /* labels for afsmonitor variables */

#include <afs/fsprobe.h>

/* from volser/volser_prototypes.h */
extern void MapPartIdIntoName(afs_int32 partId, char *partName);


#if defined(AFS_3_4) || defined(AFS_3_5)
#else
#define int32 afs_int32
#define uint32 afs_uint32
#endif

const char *const xs_version = "Monitor.xs (Major Version 0.2 $Rev: 609 $)";

extern char *error_message();
extern struct hostent *hostutil_GetHostByName();
extern char *hostutil_GetNameByINet();

/* error handling macros */

#define SETCODE(code) set_code(code)
#define FSSETCODE(code) {if (code == -1) set_code(errno); else set_code(code);}
#define BSETCODE(code, msg) bv_set_code(code, msg)
#define VSETCODE(code, msg) bv_set_code(code, msg)

static int32 raise_exception = 0;


static void
bv_set_code(code, msg)
   int32 code;
   const char *msg;
{
   SV *sv = perl_get_sv("AFS::CODE", TRUE);
   sv_setiv(sv, (IV) code);
   if (code == 0) {
      sv_setpv(sv, "");
   }
   else {
      if (raise_exception) {
         char buffer[1024];
         sprintf(buffer, "AFS exception: %s (%d)", msg, code);
         croak(buffer);
      }
      sv_setpv(sv, (char *)msg);
   }
   SvIOK_on(sv);
}

static void
set_code(code)
   int32 code;
{
   SV *sv = perl_get_sv("AFS::CODE", TRUE);
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
      sv_setpv(sv, (char *)error_message(code));
   }
   SvIOK_on(sv);
}

/* end of error handling macros */


/* start of rxdebug helper functions */


/*
 * from src/rxdebug/rxdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static short
rxdebug_PortNumber(aport)
   register char *aport;
{
   register int tc;
   register short total;

   total = 0;
   while ((tc = (*aport++))) {
      if (tc < '0' || tc > '9')
         return -1; /* bad port number */
      total *= 10;
      total += tc - (int)'0';
   }
   return htons(total);
}


/*
 * from src/rxdebug/rxdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static short
rxdebug_PortName(char *aname)
{
   register struct servent *ts;
   ts = getservbyname(aname, (char *) NULL);
   if (!ts)
      return -1;
   return ts->s_port;   /* returns it in network byte order */
}


/*
 * replaces rx_PrintTheseStats() in original c code.
 * places stats in RXSTATS instead of printing them
 * from src/rx/rx.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static void
myPrintTheseStats(HV *RXSTATS, struct rx_statistics *rxstats)
{
   HV *PACKETS;
   HV *TYPE;
   HV *TOTALRTT;
   HV *MINRTT;
   HV *MAXRTT;
   int i;
   int num_unused;

   hv_store(RXSTATS, "packetRequests", 14, newSViv(rxstats->packetRequests),
            0);

   hv_store(RXSTATS, "receivePktAllocFailures", 23,
            newSViv(rxstats->receivePktAllocFailures), 0);
   hv_store(RXSTATS, "receiveCbufPktAllocFailures", 27,
            newSViv(rxstats->receiveCbufPktAllocFailures), 0);
   hv_store(RXSTATS, "sendPktAllocFailures", 20,
            newSViv(rxstats->sendPktAllocFailures), 0);
   hv_store(RXSTATS, "sendCbufPktAllocFailures", 24,
            newSViv(rxstats->sendCbufPktAllocFailures), 0);
   hv_store(RXSTATS, "specialPktAllocFailures", 23,
            newSViv(rxstats->specialPktAllocFailures), 0);

   hv_store(RXSTATS, "socketGreedy", 12, newSViv(rxstats->socketGreedy), 0);
   hv_store(RXSTATS, "bogusPacketOnRead", 17,
            newSViv(rxstats->bogusPacketOnRead), 0);
   hv_store(RXSTATS, "bogusHost", 9, newSViv(rxstats->bogusHost), 0);
   hv_store(RXSTATS, "noPacketOnRead", 14, newSViv(rxstats->noPacketOnRead),
            0);
   hv_store(RXSTATS, "noPacketBuffersOnRead", 21,
            newSViv(rxstats->noPacketBuffersOnRead), 0);
   hv_store(RXSTATS, "selects", 7, newSViv(rxstats->selects), 0);
   hv_store(RXSTATS, "sendSelects", 11, newSViv(rxstats->sendSelects), 0);


   PACKETS = newHV();
   num_unused = 0;

   for (i = 0; i < RX_N_PACKET_TYPES; i++) {
      char *packet_type = rx_packetTypes[i];
      TYPE = newHV();
      hv_store(TYPE, "packetsRead", 11, newSViv(rxstats->packetsRead[i]), 0);
      hv_store(TYPE, "packetsSent", 11, newSViv(rxstats->packetsSent[i]), 0);
      if (packet_type == "unused") {
         /* rename "unused" types */
         /* can't have several entries in a hash with same name */
         char packet_type_unused[7];
         sprintf(packet_type_unused, "unused%d", num_unused);
         packet_type = packet_type_unused;
         num_unused++;
      }
      hv_store(PACKETS, packet_type, strlen(packet_type),
               newRV_inc((SV *) (TYPE)), 0);
   }
   hv_store(RXSTATS, "packets", 7, newRV_inc((SV *) (PACKETS)), 0);

   hv_store(RXSTATS, "dataPacketsRead", 15, newSViv(rxstats->dataPacketsRead),
            0);
   hv_store(RXSTATS, "ackPacketsRead", 14, newSViv(rxstats->ackPacketsRead),
            0);
   hv_store(RXSTATS, "dupPacketsRead", 14, newSViv(rxstats->dupPacketsRead),
            0);
   hv_store(RXSTATS, "spuriousPacketsRead", 19,
            newSViv(rxstats->spuriousPacketsRead), 0);
   hv_store(RXSTATS, "ignorePacketDally", 17,
            newSViv(rxstats->ignorePacketDally), 0);

   hv_store(RXSTATS, "pingPacketsSent", 15, newSViv(rxstats->pingPacketsSent),
            0);
   hv_store(RXSTATS, "abortPacketsSent", 16,
            newSViv(rxstats->abortPacketsSent), 0);
   hv_store(RXSTATS, "busyPacketsSent", 15, newSViv(rxstats->busyPacketsSent),
            0);

   hv_store(RXSTATS, "ackPacketsSent", 14, newSViv(rxstats->ackPacketsSent),
            0);
   hv_store(RXSTATS, "dataPacketsSent", 15, newSViv(rxstats->dataPacketsSent),
            0);
   hv_store(RXSTATS, "dataPacketsReSent", 17,
            newSViv(rxstats->dataPacketsReSent), 0);
   hv_store(RXSTATS, "dataPacketsPushed", 17,
            newSViv(rxstats->dataPacketsPushed), 0);
   hv_store(RXSTATS, "ignoreAckedPacket", 17,
            newSViv(rxstats->ignoreAckedPacket), 0);

   hv_store(RXSTATS, "netSendFailures", 15, newSViv(rxstats->netSendFailures),
            0);
   hv_store(RXSTATS, "fatalErrors", 11, newSViv(rxstats->fatalErrors), 0);

   hv_store(RXSTATS, "nServerConns", 12, newSViv(rxstats->nServerConns), 0);
   hv_store(RXSTATS, "nClientConns", 12, newSViv(rxstats->nClientConns), 0);
   hv_store(RXSTATS, "nPeerStructs", 12, newSViv(rxstats->nPeerStructs), 0);
   hv_store(RXSTATS, "nCallStructs", 12, newSViv(rxstats->nCallStructs), 0);
   hv_store(RXSTATS, "nFreeCallStructs", 16,
            newSViv(rxstats->nFreeCallStructs), 0);

   hv_store(RXSTATS, "nRttSamples", 11, newSViv(rxstats->nRttSamples), 0);

   TOTALRTT = newHV();
   hv_store(TOTALRTT, "sec", 3, newSViv(rxstats->totalRtt.sec), 0);
   hv_store(TOTALRTT, "usec", 4, newSViv(rxstats->totalRtt.usec), 0);
   hv_store(RXSTATS, "totalRtt", 8, newRV_inc((SV *) (TOTALRTT)), 0);
   MINRTT = newHV();
   hv_store(MINRTT, "sec", 3, newSViv(rxstats->minRtt.sec), 0);
   hv_store(MINRTT, "usec", 4, newSViv(rxstats->minRtt.usec), 0);
   hv_store(RXSTATS, "minRtt", 6, newRV_inc((SV *) (MINRTT)), 0);
   MAXRTT = newHV();
   hv_store(MAXRTT, "sec", 3, newSViv(rxstats->maxRtt.sec), 0);
   hv_store(MAXRTT, "usec", 4, newSViv(rxstats->maxRtt.usec), 0);
   hv_store(RXSTATS, "maxRtt", 6, newRV_inc((SV *) (MAXRTT)), 0);

#if !defined(AFS_PTHREAD_ENV) && !defined(AFS_USE_GETTIMEOFDAY)
   hv_store(RXSTATS, "clock_nUpdates", 14, newSViv(clock_nUpdates), 0);
#endif
}

/* end of rxdebug helper functions */





/* start of afsmonitor helper functions */

/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

#define FS 1    /* for misc. use */
#define CM 2    /* for misc. use */
#define CFG_STR_LEN 80  /* max length of config file fields */
#define NUM_XSTAT_FS_AFS_PERFSTATS_LONGS 66 /* number of fields (longs)
                                             * in struct afs_PerfStats */
#define NUM_AFS_STATS_CMPERF_LONGS 40   /* number of longs in struct afs_stats_CMPerf
                                         * excluding up/down stats and fields we dont display */


/*
 * from src/afsmonitor/afsmonitor.h
 *
 */

#define HOST_NAME_LEN 80    /* length of server/cm names */
#define THRESH_VAR_NAME_LEN 80  /* THRESHOLD STRUCTURE DEFINITIONS */
#define THRESH_VAR_LEN 16
#define NUM_FS_STAT_ENTRIES 271 /* number of file server statistics
                                 * entries to display */
#define FS_STAT_STRING_LEN 14   /* max length of each string above */
#define NUM_CM_STAT_ENTRIES 571 /* number of cache manager statistics
                                 * entries to display */
#define CM_STAT_STRING_LEN 14   /* max length of each string above */

#define FS_NUM_DATA_CATEGORIES 9    /* # of fs categories */
#define CM_NUM_DATA_CATEGORIES 16   /* # of cm categories */


/*
 * from src/xstat/xstat_fs.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 *

/*
 * We have to pass a port to Rx to start up our callback listener
 * service, but 7001 is already taken up by the Cache Manager.  So,
 * we make up our own.
 */
#define XSTAT_FS_CBPORT 7101


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static char *fsOpNames[] = {
   "FetchData",
   "FetchACL",
   "FetchStatus",
   "StoreData",
   "StoreACL",
   "StoreStatus",
   "RemoveFile",
   "CreateFile",
   "Rename",
   "Symlink",
   "Link",
   "MakeDir",
   "RemoveDir",
   "SetLock",
   "ExtendLock",
   "ReleaseLock",
   "GetStatistics",
   "GiveUpCallbacks",
   "GetVolumeInfo",
   "GetVolumeStatus",
   "SetVolumeStatus",
   "GetRootVolume",
   "CheckToken",
   "GetTime",
   "NGetVolumeInfo",
   "BulkStatus",
   "XStatsVersion",
   "GetXStats",
   "XLookup"	/* from xstat/xstat_cm_test.c */
};


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static char *cmOpNames[] = {
   "CallBack",
   "InitCallBackState",
   "Probe",
   "GetLock",
   "GetCE",
   "XStatsVersion",
   "GetXStats"
};


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static char *xferOpNames[] = {
   "FetchData",
   "StoreData"
};


/*
 * from src/afsmonitor/afsmonitor.h
 *
 */

/* structure of each threshold item */
struct Threshold {
   char itemName[THRESH_VAR_NAME_LEN];  /* field name */
   int index;                   /* positional index */
   char threshVal[THRESH_VAR_LEN];  /* user provided threshold value */
   char handler[256];           /* user provided ovf handler */
};


/*
 * from src/afsmonitor/afsmonitor.h
 *
 */

/* structures to store info of hosts to be monitored */
struct afsmon_hostEntry {
   char hostName[HOST_NAME_LEN];    /* fs or cm host name */
   int numThresh;               /* number of thresholds for this host */
   struct Threshold *thresh;    /* ptr to threshold entries */
   struct afsmon_hostEntry *next;
};


/*
 * from src/afsmonitor/afsmonitor.h
 *
 */

/* structures to store statistics in a format convenient to dump to the
screen */
/* for file servers */
struct fs_Display_Data {
   char hostName[HOST_NAME_LEN];
   int probeOK;                 /* 0 => probe failed */
   char data[NUM_FS_STAT_ENTRIES][FS_STAT_STRING_LEN];
   short threshOvf[NUM_FS_STAT_ENTRIES];    /* overflow flags */
   int ovfCount;                /* overflow count */
};
/* for cache managers */
struct cm_Display_Data {
   char hostName[HOST_NAME_LEN];
   int probeOK;                 /* 0 => probe failed */
   char data[NUM_CM_STAT_ENTRIES][CM_STAT_STRING_LEN];
   short threshOvf[NUM_CM_STAT_ENTRIES];    /* overflow flags */
   int ovfCount;                /* overflow count */
};



/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

/* wouldn't compile without this, but it wasn't in original afsmonitor.c */
#if !defined(__USE_GNU) && !defined(__APPLE_CC__)
char *
strcasestr(char *s1, char *s2)
{
   char *ptr;
   int len1, len2;

   len1 = strlen(s1);
   len2 = strlen(s2);

   if (len1 < len2)
      return ((char *)NULL);

   ptr = s1;

   while (len1 >= len2 && len1 > 0) {
      if ((strncasecmp(ptr, s2, len2)) == 0)
         return (ptr);
      ptr++;
      len1--;
   }
   return ((char *)NULL);
}
#endif           /* __USE_GNU */


/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

struct hostent *
GetHostByName(char *name)
{
   struct hostent *he;
#ifdef AFS_SUN5_ENV
   char ip_addr[32];
#endif

   he = gethostbyname(name);
#ifdef AFS_SUN5_ENV
   /* On solaris the above does not resolve hostnames to full names */
   if (he != NULL) {
      memcpy(ip_addr, he->h_addr, he->h_length);
      he = gethostbyaddr(ip_addr, he->h_length, he->h_addrtype);
   }
#endif
   return (he);
}


/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

/*
 * Constructs a string to pass back to Perl for easy execution of the threshold handler.
 * DOES NOT execute the threshold handler.
 *
 * from src/afsmonitor/afsmonitor.c
 *
 * int
 * execute_thresh_handler(a_handler, a_hostName, a_hostType,
 *                         a_threshName,a_threshValue, a_actValue)
 * char *a_handler;
 * char *a_hostName;
 * int a_hostType;
 * char *a_threshName;
 * char *a_threshValue;
 * char *a_actValue;
 */

int
my_execute_thresh_handler(a_handler, a_hostName, a_hostType, a_threshName,
                          a_threshValue, a_actValue,
                          ENTRY, buffer)
   char *a_handler;             /* ptr to handler function + args */
   char *a_hostName;            /* host name for which threshold crossed */
   int a_hostType;              /* fs or cm ? */
   char *a_threshName;          /* threshold variable name */
   char *a_threshValue;         /* threshold value */
   char *a_actValue;            /* actual value */
   HV *ENTRY;
   char *buffer;
{
   char fileName[256];          /* file name to execute */
   int i;
   char *ch;
   int argNum;
   int anotherArg;              /* boolean used to flag if another arg is available */
   char args[20 * 256] = "";
   char fsHandler_args[20][256];


   /* get the filename to execute - the first argument */
   sscanf(a_handler, "%s", fileName);

   /* construct the contents of *argv[] */

   strncpy(fsHandler_args[0], fileName, 256);
   strncpy(fsHandler_args[1], a_hostName, HOST_NAME_LEN);
   if (a_hostType == FS)
      strcpy(fsHandler_args[2], "fs");
   else
      strcpy(fsHandler_args[2], "cm");
   strncpy(fsHandler_args[3], a_threshName, THRESH_VAR_NAME_LEN);
   strncpy(fsHandler_args[4], a_threshValue, THRESH_VAR_LEN);
   strncpy(fsHandler_args[5], a_actValue, THRESH_VAR_LEN);


   argNum = 6;
   anotherArg = 1;
   ch = a_handler;

   /* we have already extracted the file name so skip to the 1st arg */
   while (isspace(*ch)) /* leading blanks */
      ch++;
   while (!isspace(*ch) && *ch != '\0') /* handler filename */
      ch++;

   while (*ch != '\0') {
      if (isspace(*ch)) {
         anotherArg = 1;
      }
      else if (anotherArg) {
         anotherArg = 0;
         sscanf(ch, "%s", fsHandler_args[argNum]);
         argNum++;
      }
      ch++;
      if (argNum >= 20) {
         sprintf(buffer,
                 "Threshold handlers cannot have more than 20 arguments (55)");
         return (55);
      }

   }

   strcpy(args, fsHandler_args[0]);

   for (i = 1; i < argNum; i++) {
      strcat(args, " ");
      strcat(args, fsHandler_args[i]);
   }

   hv_store(ENTRY, "overflow", 8, newSVpv(args, 0), 0);

   return (0);
}   /* my_execute_thresh_handler() */


/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_insert_FS(a_hostName, nameList, last_hostEntry)
   char *a_hostName;            /* name of file server to be inserted in list */
   struct afsmon_hostEntry **nameList;
   struct afsmon_hostEntry **last_hostEntry;
{
   static struct afsmon_hostEntry *curr_item;
   static struct afsmon_hostEntry *prev_item;

   if (*a_hostName == '\0')
      return (-1);
   curr_item = (struct afsmon_hostEntry *)
      malloc(sizeof(struct afsmon_hostEntry));
   if (curr_item == (struct afsmon_hostEntry *) NULL) {
      warn("Failed to allocate space for nameList\n");
      return (-1);
   }

   strncpy(curr_item->hostName, a_hostName, CFG_STR_LEN);
   curr_item->next = (struct afsmon_hostEntry *) NULL;
   curr_item->numThresh = 0;
   curr_item->thresh = (struct Threshold *) NULL;

   if ((*nameList) == (struct afsmon_hostEntry *) NULL)
      (*nameList) = curr_item;
   else
      prev_item->next = curr_item;

   prev_item = curr_item;
   /*  record the address of this entry so that its threshold */
   /* count can be incremented during  the first pass of the config file */
   (*last_hostEntry) = curr_item;

   return (0);
}   /* my_insert_FS() */



/* my_insert_CM() */

/*
 * from src/afsmonitor/afsmonitor.c:
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_insert_CM(a_hostName, nameList, last_hostEntry)
   char *a_hostName;            /* name of cache manager to be inserted in list */
   struct afsmon_hostEntry **nameList;
   struct afsmon_hostEntry **last_hostEntry;
{
   static struct afsmon_hostEntry *curr_item;
   static struct afsmon_hostEntry *prev_item;

   if (*a_hostName == '\0')
      return (-1);

   curr_item = (struct afsmon_hostEntry *)
      malloc(sizeof(struct afsmon_hostEntry));
   if (curr_item == (struct afsmon_hostEntry *) NULL) {
      warn("Failed to allocate space for nameList\n");
      return (-1);
   }

   strncpy(curr_item->hostName, a_hostName, CFG_STR_LEN);
   curr_item->next = (struct afsmon_hostEntry *) NULL;
   curr_item->numThresh = 0;
   curr_item->thresh = NULL;

   if ((*nameList) == (struct afsmon_hostEntry *) NULL) {
      (*nameList) = curr_item;
   }
   else {
      prev_item->next = curr_item;
   }

   prev_item = curr_item;
   /*  record the address of this entry so that its threshold */
   /* count can be incremented during  the first pass of the config file */
   (*last_hostEntry) = curr_item;

   return (0);
}   /* my_insert_CM() */



/*
 * parses a threshold entry line in the config file.
 *
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_parse_threshEntry(a_line, global_fsThreshCount, global_cmThreshCount,
                     last_hostEntry, lastHostType, buffer)
   char *a_line;                /* line that is being parsed */
   int *global_fsThreshCount;   /* count of global file server thresholds */
   int *global_cmThreshCount;   /* count of global cache manager thresholds */
   struct afsmon_hostEntry *last_hostEntry; /* a pointer to the last host entry */
   int lastHostType;            /* points to an integer specifying whether the last host was fs or cm */
   char *buffer;                /* to return error messages in */
{
   char opcode[CFG_STR_LEN];    /* junk characters */
   char arg1[CFG_STR_LEN];      /* hostname or qualifier (fs/cm?)  */
   char arg2[CFG_STR_LEN];      /* threshold variable */
   char arg3[CFG_STR_LEN];      /* threshold value */
   char arg4[CFG_STR_LEN];      /* user's handler  */
   char arg5[CFG_STR_LEN];      /* junk characters */


   /* break it up */
   opcode[0] = 0;
   arg1[0] = 0;
   arg2[0] = 0;
   arg3[0] = 0;
   arg4[0] = 0;
   arg5[0] = 0;
   sscanf(a_line, "%s %s %s %s %s %s", opcode, arg1, arg2, arg3, arg4, arg5);

   /* syntax is "thresh fs/cm variable_name threshold_value [handler] " */
   if (((strlen(arg1)) == 0) || ((strlen(arg2)) == 0)
       || ((strlen(arg3)) == 0)) {
      sprintf(buffer, "Incomplete line");
      return (-1);
   }
   if (strlen(arg3) > THRESH_VAR_LEN - 2) {
      sprintf(buffer, "threshold value too long");
      return (-1);
   }

   if ((strcasecmp(arg1, "fs")) == 0) {
      switch (lastHostType) {
        case 0:    /* its a global threshold */
           (*global_fsThreshCount)++;
           break;
        case 1:    /* inc thresh count of last file server */
           last_hostEntry->numThresh++;
           break;
        case 2:
           sprintf(buffer,
                   "A threshold for a File Server cannot be placed after a Cache Manager host entry in the config file");
           return (-1);
        default:
           sprintf(buffer, "Programming error 1");
           return (-1);
      }
   }
   else if ((strcasecmp(arg1, "cm")) == 0) {
      switch (lastHostType) {
        case 0:    /* its a global threshold */
           (*global_cmThreshCount)++;
           break;
        case 2:    /* inc thresh count of last cache manager */
           last_hostEntry->numThresh++;
           break;
        case 1:
           sprintf(buffer,
                   "A threshold for a Cache Manager cannot be placed after a File Server host entry in the config file");
           return (-1);
        default:
           sprintf(buffer, "Programming error 2");
           return (-1);
      }
   }
   else {
      sprintf(buffer,
              "Syntax error. Second argument should be \"fs\" or \"cm\"");
      return (-1);
   }

   return (0);
}   /* my_parse_threshEntry() */



/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_parse_showEntry(a_line, fs_showDefault, cm_showDefault, fs_showFlags,
                   cm_showFlags, buffer)
   char *a_line;
   int *fs_showDefault;
   int *cm_showDefault;
   short *fs_showFlags;
   short *cm_showFlags;
   char *buffer;
{

   char opcode[CFG_STR_LEN];    /* specifies type of config entry */
   char arg1[CFG_STR_LEN];      /* show fs or cm entry ? */
   char arg2[CFG_STR_LEN];      /* what we gotta show  */
   char arg3[CFG_STR_LEN];      /* junk */
   char catName[CFG_STR_LEN];   /* for category names */
   int numGroups = 0;           /* number of groups in a section */
   int fromIdx = 0;
   int toIdx = 0;
   int found = 0;
   int idx = 0;                 /* index to fs_categories[] */
   int i = 0;
   int j = 0;

   extern char *fs_varNames[];
   extern char *cm_varNames[];
   extern char *fs_categories[];    /* file server data category names */
   extern char *cm_categories[];    /* cache manager data category names */

   opcode[0] = 0;
   arg1[0] = 0;
   arg2[0] = 0;
   arg3[0] = 0;
   sscanf(a_line, "%s %s %s %s", opcode, arg1, arg2, arg3);

   if (arg3[0] != '\0') {
      sprintf(buffer, "Extraneous characters at end of line");
      return (-1);
   }

   if ((strcasecmp(arg1, "fs") != 0) && (strcasecmp(arg1, "cm") != 0)) {
      sprintf(buffer,
              "Second argument of \"show\" directive should be \"fs\" or \"cm\"");
      return (-1);
   }

   /* Each entry can either be a variable name or a section/group name. Variable
    * names are listed in xx_varNames[] and section/group names in xx_categories[].
    * The section/group names in xx_categiries[] also give the starting/ending
    * indices of the variables belonging to that section/group. These indices
    * are stored in order in xx_Display_map[] and displayed to the screen in that
    * order. */

   /* To handle duplicate "show" entries we keep track of what what we have
    * already marked to show in the xx_showFlags[] */

   if (strcasecmp(arg1, "fs") == 0) {   /* its a File Server entry */
      /* mark that we have to show only what the user wants */
      *fs_showDefault = 0;

      /* if it is a section/group name, find it in the fs_categories[] array */

      found = 0;
      if (strcasestr(arg2, "_section") != (char *)NULL
          || strcasestr(arg2, "_group") != (char *)NULL) {
         idx = 0;
         while (idx < FS_NUM_DATA_CATEGORIES) {
            sscanf(fs_categories[idx], "%s %d %d", catName, &fromIdx, &toIdx);
            idx++;
            if (strcasecmp(arg2, catName) == 0) {
               found = 1;
               break;
            }
         }

         if (!found) {  /* typo in section/group name */
            sprintf(buffer, "Could not find section/group name %s", arg2);
            return (-1);
         }
      }

        /* if it is a group name, read its start/end indices and fill in the
         * fs_Display_map[]. */

      if (strcasestr(arg2, "_group") != (char *)NULL) {

         if (fromIdx < 0 || toIdx < 0 || fromIdx > NUM_FS_STAT_ENTRIES ||
             toIdx > NUM_FS_STAT_ENTRIES)
            return (-2);
         for (j = fromIdx; j <= toIdx; j++) {
            fs_showFlags[j] = 1;
         }
      }

      /* if it is a section name */
      else if (strcasestr(arg2, "_section") != (char *)NULL) {
         /* fromIdx is actually the number of groups in this section */
         numGroups = fromIdx;
         /* for each group in section */
         while (idx < FS_NUM_DATA_CATEGORIES && numGroups) {
            sscanf(fs_categories[idx], "%s %d %d", catName, &fromIdx, &toIdx);

            if (strcasestr(catName, "_group") != (char *) NULL) {
               if (fromIdx < 0 || toIdx < 0 || fromIdx > NUM_FS_STAT_ENTRIES
                   || toIdx > NUM_FS_STAT_ENTRIES)
                  return (-4);
               for (j = fromIdx; j <= toIdx; j++) {
                  fs_showFlags[j] = 1;
               }
            }
            else {
               sprintf(buffer, "Error parsing groups for %s", arg2);
               return (-6);
            }
            idx++;
            numGroups--;
         }  /* for each group in section */

      }
      else {    /* it is a variable name */

         for (i = 0; i < NUM_FS_STAT_ENTRIES; i++) {
            if (strcasecmp(arg2, fs_varNames[i]) == 0) {
               fs_showFlags[i] = 1;
               found = 1;
               break;
            }
         }
         if (!found) {  /* typo in variable name */
            sprintf(buffer, "Could not find variable name %s", arg2);
            return (-1);
         }
      } /* its a variable name */

   }

    /* it is an fs entry */
   if (strcasecmp(arg1, "cm") == 0) {   /* its a Cache Manager entry */

      /* mark that we have to show only what the user wants */
      *cm_showDefault = 0;

      /* if it is a section/group name, find it in the cm_categories[] array */

      found = 0;
      if (strcasestr(arg2, "_section") != (char *)NULL
          || strcasestr(arg2, "_group") != (char *)NULL) {
         idx = 0;
         while (idx < CM_NUM_DATA_CATEGORIES) {
            sscanf(cm_categories[idx], "%s %d %d", catName, &fromIdx, &toIdx);
            idx++;
            if (strcasecmp(arg2, catName) == 0) {
               found = 1;
               break;
            }
         }

         if (!found) {  /* typo in section/group name */
            sprintf(buffer, "Could not find section/group name %s", arg2);
            return (-1);
         }
      }

      /* if it is a group name */

      if (strcasestr(arg2, "_group") != (char *)NULL) {

         if (fromIdx < 0 || toIdx < 0 || fromIdx > NUM_CM_STAT_ENTRIES
             || toIdx > NUM_CM_STAT_ENTRIES)
            return (-10);
         for (j = fromIdx; j <= toIdx; j++) {
            cm_showFlags[j] = 1;
         }
      }

      /* if it is a section name, get the count of number of groups in it and
       * for each group fill in the start/end indices in the cm_Display_map[] */

      else if (strcasestr(arg2, "_section") != (char *)NULL) {
         /* fromIdx is actually the number of groups in thi section */
         numGroups = fromIdx;
         /* for each group in section */
         while (idx < CM_NUM_DATA_CATEGORIES && numGroups) {
            sscanf(cm_categories[idx], "%s %d %d", catName, &fromIdx, &toIdx);

            if (strcasestr(catName, "_group") != (char *) NULL) {
               if (fromIdx < 0 || toIdx < 0 || fromIdx > NUM_CM_STAT_ENTRIES
                   || toIdx > NUM_CM_STAT_ENTRIES)
                  return (-12);
               for (j = fromIdx; j <= toIdx; j++) {
                  cm_showFlags[j] = 1;
               }
            }
            else {
               sprintf(buffer, "Error parsing groups for %s", arg2);
               return (-15);
            }
            idx++;
            numGroups--;
         }  /* for each group in section */
      }
      else {    /* it is a variable name */

         for (i = 0; i < NUM_CM_STAT_ENTRIES; i++) {
            if (strcasecmp(arg2, cm_varNames[i]) == 0) {
               cm_showFlags[i] = 1;
               found = 1;
               break;
            }
         }
         if (!found) {  /* typo in section/group name */
            sprintf(buffer, "Could not find variable name %s", arg2);
            return (-1);
         }
      } /* its a variable name */

   }    /* it is a cm entry */

   return (0);

}   /* my_parse_showEntry() */



/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_parse_hostEntry(a_line, numFS, numCM, lastHostType, last_hostEntry,
                   FSnameList, CMnameList, buffer)
   char *a_line;
   int *numFS;
   int *numCM;
   int *lastHostType;
   struct afsmon_hostEntry **last_hostEntry;
   struct afsmon_hostEntry **FSnameList;
   struct afsmon_hostEntry **CMnameList;
   char *buffer;
{
   char opcode[CFG_STR_LEN];
   char arg1[CFG_STR_LEN];
   char arg2[CFG_STR_LEN];
   struct hostent *he = 0;
   int code = 0;

   opcode[0] = 0;
   arg1[0] = 0;
   arg2[0] = 0;

   sscanf(a_line, "%s %s %s", opcode, arg1, arg2);
   if ((strlen(arg2)) != 0) {
      sprintf(buffer, "Extraneous characters at end of line");
      return (-1);
   }

   he = GetHostByName(arg1);
   if (he == NULL) {
      sprintf(buffer, "Unable to resolve hostname %s", arg1);
      return (-1);
   }

   if ((strcasecmp(opcode, "fs")) == 0) {
      /* use the complete host name to insert in the file server names list */
      code = my_insert_FS(he->h_name, FSnameList, last_hostEntry);
      if (code) {
         return (-1);
      }
      /* note that last host entry in the config file was fs */
      (*lastHostType) = 1;
      (*numFS)++;
   }
   else if ((strcasecmp(opcode, "cm")) == 0) {
      /* use the complete host name to insert in the CM names list */
      code = my_insert_CM(he->h_name, CMnameList, last_hostEntry);
      if (code)
         return (-1);
      /* last host entry in the config file was cm */
      (*lastHostType) = 2;
      (*numCM)++;
   }
   else {
      return (-1);
   }

   return (0);
}   /* my_parse_hostEntry() */



/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_store_threshold(a_type, a_varName, a_value, a_handler, global_TC,
                   Header, hostname, srvCount, buffer)
   int a_type;                  /* 1 = fs , 2 = cm */
   char *a_varName;             /* threshold name */
   char *a_value;               /* threshold value */
   char *a_handler;             /* threshold overflow handler */
   int *global_TC;              /* ptr to global_xxThreshCount */
   struct afsmon_hostEntry *Header; /* tmp ptr to hostEntry list header */
   char *hostname;
   int srvCount;                /* tmp count of host names */
   char *buffer;
{

   struct afsmon_hostEntry *tmp_host = 0;   /* tmp ptr to hostEntry */
   struct Threshold *threshP = 0;   /* tmp ptr to threshold list */
   int index = 0;               /* index to fs_varNames or cm_varNames */
   int found = 0;
   int done = 0;
   int i = 0, j = 0;

   /* resolve the threshold variable name */
   found = 0;
   if (a_type == FS) {  /* fs threshold */
      for (index = 0; index < NUM_FS_STAT_ENTRIES; index++) {
         if (strcasecmp(a_varName, fs_varNames[index]) == 0) {
            found = 1;
            break;
         }
      }
      if (!found) {
         sprintf(buffer, "Unknown FS threshold variable name %s", a_varName);
         return (-1);
      }
   }
   else if (a_type == CM) { /* cm threshold */
      for (index = 0; index < NUM_CM_STAT_ENTRIES; index++) {
         if (strcasecmp(a_varName, cm_varNames[index]) == 0) {
            found = 1;
            break;
         }
      }
      if (!found) {
         sprintf(buffer, "Unknown CM threshold variable name %s", a_varName);
         return (-1);
      }
   }
   else
      return (-1);

   /* if the global thresh count is not zero, place this threshold on
    * all the host entries  */

   if (*global_TC) {
      tmp_host = Header;
      for (i = 0; i < srvCount; i++) {
         threshP = tmp_host->thresh;
         done = 0;
         for (j = 0; j < tmp_host->numThresh; j++) {
            if ((threshP->itemName[0] == '\0') ||
                (strcasecmp(threshP->itemName, a_varName) == 0)) {
               strncpy(threshP->itemName, a_varName, THRESH_VAR_NAME_LEN);
               strncpy(threshP->threshVal, a_value, THRESH_VAR_LEN);
               strcpy(threshP->handler, a_handler);
               threshP->index = index;
               done = 1;
               break;
            }
            threshP++;
         }
         if (!done) {
            sprintf(buffer,
                    "Could not insert threshold entry for %s in thresh list of host %s",
                    a_varName, tmp_host->hostName);
            return (-1);
         }
         tmp_host = tmp_host->next;
      }
      (*global_TC)--;
      return (0);
   }

   /* it is not a global threshold, insert it in the thresh list of this
    * host only. We overwrite the global threshold if it was already set */

   if (*hostname == '\0') {
      sprintf(buffer, "Programming error 3");
      return (-1);
   }

   /* get the hostEntry that this threshold belongs to */
   tmp_host = Header;
   found = 0;
   for (i = 0; i < srvCount; i++) {
      if (strcasecmp(tmp_host->hostName, hostname) == 0) {
         found = 1;
         break;
      }
      tmp_host = tmp_host->next;
   }
   if (!found) {
      sprintf(buffer, "Unable to find host %s in %s hostEntry list", hostname,
              (a_type - 1) ? "CM" : "FS");
      return (-1);
   }

   /* put this entry on the thresh list of this host, overwrite global value
    * if needed */

   threshP = tmp_host->thresh;
   done = 0;
   for (i = 0; i < tmp_host->numThresh; i++) {
      if ((threshP->itemName[0] == '\0') ||
          (strcasecmp(threshP->itemName, a_varName) == 0)) {
         strncpy(threshP->itemName, a_varName, THRESH_VAR_NAME_LEN);
         strncpy(threshP->threshVal, a_value, THRESH_VAR_LEN);
         strcpy(threshP->handler, a_handler);
         threshP->index = index;
         done = 1;
         break;
      }
      threshP++;
   }

   if (!done) {
      sprintf(buffer, "Unable to insert threshold %s for %s host %s",
              a_varName, (a_type - 1) ? "CM" : "FS", tmp_host->hostName);
      return (-1);
   }

   return (0);

}   /* my_store_threshold() */



/*
 * from /src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 *
 * int
 * check_fs_thresholds(a_hostEntry, a_Data)
 * struct afsmon_hostEntry *a_hostEntry;
 * struct fs_Display_Data *a_Data;
 *
 * and
 *
 * int
 * check_cm_thresholds(a_hostEntry, a_Data)
 * struct afsmon_hostEntry *a_hostEntry;
 * struct cm_Display_Data *a_Data;
 */

int
my_check_thresholds(a_hostEntry, HOSTINFO, type, buffer)
   struct afsmon_hostEntry *a_hostEntry;    /* ptr to hostEntry */
   HV *HOSTINFO;                /* ptr to data to be displayed */
   int type;
   char *buffer;
{

   struct Threshold *threshP;
   double tValue = 0;           /* threshold value */
   double pValue = 0;           /* probe value */
   int i;
   int idx;
   int count;                   /* number of thresholds exceeded */
   HV *SECTION;
   HV *GROUP;
   HV *VALUE;
   int found;
   char *key;
   I32 keylen;
   char strval[256];
   int code = 0;
   char *varName;

   if (a_hostEntry->numThresh == 0) {
      /* store in ovf count ?? */
      return (0);
   }

   count = 0;
   threshP = a_hostEntry->thresh;
   for (i = 0; i < a_hostEntry->numThresh; i++) {
      found = 0;

      if (threshP->itemName[0] == '\0') {
         threshP++;
         continue;
      }

      idx = threshP->index; /* positional index to the data array */
      tValue = atof(threshP->threshVal);    /* threshold value */
      hv_iterinit(HOSTINFO);


      while ((SECTION = (HV *) hv_iternextsv(HOSTINFO, &key, &keylen))) {

         if (!SvROK(SECTION)
             || SvTYPE(SECTION = (HV *) SvRV(SECTION)) != SVt_PVHV) {
            continue;
         }
         hv_iterinit(SECTION);

         while ((GROUP = (HV *) hv_iternextsv(SECTION, &key, &keylen))) {
            if (!SvROK(GROUP)
                || SvTYPE(GROUP = (HV *) SvRV(GROUP)) != SVt_PVHV) {
               continue;
            }
            if (type == FS)
               varName = fs_varNames[idx];
            else if (type == CM)
               varName = cm_varNames[idx];
            else
               return (-1);

            if (hv_exists(GROUP, varName, strlen(varName))) {
               VALUE = (HV *)
                  SvRV(*hv_fetch(GROUP, varName, strlen(varName), FALSE));
               pValue = SvIV(*hv_fetch(VALUE, "value", 5, FALSE));
               found = 1;
               break;
            }
         }
         if (found)
            break;
      }

      if (!found) {
         threshP++;
         continue;
      }

      if (pValue > tValue) {
         hv_store(VALUE, "overflow", 8, newSViv(1), 0);
         hv_store(VALUE, "threshold", 9, newSVnv(tValue), 0);

         if (threshP->handler[0] != '\0') {
            sprintf(strval, "%g", pValue);
            code = my_execute_thresh_handler(threshP->handler,
                                             a_hostEntry->hostName, type,
                                             threshP->itemName,
                                             threshP->threshVal, strval,
                                             VALUE, buffer);
            if (code) {
               return (code);
            }
         }

         count++;
      }
      threshP++;
   }

   return (0);
}   /* my_check_thresholds() */




/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_process_config_file(a_config_filename, numFS, numCM, lastHostType,
                       last_hostEntry, fs_showDefault, cm_showDefault,
                       fs_showFlags, cm_showFlags, FSnameList, CMnameList)
   char *a_config_filename;
   int *numFS;
   int *numCM;
   int *lastHostType;
   struct afsmon_hostEntry **last_hostEntry;
   int *fs_showDefault;
   int *cm_showDefault;
   short *fs_showFlags;
   short *cm_showFlags;
   struct afsmon_hostEntry **FSnameList;
   struct afsmon_hostEntry **CMnameList;
{
   char buff1[256] = "";        /* for error messages */
   char buff2[256] = "";        /* for error messages returned from subroutines */
   FILE *configFD = 0;          /* config file descriptor */
   char line[4 * CFG_STR_LEN];  /* a line of config file */
   char opcode[CFG_STR_LEN];    /* specifies type of config entry */
   char arg1[CFG_STR_LEN];      /* hostname or qualifier (fs/cm?)  */
   char arg2[CFG_STR_LEN];      /* threshold variable */
   char arg3[CFG_STR_LEN];      /* threshold value */
   char arg4[CFG_STR_LEN];      /* user's handler  */
   struct afsmon_hostEntry *curr_host = 0;
   struct hostent *he = 0;      /* hostentry to resolve host name */
   char *handlerPtr = 0;        /* ptr to pass theresh handler string */
   int code = 0;                /* error code */
   int linenum = 0;             /* config file line number */
   int threshCount = 0;         /* count of thresholds for each server */
   int error_in_config = 0;     /* syntax errors in config file  ?? */
   int i = 0;
   int numBytes = 0;
   /* int global_ThreshFlag = 1; */
   int global_fsThreshCount = 0;
   int global_cmThreshCount = 0;
   static char last_fsHost[HOST_NAME_LEN];
   static char last_cmHost[HOST_NAME_LEN];

   /* open config file */
   configFD = fopen(a_config_filename, "r");
   if (configFD == (FILE *) NULL) {
      sprintf(buff1, "Failed to open config file %s", a_config_filename);
      BSETCODE(5, buff1);
      return (-1);
   }

   /* parse config file */

   /* First Pass - check syntax and count number of servers and thresholds to monitor */

   *numFS = 0;
   *numCM = 0;
   threshCount = 0;
   error_in_config = 0; /* flag to note if config file has syntax errors */

   while ((fgets(line, CFG_STR_LEN, configFD)) != NULL) {
      opcode[0] = 0;
      arg1[0] = 0;
      arg2[0] = 0;
      arg3[0] = 0;
      arg4[0] = 0;
      sscanf(line, "%s %s %s %s %s", opcode, arg1, arg2, arg3, arg4);
      linenum++;
      /* fprintf(STDERR, "Got line %d: \"%s %s %s %s %s\"\n",
       * linenum, opcode, arg1, arg2, arg3, arg4); */
      /* skip blank lines and comment lines */
      if ((strlen(opcode) == 0) || line[0] == '#') {
         /* fprintf(STDERR, " - skipping line %d\n", linenum); */
         continue;
      }
      if ((strcasecmp(opcode, "fs") == 0) || (strcasecmp(opcode, "cm")) == 0) {
         /* fprintf(STDERR, " - parsing host entry\n"); */
         code =
            my_parse_hostEntry(line, numFS, numCM, lastHostType,
                               last_hostEntry, FSnameList, CMnameList, buff2);
         /* thresholds are not global anymore */
         /* if (global_ThreshFlag) global_ThreshFlag = 0; */
      }
      else if ((strcasecmp(opcode, "thresh")) == 0) {
         /* fprintf(STDERR, " - parsing thresh entry\n"); */
         code =
            my_parse_threshEntry(line, &global_fsThreshCount,
                                 &global_cmThreshCount, *last_hostEntry,
                                 *lastHostType, buff2);
      }
      else if ((strcasecmp(opcode, "show")) == 0) {
         /* fprintf(STDERR, " - parsing show entry\n"); */
         code =
            my_parse_showEntry(line, fs_showDefault, cm_showDefault,
                               fs_showFlags, cm_showFlags, buff2);
      }
      else {
         /* fprintf(STDERR, " - unknown entry\n"); */
         sprintf(buff2, "Unknown opcode %s", opcode);
         code = 1;
      }

      if (code) {
         sprintf(buff1,
                 "Error processing config file line %d (\"%s %s %s %s %s\"). %s",
                 linenum, opcode, arg1, arg2, arg3, arg4, buff2);
         error_in_config = 1;
         BSETCODE(10, buff1);
         return (-1);
      }
   }
   /* fprintf(STDERR, "got to end of file.\n"); */

   if (error_in_config) {
      sprintf(buff1, "Error in config file. %s", buff2);
      BSETCODE(10, buff1);
      return (-1);
   }

   /* the threshold count of all hosts in increased by 1 for each global
    * threshold. If one of the hosts has a local threshold for the same
    * variable it would end up being counted twice. whats a few bytes of memory
    * wasted anyway ? */

   if (global_fsThreshCount) {
      curr_host = *FSnameList;
      for (i = 0; i < *numFS; i++) {
         curr_host->numThresh += global_fsThreshCount;
         curr_host = curr_host->next;
      }
   }
   if (global_cmThreshCount) {
      curr_host = *CMnameList;
      for (i = 0; i < *numCM; i++) {
         curr_host->numThresh += global_cmThreshCount;
         curr_host = curr_host->next;
      }
   }

   /* make sure we have something to monitor */
   if (*numFS == 0 && *numCM == 0) {
      sprintf(buff1,
              "Config file must specify atleast one File Server or Cache Manager host to monitor.");
      fclose(configFD);
      BSETCODE(15, buff1);
      return (-1);
   }

   /* Second Pass */

   fseek(configFD, 0, 0);   /* seek to the beginning */

   /* allocate memory for threshold lists */

   curr_host = *FSnameList;
   for (i = 0; i < *numFS; i++) {
      if (curr_host->hostName[0] == '\0') {
         sprintf(buff1, "Programming error 4");
         BSETCODE(20, buff1);
         return (-1);
      }
      if (curr_host->numThresh) {
         numBytes = curr_host->numThresh * sizeof(struct Threshold);
         curr_host->thresh = (struct Threshold *)malloc(numBytes);
         if (curr_host->thresh == (struct Threshold *) NULL) {
            sprintf(buff1, "Memory Allocation error 1");
            BSETCODE(25, buff1);
            return (-1);
         }
         memset(curr_host->thresh, 0, numBytes);
      }
      curr_host = curr_host->next;
   }

   curr_host = *CMnameList;
   for (i = 0; i < *numCM; i++) {
      if (curr_host->hostName[0] == '\0') {
         sprintf(buff1, "Programming error 5");
         BSETCODE(30, buff1);
         return (-1);
      }
      if (curr_host->numThresh) {
         numBytes = curr_host->numThresh * sizeof(struct Threshold);
         curr_host->thresh = (struct Threshold *)malloc(numBytes);
         if (curr_host->thresh == (struct Threshold *) NULL) {
            sprintf(buff1, "Memory Allocation error 2");
            BSETCODE(35, buff1);
            return (-1);
         }
         memset(curr_host->thresh, 0, numBytes);
      }
      curr_host = curr_host->next;
   }

   opcode[0] = 0;
   arg1[0] = 0;
   arg2[0] = 0;
   arg3[0] = 0;
   arg4[0] = 0;
   last_fsHost[0] = '\0';
   last_cmHost[0] = '\0';
   linenum = 0;
   while ((fgets(line, CFG_STR_LEN, configFD)) != NULL) {
      opcode[0] = 0;
      arg1[0] = 0;
      arg2[0] = 0;
      arg3[0] = 0;
      arg4[0] = 0;
      sscanf(line, "%s %s %s %s %s", opcode, arg1, arg2, arg3, arg4);
      linenum++;

      /* if we have a host entry, remember the host name */
      if (strcasecmp(opcode, "fs") == 0) {
         he = GetHostByName(arg1);
         strncpy(last_fsHost, he->h_name, HOST_NAME_LEN);
      }
      else if (strcasecmp(opcode, "cm") == 0) {
         he = GetHostByName(arg1);
         strncpy(last_cmHost, he->h_name, HOST_NAME_LEN);
      }
      else if (strcasecmp(opcode, "thresh") == 0) {
         /* if we have a threshold handler it may have arguments
          * and the sscanf() above would not get them, so do the
          * following */
         if (strlen(arg4)) {
            handlerPtr = line;
            /* now skip over 4 words - this is done by first
             * skipping leading blanks then skipping a word */
            for (i = 0; i < 4; i++) {
               while (isspace(*handlerPtr))
                  handlerPtr++;
               while (!isspace(*handlerPtr))
                  handlerPtr++;
            }
            while (isspace(*handlerPtr))
               handlerPtr++;
            /* we how have a pointer to the start of the handler
             * name & args */
         }
         else
            handlerPtr = arg4;  /* empty string */

         if (strcasecmp(arg1, "fs") == 0)
            code = my_store_threshold(1,    /* 1 = fs */
                                      arg2, arg3, handlerPtr,
                                      &global_fsThreshCount, *FSnameList,
                                      last_fsHost, *numFS, buff2);

         else if (strcasecmp(arg1, "cm") == 0)
            code = my_store_threshold(2,    /* 2 = cm */
                                      arg2, arg3, handlerPtr,
                                      &global_cmThreshCount, *CMnameList,
                                      last_cmHost, *numCM, buff2);

         else {
            sprintf(buff1, "Programming error 6");
            BSETCODE(40, buff1);
            return (-1);
         }
         if (code) {
            sprintf(buff1,
                    "Error processing config file line %d (\"%s %s %s %s %s\"): Failed to store threshold. %s",
                    linenum, opcode, arg1, arg2, arg3, arg4, buff2);
            BSETCODE(45, buff1);
            return (-1);
         }
      }
   }

   fclose(configFD);
   return (0);
}   /* my_process_config_file() */




/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_fs_OpTiming(a_opIdx, a_opTimeP, fs_outFD)
   int a_opIdx;
   struct fs_stats_opTimingData *a_opTimeP;
   FILE *fs_outFD;
{

   fprintf(fs_outFD,
           "%15s: %d ops (%d OK); sum=%d.%06d, min=%d.%06d, max=%d.%06d\n",
           fsOpNames[a_opIdx], a_opTimeP->numOps, a_opTimeP->numSuccesses,
           a_opTimeP->sumTime.tv_sec, a_opTimeP->sumTime.tv_usec,
           a_opTimeP->minTime.tv_sec, a_opTimeP->minTime.tv_usec,
           a_opTimeP->maxTime.tv_sec, a_opTimeP->maxTime.tv_usec);
}   /* my_Print_fs_OpTiming() */


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_fs_XferTiming(a_opIdx, a_xferP, fs_outFD)
   int a_opIdx;
   struct fs_stats_xferData *a_xferP;
   FILE *fs_outFD;
{

   fprintf(fs_outFD,
           "%s: %d xfers (%d OK), time sum=%d.%06d, min=%d.%06d, max=%d.%06d\n",
           xferOpNames[a_opIdx], a_xferP->numXfers, a_xferP->numSuccesses,
           a_xferP->sumTime.tv_sec, a_xferP->sumTime.tv_usec,
           a_xferP->minTime.tv_sec, a_xferP->minTime.tv_usec,
           a_xferP->maxTime.tv_sec, a_xferP->maxTime.tv_usec);
   fprintf(fs_outFD, "\t[bytes: sum=%d, min=%d, max=%d]\n",
           a_xferP->sumBytes, a_xferP->minBytes, a_xferP->maxBytes);
   fprintf(fs_outFD,
           "\t[buckets: 0: %d, 1: %d, 2: %d, 3: %d, 4: %d, 5: %d 6: %d, 7: %d, 8: %d]\n",
           a_xferP->count[0], a_xferP->count[1], a_xferP->count[2],
           a_xferP->count[3], a_xferP->count[4], a_xferP->count[5],
           a_xferP->count[6], a_xferP->count[7], a_xferP->count[8]);
}   /* my_Print_fs_XferTiming() */



/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_fs_OverallPerfInfo(a_ovP, fs_outFD)
   struct afs_PerfStats *a_ovP;
   FILE *fs_outFD;
{

   fprintf(fs_outFD, "\t%10d numPerfCalls\n\n", a_ovP->numPerfCalls);

   /*
    * Vnode cache section.
    */
   fprintf(fs_outFD, "\t%10d vcache_L_Entries\n", a_ovP->vcache_L_Entries);
   fprintf(fs_outFD, "\t%10d vcache_L_Allocs\n", a_ovP->vcache_L_Allocs);
   fprintf(fs_outFD, "\t%10d vcache_L_Gets\n", a_ovP->vcache_L_Gets);
   fprintf(fs_outFD, "\t%10d vcache_L_Reads\n", a_ovP->vcache_L_Reads);
   fprintf(fs_outFD, "\t%10d vcache_L_Writes\n\n", a_ovP->vcache_L_Writes);

   fprintf(fs_outFD, "\t%10d vcache_S_Entries\n", a_ovP->vcache_S_Entries);
   fprintf(fs_outFD, "\t%10d vcache_S_Allocs\n", a_ovP->vcache_S_Allocs);
   fprintf(fs_outFD, "\t%10d vcache_S_Gets\n", a_ovP->vcache_S_Gets);
   fprintf(fs_outFD, "\t%10d vcache_S_Reads\n", a_ovP->vcache_S_Reads);
   fprintf(fs_outFD, "\t%10d vcache_S_Writes\n\n", a_ovP->vcache_S_Writes);

   fprintf(fs_outFD, "\t%10d vcache_H_Entries\n", a_ovP->vcache_H_Entries);
   fprintf(fs_outFD, "\t%10d vcache_H_Gets\n", a_ovP->vcache_H_Gets);
   fprintf(fs_outFD, "\t%10d vcache_H_Replacements\n\n",
           a_ovP->vcache_H_Replacements);

   /*
    * Directory package section.
    */
   fprintf(fs_outFD, "\t%10d dir_Buffers\n", a_ovP->dir_Buffers);
   fprintf(fs_outFD, "\t%10d dir_Calls\n", a_ovP->dir_Calls);
   fprintf(fs_outFD, "\t%10d dir_IOs\n\n", a_ovP->dir_IOs);

   /*
    * Rx section.
    */
   fprintf(fs_outFD, "\t%10d rx_packetRequests\n", a_ovP->rx_packetRequests);
   fprintf(fs_outFD, "\t%10d rx_noPackets_RcvClass\n",
           a_ovP->rx_noPackets_RcvClass);
   fprintf(fs_outFD, "\t%10d rx_noPackets_SendClass\n",
           a_ovP->rx_noPackets_SendClass);
   fprintf(fs_outFD, "\t%10d rx_noPackets_SpecialClass\n",
           a_ovP->rx_noPackets_SpecialClass);
   fprintf(fs_outFD, "\t%10d rx_socketGreedy\n", a_ovP->rx_socketGreedy);
   fprintf(fs_outFD, "\t%10d rx_bogusPacketOnRead\n",
           a_ovP->rx_bogusPacketOnRead);
   fprintf(fs_outFD, "\t%10d rx_bogusHost\n", a_ovP->rx_bogusHost);
   fprintf(fs_outFD, "\t%10d rx_noPacketOnRead\n", a_ovP->rx_noPacketOnRead);
   fprintf(fs_outFD, "\t%10d rx_noPacketBuffersOnRead\n",
           a_ovP->rx_noPacketBuffersOnRead);
   fprintf(fs_outFD, "\t%10d rx_selects\n", a_ovP->rx_selects);
   fprintf(fs_outFD, "\t%10d rx_sendSelects\n", a_ovP->rx_sendSelects);
   fprintf(fs_outFD, "\t%10d rx_packetsRead_RcvClass\n",
           a_ovP->rx_packetsRead_RcvClass);
   fprintf(fs_outFD, "\t%10d rx_packetsRead_SendClass\n",
           a_ovP->rx_packetsRead_SendClass);
   fprintf(fs_outFD, "\t%10d rx_packetsRead_SpecialClass\n",
           a_ovP->rx_packetsRead_SpecialClass);
   fprintf(fs_outFD, "\t%10d rx_dataPacketsRead\n",
           a_ovP->rx_dataPacketsRead);
   fprintf(fs_outFD, "\t%10d rx_ackPacketsRead\n", a_ovP->rx_ackPacketsRead);
   fprintf(fs_outFD, "\t%10d rx_dupPacketsRead\n", a_ovP->rx_dupPacketsRead);
   fprintf(fs_outFD, "\t%10d rx_spuriousPacketsRead\n",
           a_ovP->rx_spuriousPacketsRead);
   fprintf(fs_outFD, "\t%10d rx_packetsSent_RcvClass\n",
           a_ovP->rx_packetsSent_RcvClass);
   fprintf(fs_outFD, "\t%10d rx_packetsSent_SendClass\n",
           a_ovP->rx_packetsSent_SendClass);
   fprintf(fs_outFD, "\t%10d rx_packetsSent_SpecialClass\n",
           a_ovP->rx_packetsSent_SpecialClass);
   fprintf(fs_outFD, "\t%10d rx_ackPacketsSent\n", a_ovP->rx_ackPacketsSent);
   fprintf(fs_outFD, "\t%10d rx_pingPacketsSent\n",
           a_ovP->rx_pingPacketsSent);
   fprintf(fs_outFD, "\t%10d rx_abortPacketsSent\n",
           a_ovP->rx_abortPacketsSent);
   fprintf(fs_outFD, "\t%10d rx_busyPacketsSent\n",
           a_ovP->rx_busyPacketsSent);
   fprintf(fs_outFD, "\t%10d rx_dataPacketsSent\n",
           a_ovP->rx_dataPacketsSent);
   fprintf(fs_outFD, "\t%10d rx_dataPacketsReSent\n",
           a_ovP->rx_dataPacketsReSent);
   fprintf(fs_outFD, "\t%10d rx_dataPacketsPushed\n",
           a_ovP->rx_dataPacketsPushed);
   fprintf(fs_outFD, "\t%10d rx_ignoreAckedPacket\n",
           a_ovP->rx_ignoreAckedPacket);
   fprintf(fs_outFD, "\t%10d rx_totalRtt_Sec\n", a_ovP->rx_totalRtt_Sec);
   fprintf(fs_outFD, "\t%10d rx_totalRtt_Usec\n", a_ovP->rx_totalRtt_Usec);
   fprintf(fs_outFD, "\t%10d rx_minRtt_Sec\n", a_ovP->rx_minRtt_Sec);
   fprintf(fs_outFD, "\t%10d rx_minRtt_Usec\n", a_ovP->rx_minRtt_Usec);
   fprintf(fs_outFD, "\t%10d rx_maxRtt_Sec\n", a_ovP->rx_maxRtt_Sec);
   fprintf(fs_outFD, "\t%10d rx_maxRtt_Usec\n", a_ovP->rx_maxRtt_Usec);
   fprintf(fs_outFD, "\t%10d rx_nRttSamples\n", a_ovP->rx_nRttSamples);
   fprintf(fs_outFD, "\t%10d rx_nServerConns\n", a_ovP->rx_nServerConns);
   fprintf(fs_outFD, "\t%10d rx_nClientConns\n", a_ovP->rx_nClientConns);
   fprintf(fs_outFD, "\t%10d rx_nPeerStructs\n", a_ovP->rx_nPeerStructs);
   fprintf(fs_outFD, "\t%10d rx_nCallStructs\n", a_ovP->rx_nCallStructs);
   fprintf(fs_outFD, "\t%10d rx_nFreeCallStructs\n\n",
           a_ovP->rx_nFreeCallStructs);

   /*
    * Host module fields.
    */
   fprintf(fs_outFD, "\t%10d host_NumHostEntries\n",
           a_ovP->host_NumHostEntries);
   fprintf(fs_outFD, "\t%10d host_HostBlocks\n", a_ovP->host_HostBlocks);
   fprintf(fs_outFD, "\t%10d host_NonDeletedHosts\n",
           a_ovP->host_NonDeletedHosts);
   fprintf(fs_outFD, "\t%10d host_HostsInSameNetOrSubnet\n",
           a_ovP->host_HostsInSameNetOrSubnet);
   fprintf(fs_outFD, "\t%10d host_HostsInDiffSubnet\n",
           a_ovP->host_HostsInDiffSubnet);
   fprintf(fs_outFD, "\t%10d host_HostsInDiffNetwork\n",
           a_ovP->host_HostsInDiffNetwork);
   fprintf(fs_outFD, "\t%10d host_NumClients\n", a_ovP->host_NumClients);
   fprintf(fs_outFD, "\t%10d host_ClientBlocks\n\n",
           a_ovP->host_ClientBlocks);

}   /* my_Print_fs_OverallPerfInfo() */



/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_fs_DetailedPerfInfo(a_detP, fs_outFD)
   struct fs_stats_DetailedStats *a_detP;
   FILE *fs_outFD;
{

   int currIdx = 0;             /*Loop variable */
   fprintf(fs_outFD, "\t%10d epoch\n", a_detP->epoch);
   for (currIdx = 0; currIdx < FS_STATS_NUM_RPC_OPS; currIdx++)
      my_Print_fs_OpTiming(currIdx, &(a_detP->rpcOpTimes[currIdx]), fs_outFD);
   for (currIdx = 0; currIdx < FS_STATS_NUM_XFER_OPS; currIdx++)
      my_Print_fs_XferTiming(currIdx, &(a_detP->xferOpTimes[currIdx]),
                             fs_outFD);
}   /* my_Print_fs_DetailedPerfInfo() */


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_fs_FullPerfInfo(a_fs_Results, fs_outFD)
   struct xstat_fs_ProbeResults *a_fs_Results;
   FILE *fs_outFD;
{
   /*Correct # longs to rcv */
   static afs_int32 fullPerfLongs = (sizeof(struct fs_stats_FullPerfStats) >> 2);
   afs_int32 numLongs = 0;      /*# longwords received */
   struct fs_stats_FullPerfStats *fullPerfP = 0;    /*Ptr to full perf stats */
   char *printableTime = 0;     /*Ptr to printable time string */

   numLongs = a_fs_Results->data.AFS_CollData_len;
   if (numLongs != fullPerfLongs) {
      fprintf(fs_outFD,
              " ** Data size mismatch in full performance collection!\n");
      fprintf(fs_outFD, " ** Expecting %d, got %d\n", fullPerfLongs,
              numLongs);
      return;
   }
   printableTime = ctime((time_t *) & (a_fs_Results->probeTime));
   printableTime[strlen(printableTime) - 1] = '\0';
   fullPerfP = (struct fs_stats_FullPerfStats *)
      (a_fs_Results->data.AFS_CollData_val);
   fprintf(fs_outFD,
           "AFS_XSTATSCOLL_FULL_PERF_INFO (coll %d) for FS %s\n[Probe %d, %s]\n\n",
           a_fs_Results->collectionNumber, a_fs_Results->connP->hostName,
           a_fs_Results->probeNum, printableTime);
   my_Print_fs_OverallPerfInfo(&(fullPerfP->overall), fs_outFD);
   my_Print_fs_DetailedPerfInfo(&(fullPerfP->det), fs_outFD);
}


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_afsmon_fsOutput(a_outfile, a_detOutput, xstat_fs_Results)
   char *a_outfile;             /* ptr to output file name */
   int a_detOutput;             /* detailed output ? */
   struct xstat_fs_ProbeResults xstat_fs_Results;
{

   char *printTime = 0;         /* ptr to time string */
   char *hostname = 0;          /* fileserner name */
   afs_int32 numLongs = 0;      /* longwords in result */
   afs_int32 *currLong = 0;     /* ptr to longwords in result */
   int i = 0;
   FILE *fs_outFD = 0;

   fs_outFD = fopen(a_outfile, "a");
   if (fs_outFD == (FILE *) NULL) {
      warn("failed to open output file %s", a_outfile);
      return;
   }

   /* get the probe time and strip the \n at the end */
   printTime = ctime((time_t *) & (xstat_fs_Results.probeTime));
   printTime[strlen(printTime) - 1] = '\0';
   hostname = xstat_fs_Results.connP->hostName;

   /* print "time hostname FS" */
   fprintf(fs_outFD, "\n%s %s FS ", printTime, hostname);

   /* if probe failed print -1 and return */
   if (xstat_fs_Results.probeOK) {
      fprintf(fs_outFD, "-1\n");
      fclose(fs_outFD);
      return;
   }

   /* print out the probe information as  long words */
   numLongs = xstat_fs_Results.data.AFS_CollData_len;
   currLong = (afs_int32 *) (xstat_fs_Results.data.AFS_CollData_val);

   for (i = 0; i < numLongs; i++) {
      fprintf(fs_outFD, "%d ", *currLong++);
   }
   fprintf(fs_outFD, "\n\n");

   /* print detailed information */
   if (a_detOutput) {
      my_Print_fs_FullPerfInfo(&xstat_fs_Results, fs_outFD);
      fflush(fs_outFD);
   }

   fclose(fs_outFD);

}   /* my_afsmon_fsOutput() */





/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_fs_Results_ltoa(a_fsData, a_fsResults)
   struct fs_Display_Data *a_fsData;    /* target buffer */
   struct xstat_fs_ProbeResults *a_fsResults;   /* ptr to xstat fs Results */
{
   afs_int32 *srcbuf;
   struct fs_stats_FullPerfStats *fullPerfP;
   int idx;
   int i, j;
   afs_int32 *tmpbuf;


   fullPerfP = (struct fs_stats_FullPerfStats *)
      (a_fsResults->data.AFS_CollData_val);

   /* there are two parts to the xstat FS statistics
    * - fullPerfP->overall which give the overall performance statistics, and
    * - fullPerfP->det which gives detailed info about file server operation
    * execution times */

   /* copy overall performance statistics */
   srcbuf = (afs_int32 *) & (fullPerfP->overall);
   idx = 0;
   for (i = 0; i < NUM_XSTAT_FS_AFS_PERFSTATS_LONGS; i++) {
      sprintf(a_fsData->data[idx], "%d", *srcbuf);
      idx++;
      srcbuf++;
   }

   /* copy epoch */
   srcbuf = (afs_int32 *) & (fullPerfP->det.epoch);
   sprintf(a_fsData->data[idx], "%d", *srcbuf); /* epoch */
   idx++;

   /* copy fs operation timing */

   srcbuf = (afs_int32 *) (fullPerfP->det.rpcOpTimes);

   for (i = 0; i < FS_STATS_NUM_RPC_OPS; i++) {
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* numOps */
      idx++;
      srcbuf++;
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* numSuccesses */
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sum time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sqr time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* min time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* max time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
   }

   /* copy fs transfer timings */

   srcbuf = (afs_int32 *) (fullPerfP->det.xferOpTimes);
   for (i = 0; i < FS_STATS_NUM_XFER_OPS; i++) {
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* numOps */
      idx++;
      srcbuf++;
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* numSuccesses */
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sum time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sqr time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* min time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* max time */
      sprintf(a_fsData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* sum bytes */
      idx++;
      srcbuf++;
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* min bytes */
      idx++;
      srcbuf++;
      sprintf(a_fsData->data[idx], "%d", *srcbuf);  /* max bytes */
      idx++;
      srcbuf++;
      for (j = 0; j < FS_STATS_NUM_XFER_BUCKETS; j++) {
         sprintf(a_fsData->data[idx], "%d", *srcbuf);   /* bucket[j] */
         idx++;
         srcbuf++;
      }
   }

   return (0);
}   /* my_fs_Results_ltoa() */



void
fs_Results_to_Hash(struct fs_Display_Data *fsData, HV *HOSTINFO,
                   short *showFlags, int showDefault)
{
   int secidx;
   int grpidx;
   int numgrp;
   int fromidx;
   int toidx;
   char section[CFG_STR_LEN] = "";
   char group[CFG_STR_LEN] = "";
   HV *ENTRY;
   HV *GROUP;
   HV *SECTION;
   int i;

   secidx = 0;
   grpidx = secidx + 1;

   while (secidx < FS_NUM_DATA_CATEGORIES) {

      sscanf(fs_categories[secidx], "%s %d", section, &numgrp);
      SECTION = newHV();

      while (grpidx <= secidx + numgrp) {
         GROUP = newHV();
         sscanf(fs_categories[grpidx], "%s %d %d", group, &fromidx, &toidx);
         for (i = fromidx; i <= toidx; i++) {
            if (showFlags[i] || showDefault) {
               ENTRY = newHV();
               hv_store(ENTRY, "value", 5, newSVnv(atof(fsData->data[i])), 0);
               hv_store(GROUP, fs_varNames[i], strlen(fs_varNames[i]),
                        newRV_inc((SV *) ENTRY), 0);
            }
         }
         if (HvKEYS(GROUP))
            hv_store(SECTION, group, strlen(group), newRV_inc((SV *) GROUP),
                     0);
         grpidx++;
      }
      if (HvKEYS(SECTION))
         hv_store(HOSTINFO, section, strlen(section),
                  newRV_inc((SV *) SECTION), 0);
      secidx += numgrp + 1;
      grpidx = secidx + 1;
   }
}   /* fs_Results_to_Hash() */



/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_save_FS_data_forDisplay(a_fsResults, HOSTINFO, numFS, FSnameList,
                           fs_showFlags, fs_showDefault, buffer)
   struct xstat_fs_ProbeResults *a_fsResults;
   HV *HOSTINFO;
   int numFS;
   struct afsmon_hostEntry *FSnameList;
   short *fs_showFlags;
   int fs_showDefault;
   char *buffer;
{
   struct fs_Display_Data *curr_fsDataP;
   struct afsmon_hostEntry *curr_host = 0;
   int i = 0;
   int code = 0;
   int done = 0;
   char buff2[256] = "";

   curr_fsDataP =
      (struct fs_Display_Data *)malloc(sizeof(struct fs_Display_Data));
   if (curr_fsDataP == (struct fs_Display_Data *) NULL) {
      sprintf(buffer, "Memory allocation failure");
      return (-1);
   }
   memset(curr_fsDataP, 0, sizeof(struct fs_Display_Data));

   hv_store(HOSTINFO, "hostName", 8, newSVpv(a_fsResults->connP->hostName, 0),
            0);

   /*  Check the status of the probe. If it succeeded, we store its
    * results in the display data structure. If it failed we only mark
    * the failed status in the display data structure. */

   if (a_fsResults->probeOK) {  /* 1 => notOK the xstat results */
      hv_store(HOSTINFO, "probeOK", 7, newSViv(0), 0);
   }
   else {   /* probe succeeded, update display data structures */
      hv_store(HOSTINFO, "probeOK", 7, newSViv(1), 0);

      my_fs_Results_ltoa(curr_fsDataP, a_fsResults);

      fs_Results_to_Hash(curr_fsDataP, HOSTINFO, fs_showFlags,
                         fs_showDefault);

      /* compare with thresholds and set the overflow flags.
       * note that the threshold information is in the hostEntry structure and
       * each threshold item has a positional index associated with it */

      /* locate the hostEntry for this host */
      done = 0;
      curr_host = FSnameList;
      for (i = 0; i < numFS; i++) {
         if (strcasecmp(curr_host->hostName, a_fsResults->connP->hostName)
             == 0) {
            done = 1;
            break;
         }
         curr_host = curr_host->next;;
      }
      if (!done) {
         sprintf(buffer, "Error storing results for FS host %s (70)",
                 a_fsResults->connP->hostName);
         return (70);
      }

      code = my_check_thresholds(curr_host, HOSTINFO, FS, buff2);
      if (code) {
         sprintf(buffer, "Error in checking thresholds (75) %s", buff2);
         return (75);
      }

   }    /* the probe succeeded, so we store the data in the display structure */
   return (0);

}   /* my_save_FS_data_forDisplay() */



/*
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_afsmon_FS_Handler(xstat_fs_Results, numFS, conn_idx, buffer, argp)
   struct xstat_fs_ProbeResults xstat_fs_Results;
   int numFS;
   int conn_idx;
   char *buffer;
   va_list argp;
{
   char *outputfile = va_arg(argp, char *);
   int detailed = va_arg(argp, int);
   AV *FILESERV = va_arg(argp, AV *);
   struct afsmon_hostEntry *FSnameList =
      va_arg(argp, struct afsmon_hostEntry *);
   short *fs_showFlags = va_arg(argp, short *);
   int fs_showDefault = va_arg(argp, int);

   HV *HOSTINFO = newHV();

   int code = 0;

   if (outputfile)
      my_afsmon_fsOutput(outputfile, detailed, xstat_fs_Results);

   /* add everything to data structure */
   code =
      my_save_FS_data_forDisplay(&xstat_fs_Results, HOSTINFO, numFS,
                                 FSnameList, fs_showFlags, fs_showDefault,
                                 buffer);
   if (code) {
      return (code);
   }

   /* Add HOSTINFO to FS */
   av_store(FILESERV, conn_idx, newRV_inc((SV *) (HOSTINFO)));
   return (0);

}   /* my_afsmon_FS_Handler() */




/*
 * from src/xstat/xstat_fs.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_fs_LWP(ProbeHandler, xstat_fs_ConnInfo, xstat_fs_numServers,
                xstat_fs_collIDP, xstat_fs_numCollections, buffer, argp)
   int (*ProbeHandler) ();
   struct xstat_fs_ConnectionInfo *xstat_fs_ConnInfo;
   int xstat_fs_numServers;
   afs_int32 *xstat_fs_collIDP;
   int xstat_fs_numCollections;
   char *buffer;
   va_list argp;
{
   afs_int32 srvVersionNumber = 0;  /*Xstat version # */
   afs_int32 clientVersionNumber = AFS_XSTAT_VERSION;   /*Client xstat version */
   afs_int32 *currCollIDP = 0;
   int numColls = 0;
   int conn_idx = 0;
   struct xstat_fs_ConnectionInfo *curr_conn = 0;
   char buff2[256] = "";
   int code = 0;
   int index = 0;

   struct xstat_fs_ProbeResults xstat_fs_Results;
   afs_int32 xstat_fsData[AFS_MAX_XSTAT_LONGS];
   xstat_fs_Results.probeTime = 0;
   xstat_fs_Results.connP = (struct xstat_fs_ConnectionInfo *) NULL;
   xstat_fs_Results.collectionNumber = 0;
   xstat_fs_Results.data.AFS_CollData_len = AFS_MAX_XSTAT_LONGS;
   xstat_fs_Results.data.AFS_CollData_val = (afs_int32 *) xstat_fsData;
   xstat_fs_Results.probeOK = 0;

   curr_conn = xstat_fs_ConnInfo;
   for (conn_idx = 0; conn_idx < xstat_fs_numServers; conn_idx++) {
      /*
       * Grab the statistics for the current File Server, if the
       * connection is valid.
       */
      if (curr_conn->rxconn != (struct rx_connection *) NULL) {

         currCollIDP = xstat_fs_collIDP;
         for (numColls = 0;
              numColls < xstat_fs_numCollections; numColls++, currCollIDP++) {
            /*
             * Initialize the per-probe values.
             */
            xstat_fs_Results.collectionNumber = *currCollIDP;
            xstat_fs_Results.data.AFS_CollData_len = AFS_MAX_XSTAT_LONGS;
            memset(xstat_fs_Results.data.AFS_CollData_val, 0,
                   AFS_MAX_XSTAT_LONGS * 4);

            xstat_fs_Results.connP = curr_conn;

            xstat_fs_Results.probeOK =
               RXAFS_GetXStats(curr_conn->rxconn,
                               clientVersionNumber,
                               *currCollIDP,
                               &srvVersionNumber,
                               &(xstat_fs_Results.probeTime),
                               &(xstat_fs_Results.data));
            code =
               ProbeHandler(xstat_fs_Results, xstat_fs_numServers, index,
                            buff2, argp);
            index++;

            if (code) {
               sprintf(buffer, "Handler returned error code %d. %s",
                       code, buff2);
               return (code);
            }

         }  /* For each collection */
      } /*Valid Rx connection */

      /*
       * Advance the xstat_fs connection pointer.
       */
      curr_conn++;

   }    /* For each xstat_fs connection */
   return (0);
}   /* my_xstat_fs_LWP() */


/*
 * from src/xstat/xstat_fs.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_fs_Init(int (*ProbeHandler) (), int xstat_fs_numServers,
                 struct sockaddr_in *a_socketArray,
                 int xstat_fs_numCollections, afs_int32 * xstat_fs_collIDP,
                 char *buffer, ...)
{
   int curr_srv = 0;
   int conn_err = 0;
   char *hostNameFound = "";
   struct xstat_fs_ConnectionInfo *curr_conn = 0, *xstat_fs_ConnInfo = 0;
   struct rx_securityClass *secobj = 0; /*Client security object */
   char buff2[256] = "";
   int PortToUse = 0;
   int code = 0;
   va_list argp;

   xstat_fs_ConnInfo = (struct xstat_fs_ConnectionInfo *)
      malloc(xstat_fs_numServers * sizeof(struct xstat_fs_ConnectionInfo));
   if (xstat_fs_ConnInfo == (struct xstat_fs_ConnectionInfo *) NULL) {
      sprintf(buffer,
              "Can't allocate %d connection info structs (%d bytes)",
              xstat_fs_numServers,
              (xstat_fs_numServers * sizeof(struct xstat_fs_ConnectionInfo)));
      return (-1);  /*No cleanup needs to be done yet */
   }

   PortToUse = XSTAT_FS_CBPORT;

   do {
      code = rx_Init(htons(PortToUse));
      if (code) {
         if (code == RX_ADDRINUSE) {
            PortToUse++;
         }
         else {
            sprintf(buffer, "Fatal error in rx_Init()");
            return (-1);
         }
      }
   } while (code);

    /*
     * Create a null Rx client security object, to be used by the
     * probe LWP.
     */
   secobj = rxnull_NewClientSecurityObject();
   if (secobj == (struct rx_securityClass *) NULL) {
      /*Delete already-malloc'ed areas */
      my_xstat_fs_Cleanup(1, xstat_fs_numServers, xstat_fs_ConnInfo, buff2);
      sprintf(buffer, "Can't create probe LWP client security object. %s",
              buff2);
      return (-1);
   }

   curr_conn = xstat_fs_ConnInfo;
   conn_err = 0;
   for (curr_srv = 0; curr_srv < xstat_fs_numServers; curr_srv++) {
      /*
       * Copy in the socket info for the current server, resolve its
       * printable name if possible.
       */

      memcpy(&(curr_conn->skt), a_socketArray + curr_srv,
             sizeof(struct sockaddr_in));

      hostNameFound = hostutil_GetNameByINet(curr_conn->skt.sin_addr.s_addr);
      if (hostNameFound == NULL) {
         warn("Can't map Internet address %lu to a string name",
              curr_conn->skt.sin_addr.s_addr);
         curr_conn->hostName[0] = '\0';
      }
      else {
         strcpy(curr_conn->hostName, hostNameFound);
      }

      /*
       * Make an Rx connection to the current server.
       */

      curr_conn->rxconn = rx_NewConnection(curr_conn->skt.sin_addr.s_addr,  /*Server addr */
                                           curr_conn->skt.sin_port, /*Server port */
                                           1,   /*AFS service # */
                                           secobj,  /*Security obj */
                                           0);  /*# of above */
      if (curr_conn->rxconn == (struct rx_connection *) NULL) {
         sprintf(buffer,
                 "Can't create Rx connection to server '%s' (%lu)",
                 curr_conn->hostName, curr_conn->skt.sin_addr.s_addr);
         my_xstat_fs_Cleanup(1, xstat_fs_numServers, xstat_fs_ConnInfo,
                             buff2);
         return (-2);
      }
      /*
       * Bump the current xstat_fs connection to set up.
       */
      curr_conn++;

   }    /*for curr_srv */


   va_start(argp, buffer);
   code =
      my_xstat_fs_LWP(ProbeHandler, xstat_fs_ConnInfo, xstat_fs_numServers,
                      xstat_fs_collIDP, xstat_fs_numCollections, buffer,
                      argp);
   va_end(argp);

   if (code) {
      return (code);
   }
   my_xstat_fs_Cleanup(1, xstat_fs_numServers, xstat_fs_ConnInfo, buff2);
   return (0);
}   /* my_xstat_fs_Init() */


/*
 * from src/xstat/xstat_fs.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_fs_Cleanup(a_releaseMem, xstat_fs_numServers, xstat_fs_ConnInfo,
                    buffer)
   int a_releaseMem;
   int xstat_fs_numServers;
   struct xstat_fs_ConnectionInfo *xstat_fs_ConnInfo;
   char *buffer;
{
   int code = 0;                /*Return code */
   int conn_idx = 0;            /*Current connection index */
   struct xstat_fs_ConnectionInfo *curr_conn = 0;   /*Ptr to xstat_fs connection */

   /*
    * Take care of all Rx connections first.  Check to see that the
    * server count is a legal value.
    */
   if (xstat_fs_numServers <= 0) {
      sprintf(buffer,
              "Illegal number of servers (xstat_fs_numServers = %d)",
              xstat_fs_numServers);
      code = -1;
   }
   else {
      if (xstat_fs_ConnInfo != (struct xstat_fs_ConnectionInfo *) NULL) {
         /*
          * The xstat_fs connection structure array exists.  Go through
          * it and close up any Rx connections it holds.
          */
         curr_conn = xstat_fs_ConnInfo;
         for (conn_idx = 0; conn_idx < xstat_fs_numServers; conn_idx++) {
            if (curr_conn->rxconn != (struct rx_connection *) NULL) {
               rx_DestroyConnection(curr_conn->rxconn);
               curr_conn->rxconn = (struct rx_connection *) NULL;
            }
            curr_conn++;
         }  /*for each xstat_fs connection */
      } /*xstat_fs connection structure exists */
   }    /*Legal number of servers */

   /*
    * If asked to, release the space we've allocated.
    */
   if (a_releaseMem) {
      if (xstat_fs_ConnInfo != (struct xstat_fs_ConnectionInfo *) NULL)
         free(xstat_fs_ConnInfo);
   }

   /*
    * Return the news, whatever it is.
    */
   return (code);

}   /* my_xstat_fs_Cleanup() */




/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_UpDownStats(a_upDownP, cm_outFD)
   struct afs_stats_SrvUpDownInfo *a_upDownP;   /*Ptr to server up/down info */
   FILE *cm_outFD;
{   /*Print_cm_UpDownStats */

   /*
    * First, print the simple values.
    */
   fprintf(cm_outFD, "\t\t%10d numTtlRecords\n", a_upDownP->numTtlRecords);
   fprintf(cm_outFD, "\t\t%10d numUpRecords\n", a_upDownP->numUpRecords);
   fprintf(cm_outFD, "\t\t%10d numDownRecords\n", a_upDownP->numDownRecords);
   fprintf(cm_outFD, "\t\t%10d sumOfRecordAges\n",
           a_upDownP->sumOfRecordAges);
   fprintf(cm_outFD, "\t\t%10d ageOfYoungestRecord\n",
           a_upDownP->ageOfYoungestRecord);
   fprintf(cm_outFD, "\t\t%10d ageOfOldestRecord\n",
           a_upDownP->ageOfOldestRecord);
   fprintf(cm_outFD, "\t\t%10d numDowntimeIncidents\n",
           a_upDownP->numDowntimeIncidents);
   fprintf(cm_outFD, "\t\t%10d numRecordsNeverDown\n",
           a_upDownP->numRecordsNeverDown);
   fprintf(cm_outFD, "\t\t%10d maxDowntimesInARecord\n",
           a_upDownP->maxDowntimesInARecord);
   fprintf(cm_outFD, "\t\t%10d sumOfDowntimes\n", a_upDownP->sumOfDowntimes);
   fprintf(cm_outFD, "\t\t%10d shortestDowntime\n",
           a_upDownP->shortestDowntime);
   fprintf(cm_outFD, "\t\t%10d longestDowntime\n",
           a_upDownP->longestDowntime);

   /*
    * Now, print the array values.
    */
   fprintf(cm_outFD, "\t\tDowntime duration distribution:\n");
   fprintf(cm_outFD, "\t\t\t%8d: 0 min .. 10 min\n",
           a_upDownP->downDurations[0]);
   fprintf(cm_outFD, "\t\t\t%8d: 10 min .. 30 min\n",
           a_upDownP->downDurations[1]);
   fprintf(cm_outFD, "\t\t\t%8d: 30 min .. 1 hr\n",
           a_upDownP->downDurations[2]);
   fprintf(cm_outFD, "\t\t\t%8d: 1 hr .. 2 hr\n",
           a_upDownP->downDurations[3]);
   fprintf(cm_outFD, "\t\t\t%8d: 2 hr .. 4 hr\n",
           a_upDownP->downDurations[4]);
   fprintf(cm_outFD, "\t\t\t%8d: 4 hr .. 8 hr\n",
           a_upDownP->downDurations[5]);
   fprintf(cm_outFD, "\t\t\t%8d: > 8 hr\n", a_upDownP->downDurations[6]);

   fprintf(cm_outFD, "\t\tDowntime incident distribution:\n");
   fprintf(cm_outFD, "\t\t\t%8d: 0 times\n", a_upDownP->downIncidents[0]);
   fprintf(cm_outFD, "\t\t\t%8d: 1 time\n", a_upDownP->downIncidents[1]);
   fprintf(cm_outFD, "\t\t\t%8d: 2 .. 5 times\n",
           a_upDownP->downIncidents[2]);
   fprintf(cm_outFD, "\t\t\t%8d: 6 .. 10 times\n",
           a_upDownP->downIncidents[3]);
   fprintf(cm_outFD, "\t\t\t%8d: 10 .. 50 times\n",
           a_upDownP->downIncidents[4]);
   fprintf(cm_outFD, "\t\t\t%8d: > 50 times\n", a_upDownP->downIncidents[5]);

}   /* my_Print_cm_UpDownStats() */


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_XferTiming(a_opIdx, a_opNames, a_xferP, cm_outFD)
   int a_opIdx;
   char *a_opNames[];
   struct afs_stats_xferData *a_xferP;
   FILE *cm_outFD;
{   /*Print_cm_XferTiming */

   fprintf(cm_outFD,
           "%s: %d xfers (%d OK), time sum=%d.%06d, min=%d.%06d, max=%d.%06d\n",
           a_opNames[a_opIdx], a_xferP->numXfers, a_xferP->numSuccesses,
           a_xferP->sumTime.tv_sec, a_xferP->sumTime.tv_usec,
           a_xferP->minTime.tv_sec, a_xferP->minTime.tv_usec,
           a_xferP->maxTime.tv_sec, a_xferP->maxTime.tv_usec);
   fprintf(cm_outFD, "\t[bytes: sum=%d, min=%d, max=%d]\n", a_xferP->sumBytes,
           a_xferP->minBytes, a_xferP->maxBytes);
   fprintf(cm_outFD,
           "\t[buckets: 0: %d, 1: %d, 2: %d, 3: %d, 4: %d, 5: %d 6: %d, 7: %d, 8: %d]\n",
           a_xferP->count[0], a_xferP->count[1], a_xferP->count[2],
           a_xferP->count[3], a_xferP->count[4], a_xferP->count[5],
           a_xferP->count[6], a_xferP->count[7], a_xferP->count[8]);

}   /* my_Print_cm_XferTiming() */


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_ErrInfo(a_opIdx, a_opNames, a_opErrP, cm_outFD)
   int a_opIdx;
   char *a_opNames[];
   struct afs_stats_RPCErrors *a_opErrP;
   FILE *cm_outFD;
{   /*Print_cm_ErrInfo */

   fprintf(cm_outFD,
           "%15s: %d server, %d network, %d prot, %d vol, %d busies, %d other\n",
           a_opNames[a_opIdx], a_opErrP->err_Server, a_opErrP->err_Network,
           a_opErrP->err_Protection, a_opErrP->err_Volume,
           a_opErrP->err_VolumeBusies, a_opErrP->err_Other);

}   /* my_Print_cm_ErrInfo() */



/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_OpTiming(a_opIdx, a_opNames, a_opTimeP, cm_outFD)
   int a_opIdx;
   char *a_opNames[];
   struct afs_stats_opTimingData *a_opTimeP;
   FILE *cm_outFD;
{   /*Print_cm_OpTiming */

   fprintf(cm_outFD,
           "%15s: %d ops (%d OK); sum=%d.%06d, min=%d.%06d, max=%d.%06d\n",
           a_opNames[a_opIdx], a_opTimeP->numOps, a_opTimeP->numSuccesses,
           a_opTimeP->sumTime.tv_sec, a_opTimeP->sumTime.tv_usec,
           a_opTimeP->minTime.tv_sec, a_opTimeP->minTime.tv_usec,
           a_opTimeP->maxTime.tv_sec, a_opTimeP->maxTime.tv_usec);

}   /* my_Print_cm_OpTiming() */



/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_OverallPerfInfo(a_ovP, cm_outFD)
   struct afs_stats_CMPerf *a_ovP;
   FILE *cm_outFD;
{

   fprintf(cm_outFD, "\t%10d numPerfCalls\n", a_ovP->numPerfCalls);

   fprintf(cm_outFD, "\t%10d epoch\n", a_ovP->epoch);
   fprintf(cm_outFD, "\t%10d numCellsVisible\n", a_ovP->numCellsVisible);
   fprintf(cm_outFD, "\t%10d numCellsContacted\n", a_ovP->numCellsContacted);
   fprintf(cm_outFD, "\t%10d dlocalAccesses\n", a_ovP->dlocalAccesses);
   fprintf(cm_outFD, "\t%10d vlocalAccesses\n", a_ovP->vlocalAccesses);
   fprintf(cm_outFD, "\t%10d dremoteAccesses\n", a_ovP->dremoteAccesses);
   fprintf(cm_outFD, "\t%10d vremoteAccesses\n", a_ovP->vremoteAccesses);
   fprintf(cm_outFD, "\t%10d cacheNumEntries\n", a_ovP->cacheNumEntries);
   fprintf(cm_outFD, "\t%10d cacheBlocksTotal\n", a_ovP->cacheBlocksTotal);
   fprintf(cm_outFD, "\t%10d cacheBlocksInUse\n", a_ovP->cacheBlocksInUse);
   fprintf(cm_outFD, "\t%10d cacheBlocksOrig\n", a_ovP->cacheBlocksOrig);
   fprintf(cm_outFD, "\t%10d cacheMaxDirtyChunks\n",
           a_ovP->cacheMaxDirtyChunks);
   fprintf(cm_outFD, "\t%10d cacheCurrDirtyChunks\n",
           a_ovP->cacheCurrDirtyChunks);
   fprintf(cm_outFD, "\t%10d dcacheHits\n", a_ovP->dcacheHits);
   fprintf(cm_outFD, "\t%10d vcacheHits\n", a_ovP->vcacheHits);
   fprintf(cm_outFD, "\t%10d dcacheMisses\n", a_ovP->dcacheMisses);
   fprintf(cm_outFD, "\t%10d vcacheMisses\n", a_ovP->vcacheMisses);
   fprintf(cm_outFD, "\t%10d cacheFilesReused\n", a_ovP->cacheFilesReused);
   fprintf(cm_outFD, "\t%10d vcacheXAllocs\n", a_ovP->vcacheXAllocs);

   fprintf(cm_outFD, "\t%10d bufAlloced\n", a_ovP->bufAlloced);
   fprintf(cm_outFD, "\t%10d bufHits\n", a_ovP->bufHits);
   fprintf(cm_outFD, "\t%10d bufMisses\n", a_ovP->bufMisses);
   fprintf(cm_outFD, "\t%10d bufFlushDirty\n", a_ovP->bufFlushDirty);

   fprintf(cm_outFD, "\t%10d LargeBlocksActive\n", a_ovP->LargeBlocksActive);
   fprintf(cm_outFD, "\t%10d LargeBlocksAlloced\n",
           a_ovP->LargeBlocksAlloced);
   fprintf(cm_outFD, "\t%10d SmallBlocksActive\n", a_ovP->SmallBlocksActive);
   fprintf(cm_outFD, "\t%10d SmallBlocksAlloced\n",
           a_ovP->SmallBlocksAlloced);
   fprintf(cm_outFD, "\t%10d OutStandingMemUsage\n",
           a_ovP->OutStandingMemUsage);
   fprintf(cm_outFD, "\t%10d OutStandingAllocs\n", a_ovP->OutStandingAllocs);
   fprintf(cm_outFD, "\t%10d CallBackAlloced\n", a_ovP->CallBackAlloced);
   fprintf(cm_outFD, "\t%10d CallBackFlushes\n", a_ovP->CallBackFlushes);

   fprintf(cm_outFD, "\t%10d srvRecords\n", a_ovP->srvRecords);
   fprintf(cm_outFD, "\t%10d srvNumBuckets\n", a_ovP->srvNumBuckets);
   fprintf(cm_outFD, "\t%10d srvMaxChainLength\n", a_ovP->srvMaxChainLength);
   fprintf(cm_outFD, "\t%10d srvMaxChainLengthHWM\n",
           a_ovP->srvMaxChainLengthHWM);
   fprintf(cm_outFD, "\t%10d srvRecordsHWM\n", a_ovP->srvRecordsHWM);

   fprintf(cm_outFD, "\t%10d sysName_ID\n", a_ovP->sysName_ID);

   fprintf(cm_outFD, "\tFile Server up/downtimes, same cell:\n");
   my_Print_cm_UpDownStats(&(a_ovP->fs_UpDown[0]), cm_outFD);

   fprintf(cm_outFD, "\tFile Server up/downtimes, diff cell:\n");
   my_Print_cm_UpDownStats(&(a_ovP->fs_UpDown[1]), cm_outFD);

   fprintf(cm_outFD, "\tVL Server up/downtimes, same cell:\n");
   my_Print_cm_UpDownStats(&(a_ovP->vl_UpDown[0]), cm_outFD);

   fprintf(cm_outFD, "\tVL Server up/downtimes, diff cell:\n");
   my_Print_cm_UpDownStats(&(a_ovP->vl_UpDown[1]), cm_outFD);

}   /* my_Print_cm_OverallPerfInfo() */


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_RPCPerfInfo(a_rpcP, cm_outFD)
   struct afs_stats_RPCOpInfo *a_rpcP;
   FILE *cm_outFD;
{

   int currIdx;                 /*Loop variable */

   /*
    * Print the contents of each of the opcode-related arrays.
    */
   fprintf(cm_outFD, "FS Operation Timings:\n---------------------\n");
   for (currIdx = 0; currIdx < AFS_STATS_NUM_FS_RPC_OPS; currIdx++)
      my_Print_cm_OpTiming(currIdx, fsOpNames, &(a_rpcP->fsRPCTimes[currIdx]),
                           cm_outFD);

   fprintf(cm_outFD, "\nError Info:\n-----------\n");
   for (currIdx = 0; currIdx < AFS_STATS_NUM_FS_RPC_OPS; currIdx++)
      my_Print_cm_ErrInfo(currIdx, fsOpNames, &(a_rpcP->fsRPCErrors[currIdx]),
                          cm_outFD);

   fprintf(cm_outFD, "\nTransfer timings:\n-----------------\n");
   for (currIdx = 0; currIdx < AFS_STATS_NUM_FS_XFER_OPS; currIdx++)
      my_Print_cm_XferTiming(currIdx, xferOpNames,
                             &(a_rpcP->fsXferTimes[currIdx]), cm_outFD);

   fprintf(cm_outFD, "\nCM Operation Timings:\n---------------------\n");
   for (currIdx = 0; currIdx < AFS_STATS_NUM_CM_RPC_OPS; currIdx++)
      my_Print_cm_OpTiming(currIdx, cmOpNames, &(a_rpcP->cmRPCTimes[currIdx]),
                           cm_outFD);

}   /* my_Print_cm_RPCPerfInfo() */



/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_Print_cm_FullPerfInfo(xstat_cm_Results, cm_outFD)
   struct xstat_cm_ProbeResults xstat_cm_Results;
   FILE *cm_outFD;
{
   /* Ptr to authentication stats */
   struct afs_stats_AuthentInfo *authentP;
   /* Ptr to access stats */
   struct afs_stats_AccessInfo *accessinfP;
   /* Correct #longs */
   static afs_int32 fullPerfLongs = (sizeof(struct afs_stats_CMFullPerf) >> 2);
   /* # longs actually received */
   afs_int32 numLongs;
   /* Ptr to full perf info */
   struct afs_stats_CMFullPerf *fullP;
   /* Ptr to printable time string */
   char *printableTime;

   numLongs = xstat_cm_Results.data.AFSCB_CollData_len;

   if (numLongs != fullPerfLongs) {

      fprintf(cm_outFD,
              " ** Data size mismatch in performance collection!\n");
      fprintf(cm_outFD, " ** Expecting %d, got %d\n", fullPerfLongs,
              numLongs);
      return;
   }

   printableTime = ctime((time_t *) & (xstat_cm_Results.probeTime));
   printableTime[strlen(printableTime) - 1] = '\0';
   fullP = (struct afs_stats_CMFullPerf *)
      (xstat_cm_Results.data.AFSCB_CollData_val);

   fprintf(cm_outFD,
           "AFSCB_XSTATSCOLL_FULL_PERF_INFO (coll %d) for CM %s\n[Probe %d, %s]\n\n",
           xstat_cm_Results.collectionNumber,
           xstat_cm_Results.connP->hostName, xstat_cm_Results.probeNum,
           printableTime);

   /*
    * Print the overall numbers first, followed by all of the RPC numbers,
    * then each of the other groupings.
    */
   fprintf(cm_outFD,
           "Overall Performance Info:\n-------------------------\n");
   my_Print_cm_OverallPerfInfo(&(fullP->perf), cm_outFD);
   fprintf(cm_outFD, "\n");
   my_Print_cm_RPCPerfInfo(&(fullP->rpc), cm_outFD);

   authentP = &(fullP->authent);
   fprintf(cm_outFD, "\nAuthentication info:\n--------------------\n");
   fprintf(cm_outFD,
           "\t%d PAGS, %d records (%d auth, %d unauth), %d max in PAG, chain max: %d\n",
           authentP->curr_PAGs, authentP->curr_Records,
           authentP->curr_AuthRecords, authentP->curr_UnauthRecords,
           authentP->curr_MaxRecordsInPAG, authentP->curr_LongestChain);
   fprintf(cm_outFD, "\t%d PAG creations, %d tkt updates\n",
           authentP->PAGCreations, authentP->TicketUpdates);
   fprintf(cm_outFD,
           "\t[HWMs: %d PAGS, %d records, %d max in PAG, chain max: %d]\n",
           authentP->HWM_PAGs, authentP->HWM_Records,
           authentP->HWM_MaxRecordsInPAG, authentP->HWM_LongestChain);

   accessinfP = &(fullP->accessinf);
   fprintf(cm_outFD,
           "\n[Un]replicated accesses:\n------------------------\n");
   fprintf(cm_outFD,
           "\t%d unrep, %d rep, %d reps accessed, %d max reps/ref, %d first OK\n\n",
           accessinfP->unreplicatedRefs, accessinfP->replicatedRefs,
           accessinfP->numReplicasAccessed, accessinfP->maxReplicasPerRef,
           accessinfP->refFirstReplicaOK);

   /* There really isn't any authorship info
    * authorP = &(fullP->author); */
}   /* my_Print_cm_FullPerfInfo() */


/*
 * from src/afsmonitor/afsmon-output.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_afsmon_cmOutput(a_outfile, a_detOutput, xstat_cm_Results)
   char *a_outfile;             /* ptr to output file name */
   int a_detOutput;             /* detailed output ? */
   struct xstat_cm_ProbeResults xstat_cm_Results;
{

   char *printTime = 0;         /* ptr to time string */
   char *hostname = 0;          /* fileserner name */
   afs_int32 numLongs = 0;      /* longwords in result */
   afs_int32 *currLong = 0;     /* ptr to longwords in result */
   int i = 0;
   FILE *cm_outFD = 0;

   cm_outFD = fopen(a_outfile, "a");
   if (cm_outFD == (FILE *) NULL) {
      warn("failed to open output file %s", a_outfile);
      return;
   }

   /* get the probe time and strip the \n at the end */
   printTime = ctime((time_t *) & (xstat_cm_Results.probeTime));
   printTime[strlen(printTime) - 1] = '\0';
   hostname = xstat_cm_Results.connP->hostName;

   /* print "time hostname CM" prefix */
   fprintf(cm_outFD, "\n%s %s CM ", printTime, hostname);

   /* if probe failed print -1 and vanish */
   if (xstat_cm_Results.probeOK) {
      fprintf(cm_outFD, "-1\n");
      fclose(cm_outFD);
      return;
   }

   /* print out the probe information as  long words */
   numLongs = xstat_cm_Results.data.AFSCB_CollData_len;
   currLong = (afs_int32 *) (xstat_cm_Results.data.AFSCB_CollData_val);

   for (i = 0; i < numLongs; i++) {
      fprintf(cm_outFD, "%d ", *currLong++);
   }
   fprintf(cm_outFD, "\n\n");

   /* print detailed information */
   if (a_detOutput) {
      my_Print_cm_FullPerfInfo(xstat_cm_Results, cm_outFD);
      fflush(cm_outFD);
   }

   fclose(cm_outFD);

}   /* my_afsmon_cmOutput() */



/*
 * unchanged except for removing debugging print statements at beginning, and one
 * correction (replacing xstat_cm_Results with a_cmResults)
 *
 * from src/afsmonitor/afsmonitor.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_cm_Results_ltoa(a_cmData, a_cmResults)
   struct cm_Display_Data *a_cmData;    /* target buffer */
   struct xstat_cm_ProbeResults *a_cmResults;   /* ptr to xstat cm Results */
{
   struct afs_stats_CMFullPerf *fullP;  /* ptr to complete CM stats */
   afs_int32 *srcbuf;
   afs_int32 *tmpbuf;
   int i, j;
   int idx;
   afs_int32 numLongs;


   fullP = (struct afs_stats_CMFullPerf *)
      (a_cmResults->data.AFSCB_CollData_val);

   /* There are 4 parts to CM statistics
    * - Overall performance statistics (including up/down statistics)
    * - This CMs FS RPC operations info
    * - This CMs FS RPC errors info
    * - This CMs FS transfers info
    * - Authentication info
    * - [Un]Replicated access info
    */


   /* copy overall performance statistics */
   srcbuf = (afs_int32 *) & (fullP->perf);
   idx = 0;


   /* we skip the 19 entry, ProtServAddr, so the index must account for this */
   for (i = 0; i < NUM_AFS_STATS_CMPERF_LONGS + 1; i++) {
      if (i == 19) {
         srcbuf++;
         continue;  /* skip ProtServerAddr */
      }
      sprintf(a_cmData->data[idx], "%d", *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* server up/down statistics */
   /* copy file server up/down stats */
   srcbuf = (afs_int32 *) (fullP->perf.fs_UpDown);
   numLongs =
      2 * (sizeof(struct afs_stats_SrvUpDownInfo) / sizeof(afs_int32));
   for (i = 0; i < numLongs; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy volume location  server up/down stats */
   srcbuf = (afs_int32 *) (fullP->perf.vl_UpDown);
   numLongs =
      2 * (sizeof(struct afs_stats_SrvUpDownInfo) / sizeof(afs_int32));
   for (i = 0; i < numLongs; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy CMs individual FS RPC operations info */
   srcbuf = (afs_int32 *) (fullP->rpc.fsRPCTimes);
   for (i = 0; i < AFS_STATS_NUM_FS_RPC_OPS; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* numOps */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* numSuccesses */
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sum time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sqr time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* min time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* max time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy CMs individual FS RPC errors info */

   srcbuf = (afs_int32 *) (fullP->rpc.fsRPCErrors);
   for (i = 0; i < AFS_STATS_NUM_FS_RPC_OPS; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* server */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* network */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* prot */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* vol */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* busies */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* other */
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy CMs individual RPC transfers info */

   srcbuf = (afs_int32 *) (fullP->rpc.fsXferTimes);
   for (i = 0; i < AFS_STATS_NUM_FS_XFER_OPS; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* numOps */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* numSuccesses */
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sum time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sqr time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* min time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* max time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* sum bytes */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* min bytes */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* max bytes */
      idx++;
      srcbuf++;
      for (j = 0; j < AFS_STATS_NUM_XFER_BUCKETS; j++) {
         sprintf(a_cmData->data[idx], "%d", *srcbuf);   /* bucket[j] */
         idx++;
         srcbuf++;
      }
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy CM operations timings */

   srcbuf = (afs_int32 *) (fullP->rpc.cmRPCTimes);
   for (i = 0; i < AFS_STATS_NUM_CM_RPC_OPS; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* numOps */
      idx++;
      srcbuf++;
      sprintf(a_cmData->data[idx], "%d", *srcbuf);  /* numSuccesses */
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sum time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* sqr time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* min time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
      tmpbuf = srcbuf++;    /* max time */
      sprintf(a_cmData->data[idx], "%d.%06d", *tmpbuf, *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy authentication info */

   srcbuf = (afs_int32 *) & (fullP->authent);
   numLongs = sizeof(struct afs_stats_AuthentInfo) / sizeof(afs_int32);
   for (i = 0; i < numLongs; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */

   /* copy CM [un]replicated access info */

   srcbuf = (afs_int32 *) & (fullP->accessinf);
   numLongs = sizeof(struct afs_stats_AccessInfo) / sizeof(afs_int32);
   for (i = 0; i < numLongs; i++) {
      sprintf(a_cmData->data[idx], "%d", *srcbuf);
      idx++;
      srcbuf++;
   }

   /*printf("Ending index value = %d\n",idx-1); */
   return (0);

}   /* my_cm_Results_ltoa() */




/* cm_Results_to_Hash() */

void
cm_Results_to_Hash(struct cm_Display_Data *cmData, HV *HOSTINFO,
                   short *showFlags, int showDefault)
{
   int secidx;
   int grpidx;
   int numgrp;
   int fromidx;
   int toidx;
   char section[CFG_STR_LEN] = "";
   char group[CFG_STR_LEN] = "";
   HV *ENTRY;
   HV *GROUP;
   HV *SECTION;
   int i;

   secidx = 0;
   grpidx = secidx + 1;

   while (secidx < CM_NUM_DATA_CATEGORIES) {

      sscanf(cm_categories[secidx], "%s %d", section, &numgrp);
      SECTION = newHV();

      while (grpidx <= secidx + numgrp) {
         GROUP = newHV();
         sscanf(cm_categories[grpidx], "%s %d %d", group, &fromidx, &toidx);
         for (i = fromidx; i <= toidx; i++) {
            if (showFlags[i] || showDefault) {
               ENTRY = newHV();
               hv_store(ENTRY, "value", 5, newSVnv(atof(cmData->data[i])), 0);
               hv_store(GROUP, cm_varNames[i], strlen(cm_varNames[i]),
                        newRV_inc((SV *) ENTRY), 0);
            }
         }
         if (HvKEYS(GROUP))
            hv_store(SECTION, group, strlen(group), newRV_inc((SV *) GROUP),
                     0);
         grpidx++;
      }
      if (HvKEYS(SECTION))
         hv_store(HOSTINFO, section, strlen(section),
                  newRV_inc((SV *) SECTION), 0);
      secidx += numgrp + 1;
      grpidx = secidx + 1;
   }
}   /* cm_Results_to_Hash() */



/*
 * from src/afsmonitor/afsmonitor.c:
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_save_CM_data_forDisplay(a_cmResults, HOSTINFO, numCM, CMnameList,
                           cm_showFlags, cm_showDefault, buffer)
   struct xstat_cm_ProbeResults *a_cmResults;
   HV *HOSTINFO;
   int numCM;
   struct afsmon_hostEntry *CMnameList;
   short *cm_showFlags;
   int cm_showDefault;
   char *buffer;
{
   struct cm_Display_Data *curr_cmDataP;
   struct afsmon_hostEntry *curr_host = 0;
   int i = 0;
   int code = 0;
   int done = 0;
   char buff2[256] = "";

   curr_cmDataP =
      (struct cm_Display_Data *)malloc(sizeof(struct cm_Display_Data));
   if (curr_cmDataP == (struct cm_Display_Data *) NULL) {
      sprintf(buffer, "Memory allocation failure");
      return (-10);
   }
   memset(curr_cmDataP, 0, sizeof(struct cm_Display_Data));

   hv_store(HOSTINFO, "hostName", 8, newSVpv(a_cmResults->connP->hostName, 0),
            0);

   /*  Check the status of the probe. If it succeeded, we store its
    * results in the display data structure. If it failed we only mark
    * the failed status in the display data structure. */

   if (a_cmResults->probeOK) {  /* 1 => notOK the xstat results */
      hv_store(HOSTINFO, "probeOK", 7, newSViv(0), 0);
   }
   else {   /* probe succeeded, update display data structures */
      hv_store(HOSTINFO, "probeOK", 7, newSViv(1), 0);

      my_cm_Results_ltoa(curr_cmDataP, a_cmResults);

      cm_Results_to_Hash(curr_cmDataP, HOSTINFO, cm_showFlags,
                         cm_showDefault);

      done = 0;
      curr_host = CMnameList;
      for (i = 0; i < numCM; i++) {
         if (strcasecmp(curr_host->hostName, a_cmResults->connP->hostName)
             == 0) {
            done = 1;
            break;
         }
         curr_host = curr_host->next;;
      }
      if (!done) {
         sprintf(buffer, "Error storing results for CM host %s (100)",
                 a_cmResults->connP->hostName);
         return (100);
      }

      code = my_check_thresholds(curr_host, HOSTINFO, CM, buff2);
      if (code) {
         sprintf(buffer, "Error in checking thresholds (105) %s", buff2);
         return (105);
      }

   }

   return (0);
}   /* my_save_CM_data_forDisplay() */



/*
 * from src/afsmonitor/afsmonitor.c:
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_afsmon_CM_Handler(xstat_cm_Results, numCM, conn_idx, buffer, argp)
   struct xstat_cm_ProbeResults xstat_cm_Results;
   int numCM;
   int conn_idx;
   char *buffer;
   va_list argp;
{
   int code = 0;

   char *outputfile = va_arg(argp, char *);
   int detailed = va_arg(argp, int);
   AV *CACHEMAN = va_arg(argp, AV *);
   struct afsmon_hostEntry *CMnameList =
      va_arg(argp, struct afsmon_hostEntry *);
   short *cm_showFlags = va_arg(argp, short *);
   int cm_showDefault = va_arg(argp, int);

   HV *HOSTINFO = newHV();

   if (outputfile) {
      my_afsmon_cmOutput(outputfile, detailed, xstat_cm_Results);
   }

   /* add everything to data structure */
   code =
      my_save_CM_data_forDisplay(&xstat_cm_Results, HOSTINFO, numCM,
                                 CMnameList, cm_showFlags, cm_showDefault,
                                 buffer);
   if (code) {
      return (code);
   }

   /* Add HOSTINFO to CM */
   av_store(CACHEMAN, conn_idx, newRV_inc((SV *) HOSTINFO));
   return (0);
}   /* my_afsmon_CM_Handler() */




/*
 * from src/xstat/xstat_cm.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_cm_LWP(ProbeHandler, xstat_cm_ConnInfo, xstat_cm_numServers,
                xstat_cm_collIDP, xstat_cm_numCollections, buffer, argp)
   int (*ProbeHandler) ();
   struct xstat_cm_ConnectionInfo *xstat_cm_ConnInfo;
   int xstat_cm_numServers;
   afs_int32 *xstat_cm_collIDP;
   int xstat_cm_numCollections;
   char *buffer;
   va_list argp;
{
   afs_int32 srvVersionNumber = 0;  /*Xstat version # */
   afs_int32 clientVersionNumber = AFSCB_XSTAT_VERSION; /*Client xstat version */
   afs_int32 *currCollIDP = 0;
   int numColls = 0;
   int conn_idx = 0;
   struct xstat_cm_ConnectionInfo *curr_conn = 0;
   char buff2[256] = "";
   int code = 0;
   int index = 0;

   struct xstat_cm_ProbeResults xstat_cm_Results;
   afs_int32 xstat_cmData[AFSCB_MAX_XSTAT_LONGS];
   xstat_cm_Results.probeTime = 0;
   xstat_cm_Results.connP = (struct xstat_cm_ConnectionInfo *) NULL;
   xstat_cm_Results.collectionNumber = 0;
   xstat_cm_Results.data.AFSCB_CollData_len = AFSCB_MAX_XSTAT_LONGS;
   xstat_cm_Results.data.AFSCB_CollData_val = (afs_int32 *) xstat_cmData;
   xstat_cm_Results.probeOK = 0;

   curr_conn = xstat_cm_ConnInfo;
   for (conn_idx = 0; conn_idx < xstat_cm_numServers; conn_idx++) {
      /*
       * Grab the statistics for the current File Server, if the
       * connection is valid.
       */
      if (curr_conn->rxconn != (struct rx_connection *) NULL) {

         currCollIDP = xstat_cm_collIDP;
         for (numColls = 0;
              numColls < xstat_cm_numCollections; numColls++, currCollIDP++) {
            /*
             * Initialize the per-probe values.
             */
            xstat_cm_Results.collectionNumber = *currCollIDP;
            xstat_cm_Results.data.AFSCB_CollData_len = AFSCB_MAX_XSTAT_LONGS;
            memset(xstat_cm_Results.data.AFSCB_CollData_val, 0,
                   AFSCB_MAX_XSTAT_LONGS * 4);

            xstat_cm_Results.connP = curr_conn;

            xstat_cm_Results.probeOK =
               RXAFSCB_GetXStats(curr_conn->rxconn,
                                 clientVersionNumber, *currCollIDP,
                                 &srvVersionNumber,
                                 &(xstat_cm_Results.probeTime),
                                 &(xstat_cm_Results.data));

            code =
               ProbeHandler(xstat_cm_Results, xstat_cm_numServers, index,
                            buff2, argp);
            index++;

            if (code) {
               sprintf(buffer, "Handler routine got error code %d. %s",
                       code, buff2);
               return (code);
            }

         }  /* For each collection */
      } /*Valid Rx connection */

      /*
       * Advance the xstat_fs connection pointer.
       */
      curr_conn++;

   }    /* For each xstat_cm connection */
   return (0);
}   /* my_xstat_cm_LWP() */



/*
 * from src/xstat/xstat_cm.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_cm_Init(int (*ProbeHandler) (), int xstat_cm_numServers,
                 struct sockaddr_in *a_socketArray,
                 int xstat_cm_numCollections, afs_int32 * xstat_cm_collIDP,
                 char *buffer, ...)
{
   int curr_srv = 0;
   int conn_err = 0;
   char *hostNameFound = "";
   struct xstat_cm_ConnectionInfo *curr_conn = 0, *xstat_cm_ConnInfo = 0;
   struct rx_securityClass *secobj = 0; /*Client security object */
   char buff2[256] = "";
   int code = 0;
   va_list argp;

   xstat_cm_ConnInfo = (struct xstat_cm_ConnectionInfo *)
      malloc(xstat_cm_numServers * sizeof(struct xstat_cm_ConnectionInfo));
   if (xstat_cm_ConnInfo == (struct xstat_cm_ConnectionInfo *) NULL) {
      sprintf(buffer,
              "Can't allocate %d connection info structs (%d bytes)",
              xstat_cm_numServers,
              (xstat_cm_numServers * sizeof(struct xstat_cm_ConnectionInfo)));
      return (-1);  /*No cleanup needs to be done yet */
   }

   code = rx_Init(htons(0));
   if (code) {
      sprintf(buffer, "Fatal error in rx_Init(), error=%d", code);
      return (-1);
   }

    /*
     * Create a null Rx client security object, to be used by the
     * probe LWP.
     */
   secobj = rxnull_NewClientSecurityObject();
   if (secobj == (struct rx_securityClass *) NULL) {
      /*Delete already-malloc'ed areas */
      my_xstat_cm_Cleanup(1, xstat_cm_numServers, xstat_cm_ConnInfo, buff2);
      sprintf(buffer, "Can't create probe LWP client security object. %s",
              buff2);
      return (-1);
   }

   curr_conn = xstat_cm_ConnInfo;
   conn_err = 0;
   for (curr_srv = 0; curr_srv < xstat_cm_numServers; curr_srv++) {
      /*
       * Copy in the socket info for the current server, resolve its
       * printable name if possible.
       */

      memcpy(&(curr_conn->skt), a_socketArray + curr_srv,
             sizeof(struct sockaddr_in));

      hostNameFound = hostutil_GetNameByINet(curr_conn->skt.sin_addr.s_addr);
      if (hostNameFound == NULL) {
         warn("Can't map Internet address %lu to a string name",
              curr_conn->skt.sin_addr.s_addr);
         curr_conn->hostName[0] = '\0';
      }
      else {
         strcpy(curr_conn->hostName, hostNameFound);
      }

      /*
       * Make an Rx connection to the current server.
       */

      curr_conn->rxconn = rx_NewConnection(curr_conn->skt.sin_addr.s_addr,  /*Server addr */
                                           curr_conn->skt.sin_port, /*Server port */
                                           1,   /*AFS service # */
                                           secobj,  /*Security obj */
                                           0);  /*# of above */
      if (curr_conn->rxconn == (struct rx_connection *) NULL) {
         sprintf(buffer,
                 "Can't create Rx connection to server '%s' (%lu)",
                 curr_conn->hostName, curr_conn->skt.sin_addr.s_addr);
         my_xstat_cm_Cleanup(1, xstat_cm_numServers, xstat_cm_ConnInfo,
                             buff2);
         return (-2);
      }
      /*
       * Bump the current xstat_fs connection to set up.
       */
      curr_conn++;

   }    /*for curr_srv */


   va_start(argp, buffer);
   code =
      my_xstat_cm_LWP(ProbeHandler, xstat_cm_ConnInfo, xstat_cm_numServers,
                      xstat_cm_collIDP, xstat_cm_numCollections, buffer,
                      argp);
   va_end(argp);

   if (code) {
      return (code);
   }
   my_xstat_cm_Cleanup(1, xstat_cm_numServers, xstat_cm_ConnInfo, buff2);
   return (0);


}   /* my_xstat_cm_Init() */


/*
 * from src/xstat/xstat_cm.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_cm_Cleanup(int a_releaseMem, int xstat_cm_numServers,
                    struct xstat_cm_ConnectionInfo *xstat_cm_ConnInfo,
                    char *buffer)
{
   int code = 0;                /*Return code */
   int conn_idx = 0;            /*Current connection index */
   struct xstat_cm_ConnectionInfo *curr_conn = 0;   /*Ptr to xstat_fs connection */

   /*
    * Take care of all Rx connections first.  Check to see that the
    * server count is a legal value.
    */
   if (xstat_cm_numServers <= 0) {
      sprintf(buffer,
              "Illegal number of servers (xstat_cm_numServers = %d)",
              xstat_cm_numServers);
      code = -1;
   }
   else {
      if (xstat_cm_ConnInfo != (struct xstat_cm_ConnectionInfo *) NULL) {
         /*
          * The xstat_fs connection structure array exists.  Go through
          * it and close up any Rx connections it holds.
          */
         curr_conn = xstat_cm_ConnInfo;
         for (conn_idx = 0; conn_idx < xstat_cm_numServers; conn_idx++) {
            if (curr_conn->rxconn != (struct rx_connection *) NULL) {
               rx_DestroyConnection(curr_conn->rxconn);
               curr_conn->rxconn = (struct rx_connection *) NULL;
            }
            curr_conn++;
         }  /*for each xstat_cm connection */
      } /*xstat_cm connection structure exists */
   }    /*Legal number of servers */

   /*
    * If asked to, release the space we've allocated.
    */
   if (a_releaseMem) {
      if (xstat_cm_ConnInfo != (struct xstat_cm_ConnectionInfo *) NULL)
         free(xstat_cm_ConnInfo);
   }

   /*
    * Return the news, whatever it is.
    */
   return (code);

}   /* my_xstat_cm_Cleanup() */



/* end of afsmonitor helper functions */



/* cmdebug helper functions */

/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static int
IsLocked(register struct AFSDBLockDesc *alock)
{
    if (alock->waitStates || alock->exclLocked || alock->numWaiting
        || alock->readersReading)
        return 1;
    return 0;
}


/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

struct cell_cache {
   afs_int32 cellnum;
   char *cellname;
   struct cell_cache *next;
};


/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

#ifdef USE_GETCELLNAME
static char *
GetCellName(struct rx_connection *aconn, afs_int32 cellnum)
{
   static int no_getcellbynum;
   static struct cell_cache *cache;
   struct cell_cache *tcp;
   int code;
   char *cellname;
   serverList sl;

   if (no_getcellbynum)
      return NULL;

   for (tcp = cache; tcp; tcp = tcp->next)
      if (tcp->cellnum == cellnum)
         return tcp->cellname;

   cellname = NULL;
   sl.serverList_len = 0;
   sl.serverList_val = NULL;
   code = RXAFSCB_GetCellByNum(aconn, cellnum, &cellname, &sl);
   if (code) {
      if (code == RXGEN_OPCODE)
         no_getcellbynum = 1;
      return NULL;
   }

   if (sl.serverList_val)
      free(sl.serverList_val);
   tcp = malloc(sizeof(struct cell_cache));
   tcp->next = cache;
   tcp->cellnum = cellnum;
   tcp->cellname = cellname;
   cache = tcp;

   return cellname;
}
#endif


/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintLock(register struct AFSDBLockDesc *alock, HV *LOCK)
{
   hv_store(LOCK, "waitStates", 10, newSViv(alock->waitStates), 0);
   hv_store(LOCK, "exclLocked", 10, newSViv(alock->exclLocked), 0);
   hv_store(LOCK, "pid_writer", 10, newSViv(alock->pid_writer), 0);
   hv_store(LOCK, "src_indicator", 13, newSViv(alock->src_indicator), 0);
   hv_store(LOCK, "readersReading", 14, newSViv(alock->readersReading), 0);
   hv_store(LOCK, "pid_last_reader", 15, newSViv(alock->pid_last_reader), 0);
   hv_store(LOCK, "numWaiting", 10, newSViv(alock->numWaiting), 0);
}


/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_PrintLocks(register struct rx_connection *aconn, int aint32,
              AV *LOCKS, char *buffer)
{
   register int i;
   struct AFSDBLock lock;
   afs_int32 code;
   HV *LOCK;
   HV *LOCKDESC;

   for (i = 0; i < 1000; i++) {
      code = RXAFSCB_GetLock(aconn, i, &lock);
      if (code) {
         if (code == 1)
            break;
         /* otherwise we have an unrecognized error */
         sprintf(buffer, "cmdebug: error checking locks: %s",
                 error_message(code));
         return code;
      }
      /* here we have the lock information, so display it, perhaps */
      if (aint32 || IsLocked(&lock.lock)) {
         LOCK = newHV();
         hv_store(LOCK, "name", 4, newSVpv(lock.name, 0), 0);
         LOCKDESC = newHV();
         my_PrintLock(&lock.lock, LOCKDESC);
         hv_store(LOCK, "lock", 4, newRV_inc((SV *) LOCKDESC), 0);
         av_store(LOCKS, i, newRV_inc((SV *) LOCK));
      }
   }
   return 0;
}

#ifdef OpenAFS_1_2
int
my_PrintCacheEntries(aconn, aint32, CACHE_ENTRIES, buffer)
   register struct rx_connection *aconn;
   int aint32;
   AV *CACHE_ENTRIES;
   char *buffer;
{
   register int i;
   register afs_int32 code;
   struct AFSDBCacheEntry centry;
   char *cellname;
   HV *NETFID;
   HV *CENTRY;
   HV *LOCK;

   for (i = 0; i < 10000; i++) {
      code = RXAFSCB_GetCE(aconn, i, &centry);
      if (code) {
         if (code == 1)
            break;
         sprintf(buffer, "cmdebug: failed to get cache entry %d (%s)", i,
                 error_message(code));
         return code;
      }

      CENTRY = newHV();

      hv_store(CENTRY, "addr", 4, newSViv(centry.addr), 0);

      if (centry.addr == 0) {
         /* PS output */
         NETFID = newHV();
         hv_store(NETFID, "Vnode", 5, newSViv(centry.netFid.Vnode), 0);
         hv_store(NETFID, "Volume", 6, newSViv(centry.netFid.Volume), 0);
         hv_store(NETFID, "Unique", 6, newSViv(centry.netFid.Unique), 0);
         hv_store(CENTRY, "netFid", 6, newRV_inc((SV *) NETFID), 0);
         av_store(CACHE_ENTRIES, i, newRV_inc((SV *) CENTRY));
         continue;
      }

      if (!aint32 && !IsLocked(&centry.lock))
         continue;

      hv_store(CENTRY, "cell", 4, newSViv(centry.cell), 0);
      NETFID = newHV();
      hv_store(NETFID, "Vnode", 5, newSViv(centry.netFid.Vnode), 0);
      hv_store(NETFID, "Volume", 6, newSViv(centry.netFid.Volume), 0);
      hv_store(NETFID, "Unique", 6, newSViv(centry.netFid.Unique), 0);
      hv_store(CENTRY, "netFid", 6, newRV_inc((SV *) NETFID), 0);

#ifdef USE_GETCELLNAME
      cellname = GetCellName(aconn, centry.cell);
      if (cellname)
         hv_store(CENTRY, "cellname", 8, newSVpv(cellname, 0), 0);
#endif

      if (IsLocked(&centry.lock)) {
         LOCK = newHV();
         my_PrintLock(&centry.lock, LOCK);
         hv_store(CENTRY, "lock", 4, newRV_inc((SV *) LOCK), 0);
      }

      hv_store(CENTRY, "Length", 6, newSViv(centry.Length), 0);
      hv_store(CENTRY, "DataVersion", 11, newSViv(centry.DataVersion), 0);
      hv_store(CENTRY, "refCount", 8, newSViv(centry.refCount), 0);
      hv_store(CENTRY, "callback", 8, newSViv(centry.callback), 0);
      hv_store(CENTRY, "cbExpires", 9, newSViv(centry.cbExpires), 0);
      hv_store(CENTRY, "opens", 5, newSViv(centry.opens), 0);
      hv_store(CENTRY, "writers", 7, newSViv(centry.writers), 0);

      /* now display states */
      hv_store(CENTRY, "mvstat", 6, newSViv(centry.mvstat), 0);

      hv_store(CENTRY, "states", 6, newSViv(centry.states), 0);
      av_store(CACHE_ENTRIES, i, newRV_inc((SV *) CENTRY));
   }
   return 0;
}
#endif		/* ifdef OpenAFS_1_2 */



#ifdef OpenAFS_1_4
/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
PrintCacheEntries32(struct rx_connection *aconn, int aint32,
                    AV *CACHE_ENTRIES, char *buffer)
{
    register int i;
    register afs_int32 code;
    struct AFSDBCacheEntry centry;
    char *cellname;
    HV *NETFID;
    HV *CENTRY;
    HV *LOCK;

    for (i = 0; i < 10000; i++) {
        code = RXAFSCB_GetCE(aconn, i, &centry);
        if (code) {
            if (code == 1)
                break;
            sprintf(buffer, "cmdebug: failed to get cache entry %d (%s)\n", i,
                   error_message(code));
            return code;
        }

        CENTRY = newHV();

        hv_store(CENTRY, "addr", 4, newSViv(centry.addr), 0);

        if (centry.addr == 0) {
            /* PS output */
            printf("Proc %4d sleeping at %08x, pri %3d\n",
                   centry.netFid.Vnode, centry.netFid.Volume,
                   centry.netFid.Unique - 25);
            continue;
        }

        if (((aint32 == 0) && !IsLocked(&centry.lock)) ||
            ((aint32 == 2) && (centry.refCount == 0)) ||
            ((aint32 == 4) && (centry.callback == 0)))
            continue;

        /* otherwise print this entry */
        hv_store(CENTRY, "cell", 4, newSViv(centry.cell), 0);
        NETFID = newHV();
        hv_store(NETFID, "Vnode", 5, newSViv(centry.netFid.Vnode), 0);
        hv_store(NETFID, "Volume", 6, newSViv(centry.netFid.Volume), 0);
        hv_store(NETFID, "Unique", 6, newSViv(centry.netFid.Unique), 0);
        hv_store(CENTRY, "netFid", 6, newRV_inc((SV *) NETFID), 0);

#ifdef USE_GETCELLNAME
        cellname = GetCellName(aconn, centry.cell);
        if (cellname)
            hv_store(CENTRY, "cellname", 8, newSVpv(cellname, 0), 0);
#endif

        if (IsLocked(&centry.lock)) {
            LOCK = newHV();
            my_PrintLock(&centry.lock, LOCK);
            hv_store(CENTRY, "lock", 4, newRV_inc((SV *) LOCK), 0);
        }
        hv_store(CENTRY, "Length",       6, newSViv(centry.Length), 0);
        hv_store(CENTRY, "DataVersion", 11, newSViv(centry.DataVersion), 0);
        hv_store(CENTRY, "refCount",     8, newSViv(centry.refCount), 0);
        hv_store(CENTRY, "callback",     8, newSViv(centry.callback), 0);
        hv_store(CENTRY, "cbExpires",    9, newSViv(centry.cbExpires), 0);
        hv_store(CENTRY, "opens",        5, newSViv(centry.opens), 0);
        hv_store(CENTRY, "writers",      7, newSViv(centry.writers), 0);


        /* now display states */
        hv_store(CENTRY, "mvstat", 6, newSViv(centry.mvstat), 0);

        hv_store(CENTRY, "states", 6, newSViv(centry.states), 0);
        av_store(CACHE_ENTRIES, i, newRV_inc((SV *) CENTRY));
    }
    return 0;
}


/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
PrintCacheEntries64(struct rx_connection *aconn, int aint32,
                    AV *CACHE_ENTRIES, char *buffer)
{
    register int i;
    register afs_int32 code;
    struct AFSDBCacheEntry64 centry;
    char *cellname;
    char *data_name;
    HV *NETFID;
    HV *CENTRY;
    HV *LOCK;

    for (i = 0; i < 10000; i++) {
        code = RXAFSCB_GetCE64(aconn, i, &centry);
        if (code) {
            if (code == 1)
                break;
            sprintf(buffer, "cmdebug: failed to get cache entry %d (%s)\n", i,
                   error_message(code));
            return code;
        }

        CENTRY = newHV();

        hv_store(CENTRY, "addr", 4, newSViv(centry.addr), 0);

        if (centry.addr == 0) {
            /* PS output */
            NETFID = newHV();
            hv_store(NETFID, "Vnode", 5, newSViv(centry.netFid.Vnode), 0);
            hv_store(NETFID, "Volume", 6, newSViv(centry.netFid.Volume), 0);
            hv_store(NETFID, "Unique", 6, newSViv(centry.netFid.Unique-25), 0);
            hv_store(CENTRY, "netFid", 6, newRV_inc((SV *) NETFID), 0);
            av_store(CACHE_ENTRIES, i, newRV_inc((SV *) CENTRY));
            continue;
        }

        if (((aint32 == 0) && !IsLocked(&centry.lock)) ||
            ((aint32 == 2) && (centry.refCount == 0)) ||
            ((aint32 == 4) && (centry.callback == 0)))
            continue;

        /* otherwise print this entry */
        hv_store(CENTRY, "cell", 4, newSViv(centry.cell), 0);
        NETFID = newHV();
        hv_store(NETFID, "Vnode", 5, newSViv(centry.netFid.Vnode), 0);
        hv_store(NETFID, "Volume", 6, newSViv(centry.netFid.Volume), 0);
        hv_store(NETFID, "Unique", 6, newSViv(centry.netFid.Unique), 0);
        hv_store(CENTRY, "netFid", 6, newRV_inc((SV *) NETFID), 0);

#ifdef USE_GETCELLNAME
        cellname = GetCellName(aconn, centry.cell);
        if (cellname)
            hv_store(CENTRY, "cellname", 8, newSVpv(cellname, 0), 0);
#endif

        if (IsLocked(&centry.lock)) {
            LOCK = newHV();
            my_PrintLock(&centry.lock, LOCK);
            hv_store(CENTRY, "lock", 4, newRV_inc((SV *) LOCK), 0);
        }

        hv_store(CENTRY, "Length",       6, newSViv(centry.Length), 0);
        hv_store(CENTRY, "DataVersion", 11, newSViv(centry.DataVersion), 0);
        hv_store(CENTRY, "refCount",     8, newSViv(centry.refCount), 0);
        hv_store(CENTRY, "callback",     8, newSViv(centry.callback), 0);
        hv_store(CENTRY, "cbExpires",    9, newSViv(centry.cbExpires), 0);
        hv_store(CENTRY, "opens",        5, newSViv(centry.opens), 0);
        hv_store(CENTRY, "writers",      7, newSViv(centry.writers), 0);

        /* now display states */
        if (centry.mvstat == 0)
            data_name = "normal file";
        else if (centry.mvstat == 1)
            data_name = "mount point";
        else if (centry.mvstat == 2)
            data_name = "volume root";
        else if (centry.mvstat == 3)
            data_name = "directory";
        else if (centry.mvstat == 4)
            data_name = "symlink";
        else if (centry.mvstat == 5)
            data_name = "microsoft dfs link";
        else if (centry.mvstat == 6)
            data_name = "invalid link";
        else
            data_name = "bogus mvstat";
        hv_store(CENTRY, "mvstat", 6, newSVpv(data_name, strlen(data_name)), 0);

        data_name = "";
        if (centry.states & 1)
            sprintf(data_name, "%s, stat'd", data_name);
        if (centry.states & 2)
            sprintf(data_name, "%s, backup", data_name);
        if (centry.states & 4)
            sprintf(data_name, "%s, read-only", data_name);
        if (centry.states & 8)
            sprintf(data_name, "%s, mt pt valid", data_name);
        if (centry.states & 0x10)
            sprintf(data_name, "%s, pending core", data_name);
        if (centry.states & 0x40)
            sprintf(data_name, "%s, wait-for-store", data_name);
        if (centry.states & 0x80)
            sprintf(data_name, "%s, mapped", data_name);
        hv_store(CENTRY, "states", 6, newSVpv(data_name, strlen(data_name)), 0);

        av_store(CACHE_ENTRIES, i, newRV_inc((SV *) CENTRY));
    }
    return 0;
}


/*
 * from src/venus/cmdebug.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_PrintCacheEntries(struct rx_connection *aconn, int aint32,
                     AV *CACHE_ENTRIES, char *buffer)
{
    register afs_int32 code;
    struct AFSDBCacheEntry64 centry64;

    code = RXAFSCB_GetCE64(aconn, 0, &centry64);
    if (code != RXGEN_OPCODE)
        return PrintCacheEntries64(aconn, aint32, CACHE_ENTRIES, buffer);
    else
        return PrintCacheEntries32(aconn, aint32, CACHE_ENTRIES, buffer);
}
#endif		/* ifdef OpenAFS_1_4 */


/* end of cmdebug helper functions */



/* udebug helper functions */

/*
 * from src/ubik/ubik.h
 *
 */

#define MAXSKEW  10


/*
 * from src/ubik/udebug.c
 *     ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static short
udebug_PortNumber(register char *aport)
{
       register int tc;
    register afs_int32 total;

    total = 0;
    while ((tc = *aport++)) {
        if (tc < '0' || tc > '9')
            return -1;          /* bad port number */
        total *= 10;
        total += tc - (int)'0';
    }
    return (total);
}


/*
 * from src/ubik/udebug.c
 *     ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static short
udebug_PortName(char *aname)
{
    struct servent *ts;
    int len;

    ts = getservbyname(aname, NULL);

    if (ts)
        return ntohs(ts->s_port);       /* returns it in host byte order */

    len = strlen(aname);
    if (strncmp(aname, "vlserver", len) == 0) {
        return 7003;
    } else if (strncmp(aname, "ptserver", len) == 0) {
        return 7002;
    } else if (strncmp(aname, "kaserver", len) == 0) {
        return 7004;
    } else if (strncmp(aname, "buserver", len) == 0) {
        return 7021;
    }
    return (-1);
}


/* end of udebug helper functions */





/* scout helper functions */


/*
 * from src/fsprobe/fsprobe.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

#define FSPROBE_CBPORT  7101

extern int RXAFSCB_ExecuteRequest();

int
my_fsprobe_LWP(fsprobe_numServers, fsprobe_ConnInfo, fsprobe_Results,
               fsprobe_statsBytes, fsprobe_probeOKBytes,
               scout_debugfd, RETVAL, buffer)
   int fsprobe_numServers;
   struct fsprobe_ConnectionInfo *fsprobe_ConnInfo;
   struct fsprobe_ProbeResults *fsprobe_Results;
   int fsprobe_statsBytes;
   int fsprobe_probeOKBytes;
   FILE *scout_debugfd;
   AV *RETVAL;
   char *buffer;
{
   static char rn[] = "fsprobe_LWP";    /*Routine name */
   register afs_int32 code = 0; /*Results of calls */
   int conn_idx;                /*Connection index */
   struct fsprobe_ConnectionInfo *curr_conn;    /*Current connection */
   struct ProbeViceStatistics *curr_stats;  /*Current stats region */
   int *curr_probeOK;           /*Current probeOK field */
   int i;

   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Called\n", rn);
      fprintf(scout_debugfd,
              "[%s] Collecting data from %d connected servers\n", rn,
              fsprobe_numServers);
      fflush(scout_debugfd);
   }
   curr_conn = fsprobe_ConnInfo;
   curr_stats = fsprobe_Results->stats;
   curr_probeOK = fsprobe_Results->probeOK;
   fsprobe_Results->probeNum++;
   memset(fsprobe_Results->stats, 0, fsprobe_statsBytes);
   memset(fsprobe_Results->probeOK, 0, fsprobe_probeOKBytes);

   for (conn_idx = 0; conn_idx < fsprobe_numServers; conn_idx++) {
      /*
       * Grab the statistics for the current FileServer, if the
       * connection is valid.
       */
      if (scout_debugfd) {
         fprintf(scout_debugfd, "[%s] Contacting server %s\n", rn,
                 curr_conn->hostName);
         fflush(scout_debugfd);
      }
      if (curr_conn->rxconn != (struct rx_connection *) NULL) {
         if (scout_debugfd) {
            fprintf(scout_debugfd,
                    "[%s] Connection valid, calling RXAFS_GetStatistics\n",
                    rn);
            fflush(scout_debugfd);
         }
         *curr_probeOK = RXAFS_GetStatistics(curr_conn->rxconn, (struct ViceStatistics *)curr_stats);

      } /*Valid Rx connection */

      /*
       * Call the Volume Server too to get additional stats
       */
      if (scout_debugfd) {
         fprintf(scout_debugfd, "[%s] Contacting volume server %s\n", rn,
                 curr_conn->hostName);
         fflush(scout_debugfd);
      }
      if (curr_conn->rxVolconn != (struct rx_connection *) NULL) {
         char pname[10];
         struct diskPartition partition;

         if (scout_debugfd) {
            fprintf(scout_debugfd,
                    "[%s] Connection valid, calling RXAFS_GetStatistics\n",
                    rn);
            fflush(scout_debugfd);
         }
         for (i = 0; i < curr_conn->partCnt; i++) {
            if (curr_conn->partList.partFlags[i] & PARTVALID) {
               MapPartIdIntoName(curr_conn->partList.partId[i], pname);
               code =
                  AFSVolPartitionInfo(curr_conn->rxVolconn, pname,
                                      &partition);
               if (code) {
                  sprintf(buffer,
                          "Could not get information on server %s partition %s",
                          curr_conn->hostName, pname);
               }
               else {
                  curr_stats->Disk[i].BlocksAvailable = partition.free;
                  curr_stats->Disk[i].TotalBlocks = partition.minFree;
                  strcpy(curr_stats->Disk[i].Name, pname);
               }
            }
         }
      }

      /*
       * Advance the fsprobe connection pointer & stats pointer.
       */
      curr_conn++;
      curr_stats++;
      curr_probeOK++;

   }    /*For each fsprobe connection */

   return (code);
}   /* my_fsprobe_LWP */


/*
 * from src/fsprobe/fsprobe.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_XListPartitions(aconn, ptrPartList, cntp, scout_debugfd)
   struct rx_connection *aconn;
   struct partList *ptrPartList;
   afs_int32 *cntp;
   FILE *scout_debugfd;
{
   struct pIDs partIds;
   struct partEntries partEnts;
   register int i, j = 0, code;
   static int newvolserver = 0;

   static char rn[] = "my_XListPartitions";
   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Called\n", rn);
      fflush(scout_debugfd);
   }

   *cntp = 0;
   if (newvolserver == 1) {
      for (i = 0; i < 26; i++)
         partIds.partIds[i] = -1;
    tryold:
      code = AFSVolListPartitions(aconn, &partIds);
      if (!code) {
         for (i = 0; i < 26; i++) {
            if ((partIds.partIds[i]) != -1) {
               ptrPartList->partId[j] = partIds.partIds[i];
               ptrPartList->partFlags[j] = PARTVALID;
               j++;
            }
            else
               ptrPartList->partFlags[i] = 0;
         }
         *cntp = j;
      }
      goto out;
   }
   partEnts.partEntries_len = 0;
   partEnts.partEntries_val = (afs_int32 *) NULL;
   code = AFSVolXListPartitions(aconn, &partEnts);
   if (!newvolserver) {
      if (code == RXGEN_OPCODE) {
         newvolserver = 1;  /* Doesn't support new interface */
         goto tryold;
      }
      else if (!code) {
         newvolserver = 2;
      }
   }
   if (!code) {
      *cntp = partEnts.partEntries_len;
      if (*cntp > VOLMAXPARTS) {
         warn
            ("Warning: number of partitions on the server too high %d (process only %d)\n",
             *cntp, VOLMAXPARTS);
         *cntp = VOLMAXPARTS;
      }
      for (i = 0; i < *cntp; i++) {
         ptrPartList->partId[i] = partEnts.partEntries_val[i];
         ptrPartList->partFlags[i] = PARTVALID;
      }
      free(partEnts.partEntries_val);
   }
 out:
   if (code)
      warn("Could not fetch the list of partitions from the server\n");
   return code;
}


/*
 * from src/fsprobe/fsprobe.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_fsprobe_Cleanup(fsprobe_Results, fsprobe_ConnInfo, fsprobe_numServers,
                   scout_debugfd, buffer)
   struct fsprobe_ProbeResults *fsprobe_Results;
   struct fsprobe_ConnectionInfo *fsprobe_ConnInfo;
   int fsprobe_numServers;
   FILE *scout_debugfd;
   char *buffer;
{

   int code = 0;                /*Return code */
   int conn_idx;                /*Current connection index */
   struct fsprobe_ConnectionInfo *curr_conn;    /*Ptr to fsprobe connection */
   static char rn[] = "my_fsprobe_Cleanup";

   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Called\n", rn);
      fflush(scout_debugfd);
   }


   /*
    * Take care of all Rx connections first.  Check to see that the
    * server count is a legal value.
    */
   if (fsprobe_numServers <= 0) {
      sprintf(buffer,
              "[%s] Illegal number of servers to clean up (fsprobe_numServers = %d)",
              rn, fsprobe_numServers);
      code = -1;
   }
   else {
      if (fsprobe_ConnInfo != (struct fsprobe_ConnectionInfo *) NULL) {
         /*
          * The fsprobe connection structure array exists.  Go through it
          * and close up any Rx connections it holds.
          */
         curr_conn = fsprobe_ConnInfo;
         for (conn_idx = 0; conn_idx < fsprobe_numServers; conn_idx++) {
            if (curr_conn->rxconn != (struct rx_connection *) NULL) {
               rx_DestroyConnection(curr_conn->rxconn);
               curr_conn->rxconn = (struct rx_connection *) NULL;
            }
            if (curr_conn->rxVolconn != (struct rx_connection *) NULL) {
               rx_DestroyConnection(curr_conn->rxVolconn);
               curr_conn->rxVolconn = (struct rx_connection *) NULL;
            }
            curr_conn++;
         }  /*for each fsprobe connection */
      } /*fsprobe connection structure exists */
   }    /*Legal number of servers */

   /*
    * Now, release all the space we've allocated
    */
   if (fsprobe_ConnInfo != (struct fsprobe_ConnectionInfo *) NULL)
      free(fsprobe_ConnInfo);
   if (fsprobe_Results->stats != (struct ProbeViceStatistics *) NULL)
      free(fsprobe_Results->stats);
   if (fsprobe_Results->probeOK != (int *) NULL)
      free(fsprobe_Results->probeOK);

   /*
    * Return the news, whatever it is.
    */
   return (code);


}


/*
 * from src/fsprobe/fsprobe.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_fsprobe_Init(fsprobe_Results, fsprobe_ConnInfo, a_numServers,
                a_socketArray, RETVAL, scout_debugfd, buffer)
   struct fsprobe_ProbeResults *fsprobe_Results;    /*Latest probe results */
   struct fsprobe_ConnectionInfo **fsprobe_ConnInfo;    /*Ptr to connection array */
   int a_numServers;
   struct sockaddr_in *a_socketArray;
   AV *RETVAL;
   FILE *scout_debugfd;
   char *buffer;
{
   static char rn[] = "my_fsprobe_Init";
   struct fsprobe_ConnectionInfo *curr_conn;    /*Current connection */
   int fsprobe_statsBytes;      /*Num bytes in stats block */
   int fsprobe_probeOKBytes;    /*Num bytes in probeOK block */
   int conn_err = 0, code = 0;
   int curr_srv;
   char *hostNameFound;
   int PortToUse;
   struct rx_securityClass *secobj;
   struct rx_securityClass *CBsecobj;
   struct rx_service *rxsrv_afsserver;
   char buff2[256] = "";

   struct rx_call *rxcall;      /*Bogus param */
   AFSCBFids *Fids_Array;       /*Bogus param */
   AFSCBs *CallBack_Array;      /*Bogus param */
   struct interfaceAddr *interfaceAddr; /*Bogus param */


   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Called\n", rn);
      fflush(scout_debugfd);
   }
   if (a_numServers <= 0) {
      sprintf(buffer, "[%s] Illegal number of servers: %d", rn, a_numServers);
      return (-1);
   }
   if (a_socketArray == (struct sockaddr_in *) NULL) {
      sprintf(buffer, "[%s] Null server socket array argument", rn);
      return (-1);
   }

   memset(fsprobe_Results, 0, sizeof(struct fsprobe_ProbeResults));


   rxcall = (struct rx_call *) NULL;
   Fids_Array = (AFSCBFids *) NULL;
   CallBack_Array = (AFSCBs *) NULL;
   interfaceAddr = (struct interfaceAddr *) NULL;

   SRXAFSCB_CallBack(rxcall, Fids_Array, CallBack_Array);
   SRXAFSCB_InitCallBackState2(rxcall, interfaceAddr);
   SRXAFSCB_Probe(rxcall);



   *fsprobe_ConnInfo = (struct fsprobe_ConnectionInfo *)
      malloc(a_numServers * sizeof(struct fsprobe_ConnectionInfo));
   if (*fsprobe_ConnInfo == (struct fsprobe_ConnectionInfo *) NULL) {
      sprintf(buffer,
              "[%s] Can't allocate %d connection info structs (%d bytes)\n",
              rn, a_numServers,
              (a_numServers * sizeof(struct fsprobe_ConnectionInfo)));
      return (-1);  /*No cleanup needs to be done yet */
   }
   else if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] *fsprobe_ConnInfo allocated (%d bytes)\n",
              rn, a_numServers * sizeof(struct fsprobe_ConnectionInfo));
      fflush(scout_debugfd);
   }

   fsprobe_statsBytes = a_numServers * sizeof(struct ProbeViceStatistics);
   fsprobe_Results->stats = (struct ProbeViceStatistics *)
      malloc(fsprobe_statsBytes);
   if (fsprobe_Results->stats == (struct ProbeViceStatistics *) NULL) {
      /*Delete already-malloc'ed areas */
      my_fsprobe_Cleanup(fsprobe_Results, *fsprobe_ConnInfo, a_numServers,
                         scout_debugfd, buff2);
      sprintf(buffer,
              "[%s] Can't allocate %d statistics structs (%d bytes). %s", rn,
              a_numServers, fsprobe_statsBytes, buff2);
      return (-1);
   }
   else if (scout_debugfd) {
      fprintf(scout_debugfd,
              "[%s] fsprobe_Results->stats allocated (%d bytes)\n", rn,
              fsprobe_statsBytes);
      fflush(scout_debugfd);
   }

   fsprobe_probeOKBytes = a_numServers * sizeof(int);
   fsprobe_Results->probeOK = (int *)malloc(fsprobe_probeOKBytes);
   if (fsprobe_Results->probeOK == (int *) NULL) {
      /* Delete already-malloc'ed areas */
      my_fsprobe_Cleanup(fsprobe_Results, *fsprobe_ConnInfo, a_numServers,
                         scout_debugfd, buff2);
      sprintf(buffer,
              "[%s] Can't allocate %d probeOK array entries (%d bytes). %s",
              rn, a_numServers, fsprobe_probeOKBytes, buff2);
      return (-1);
   }
   else if (scout_debugfd) {
      fprintf(scout_debugfd,
              "[%s] fsprobe_Results->probeOK allocated (%d bytes)\n",
              rn, fsprobe_probeOKBytes);
      fflush(scout_debugfd);
   }
   fsprobe_Results->probeNum = 0;
   fsprobe_Results->probeTime = 0;
   memset(fsprobe_Results->stats, 0,
          (a_numServers * sizeof(struct ProbeViceStatistics)));

   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Initializing Rx\n", rn);
      fflush(scout_debugfd);
   }
   PortToUse = FSPROBE_CBPORT;
   do {
      code = rx_Init(htons(PortToUse));
      if (code) {
         if (code == RX_ADDRINUSE) {
            if (scout_debugfd) {
               fprintf(scout_debugfd,
                       "[%s] Callback port %d in use, advancing\n", rn,
                       PortToUse);
               fflush(scout_debugfd);
            }
            PortToUse++;
         }
         else {
            sprintf(buffer, "[%s] Fatal error in rx_Init()\n", rn);
            return (-1);
         }
      }
   } while (code);
   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Rx initialized on port %d\n", rn,
              PortToUse);
      fflush(scout_debugfd);
   }


   /*
    * Create a null Rx server security object, to be used by the
    * Callback listener.
    */
   CBsecobj = (struct rx_securityClass *)rxnull_NewServerSecurityObject();
   if (CBsecobj == (struct rx_securityClass *) NULL) {
      /*Delete already-malloc'ed areas */
      my_fsprobe_Cleanup(fsprobe_Results, *fsprobe_ConnInfo, a_numServers,
                         scout_debugfd, buff2);
      sprintf(buffer,
              "[%s] Can't create null security object for the callback listener. %s",
              rn, buff2);
      return (-1);
   }
   if (scout_debugfd)
      fprintf(scout_debugfd, "[%s] Callback server security object created\n",
              rn);


   /*
    * Create a null Rx client security object, to be used by the
    * probe LWP.
    */
   secobj = (struct rx_securityClass *)rxnull_NewClientSecurityObject();
   if (secobj == (struct rx_securityClass *) NULL) {
      /*Delete already-malloc'ed areas */
      my_fsprobe_Cleanup(fsprobe_Results, *fsprobe_ConnInfo, a_numServers,
                         scout_debugfd, buff2);
      sprintf(buffer,
              "[%s] Can't create client security object for probe LWP. %s",
              rn, buff2);
      return (-1);
   }
   if (scout_debugfd) {
      fprintf(scout_debugfd,
              "[%s] Probe LWP client security object created\n", rn);
      fflush(scout_debugfd);
   }


   curr_conn = *fsprobe_ConnInfo;
   conn_err = 0;
   for (curr_srv = 0; curr_srv < a_numServers; curr_srv++) {
      /*
       * Copy in the socket info for the current server, resolve its
       * printable name if possible.
       */
      if (scout_debugfd) {
         fprintf(scout_debugfd,
                 "[%s] Copying in the following socket info:\n", rn);
         fprintf(scout_debugfd, "[%s] IP addr 0x%lx, port %d\n", rn,
                 (a_socketArray + curr_srv)->sin_addr.s_addr,
                 (a_socketArray + curr_srv)->sin_port);
         fflush(scout_debugfd);
      }
      memcpy(&(curr_conn->skt), a_socketArray + curr_srv,
             sizeof(struct sockaddr_in));

      hostNameFound = hostutil_GetNameByINet(curr_conn->skt.sin_addr.s_addr);
      if (hostNameFound == (char *) NULL) {
         warn("Can't map Internet address %lu to a string name\n",
              curr_conn->skt.sin_addr.s_addr);
         curr_conn->hostName[0] = '\0';
      }
      else {
         strcpy(curr_conn->hostName, hostNameFound);
         if (scout_debugfd) {
            fprintf(scout_debugfd,
                    "[%s] Host name for server index %d is %s\n", rn,
                    curr_srv, curr_conn->hostName);
            fflush(scout_debugfd);
         }
      }

      /*
       * Make an Rx connection to the current server.
       */
      if (scout_debugfd) {
         fprintf(scout_debugfd,
                 "[%s] Connecting to srv idx %d, IP addr 0x%lx, port %d, service 1\n",
                 rn, curr_srv, curr_conn->skt.sin_addr.s_addr,
                 curr_conn->skt.sin_port);
         fflush(scout_debugfd);
      }

      curr_conn->rxconn = rx_NewConnection(curr_conn->skt.sin_addr.s_addr,  /*Server addr */
                                           curr_conn->skt.sin_port, /*Server port */
                                           1,   /*AFS service num */
                                           secobj,  /*Security object */
                                           0);  /*Number of above */
      if (curr_conn->rxconn == (struct rx_connection *) NULL) {
         sprintf(buffer,
                 "[%s] Can't create Rx connection to server %s (%lu)",
                 rn, curr_conn->hostName, curr_conn->skt.sin_addr.s_addr);
         conn_err = 1;
      }
      if (scout_debugfd) {
         fprintf(scout_debugfd, "[%s] New connection at 0x%lx\n",
                 rn, curr_conn->rxconn);
         fflush(scout_debugfd);
      }

      /*
       * Make an Rx connection to the current volume server.
       */
      if (scout_debugfd) {
         fprintf(scout_debugfd,
                 "[%s] Connecting to srv idx %d, IP addr 0x%lx, port %d, service 1\n",
                 rn, curr_srv, curr_conn->skt.sin_addr.s_addr, htons(7005));
         fflush(scout_debugfd);
      }
      curr_conn->rxVolconn = rx_NewConnection(curr_conn->skt.sin_addr.s_addr,   /*Server addr */
                                              htons(AFSCONF_VOLUMEPORT),    /*Volume Server port */
                                              VOLSERVICE_ID,    /*AFS service num */
                                              secobj,   /*Security object */
                                              0);   /*Number of above */
      if (curr_conn->rxVolconn == (struct rx_connection *) NULL) {
         sprintf(buffer,
                 "[%s] Can't create Rx connection to volume server %s (%lu)\n",
                 rn, curr_conn->hostName, curr_conn->skt.sin_addr.s_addr);
         conn_err = 1;
      }
      else {
         int i, cnt;

         memset(&curr_conn->partList, 0, sizeof(struct partList));
         curr_conn->partCnt = 0;
         i = my_XListPartitions(curr_conn->rxVolconn, &curr_conn->partList,
                                &cnt, scout_debugfd);
         if (!i) {
            curr_conn->partCnt = cnt;
         }
      }
      if (scout_debugfd) {
         fprintf(scout_debugfd, "[%s] New connection at 0x%lx\n",
                 rn, curr_conn->rxVolconn);
         fflush(scout_debugfd);
      }


      /*
       * Bump the current fsprobe connection to set up.
       */
      curr_conn++;
   }    /*for curr_srv */

   /*
    * Create the AFS callback service (listener).
    */
   if (scout_debugfd)
      fprintf(scout_debugfd, "[%s] Creating AFS callback listener\n", rn);
   rxsrv_afsserver = rx_NewService(0,   /*Use default port */
                                   1,   /*Service ID */
                                   "afs",   /*Service name */
                                   &CBsecobj,   /*Ptr to security object(s) */
                                   1,   /*Number of security objects */
                                   RXAFSCB_ExecuteRequest); /*Dispatcher */
   if (rxsrv_afsserver == (struct rx_service *) NULL) {
      /*Delete already-malloc'ed areas */
      my_fsprobe_Cleanup(fsprobe_Results, *fsprobe_ConnInfo, a_numServers,
                         scout_debugfd, buff2);
      sprintf(buffer, "[%s] Can't create callback Rx service/listener. %s",
              rn, buff2);
      return (-1);
   }
   if (scout_debugfd)
      fprintf(scout_debugfd, "[%s] Callback listener created\n", rn);

   /*
    * Start up the AFS callback service.
    */
   if (scout_debugfd)
      fprintf(scout_debugfd, "[%s] Starting up callback listener.\n", rn);
   rx_StartServer(0 /*Don't donate yourself to LWP pool */ );

   /* start probe */
   code = my_fsprobe_LWP(a_numServers, *fsprobe_ConnInfo, fsprobe_Results,
                         fsprobe_statsBytes, fsprobe_probeOKBytes,
                         scout_debugfd, RETVAL, buffer);
   if (code)
      return (code);

   if (conn_err)
      return (-2);
   else
      return (0);

}   /* my_fsprobe_Init() */


/*
 * from src/scout/scout.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_FS_Handler(fsprobe_Results, numServers, fsprobe_ConnInfo, scout_debugfd,
              RETVAL, buffer)
   struct fsprobe_ProbeResults fsprobe_Results;
   int numServers;
   struct fsprobe_ConnectionInfo *fsprobe_ConnInfo;
   FILE *scout_debugfd;
   AV *RETVAL;
   char *buffer;
{
   static char rn[] = "my_FS_Handler";  /*Routine name */
   int code;                    /*Return code */
   struct ProbeViceStatistics *curr_stats;  /*Ptr to current stats */
   struct fsprobe_ConnectionInfo *curr_conn;
   ViceDisk *curr_diskstat;
   int curr_disk;
   int *curr_probeOK;           /*Ptr to current probeOK field */
   int i = 0, j = 0;
   HV *RESULTS;
   HV *STATS;
   AV *DISKS;
   HV *DISK;

   if (scout_debugfd) {
      fprintf(scout_debugfd, "[%s] Called\n", rn);
      fflush(scout_debugfd);
   }

   curr_stats = fsprobe_Results.stats;
   curr_probeOK = fsprobe_Results.probeOK;
   curr_conn = fsprobe_ConnInfo;

   for (i = 0; i < numServers; i++) {
      RESULTS = newHV();

      hv_store(RESULTS, "probeOK", 7, newSViv((*curr_probeOK) ? 0 : 1), 0);
      hv_store(RESULTS, "probeTime", 9, newSViv(fsprobe_Results.probeTime),
               0);
      hv_store(RESULTS, "hostName", 8, newSVpv(curr_conn->hostName, 0), 0);

      if (*curr_probeOK == 0) {
         STATS = newHV();
         hv_store(STATS, "CurrentConnections", 18,
                  newSViv(curr_stats->CurrentConnections), 0);
         hv_store(STATS, "TotalFetchs", 11, newSViv(curr_stats->TotalFetchs),
                  0);
         hv_store(STATS, "TotalStores", 11, newSViv(curr_stats->TotalStores),
                  0);
         hv_store(STATS, "WorkStations", 12,
                  newSViv(curr_stats->WorkStations), 0);

         hv_store(STATS, "CurrentMsgNumber", strlen("CurrentMsgNumber"),
                  newSViv(curr_stats->CurrentMsgNumber), 0);
         hv_store(STATS, "OldestMsgNumber", strlen("OldestMsgNumber"),
                  newSViv(curr_stats->OldestMsgNumber), 0);
         hv_store(STATS, "CurrentTime", strlen("CurrentTime"),
                  newSViv(curr_stats->CurrentTime), 0);
         hv_store(STATS, "BootTime", strlen("BootTime"),
                  newSViv(curr_stats->BootTime), 0);
         hv_store(STATS, "StartTime", strlen("StartTime"),
                  newSViv(curr_stats->StartTime), 0);
         hv_store(STATS, "TotalViceCalls", strlen("TotalViceCalls"),
                  newSViv(curr_stats->TotalViceCalls), 0);
         hv_store(STATS, "FetchDatas", strlen("FetchDatas"),
                  newSViv(curr_stats->FetchDatas), 0);
         hv_store(STATS, "FetchedBytes", strlen("FetchedBytes"),
                  newSViv(curr_stats->FetchedBytes), 0);
         hv_store(STATS, "FetchDataRate", strlen("FetchDataRate"),
                  newSViv(curr_stats->FetchDataRate), 0);
         hv_store(STATS, "StoreDatas", strlen("StoreDatas"),
                  newSViv(curr_stats->StoreDatas), 0);
         hv_store(STATS, "StoredBytes", strlen("StoredBytes"),
                  newSViv(curr_stats->StoredBytes), 0);
         hv_store(STATS, "StoreDataRate", strlen("StoreDataRate"),
                  newSViv(curr_stats->StoreDataRate), 0);
         hv_store(STATS, "TotalRPCBytesSent", strlen("TotalRPCBytesSent"),
                  newSViv(curr_stats->TotalRPCBytesSent), 0);
         hv_store(STATS, "TotalRPCBytesReceived",
                  strlen("TotalRPCBytesReceived"),
                  newSViv(curr_stats->TotalRPCBytesReceived), 0);
         hv_store(STATS, "TotalRPCPacketsSent", strlen("TotalRPCPacketsSent"),
                  newSViv(curr_stats->TotalRPCPacketsSent), 0);
         hv_store(STATS, "TotalRPCPacketsReceived",
                  strlen("TotalRPCPacketsReceived"),
                  newSViv(curr_stats->TotalRPCPacketsReceived), 0);
         hv_store(STATS, "TotalRPCPacketsLost", strlen("TotalRPCPacketsLost"),
                  newSViv(curr_stats->TotalRPCPacketsLost), 0);
         hv_store(STATS, "TotalRPCBogusPackets",
                  strlen("TotalRPCBogusPackets"),
                  newSViv(curr_stats->TotalRPCBogusPackets), 0);
         hv_store(STATS, "SystemCPU", strlen("SystemCPU"),
                  newSViv(curr_stats->SystemCPU), 0);
         hv_store(STATS, "UserCPU", strlen("UserCPU"),
                  newSViv(curr_stats->UserCPU), 0);
         hv_store(STATS, "NiceCPU", strlen("NiceCPU"),
                  newSViv(curr_stats->NiceCPU), 0);
         hv_store(STATS, "IdleCPU", strlen("IdleCPU"),
                  newSViv(curr_stats->IdleCPU), 0);
         hv_store(STATS, "TotalIO", strlen("TotalIO"),
                  newSViv(curr_stats->TotalIO), 0);
         hv_store(STATS, "ActiveVM", strlen("ActiveVM"),
                  newSViv(curr_stats->ActiveVM), 0);
         hv_store(STATS, "TotalVM", strlen("TotalVM"),
                  newSViv(curr_stats->TotalVM), 0);
         hv_store(STATS, "EtherNetTotalErrors", strlen("EtherNetTotalErrors"),
                  newSViv(curr_stats->EtherNetTotalErrors), 0);
         hv_store(STATS, "EtherNetTotalWrites", strlen("EtherNetTotalWrites"),
                  newSViv(curr_stats->EtherNetTotalWrites), 0);
         hv_store(STATS, "EtherNetTotalInterupts",
                  strlen("EtherNetTotalInterupts"),
                  newSViv(curr_stats->EtherNetTotalInterupts), 0);
         hv_store(STATS, "EtherNetGoodReads", strlen("EtherNetGoodReads"),
                  newSViv(curr_stats->EtherNetGoodReads), 0);
         hv_store(STATS, "EtherNetTotalBytesWritten",
                  strlen("EtherNetTotalBytesWritten"),
                  newSViv(curr_stats->EtherNetTotalBytesWritten), 0);
         hv_store(STATS, "EtherNetTotalBytesRead",
                  strlen("EtherNetTotalBytesRead"),
                  newSViv(curr_stats->EtherNetTotalBytesRead), 0);
         hv_store(STATS, "ProcessSize", strlen("ProcessSize"),
                  newSViv(curr_stats->ProcessSize), 0);
         hv_store(STATS, "WorkStations", strlen("WorkStations"),
                  newSViv(curr_stats->WorkStations), 0);
         hv_store(STATS, "ActiveWorkStations", strlen("ActiveWorkStations"),
                  newSViv(curr_stats->ActiveWorkStations), 0);
         hv_store(STATS, "Spare1", strlen("Spare1"),
                  newSViv(curr_stats->Spare1), 0);
         hv_store(STATS, "Spare2", strlen("Spare2"),
                  newSViv(curr_stats->Spare2), 0);
         hv_store(STATS, "Spare3", strlen("Spare3"),
                  newSViv(curr_stats->Spare3), 0);
         hv_store(STATS, "Spare4", strlen("Spare4"),
                  newSViv(curr_stats->Spare4), 0);
         hv_store(STATS, "Spare5", strlen("Spare5"),
                  newSViv(curr_stats->Spare5), 0);
         hv_store(STATS, "Spare6", strlen("Spare6"),
                  newSViv(curr_stats->Spare6), 0);
         hv_store(STATS, "Spare7", strlen("Spare7"),
                  newSViv(curr_stats->Spare7), 0);
         hv_store(STATS, "Spare8", strlen("Spare8"),
                  newSViv(curr_stats->Spare8), 0);

         DISKS = newAV();

         curr_diskstat = (ViceDisk *) curr_stats->Disk;
         j = 0;
         for (curr_disk = 0; curr_disk < VOLMAXPARTS; curr_disk++) {
            if (strncmp("/vice", curr_diskstat->Name, 5) == 0) {
               DISK = newHV();
               hv_store(DISK, "Name", 4, newSVpv(&curr_diskstat->Name[6], 0),
                        0);
               hv_store(DISK, "TotalBlocks", 10,
                        newSViv(curr_diskstat->TotalBlocks), 0);
               hv_store(DISK, "BlocksAvailable", 15,
                        newSViv(curr_diskstat->BlocksAvailable), 0);
               av_store(DISKS, j, newRV_inc((SV *) DISK));
               curr_diskstat++;
               j++;
            }
         }

         hv_store(STATS, "Disk", 4, newRV_inc((SV *) DISKS), 0);
         hv_store(RESULTS, "stats", 5, newRV_inc((SV *) STATS), 0);
      }
      av_store(RETVAL, i, newRV_inc((SV *) RESULTS));
      curr_stats++;
      curr_probeOK++;
      curr_conn++;
   }

   code =
      my_fsprobe_Cleanup(&fsprobe_Results, fsprobe_ConnInfo, numServers,
                         scout_debugfd, buffer);

   return code;
}

/* end of scout helper functions */



/* xstat_fs_test helper functions */

/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintOpTiming(int a_opIdx, struct fs_stats_opTimingData *a_opTimeP, HV *DATA)
{
   HV *OPTIMING = newHV();

   hv_store(OPTIMING, "sumTime", 7,
            newSVnv(a_opTimeP->sumTime.tv_sec +
                    a_opTimeP->sumTime.tv_usec / 1000000.0), 0);
   hv_store(OPTIMING, "sqrTime", 7,
            newSVnv(a_opTimeP->sqrTime.tv_sec +
                    a_opTimeP->sqrTime.tv_usec / 1000000.0), 0);
   hv_store(OPTIMING, "minTime", 7,
            newSVnv(a_opTimeP->minTime.tv_sec +
                    a_opTimeP->minTime.tv_usec / 1000000.0), 0);
   hv_store(OPTIMING, "maxTime", 7,
            newSVnv(a_opTimeP->maxTime.tv_sec +
                    a_opTimeP->maxTime.tv_usec / 1000000.0), 0);
   hv_store(OPTIMING, "numSuccesses", 12, newSViv(a_opTimeP->numSuccesses),
            0);
   hv_store(OPTIMING, "numOps", 6, newSViv(a_opTimeP->numOps), 0);

   hv_store(DATA, fsOpNames[a_opIdx], strlen(fsOpNames[a_opIdx]),
            newRV_inc((SV *) OPTIMING), 0);
}


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintXferTiming(int a_opIdx, struct fs_stats_xferData *a_xferP, HV *DATA)
{
   HV *XFERTIMING = newHV();
   AV *COUNT = newAV();
   int i;

   hv_store(XFERTIMING, "sumTime", 7,
            newSVnv(a_xferP->sumTime.tv_sec +
                    a_xferP->sumTime.tv_usec / 1000000.0), 0);
   hv_store(XFERTIMING, "sqrTime", 7,
            newSVnv(a_xferP->sqrTime.tv_sec +
                    a_xferP->sqrTime.tv_usec / 1000000.0), 0);
   hv_store(XFERTIMING, "minTime", 7,
            newSVnv(a_xferP->minTime.tv_sec +
                    a_xferP->minTime.tv_usec / 1000000.0), 0);
   hv_store(XFERTIMING, "maxTime", 7,
            newSVnv(a_xferP->maxTime.tv_sec +
                    a_xferP->maxTime.tv_usec / 1000000.0), 0);
   hv_store(XFERTIMING, "numSuccesses", 12, newSViv(a_xferP->numSuccesses),
            0);
   hv_store(XFERTIMING, "numXfers", 8, newSViv(a_xferP->numXfers), 0);

   hv_store(XFERTIMING, "sumBytes", 8, newSViv(a_xferP->sumBytes), 0);
   hv_store(XFERTIMING, "minBytes", 8, newSViv(a_xferP->minBytes), 0);
   hv_store(XFERTIMING, "maxBytes", 8, newSViv(a_xferP->maxBytes), 0);

   for (i = 0; i <= 8; i++)
      av_store(COUNT, i, newSViv(a_xferP->count[i]));

   hv_store(XFERTIMING, "count", 5, newRV_inc((SV *) COUNT), 0);

   hv_store(DATA, xferOpNames[a_opIdx], strlen(xferOpNames[a_opIdx]),
            newRV_inc((SV *) XFERTIMING), 0);
}


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintDetailedPerfInfo(struct fs_stats_DetailedStats *a_detP, HV *DATA)
{
   int currIdx;
   HV *OPTIMES = newHV();
   HV *XFERS = newHV();

   hv_store(DATA, "epoch", 5,
            newSVnv(a_detP->epoch.tv_sec + a_detP->epoch.tv_usec / 1000000.0),
            0);

   for (currIdx = 0; currIdx < FS_STATS_NUM_RPC_OPS; currIdx++)
      my_PrintOpTiming(currIdx, &(a_detP->rpcOpTimes[currIdx]), OPTIMES);

   hv_store(DATA, "rpcOpTimes", 10, newRV_inc((SV *) OPTIMES), 0);

   for (currIdx = 0; currIdx < FS_STATS_NUM_XFER_OPS; currIdx++)
      my_PrintXferTiming(currIdx, &(a_detP->xferOpTimes[currIdx]), XFERS);

   hv_store(DATA, "xferOpTimes", 11, newRV_inc((SV *) XFERS), 0);
}


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintOverallPerfInfo(struct afs_PerfStats *a_ovP, HV *DATA)
{
   hv_store(DATA, "numPerfCalls", strlen("numPerfCalls"),
            newSViv(a_ovP->numPerfCalls), 0);

   /*
    * Vnode cache section.
    */
   hv_store(DATA, "vcache_L_Entries", strlen("vcache_L_Entries"),
            newSViv(a_ovP->vcache_L_Entries), 0);
   hv_store(DATA, "vcache_L_Allocs", strlen("vcache_L_Allocs"),
            newSViv(a_ovP->vcache_L_Allocs), 0);
   hv_store(DATA, "vcache_L_Gets", strlen("vcache_L_Gets"),
            newSViv(a_ovP->vcache_L_Gets), 0);
   hv_store(DATA, "vcache_L_Reads", strlen("vcache_L_Reads"),
            newSViv(a_ovP->vcache_L_Reads), 0);
   hv_store(DATA, "vcache_L_Writes", strlen("vcache_L_Writes"),
            newSViv(a_ovP->vcache_L_Writes), 0);

   hv_store(DATA, "vcache_S_Entries", strlen("vcache_S_Entries"),
            newSViv(a_ovP->vcache_S_Entries), 0);
   hv_store(DATA, "vcache_S_Allocs", strlen("vcache_S_Allocs"),
            newSViv(a_ovP->vcache_S_Allocs), 0);
   hv_store(DATA, "vcache_S_Gets", strlen("vcache_S_Gets"),
            newSViv(a_ovP->vcache_S_Gets), 0);
   hv_store(DATA, "vcache_S_Reads", strlen("vcache_S_Reads"),
            newSViv(a_ovP->vcache_S_Reads), 0);
   hv_store(DATA, "vcache_S_Writes", strlen("vcache_S_Writes"),
            newSViv(a_ovP->vcache_S_Writes), 0);

   hv_store(DATA, "vcache_H_Entries", strlen("vcache_H_Entries"),
            newSViv(a_ovP->vcache_H_Entries), 0);
   hv_store(DATA, "vcache_H_Gets", strlen("vcache_H_Gets"),
            newSViv(a_ovP->vcache_H_Gets), 0);
   hv_store(DATA, "vcache_H_Replacements", strlen("vcache_H_Replacements"),
            newSViv(a_ovP->vcache_H_Replacements), 0);

   /*
    * Directory package section.
    */
   hv_store(DATA, "dir_Buffers", strlen("dir_Buffers"),
            newSViv(a_ovP->dir_Buffers), 0);
   hv_store(DATA, "dir_Calls", strlen("dir_Calls"),
            newSViv(a_ovP->dir_Calls), 0);
   hv_store(DATA, "dir_IOs", strlen("dir_IOs"), newSViv(a_ovP->dir_IOs), 0);

   /*
    * Rx section.
    */
   hv_store(DATA, "rx_packetRequests", strlen("rx_packetRequests"),
            newSViv(a_ovP->rx_packetRequests), 0);
   hv_store(DATA, "rx_noPackets_RcvClass", strlen("rx_noPackets_RcvClass"),
            newSViv(a_ovP->rx_noPackets_RcvClass), 0);
   hv_store(DATA, "rx_noPackets_SendClass", strlen("rx_noPackets_SendClass"),
            newSViv(a_ovP->rx_noPackets_SendClass), 0);
   hv_store(DATA, "rx_noPackets_SpecialClass",
            strlen("rx_noPackets_SpecialClass"),
            newSViv(a_ovP->rx_noPackets_SpecialClass), 0);
   hv_store(DATA, "rx_socketGreedy", strlen("rx_socketGreedy"),
            newSViv(a_ovP->rx_socketGreedy), 0);
   hv_store(DATA, "rx_bogusPacketOnRead", strlen("rx_bogusPacketOnRead"),
            newSViv(a_ovP->rx_bogusPacketOnRead), 0);
   hv_store(DATA, "rx_bogusHost", strlen("rx_bogusHost"),
            newSViv(a_ovP->rx_bogusHost), 0);
   hv_store(DATA, "rx_noPacketOnRead", strlen("rx_noPacketOnRead"),
            newSViv(a_ovP->rx_noPacketOnRead), 0);
   hv_store(DATA, "rx_noPacketBuffersOnRead",
            strlen("rx_noPacketBuffersOnRead"),
            newSViv(a_ovP->rx_noPacketBuffersOnRead), 0);
   hv_store(DATA, "rx_selects", strlen("rx_selects"),
            newSViv(a_ovP->rx_selects), 0);
   hv_store(DATA, "rx_sendSelects", strlen("rx_sendSelects"),
            newSViv(a_ovP->rx_sendSelects), 0);
   hv_store(DATA, "rx_packetsRead_RcvClass",
            strlen("rx_packetsRead_RcvClass"),
            newSViv(a_ovP->rx_packetsRead_RcvClass), 0);
   hv_store(DATA, "rx_packetsRead_SendClass",
            strlen("rx_packetsRead_SendClass"),
            newSViv(a_ovP->rx_packetsRead_SendClass), 0);
   hv_store(DATA, "rx_packetsRead_SpecialClass",
            strlen("rx_packetsRead_SpecialClass"),
            newSViv(a_ovP->rx_packetsRead_SpecialClass), 0);
   hv_store(DATA, "rx_dataPacketsRead", strlen("rx_dataPacketsRead"),
            newSViv(a_ovP->rx_dataPacketsRead), 0);
   hv_store(DATA, "rx_ackPacketsRead", strlen("rx_ackPacketsRead"),
            newSViv(a_ovP->rx_ackPacketsRead), 0);
   hv_store(DATA, "rx_dupPacketsRead", strlen("rx_dupPacketsRead"),
            newSViv(a_ovP->rx_dupPacketsRead), 0);
   hv_store(DATA, "rx_spuriousPacketsRead", strlen("rx_spuriousPacketsRead"),
            newSViv(a_ovP->rx_spuriousPacketsRead), 0);
   hv_store(DATA, "rx_packetsSent_RcvClass",
            strlen("rx_packetsSent_RcvClass"),
            newSViv(a_ovP->rx_packetsSent_RcvClass), 0);
   hv_store(DATA, "rx_packetsSent_SendClass",
            strlen("rx_packetsSent_SendClass"),
            newSViv(a_ovP->rx_packetsSent_SendClass), 0);
   hv_store(DATA, "rx_packetsSent_SpecialClass",
            strlen("rx_packetsSent_SpecialClass"),
            newSViv(a_ovP->rx_packetsSent_SpecialClass), 0);
   hv_store(DATA, "rx_ackPacketsSent", strlen("rx_ackPacketsSent"),
            newSViv(a_ovP->rx_ackPacketsSent), 0);
   hv_store(DATA, "rx_pingPacketsSent", strlen("rx_pingPacketsSent"),
            newSViv(a_ovP->rx_pingPacketsSent), 0);
   hv_store(DATA, "rx_abortPacketsSent", strlen("rx_abortPacketsSent"),
            newSViv(a_ovP->rx_abortPacketsSent), 0);
   hv_store(DATA, "rx_busyPacketsSent", strlen("rx_busyPacketsSent"),
            newSViv(a_ovP->rx_busyPacketsSent), 0);
   hv_store(DATA, "rx_dataPacketsSent", strlen("rx_dataPacketsSent"),
            newSViv(a_ovP->rx_dataPacketsSent), 0);
   hv_store(DATA, "rx_dataPacketsReSent", strlen("rx_dataPacketsReSent"),
            newSViv(a_ovP->rx_dataPacketsReSent), 0);
   hv_store(DATA, "rx_dataPacketsPushed", strlen("rx_dataPacketsPushed"),
            newSViv(a_ovP->rx_dataPacketsPushed), 0);
   hv_store(DATA, "rx_ignoreAckedPacket", strlen("rx_ignoreAckedPacket"),
            newSViv(a_ovP->rx_ignoreAckedPacket), 0);
   hv_store(DATA, "rx_totalRtt_Sec", strlen("rx_totalRtt_Sec"),
            newSViv(a_ovP->rx_totalRtt_Sec), 0);
   hv_store(DATA, "rx_totalRtt_Usec", strlen("rx_totalRtt_Usec"),
            newSViv(a_ovP->rx_totalRtt_Usec), 0);
   hv_store(DATA, "rx_minRtt_Sec", strlen("rx_minRtt_Sec"),
            newSViv(a_ovP->rx_minRtt_Sec), 0);
   hv_store(DATA, "rx_minRtt_Usec", strlen("rx_minRtt_Usec"),
            newSViv(a_ovP->rx_minRtt_Usec), 0);
   hv_store(DATA, "rx_maxRtt_Sec", strlen("rx_maxRtt_Sec"),
            newSViv(a_ovP->rx_maxRtt_Sec), 0);
   hv_store(DATA, "rx_maxRtt_Usec", strlen("rx_maxRtt_Usec"),
            newSViv(a_ovP->rx_maxRtt_Usec), 0);
   hv_store(DATA, "rx_nRttSamples", strlen("rx_nRttSamples"),
            newSViv(a_ovP->rx_nRttSamples), 0);
   hv_store(DATA, "rx_nServerConns", strlen("rx_nServerConns"),
            newSViv(a_ovP->rx_nServerConns), 0);
   hv_store(DATA, "rx_nClientConns", strlen("rx_nClientConns"),
            newSViv(a_ovP->rx_nClientConns), 0);
   hv_store(DATA, "rx_nPeerStructs", strlen("rx_nPeerStructs"),
            newSViv(a_ovP->rx_nPeerStructs), 0);
   hv_store(DATA, "rx_nCallStructs", strlen("rx_nCallStructs"),
            newSViv(a_ovP->rx_nCallStructs), 0);
   hv_store(DATA, "rx_nFreeCallStructs", strlen("rx_nFreeCallStructs"),
            newSViv(a_ovP->rx_nFreeCallStructs), 0);
#ifndef NOAFS_XSTATSCOLL_CBSTATS
   hv_store(DATA, "rx_nBusies", strlen("rx_nBusies"),
            newSViv(a_ovP->rx_nBusies), 0);
   hv_store(DATA, "fs_nBusies", strlen("fs_nBusies"),
            newSViv(a_ovP->fs_nBusies), 0);
   hv_store(DATA, "fs_GetCapabilities", strlen("fs_GetCapabilities"),
            newSViv(a_ovP->fs_nGetCaps), 0);
#endif

   /*
    * Host module fields.
    */
   hv_store(DATA, "host_NumHostEntries", strlen("host_NumHostEntries"),
            newSViv(a_ovP->host_NumHostEntries), 0);
   hv_store(DATA, "host_HostBlocks", strlen("host_HostBlocks"),
            newSViv(a_ovP->host_HostBlocks), 0);
   hv_store(DATA, "host_NonDeletedHosts", strlen("host_NonDeletedHosts"),
            newSViv(a_ovP->host_NonDeletedHosts), 0);
   hv_store(DATA, "host_HostsInSameNetOrSubnet",
            strlen("host_HostsInSameNetOrSubnet"),
            newSViv(a_ovP->host_HostsInSameNetOrSubnet), 0);
   hv_store(DATA, "host_HostsInDiffSubnet", strlen("host_HostsInDiffSubnet"),
            newSViv(a_ovP->host_HostsInDiffSubnet), 0);
   hv_store(DATA, "host_HostsInDiffNetwork",
            strlen("host_HostsInDiffNetwork"),
            newSViv(a_ovP->host_HostsInDiffNetwork), 0);
   hv_store(DATA, "host_NumClients", strlen("host_NumClients"),
            newSViv(a_ovP->host_NumClients), 0);
   hv_store(DATA, "host_ClientBlocks", strlen("host_ClientBlocks"),
            newSViv(a_ovP->host_ClientBlocks), 0);

   hv_store(DATA, "sysname_ID", strlen("sysname_ID"),
            newSViv(a_ovP->sysname_ID), 0);
}



/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintCallInfo(struct xstat_fs_ProbeResults *xstat_fs_Results, HV *HOSTINFO)
{
   int numInt32s;
   afs_int32 *currInt32;
   register int i;
   char temp[100];
   HV *DATA = newHV();

   numInt32s = xstat_fs_Results->data.AFS_CollData_len;

   hv_store(DATA, "AFS_CollData_len", 16, newSViv(numInt32s), 0);
   currInt32 = (afs_int32 *) (xstat_fs_Results->data.AFS_CollData_val);
   for (i = 0; i < numInt32s; i++) {
      sprintf(temp, "%d", i);
      hv_store(DATA, temp, strlen(temp), newSViv(*currInt32++), 0);
   }
   hv_store(HOSTINFO, "data", 4, newRV_inc((SV *) DATA), 0);
}


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintPerfInfo(struct xstat_fs_ProbeResults *xstat_fs_Results, HV *HOSTINFO)
{
   /* Correct # int32s to rcv */
   static afs_int32 perfInt32s = (sizeof(struct afs_PerfStats) >> 2);
   /* # int32words received */
   afs_int32 numInt32s;
   /* Ptr to performance stats */
   struct afs_PerfStats *perfP;
   HV *DATA = newHV();

   numInt32s = xstat_fs_Results->data.AFS_CollData_len;
   if (numInt32s != perfInt32s) {
      warn("** Data size mismatch in performance collection!");
      warn("** Expecting %d, got %d\n", perfInt32s, numInt32s);
      return;
   }

   perfP = (struct afs_PerfStats *)
      (xstat_fs_Results->data.AFS_CollData_val);

   my_PrintOverallPerfInfo(perfP, DATA);

   hv_store(HOSTINFO, "data", 4, newRV_inc((SV *) DATA), 0);
}


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_fs_PrintFullPerfInfo(struct xstat_fs_ProbeResults *xstat_fs_Results, HV *HOSTINFO)
{
   /* Correct # int32s to rcv */
   static afs_int32 fullPerfInt32s = (sizeof(struct fs_stats_FullPerfStats) >> 2);
   /* # int32words received */
   afs_int32 numInt32s;
   /* Ptr to full perf stats */
   struct fs_stats_FullPerfStats *fullPerfP;
   HV *DATA = newHV();

   numInt32s = xstat_fs_Results->data.AFS_CollData_len;
   if (numInt32s != fullPerfInt32s) {
      warn("** Data size mismatch in full performance collection!");
      warn("** Expecting %d, got %d\n", fullPerfInt32s, numInt32s);
      return;
   }

   fullPerfP = (struct fs_stats_FullPerfStats *)
      (xstat_fs_Results->data.AFS_CollData_val);

   my_PrintOverallPerfInfo(&(fullPerfP->overall), DATA);
   my_PrintDetailedPerfInfo(&(fullPerfP->det), DATA);

   hv_store(HOSTINFO, "data", 4, newRV_inc((SV *) DATA), 0);
}


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

static char *CbCounterStrings[] = {
    "DeleteFiles",
    "DeleteCallBacks",
    "BreakCallBacks",
    "AddCallBack",
    "GotSomeSpaces",
    "DeleteAllCallBacks",
    "nFEs", "nCBs", "nblks",
    "CBsTimedOut",
    "nbreakers",
    "GSS1", "GSS2", "GSS3", "GSS4", "GSS5"
};


/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_fs_PrintCbCounters(struct xstat_fs_ProbeResults *xstat_fs_Results, HV *HOSTINFO)
{
    int numInt32s = sizeof(CbCounterStrings)/sizeof(char *);
    int i;
    afs_uint32 *val = xstat_fs_Results->data.AFS_CollData_val;
    HV *DATA = newHV();

    if (numInt32s > xstat_fs_Results->data.AFS_CollData_len)
        numInt32s = xstat_fs_Results->data.AFS_CollData_len;

    for (i=0; i<numInt32s; i++) {
        hv_store(DATA, CbCounterStrings[i], strlen(CbCounterStrings[i]), newSViv(val[i]), 0);
    }

   hv_store(HOSTINFO, "CbCounters", 10, newRV_inc((SV *) DATA), 0);
}




/*
 * from src/xstat/xstat_fs_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_FS_Handler(xstat_fs_Results, xstat_fs_numServers, index, buffer,
                    argp)
   struct xstat_fs_ProbeResults xstat_fs_Results;
   int xstat_fs_numServers;
   int index;
   char *buffer;
   va_list argp;
{
   AV *RETVAL = va_arg(argp, AV *);

   HV *HOSTINFO = newHV();

   hv_store(HOSTINFO, "probeOK", 7, newSViv(xstat_fs_Results.probeOK ? 0 : 1),
            0);
   hv_store(HOSTINFO, "hostName", 8,
            newSVpv(xstat_fs_Results.connP->hostName, 0), 0);
   hv_store(HOSTINFO, "collectionNumber", 16,
            newSViv(xstat_fs_Results.collectionNumber), 0);
   hv_store(HOSTINFO, "probeTime", 9, newSViv(xstat_fs_Results.probeTime), 0);

   if (xstat_fs_Results.probeOK == 0) {

      switch (xstat_fs_Results.collectionNumber) {
        case AFS_XSTATSCOLL_CALL_INFO:
           my_PrintCallInfo(&xstat_fs_Results, HOSTINFO);
           break;

        case AFS_XSTATSCOLL_PERF_INFO:
           my_PrintPerfInfo(&xstat_fs_Results, HOSTINFO);
           break;

        case AFS_XSTATSCOLL_FULL_PERF_INFO:
           my_fs_PrintFullPerfInfo(&xstat_fs_Results, HOSTINFO);
           break;

#ifndef NOAFS_XSTATSCOLL_CBSTATS
        case AFS_XSTATSCOLL_CBSTATS:
           my_fs_PrintCbCounters(&xstat_fs_Results, HOSTINFO);
           break;
#endif

        default:
           sprintf(buffer, "** Unknown collection: %d",
                   xstat_fs_Results.collectionNumber);
           return (-1);
      }
   }

   av_store(RETVAL, index, newRV_inc((SV *) HOSTINFO));
   return (0);
}

/* end of xstat_fs_test helper functions */



/* xstat_cm_test helper functions */


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_print_cmCallStats(struct xstat_cm_ProbeResults *xstat_cm_Results, HV *HOSTINFO)
{
   struct afs_CMStats *cmp;
   HV *DATA = newHV();
   char *data_name;

   cmp = (struct afs_CMStats *)(xstat_cm_Results->data.AFSCB_CollData_val);

   data_name = "afs_init";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_init), 0);
   data_name = "gop_rdwr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_gop_rdwr), 0);
   data_name = "aix_gnode_rele";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_aix_gnode_rele), 0);
   data_name = "gettimeofday";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_gettimeofday), 0);
   data_name = "m_cpytoc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_m_cpytoc), 0);
   data_name = "aix_vattr_null";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_aix_vattr_null), 0);
   data_name = "afs_gn_frunc";
   hv_store(DATA, "afs_gn_ftrunc", strlen("afs_gn_ftrunc"),
            newSViv(cmp->callInfo.C_afs_gn_ftrunc), 0);
   data_name = "afs_gn_rdwr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_rdwr), 0);
   data_name = "afs_gn_ioctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_ioctl), 0);
   data_name = "afs_gn_locktl";
   hv_store(DATA, "afs_gn_lockctl", strlen("afs_gn_lockctl"),
            newSViv(cmp->callInfo.C_afs_gn_lockctl), 0);
   data_name = "afs_gn_readlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_readlink), 0);
   data_name = "afs_gn_readdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_readdir), 0);
   data_name = "afs_gn_select";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_select), 0);
   data_name = "afs_gn_strategy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_strategy), 0);
   data_name = "afs_gn_symlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_symlink), 0);
   data_name = "afs_gn_revoke";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_revoke), 0);
   data_name = "afs_gn_link";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_link), 0);
   data_name = "afs_gn_mkdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_mkdir), 0);
   data_name = "afs_gn_mknod";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_mknod), 0);
   data_name = "afs_gn_remove";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_remove), 0);
   data_name = "afs_gn_rename";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_rename), 0);
   data_name = "afs_gn_rmdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_rmdir), 0);
   data_name = "afs_gn_fid";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_fid), 0);
   data_name = "afs_gn_lookup";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_lookup), 0);
   data_name = "afs_gn_open";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_open), 0);
   data_name = "afs_gn_create";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_create), 0);
   data_name = "afs_gn_hold";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_hold), 0);
   data_name = "afs_gn_rele";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_rele), 0);
   data_name = "afs_gn_unmap";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_unmap), 0);
   data_name = "afs_gn_access";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_access), 0);
   data_name = "afs_gn_getattr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_getattr), 0);
   data_name = "afs_gn_setattr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_setattr), 0);
   data_name = "afs_gn_fclear";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_fclear), 0);
   data_name = "afs_gn_fsync";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gn_fsync), 0);
   data_name = "phash";
   hv_store(DATA, "pHash", strlen("pHash"), newSViv(cmp->callInfo.C_pHash),
            0);
   data_name = "DInit";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_DInit), 0);
   data_name = "DRead";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_DRead), 0);
   data_name = "FixupBucket";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_FixupBucket), 0);
   data_name = "afs_newslot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_newslot), 0);
   data_name = "DRelease";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_DRelease), 0);
   data_name = "DFlush";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_DFlush), 0);
   data_name = "DFlushEntry";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_DFlushEntry), 0);
   data_name = "DVOffset";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_DVOffset), 0);
   data_name = "DZap";
   hv_store(DATA, data_name, strlen(data_name), newSViv(cmp->callInfo.C_DZap),
            0);
   data_name = "DNew";
   hv_store(DATA, data_name, strlen(data_name), newSViv(cmp->callInfo.C_DNew),
            0);
   data_name = "afs_RemoveVCB";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_RemoveVCB), 0);
   data_name = "afs_NewVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_NewVCache), 0);
   data_name = "afs_FlushActiveVcaches";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FlushActiveVcaches), 0);
   data_name = "afs_VerifyVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_VerifyVCache), 0);
   data_name = "afs_WriteVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_WriteVCache), 0);
   data_name = "afs_GetVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetVCache), 0);
   data_name = "afs_StuffVcache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_StuffVcache), 0);
   data_name = "afs_FindVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FindVCache), 0);
   data_name = "afs_PutDCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PutDCache), 0);
   data_name = "afs_PutVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PutVCache), 0);
   data_name = "CacheStoreProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_CacheStoreProc), 0);
   data_name = "afs_FindDcache";
   hv_store(DATA, "afs_FindDCache", strlen("afs_FindDCache"),
            newSViv(cmp->callInfo.C_afs_FindDCache), 0);
   data_name = "afs_TryToSmush";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_TryToSmush), 0);
   data_name = "afs_AdjustSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_AdjustSize), 0);
   data_name = "afs_CheckSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckSize), 0);
   data_name = "afs_StoreWarn";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_StoreWarn), 0);
   data_name = "CacheFetchProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_CacheFetchProc), 0);
   data_name = "UFS_CacheStoreProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_UFS_CacheStoreProc), 0);
   data_name = "UFS_CacheFetchProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_UFS_CacheFetchProc), 0);
   data_name = "afs_GetDCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetDCache), 0);
   data_name = "afs_SimpleVStat";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_SimpleVStat), 0);
   data_name = "afs_ProcessFS";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ProcessFS), 0);
   data_name = "afs_InitCacheInfo";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_InitCacheInfo), 0);
   data_name = "afs_InitVolumeInfo";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_InitVolumeInfo), 0);
   data_name = "afs_InitCacheFile";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_InitCacheFile), 0);
   data_name = "afs_CacheInit";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CacheInit), 0);
   data_name = "afs_GetDSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetDSlot), 0);
   data_name = "afs_WriteThroughDSlots";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_WriteThroughDSlots), 0);
   data_name = "afs_MemGetDSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemGetDSlot), 0);
   data_name = "afs_UFSGetDSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_UFSGetDSlot), 0);
   data_name = "afs_StoreDCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_StoreDCache), 0);
   data_name = "afs_StoreMini";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_StoreMini), 0);
   data_name = "afs_StoreAllSegments";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_StoreAllSegments), 0);
   data_name = "afs_InvalidateAllSegments";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_InvalidateAllSegments), 0);
   data_name = "afs_TruncateAllSegments";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_TruncateAllSegments), 0);
   data_name = "afs_CheckVolSync";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckVolSync), 0);
   data_name = "afs_wakeup";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_wakeup), 0);
   data_name = "afs_CFileOpen";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CFileOpen), 0);
   data_name = "afs_CFileTruncate";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CFileTruncate), 0);
   data_name = "afs_GetDownD";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetDownD), 0);
   data_name = "afs_WriteDCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_WriteDCache), 0);
   data_name = "afs_FlushDCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FlushDCache), 0);
   data_name = "afs_GetDownDSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetDownDSlot), 0);
   data_name = "afs_FlushVCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FlushVCache), 0);
   data_name = "afs_GetDownV";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetDownV), 0);
   data_name = "afs_QueueVCB";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_QueueVCB), 0);
   data_name = "afs_call";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_call), 0);
   data_name = "afs_syscall_call";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syscall_call), 0);
   data_name = "afs_syscall_icreate";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syscall_icreate), 0);
   data_name = "afs_syscall_iopen";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syscall_iopen), 0);
   data_name = "afs_syscall_iincdec";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syscall_iincdec), 0);
   data_name = "afs_syscall_ireadwrite";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syscall_ireadwrite), 0);
   data_name = "afs_syscall";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syscall), 0);
   data_name = "lpioctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_lpioctl), 0);
   data_name = "lsetpag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_lsetpag), 0);
   data_name = "afs_CheckInit";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckInit), 0);
   data_name = "ClearCallback";
   hv_store(DATA, "ClearCallBack", strlen("ClearCallBack"),
            newSViv(cmp->callInfo.C_ClearCallBack), 0);
   data_name = "SRXAFSCB_GetCE";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_SRXAFSCB_GetCE), 0);
   data_name = "SRXAFSCB_GetLock";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_SRXAFSCB_GetLock), 0);
   data_name = "SRXAFSCB_CallBack";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_SRXAFSCB_CallBack), 0);
   data_name = "SRXAFSCB_InitCallBackState";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_SRXAFSCB_InitCallBackState), 0);
   data_name = "SRXAFSCB_Probe";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_SRXAFSCB_Probe), 0);
   data_name = "afs_Chunk";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_Chunk), 0);
   data_name = "afs_ChunkBase";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ChunkBase), 0);
   data_name = "afs_ChunkOffset";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ChunkOffset), 0);
   data_name = "afs_ChunkSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ChunkSize), 0);
   data_name = "afs_ChunkToBase";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ChunkToBase), 0);
   data_name = "afs_ChunkToSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ChunkToSize), 0);
   data_name = "afs_SetChunkSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_SetChunkSize), 0);
   data_name = "afs_config";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_config), 0);
   data_name = "mem_freebytes";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_mem_freebytes), 0);
   data_name = "mem_getbytes";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_mem_getbytes), 0);
   data_name = "afs_Daemon";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_Daemon), 0);
   data_name = "afs_CheckRootVolume";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckRootVolume), 0);
   data_name = "BPath";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_BPath), 0);
   data_name = "BPrefetch";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_BPrefetch), 0);
   data_name = "BStore";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_BStore), 0);
   data_name = "afs_BBusy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_BBusy), 0);
   data_name = "afs_BQueue";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_BQueue), 0);
   data_name = "afs_BRelease";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_BRelease), 0);
   data_name = "afs_BackgroundDaemon";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_BackgroundDaemon), 0);
   data_name = "exporter_add";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_exporter_add), 0);
   data_name = "exporter_find";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_exporter_find), 0);
   data_name = "afs_gfs_kalloc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gfs_kalloc), 0);
   data_name = "afs_gfs_kfree";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gfs_kfree), 0);
   data_name = "gop_lookupname";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_gop_lookupname), 0);
   data_name = "afs_uniqtime";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_uniqtime), 0);
   data_name = "gfs_vattr_null";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_gfs_vattr_null), 0);
   data_name = "afs_lock";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_lock), 0);
   data_name = "afs_unlock";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_unlock), 0);
   data_name = "afs_update";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_update), 0);
   data_name = "afs_gclose";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gclose), 0);
   data_name = "afs_gopen";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gopen), 0);
   data_name = "afs_greadlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_greadlink), 0);
   data_name = "afs_select";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_select), 0);
   data_name = "afs_gbmap";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gbmap), 0);
   data_name = "afs_getfsdata";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_getfsdata), 0);
   data_name = "afs_gsymlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gsymlink), 0);
   data_name = "afs_namei";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_namei), 0);
   data_name = "afs_gmount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gmount), 0);
   data_name = "afs_gget";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gget), 0);
   data_name = "afs_glink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_glink), 0);
   data_name = "afs_gmkdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_gmkdir), 0);
   data_name = "afs_unlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_unlink), 0);
   data_name = "afs_grmdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_grmdir), 0);
   data_name = "afs_makenode";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_makenode), 0);
   data_name = "afs_grename";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_grename), 0);
   data_name = "afs_rele";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_rele), 0);
   data_name = "afs_syncgp";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_syncgp), 0);
   data_name = "afs_getval";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_getval), 0);
   data_name = "afs_trunc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_trunc), 0);
   data_name = "afs_rwgp";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_rwgp), 0);
   data_name = "afs_stat";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_stat), 0);
   data_name = "afsc_link";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afsc_link), 0);
   data_name = "afs_vfs_mount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_vfs_mount), 0);
   data_name = "afs_uniqtime";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_uniqtime), 0);
   data_name = "iopen";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_iopen), 0);
   data_name = "idec";
   hv_store(DATA, data_name, strlen(data_name), newSViv(cmp->callInfo.C_idec),
            0);
   data_name = "iinc";
   hv_store(DATA, data_name, strlen(data_name), newSViv(cmp->callInfo.C_iinc),
            0);
   data_name = "ireadwrite";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_ireadwrite), 0);
   data_name = "iread";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_iread), 0);
   data_name = "iwrite";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_iwrite), 0);
   data_name = "iforget";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_iforget), 0);
   data_name = "icreate";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_icreate), 0);
   data_name = "igetinode";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_igetinode), 0);
   data_name = "osi_SleepR";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_SleepR), 0);
   data_name = "osi_SleepS";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_SleepS), 0);
   data_name = "osi_SleepW";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_SleepW), 0);
   data_name = "osi_Sleep";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Sleep), 0);
   data_name = "afs_LookupMCE";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_LookupMCE), 0);
   data_name = "afs_MemReadBlk";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemReadBlk), 0);
   data_name = "afs_MemReadUIO";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemReadUIO), 0);
   data_name = "afs_MemWriteBlk";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemWriteBlk), 0);
   data_name = "afs_MemWriteUIO";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemWriteUIO), 0);
   data_name = "afs_MemCacheStoreProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemCacheStoreProc), 0);
   data_name = "afs_MemCacheFetchProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemCacheFetchProc), 0);
   data_name = "afs_MemCacheTruncate";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemCacheTruncate), 0);
   data_name = "afs_MemCacheStoreProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemCacheStoreProc), 0);
   data_name = "afs_GetNfsClientPag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetNfsClientPag), 0);
   data_name = "afs_FindNfsClientPag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FindNfsClientPag), 0);
   data_name = "afs_PutNfsClientPag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PutNfsClientPag), 0);
   data_name = "afs_nfsclient_reqhandler";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nfsclient_reqhandler), 0);
   data_name = "afs_nfsclient_GC";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nfsclient_GC), 0);
   data_name = "afs_nfsclient_hold";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nfsclient_hold), 0);
   data_name = "afs_nfsclient_stats";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nfsclient_stats), 0);
   data_name = "afs_nfsclient_sysname";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nfsclient_sysname), 0);
   data_name = "afs_rfs_dispatch";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_rfs_dispatch), 0);
   data_name = "afs_nfs2afscall";
   hv_store(DATA, "Nfs2AfsCall", strlen("Nfs2AfsCall"),
            newSViv(cmp->callInfo.C_Nfs2AfsCall), 0);
   data_name = "afs_sun_xuntext";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_sun_xuntext), 0);
   data_name = "osi_Active";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Active), 0);
   data_name = "osi_FlushPages";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_FlushPages), 0);
   data_name = "osi_FlushText";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_FlushText), 0);
   data_name = "osi_CallProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_CallProc), 0);
   data_name = "osi_CancelProc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_CancelProc), 0);
   data_name = "osi_Invisible";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Invisible), 0);
   data_name = "osi_Time";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Time), 0);
   data_name = "osi_Alloc";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Alloc), 0);
   data_name = "osi_SetTime";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_SetTime), 0);
   data_name = "osi_Dump";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Dump), 0);
   data_name = "osi_Free";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Free), 0);
   data_name = "osi_UFSOpen";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_UFSOpen), 0);
   data_name = "osi_Close";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Close), 0);
   data_name = "osi_Stat";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Stat), 0);
   data_name = "osi_Truncate";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Truncate), 0);
   data_name = "osi_Read";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Read), 0);
   data_name = "osi_Write";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Write), 0);
   data_name = "osi_MapStrategy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_MapStrategy), 0);
   data_name = "osi_AllocLargeSpace";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_AllocLargeSpace), 0);
   data_name = "osi_FreeLargeSpace";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_FreeLargeSpace), 0);
   data_name = "osi_AllocSmallSpace";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_AllocSmallSpace), 0);
   data_name = "osi_FreeSmallSpace";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_FreeSmallSpace), 0);
   data_name = "osi_CloseToTheEdge";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_CloseToTheEdge), 0);
   data_name = "osi_xgreedy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_xgreedy), 0);
   data_name = "osi_FreeSocket";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_FreeSocket), 0);
   data_name = "osi_NewSocket";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_NewSocket), 0);
   data_name = "osi_NetSend";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_NetSend), 0);
   data_name = "WaitHack";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_WaitHack), 0);
   data_name = "osi_CancelWait";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_CancelWait), 0);
   data_name = "osi_Wakeup";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Wakeup), 0);
   data_name = "osi_Wait";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_osi_Wait), 0);
   data_name = "dirp_Read";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_dirp_Read), 0);
   data_name = "dirp_Cpy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_dirp_Cpy), 0);
   data_name = "dirp_Eq";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_dirp_Eq), 0);
   data_name = "dirp_Write";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_dirp_Write), 0);
   data_name = "dirp_Zap";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_dirp_Zap), 0);
   data_name = "afs_ioctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ioctl), 0);
   data_name = "handleIoctl";
   hv_store(DATA, "HandleIoctl", strlen("HandleIoctl"),
            newSViv(cmp->callInfo.C_HandleIoctl), 0);
   data_name = "afs_xioctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_xioctl), 0);
   data_name = "afs_pioctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_pioctl), 0);
   data_name = "HandlePioctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_HandlePioctl), 0);
   data_name = "PGetVolumeStatus";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetVolumeStatus), 0);
   data_name = "PSetVolumeStatus";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetVolumeStatus), 0);
   data_name = "PFlush";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PFlush), 0);
   data_name = "PFlushVolumeData";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PFlushVolumeData), 0);
   data_name = "PNewStatMount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PNewStatMount), 0);
   data_name = "PGetTokens";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetTokens), 0);
   data_name = "PSetTokens";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetTokens), 0);
   data_name = "PUnlog";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PUnlog), 0);
   data_name = "PCheckServers";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PCheckServers), 0);
   data_name = "PCheckAuth";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PCheckAuth), 0);
   data_name = "PCheckVolNames";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PCheckVolNames), 0);
   data_name = "PFindVolume";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PFindVolume), 0);
   data_name = "Prefetch";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_Prefetch), 0);
   data_name = "PGetCacheSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetCacheSize), 0);
   data_name = "PSetCacheSize";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetCacheSize), 0);
   data_name = "PSetSysName";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetSysName), 0);
   data_name = "PExportAfs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PExportAfs), 0);
   data_name = "HandleClientContext";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_HandleClientContext), 0);
   data_name = "PViceAccess";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PViceAccess), 0);
   data_name = "PRemoveCallBack";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PRemoveCallBack), 0);
   data_name = "PRemoveMount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PRemoveMount), 0);
   data_name = "PSetVolumeStatus";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetVolumeStatus), 0);
   data_name = "PListCells";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PListCells), 0);
   data_name = "PNewCell";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PNewCell), 0);
   data_name = "PGetUserCell";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetUserCell), 0);
   data_name = "PGetCellStatus";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetCellStatus), 0);
   data_name = "PSetCellStatus";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetCellStatus), 0);
   data_name = "PVenusLogging";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PVenusLogging), 0);
   data_name = "PGetAcl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetAcl), 0);
   data_name = "PGetFID";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetFID), 0);
   data_name = "PSetAcl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetAcl), 0);
   data_name = "PGetFileCell";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetFileCell), 0);
   data_name = "PGetWSCell";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetWSCell), 0);
   data_name = "PGetSPrefs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetSPrefs), 0);
   data_name = "PSetSPrefs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetSPrefs), 0);
   data_name = "afs_ResetAccessCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ResetAccessCache), 0);
   data_name = "afs_FindUser";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FindUser), 0);
   data_name = "afs_GetUser";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetUser), 0);
   data_name = "afs_GCUserData";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GCUserData), 0);
   data_name = "afs_PutUser";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PutUser), 0);
   data_name = "afs_SetPrimary";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_SetPrimary), 0);
   data_name = "afs_ResetUserConns";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ResetUserConns), 0);
   data_name = "afs_RemoveUserConns";
   hv_store(DATA, "RemoveUserConns", strlen("RemoveUserConns"),
            newSViv(cmp->callInfo.C_RemoveUserConns), 0);
   data_name = "afs_ResourceInit";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ResourceInit), 0);
   data_name = "afs_GetCell";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetCell), 0);
   data_name = "afs_GetCellByIndex";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetCellByIndex), 0);
   data_name = "afs_GetCellByName";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetCellByName), 0);
#ifdef GETREALCELLBYINDEX
   data_name = "afs_GetRealCellByIndex";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetRealCellByIndex), 0);
#endif
   data_name = "afs_NewCell";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_NewCell), 0);
   data_name = "CheckVLDB";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_CheckVLDB), 0);
   data_name = "afs_GetVolume";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetVolume), 0);
   data_name = "afs_PutVolume";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PutVolume), 0);
   data_name = "afs_GetVolumeByName";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetVolumeByName), 0);
   data_name = "afs_random";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_random), 0);
   data_name = "InstallVolumeEntry";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_InstallVolumeEntry), 0);
   data_name = "InstallVolumeInfo";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_InstallVolumeInfo), 0);
   data_name = "afs_ResetVolumeInfo";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ResetVolumeInfo), 0);
   data_name = "afs_FindServer";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FindServer), 0);
   data_name = "afs_GetServer";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetServer), 0);
   data_name = "afs_SortServers";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_SortServers), 0);
   data_name = "afs_CheckServers";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckServers), 0);
   data_name = "ServerDown";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_ServerDown), 0);
   data_name = "afs_Conn";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_Conn), 0);
   data_name = "afs_PutConn";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PutConn), 0);
   data_name = "afs_ConnByHost";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ConnByHost), 0);
   data_name = "afs_ConnByMHosts";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ConnByMHosts), 0);
   data_name = "afs_Analyze";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_Analyze), 0);
   data_name = "afs_CheckLocks";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckLocks), 0);
   data_name = "CheckVLServer";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_CheckVLServer), 0);
   data_name = "afs_CheckCacheResets";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckCacheResets), 0);
   data_name = "afs_CheckVolumeNames";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckVolumeNames), 0);
   data_name = "afs_CheckCode";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CheckCode), 0);
   data_name = "afs_CopyError";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CopyError), 0);
   data_name = "afs_FinalizeReq";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FinalizeReq), 0);
   data_name = "afs_GetVolCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetVolCache), 0);
   data_name = "afs_GetVolSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetVolSlot), 0);
   data_name = "afs_UFSGetVolSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_UFSGetVolSlot), 0);
   data_name = "afs_MemGetVolSlot";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemGetVolSlot), 0);
   data_name = "afs_WriteVolCache";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_WriteVolCache), 0);
   data_name = "haveCallbacksfrom";
   hv_store(DATA, "HaveCallBacksFrom", strlen("HaveCallBacksFrom"),
            newSViv(cmp->callInfo.C_HaveCallBacksFrom), 0);
   data_name = "afs_getpage";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_getpage), 0);
   data_name = "afs_putpage";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_putpage), 0);
   data_name = "afs_nfsrdwr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nfsrdwr), 0);
   data_name = "afs_map";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_map), 0);
   data_name = "afs_cmp";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_cmp), 0);
   data_name = "afs_PageLeft";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_PageLeft), 0);
   data_name = "afs_mount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_mount), 0);
   data_name = "afs_unmount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_unmount), 0);
   data_name = "afs_root";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_root), 0);
   data_name = "afs_statfs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_statfs), 0);
   data_name = "afs_sync";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_sync), 0);
   data_name = "afs_vget";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_vget), 0);
   data_name = "afs_index";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_index), 0);
   data_name = "afs_setpag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_setpag), 0);
   data_name = "genpag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_genpag), 0);
   data_name = "getpag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_getpag), 0);
   data_name = "genpag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_genpag), 0);
   data_name = "afs_GetMariner";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetMariner), 0);
   data_name = "afs_AddMarinerName";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_AddMarinerName), 0);
   data_name = "afs_open";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_open), 0);
   data_name = "afs_close";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_close), 0);
   data_name = "afs_closex";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_closex), 0);
   data_name = "afs_write";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_write), 0);
   data_name = "afs_UFSwrite";
   hv_store(DATA, "afs_UFSWrite", strlen("afs_UFSWrite"),
            newSViv(cmp->callInfo.C_afs_UFSWrite), 0);
   data_name = "afs_Memwrite";
   hv_store(DATA, "afs_MemWrite", strlen("afs_MemWrite"),
            newSViv(cmp->callInfo.C_afs_MemWrite), 0);
   data_name = "afs_rdwr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_rdwr), 0);
   data_name = "afs_read";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_read), 0);
   data_name = "afs_UFSread";
   hv_store(DATA, "afs_UFSRead", strlen("afs_UFSRead"),
            newSViv(cmp->callInfo.C_afs_UFSRead), 0);
   data_name = "afs_Memread";
   hv_store(DATA, "afs_MemRead", strlen("afs_MemRead"),
            newSViv(cmp->callInfo.C_afs_MemRead), 0);
   data_name = "afs_CopyOutAttrs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_CopyOutAttrs), 0);
   data_name = "afs_access";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_access), 0);
   data_name = "afs_getattr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_getattr), 0);
   data_name = "afs_setattr";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_setattr), 0);
   data_name = "afs_VAttrToAS";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_VAttrToAS), 0);
   data_name = "EvalMountPoint";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_EvalMountPoint), 0);
   data_name = "afs_lookup";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_lookup), 0);
   data_name = "afs_create";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_create), 0);
   data_name = "afs_LocalHero";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_LocalHero), 0);
   data_name = "afs_remove";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_remove), 0);
   data_name = "afs_link";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_link), 0);
   data_name = "afs_rename";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_rename), 0);
   data_name = "afs_InitReq";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_InitReq), 0);
   data_name = "afs_mkdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_mkdir), 0);
   data_name = "afs_rmdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_rmdir), 0);
   data_name = "afs_readdir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_readdir), 0);
   data_name = "afs_read1dir";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_read1dir), 0);
   data_name = "afs_readdir_move";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_readdir_move), 0);
   data_name = "afs_readdir_iter";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_readdir_iter), 0);
   data_name = "afs_symlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_symlink), 0);
   data_name = "afs_HandleLink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_HandleLink), 0);
   data_name = "afs_MemHandleLink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_MemHandleLink), 0);
   data_name = "afs_UFSHandleLink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_UFSHandleLink), 0);
   data_name = "HandleFlock";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_HandleFlock), 0);
   data_name = "afs_readlink";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_readlink), 0);
   data_name = "afs_fsync";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_fsync), 0);
   data_name = "afs_inactive";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_inactive), 0);
   data_name = "afs_ustrategy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_ustrategy), 0);
   data_name = "afs_strategy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_strategy), 0);
   data_name = "afs_bread";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_bread), 0);
   data_name = "afs_brelse";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_brelse), 0);
   data_name = "afs_bmap";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_bmap), 0);
   data_name = "afs_fid";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_fid), 0);
   data_name = "afs_FakeOpen";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FakeOpen), 0);
   data_name = "afs_FakeClose";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_FakeClose), 0);
   data_name = "afs_StoreOnLastReference";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_StoreOnLastReference), 0);
   data_name = "afs_AccessOK";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_AccessOK), 0);
   data_name = "afs_GetAccessBits";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_GetAccessBits), 0);
   data_name = "afsio_copy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afsio_copy), 0);
   data_name = "afsio_trim";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afsio_trim), 0);
   data_name = "afsio_skip";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afsio_skip), 0);
   data_name = "afs_page_read";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_page_read), 0);
   data_name = "afs_page_write";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_page_write), 0);
   data_name = "afs_page_read";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_page_read), 0);
   data_name = "afs_get_groups_from_pag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_get_groups_from_pag), 0);
   data_name = "afs_get_pag_from_groups";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_get_pag_from_groups), 0);
   data_name = "AddPag";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_AddPag), 0);
   data_name = "PagInCred";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PagInCred), 0);
   data_name = "afs_getgroups";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_getgroups), 0);
   data_name = "afs_page_in";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_page_in), 0);
   data_name = "afs_page_out";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_page_out), 0);
   data_name = "afs_AdvanceFD";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_AdvanceFD), 0);
   data_name = "afs_lockf";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_lockf), 0);
   data_name = "afs_xsetgroups";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_xsetgroups), 0);
   data_name = "afs_nlinks";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_nlinks), 0);
   data_name = "afs_lockctl";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_lockctl), 0);
   data_name = "afs_xflock";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_xflock), 0);
   data_name = "PGetCPrefs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PGetCPrefs), 0);
   data_name = "PSetCPrefs";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PSetCPrefs), 0);
#ifdef	AFS_HPUX_ENV
   data_name = "afs_pagein";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_pagein), 0);
   data_name = "afs_pageout";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_pageout), 0);
   data_name = "afs_hp_strategy";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_afs_hp_strategy), 0);
#endif
   data_name = "PFlushMount";
   hv_store(DATA, data_name, strlen(data_name),
            newSViv(cmp->callInfo.C_PFlushMount), 0);


   hv_store(HOSTINFO, "data", 4, newRV_inc((SV *) DATA), 0);

}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintUpDownStats(struct afs_stats_SrvUpDownInfo *a_upDownP, AV *UPDOWN, int index)
{
   HV *INFO = newHV();
   AV *DOWNDURATIONS = newAV();
   AV *DOWNINCIDENTS = newAV();
   int i;

   /*
    * First, print the simple values.
    */
   hv_store(INFO, "numTtlRecords", strlen("numTtlRecords"),
            newSViv(a_upDownP->numTtlRecords), 0);
   hv_store(INFO, "numUpRecords", strlen("numUpRecords"),
            newSViv(a_upDownP->numUpRecords), 0);
   hv_store(INFO, "numDownRecords", strlen("numDownRecords"),
            newSViv(a_upDownP->numDownRecords), 0);
   hv_store(INFO, "sumOfRecordAges", strlen("sumOfRecordAges"),
            newSViv(a_upDownP->sumOfRecordAges), 0);
   hv_store(INFO, "ageOfYoungestRecord", strlen("ageOfYoungestRecord"),
            newSViv(a_upDownP->ageOfYoungestRecord), 0);
   hv_store(INFO, "ageOfOldestRecord", strlen("ageOfOldestRecord"),
            newSViv(a_upDownP->ageOfOldestRecord), 0);
   hv_store(INFO, "numDowntimeIncidents", strlen("numDowntimeIncidents"),
            newSViv(a_upDownP->numDowntimeIncidents), 0);
   hv_store(INFO, "numRecordsNeverDown", strlen("numRecordsNeverDown"),
            newSViv(a_upDownP->numRecordsNeverDown), 0);
   hv_store(INFO, "maxDowntimesInARecord", strlen("maxDowntimesInARecord"),
            newSViv(a_upDownP->maxDowntimesInARecord), 0);
   hv_store(INFO, "sumOfDowntimes", strlen("sumOfDowntimes"),
            newSViv(a_upDownP->sumOfDowntimes), 0);
   hv_store(INFO, "shortestDowntime", strlen("shortestDowntime"),
            newSViv(a_upDownP->shortestDowntime), 0);
   hv_store(INFO, "longestDowntime", strlen("longestDowntime"),
            newSViv(a_upDownP->longestDowntime), 0);

   /*
    * Now, print the array values.
    */
   for (i = 0; i <= 6; i++) {
      av_store(DOWNDURATIONS, i, newSViv(a_upDownP->downDurations[i]));
   }
   for (i = 0; i <= 5; i++) {
      av_store(DOWNINCIDENTS, i, newSViv(a_upDownP->downIncidents[i]));
   }
   hv_store(INFO, "downDurations", 13, newRV_inc((SV *) DOWNDURATIONS), 0);
   hv_store(INFO, "downIncidents", 13, newRV_inc((SV *) DOWNINCIDENTS), 0);
   av_store(UPDOWN, index, newRV_inc((SV *) INFO));
}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintOverallPerfInfo(struct afs_stats_CMPerf *a_ovP, HV *PERF)
{
   char *data_name;
   AV *FS_UPDOWN = newAV();
   AV *VL_UPDOWN = newAV();

   data_name = "numPerfCalls";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->numPerfCalls),
            0);
   data_name = "epoch";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->epoch), 0);
   data_name = "numCellsVisible";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->numCellsVisible), 0);
   data_name = "numCellsContacted";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->numCellsContacted), 0);
   data_name = "dlocalAccesses";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->dlocalAccesses), 0);
   data_name = "vlocalAccesses";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->vlocalAccesses), 0);
   data_name = "dremoteAccesses";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->dremoteAccesses), 0);
   data_name = "vremoteAccesses";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->vremoteAccesses), 0);
   data_name = "cacheNumEntries";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheNumEntries), 0);
   data_name = "cacheBlocksTotal";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheBlocksTotal), 0);
   data_name = "cacheBlocksInUse";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheBlocksInUse), 0);
   data_name = "cacheBlocksOrig";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheBlocksOrig), 0);
   data_name = "cacheMaxDirtyChunks";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheMaxDirtyChunks), 0);
   data_name = "cacheCurrDirtyChunks";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheCurrDirtyChunks), 0);
   data_name = "dcacheHits";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->dcacheHits),
            0);
   data_name = "vcacheHits";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->vcacheHits),
            0);
   data_name = "dcacheMisses";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->dcacheMisses),
            0);
   data_name = "vcacheMisses";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->vcacheMisses),
            0);
   data_name = "cacheFilesReused";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->cacheFilesReused), 0);
   data_name = "vcacheXAllocs";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->vcacheXAllocs),
            0);
   data_name = "dcacheXAllocs";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->dcacheXAllocs),
            0);
   data_name = "bufAlloced";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->bufAlloced),
            0);
   data_name = "bufHits";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->bufHits), 0);
   data_name = "bufMisses";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->bufMisses), 0);
   data_name = "bufFlushDirty";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->bufFlushDirty),
            0);
   data_name = "LargeBlocksActive";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->LargeBlocksActive), 0);
   data_name = "LargeBlocksAlloced";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->LargeBlocksAlloced), 0);
   data_name = "SmallBlocksActive";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->SmallBlocksActive), 0);
   data_name = "SmallBlocksAlloced";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->SmallBlocksAlloced), 0);
   data_name = "OutStandingMemUsage";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->OutStandingMemUsage), 0);
   data_name = "OutStandingAllocs";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->OutStandingAllocs), 0);
   data_name = "CallBackAlloced";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->CallBackAlloced), 0);
   data_name = "CallBackFlushes";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->CallBackFlushes), 0);
   data_name = "CallBackLoops";
   hv_store(PERF, "cbloops", strlen("cbloops"), newSViv(a_ovP->cbloops), 0);
   data_name = "srvRecords";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->srvRecords),
            0);
   data_name = "srvNumBuckets";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->srvNumBuckets),
            0);
   data_name = "srvMaxChainLength";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->srvMaxChainLength), 0);
   data_name = "srvMaxChainLengthHWM";
   hv_store(PERF, data_name, strlen(data_name),
            newSViv(a_ovP->srvMaxChainLengthHWM), 0);
   data_name = "srvRecordsHWM";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->srvRecordsHWM),
            0);
   data_name = "sysName_ID";
   hv_store(PERF, data_name, strlen(data_name), newSViv(a_ovP->sysName_ID),
            0);

   my_cm_PrintUpDownStats(&(a_ovP->fs_UpDown[0]), FS_UPDOWN, 0);

   my_cm_PrintUpDownStats(&(a_ovP->fs_UpDown[1]), FS_UPDOWN, 1);

   my_cm_PrintUpDownStats(&(a_ovP->vl_UpDown[0]), VL_UPDOWN, 0);

   my_cm_PrintUpDownStats(&(a_ovP->vl_UpDown[1]), VL_UPDOWN, 1);

   hv_store(PERF, "fs_UpDown", 9, newRV_inc((SV *) FS_UPDOWN), 0);
   hv_store(PERF, "vl_UpDown", 9, newRV_inc((SV *) VL_UPDOWN), 0);

}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintOpTiming(a_opIdx, a_opNames, a_opTimeP, RPCTIMES)
   int a_opIdx;
   char *a_opNames[];
   struct afs_stats_opTimingData *a_opTimeP;
   HV *RPCTIMES;
{
   HV *TIMES = newHV();
   hv_store(TIMES, "numOps", 6, newSViv(a_opTimeP->numOps), 0);
   hv_store(TIMES, "numSuccesses", 12, newSViv(a_opTimeP->numSuccesses), 0);

   hv_store(TIMES, "sumTime", 7, newSVnv(a_opTimeP->sumTime.tv_sec
                                         +
                                         (a_opTimeP->sumTime.tv_usec /
                                          1000000.0)), 0);
   hv_store(TIMES, "sqrTime", 7,
            newSVnv(a_opTimeP->sqrTime.tv_sec +
                    (a_opTimeP->sqrTime.tv_usec / 1000000.0)), 0);
   hv_store(TIMES, "minTime", 7,
            newSVnv(a_opTimeP->minTime.tv_sec +
                    (a_opTimeP->minTime.tv_usec / 1000000.0)), 0);
   hv_store(TIMES, "maxTime", 7,
            newSVnv(a_opTimeP->maxTime.tv_sec +
                    (a_opTimeP->maxTime.tv_usec / 1000000.0)), 0);

   hv_store(RPCTIMES, a_opNames[a_opIdx], strlen(a_opNames[a_opIdx]),
            newRV_inc((SV *) TIMES), 0);
}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintErrInfo(a_opIdx, a_opNames, a_opErrP, RPCERRORS)
   int a_opIdx;
   char *a_opNames[];
   struct afs_stats_RPCErrors *a_opErrP;
   HV *RPCERRORS;
{
   HV *ERRORS = newHV();

   hv_store(ERRORS, "err_Server",       10, newSViv(a_opErrP->err_Server), 0);
   hv_store(ERRORS, "err_Network",      11, newSViv(a_opErrP->err_Network), 0);
   hv_store(ERRORS, "err_Protection",   14, newSViv(a_opErrP->err_Protection), 0);
   hv_store(ERRORS, "err_Volume",       10, newSViv(a_opErrP->err_Volume), 0);
   hv_store(ERRORS, "err_VolumeBusies", 16, newSViv(a_opErrP->err_VolumeBusies), 0);
   hv_store(ERRORS, "err_Other",         9, newSViv(a_opErrP->err_Other), 0);

   hv_store(RPCERRORS, a_opNames[a_opIdx], strlen(a_opNames[a_opIdx]),
            newRV_inc((SV *) ERRORS), 0);
}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintXferTiming(a_opIdx, a_opNames, a_xferP, XFERTIMES)
   int a_opIdx;
   char *a_opNames[];
   struct afs_stats_xferData *a_xferP;
   HV *XFERTIMES;
{
   HV *TIMES = newHV();
   AV *COUNT = newAV();
   int i;

   hv_store(TIMES, "numXfers", 8, newSViv(a_xferP->numXfers), 0);
   hv_store(TIMES, "numSuccesses", 12, newSViv(a_xferP->numSuccesses), 0);
   hv_store(TIMES, "sumTime", 7, newSVnv(a_xferP->sumTime.tv_sec
                                         +
                                         (a_xferP->sumTime.tv_usec /
                                          1000000.0)), 0);
   hv_store(TIMES, "sqrTime", 7, newSVnv(a_xferP->sqrTime.tv_sec +
                                 (a_xferP->sqrTime.tv_usec / 1000000.0)), 0);
   hv_store(TIMES, "minTime", 7, newSVnv(a_xferP->minTime.tv_sec +
                                 (a_xferP->minTime.tv_usec / 1000000.0)), 0);
   hv_store(TIMES, "maxTime", 7, newSVnv(a_xferP->maxTime.tv_sec +
                                 (a_xferP->maxTime.tv_usec / 1000000.0)), 0);
   hv_store(TIMES, "sumBytes", 8, newSViv(a_xferP->sumBytes), 0);
   hv_store(TIMES, "minBytes", 8, newSViv(a_xferP->minBytes), 0);
   hv_store(TIMES, "maxBytes", 8, newSViv(a_xferP->maxBytes), 0);


   for (i = 0; i <= 8; i++)
      av_store(COUNT, i, newSViv(a_xferP->count[i]));

   hv_store(TIMES, "count", 5, newRV_inc((SV *) COUNT), 0);

   hv_store(XFERTIMES, a_opNames[a_opIdx], strlen(a_opNames[a_opIdx]),
            newRV_inc((SV *) TIMES), 0);
}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_PrintRPCPerfInfo(struct afs_stats_RPCOpInfo *a_rpcP, HV *RPC)
{
   int currIdx;
   HV *FSRPCTIMES  = newHV();
   HV *FSRPCERRORS = newHV();
   HV *FSXFERTIMES = newHV();
   HV *CMRPCTIMES  = newHV();

   for (currIdx = 0; currIdx < AFS_STATS_NUM_FS_RPC_OPS; currIdx++)
      my_cm_PrintOpTiming(currIdx, fsOpNames, &(a_rpcP->fsRPCTimes[currIdx]),
                          FSRPCTIMES);

   hv_store(RPC, "fsRPCTimes", 10, newRV_inc((SV *) FSRPCTIMES), 0);

   for (currIdx = 0; currIdx < AFS_STATS_NUM_FS_RPC_OPS; currIdx++)
      my_cm_PrintErrInfo(currIdx, fsOpNames, &(a_rpcP->fsRPCErrors[currIdx]),
                         FSRPCERRORS);

   hv_store(RPC, "fsRPCErrors", 11, newRV_inc((SV *) FSRPCERRORS), 0);

   for (currIdx = 0; currIdx < AFS_STATS_NUM_FS_XFER_OPS; currIdx++)
      my_cm_PrintXferTiming(currIdx, xferOpNames,
                            &(a_rpcP->fsXferTimes[currIdx]), FSXFERTIMES);

   hv_store(RPC, "fsXferTimes", 11, newRV_inc((SV *) FSXFERTIMES), 0);

   for (currIdx = 0; currIdx < AFS_STATS_NUM_CM_RPC_OPS; currIdx++)
      my_cm_PrintOpTiming(currIdx, cmOpNames, &(a_rpcP->cmRPCTimes[currIdx]),
                          CMRPCTIMES);

   hv_store(RPC, "cmRPCTimes", 10, newRV_inc((SV *) CMRPCTIMES), 0);

}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintFullPerfInfo(struct xstat_cm_ProbeResults *xstat_cm_Results, HV *HOSTINFO)
{
   /*Ptr to authentication stats */
   struct afs_stats_AuthentInfo *authentP;
   /*Ptr to access stats */
   struct afs_stats_AccessInfo *accessinfP;
   /*Correct #int32s */
   static afs_int32 fullPerfInt32s = (sizeof(struct afs_stats_CMFullPerf) >> 2);
   /*# int32s actually received */
   afs_int32 numInt32s;
   struct afs_stats_CMFullPerf *fullP;
   HV *DATA      = newHV();
   HV *PERF      = newHV();
   HV *RPC       = newHV();
   HV *AUTHENT   = newHV();
   HV *ACCESSINF = newHV();

   numInt32s = xstat_cm_Results->data.AFSCB_CollData_len;
   if (numInt32s != fullPerfInt32s) {
      warn("** Data size mismatch in performance collection!");
      warn("** Expecting %d, got %d\n", fullPerfInt32s, numInt32s);
      warn("** Version mismatch with Cache Manager\n");
      return;
   }
   fullP = (struct afs_stats_CMFullPerf *)
      (xstat_cm_Results->data.AFSCB_CollData_val);

   my_cm_PrintOverallPerfInfo(&(fullP->perf), PERF);
   hv_store(DATA, "perf", 4, newRV_inc((SV *) PERF), 0);
   my_PrintRPCPerfInfo(&(fullP->rpc), RPC);
   hv_store(DATA, "rpc", 3, newRV_inc((SV *) RPC), 0);

   authentP = &(fullP->authent);

   hv_store(AUTHENT, "curr_PAGs", 9, newSViv(authentP->curr_PAGs), 0);
   hv_store(AUTHENT, "curr_Records", 12, newSViv(authentP->curr_Records), 0);
   hv_store(AUTHENT, "curr_AuthRecords", 16,
            newSViv(authentP->curr_AuthRecords), 0);
   hv_store(AUTHENT, "curr_UnauthRecords", 18,
            newSViv(authentP->curr_UnauthRecords), 0);
   hv_store(AUTHENT, "curr_MaxRecordsInPAG", 20,
            newSViv(authentP->curr_MaxRecordsInPAG), 0);
   hv_store(AUTHENT, "curr_LongestChain", 17,
            newSViv(authentP->curr_LongestChain), 0);
   hv_store(AUTHENT, "PAGCreations", 12, newSViv(authentP->PAGCreations), 0);
   hv_store(AUTHENT, "TicketUpdates", 13, newSViv(authentP->TicketUpdates),
            0);
   hv_store(AUTHENT, "HWM_PAGs", 8, newSViv(authentP->HWM_PAGs), 0);
   hv_store(AUTHENT, "HWM_Records", 11, newSViv(authentP->HWM_Records), 0);
   hv_store(AUTHENT, "HWM_MaxRecordsInPAG", 19,
            newSViv(authentP->HWM_MaxRecordsInPAG), 0);
   hv_store(AUTHENT, "HWM_LongestChain", 16,
            newSViv(authentP->HWM_LongestChain), 0);
   hv_store(DATA, "authent", 7, newRV_inc((SV *) AUTHENT), 0);

   accessinfP = &(fullP->accessinf);

   hv_store(ACCESSINF, "unreplicatedRefs", 16,
            newSViv(accessinfP->unreplicatedRefs), 0);
   hv_store(ACCESSINF, "replicatedRefs", 14,
            newSViv(accessinfP->replicatedRefs), 0);
   hv_store(ACCESSINF, "numReplicasAccessed", 19,
            newSViv(accessinfP->numReplicasAccessed), 0);
   hv_store(ACCESSINF, "maxReplicasPerRef", 17,
            newSViv(accessinfP->maxReplicasPerRef), 0);
   hv_store(ACCESSINF, "refFirstReplicaOK", 17,
            newSViv(accessinfP->refFirstReplicaOK), 0);
   hv_store(DATA, "accessinf", 9, newRV_inc((SV *) ACCESSINF), 0);

   hv_store(HOSTINFO, "data", 4, newRV_inc((SV *) DATA), 0);
}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

void
my_cm_PrintPerfInfo(struct xstat_cm_ProbeResults *xstat_cm_Results, HV *HOSTINFO)
{
   /*Correct # int32s to rcv */
   static afs_int32 perfInt32s = (sizeof(struct afs_stats_CMPerf) >> 2);
   /*# int32words received */
   afs_int32 numInt32s;
   /*Ptr to performance stats */
   struct afs_stats_CMPerf *perfP;
   HV *DATA = newHV();

   numInt32s = xstat_cm_Results->data.AFSCB_CollData_len;
   if (numInt32s != perfInt32s) {
      warn("** Data size mismatch in performance collection!");
      warn("** Expecting %d, got %d\n", perfInt32s, numInt32s);
      warn("** Version mismatch with Cache Manager\n");
      return;
   }
   perfP = (struct afs_stats_CMPerf *)
      (xstat_cm_Results->data.AFSCB_CollData_val);

   my_cm_PrintOverallPerfInfo(perfP, DATA);
   hv_store(HOSTINFO, "data", 4, newRV_inc((SV *) DATA), 0);
}


/*
 * from src/xstat/xstat_cm_test.c
 *    ("$Header: /afs/slac/g/scs/slur/Repository/AFSDebug/Debug/src/Monitor.xs,v 1.2 2006/07/05 22:25:10 alfw Exp $");
 */

int
my_xstat_CM_Handler(xstat_cm_Results, xstat_cm_numServers, index, buffer,
                    argp)
   struct xstat_cm_ProbeResults xstat_cm_Results;
   int xstat_cm_numServers;
   int index;
   char *buffer;
   va_list argp;
{
   AV *RETVAL = va_arg(argp, AV *);

   HV *HOSTINFO = newHV();

   hv_store(HOSTINFO, "probeOK", 7, newSViv(xstat_cm_Results.probeOK ? 0 : 1),
            0);
   hv_store(HOSTINFO, "hostName", 8,
            newSVpv(xstat_cm_Results.connP->hostName, 0), 0);
   hv_store(HOSTINFO, "collectionNumber", 16,
            newSViv(xstat_cm_Results.collectionNumber), 0);
   hv_store(HOSTINFO, "probeTime", 9, newSViv(xstat_cm_Results.probeTime), 0);

   if (xstat_cm_Results.probeOK == 0) {
      switch (xstat_cm_Results.collectionNumber) {
           /* Why are so many things commented out? -EC */
        case AFSCB_XSTATSCOLL_CALL_INFO:
           /* Why was this commented out in 3.3 ? */
           /* PrintCallInfo();  */
           my_print_cmCallStats(&xstat_cm_Results, HOSTINFO);
           break;

        case AFSCB_XSTATSCOLL_PERF_INFO:
           /* we will do nothing here */
           /* PrintPerfInfo(); */
           my_cm_PrintPerfInfo(&xstat_cm_Results, HOSTINFO);
           break;

        case AFSCB_XSTATSCOLL_FULL_PERF_INFO:
           my_cm_PrintFullPerfInfo(&xstat_cm_Results, HOSTINFO);
           break;

        default:
           sprintf(buffer, "** Unknown collection: %d",
                   xstat_cm_Results.collectionNumber);
           return (-1);
      }
   }


   av_store(RETVAL, index, newRV_inc((SV *) HOSTINFO));
   return (0);
}


/* end of xstat_cm_test helper functions */



MODULE = AFS::Monitor    PACKAGE = AFS::Monitor    PREFIX = afs_
PROTOTYPES: ENABLE

BOOT:
    initialize_rxk_error_table();


void
afs_do_xstat_cm_test(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {
    SV *value;
    I32 keylen = 0;
    char *key;
    int num_args = 0;
    char buffer[256] = "";
    AV *host_array=0;
    AV *coll_array=0;
    int code;                          /*Return code*/
    int numCMs=0;                      /*# Cache Managers to monitor*/
    int numCollIDs=0;                  /*# collections to fetch*/
    int currCM;                        /*Loop index*/
    int currCollIDIdx;                 /*Index of current collection ID*/
    afs_int32 *collIDP;                /*Ptr to array of collection IDs*/
    afs_int32 *currCollIDP;            /*Ptr to current collection ID*/
    struct sockaddr_in *CMSktArray;    /*Cache Manager socket array */
    struct hostent *he;                /*Host entry*/

    AV *RETVAL = newAV();

    /* parse arguments */
    num_args = hv_iterinit(args);
    while (num_args--) {

      value = hv_iternextsv(args, &key, &keylen);

      if(strncmp(key, "collID", keylen) == 0 && keylen <= 6) {
        if (SvROK(value))
          coll_array = (AV*) SvRV(value);
        else {
          coll_array = av_make(1, &value);
          sv_2mortal((SV *) coll_array);
        }
        numCollIDs = av_len(coll_array) + 1;
      }
      else if(strncmp(key, "cmname", keylen) == 0 && keylen <= 6) {
        if (SvROK(value))
          host_array = (AV*) SvRV(value);
        else {
          host_array = av_make(1, &value);
          sv_2mortal((SV *) host_array);
        }
        numCMs = av_len(host_array) + 1;
      }
      else {
        sprintf(buffer, "Unrecognized flag: %s", key);
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      } /* end ifs */

    } /* end while */
    /* done parsing arguments */

    if (host_array == 0) {
      sprintf(buffer, "Missing required parameter 'cmname'");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    else if (numCMs == 0) {
      sprintf(buffer, "The field 'cmname' isn't completed properly");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    else if (coll_array == 0) {
      sprintf(buffer, "Missing required parameter 'collID'");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    else if (numCollIDs == 0) {
      sprintf(buffer, "The field 'collID' isn't completed properly");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }

    CMSktArray = (struct sockaddr_in *)
        malloc(numCMs * sizeof(struct sockaddr_in));
    if (CMSktArray == (struct sockaddr_in *) NULL) {
        sprintf(buffer, "Can't allocate socket array for %d Cache Managers",
                numCMs);
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
    }

    for (currCM = 0; currCM < numCMs; currCM++) {
#if defined(AFS_DARWIN_ENV) || defined(AFS_FBSD_ENV)
        CMSktArray[currCM].sin_family = AF_INET;        /*Internet family */
#else
        CMSktArray[currCM].sin_family = htons(AF_INET); /*Internet family */
#endif
        CMSktArray[currCM].sin_port = htons(7001);      /*Cache Manager port */
        he = hostutil_GetHostByName((char *) SvPV(*av_fetch(host_array, currCM, 0), PL_na));
        if (he == (struct hostent *) NULL) {
            sprintf(buffer,
                    "Can't get host info for '%s'\n",
                    (char *) SvPV(*av_fetch(host_array, currCM, 0), PL_na));
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        memcpy(&(CMSktArray[currCM].sin_addr.s_addr), he->h_addr, 4);

    } /*Get socket info for each Cache Manager*/

    collIDP = (afs_int32 *) malloc(numCollIDs * sizeof(afs_int32));
    currCollIDP = collIDP;
    for (currCollIDIdx = 0; currCollIDIdx < numCollIDs; currCollIDIdx++) {
	*currCollIDP = (afs_int32) SvIV(*av_fetch(coll_array, currCollIDIdx, 0));
	currCollIDP++;
    }

    code = my_xstat_cm_Init(my_xstat_CM_Handler, numCMs, CMSktArray,
                            numCollIDs, collIDP, buffer, RETVAL);
    if(code) {
       BSETCODE(code, buffer);
       XSRETURN_UNDEF;
    }

    ST(0) = sv_2mortal(newRV_inc((SV*)RETVAL));
    SETCODE(0);
    XSRETURN(1);
  }


void
afs_do_xstat_fs_test(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {
    SV *value;
    I32 keylen = 0;
    char *key;
    int num_args = 0;
    char buffer[256] = "";
    AV *host_array=0;
    AV *coll_array=0;
    int code;                          /*Return code*/
    int numFSs=0;                      /*# File Servers to monitor*/
    int numCollIDs=0;                  /*# collections to fetch*/
    int currFS;                        /*Loop index*/
    int currCollIDIdx;                 /*Index of current collection ID*/
    afs_int32 *collIDP;                /*Ptr to array of collection IDs*/
    afs_int32 *currCollIDP;            /*Ptr to current collection ID*/
    struct sockaddr_in *FSSktArray;    /*File Server socket array */
    int sktbytes;
    struct hostent *he;                /*Host entry*/

    AV *RETVAL = newAV();


    /* parse arguments */
    num_args = hv_iterinit(args);
    while (num_args--) {

      value = hv_iternextsv(args, &key, &keylen);

      switch (*key) {

        case 'c':
          if(strncmp(key, "collID", keylen) == 0 && keylen <= 6) {
            if (SvROK(value))
              coll_array = (AV*) SvRV(value);
            else {
              coll_array = av_make(1, &value);
              sv_2mortal((SV *) coll_array);
            }
            numCollIDs = av_len(coll_array) + 1;
          } else goto unrecognized;
        break;

        case 'f':
          if(strncmp(key, "fsname", keylen) == 0 && keylen <= 6) {
            if (SvROK(value))
              host_array = (AV*) SvRV(value);
            else {
              host_array = av_make(1, &value);
              sv_2mortal((SV *) host_array);
            }
            numFSs = av_len(host_array) + 1;
          } else goto unrecognized;
        break;

        default:
          unrecognized:
          sprintf(buffer, "Unrecognized flag: %s", key);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
        break;
      } /* end switch */
    } /* end while */
    /* done parsing arguments */

    if (host_array == 0) {
      sprintf(buffer, "Missing required parameter 'fsname'");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    else if (numFSs == 0) {
      sprintf(buffer, "The field 'fsname' isn't completed properly");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    else if (coll_array == 0) {
      sprintf(buffer, "Missing required parameter 'collID'");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    else if (numCollIDs == 0) {
      sprintf(buffer, "The field 'collID' isn't completed properly");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }

    sktbytes = numFSs * sizeof(struct sockaddr_in);
    FSSktArray = (struct sockaddr_in *) malloc(sktbytes);
    if (FSSktArray == (struct sockaddr_in *) NULL) {
      sprintf(buffer,
              "Can't malloc() %d sockaddrs (%d bytes) for the given file servers",
              numFSs, sktbytes);
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }
    memset(FSSktArray, 0, sktbytes);

     /*
     * Fill in the socket array for each of the File Servers listed.
     */
    for (currFS = 0; currFS < numFSs; currFS++) {
#if defined(AFS_DARWIN_ENV) || defined(AFS_FBSD_ENV)
        FSSktArray[currFS].sin_family = AF_INET;        /*Internet family */
#else
        FSSktArray[currFS].sin_family = htons(AF_INET); /*Internet family */
#endif
	FSSktArray[currFS].sin_port   = htons(7000);	/*FileServer port*/
	he = hostutil_GetHostByName((char *) SvPV(*av_fetch(host_array, currFS, 0), PL_na));
	if (he == (struct hostent *) NULL) {
	    sprintf(buffer,
		    "Can't get host info for '%s'",
		    (char *) SvPV(*av_fetch(host_array, currFS, 0), PL_na));
	    BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
	}
	memcpy(&(FSSktArray[currFS].sin_addr.s_addr), he->h_addr, 4);

    } /*Get socket info for each File Server*/

    collIDP = (afs_int32 *) malloc(numCollIDs * sizeof(afs_int32));
    currCollIDP = collIDP;
    for (currCollIDIdx = 0; currCollIDIdx < numCollIDs; currCollIDIdx++) {
	*currCollIDP = (afs_int32) SvIV(*av_fetch(coll_array, currCollIDIdx, 0));
	currCollIDP++;
    }

    code = my_xstat_fs_Init(my_xstat_FS_Handler, numFSs, FSSktArray,
                            numCollIDs, collIDP, buffer, RETVAL);
    if(code) {
       BSETCODE(code, buffer);
       XSRETURN_UNDEF;
    }

    ST(0) = sv_2mortal(newRV_inc((SV*)RETVAL));
    SETCODE(0);
    XSRETURN(1);

  }


void
afs_do_scout(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {
    static char rn[] = "afs_do_scout";
    SV *value;
    I32 keylen = 0;
    char *key;
    int num_args = 0;
    char buffer[256] = "";
    struct fsprobe_ProbeResults fsprobe_Results;
    struct fsprobe_ConnectionInfo *fsprobe_ConnInfo; /*Ptr to connection array*/
    char buff2[256] = "";

    char basename[64] = "";
    int numservers = 0;
    char fullsrvname[128] = "";
    struct sockaddr_in *FSSktArray;
    struct sockaddr_in *curr_skt;
    struct hostent *he;
    int i, code;
    int sktbytes;
    FILE *scout_debugfd = (FILE *) NULL;
    char *debug_filename = (char *) NULL;

    AV *host_array = (AV *) NULL;

    AV *RETVAL = newAV();

    /* parse arguments */
    num_args = hv_iterinit(args);
    while (num_args--) {

      value = hv_iternextsv(args, &key, &keylen);

      switch (*key) {

        case 'b':
          if(strncmp(key, "basename", keylen) == 0 && keylen <= 8) {
            sprintf(basename, "%s", SvPV(value, PL_na));
          } else goto unrecognized;
        break;

        case 'd':
          if(strncmp(key, "debug", keylen) == 0 && keylen <= 5) {
            debug_filename = (char *) SvPV(value, PL_na);
          } else goto unrecognized;
        break;

        case 's':
          if(strncmp(key, "servers", keylen) == 0 && keylen <= 7) {
            if (SvROK(value))
              host_array = (AV*) SvRV(value);
            else {
              host_array = av_make(1, &value);
              sv_2mortal((SV *) host_array);
            }
            numservers = av_len(host_array) + 1;
          } else goto unrecognized;
        break;

        default:
          unrecognized:
          sprintf(buffer, "Unrecognized flag: %s", key);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
        break;
      } /* end switch */
    } /* end while */
    /* done parsing arguments */

    if(numservers == 0) {
      sprintf(buffer, "Missing required parameter 'server'");
      BSETCODE(-1, buffer);
      XSRETURN_UNDEF;
    }

    if(debug_filename) {
      scout_debugfd = fopen(debug_filename, "w");
      if(scout_debugfd == (FILE *) NULL) {
        sprintf(buffer, "Can't open debugging file '%s'!", debug_filename);
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
      fprintf(scout_debugfd, "[%s] Writing to Scout debugging file '%s'\n",
              rn, debug_filename);
      fflush(scout_debugfd);
    }

    /* execute_scout */

    sktbytes = numservers * sizeof(struct sockaddr_in);
    FSSktArray = (struct sockaddr_in *) malloc(sktbytes);
    if (FSSktArray == (struct sockaddr_in *) NULL) {
      sprintf(buffer,
              "Can't malloc() %d sockaddrs (%d bytes) for the given servers",
              numservers, sktbytes);
      BSETCODE(-1, buffer);
      if (scout_debugfd != (FILE *) NULL) {
        fprintf(scout_debugfd, "[%s] Closing debugging file\n", rn);
        fclose(scout_debugfd);
      }
      XSRETURN_UNDEF;
    }
    memset(FSSktArray, 0, sktbytes);

    curr_skt = FSSktArray;
    for(i=0; i<numservers; i++) {
       if(*basename == '\0')
         sprintf(fullsrvname, "%s", (char *) SvPV(*av_fetch(host_array, i, 0), PL_na));
       else
         sprintf(fullsrvname, "%s.%s", (char *) SvPV(*av_fetch(host_array, i, 0), PL_na), basename);
       he = hostutil_GetHostByName(fullsrvname);
       if(he == (struct hostent *) NULL) {
         sprintf(buffer, "Can't get host info for '%s'", fullsrvname);
         BSETCODE(-1, buffer);
         if (scout_debugfd != (FILE *) NULL) {
           fprintf(scout_debugfd, "[%s] Closing debugging file\n", rn);
           fclose(scout_debugfd);
         }
         XSRETURN_UNDEF;
       }
       memcpy(&(curr_skt->sin_addr.s_addr), he->h_addr, 4);
#if defined(AFS_DARWIN_ENV) || defined(AFS_FBSD_ENV)
        curr_skt->sin_family = AF_INET;         /*Internet family */
#else
        curr_skt->sin_family = htons(AF_INET);  /*Internet family */
#endif
       curr_skt->sin_port   = htons(7000);       /* FileServer port */
       curr_skt++;
    }
    code = my_fsprobe_Init(&fsprobe_Results, &fsprobe_ConnInfo, numservers,
                           FSSktArray, RETVAL, scout_debugfd, buffer);
    if(code) {
      if(buffer == "") {
        sprintf(buffer, "Error returned by fsprobe_Init: %d", code);
      }
      BSETCODE(code, buffer);
      if (scout_debugfd != (FILE *) NULL) {
        fprintf(scout_debugfd, "[%s] Closing debugging file\n", rn);
        fclose(scout_debugfd);
      }
      XSRETURN_UNDEF;
    }
    code = my_FS_Handler(fsprobe_Results, numservers, fsprobe_ConnInfo,
                         scout_debugfd, RETVAL, buff2);
    if (code) {
      sprintf(buffer, "[%s] Handler routine returned error code %d. %s", rn, code, buff2);
      BSETCODE(code, buffer);
      if (scout_debugfd != (FILE *) NULL) {
        fprintf(scout_debugfd, "[%s] Closing debugging file\n", rn);
        fclose(scout_debugfd);
      }
      XSRETURN_UNDEF;
    }

    if (scout_debugfd != (FILE *) NULL) {
       fprintf(scout_debugfd, "[%s] Closing debugging file\n", rn);
       fclose(scout_debugfd);
    }

    ST(0) = sv_2mortal(newRV_inc((SV*)RETVAL));
    SETCODE(0);
    XSRETURN(1);
  }

void
afs_do_udebug(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {

    SV *value;
    I32 keylen = 0;
    char *key;
    int num_args = 0;
    char buffer[256] = "";

    char *hostName = (char *) NULL;
    char *portName = (char *) NULL;
    afs_int32 hostAddr;
    struct in_addr inhostAddr;
    register afs_int32 i, j, code;
    short port;
    int int32p = 0;
    struct hostent *th;
    struct rx_connection *tconn;
    struct rx_securityClass *sc;
    struct ubik_debug udebug;
    struct ubik_sdebug usdebug;
    int oldServer = 0;   /* are we talking to a pre 3.5 server? */
    afs_int32 isClone = 0;

    HV *RETVAL = newHV();
    AV *ADDRESSES;
    HV *LOCALVERSION;
    HV *SYNCVERSION;
    HV *SYNCTID;
    AV *SERVERS;
    HV *USDEBUG;
    AV *ALTADDR;
    HV *REMOTEVERSION;

    /* parse arguments */
    num_args = hv_iterinit(args);
    while (num_args--) {

      value = hv_iternextsv(args, &key, &keylen);

      switch (*key) {

        case 'l':
          if(strncmp(key, "long", keylen) == 0 && keylen <= 4) {
            int32p = (int) SvIV(value);
          } else goto unrecognized;
        break;

        case 'p':
          if(strncmp(key, "port", keylen) == 0 && keylen <= 4) {
            portName = (char *) SvPV(value, PL_na);
          } else goto unrecognized;
        break;

        case 's':
          if(strncmp(key, "server", keylen) == 0 && keylen <= 6) {
            hostName = (char *) SvPV(value, PL_na);
          } else goto unrecognized;
        break;

        default:
          unrecognized:
          sprintf(buffer, "Unrecognized flag: %s", key);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
        break;
      } /* end switch */
    } /* end while */
    /* done parsing arguments */


    /* lookup host */
    if (hostName) {
       th = hostutil_GetHostByName(hostName);
       if (!th) {
          sprintf(buffer, "udebug: host %s not found in host table", hostName);
          BSETCODE(1, buffer);
          XSRETURN_UNDEF;
       }
       memcpy(&hostAddr, th->h_addr, sizeof(afs_int32));
    }
    else hostAddr = htonl(0x7f000001);  /* IP localhost */


    if (!portName)
       port = htons(3000);             /* default */
    else {
       port = udebug_PortNumber(portName);
       if (port < 0)
          port = udebug_PortName(portName);
       if (port < 0) {
          sprintf(buffer, "udebug: can't resolve port name %s", portName);
          BSETCODE(1, buffer);
          XSRETURN_UNDEF;
       }
       port = htons(port);
    }

    rx_Init(0);
    sc = rxnull_NewClientSecurityObject();
    tconn = rx_NewConnection(hostAddr, port, VOTE_SERVICE_ID, sc, 0);

    /* now do the main call */
#ifdef USE_VOTEXDEBUG
    code = VOTE_XDebug(tconn, &udebug, &isClone);
    if (code) code = VOTE_Debug(tconn, &udebug);
#else
    code = VOTE_Debug(tconn, &udebug);
#endif
    if (code == RXGEN_OPCODE)
    {  ubik_debug * ptr = &udebug;
       oldServer = 1;             /* talking to a pre 3.5 server */
       memset(&udebug, 0, sizeof(udebug));
       code = VOTE_DebugOld(tconn, (struct ubik_debug_old *) ptr);
    }

    if (code) {
       sprintf(buffer, "return code %d from VOTE_Debug", code);
       BSETCODE(code, buffer);
       XSRETURN_UNDEF;
    }

    /* now print the main info */
    inhostAddr.s_addr = hostAddr;
    if ( !oldServer )
    {
       ADDRESSES = newAV();
       for ( j=0; udebug.interfaceAddr[j] && ( j<UBIK_MAX_INTERFACE_ADDR ); j++) {
          av_store(ADDRESSES, j, newSVpv(afs_inet_ntoa(htonl(udebug.interfaceAddr[j])), 0));
       }
       hv_store(RETVAL, "interfaceAddr", 13, newRV_inc((SV*)ADDRESSES), 0);
    }

    hv_store(RETVAL, "host", 4, newSVpv(inet_ntoa(inhostAddr), 0), 0);
    hv_store(RETVAL, "now", 3, newSViv(udebug.now), 0);

    /* UBIK skips the voting if 1 server - so we fudge it here */
    if ( udebug.amSyncSite && (udebug.nServers == 1) ) {
       udebug.lastYesHost  = hostAddr;
       udebug.lastYesTime  = udebug.now;
       udebug.lastYesState = 1;
       udebug.lastYesClaim = udebug.now;
       udebug.syncVersion.epoch   = udebug.localVersion.epoch;
       udebug.syncVersion.counter = udebug.localVersion.counter;
    }

    /* sockaddr is always in net-order */
    if ( udebug.lastYesHost != 0xffffffff ) {
       inhostAddr.s_addr = htonl(udebug.lastYesHost);
       hv_store(RETVAL, "lastYesHost", 11, newSVpv(inet_ntoa(inhostAddr), 0), 0);
       hv_store(RETVAL, "lastYesTime", 11, newSViv(udebug.lastYesTime), 0);
       hv_store(RETVAL, "lastYesState", 12, newSViv(udebug.lastYesState), 0);
       hv_store(RETVAL, "lastYesClaim", 12, newSViv(udebug.lastYesClaim), 0);
    }

    LOCALVERSION = newHV();
    hv_store(LOCALVERSION, "epoch", 5, newSViv(udebug.localVersion.epoch), 0);
    hv_store(LOCALVERSION, "counter", 7, newSViv(udebug.localVersion.counter), 0);
    hv_store(RETVAL, "localVersion", 12, newRV_inc((SV*)LOCALVERSION), 0);

    hv_store(RETVAL, "amSyncSite", 10, newSViv(udebug.amSyncSite), 0);

    hv_store(RETVAL, "epochTime", 9, newSViv(udebug.epochTime), 0);

    if (udebug.amSyncSite) {
       hv_store(RETVAL, "syncSiteUntil", 13, newSViv(udebug.syncSiteUntil), 0);
       hv_store(RETVAL, "nServers", 8, newSViv(udebug.nServers), 0);
       hv_store(RETVAL, "recoveryState", 13, newSViv(udebug.recoveryState), 0);
       if (udebug.activeWrite) {
          hv_store(RETVAL, "tidCounter", 10, newSViv(udebug.tidCounter), 0);
       }
    }
    else {
       hv_store(RETVAL, "isClone", 7, newSViv(isClone), 0);

       inhostAddr.s_addr = htonl(udebug.lowestHost);
       hv_store(RETVAL, "lowestHost", 10, newSVpv(inet_ntoa(inhostAddr), 0), 0);
       hv_store(RETVAL, "lowestTime", 10, newSViv(udebug.lowestTime), 0);

       inhostAddr.s_addr = htonl(udebug.syncHost);
       hv_store(RETVAL, "syncHost", 8, newSVpv(inet_ntoa(inhostAddr), 0), 0);
       hv_store(RETVAL, "syncTime", 8, newSViv(udebug.syncTime), 0);
    }

    SYNCVERSION = newHV();
    hv_store(SYNCVERSION, "epoch", 5, newSViv(udebug.syncVersion.epoch), 0);
    hv_store(SYNCVERSION, "counter", 7, newSViv(udebug.syncVersion.counter), 0);
    hv_store(RETVAL, "syncVersion", 11, newRV_inc((SV*)SYNCVERSION), 0);

    hv_store(RETVAL, "lockedPages", 11, newSViv(udebug.lockedPages), 0);
    hv_store(RETVAL, "writeLockedPages", 16, newSViv(udebug.writeLockedPages), 0);

    hv_store(RETVAL, "anyReadLocks", 12, newSViv(udebug.anyReadLocks), 0);
    hv_store(RETVAL, "anyWriteLocks", 13, newSViv(udebug.anyWriteLocks), 0);

    hv_store(RETVAL, "currentTrans", 12, newSViv(udebug.currentTrans), 0);
    if (udebug.currentTrans) {
       hv_store(RETVAL, "writeTrans", 10, newSViv(udebug.writeTrans), 0);
       SYNCTID = newHV();
       hv_store(SYNCTID, "epoch", 5, newSViv(udebug.syncTid.epoch), 0);
       hv_store(SYNCTID, "counter", 7, newSViv(udebug.syncTid.counter), 0);
       hv_store(RETVAL, "syncTid", 7, newRV_inc((SV*)SYNCTID), 0);
    }

    if (int32p || udebug.amSyncSite) {
       /* now do the subcalls */
       SERVERS = newAV();

       for ( i=0; ; i++ ) {
#ifdef USE_VOTEXDEBUG
          isClone = 0;
          code = VOTE_XSDebug(tconn, i, &usdebug, &isClone);
          if (code < 0) {
             if ( oldServer ) {                      /* pre 3.5 server */
                ubik_sdebug * ptr = &usdebug;
                memset(&usdebug, 0, sizeof(usdebug));
                code = VOTE_SDebugOld(tconn, i, (struct ubik_sdebug_old *) ptr);
             }
             else
                code = VOTE_SDebug(tconn, i, &usdebug);
          }
#else
          if ( oldServer ) {                      /* pre 3.5 server */
             ubik_sdebug * ptr = &usdebug;
             memset(&usdebug, 0, sizeof(usdebug));
             code = VOTE_SDebugOld(tconn, i, (struct ubik_sdebug_old *) ptr);
          }
          else
             code = VOTE_SDebug(tconn, i, &usdebug);
#endif

          if (code > 0)
                break;          /* done */
          if (code < 0) {
             warn("error code %d from VOTE_SDebug\n", code);
             break;
          }

          /* otherwise print the structure */
          USDEBUG = newHV();
          inhostAddr.s_addr = htonl(usdebug.addr);

          hv_store(USDEBUG, "addr", 4, newSVpv(afs_inet_ntoa(htonl(usdebug.addr)), 0), 0);

          ALTADDR = newAV();
          for ( j=0;((usdebug.altAddr[j]) && (j<UBIK_MAX_INTERFACE_ADDR-1)); j++) {
             av_store(ALTADDR, j, newSVpv(afs_inet_ntoa(htonl(usdebug.altAddr[j])), 0));
          }
          if (j) hv_store(USDEBUG, "altAddr", 7, newRV_inc((SV*)ALTADDR), 0);

          REMOTEVERSION = newHV();
          hv_store(REMOTEVERSION, "epoch", 5, newSViv(usdebug.remoteVersion.epoch), 0);
          hv_store(REMOTEVERSION, "counter", 7, newSViv(usdebug.remoteVersion.counter), 0);
          hv_store(USDEBUG, "remoteVersion", 13, newRV_inc((SV*)REMOTEVERSION), 0);

          hv_store(USDEBUG, "isClone", 7, newSViv(isClone), 0);

          hv_store(USDEBUG, "lastVoteTime", 12, newSViv(usdebug.lastVoteTime), 0);

          hv_store(USDEBUG, "lastBeaconSent", 14, newSViv(usdebug.lastBeaconSent), 0);
          hv_store(USDEBUG, "lastVote", 8, newSViv(usdebug.lastVote), 0);

          hv_store(USDEBUG, "currentDB", 9, newSViv(usdebug.currentDB), 0);
          hv_store(USDEBUG, "up", 2, newSViv(usdebug.up), 0);
          hv_store(USDEBUG, "beaconSinceDown", 15, newSViv(usdebug.beaconSinceDown), 0);

          av_store(SERVERS, i, newRV_inc((SV*)USDEBUG));
       }
       hv_store(RETVAL, "servers", 7, newRV_inc((SV*)SERVERS), 0);
    }

    /* return RETVAL */
    ST(0) = sv_2mortal(newRV_inc((SV*)RETVAL));
    SETCODE(0);
    XSRETURN(1);

  }

void
afs_do_cmdebug(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {
    SV *value;
    I32 keylen = 0;
    char *key;
    int num_args = 0;
    int code = 0;
    int aint32 = 0;
    struct rx_connection *conn;
    register char *hostName = "";
    register struct hostent *thp;
    struct rx_securityClass *secobj;
    afs_int32 addr = 0;
    afs_int32 port = 7001;
    char buffer[256] = "";

    AV *LOCKS = newAV();           /* return */
    AV *CACHE_ENTRIES = newAV();   /* values */

    /* parse arguments */
    num_args = hv_iterinit(args);
    while (num_args--) {
      value = hv_iternextsv(args, &key, &keylen);

      switch (*key) {

        case 'l':
          if(strncmp(key, "long", keylen) == 0 && keylen <= 4) {
            aint32 = (int) SvIV(value);
          } else goto unrecognized;
        break;

        case 'p':
          if(strncmp(key, "port", keylen) == 0 && keylen <= 4) {
            port = (int) SvIV(value);
          } else goto unrecognized;
        break;

        case 's':
          if(strncmp(key, "servers", keylen) == 0 && keylen <= 7) {
            hostName = (char *) SvPV(value, PL_na);
          } else goto unrecognized;
        break;

        default:
          unrecognized:
          sprintf(buffer, "Unrecognized flag: %s", key);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
        break;
      } /* end switch */
    } /* end while */
    /* done parsing arguments */

    rx_Init(0);

    thp = hostutil_GetHostByName(hostName);
    if (!thp) {
        sprintf(buffer, "can't resolve address for host %s", hostName);
        BSETCODE(1, buffer);
        XSRETURN_UNDEF;
    }
    memcpy(&addr, thp->h_addr, sizeof(afs_int32));
    secobj = rxnull_NewServerSecurityObject();
    conn = rx_NewConnection(addr, htons(port), 1, secobj, 0);
    if (!conn) {
        sprintf(buffer, "failed to create connection for host %s", hostName);
        BSETCODE(1, buffer);
        XSRETURN_UNDEF;
    }
    code = my_PrintLocks(conn, aint32, LOCKS, buffer);
    if(code) {
       BSETCODE(code, buffer);
       XSRETURN_UNDEF;
    }
    code = my_PrintCacheEntries(conn, aint32, CACHE_ENTRIES, buffer);
    if(code) {
       BSETCODE(code, buffer);
       XSRETURN_UNDEF;
    }

    SETCODE(0);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newRV_inc((SV*)LOCKS)));
    PUSHs(sv_2mortal(newRV_inc((SV*)CACHE_ENTRIES)));

  }

void
afs_do_afsmonitor(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {
    I32 keylen = 0;
    char* key = 0;
    SV* value = 0;
    char* host = 0;
    AV* host_array = 0;
    AV* show_array = 0;
    AV* fsthresh_array = 0;
    AV* cmthresh_array = 0;
    HV* thresh_entry = 0;
    int global_fsThreshCount = 0;
    int global_cmThreshCount = 0;
    int found = 0;
    int numBytes = 0;
    char* thresh_name = "";
    char* thresh_value = 0;
    char* thresh_host = "";
    char* thresh_handler = "";
    int num_args = 0;
    int detailed = 0;
    char* config_filename = 0;
    char* output_filename = 0;
    FILE *outputFD = 0;
    struct afsmon_hostEntry *temp_host = 0;
    int numFS = 0;
    int numCM = 0;
    struct afsmon_hostEntry *last_hostEntry = 0;
    int lastHostType = 0;
    short fs_showFlags[NUM_FS_STAT_ENTRIES];
    short cm_showFlags[NUM_CM_STAT_ENTRIES];
    int fs_showDefault = 1;
    int cm_showDefault = 1;

    int num = 0;
    int i = 0;
    int j = 0;
    int code = 0;
    char buffer[256] = "";
    char buff2[256] = "";

    /* from afsmon_execute() */
    static char fullhostname[128] = "";   /* full host name */
    struct sockaddr_in *FSSktArray = 0;   /* fs socket array */
    int FSsktbytes = 0;         /* num bytes in above */
    struct sockaddr_in *CMSktArray = 0;   /* cm socket array */
    int CMsktbytes = 0;         /* num bytes in above */
    struct sockaddr_in *curr_skt = 0;     /* ptr to current socket*/
    struct afsmon_hostEntry *curr_FS = 0; /* ptr to FS name list */
    struct afsmon_hostEntry *curr_CM = 0; /* ptr to CM name list */
    struct hostent *he = 0;     /* host entry */
    afs_int32 *collIDP = 0;     /* ptr to collection ID */
    int numCollIDs = 0;         /* number of collection IDs */
    /* end of from afsmon_execute() */

    AV* FILESERV = newAV(); /* File Servers */
    AV* CACHEMAN = newAV(); /* Cache Managers */

    struct afsmon_hostEntry *FSnameList=0;
    struct afsmon_hostEntry *CMnameList=0;

    /* initialize showFlags for processing "show" directives in config file */
    for(i=0; i<NUM_FS_STAT_ENTRIES; i++)
      fs_showFlags[i] = 0;
    for(i=0; i<NUM_CM_STAT_ENTRIES; i++)
      cm_showFlags[i] = 0;

    /* parse arguments */
    num_args = hv_iterinit(args);
    /* fprintf(STDERR, "[afsmonitor] Parsing args now: %d\n", num_args); */
    while (num_args--) {
      value = hv_iternextsv(args, &key, &keylen);

      /* fprintf(STDERR, "got flag %s, size %d. %d remaining.\n", key, keylen, num_args); */

      switch (*key) {
        case 'c':
          if(keylen < 2) goto unrecognized;
          switch(key[1]) {
            case 'o':
              if(strncmp(key, "config", keylen) == 0 && keylen <= 6) {
                /* fprintf(STDERR, "flag %s recognized as config; value is %s\n",
                   key, (char *) SvPV(value, PL_na)); */
                config_filename = (char *) SvPV(value, PL_na);
              } else goto unrecognized;
            break;

            case 'm':
              if(keylen < 3) goto unrecognized;
              switch(key[2]) {
                case 'h':
                 if(strncmp(key, "cmhosts", keylen) == 0 && keylen <= 7) {
                   /* fprintf(STDERR, "flag %s recognized as cmhosts\n", key); */
                  if (SvROK(value))
                    host_array = (AV*) SvRV(value);
                  else {
                    host_array = av_make(1, &value);
                    sv_2mortal((SV *) host_array);
                  }
                   num = av_len(host_array);
                   /* fprintf(STDERR, "it has %d elements.\n", num+1); */
                   for(i=0; i<=num; i++) {
                     host = (char *) SvPV(*av_fetch(host_array, i, 0), PL_na);
                     sprintf(buffer,"cm %s",host);
                     code = my_parse_hostEntry(buffer, &numFS, &numCM, &lastHostType,
                                            &last_hostEntry, &FSnameList, &CMnameList, buff2);
                     /* fprintf(STDERR, "got host: %s\n", host); */
                     if (code) {
                       sprintf(buffer, "Could not parse cache manager %s. %s", host, buff2);
                       BSETCODE(180, buffer);
                       /* 180 is the exit code for this error in the original afsmonitor.c */
                       XSRETURN_UNDEF;
                     }
                   }
                 } else goto unrecognized;
                 break;
                case 's':
                 if(strncmp(key, "cmshow", keylen) == 0 && keylen <= 6) {
                   /* fprintf(STDERR, "flag %s recognized as cmshow\n", key); */
                   show_array = (AV*) SvRV(value);
                   num = av_len(show_array);
                   for (i=0; i<=num; i++) {
                     sprintf(buffer, "show cm %s", SvPV(*av_fetch(show_array, i, 0), PL_na));
                     code = my_parse_showEntry(buffer, &fs_showDefault, &cm_showDefault,
                                               fs_showFlags, cm_showFlags, buff2);
                     if(code) {
                       sprintf(buffer, "Error parsing cmshow flag. %s", buff2);
                       BSETCODE(-1, buffer);
                       XSRETURN_UNDEF;
                     }
                   }
                 } else goto unrecognized;
                 break;
                case 't':
                 if(strncmp(key, "cmthresh", keylen) == 0 && keylen <= 8) {
                   /* fprintf(STDERR, "flag %s recognized as cmthresh\n", key); */
                   cmthresh_array = (AV*) SvRV(value);
                 } else goto unrecognized;
                 break;
                default:
                 goto unrecognized;
              }
            break;

            default:
              goto unrecognized;
          }
          break;

        case 'd':
          if(strncmp(key, "detailed", keylen) == 0 && keylen <= 8) {
            /* fprintf(STDERR, "flag %s recognized as detailed; value is %d\n",
                       key, (int) SvIV(value)); */
            detailed = (int) SvIV(value);
          } else goto unrecognized;
        break;

        case 'f':
          if(keylen < 3 || key[1] != 's') goto unrecognized;
          switch(key[2]) {
            case 'h':
              if(strncmp(key, "fshosts", keylen) == 0 && keylen <= 7) {
                /* fprintf(STDERR, "flag %s recognized as fshosts\n", key); */
                if (SvROK(value))
                  host_array = (AV*) SvRV(value);
                else {
                  host_array = av_make(1, &value);
                  sv_2mortal((SV *) host_array);
                }
                num = av_len(host_array);
                /* fprintf(STDERR, "it has %d elements.\n", num+1); */
                for(i=0; i<=num; i++) {
                  host = (char *) SvPV(*av_fetch(host_array, i, 0), PL_na);
                  sprintf(buffer,"fs %s",host);
                  code = my_parse_hostEntry(buffer, &numFS, &numCM, &lastHostType,
                                         &last_hostEntry, &FSnameList, &CMnameList, buff2);
                  /* fprintf(STDERR, "got host: %s\n", host); */
                  if (code) {
                    sprintf(buffer, "Could not parse file server %s. %s", host, buff2);
                    BSETCODE(180, buffer);
                    XSRETURN_UNDEF;
                  }
                }
              } else goto unrecognized;
              break;
            case 's':
              if(strncmp(key, "fsshow", keylen) == 0 && keylen <= 6) {
                /* fprintf(STDERR, "flag %s recognized as fsshow\n", key); */
                show_array = (AV*) SvRV(value);
                num = av_len(show_array);
                for (i=0; i<=num; i++) {
                  sprintf(buffer, "show fs %s", SvPV(*av_fetch(show_array, i, 0), PL_na));
                  code = my_parse_showEntry(buffer, &fs_showDefault, &cm_showDefault,
                                            fs_showFlags, cm_showFlags, buff2);
                  if(code) {
                    sprintf(buffer, "Error parsing fsshow flag. %s", buff2);
                    BSETCODE(-1, buffer);
                    XSRETURN_UNDEF;
                  }
                }
              } else goto unrecognized;
              break;
            case 't':
              if(strncmp(key, "fsthresh", keylen) == 0 && keylen <= 8) {
                /* fprintf(STDERR, "flag %s recognized as fsthresh\n", key); */
                fsthresh_array = (AV*) SvRV(value);
              } else goto unrecognized;
              break;
            default:
              goto unrecognized;
          }
        break;

        case 'o':
          if(strncmp(key, "output", keylen) == 0 && keylen <= 6) {
            /* fprintf(STDERR, "flag %s recognized as output; value is %s\n",
                       key, (char *) SvPV(value, PL_na)); */
            output_filename = (char *) SvPV(value, PL_na);
          } else goto unrecognized;
        break;

        default:
          unrecognized:
          /* fprintf(STDERR,
                     "flag not recognized. (key: %s) (value: %s)\n",
                     key, (char *) SvPV(value, PL_na)); */
          sprintf(buffer, "Unrecognized flag: %s", key);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
      } /* end switch */
    } /* end while */
    /* done parsing arguments */

    /* Open output file, if provided. */
    if (output_filename) {
      outputFD = fopen(output_filename,"a");
      if (outputFD == (FILE *) NULL) {
        sprintf(buffer, "Failed to open output file %s", output_filename);
        BSETCODE(160, buffer);
        XSRETURN_UNDEF;
      }
      fclose (outputFD);
    }

    /* cannot use 'detailed' without 'output' */
    if (detailed) {
      if (!output_filename) {
        sprintf(buffer, "detailed switch can be used only with output switch");
        BSETCODE(165, buffer);
        /* 165 is the exit code for this error in the original afsmonitor.c */
        XSRETURN_UNDEF;
      }
    }

    /* The config option is mutually exclusive with the fshosts,cmhosts options */
    if (config_filename) {
      if (numFS || numCM) {
        sprintf(buffer,"Cannot use config option with fshosts or cmhosts");
        BSETCODE(170, buffer);
        /* 170 is the exit code for this error in the original afsmonitor.c */
        XSRETURN_UNDEF;
      }
    }
    else {
      if (!numFS && !numCM) {
        sprintf(buffer,"Must specify either config or (fshosts and/or cmhosts) options");
        BSETCODE(175, buffer);
        /* 175 is the exit code for this error in the original afsmonitor.c */
        XSRETURN_UNDEF;
      }
    }

    if (fsthresh_array) {
      if(!numFS) {
        sprintf(buffer, "Cannot use fsthresh option without specifying fshosts");
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
      num = av_len(fsthresh_array);
      for (i=0; i<=num; i++) {
        thresh_host = 0;
        thresh_handler = "";
        thresh_entry = (HV*) SvRV(*av_fetch(fsthresh_array, i, 0));
        hv_iterinit(thresh_entry);
        while((value = hv_iternextsv(thresh_entry, &key, &keylen))) {
          if(strcmp(key, "host")==0) {
            thresh_host = (char *)SvPV(value, PL_na);
            he = GetHostByName(thresh_host);
            if(he == (struct hostent *) NULL) {
              sprintf(buffer,
                      "Couldn't parse fsthresh flag; unable to resolve hostname %s\n",
                      thresh_host);
              BSETCODE(-1, buffer);
              XSRETURN_UNDEF;
            }
            thresh_host = he->h_name;
          }
          else if(strcmp(key, "handler")==0) {
            thresh_handler = (char *) SvPV(value, PL_na);
          }
          else {
            thresh_name = key;
            thresh_value = (char *) SvPV(value, PL_na);
          }
        }
        sprintf(buffer, "thresh fs %s %s %s",
                thresh_name, thresh_value, thresh_handler);
        if(!thresh_host) {
          code = my_parse_threshEntry(buffer, &global_fsThreshCount,
                      &global_cmThreshCount, (struct afsmon_hostEntry *) NULL, 0, buff2);
          if (code) {
            sprintf(buffer, "Couldn't parse fsthresh entry. %s", buff2);
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
          }
        }
        else {
          temp_host = FSnameList;
          found = 0;
          for (j = 0; j < numFS; j++) {
            if(strcmp(thresh_host, temp_host->hostName) == 0) {
              found = 1;
              break;
            }
            temp_host = temp_host->next;
          }
          if(found) {
            code = my_parse_threshEntry(buffer, &global_fsThreshCount,
                                        &global_cmThreshCount, temp_host,
                                        1, buff2);
            if(code) {
              sprintf(buffer, "Couldn't parse fsthresh entry. %s", buff2);
              BSETCODE(code, buffer);
              XSRETURN_UNDEF;
            }
          }
          else {
            sprintf(buffer,
                    "Couldn't parse fsthresh entry for host %s; host not found",
                    thresh_host);
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
          }
        }
      }
      if (global_fsThreshCount) {
        temp_host = FSnameList;
        for (i = 0; i < numFS; i++) {
          temp_host->numThresh += global_fsThreshCount;
          temp_host = temp_host->next;
        }
      }
      temp_host = FSnameList;
      for (i = 0; i < numFS; i++) {
        if (temp_host->numThresh) {
          numBytes = temp_host->numThresh * sizeof(struct Threshold);
          temp_host->thresh = (struct Threshold *)malloc(numBytes);
          if (temp_host->thresh == (struct Threshold *) NULL) {
            sprintf(buffer, "Memory Allocation error 1.5");
            BSETCODE(25, buffer);
            XSRETURN_UNDEF;
          }
          memset(temp_host->thresh, 0, numBytes);
        }
        temp_host = temp_host->next;
      }
      num = av_len(fsthresh_array);
      for (i=0; i<=num; i++) {
        thresh_host = 0;
        thresh_handler = "";
        thresh_entry = (HV*) SvRV(*av_fetch(fsthresh_array, i, 0));
        hv_iterinit(thresh_entry);
        while((value = hv_iternextsv(thresh_entry, &key, &keylen))) {
          if(strcmp(key, "host") == 0) {
            thresh_host = (char *)SvPV(value, PL_na);
            he = GetHostByName(thresh_host);
            if(he == (struct hostent *) NULL) {
              sprintf(buffer,
                      "Couldn't parse fsthresh flag; unable to resolve hostname %s\n",
                      thresh_host);
              BSETCODE(-1, buffer);
              XSRETURN_UNDEF;
            }
            thresh_host = he->h_name;
          }
          else if(strcmp(key, "handler")==0) {
            thresh_handler = (char *) SvPV(value, PL_na);
          }
          else {
            thresh_name = key;
            thresh_value = (char *) SvPV(value, PL_na);
          }
        }
        if(thresh_host) global_fsThreshCount = 0;
        else global_fsThreshCount = 1;
        code = my_store_threshold(1, thresh_name, thresh_value, thresh_handler,
                           &global_fsThreshCount, FSnameList, thresh_host,
                           numFS, buff2);
        if(code) {
          sprintf(buffer, "Unable to store threshold %s. %s", thresh_name, buff2);
          BSETCODE(code, buffer);
          XSRETURN_UNDEF;
        }
      }
    }

    if (cmthresh_array) {
      if(!numCM) {
        sprintf(buffer, "Cannot use cmthresh option without specifying cmhosts");
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
      num = av_len(cmthresh_array);
      for (i=0; i<=num; i++) {
        thresh_host = 0;
        thresh_handler = "";
        thresh_entry = (HV*) SvRV(*av_fetch(cmthresh_array, i, 0));
        hv_iterinit(thresh_entry);
        while((value = hv_iternextsv(thresh_entry, &key, &keylen))) {
          if(strcmp(key, "host")==0) {
            thresh_host = (char *)SvPV(value, PL_na);
            he = GetHostByName(thresh_host);
            if(he == (struct hostent *) NULL) {
              sprintf(buffer,
                      "Couldn't parse cmthresh flag; unable to resolve hostname %s\n",
                      thresh_host);
              BSETCODE(-1, buffer);
              XSRETURN_UNDEF;
            }
            thresh_host = he->h_name;
          }
          else if(strcmp(key, "handler")==0) {
            thresh_handler = (char *) SvPV(value, PL_na);
          }
          else {
            thresh_name = key;
            thresh_value = (char *) SvPV(value, PL_na);
          }
        }
        sprintf(buffer, "thresh cm %s %s %s", thresh_name, thresh_value, thresh_handler);
        if(!thresh_host) {
          code = my_parse_threshEntry(buffer, &global_fsThreshCount,
                      &global_cmThreshCount, (struct afsmon_hostEntry *) NULL, 0, buff2);
          if (code) {
            sprintf(buffer, "Couldn't parse cmthresh entry. %s", buff2);
            BSETCODE(code, buffer);
            XSRETURN_UNDEF;
          }
        }
        else {
          temp_host = CMnameList;
          found = 0;
          for (j = 0; j < numCM; j++) {
            if(strcmp(thresh_host, temp_host->hostName) == 0) {
              found = 1;
              break;
            }
            temp_host = temp_host->next;
          }
          if(found) {
            code = my_parse_threshEntry(buffer, &global_fsThreshCount,
                                        &global_cmThreshCount, temp_host,
                                        2, buff2);
            if(code) {
              sprintf(buffer, "Couldn't parse cmthresh entry. %s", buff2);
              BSETCODE(code, buffer);
              XSRETURN_UNDEF;
            }
          }
          else {
            sprintf(buffer,
                    "Couldn't parse cmthresh entry for host %s; host not found",
                    thresh_host);
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
          }
        }
      }
      if (global_cmThreshCount) {
        temp_host = CMnameList;
        for (i = 0; i < numCM; i++) {
          temp_host->numThresh += global_cmThreshCount;
          temp_host = temp_host->next;
        }
      }
      temp_host = CMnameList;
      for (i = 0; i < numCM; i++) {
        if (temp_host->numThresh) {
          numBytes = temp_host->numThresh * sizeof(struct Threshold);
          temp_host->thresh = (struct Threshold *)malloc(numBytes);
          if (temp_host->thresh == (struct Threshold *) NULL) {
            sprintf(buffer, "Memory Allocation error 2.5");
            BSETCODE(25, buffer);
            XSRETURN_UNDEF;
          }
          memset(temp_host->thresh, 0, numBytes);
        }
        temp_host = temp_host->next;
      }
      num = av_len(cmthresh_array);
      for (i=0; i<=num; i++) {
        thresh_host = 0;
        thresh_handler = "";
        thresh_entry = (HV*) SvRV(*av_fetch(cmthresh_array, i, 0));
        hv_iterinit(thresh_entry);
        while((value = hv_iternextsv(thresh_entry, &key, &keylen))) {
          if(strcmp(key, "host") == 0) {
            thresh_host = (char *)SvPV(value, PL_na);
            he = GetHostByName(thresh_host);
            if(he == (struct hostent *) NULL) {
              sprintf(buffer,
                      "Couldn't parse cmthresh flag; unable to resolve hostname %s\n",
                      thresh_host);
              BSETCODE(-1, buffer);
              XSRETURN_UNDEF;
            }
            thresh_host = he->h_name;
          }
          else if(strcmp(key, "handler")==0) {
            thresh_handler = (char *) SvPV(value, PL_na);
          }
          else {
            thresh_name = key;
            thresh_value = (char *) SvPV(value, PL_na);
          }
        }
        if(thresh_host) global_cmThreshCount = 0;
        else global_cmThreshCount = 1;
        code = my_store_threshold(2, thresh_name, thresh_value, thresh_handler,
                           &global_cmThreshCount, CMnameList, thresh_host,
                           numCM, buff2);
        if(code) {
          sprintf(buffer, "Unable to store threshold %s. %s", thresh_name, buff2);
          BSETCODE(code, buffer);
          XSRETURN_UNDEF;
        }
      }
    }

    /* process configuration file */
    if(config_filename) {
      code = my_process_config_file(config_filename, &numFS, &numCM, &lastHostType,
                                 &last_hostEntry, &fs_showDefault, &cm_showDefault,
                                 fs_showFlags, cm_showFlags, &FSnameList, &CMnameList);
      if(code == -1)
        XSRETURN_UNDEF;
    }

  /* from afsmon_execute() */

    /* process file server entries */
    if (numFS) {
    /* Allocate an array of sockets for each fileserver we monitor */

      FSsktbytes = numFS * sizeof(struct sockaddr_in);
      FSSktArray = (struct sockaddr_in *) malloc(FSsktbytes);
      if (FSSktArray == (struct sockaddr_in *) NULL) {
        sprintf(buffer,"cannot malloc %d sockaddr_ins for fileservers", numFS);
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }

      memset(FSSktArray, 0, FSsktbytes);

      /* Fill in the socket information for each fileserve  */

      curr_skt = FSSktArray;
      curr_FS = FSnameList;  /* FS name list header */
      while (curr_FS) {
        strncpy(fullhostname,curr_FS->hostName,sizeof(fullhostname));
        he = GetHostByName(fullhostname);
        if (he == (struct hostent *) NULL) {
          sprintf(buffer,"Cannot get host info for %s", fullhostname);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
        }
        strncpy(curr_FS->hostName,he->h_name,HOST_NAME_LEN); /* complete name*/
        memcpy(&(curr_skt->sin_addr.s_addr), he->h_addr, 4);
#if defined(AFS_DARWIN_ENV) || defined(AFS_FBSD_ENV)
            curr_skt->sin_family = AF_INET;             /*Internet family */
#else
            curr_skt->sin_family = htons(AF_INET);      /*Internet family */
#endif
        curr_skt->sin_port   = htons(7000);       /*FileServer port*/
#ifdef STRUCT_SOCKADDR_HAS_SA_LEN
        curr_skt->sin_len = sizeof(struct sockaddr_in);
#endif
        /* get the next dude */
        curr_skt++;
        curr_FS = curr_FS->next;
      }

      /* initialize collection IDs. We need only one entry since we collect
         all the information from xstat */

      numCollIDs = 1;
      collIDP = (afs_int32 *) malloc (sizeof (afs_int32));
      if (collIDP == (afs_int32 *) NULL) {
        sprintf(buffer,"failed to allocate a measely afs_int32 word. Argh!");
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
      *collIDP = 2;     /* USE A macro for this */

      code = my_xstat_fs_Init(my_afsmon_FS_Handler, numFS, FSSktArray, numCollIDs,
                              collIDP, buff2, output_filename, detailed, FILESERV,
                              FSnameList, fs_showFlags, fs_showDefault);

      if (code) {
        sprintf(buffer,"my_xstat_fs_Init() returned error. %s", buff2);
        BSETCODE(125, buffer);
        XSRETURN_UNDEF;
      }
    }  /* end of process fileserver entries */

    /* process cache manager entries */
    if (numCM) {
    /* Allocate an array of sockets for each fileserver we monitor */

      CMsktbytes = numCM * sizeof(struct sockaddr_in);
      CMSktArray = (struct sockaddr_in *) malloc(CMsktbytes);
      if (CMSktArray == (struct sockaddr_in *) NULL) {
        sprintf(buffer,"cannot malloc %d sockaddr_ins for CM entries", numCM);
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }

      memset(CMSktArray, 0, CMsktbytes);

      /* Fill in the socket information for each CM  */

      curr_skt = CMSktArray;
      curr_CM = CMnameList;  /* CM name list header */
      while (curr_CM) {
        strncpy(fullhostname,curr_CM->hostName,sizeof(fullhostname));
        he = GetHostByName(fullhostname);
        if (he == (struct hostent *) NULL) {
          sprintf(buffer,"Cannot get host info for %s", fullhostname);
          BSETCODE(-1, buffer);
          XSRETURN_UNDEF;
        }
        strncpy(curr_CM->hostName,he->h_name,HOST_NAME_LEN); /* complete name*/
        memcpy(&(curr_skt->sin_addr.s_addr), he->h_addr, 4);
        curr_skt->sin_family = htons(AF_INET);    /*Internet family*/
        curr_skt->sin_port   = htons(7001);  /*Cache Manager port */
#ifdef STRUCT_SOCKADDR_HAS_SA_LEN
        curr_skt->sin_len = sizeof(struct sockaddr_in);
#endif

        /* get the next dude */
        curr_skt++;
        curr_CM = curr_CM->next;
      }

      /* initialize collection IDs. We need only one entry since we collect
         all the information from xstat */

      numCollIDs = 1;
      collIDP = (afs_int32 *) malloc (sizeof (afs_int32));
      if (collIDP == (afs_int32 *) NULL) {
        sprintf(buffer,"failed to allocate a measely afs_int32 word. Argh!");
        BSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
      *collIDP = 2;     /* USE A macro for this */

      code = my_xstat_cm_Init(my_afsmon_CM_Handler, numCM, CMSktArray, numCollIDs,
                              collIDP, buff2, output_filename, detailed, CACHEMAN,
                              CMnameList, cm_showFlags, cm_showDefault);

      if (code) {
        sprintf(buffer,"my_xstat_cm_Init() returned error. %s", buff2);
        BSETCODE(130, buffer);
        XSRETURN_UNDEF;
      }

    }  /* end of process fileserver entries */

  /* end from afsmon_execute() */

    SETCODE(0);

    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newRV_inc((SV*)FILESERV)));
    PUSHs(sv_2mortal(newRV_inc((SV*)CACHEMAN)));
  }


void
afs_do_rxdebug(args)
    HV* args = (HV*) SvRV($arg);
  PREINIT:
  PPCODE:
  {
    int size;
    I32 keylen;
    char *key;
    HE* entry;
    SV* value;
    HV* RETVAL = newHV(); /* return value */
    HV* TSTATS;
    HV* RXSTATS;
    AV* CONNECTIONS;
    HV* TCONN;
    AV* CALLSTATE;
    AV* CALLMODE;
    AV* CALLFLAGS;
    AV* CALLOTHER;
    AV* CALLNUMBER;
    AV* PEERS;
    HV* TPEER;
    HV* BYTESSENT;
    HV* BYTESRECEIVED;
    HV* TIMEOUT;
    int index;

    register int i;
    int s;
    int j;
    struct sockaddr_in taddr;
    afs_int32 host;
    struct in_addr hostAddr;
    short port;
    struct hostent *th;
    register afs_int32 code;
    int nodally=0;
    int allconns=0;
    int rxstats=0;
    int onlyClient=0;
    int onlyServer=0;
    afs_int32 onlyHost = -1;
    short onlyPort = -1;
    int onlyAuth = 999;
    int flag;
    int dallyCounter;
    int withSecStats;
    int withAllConn;
    int withRxStats;
    int withWaiters;
    int withIdleThreads;
    int withPeers;
    struct rx_debugStats tstats;
    char *portName = (char *) NULL;
    char *hostName = (char *) NULL;
    struct rx_debugConn tconn;
    short noConns=0;
    short showPeers=0;
    short showLong=0;
    int version_flag=0;
    afs_int32 length=64;
    char version[64];
    char buffer[240]; /* for error messages */

    afs_uint32 supportedDebugValues = 0;
    afs_uint32 supportedStatValues = 0;
    afs_uint32 supportedConnValues = 0;
    afs_uint32 supportedPeerValues = 0;
    afs_int32 nextconn = 0;
    afs_int32 nextpeer = 0;

  size = hv_iterinit(args);
  /* fprintf(STDERR, "Parsing args now: %d\n", size); */
  while (size--) {
    char *flag;
    entry = hv_iternext(args);
    key = hv_iterkey(entry, &keylen);
    value = hv_iterval(args, entry);
    flag = key;
    /* fprintf(STDERR, "size = %d, format: got flag %s\n", size, key); */

    switch (*flag) {
    case 'a':
        if (memcmp( flag, "allconnections", 14) == 0 ) {
            allconns = (int) SvIV(value);
        }
        break;

    case 'l':
        if (memcmp( flag, "long", 4) == 0 ) {
            showLong = (int) SvIV(value);
        }
        break;

    case 'n':
        if (memcmp( flag, "nodally", 7) == 0 ) {
            nodally = (int) SvIV(value);
        } else if (memcmp( flag, "noconns", 7) == 0 ) {
            noConns = (int) SvIV(value);
        }
        break;

    case 'o':
        if (memcmp( flag, "onlyserver", 10) == 0 ) {
            onlyServer = (int) SvIV(value);
        } else if (memcmp( flag, "onlyclient", 10) == 0 ) {
            onlyClient = (int) SvIV(value);
        } else if (memcmp( flag, "onlyhost", 8) == 0 ) {
            char *name = (char *) SvPV(value, PL_na);
        struct hostent *th;
        th = hostutil_GetHostByName(name);
        if (!th) {
            sprintf(buffer, "rxdebug: host %s not found in host table", name);
            BSETCODE(-1, buffer);
            XSRETURN_UNDEF;
        }
        memcpy(&onlyHost, th->h_addr, sizeof(afs_int32));

        } else if (memcmp( flag, "onlyauth", 8) == 0 ) {
            char *name = (char *) SvPV(value, PL_na);
            if (strcmp (name, "clear") == 0) onlyAuth = 0;
            else if (strcmp (name, "auth") == 0) onlyAuth = 1;
            else if (strcmp (name, "crypt") == 0) onlyAuth = 2;
            else if ((strcmp (name, "null") == 0) ||
                     (strcmp (name, "none") == 0) ||
                     (strncmp (name, "noauth", 6) == 0) ||
                     (strncmp (name, "unauth", 6) == 0)) onlyAuth = -1;
            else {
              sprintf (buffer, "Unknown authentication level: %s", name);
              BSETCODE(-1, buffer);
              XSRETURN_UNDEF;
            }

        } else if (memcmp( flag, "onlyport", 8) == 0 ) {
            char *name = (char *) SvPV(value, PL_na);
            if ((onlyPort = rxdebug_PortNumber(name)) == -1)
              onlyPort = rxdebug_PortName(name);
            if (onlyPort == -1) {
              sprintf(buffer, "rxdebug: can't resolve port name %s", name);
              VSETCODE(-1, buffer);
              XSRETURN_UNDEF;
            }
        }

        break;

    case 'p':
        if (memcmp( flag, "port", 4) == 0 ) {
            portName = (char *) SvPV(value, PL_na);
        } else if (memcmp( flag, "peers", 5) == 0 ) {
           showPeers  = (int) SvIV(value);
        }
        break;

    case 'r':
        if (memcmp( flag, "rxstats", 7) == 0 ) {
            rxstats = (int) SvIV(value);
        }
        break;

    case 's':
        if (memcmp( flag, "servers", 7) == 0 ) {
            hostName = (char *) SvPV(value, PL_na);
        }
        break;

    case 'v':
        if (memcmp( flag, "version", 7) == 0 ) {
            version_flag = (int) SvIV(value);
        }
        break;

    default:
        break;
    } /* switch */
  } /* while */
  /*  fprintf(STDERR, "Done parsing args\n\n"); */

    /* lookup host */
    if (hostName) {
      th = hostutil_GetHostByName(hostName);
      if (!th) {
        sprintf(buffer, "rxdebug: host %s not found in host table", hostName);
        VSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
      memcpy(&host, th->h_addr, sizeof(afs_int32));
    }
    else host = htonl(0x7f000001);    /* IP localhost */

    if (!portName)
      port = htons(7000);        /* default is fileserver */
    else {
      if ((port = rxdebug_PortNumber(portName)) == -1)
        port = rxdebug_PortName(portName);
      if (port == -1) {
        sprintf(buffer, "rxdebug: can't resolve port name %s", portName);
        VSETCODE(-1, buffer);
        XSRETURN_UNDEF;
      }
    }

    dallyCounter = 0;
    hostAddr.s_addr = host;
    /* add address and port to RETVAL hash */
    hv_store(RETVAL, "address", 7, newSVpv(inet_ntoa(hostAddr), 0), 0);
    hv_store(RETVAL, "port", 4, newSViv(ntohs(port)), 0);
    s = socket(AF_INET, SOCK_DGRAM, 0);
    taddr.sin_family = AF_INET;
    taddr.sin_port = 0;
    taddr.sin_addr.s_addr = 0;
#ifdef STRUCT_SOCKADDR_HAS_SA_LEN
    taddr.sin_len = sizeof(struct sockaddr_in);
#endif
    code = bind(s, (struct sockaddr *) &taddr, sizeof(struct sockaddr_in));
    FSSETCODE(code);
    if (code) {
      perror("bind");
      XSRETURN_UNDEF;
    }

    if (version_flag) /* add version to RETVAL and finish */
    {
       code = rx_GetServerVersion(s, host, port, length, version);
       if (code < 0)
       {
          sprintf(buffer, "get version call failed with code %d, errno %d",code,errno);
          BSETCODE(code, buffer);
          XSRETURN_UNDEF;
       }
       hv_store(RETVAL, "version", 7, newSVpv(version, 0), 0);
       goto done;
    }

    code = rx_GetServerDebug(s, host, port, &tstats, &supportedDebugValues);

    if (code < 0) {
      sprintf(buffer, "getstats call failed with code %d", code);
      BSETCODE(code, buffer);
      XSRETURN_UNDEF;
    }

    withSecStats = (supportedDebugValues & RX_SERVER_DEBUG_SEC_STATS);
    withAllConn = (supportedDebugValues & RX_SERVER_DEBUG_ALL_CONN);
    withRxStats = (supportedDebugValues & RX_SERVER_DEBUG_RX_STATS);
    withWaiters = (supportedDebugValues & RX_SERVER_DEBUG_WAITER_CNT);
    withIdleThreads = (supportedDebugValues & RX_SERVER_DEBUG_IDLE_THREADS);
    withPeers = (supportedDebugValues & RX_SERVER_DEBUG_ALL_PEER);

    TSTATS = newHV();
    hv_store(TSTATS, "nFreePackets", 12, newSViv(tstats.nFreePackets), 0);
    hv_store(TSTATS, "packetReclaims", 14, newSViv(tstats.packetReclaims), 0);
    hv_store(TSTATS, "callsExecuted", 13, newSViv(tstats.callsExecuted), 0);
    hv_store(TSTATS, "usedFDs", 7, newSViv(tstats.usedFDs), 0);
    hv_store(TSTATS, "waitingForPackets", 17, newSViv(tstats.waitingForPackets), 0);
    hv_store(TSTATS, "version", 7, newSViv(tstats.version), 0);
    if (withWaiters)
       hv_store(TSTATS, "nWaiting", 8, newSViv(tstats.nWaiting), 0);
    if ( withIdleThreads )
       hv_store(TSTATS, "idleThreads", 11, newSViv(tstats.idleThreads), 0);
    hv_store(RETVAL, "tstats", 6, newRV_inc((SV*)(TSTATS)), 0);

    /* get rxstats if requested, and supported by the server */
    /* hash containing stats added at key 'rxstats' in RETVAL */
    if (rxstats)
    {
      if (!withRxStats)
      {
        noRxStats:
        withRxStats = 0;
        warn("WARNING: Server doesn't support retrieval of Rx statistics\n");
      }
      else {
        struct rx_statistics rxstats;

        /* should gracefully handle the case where rx_statistics grows */
        code = rx_GetServerStats(s, host, port, &rxstats, &supportedStatValues);
        if (code < 0) {
          sprintf(buffer, "rxstats call failed with code %d", code);
          VSETCODE(code, buffer);
          XSRETURN_UNDEF;
        }
        if (code != sizeof(rxstats)) {
          if ((((struct rx_debugIn *)(&rxstats))->type == RX_DEBUGI_BADTYPE))
            goto noRxStats;
          warn("WARNING: returned Rx statistics of unexpected size (got %d)\n", code);
          /* handle other versions?... */
        }

        RXSTATS = newHV();

        myPrintTheseStats(RXSTATS, &rxstats);

        hv_store(RETVAL, "rxstats", 7, newRV_inc((SV*)(RXSTATS)), 0);

      }
    }

    /* get connections unless -noconns flag was set */
    /* array of connections added at key 'connections' in RETVAL hash */
    if (!noConns) {
      if (allconns) {
        if (!withAllConn) {
          warn("WARNING: Server doesn't support retrieval of all connections,\n");
          warn("         getting only interesting instead.\n");
          }
      }

      CONNECTIONS = newAV();
      index = 0;
      for ( i = 0; ; i++) {
        code = rx_GetServerConnections(s, host, port, &nextconn, allconns,
                      supportedDebugValues, &tconn,
                      &supportedConnValues);
        if (code < 0) {
          warn("getconn call failed with code %d\n", code);
          break;
        }
        if (tconn.cid == 0xffffffff) {
          break;
        }

        /* see if we're in nodally mode and all calls are dallying */
        if (nodally) {
          flag = 0;
          for (j = 0; j < RX_MAXCALLS; j++) {
             if (tconn.callState[j] != RX_STATE_NOTINIT &&
                 tconn.callState[j] != RX_STATE_DALLY) {
               flag = 1;
               break;
             }
          }
          if (flag == 0) {
            /* this call looks too ordinary, bump skipped count and go
             * around again */
            dallyCounter++;
            continue;
          }
        }
        if ((onlyHost != -1) && (onlyHost != tconn.host)) continue;
        if ((onlyPort != -1) && (onlyPort != tconn.port)) continue;
        if (onlyServer && (tconn.type != RX_SERVER_CONNECTION)) continue;
        if (onlyClient && (tconn.type != RX_CLIENT_CONNECTION)) continue;
        if (onlyAuth != 999) {
          if (onlyAuth == -1) {
            if (tconn.securityIndex != 0) continue;
          }
          else {
            if (tconn.securityIndex != 2) continue;
            if (withSecStats && (tconn.secStats.type == 3) &&
             (tconn.secStats.level != onlyAuth)) continue;
          }
        }
        TCONN = newHV();
        hostAddr.s_addr = tconn.host;
        hv_store(TCONN, "host", 4, newSVpv(inet_ntoa(hostAddr), 0), 0);
        hv_store(TCONN, "port", 4, newSViv(ntohs(tconn.port)), 0);

        hv_store(TCONN, "cid", 3, newSViv(tconn.cid), 0);
        hv_store(TCONN, "epoch", 5, newSViv(tconn.epoch), 0);
        hv_store(TCONN, "error", 5, newSViv(tconn.error), 0);
        hv_store(TCONN, "serial", 6, newSViv(tconn.serial), 0);
        hv_store(TCONN, "natMTU", 6, newSViv(tconn.natMTU), 0);

        hv_store(TCONN, "flags", 5, newSViv(tconn.flags), 0);

        hv_store(TCONN, "securityIndex", 13, newSViv(tconn.securityIndex), 0);

        hv_store(TCONN, "type", 4, newSViv(tconn.type), 0);

        if (withSecStats) {
          HV* SECSTATS = newHV();
          hv_store(SECSTATS, "type", 4,
                   newSViv(tconn.secStats.type), 0);
          hv_store(SECSTATS, "level", 5,
                   newSViv(tconn.secStats.level), 0);
          hv_store(SECSTATS, "flags", 5,
                   newSViv(tconn.secStats.flags), 0);
          hv_store(SECSTATS, "expires", 7,
                   newSViv(tconn.secStats.expires), 0);
          hv_store(SECSTATS, "packetsReceived", 15,
                   newSViv(tconn.secStats.packetsReceived), 0);
          hv_store(SECSTATS, "packetsSent", 11,
                   newSViv(tconn.secStats.packetsSent), 0);
          hv_store(SECSTATS, "bytesReceived", 13,
                   newSViv(tconn.secStats.bytesReceived), 0);
          hv_store(SECSTATS, "bytesSent", 9,
                   newSViv(tconn.secStats.bytesSent), 0);
          hv_store(TCONN, "secStats", 8, newRV_inc((SV*)(SECSTATS)), 0);
        }

        CALLSTATE = newAV();
        av_fill(CALLSTATE, RX_MAXCALLS-1);
        CALLMODE = newAV();
        av_fill(CALLMODE, RX_MAXCALLS-1);
        CALLFLAGS = newAV();
        av_fill(CALLFLAGS, RX_MAXCALLS-1);
        CALLOTHER = newAV();
        av_fill(CALLOTHER, RX_MAXCALLS-1);
        CALLNUMBER = newAV();
        av_fill(CALLNUMBER, RX_MAXCALLS-1);

        for (j = 0; j < RX_MAXCALLS; j++) {
          av_store(CALLSTATE, j, newSViv(tconn.callState[j]));
          av_store(CALLMODE, j, newSViv(tconn.callMode[j]));
          av_store(CALLFLAGS, j, newSViv(tconn.callFlags[j]));
          av_store(CALLOTHER, j, newSViv(tconn.callOther[j]));
          av_store(CALLNUMBER, j, newSViv(tconn.callNumber[j]));
        }

        hv_store(TCONN, "callState", 9, newRV_inc((SV*)(CALLSTATE)), 0);
        hv_store(TCONN, "callMode", 8, newRV_inc((SV*)(CALLMODE)), 0);
        hv_store(TCONN, "callFlags", 9, newRV_inc((SV*)(CALLFLAGS)), 0);
        hv_store(TCONN, "callOther", 9, newRV_inc((SV*)(CALLOTHER)), 0);
        hv_store(TCONN, "callNumber", 10, newRV_inc((SV*)(CALLNUMBER)), 0);

        av_store(CONNECTIONS, index, newRV_inc((SV*)(TCONN)));
        index++;
      } /* end of for loop */
      if (nodally) hv_store(RETVAL, "dallyCounter", 12, newSViv(dallyCounter), 0);
      hv_store(RETVAL, "connections", 11, newRV_inc((SV*)(CONNECTIONS)), 0);
    } /* end of if (!noConns) */

    /* get peers if requested */
    /* array of peers added at key 'peers' in RETVAL hash */
    if (showPeers && withPeers) {
      PEERS = newAV();
      index = 0;
      for (i = 0; ; i++) {
        struct rx_debugPeer tpeer;
        code = rx_GetServerPeers(s, host, port, &nextpeer, allconns,
                                 &tpeer, &supportedPeerValues);
        if (code < 0) {
          warn("getpeer call failed with code %d\n", code);
          break;
        }
        if (tpeer.host == 0xffffffff) {
          break;
        }

        if ((onlyHost != -1) && (onlyHost != tpeer.host)) continue;
        if ((onlyPort != -1) && (onlyPort != tpeer.port)) continue;

        TPEER = newHV();

        hostAddr.s_addr = tpeer.host;
        hv_store(TPEER, "host", 4, newSVpv(inet_ntoa(hostAddr), 0), 0);
        hv_store(TPEER, "port", 4, newSViv(ntohs(tpeer.port)), 0);

        hv_store(TPEER, "ifMTU", 5, newSViv(tpeer.ifMTU), 0);
        hv_store(TPEER, "natMTU", 6, newSViv(tpeer.natMTU), 0);
        hv_store(TPEER, "maxMTU", 6, newSViv(tpeer.maxMTU), 0);
        hv_store(TPEER, "nSent", 5, newSViv(tpeer.nSent), 0);
        hv_store(TPEER, "reSends", 7, newSViv(tpeer.reSends), 0);

        BYTESSENT = newHV();
        hv_store(BYTESSENT, "high", 4, newSViv(tpeer.bytesSent.high), 0);
        hv_store(BYTESSENT, "low", 3, newSViv(tpeer.bytesSent.low), 0);
        hv_store(TPEER, "bytesSent", 9, newRV_inc((SV*)(BYTESSENT)), 0);

        BYTESRECEIVED = newHV();
        hv_store(BYTESRECEIVED, "high", 4, newSViv(tpeer.bytesReceived.high), 0);
        hv_store(BYTESRECEIVED, "low", 3, newSViv(tpeer.bytesReceived.low), 0);
        hv_store(TPEER, "bytesReceived", 13, newRV_inc((SV*)(BYTESRECEIVED)), 0);

        hv_store(TPEER, "rtt", 3, newSViv(tpeer.rtt), 0);
        hv_store(TPEER, "rtt_dev", 7, newSViv(tpeer.rtt_dev), 0);

        TIMEOUT = newHV();
        hv_store(TIMEOUT, "sec", 3, newSViv(tpeer.timeout.sec), 0);
        hv_store(TIMEOUT, "usec", 4, newSViv(tpeer.timeout.usec), 0);
        hv_store(TPEER, "timeout", 7, newRV_inc((SV*)(TIMEOUT)), 0);

        if (showLong) {
          hv_store(TPEER, "inPacketSkew", 12,
                   newSViv(tpeer.inPacketSkew), 0);
          hv_store(TPEER, "outPacketSkew", 13,
                   newSViv(tpeer.outPacketSkew), 0);
          hv_store(TPEER, "cwind", 5,
                   newSViv(tpeer.cwind), 0);
          hv_store(TPEER, "MTU", 3,
                   newSViv(tpeer.MTU), 0);
          hv_store(TPEER, "nDgramPackets", 13,
                   newSViv(tpeer.nDgramPackets), 0);
          hv_store(TPEER, "ifDgramPackets", 14,
                   newSViv(tpeer.ifDgramPackets), 0);
          hv_store(TPEER, "maxDgramPackets", 15,
                   newSViv(tpeer.maxDgramPackets), 0);
        }

        av_store(PEERS, index, newRV_inc((SV*)(TPEER)));
        index++;
      }

      hv_store(RETVAL, "peers", 5, newRV_inc((SV*)(PEERS)), 0);
    }

    done:
    /* return RETVAL */
    ST(0) = sv_2mortal(newRV_inc((SV*)RETVAL));
    SETCODE(0);
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

void
constant(name, arg=0)
	char *	name
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
		if (strEQ(name,"AFSCB_MAX_XSTAT_LONGS"))
                    sv_setiv(ST(0),AFSCB_MAX_XSTAT_LONGS);
		else if (strEQ(name,"AFSCB_XSTATSCOLL_CALL_INFO"))
                    sv_setiv(ST(0),AFSCB_XSTATSCOLL_CALL_INFO);
		else if (strEQ(name,"AFSCB_XSTATSCOLL_FULL_PERF_INFO"))
                    sv_setiv(ST(0),AFSCB_XSTATSCOLL_FULL_PERF_INFO);
		else if (strEQ(name,"AFSCB_XSTATSCOLL_PERF_INFO"))
                    sv_setiv(ST(0),AFSCB_XSTATSCOLL_PERF_INFO);
		else if (strEQ(name,"AFSCB_XSTAT_VERSION"))
                    sv_setiv(ST(0),AFSCB_XSTAT_VERSION);
		else if (strEQ(name,"AFSCONF_VOLUMEPORT"))
                    sv_setiv(ST(0),AFSCONF_VOLUMEPORT);
		else if (strEQ(name,"AFS_MAX_XSTAT_LONGS"))
                    sv_setiv(ST(0),AFS_MAX_XSTAT_LONGS);
		else if (strEQ(name,"AFS_STATS_NUM_CM_RPC_OPS"))
                    sv_setiv(ST(0),AFS_STATS_NUM_CM_RPC_OPS);
		else if (strEQ(name,"AFS_STATS_NUM_FS_RPC_OPS"))
                    sv_setiv(ST(0),AFS_STATS_NUM_FS_RPC_OPS);
		else if (strEQ(name,"AFS_STATS_NUM_FS_XFER_OPS"))
                    sv_setiv(ST(0),AFS_STATS_NUM_FS_XFER_OPS);
		else if (strEQ(name,"AFS_XSTATSCOLL_CALL_INFO"))
                    sv_setiv(ST(0),AFS_XSTATSCOLL_CALL_INFO);
#ifndef NOAFS_XSTATSCOLL_CBSTATS
		else if (strEQ(name,"AFS_XSTATSCOLL_CBSTATS"))
                    sv_setiv(ST(0),AFS_XSTATSCOLL_CBSTATS);
#endif
		else if (strEQ(name,"AFS_XSTATSCOLL_FULL_PERF_INFO"))
                    sv_setiv(ST(0),AFS_XSTATSCOLL_FULL_PERF_INFO);
		else if (strEQ(name,"AFS_XSTATSCOLL_PERF_INFO"))
                    sv_setiv(ST(0),AFS_XSTATSCOLL_PERF_INFO);
		else if (strEQ(name,"AFS_XSTAT_VERSION"))
                    sv_setiv(ST(0),AFS_XSTAT_VERSION);
		else {
		     ST(0) = ST(1) = &PL_sv_undef;
		     return;
		}
		break;
		case '_':
		if (strEQ(name,"AF_INET")) sv_setiv(ST(0),AF_INET);
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
	case 'F':
		switch (name[2]) {
		case 'G':
		if (strEQ(name,"CFG_STR_LEN"))
                    sv_setiv(ST(0),CFG_STR_LEN);
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
	case 'M':
		if (strEQ(name,"CM")) sv_setiv(ST(0),CM);
                else {
		switch (name[2]) {
		case '_':
		if (strEQ(name,"CM_NUM_DATA_CATEGORIES"))
                    sv_setiv(ST(0),CM_NUM_DATA_CATEGORIES);
		else if (strEQ(name,"CM_STAT_STRING_LEN"))
                    sv_setiv(ST(0),CM_STAT_STRING_LEN);
		else {
		     ST(0) = ST(1) = &PL_sv_undef;
		     return;
		}
		break;
  		default:
  			ST(0) = ST(1) = &PL_sv_undef;
			return;
  		}
                }
  		break;
  	default:
  		ST(0) = ST(1) = &PL_sv_undef;
		return;
  	}
  	break;
  case 'F':
	switch (name[1]) {
	case 'S':
		if (strEQ(name,"FS")) sv_setiv(ST(0),FS);
                else {
		switch (name[2]) {
		case 'P':
		if (strEQ(name,"FSPROBE_CBPORT"))
                    sv_setiv(ST(0),FSPROBE_CBPORT);
		else {
		     ST(0) = ST(1) = &PL_sv_undef;
		     return;
		}
		break;
		case '_':
		if (strEQ(name,"FS_NUM_DATA_CATEGORIES"))
                    sv_setiv(ST(0),FS_NUM_DATA_CATEGORIES);
		else if (strEQ(name,"FS_STATS_NUM_RPC_OPS"))
                    sv_setiv(ST(0),FS_STATS_NUM_RPC_OPS);
		else if (strEQ(name,"FS_STATS_NUM_XFER_OPS"))
                    sv_setiv(ST(0),FS_STATS_NUM_XFER_OPS);
		else if (strEQ(name,"FS_STAT_STRING_LEN"))
                    sv_setiv(ST(0),FS_STAT_STRING_LEN);
		else {
		     ST(0) = ST(1) = &PL_sv_undef;
		     return;
		}
		break;
  		default:
  			ST(0) = ST(1) = &PL_sv_undef;
			return;
  		}
                }
  		break;
  	default:
  		ST(0) = ST(1) = &PL_sv_undef;
		return;
  	}
  	break;
  case 'H':
	switch (name[1]) {
	case 'O':
		switch (name[2]) {
		case 'S':
		if (strEQ(name,"HOST_NAME_LEN"))
                    sv_setiv(ST(0),HOST_NAME_LEN);
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
		if (strEQ(name,"MAXSKEW"))
                    sv_setiv(ST(0),MAXSKEW);
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
	case 'U':
		switch (name[2]) {
		case 'M':
		if (strEQ(name,"NUM_AFS_STATS_CMPERF_LONGS"))
                    sv_setiv(ST(0),NUM_AFS_STATS_CMPERF_LONGS);
		else if (strEQ(name,"NUM_CM_STAT_ENTRIES"))
                    sv_setiv(ST(0),NUM_CM_STAT_ENTRIES);
		else if (strEQ(name,"NUM_FS_STAT_ENTRIES"))
                    sv_setiv(ST(0),NUM_FS_STAT_ENTRIES);
		else if (strEQ(name,"NUM_XSTAT_FS_AFS_PERFSTATS_LONGS"))
                    sv_setiv(ST(0),NUM_XSTAT_FS_AFS_PERFSTATS_LONGS);
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
	case 'A':
		switch (name[2]) {
		case 'R':
		if (strEQ(name,"PARTVALID"))
                    sv_setiv(ST(0),PARTVALID);
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
	case 'E':
		switch (name[2]) {
		case 'A':
		if (strEQ(name,"READ_LOCK"))
                    sv_setiv(ST(0),READ_LOCK);
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
	case 'X':
		switch (name[2]) {
		case 'G':
		if (strEQ(name,"RXGEN_OPCODE"))
                    sv_setiv(ST(0),RXGEN_OPCODE);
		else {
		     ST(0) = ST(1) = &PL_sv_undef;
		     return;
		}
		break;
		case '_':
		if (strEQ(name,"RX_ADDRINUSE"))
                    sv_setiv(ST(0),RX_ADDRINUSE);
		else if (strEQ(name,"RX_CALL_CLEARED"))
                    sv_setiv(ST(0),RX_CALL_CLEARED);
		else if (strEQ(name,"RX_CALL_READER_WAIT"))
                    sv_setiv(ST(0),RX_CALL_READER_WAIT);
		else if (strEQ(name,"RX_CALL_RECEIVE_DONE"))
                    sv_setiv(ST(0),RX_CALL_RECEIVE_DONE);
		else if (strEQ(name,"RX_CALL_WAIT_PACKETS"))
                    sv_setiv(ST(0),RX_CALL_WAIT_PACKETS);
		else if (strEQ(name,"RX_CALL_WAIT_PROC"))
                    sv_setiv(ST(0),RX_CALL_WAIT_PROC);
		else if (strEQ(name,"RX_CALL_WAIT_WINDOW_ALLOC"))
                    sv_setiv(ST(0),RX_CALL_WAIT_WINDOW_ALLOC);
		else if (strEQ(name,"RX_CALL_WAIT_WINDOW_SEND"))
                    sv_setiv(ST(0),RX_CALL_WAIT_WINDOW_SEND);
		else if (strEQ(name,"RX_CLIENT_CONNECTION"))
                    sv_setiv(ST(0),RX_CLIENT_CONNECTION);
		else if (strEQ(name,"RX_CONN_DESTROY_ME"))
                    sv_setiv(ST(0),RX_CONN_DESTROY_ME);
		else if (strEQ(name,"RX_CONN_MAKECALL_WAITING"))
                    sv_setiv(ST(0),RX_CONN_MAKECALL_WAITING);
		else if (strEQ(name,"RX_CONN_USING_PACKET_CKSUM"))
                    sv_setiv(ST(0),RX_CONN_USING_PACKET_CKSUM);
		else if (strEQ(name,"RX_DEBUGI_VERSION_W_NEWPACKETTYPES"))
                    sv_setiv(ST(0),RX_DEBUGI_VERSION_W_NEWPACKETTYPES);
		else if (strEQ(name,"RX_MAXCALLS"))
                    sv_setiv(ST(0),RX_MAXCALLS);
		else if (strEQ(name,"RX_MODE_EOF"))
                    sv_setiv(ST(0),RX_MODE_EOF);
		else if (strEQ(name,"RX_MODE_ERROR"))
                    sv_setiv(ST(0),RX_MODE_ERROR);
		else if (strEQ(name,"RX_MODE_RECEIVING"))
                    sv_setiv(ST(0),RX_MODE_RECEIVING);
		else if (strEQ(name,"RX_MODE_SENDING"))
                    sv_setiv(ST(0),RX_MODE_SENDING);
		else if (strEQ(name,"RX_N_PACKET_TYPES"))
                    sv_setiv(ST(0),RX_N_PACKET_TYPES);
		else if (strEQ(name,"RX_OTHER_IN"))
                    sv_setiv(ST(0),RX_OTHER_IN);
		else if (strEQ(name,"RX_OTHER_OUT"))
                    sv_setiv(ST(0),RX_OTHER_OUT);
		else if (strEQ(name,"RX_SERVER_CONNECTION"))
                    sv_setiv(ST(0),RX_SERVER_CONNECTION);
		else if (strEQ(name,"RX_SERVER_DEBUG_ALL_CONN"))
                    sv_setiv(ST(0),RX_SERVER_DEBUG_ALL_CONN);
		else if (strEQ(name,"RX_SERVER_DEBUG_ALL_PEER"))
                    sv_setiv(ST(0),RX_SERVER_DEBUG_ALL_PEER);
		else if (strEQ(name,"RX_SERVER_DEBUG_IDLE_THREADS"))
                    sv_setiv(ST(0),RX_SERVER_DEBUG_IDLE_THREADS);
		else if (strEQ(name,"RX_SERVER_DEBUG_RX_STATS"))
                    sv_setiv(ST(0),RX_SERVER_DEBUG_RX_STATS);
		else if (strEQ(name,"RX_SERVER_DEBUG_SEC_STATS"))
                    sv_setiv(ST(0),RX_SERVER_DEBUG_SEC_STATS);
		else if (strEQ(name,"RX_SERVER_DEBUG_WAITER_CNT"))
                    sv_setiv(ST(0),RX_SERVER_DEBUG_WAITER_CNT);
		else if (strEQ(name,"RX_STATE_ACTIVE"))
                    sv_setiv(ST(0),RX_STATE_ACTIVE);
		else if (strEQ(name,"RX_STATE_DALLY"))
                    sv_setiv(ST(0),RX_STATE_DALLY);
		else if (strEQ(name,"RX_STATE_HOLD"))
                    sv_setiv(ST(0),RX_STATE_HOLD);
		else if (strEQ(name,"RX_STATE_NOTINIT"))
                    sv_setiv(ST(0),RX_STATE_NOTINIT);
		else if (strEQ(name,"RX_STATE_PRECALL"))
                    sv_setiv(ST(0),RX_STATE_PRECALL);
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
	case 'H':
		switch (name[2]) {
		case 'A':
		if (strEQ(name,"SHARED_LOCK"))
                    sv_setiv(ST(0),SHARED_LOCK);
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
	case 'O':
		switch (name[2]) {
		case 'C':
		if (strEQ(name,"SOCK_DGRAM"))
                    sv_setiv(ST(0),SOCK_DGRAM);
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
  case 'T':
	switch (name[1]) {
	case 'H':
		switch (name[2]) {
		case 'R':
		if (strEQ(name,"THRESH_VAR_LEN"))
                    sv_setiv(ST(0),THRESH_VAR_LEN);
		else if (strEQ(name,"THRESH_VAR_NAME_LEN"))
                    sv_setiv(ST(0),THRESH_VAR_NAME_LEN);
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
		case 'I':
		if (strEQ(name,"UBIK_MAX_INTERFACE_ADDR"))
                    sv_setiv(ST(0),UBIK_MAX_INTERFACE_ADDR);
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
	case 'O':
		switch (name[2]) {
		case 'L':
		if (strEQ(name,"VOLMAXPARTS"))
                    sv_setiv(ST(0),VOLMAXPARTS);
		else if (strEQ(name,"VOLSERVICE_ID"))
                    sv_setiv(ST(0),VOLSERVICE_ID);
		else {
		     ST(0) = ST(1) = &PL_sv_undef;
		     return;
		}
		break;
		case 'T':
		if (strEQ(name,"VOTE_SERVICE_ID"))
                    sv_setiv(ST(0),VOTE_SERVICE_ID);
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
  case 'W':
	switch (name[1]) {
	case 'R':
		switch (name[2]) {
		case 'I':
		if (strEQ(name,"WRITE_LOCK"))
                    sv_setiv(ST(0),WRITE_LOCK);
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
  case 'X':
	switch (name[1]) {
	case 'S':
		switch (name[2]) {
		case 'T':
		if (strEQ(name,"XSTAT_FS_CBPORT"))
                    sv_setiv(ST(0),XSTAT_FS_CBPORT);
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
