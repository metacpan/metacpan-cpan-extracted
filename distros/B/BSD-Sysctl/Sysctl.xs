/* Sysctl.xs -- XS component of BSD-Sysctl
 *
 * Copyright (C) 2006-2014 David Landgren
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* define _FreeBSD_version where applicable */
#if __FreeBSD__ >= 2
#include <osreldate.h>
#endif

#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#include <sys/time.h>       /* struct clockinfo */
#include <sys/vmmeter.h>    /* struct vmtotal */
#include <sys/resource.h>   /* struct loadavg */
#if __FreeBSD_version < 1000000
#include <sys/mbuf.h>       /* struct mbstat (opaque mib) */
#endif
#include <sys/timex.h>      /* struct ntptimeval (opaque mib) */
#include <sys/devicestat.h> /* struct devstat (opaque mib) */
#include <sys/mount.h>      /* struct xvfsconf (opaque mib) */

/* prerequisites for TCP/IP-related structs */
#include <arpa/inet.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#if __FreeBSD_version < 500000
#include <netinet/tcp.h>  /* struct tcpstat prerequisite */
#endif

#include <netinet/icmp_var.h> /* struct icmpstat */
#include <netinet/igmp_var.h> /* struct igmpstat */
#include <netinet/tcp_var.h>  /* struct tcpstat */

/* prerequisites for struct udpstat */
#include <netinet/in.h>
#include <netinet/ip_var.h>
#include <netinet/udp.h>
#include <netinet/udp_var.h>

#include <netinet6/raw_ip6.h>
#include "bsd-sysctl.h"

int
_init_iterator(HV *self, int *mib, int *miblenp, int valid) {
    SV **headp;
    int qoid[CTL_MAXNAME];
    u_int qoidlen;
    SV *clen;
    SV **clenp;
    int cmplen;
    int j;

    qoid[0] = 0;
    qoid[1] = 2;
    if (valid) {
        memcpy(qoid+2, mib, (*miblenp) * sizeof(int));
        qoidlen = *miblenp + 2;
        *miblenp = (CTL_MAXNAME+2) * sizeof(int);
        clenp = hv_fetch(self, "_len", 4, 0);
        cmplen = SvIV(*clenp);
    }
    else {
        headp = hv_fetch(self, "head", 4, 0);
        if (!(headp && *headp)) {
            croak( "failed to get some head in _init_iterator()\n" );
        }
        if (SvPOK(*headp)) {
            /* begin where asked */
            qoidlen = sizeof(qoid);
            if (sysctlnametomib( SvPV_nolen(*headp), qoid+2, (size_t*)&qoidlen) == -1) {
                warn( "_init_iterator(%s): sysctlnametomib lookup failed\n",
                    SvPV_nolen(*headp)
                );
                return 0;
            }
            cmplen = qoidlen;
            qoidlen += 2;
        }
        else {
            /* begin at the beginning */
            qoid[2] = 1;
            cmplen  = 0;
            qoidlen = 3;
        }
        clen = newSViv(cmplen);
        SvREFCNT_inc(clen);
        hv_store(self, "_len", 4, clen, 0);
    }

    /*
    printf( "next: " );
    for (j = 0; j < qoidlen; ++j) {
        if (j) printf("."); printf("%d", qoid[j]);
    }
    printf("\n");
    */

    /* load the mib */
    if (sysctl(qoid, qoidlen, mib, (size_t*)miblenp, 0, 0) == -1) {
        return 0;
    }
    *miblenp /= sizeof(int);
    if (*miblenp < cmplen) {
        return 0 ;
    }

    for (j = 0; j < cmplen; ++j) {
        if (mib[j] != qoid[j+2]) {
            return 0;
        }
    }
    return 1;
}

MODULE = BSD::Sysctl   PACKAGE = BSD::Sysctl

PROTOTYPES: ENABLE

SV *
next (SV *refself)
    INIT:
        int mib[CTL_MAXNAME+2];
        size_t miblen;
        int qoid[CTL_MAXNAME+2];
        size_t qoidlen;
        char name[BUFSIZ];
        size_t namelen;
        HV *self;
        SV **ctxp;
        SV *ctx;
        SV *cname;
        int j;
        int *p;

    CODE:
        self = (HV *)SvRV(refself);
        if ((ctxp = hv_fetch(self, "_ctx", 4, 0))) {
            p = (int *)SvPVX(*ctxp);
            miblen = *p++;
            memcpy(mib, p, miblen * sizeof(int));

            if (!_init_iterator(self, mib, (int*)&miblen, 1)) {
                XSRETURN_UNDEF;
            }
        }
        else {
            miblen = sizeof(mib)/sizeof(mib[0]);
            if (!_init_iterator(self, mib, (int*)&miblen, 0)) {
                XSRETURN_UNDEF;
            }
        }

        qoid[0] = 0;
        qoid[1] = 1;
        memcpy(qoid+2, mib, miblen * sizeof(int));
        qoidlen = miblen + 2;

        bzero(name, BUFSIZ);
        namelen = sizeof(name);
        j = sysctl(qoid, qoidlen, name, &namelen, 0, 0);
        if (j || !namelen) {
            warn("next(): sysctl name failure %d %zu %d", j, namelen, errno);
            XSRETURN_UNDEF;
        }
        cname = newSVpvn(name, namelen-1);
        SvREFCNT_inc(cname);
        hv_store(self, "_name", 5, cname, 0);
        RETVAL = cname;

        /* reuse qoid to build context store
         *  - the length of the mib
         *  - followed by the mib values
         * and copy to an SV to save in the self hash
         */
        p = qoid;
        memcpy(p++, (const void *)&miblen, sizeof(int));
        memcpy(p, (const void *)mib, miblen * sizeof(int));

        ctx = newSVpvn((const char *)qoid, (miblen+1) * sizeof(int));
        SvREFCNT_inc(ctx);
        hv_store(self, "_ctx", 4, ctx, 0);

    OUTPUT:
        RETVAL

