/* Process.xs -- part of the Perl BSD::Process distribution */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* define _FreeBSD_version where applicable */
#if __FreeBSD__ >= 2
#include <osreldate.h>
#endif

#include <kvm.h>
#include <sys/types.h>
#include <sys/sysctl.h> /* KERN_PROC_* */
#include <pwd.h> /* struct passwd */
#include <grp.h> /* struct group */

#include <sys/param.h> /* struct kinfo_proc prereq*/
#if __FreeBSD__ >= 5
#define cv bsd_cv
#endif
#include <sys/user.h>  /* struct kinfo_proc */
#if __FreeBSD__ >= 5
#undef cv
#endif

#include <fcntl.h> /* O_RDONLY */
#include <limits.h> /* _POSIX2_LINE_MAX */

#define PATH_DEV_NULL "/dev/null"

#define TIME_FRAC(t) ((double)(t).tv_sec + (double)(t).tv_usec/1000000)
#define P_FLAG(f)    ((kp->ki_flag   & f) ? 1 : 0)
#define KI_FLAG(f)   ((kp->ki_kiflag & f) ? 1 : 0)

#if __FreeBSD_version < 500000
#define NO_FREEBSD_4x(a)    (-1)
#define NO_FREEBSD_4x_pv(a) ("")
#else
#define NO_FREEBSD_4x(a)    (a)
#define NO_FREEBSD_4x_pv(a) (a)
#endif

#if __FreeBSD_version < 600000
#define NO_FREEBSD_5x(a)    (-1)
#define NO_FREEBSD_5x_pv(a) ("")
#else
#define NO_FREEBSD_5x(a)    (a)
#define NO_FREEBSD_5x_pv(a) (a)
#endif

static int proc_info_mib[4] = { -1, -1, -1, -1 };

struct kinfo_proc *_proc_request (kvm_t *kd, int request, int param, int *pnr) {
    struct kinfo_proc *kip;

    switch(request) {
    case 2:
        kip = kvm_getprocs(kd, KERN_PROC_PGRP, param, pnr);
        break;
    case 3:
        kip = kvm_getprocs(kd, KERN_PROC_SESSION, param, pnr);
        break;
    case 5:
        kip = kvm_getprocs(kd, KERN_PROC_UID, param, pnr);
        break;
    case 6:
        kip = kvm_getprocs(kd, KERN_PROC_RUID, param, pnr);
        break;
#if __FreeBSD_version >= 600000
    case 10:
        kip = kvm_getprocs(kd, KERN_PROC_RGID, param, pnr);
        break;
    case 11:
        kip = kvm_getprocs(kd, KERN_PROC_GID, param, pnr);
        break;
#endif
    case 0:
    default:
        kip = kvm_getprocs(kd, KERN_PROC_ALL, 0, pnr);
        break;
    }
    return(kip);
}

void store_uid (HV *h, const char *field, uid_t uid) {
    struct passwd *pw;
    size_t flen;
    size_t len;

    flen = strlen(field);
    if (!(pw = getpwuid(uid))) {
        /* shouldn't ever happen... */
        hv_store(h, field, flen, newSViv(uid), 0);
    }
    else {
        len = strlen(pw->pw_name);
        hv_store(h, field, flen, newSVpvn(pw->pw_name,len), 0);
    }
}

void store_gid (HV *h, const char *field, gid_t gid) {
    struct group *gr;
    size_t flen;
    size_t len;

    flen = strlen(field);
    if (!(gr = getgrgid(gid))) {
        /* shouldn't ever happen... */
        hv_store(h, field, flen, newSViv(gid), 0);
    }
    else {
        len = strlen(gr->gr_name);
        hv_store(h, field, flen, newSVpvn(gr->gr_name,len), 0);
    }
}