int
_mib_exists(const char *arg)
    CODE:
        int mib[CTL_MAXNAME];
        size_t miblen = (sizeof(mib)/sizeof(mib[0]));
        RETVAL = (sysctlnametomib(arg, mib, &miblen) != -1);
    OUTPUT:
        RETVAL

SV *
_mib_info(const char *arg)
    INIT:
        int mib[CTL_MAXNAME+2];
        size_t miblen;
        int nr_octets;
        int size;
        char fmt[BUFSIZ];
        size_t len = sizeof(fmt);
        int fmt_type;
        char *f = fmt + sizeof(int);
        char res[BUFSIZ];
        char *resp = res;
        SV *cache;
        SV **store;

    CODE:
        /* see if the mib exists */
        miblen = (sizeof(mib) / sizeof(mib[0])) - 2;
        if (sysctlnametomib(arg, mib+2, &miblen) == -1) {
            XSRETURN_UNDEF;
        }
        nr_octets = miblen;

        /* determine how to format the results */
        mib[0] = 0;
        mib[1] = 4;
        if (sysctl(mib, nr_octets+2, fmt, &len, NULL, 0) == -1) {
            XSRETURN_UNDEF;
        }

        switch (*f) {
        case 'A':
            fmt_type = FMT_A;
            break;
        case 'I':
            ++f;
            fmt_type = *f == 'U' ? FMT_UINT : FMT_INT;
            break;
        case 'L':
            ++f;
            fmt_type = *f == 'U' ? FMT_ULONG : FMT_LONG;
            break;
        case 'Q':
            ++f;
            fmt_type = *f == 'U' ? FMT_U64 : FMT_64;
            break;
        case 'S': {
            if (strcmp(f,"S,clockinfo") == 0)    { fmt_type = FMT_CLOCKINFO; }
            else if (strcmp(f,"S,loadavg") == 0) { fmt_type = FMT_LOADAVG; }
            else if (strcmp(f,"S,timeval") == 0) { fmt_type = FMT_TIMEVAL; }
            else if (strcmp(f,"S,vmtotal") == 0) { fmt_type = FMT_VMTOTAL; }
            /* now the opaque OIDs */
            else if (strcmp(f,"S,bootinfo") == 0)   { fmt_type = FMT_BOOTINFO; }
            else if (strcmp(f,"S,devstat") == 0)    { fmt_type = FMT_DEVSTAT; }
            else if (strcmp(f,"S,icmpstat") == 0)   { fmt_type = FMT_ICMPSTAT; }
            else if (strcmp(f,"S,igmpstat") == 0)   { fmt_type = FMT_IGMPSTAT; }
            else if (strcmp(f,"S,ipstat") == 0)     { fmt_type = FMT_IPSTAT; }
            else if (strcmp(f,"S,mbstat") == 0)     { fmt_type = FMT_MBSTAT; } /* removed in FreeBSD 10 */
            else if (strcmp(f,"S,nfsrvstats") == 0) { fmt_type = FMT_NFSRVSTATS; }
            else if (strcmp(f,"S,nfsstats") == 0)   { fmt_type = FMT_NFSSTATS; }
            else if (strcmp(f,"S,ntptimeval") == 0) { fmt_type = FMT_NTPTIMEVAL; }
            else if (strcmp(f,"S,rip6stat") == 0)   { fmt_type = FMT_RIP6STAT; }
            else if (strcmp(f,"S,tcpstat") == 0)    { fmt_type = FMT_TCPSTAT; }
            else if (strcmp(f,"S,udpstat") == 0)    { fmt_type = FMT_UDPSTAT; }
            else if (strcmp(f,"S,xinpcb") == 0)     { fmt_type = FMT_XINPCB; }
            else if (strcmp(f,"S,xvfsconf") == 0)   { fmt_type = FMT_XVFSCONF; }
            else {
                /* bleah */
            }
            break;
        }
        case 'T': {
            if (strcmp(f,"T,struct cdev *") == 0) {
                fmt_type = FMT_STRUCT_CDEV;
            }
            else {
                /* bleah */
            }
            break;
        }
        case 'N':
            fmt_type = FMT_N;
            break;
        default:
            fmt_type = FMT_A;
            break;
        }

        /* first two bytes indicate format type */
        memcpy(resp, (void *)&fmt_type, sizeof(int));
        resp += sizeof(int);
        len = sizeof(int);

        /* reuse len to measure cached info */
        /* next two bytes indicate the length of the oid */
        memcpy(resp, (void *)&nr_octets, sizeof(int));
        resp += sizeof(int);
        len += sizeof(int);

        /* following bytes are the numeric oid (step past 0, 4) */
        size = (nr_octets) * sizeof(int);
        memcpy(resp, (void *)(mib+2), size);
        len += size;

        cache = newSVpvn(res, len);
        store = hv_store(
            get_hv("BSD::Sysctl::MIB_CACHE", 0),
            arg, strlen(arg), cache, 0
        );
        SvREFCNT_inc(cache);
        RETVAL = cache;
    OUTPUT:
        RETVAL

SV *
_mib_description(const char *arg)
    INIT:
        int mib[CTL_MAXNAME];
        size_t miblen = (sizeof(mib)/sizeof(mib[0]));
        int qmib[CTL_MAXNAME+2];
        char desc[BUFSIZ];
        size_t len = sizeof(desc);
    CODE:
        /* see if the mib exists */
        if (sysctlnametomib(arg, mib, &miblen) == -1) {
            XSRETURN_UNDEF;
        }
        /* fetch the description */
        qmib[0] = 0;
        qmib[1] = 5;
        memcpy(qmib+2, mib, miblen * sizeof(int));
        if (sysctl(qmib, miblen+2, desc, &len, NULL, 0) == -1) {
            XSRETURN_UNDEF;
        }
        RETVAL = newSVpvn(desc, len-1);
    OUTPUT:
        RETVAL

SV *
_mib_lookup(const char *arg)
    INIT:
        HV *cache;
        SV **oidp;
        SV *oid;
        int mib[CTL_MAXNAME];
        size_t miblen = (sizeof(mib)/sizeof(mib[0]));
        char *oid_data;
        int oid_fmt;
        int oid_len;
        SV *sv_buf;
        char *buf;
        size_t buflen = sizeof(buf);

    CODE:
        /* see if the mib exists */
        cache = get_hv("BSD::Sysctl::MIB_CACHE", 0);

        if((oidp = hv_fetch(cache, arg, strlen(arg), 0))) {
            oid = *oidp;
        }
        else {
            /* else use the cache
            * How do you call an XS sub from C?
            */
            warn("uncached mib: %s\n", arg);
            XSRETURN_UNDEF;
        }

        oid_data = SvPVX(oid);
        oid_fmt  = (int)(*oid_data);
        oid_data += sizeof(int);

        oid_len  = (int)(*oid_data);
        oid_data += sizeof(int);
        
        memcpy(mib, oid_data, oid_len * sizeof(int));

        /* determine buffer size */
        if (sysctl(mib, oid_len, NULL, &buflen, NULL, 0) == -1) {
            XSRETURN_UNDEF;
        }
        if (0 == buflen) {
            XSRETURN_UNDEF;
        }

        sv_buf = newSV(buflen);
        buf    = SvPVX(sv_buf);
        if (sysctl(mib, oid_len, buf, &buflen, NULL, 0) == -1) {
            XSRETURN_UNDEF;
        }

        switch(oid_fmt) {
        case FMT_A:
            SvPOK_on(sv_buf);
            SvCUR_set(sv_buf, buflen);
            RETVAL = sv_buf;
            break;
        case FMT_INT:
            if (buflen == sizeof(int)) {
                RETVAL = newSViv(*(int *)buf);
            }
            else {
                AV *c = (AV *)sv_2mortal((SV *)newAV());
                char *bptr = buf;
                while (buflen >= sizeof(int)) {
                    av_push(c, newSViv(*(int *)bptr));
                    buflen -= sizeof(int);
                    bptr   += sizeof(int);
                }
                RETVAL = newRV((SV *)c);
            }
            break;
        case FMT_UINT:
            if (buflen == sizeof(unsigned int)) {
                RETVAL = newSViv(*(unsigned int *)buf);
            }
            else {
                AV *c = (AV *)sv_2mortal((SV *)newAV());
                char *bptr = buf;
                while (buflen >= sizeof(unsigned int)) {
                    av_push(c, newSViv(*(unsigned int *)bptr));
                    buflen -= sizeof(unsigned int);
                    bptr   += sizeof(unsigned int);
                }
                RETVAL = newRV((SV *)c);
            }
            break;
        case FMT_LONG:
            if (buflen == sizeof(long)) {
                RETVAL = newSVuv(*(long *)buf);
            }
            else {
                AV *c = (AV *)sv_2mortal((SV *)newAV());
                char *bptr = buf;
                while (buflen >= sizeof(long)) {
                    av_push(c, newSVuv(*(long *)bptr));
                    buflen -= sizeof(long);
                    bptr   += sizeof(long);
                }
                RETVAL = newRV((SV *)c);
            }
            break;
        case FMT_ULONG:
            if (buflen == sizeof(unsigned long)) {
                RETVAL = newSVuv(*(unsigned long *)buf);
            }
            else {
                AV *c = (AV *)sv_2mortal((SV *)newAV());
                char *bptr = buf;
                while (buflen >= sizeof(unsigned long)) {
                    av_push(c, newSVuv(*(unsigned long *)bptr));
                    buflen -= sizeof(unsigned long);
                    bptr   += sizeof(unsigned long);
                }
                RETVAL = newRV((SV *)c);
            }
            break;
        case FMT_64:
            if (buflen == sizeof(int64_t)) {
                RETVAL = newSVuv(*(int64_t *)buf);
            }
            else {
                AV *c = (AV *)sv_2mortal((SV *)newAV());
                char *bptr = buf;
                while (buflen >= sizeof(int64_t)) {
                    av_push(c, newSVuv(*(int64_t *)bptr));
                    buflen -= sizeof(int64_t);
                    bptr   += sizeof(int64_t);
                }
                RETVAL = newRV((SV *)c);
            }
            break;
        case FMT_U64:
            if (buflen == sizeof(uint64_t)) {
                RETVAL = newSVuv(*(uint64_t *)buf);
            }
            else {
                AV *c = (AV *)sv_2mortal((SV *)newAV());
                char *bptr = buf;
                while (buflen >= sizeof(uint64_t)) {
                    av_push(c, newSVuv(*(uint64_t *)bptr));
                    buflen -= sizeof(uint64_t);
                    bptr   += sizeof(uint64_t);
                }
                RETVAL = newRV((SV *)c);
            }
            break;
        case FMT_CLOCKINFO: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct clockinfo *inf = (struct clockinfo *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "hz",     2, newSViv(inf->hz), 0);
            hv_store(c, "tick",   4, newSViv(inf->tick), 0);
            hv_store(c, "profhz", 6, newSViv(inf->profhz), 0);
            hv_store(c, "stathz", 6, newSViv(inf->stathz), 0);
            break;
        }
        case FMT_VMTOTAL: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct vmtotal *inf = (struct vmtotal *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "runqueue",          8, newSViv(inf->t_rq), 0);
            hv_store(c, "diskwait",          8, newSViv(inf->t_dw), 0);
            hv_store(c, "pagewait",          8, newSViv(inf->t_pw), 0);
            hv_store(c, "sleeping",          8, newSViv(inf->t_sl), 0);
            hv_store(c, "pagesize",          8, newSViv(getpagesize()), 0);
            hv_store(c, "vmtotal",           7, newSVuv(inf->t_vm), 0);
            hv_store(c, "vmactive",          8, newSVuv(inf->t_avm), 0);
            hv_store(c, "realtotal",         9, newSVuv(inf->t_rm), 0);
            hv_store(c, "realactive",       10, newSVuv(inf->t_arm), 0);
            hv_store(c, "vmshared",          8, newSVuv(inf->t_vmshr), 0);
            hv_store(c, "vmsharedactive",   14, newSVuv(inf->t_avmshr), 0);
            hv_store(c, "realshared",       10, newSVuv(inf->t_rmshr), 0);
            hv_store(c, "realsharedactive", 16, newSVuv(inf->t_armshr), 0);
            hv_store(c, "pagefree",          8, newSViv(inf->t_free), 0);
            break;
        }
        case FMT_LOADAVG: {
            AV *c = (AV *)sv_2mortal((SV *)newAV());
            struct loadavg *inf = (struct loadavg *)buf;
            double scale = inf->fscale;
            RETVAL = newRV((SV *)c);
            av_extend(c, 3);
            av_store(c, 0, newSVnv((double)inf->ldavg[0]/scale));
            av_store(c, 1, newSVnv((double)inf->ldavg[1]/scale));
            av_store(c, 2, newSVnv((double)inf->ldavg[2]/scale));
            break;
        }
        case FMT_TIMEVAL: {
            struct timeval *inf = (struct timeval *)buf;
            RETVAL = newSVnv(
                (double)inf->tv_sec + ((double)inf->tv_usec/1000000)
            );
            break;
        }
        /* the remaining custom formats are for opaque mibs */