#if __FreeBSD_version < 500000
#define ACFLAG_FIELD  kp_proc.p_acflag
#define COMM_FIELD    kp_proc.p_comm
#define ESTCPU_FIELD  kp_proc.p_estcpu
#define FLAG_FIELD    kp_eproc.e_jobc
#define JOBC_FIELD    kp_eproc.e_flag
#define LASTCPU_FIELD kp_proc.p_lastcpu
#define LOCK_FIELD    kp_proc.p_lock
#define LOGIN_FIELD   kp_eproc.e_login
#define NICE_FIELD    kp_proc.p_nice
#define ONCPU_FIELD   kp_proc.p_oncpu
#define PCTCPU_FIELD  kp_proc.p_pctcpu
#define PGID_FIELD    kp_eproc.e_pgid
#define PID_FIELD     kp_proc.p_pid
#define PPID_FIELD    kp_eproc.e_ppid
#define RQINDEX_FIELD kp_proc.p_rqindex
#define RSSIZE_FIELD  kp_eproc.e_xrssize
#define RUNTIME_FIELD kp_proc.p_runtime
#define SLPTIME_FIELD kp_proc.p_slptime
#define SWRSS_FIELD   kp_eproc.e_xswrss
#define SWTIME_FIELD  kp_proc.p_swtime
#define TPGID_FIELD   kp_eproc.e_tpgid
#define TSIZE_FIELD   kp_eproc.e_xsize
#define WMESG_FIELD   kp_eproc.e_wmesg
#define XSTAT_FIELD   kp_proc.p_xstat
#else
#define ACFLAG_FIELD  ki_acflag
#define COMM_FIELD    ki_comm
#define ESTCPU_FIELD  ki_estcpu
#define FLAG_FIELD    ki_flag
#define JOBC_FIELD    ki_jobc
#define LASTCPU_FIELD ki_lastcpu
#define LOCK_FIELD    ki_lock
#define LOGIN_FIELD   ki_login
#define NICE_FIELD    ki_nice
#define ONCPU_FIELD   ki_oncpu
#define PCTCPU_FIELD  ki_pctcpu
#define PGID_FIELD    ki_pgid
#define PID_FIELD     ki_pid
#define PPID_FIELD    ki_ppid
#define RQINDEX_FIELD ki_rqindex
#define RSSIZE_FIELD  ki_rssize
#define RUNTIME_FIELD ki_runtime
#define SLPTIME_FIELD ki_slptime
#define SWRSS_FIELD   ki_swrss
#define SWTIME_FIELD  ki_swtime
#define TPGID_FIELD   ki_tpgid
#define TSIZE_FIELD   ki_tsize
#define WMESG_FIELD   ki_wmesg
#define XSTAT_FIELD   ki_xstat
#endif