#if __FreeBSD_version < 1000000
        case FMT_MBSTAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct mbstat *inf = (struct mbstat *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "copymfail",      9, newSVuv(inf->m_mcfail), 0);
            hv_store(c, "pullupfail",    10, newSVuv(inf->m_mpfail), 0);
            hv_store(c, "mbufsize",       8, newSVuv(inf->m_msize), 0);
            hv_store(c, "mclustsize",    10, newSVuv(inf->m_mclbytes), 0);
            hv_store(c, "minclsize",      9, newSVuv(inf->m_minclsize), 0);
            hv_store(c, "mbuflen",        7, newSVuv(inf->m_mlen), 0);
            hv_store(c, "mbufhead",       8, newSVuv(inf->m_mhlen), 0);
            hv_store(c, "drain",          5, newSVuv(inf->m_drain), 0);
#if __FreeBSD_version < 500000
            hv_store(c, "numtypes",       8, newSVpvn("", 0), 0);
#else
            hv_store(c, "numtypes",       8, newSViv(inf->m_numtypes), 0);
#endif
#if __FreeBSD_version < 600000
            hv_store(c, "mbufs",          5, newSVpvn("", 0), 0);
            hv_store(c, "mclusts",        7, newSVpvn("", 0), 0);
            hv_store(c, "sfallocwait",   11, newSVpvn("", 0), 0);
            hv_store(c, "sfiocnt",        7, newSVpvn("", 0), 0);
#else
            hv_store(c, "mbufs",          5, newSVuv(inf->m_mbufs), 0);
            hv_store(c, "mclusts",        7, newSVuv(inf->m_mclusts), 0);
            hv_store(c, "sfallocwait",   11, newSVuv(inf->sf_allocwait), 0);
            hv_store(c, "sfiocnt",        7, newSVuv(inf->sf_iocnt), 0);
#endif
            break;
        }
#endif
        case FMT_NTPTIMEVAL: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct ntptimeval *inf = (struct ntptimeval *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "sec",        3, newSVuv(inf->time.tv_sec), 0);
            hv_store(c, "nanosec",    7, newSViv(inf->time.tv_nsec), 0);
            hv_store(c, "maxerror",   8, newSViv(inf->maxerror), 0);
            hv_store(c, "esterror",   8, newSViv(inf->esterror), 0);
            hv_store(c, "taioffset",  9, newSViv(inf->tai), 0);
            hv_store(c, "timestate",  9, newSViv(inf->time_state), 0);
            break;
        }
        case FMT_DEVSTAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct devstat *inf = (struct devstat *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "devno",           5, newSViv(inf->device_number), 0);
            hv_store(c, "unitno",          6, newSViv(inf->unit_number), 0);
#if __FreeBSD_version < 500000
            hv_store(c, "sequence",        8, newSVpvn("", 0), 0);
            hv_store(c, "allocated",       9, newSVpvn("", 0), 0);
            hv_store(c, "startcount",     10, newSVpvn("", 0), 0);
            hv_store(c, "endcount",        8, newSVpvn("", 0), 0);
            hv_store(c, "busyfromsec",    11, newSVpvn("", 0), 0);
            hv_store(c, "busyfromfrac",   12, newSVpvn("", 0), 0);
#else
            hv_store(c, "sequence",        8, newSVuv(inf->sequence0), 0);
            hv_store(c, "allocated",       9, newSViv(inf->allocated), 0);
            hv_store(c, "startcount",     10, newSViv(inf->start_count), 0);
            hv_store(c, "endcount",        8, newSViv(inf->end_count), 0);
            hv_store(c, "busyfromsec",    11, newSViv(inf->busy_from.sec), 0);
            hv_store(c, "busyfromfrac",   12, newSVuv(inf->busy_from.frac), 0);
#endif
            break;
        }
#if __FreeBSD_version >= 500000
        case FMT_XVFSCONF: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct xvfsconf *inf = (struct xvfsconf *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "name",         4, newSVpv(inf->vfc_name, 0), 0);
            hv_store(c, "typenum",      7, newSViv(inf->vfc_typenum), 0);
            hv_store(c, "refcount",     8, newSViv(inf->vfc_refcount), 0);
            hv_store(c, "flags",        5, newSViv(inf->vfc_flags), 0);
            break;
        }
#endif
        case FMT_ICMPSTAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct icmpstat *inf = (struct icmpstat *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "error",         5, newSViv(inf->icps_error), 0);
            hv_store(c, "badcode",       7, newSViv(inf->icps_badcode), 0);
            hv_store(c, "tooshort",      8, newSViv(inf->icps_tooshort), 0);
            hv_store(c, "checksum",      8, newSViv(inf->icps_checksum), 0);
            hv_store(c, "badlen",        6, newSViv(inf->icps_badlen), 0);
            hv_store(c, "reflect",       7, newSViv(inf->icps_reflect), 0);
            hv_store(c, "bmcastecho",   10, newSViv(inf->icps_bmcastecho), 0);
            hv_store(c, "bmcasttstamp", 12, newSViv(inf->icps_bmcasttstamp), 0);
            hv_store(c, "badaddr",       7, newSViv(inf->icps_badaddr), 0);
            hv_store(c, "noroute",       7, newSViv(inf->icps_noroute), 0);
            break;
        }
        case FMT_IGMPSTAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct igmpstat *inf = (struct igmpstat *)buf;
            RETVAL = newRV((SV *)c);
#if __FreeBSD_version < 800070
            hv_store(c, "total",       5, newSVuv(inf->igps_rcv_total), 0);
            hv_store(c, "tooshort",    8, newSVuv(inf->igps_rcv_tooshort), 0);
            hv_store(c, "badsum",      6, newSVuv(inf->igps_rcv_badsum), 0);
            hv_store(c, "queries",     7, newSVuv(inf->igps_rcv_queries), 0);
            hv_store(c, "badqueries", 10, newSVuv(inf->igps_rcv_badqueries), 0);
            hv_store(c, "reports",     7, newSVuv(inf->igps_rcv_reports), 0);
            hv_store(c, "badreports", 10, newSVuv(inf->igps_rcv_badreports), 0);
            hv_store(c, "ourreports", 10, newSVuv(inf->igps_rcv_ourreports), 0);
            hv_store(c, "sent",        4, newSVuv(inf->igps_snd_reports), 0);
#else
            /* Message statistics */
            hv_store(c, "total",             5, newSVuv(inf->igps_rcv_total), 0);
            hv_store(c, "tooshort",          8, newSVuv(inf->igps_rcv_tooshort), 0);
            hv_store(c, "badttl",            6, newSVuv(inf->igps_rcv_badttl), 0);
            hv_store(c, "badsum",            6, newSVuv(inf->igps_rcv_badsum), 0);
            /* Query statistics */
            hv_store(c, "queries",           7, newSVuv(inf->igps_rcv_v1v2_queries + inf->igps_rcv_v3_queries), 0);
            hv_store(c, "v1v2_queries",     12, newSVuv(inf->igps_rcv_v1v2_queries), 0);
            hv_store(c, "v3_queries",       10, newSVuv(inf->igps_rcv_v3_queries), 0);
            hv_store(c, "badqueries",       10, newSVuv(inf->igps_rcv_badqueries), 0);
            hv_store(c, "gen_queries",      11, newSVuv(inf->igps_rcv_gen_queries), 0);
            hv_store(c, "group_queries",    13, newSVuv(inf->igps_rcv_group_queries), 0);
            hv_store(c, "gsr_queries",      11, newSVuv(inf->igps_rcv_gsr_queries), 0);
            hv_store(c, "drop_gsr_queries", 16, newSVuv(inf->igps_drop_gsr_queries), 0);
            /* Report statistics */
            hv_store(c, "reports",           7, newSVuv(inf->igps_rcv_reports), 0);
            hv_store(c, "badreports",       10, newSVuv(inf->igps_rcv_badreports), 0);
            hv_store(c, "ourreports",       10, newSVuv(inf->igps_rcv_ourreports), 0);
            hv_store(c, "nore",              4, newSVuv(inf->igps_rcv_nora), 0);
            hv_store(c, "sent",              4, newSVuv(inf->igps_snd_reports), 0);