HV *_procinfo (struct kinfo_proc *kp, int resolve) {
    HV *h;
    const char *nlistf, *memf;
    kvm_t *kd;
    char errbuf[_POSIX2_LINE_MAX];
    char **argv;
    SV *argsv;
    size_t len;
    struct group *gr;
    short g;
    AV *grlist;
#if __FreeBSD_version >= 500000
    struct rusage *rp;
#endif

    h = (HV *)sv_2mortal((SV *)newHV());

    hv_store(h, "pid",     3, newSViv(kp->PID_FIELD),     0);
    hv_store(h, "ppid",    4, newSViv(kp->PPID_FIELD),    0);
    hv_store(h, "pgid",    4, newSViv(kp->PGID_FIELD),    0);
    hv_store(h, "tpgid",   5, newSViv(kp->TPGID_FIELD),   0);
    hv_store(h, "jobc",    4, newSViv(kp->JOBC_FIELD),    0);
    hv_store(h, "tsize",   5, newSViv(kp->TSIZE_FIELD),   0);
    hv_store(h, "rssize",  6, newSViv(kp->RSSIZE_FIELD),  0);
    hv_store(h, "swrss",   5, newSViv(kp->SWRSS_FIELD),   0);
    hv_store(h, "acflag",  6, newSViv(kp->ACFLAG_FIELD),  0);
    hv_store(h, "flag",    4, newSViv(kp->FLAG_FIELD),    0);
    hv_store(h, "pctcpu",  6, newSViv(kp->PCTCPU_FIELD),  0);
    hv_store(h, "estcpu",  6, newSViv(kp->ESTCPU_FIELD),  0);
    hv_store(h, "xstat",   5, newSViv(kp->XSTAT_FIELD),   0);
    hv_store(h, "slptime", 7, newSViv(kp->SLPTIME_FIELD), 0);
    hv_store(h, "swtime",  6, newSViv(kp->SWTIME_FIELD),  0);
    hv_store(h, "runtime", 7, newSViv(kp->RUNTIME_FIELD), 0);
    hv_store(h, "lock",    4, newSViv(kp->LOCK_FIELD),    0);
    hv_store(h, "rqindex", 7, newSViv(kp->RQINDEX_FIELD), 0);
    hv_store(h, "oncpu",   5, newSViv(kp->ONCPU_FIELD),   0);
    hv_store(h, "lastcpu", 7, newSViv(kp->LASTCPU_FIELD), 0);
    hv_store(h, "nice",    4, newSViv(kp->NICE_FIELD),    0);

    hv_store(h, "wmesg",   5, newSVpv(kp->WMESG_FIELD, 0), 0);
    hv_store(h, "login",   5, newSVpv(kp->LOGIN_FIELD, 0), 0);
    hv_store(h, "comm",    4, newSVpv(kp->COMM_FIELD,  0), 0);

    hv_store(h, "sid",   3, newSViv(NO_FREEBSD_4x(kp->ki_sid)),  0);
    hv_store(h, "tsid",  4, newSViv(NO_FREEBSD_4x(kp->ki_tsid)), 0);

    if (!resolve) {
        /* numeric user and group ids */
        hv_store(h, "uid",   3, newSViv(NO_FREEBSD_4x(kp->ki_uid)), 0);
        hv_store(h, "ruid",  4, newSViv(NO_FREEBSD_4x(kp->ki_ruid)), 0);
        hv_store(h, "svuid", 5, newSViv(NO_FREEBSD_4x(kp->ki_svuid)), 0);
        hv_store(h, "rgid",  4, newSViv(NO_FREEBSD_4x(kp->ki_rgid)), 0);
        hv_store(h, "svgid", 5, newSViv(NO_FREEBSD_4x(kp->ki_svgid)), 0);
    }
    else {
        NO_FREEBSD_4x(store_uid(h, "uid",   kp->ki_uid));
        NO_FREEBSD_4x(store_uid(h, "ruid",  kp->ki_ruid));
        NO_FREEBSD_4x(store_uid(h, "svuid", kp->ki_svuid));
        NO_FREEBSD_4x(store_gid(h, "rgid",  kp->ki_rgid));
        NO_FREEBSD_4x(store_gid(h, "svgid", kp->ki_svgid));
    }

    grlist = (AV *)sv_2mortal((SV *)newAV());
#if __FreeBSD_version < 500000
    /* not available in FreeBSD 4.x */
    hv_store(h, "args",   4, newSViv(-1), 0);
#else
    /* attributes available only in FreeBSD 5.x, 6.x */
    nlistf = memf = PATH_DEV_NULL;
    kd = kvm_openfiles(nlistf, memf, NULL, O_RDONLY, errbuf);
    if (!kd) {
        warn( "kvm_openfiles failed: %s\n", errbuf );
        argv = 0;
    }
    else {
        argv = kvm_getargv(kd, kp, 0);
    }

    if( argv && *argv ) {
        len = strlen(*argv);

        argsv = newSVpvn(*argv, len);
        while (*++argv) {
            sv_catpvn(argsv, " ", 1);
            sv_catpvn(argsv, *argv, strlen(*argv));
        }
    }
    else {
        /* sometimes the process args may be unavailable; when this happens the name
         * of the executable in brackets is returned, similar to the ps program.
         */
        argsv = newSVpvn("[", 1);
        sv_catpvn(argsv, kp->COMM_FIELD, strlen(kp->COMM_FIELD));
        sv_catpvn(argsv, "]", 1);
    }

    hv_store(h, "args", 4, argsv, 0);

    if (kd) {
        kvm_close(kd);
    }

    /* deal with groups array */
    for (g = 0; g < kp->ki_ngroups; ++g) {
        if (resolve && (gr = getgrgid(kp->ki_groups[g]))) {
            av_push(grlist, newSVpvn(gr->gr_name, strlen(gr->gr_name)));
        }
        else {
            av_push(grlist, newSViv(kp->ki_groups[g]));
        }
    }
#endif
    hv_store(h, "groups", 6, newRV((SV *)grlist), 0);

    hv_store(h, "ngroups",   7, newSViv(NO_FREEBSD_4x(kp->ki_ngroups)), 0);
    hv_store(h, "size",      4, newSViv(NO_FREEBSD_4x(kp->ki_size)), 0);
    hv_store(h, "dsize",     5, newSViv(NO_FREEBSD_4x(kp->ki_dsize)), 0);
    hv_store(h, "ssize",     5, newSViv(NO_FREEBSD_4x(kp->ki_ssize)), 0);
    hv_store(h, "start",     5, newSVnv(NO_FREEBSD_4x(TIME_FRAC(kp->ki_start))), 0);
    hv_store(h, "childtime", 9, newSVnv(NO_FREEBSD_4x(TIME_FRAC(kp->ki_childtime))), 0);

    hv_store(h, "advlock",      7, newSViv(NO_FREEBSD_4x(P_FLAG(P_ADVLOCK))), 0);
    hv_store(h, "controlt",     8, newSViv(NO_FREEBSD_4x(P_FLAG(P_CONTROLT))), 0);
    hv_store(h, "kthread",      7, newSViv(NO_FREEBSD_4x(P_FLAG(P_KTHREAD))), 0);
#if __FreeBSD_version < 802501
    hv_store(h, "noload",       6, newSViv(NO_FREEBSD_4x(P_FLAG(P_NOLOAD))), 0);
#endif
    hv_store(h, "ppwait",       6, newSViv(NO_FREEBSD_4x(P_FLAG(P_PPWAIT))), 0);
    hv_store(h, "profil",       6, newSViv(NO_FREEBSD_4x(P_FLAG(P_PROFIL))), 0);
    hv_store(h, "stopprof",     8, newSViv(NO_FREEBSD_4x(P_FLAG(P_STOPPROF))), 0);
    hv_store(h, "sugid",        5, newSViv(NO_FREEBSD_4x(P_FLAG(P_SUGID))), 0);
    hv_store(h, "system",       6, newSViv(NO_FREEBSD_4x(P_FLAG(P_SYSTEM))), 0);
    hv_store(h, "single_exit", 11, newSViv(NO_FREEBSD_4x(P_FLAG(P_SINGLE_EXIT))), 0);
    hv_store(h, "traced",       6, newSViv(NO_FREEBSD_4x(P_FLAG(P_TRACED))), 0);
    hv_store(h, "waited",       6, newSViv(NO_FREEBSD_4x(P_FLAG(P_WAITED))), 0);
    hv_store(h, "wexit",        5, newSViv(NO_FREEBSD_4x(P_FLAG(P_WEXIT))), 0);
    hv_store(h, "exec",         4, newSViv(NO_FREEBSD_4x(P_FLAG(P_EXEC))), 0);
    hv_store(h, "hadthreads",  10, newSViv(NO_FREEBSD_5x(P_FLAG(P_HADTHREADS))), 0);

    hv_store(h, "kiflag",    6, newSViv(NO_FREEBSD_4x(kp->ki_kiflag)), 0);
    hv_store(h, "locked",    6, newSViv(NO_FREEBSD_4x(KI_FLAG(KI_LOCKBLOCK))), 0);
    hv_store(h, "isctty",    6, newSViv(NO_FREEBSD_4x(KI_FLAG(KI_CTTY))), 0);
    hv_store(h, "issleader", 9, newSViv(NO_FREEBSD_4x(KI_FLAG(KI_SLEADER))), 0);

    hv_store(h, "stat",        4, newSViv(NO_FREEBSD_4x((int)kp->ki_stat)), 0);
    hv_store(h, "stat_1",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 1 ? 1 : 0)), 0);
    hv_store(h, "stat_2",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 2 ? 1 : 0)), 0);
    hv_store(h, "stat_3",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 3 ? 1 : 0)), 0);
    hv_store(h, "stat_4",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 4 ? 1 : 0)), 0);
    hv_store(h, "stat_5",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 5 ? 1 : 0)), 0);
    hv_store(h, "stat_6",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 6 ? 1 : 0)), 0);
    hv_store(h, "stat_7",      6, newSViv(NO_FREEBSD_4x((int)kp->ki_stat == 7 ? 1 : 0)), 0);
    hv_store(h, "ocomm",       5, newSVpv(NO_FREEBSD_4x_pv(kp->ki_ocomm), 0), 0);
    hv_store(h, "lockname",    8, newSVpv(NO_FREEBSD_4x_pv(kp->ki_lockname), 0), 0);

    hv_store(h, "pri_class",   9, newSViv(NO_FREEBSD_4x(kp->ki_pri.pri_class)), 0);
    hv_store(h, "pri_level",   9, newSViv(NO_FREEBSD_4x(kp->ki_pri.pri_level)), 0);
    hv_store(h, "pri_native", 10, newSViv(NO_FREEBSD_4x(kp->ki_pri.pri_native)), 0);
    hv_store(h, "pri_user",    8, newSViv(NO_FREEBSD_4x(kp->ki_pri.pri_user)), 0);

    NO_FREEBSD_4x(rp = &kp->ki_rusage);
    hv_store(h, "utime",    5, newSVnv(NO_FREEBSD_4x(TIME_FRAC(rp->ru_utime))), 0);
    hv_store(h, "stime",    5, newSVnv(NO_FREEBSD_4x(TIME_FRAC(rp->ru_stime))), 0);
    hv_store(h, "time",     4, newSVnv(NO_FREEBSD_4x(
        TIME_FRAC(rp->ru_utime)+TIME_FRAC(rp->ru_stime))), 0);
    hv_store(h, "maxrss",   6, newSVnv(NO_FREEBSD_4x(rp->ru_maxrss)), 0);
    hv_store(h, "ixrss",    5, newSVnv(NO_FREEBSD_4x(rp->ru_ixrss)), 0);
    hv_store(h, "idrss",    5, newSVnv(NO_FREEBSD_4x(rp->ru_idrss)), 0);
    hv_store(h, "isrss",    5, newSVnv(NO_FREEBSD_4x(rp->ru_isrss)), 0);
    hv_store(h, "minflt",   6, newSVnv(NO_FREEBSD_4x(rp->ru_minflt)), 0);
    hv_store(h, "majflt",   6, newSVnv(NO_FREEBSD_4x(rp->ru_majflt)), 0);
    hv_store(h, "nswap",    5, newSVnv(NO_FREEBSD_4x(rp->ru_nswap)), 0);
    hv_store(h, "inblock",  7, newSVnv(NO_FREEBSD_4x(rp->ru_inblock)), 0);
    hv_store(h, "oublock",  7, newSVnv(NO_FREEBSD_4x(rp->ru_oublock)), 0);
    hv_store(h, "msgsnd",   6, newSVnv(NO_FREEBSD_4x(rp->ru_msgsnd)), 0);
    hv_store(h, "msgrcv",   6, newSVnv(NO_FREEBSD_4x(rp->ru_msgrcv)), 0);
    hv_store(h, "nsignals", 8, newSViv(NO_FREEBSD_4x(rp->ru_nsignals)), 0);
    hv_store(h, "nvcsw",    5, newSViv(NO_FREEBSD_4x(rp->ru_nvcsw)), 0);
    hv_store(h, "nivcsw",   6, newSViv(NO_FREEBSD_4x(rp->ru_nivcsw)), 0);

    /* attributes available only in FreeBSD 6.x */
    hv_store(h, "emul",        4, newSVpv(NO_FREEBSD_5x_pv(kp->ki_emul), 0), 0);
    hv_store(h, "jid",         3, newSViv(NO_FREEBSD_5x(kp->ki_jid)), 0);
    hv_store(h, "numthreads", 10, newSViv(NO_FREEBSD_5x(kp->ki_numthreads)), 0);

    NO_FREEBSD_5x(rp = &kp->ki_rusage_ch);
    hv_store(h, "utime_ch",     8, newSVnv(NO_FREEBSD_5x(TIME_FRAC(rp->ru_utime))), 0);
    hv_store(h, "stime_ch",     8, newSVnv(NO_FREEBSD_5x(TIME_FRAC(rp->ru_stime))), 0);
    hv_store(h, "time_ch",      7, newSVnv(NO_FREEBSD_5x(
        TIME_FRAC(rp->ru_utime)+TIME_FRAC(rp->ru_stime))), 0);
    hv_store(h, "maxrss_ch",    9, newSVnv(NO_FREEBSD_5x(rp->ru_maxrss)), 0);
    hv_store(h, "ixrss_ch",     8, newSVnv(NO_FREEBSD_5x(rp->ru_ixrss)), 0);
    hv_store(h, "idrss_ch",     8, newSVnv(NO_FREEBSD_5x(rp->ru_idrss)), 0);
    hv_store(h, "isrss_ch",     8, newSVnv(NO_FREEBSD_5x(rp->ru_isrss)), 0);
    hv_store(h, "minflt_ch",    9, newSVnv(NO_FREEBSD_5x(rp->ru_minflt)), 0);
    hv_store(h, "majflt_ch",    9, newSVnv(NO_FREEBSD_5x(rp->ru_majflt)), 0);
    hv_store(h, "nswap_ch",     8, newSVnv(NO_FREEBSD_5x(rp->ru_nswap)), 0);
    hv_store(h, "inblock_ch",  10, newSVnv(NO_FREEBSD_5x(rp->ru_inblock)), 0);
    hv_store(h, "oublock_ch",  10, newSVnv(NO_FREEBSD_5x(rp->ru_oublock)), 0);
    hv_store(h, "msgsnd_ch",    9, newSVnv(NO_FREEBSD_5x(rp->ru_msgsnd)), 0);
    hv_store(h, "msgrcv_ch",    9, newSVnv(NO_FREEBSD_5x(rp->ru_msgrcv)), 0);
    hv_store(h, "nsignals_ch", 11, newSViv(NO_FREEBSD_5x(rp->ru_nsignals)), 0);
    hv_store(h, "nvcsw_ch",     8, newSViv(NO_FREEBSD_5x(rp->ru_nvcsw)), 0);
    hv_store(h, "nivcsw_ch",    9, newSViv(NO_FREEBSD_5x(rp->ru_nivcsw)), 0);

    return h;
}

MODULE = BSD::Process   PACKAGE = BSD::Process

PROTOTYPES: ENABLE

short
max_kernel_groups()
    CODE:
#if __FreeBSD_version < 500000
        RETVAL = 0;
#else
        RETVAL = KI_NGROUPS;
#endif
    OUTPUT:
        RETVAL

SV *
_info(int pid, int resolve)
    PREINIT:
        /* TODO: int pid should be pid_t pid */
        size_t len;
        struct kinfo_proc ki;
        HV *h;

    CODE:
        /* use the sysctl approach instead of using a kernel
         * descriptor, makes for a bit less housekeeping.
         */
        if (proc_info_mib[0] == -1) {
            len = sizeof(proc_info_mib)/sizeof(proc_info_mib[0]);
            if (sysctlnametomib("kern.proc.pid", proc_info_mib, &len) == -1) {
                warn( "kern.proc.pid is corrupt\n");
                XSRETURN_UNDEF;
            }
        }
        proc_info_mib[3] = pid;
        len = sizeof(ki);
        if (sysctl(proc_info_mib, sizeof(proc_info_mib)/sizeof(proc_info_mib[0]), &ki, &len, NULL, 0) == -1) {
            /* process identified by pid has probably exited */
            XSRETURN_UNDEF;
        }
        h = _procinfo( &ki, resolve );
        RETVAL = newRV((SV *)h);

    OUTPUT:
        RETVAL