#endif
            break;
        }
        case FMT_TCPSTAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct tcpstat *inf = (struct tcpstat *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "connattempt",      11, newSVuv(inf->tcps_connattempt), 0);
            hv_store(c, "accepts",           7, newSVuv(inf->tcps_accepts), 0);
            hv_store(c, "connects",          8, newSVuv(inf->tcps_connects), 0);
            hv_store(c, "drops",             5, newSVuv(inf->tcps_drops), 0);
            hv_store(c, "conndrops",         9, newSVuv(inf->tcps_conndrops), 0);
            hv_store(c, "closed",            6, newSVuv(inf->tcps_closed), 0);
            hv_store(c, "segstimed",         9, newSVuv(inf->tcps_segstimed), 0);
            hv_store(c, "rttupdated",       10, newSVuv(inf->tcps_rttupdated), 0);
            hv_store(c, "delack",            6, newSVuv(inf->tcps_delack), 0);
            hv_store(c, "timeoutdrop",      11, newSVuv(inf->tcps_timeoutdrop), 0);
            hv_store(c, "rexmttimeo",       10, newSVuv(inf->tcps_rexmttimeo), 0);
            hv_store(c, "persisttimeo",     12, newSVuv(inf->tcps_persisttimeo), 0);
            hv_store(c, "keeptimeo",         9, newSVuv(inf->tcps_keeptimeo), 0);
            hv_store(c, "keepprobe",         9, newSVuv(inf->tcps_keepprobe), 0);
            hv_store(c, "keepdrops",         9, newSVuv(inf->tcps_keepdrops), 0);
            hv_store(c, "sendtotal",         9, newSVuv(inf->tcps_sndtotal), 0);
            hv_store(c, "sendpack",          8, newSVuv(inf->tcps_sndpack), 0);
            hv_store(c, "sendbyte",          8, newSVuv(inf->tcps_sndbyte), 0);
            hv_store(c, "sendrexmitpack",   14, newSVuv(inf->tcps_sndrexmitpack), 0);
            hv_store(c, "sendrexmitbyte",   14, newSVuv(inf->tcps_sndrexmitbyte), 0);
            hv_store(c, "sendacks",          8, newSVuv(inf->tcps_sndacks), 0);
            hv_store(c, "sendprobe",         9, newSVuv(inf->tcps_sndprobe), 0);
            hv_store(c, "sendurgent",       10, newSVuv(inf->tcps_sndurg), 0);
            hv_store(c, "sendwinup",         9, newSVuv(inf->tcps_sndwinup), 0);
            hv_store(c, "sendctrl",          8, newSVuv(inf->tcps_sndctrl), 0);
            hv_store(c, "recvtotal",         9, newSVuv(inf->tcps_rcvtotal), 0);
            hv_store(c, "recvpack",          8, newSVuv(inf->tcps_rcvpack), 0);
            hv_store(c, "recvbyte",          8, newSVuv(inf->tcps_rcvbyte), 0);
            hv_store(c, "recvbadsum",       10, newSVuv(inf->tcps_rcvbadsum), 0);
            hv_store(c, "recvbadoff",       10, newSVuv(inf->tcps_rcvbadoff), 0);
            hv_store(c, "recvmemdrop",      11, newSVuv(inf->tcps_rcvmemdrop), 0);
            hv_store(c, "recvshort",         9, newSVuv(inf->tcps_rcvshort), 0);
            hv_store(c, "recvduppack",      11, newSVuv(inf->tcps_rcvduppack), 0);
            hv_store(c, "recvdupbyte",      11, newSVuv(inf->tcps_rcvdupbyte), 0);
            hv_store(c, "recvpartduppack",  15, newSVuv(inf->tcps_rcvduppack), 0);
            hv_store(c, "recvpartdupbyte",  15, newSVuv(inf->tcps_rcvdupbyte), 0);
            hv_store(c, "recvoopack",       10, newSVuv(inf->tcps_rcvoopack), 0);
            hv_store(c, "recvoobyte",       10, newSVuv(inf->tcps_rcvoobyte), 0);
            hv_store(c, "recvpackafterwin", 16, newSVuv(inf->tcps_rcvpackafterwin), 0);
            hv_store(c, "recvbyteafterwin", 16, newSVuv(inf->tcps_rcvbyteafterwin), 0);
            hv_store(c, "recvafterclose",   14, newSVuv(inf->tcps_rcvafterclose), 0);
            hv_store(c, "recvwinprobe",     12, newSVuv(inf->tcps_rcvwinprobe), 0);
            hv_store(c, "recvdupack",       10, newSVuv(inf->tcps_rcvdupack), 0);
            hv_store(c, "recvacktoomuch",   14, newSVuv(inf->tcps_rcvacktoomuch), 0);
            hv_store(c, "recvackpack",      11, newSVuv(inf->tcps_rcvackpack), 0);
            hv_store(c, "recvackbyte",      11, newSVuv(inf->tcps_rcvackbyte), 0);
            hv_store(c, "recvwinupd",       10, newSVuv(inf->tcps_rcvwinupd), 0);
            hv_store(c, "pawsdrop",          8, newSVuv(inf->tcps_pawsdrop), 0);
            hv_store(c, "predack",           7, newSVuv(inf->tcps_predack), 0);
            hv_store(c, "preddat",           7, newSVuv(inf->tcps_preddat), 0);
            hv_store(c, "pcbcachemiss",     12, newSVuv(inf->tcps_pcbcachemiss), 0);
            hv_store(c, "cachedrtt",         9, newSVuv(inf->tcps_cachedrtt), 0);
            hv_store(c, "cachedrttvar",     12, newSVuv(inf->tcps_cachedrttvar), 0);
            hv_store(c, "cachedssthresh",   14, newSVuv(inf->tcps_cachedssthresh), 0);
            hv_store(c, "usedrtt",           7, newSVuv(inf->tcps_usedrtt), 0);
            hv_store(c, "usedrttvar",       10, newSVuv(inf->tcps_usedrttvar), 0);
            hv_store(c, "usedssthresh",     12, newSVuv(inf->tcps_usedssthresh), 0);
            hv_store(c, "persistdrop",      11, newSVuv(inf->tcps_persistdrop), 0);
            hv_store(c, "badsyn",            6, newSVuv(inf->tcps_badsyn), 0);
            hv_store(c, "mturesent",         9, newSVuv(inf->tcps_mturesent), 0);
            hv_store(c, "listendrop",       10, newSVuv(inf->tcps_listendrop), 0);
            hv_store(c, "listendrop",       10, newSVuv(inf->tcps_listendrop), 0);
            hv_store(c, "added",             5, newSVuv(inf->tcps_sc_added), 0);
            hv_store(c, "rexmit",            6, newSVuv(inf->tcps_sc_retransmitted), 0);
            hv_store(c, "dupsyn",            6, newSVuv(inf->tcps_sc_dupsyn), 0);
            hv_store(c, "dropped",           7, newSVuv(inf->tcps_sc_dropped), 0);
            hv_store(c, "completed",         9, newSVuv(inf->tcps_sc_completed), 0);
            hv_store(c, "bucketoverflow",   14, newSVuv(inf->tcps_sc_bucketoverflow), 0);
            hv_store(c, "cacheoverflow",    13, newSVuv(inf->tcps_sc_cacheoverflow), 0);
            hv_store(c, "reset",             5, newSVuv(inf->tcps_sc_reset), 0);
            hv_store(c, "stale",             5, newSVuv(inf->tcps_sc_stale), 0);
            hv_store(c, "aborted",           7, newSVuv(inf->tcps_sc_aborted), 0);
            hv_store(c, "badack",            6, newSVuv(inf->tcps_sc_badack), 0);
            hv_store(c, "unreach",           7, newSVuv(inf->tcps_sc_unreach), 0);
            hv_store(c, "zonefail",          8, newSVuv(inf->tcps_sc_zonefail), 0);
            hv_store(c, "sendcookie",       10, newSVuv(inf->tcps_sc_sendcookie), 0);
            hv_store(c, "recvcookie",       10, newSVuv(inf->tcps_sc_recvcookie), 0);