void
_list(int request, int param)
    PREINIT:
#ifdef dXSTARG
    dXSTARG;
#else
    dTARGET;
#endif
        struct kinfo_proc *kip;
        kvm_t *kd;
        int nr;
        char errbuf[_POSIX2_LINE_MAX];
        const char *nlistf, *memf;
    PPCODE:
        nlistf = memf = PATH_DEV_NULL;
        kd = kvm_openfiles(nlistf, memf, NULL, O_RDONLY, errbuf);
        kip = _proc_request(kd, request, param, &nr);
        if (kip) {
            int p;
            for (p = 0; p < nr; ++kip, ++p) {
#if PERL_API_VERSION == 5 && PERL_VERSION == 6
                EXTEND(SP,1);
                XPUSHi(kip->PID_FIELD);
#else
                mPUSHi(kip->PID_FIELD);
#endif
            }
            kvm_close(kd);
        }
        else {
            warn("kvm error in list(): %s\n", kvm_geterr(kd));
            XSRETURN_UNDEF;
        }
        XSRETURN(nr);

HV *
_all(int resolve, int request, int param)
    PREINIT:
        struct kinfo_proc *kip;
        kvm_t *kd;
        int nr;
        char errbuf[_POSIX2_LINE_MAX];
        char pidbuf[16];
        const char *nlistf, *memf;
        HV *h;
        HV *package;
        HV *out;
        int p;

    CODE:
        nlistf = memf = PATH_DEV_NULL;
        kd = kvm_openfiles(nlistf, memf, NULL, O_RDONLY, errbuf);
        kip = _proc_request(kd, request, param, &nr);

        if (!kip) {
            warn("kvm error in all(): %s\n", kvm_geterr(kd));
            XSRETURN_UNDEF;
        }

        out = (HV *)sv_2mortal((SV *)newHV());
        package = gv_stashpv("BSD::Process", 0);

        RETVAL = out;
        for (p = 0; p < nr; ++kip, ++p) {
            h = _procinfo( kip, resolve );
            hv_store(h, "_resolve", 8, newSViv(resolve), 0);
            hv_store(h, "_pid",     4, newSViv(kip->PID_FIELD), 0);
            sprintf( pidbuf, "%d", kip->PID_FIELD);
            hv_store(out, pidbuf, strlen(pidbuf),
                sv_bless(newRV((SV *)h), package), 0);
        }
        kvm_close(kd);

    OUTPUT:
        RETVAL