#if __FreeBSD_version < 500000
            hv_store(c, "minmssdrops",      11, newSVpvn("", 0), 0);
            hv_store(c, "sendrexmitbad",    13, newSVpvn("", 0), 0);
            hv_store(c, "hostcacheadd",     12, newSVpvn("", 0), 0);
            hv_store(c, "hostcacheover",    13, newSVpvn("", 0), 0);
#else
            hv_store(c, "minmssdrops",      11, newSVuv(inf->tcps_minmssdrops), 0);
            hv_store(c, "sendrexmitbad",    13, newSVuv(inf->tcps_sndrexmitbad), 0);
            hv_store(c, "hostcacheadd",     12, newSVuv(inf->tcps_hc_added), 0);
            hv_store(c, "hostcacheover",    13, newSVuv(inf->tcps_hc_bucketoverflow), 0);
#endif
#if __FreeBSD_version < 600000
            hv_store(c, "badrst",            6, newSVpvn("", 0), 0);
            hv_store(c, "sackrecover",      11, newSVpvn("", 0), 0);
            hv_store(c, "sackrexmitsegs",   14, newSVpvn("", 0), 0);
            hv_store(c, "sackrexmitbytes",  15, newSVpvn("", 0), 0);
            hv_store(c, "sackrecv",          8, newSVpvn("", 0), 0);
            hv_store(c, "sacksend",          8, newSVpvn("", 0), 0);
            hv_store(c, "sackscorebover",   14, newSVpvn("", 0), 0);
#else
            hv_store(c, "badrst",            6, newSVuv(inf->tcps_badrst), 0);
            hv_store(c, "sackrecover",      11, newSVuv(inf->tcps_sack_recovery_episode), 0);
            hv_store(c, "sackrexmitsegs",   14, newSVuv(inf->tcps_sack_rexmits), 0);
            hv_store(c, "sackrexmitbytes",  15, newSVuv(inf->tcps_sack_rexmit_bytes), 0);
            hv_store(c, "sackrecv",          8, newSVuv(inf->tcps_sack_rcv_blocks), 0);
            hv_store(c, "sacksend",          8, newSVuv(inf->tcps_sack_send_blocks), 0);
            hv_store(c, "sackscorebover",   14, newSVuv(inf->tcps_sack_sboverflow), 0);
#endif
            break;
        }
        case FMT_UDPSTAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct udpstat *inf = (struct udpstat *)buf;
            RETVAL = newRV((SV *)c);
            hv_store(c, "inpackets",       9, newSVuv(inf->udps_ipackets), 0);
            hv_store(c, "headdrops",       9, newSVuv(inf->udps_hdrops), 0);
            hv_store(c, "badsum",          6, newSVuv(inf->udps_badsum), 0);
            hv_store(c, "nosum",           5, newSVuv(inf->udps_nosum), 0);
            hv_store(c, "badlen",          6, newSVuv(inf->udps_badlen), 0);
            hv_store(c, "noport",          6, newSVuv(inf->udps_noport), 0);
            hv_store(c, "noportbcast",    11, newSVuv(inf->udps_noportbcast), 0);
            hv_store(c, "pcbcachemiss",   12, newSVuv(inf->udpps_pcbcachemiss), 0);
            hv_store(c, "pcbhashmiss",    11, newSVuv(inf->udpps_pcbhashmiss), 0);
            hv_store(c, "outpackets",     10, newSVuv(inf->udps_opackets), 0);
            hv_store(c, "fastout",         7, newSVuv(inf->udps_fastout), 0);
            hv_store(c, "noportmcast",    11, newSVuv(inf->udps_noportmcast), 0);
            break;
        }
        case FMT_RIP6STAT: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct rip6stat *inf = (struct rip6stat *)buf;
            RETVAL = newRV((SV *)c);
            /* these values are of type u_quad_t */
            hv_store(c, "inpackets",       9, newSVnv(inf->rip6s_ipackets), 0);
            hv_store(c, "insum",           5, newSVnv(inf->rip6s_isum), 0);
            hv_store(c, "badsum",          6, newSVnv(inf->rip6s_badsum), 0);
            hv_store(c, "nosock",          6, newSVnv(inf->rip6s_nosock), 0);
            hv_store(c, "nosockmcast",    11, newSVnv(inf->rip6s_nosockmcast), 0);
            hv_store(c, "sockfull",        8, newSVnv(inf->rip6s_fullsock), 0);
            hv_store(c, "outpackets",     10, newSVnv(inf->rip6s_opackets), 0);
            break;
        }
#ifdef BOOTINFO_VERSION
        case FMT_BOOTINFO: {
            HV *c = (HV *)sv_2mortal((SV *)newHV());
            struct bootinfo *inf = (struct bootinfo *)buf;
            RETVAL = newRV((SV *)c);
            /* ignore the following fields for the time being:
             * bi_bios_geom
             * bi_kernelname
             * bi_nfs_diskless
             * bi_symtab
             * bi_esymtab
             */
            hv_store(c, "version",        7, newSVuv(inf->bi_version), 0);
            /* don't know if any IA64 fields are useful,
             * (as per /usr/src/sys/ia64/include/bootinfo.h)
             */
#ifdef __ia64
            hv_store(c, "biosused",       8, newSVpvn("", 0), 0);
            hv_store(c, "size",           4, newSVpvn("", 0), 0);
            hv_store(c, "msizevalid",    10, newSVpvn("", 0), 0);
            hv_store(c, "biosdev",        7, newSVpvn("", 0), 0);
            hv_store(c, "basemem",        7, newSVpvn("", 0), 0);
            hv_store(c, "extmem",         6, newSVpvn("", 0), 0);
#else
            hv_store(c, "biosused",       8, newSVuv(inf->bi_n_bios_used), 0);
            hv_store(c, "size",           4, newSVuv(inf->bi_size), 0);
            hv_store(c, "msizevalid",    10, newSVuv(inf->bi_memsizes_valid), 0);
            hv_store(c, "biosdev",        7, newSVuv(inf->bi_bios_dev), 0);
            hv_store(c, "basemem",        7, newSVuv(inf->bi_basemem), 0);
            hv_store(c, "extmem",         6, newSVuv(inf->bi_extmem), 0);
#endif
            break;
        }
#endif
        case FMT_N:
        case FMT_IPSTAT:
        case FMT_NFSRVSTATS:
        case FMT_NFSSTATS:
        case FMT_XINPCB:
        case FMT_STRUCT_CDEV:
            /* don't know how to interpret the results */
            SvREFCNT_dec(sv_buf);
            XSRETURN_IV(0);
            break;
        default:
            warn("%s: unhandled format type=%d\n", arg, oid_fmt);
            SvREFCNT_dec(sv_buf);
            XSRETURN_IV(0);
            break;
        }

        if (oid_fmt != FMT_A) {
            SvREFCNT_dec(sv_buf);
        }

    OUTPUT:
        RETVAL

SV *
_mib_set(const char *arg, const char *value)
    INIT:
        HV *cache;
        SV **oidp;
        SV *oid;
        char *oid_data;
        int oid_fmt;
        int oid_len;
        int intval;
        unsigned int uintval;
        long longval;
        unsigned long ulongval;
        void *newval = 0;
        size_t newsize = 0;
        char *endconvptr;

    CODE:
        /* see if the mib exists */
        cache = get_hv("BSD::Sysctl::MIB_CACHE", 0);

        if((oidp = hv_fetch(cache, arg, strlen(arg), 0))) {
            oid = *oidp;
        }
        else {
            /* else use the cache
            * How do you call an XS sub from C?
            */
            warn("uncached mib: %s\n", arg);
            XSRETURN_UNDEF;
        }

        oid_data = SvPVX(oid);
        oid_fmt  = (int)(*oid_data);
        oid_data += sizeof(int);

        oid_len  = (int)(*oid_data);
        oid_data += sizeof(int);
        
        switch(oid_fmt) {
        case FMT_A:
            newval  = (void *)value;
            newsize = strlen(value);
            break;

        case FMT_INT:
            intval = (int)strtol(value, &endconvptr, 0);
            if (endconvptr == value || *endconvptr != '\0') {
                warn("invalid integer: '%s'", value);
                XSRETURN_UNDEF;
            }
            newval  = &intval;
            newsize = sizeof(intval);
            break;

        case FMT_UINT:
            uintval = (unsigned int)strtoul(value, &endconvptr, 0);
            if (endconvptr == value || *endconvptr != '\0') {
                warn("invalid unsigned integer: '%s'", value);
                XSRETURN_UNDEF;
            }
            newval  = &uintval;
            newsize = sizeof(uintval);
            break;

        case FMT_LONG:
            longval = strtol(value, &endconvptr, 0);
            if (endconvptr == value || *endconvptr != '\0') {
                warn("invalid long integer: '%s'", value);
                XSRETURN_UNDEF;
            }
            newval  = &longval;
            newsize = sizeof(longval);
            break;

        case FMT_ULONG:
            ulongval = strtoul(value, &endconvptr, 0);
            if (endconvptr == value || *endconvptr != '\0') {
                warn("invalid unsigned long integer: '%s'", value);
                XSRETURN_UNDEF;
            }
            newval  = &ulongval;
            newsize = sizeof(ulongval);
            break;
        }
        
        if (sysctl((int *)oid_data, oid_len, 0, 0, newval, newsize) == -1) {
            warn("set sysctl %s failed\n", arg);
            XSRETURN_UNDEF;
        }
        RETVAL = newSViv(1);

    OUTPUT:
        RETVAL
