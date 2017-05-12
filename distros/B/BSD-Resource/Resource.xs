/*
 * Copyright (c) 1995-2017 Jarkko Hietaniemi. All rights reserved.
 * For license see COPYRIGHT and LICENSE in Resource.pm.
 *
 * Resource.xs
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef WIN32
# include <time.h>
#else
# include <sys/time.h>
#endif
#ifdef HAS_SELECT
# ifdef I_SYS_SELECT
#  include <sys/select.h>
# endif
#endif
#ifdef __cplusplus
}
#endif

#if defined(__hpux) && !defined(_INCLUDE_XOPEN_SOURCE_EXTENDED)
#define _INCLUDE_XOPEN_SOURCE_EXTENDED
#endif

/* If this fails your vendor has failed you and Perl cannot help. */
#include <sys/resource.h>

#if defined(__sun__) && defined(__svr4__) && !defined(SOLARIS_NO_PROCFS)
#   define SOLARIS
#   define SOLARIS_PROCFS
#   ifdef I_SYS_RUSAGE
#       include <sys/rusage.h>
/* Some old Solarises have no RUSAGE_* defined in <sys/resource.h>.
 * There is <sys/rusage.h> which has but this file is very non-standard.
 * More the fun, the file itself warns will not be there for long. */
#       define part_of_sec tv_nsec
#   endif
/* Solaris uses timerstruc_t in struct rusage. According to the <sys/time.h>
 * in old Solarises tv_nsec in the timerstruc_t is nanoseconds (and the name
 * also supports that theory) BUT getrusage() seems after all to tick
 * microseconds, not nano. */
#   define part_in_sec 0.000001
#
/* Newer Solarises (5.5 onwards) have much better support for rusage-kinda
 * things via the proc interface. */
#   define _STRUCTURED_PROC 1
#   include <sys/procfs.h>
#   include <fcntl.h>

#   ifdef PIOCUSAGE
#       undef SOLARIS_STRUCTURED_PROC
#   else
#       define SOLARIS_STRUCTURED_PROC
#   endif

#   ifdef SOLARIS_STRUCTURED_PROC
#       define Struct_psinfo  struct psinfo
#       define Struct_pstatus struct pstatus
#   else
#       define Struct_psinfo  struct prpsinfo
#       define Struct_pstatus struct prstatus
#   endif
#endif

#ifdef SOLARIS_NO_PROCFS
#   define SOLARIS
#   undef SOLARIS_PROCFS
#   define TRY_GETRUSAGE_SYS_SYSCALL
#endif

#ifndef part_of_sec
#define part_of_sec tv_usec
#define part_in_sec 0.000001
#endif

#define IDM ((double)part_in_sec)
#define TV2DS(tv) ((double)tv.tv_sec+(double)tv.part_of_sec*part_in_sec)

#ifndef HAS_GETRUSAGE
#  if defined(RUSAGE_SELF) || defined(SOLARIS)
#     define HAS_GETRUSAGE
#  endif
#endif

#if defined(OS2) && !defined(PRIO_PROCESS)
#   define PRIO_PROCESS 0	/* This argument is ignored anyway. */
#endif

#if defined(__hpux) && defined(RLIMIT_NLIMITS)
/* there is getrusage() in HPUX but only as an indirect syscall */
#   define TRY_GETRUSAGE_AS_SYSCALL
/* some rlimits exist (but are officially unsupported by HP) */
#   ifndef RLIMIT_CPU
#     define RLIMIT_CPU      0
#   endif
#   ifndef RLIMIT_FSIZE
#     define RLIMIT_FSIZE    1
#   endif
#   ifndef RLIMIT_DATA
#     define RLIMIT_DATA     2
#   endif
#   ifndef RLIMIT_STACK
#     define RLIMIT_STACK    3
#   endif
#   ifndef RLIMIT_CORE
#     define RLIMIT_CORE     4
#   endif
#   ifndef RLIMIT_RSS
#     define RLIMIT_RSS      5
#   endif
#   ifndef RLIMIT_NOFILE
#     define RLIMIT_NOFILE   6
#   endif
#   ifndef RLIMIT_OPEN_MAX
#     define RLIMIT_OPEN_MAX RLIMIT_NOFILE
#   endif
#   ifndef RLIM_NLIMITS
#     define RLIM_NLIMITS    7
#   endif
#   ifndef RLIM_INFINITY
#     define RLIM_INFINITY   0x7fffffff
#   endif
#endif

#ifdef __linux__
    /* enums without #defines, how wonderful */
#   ifndef PRIO_PROCESS
#       define PRIO_PROCESS PRIO_PROCESS
#   endif
#   ifndef PRIO_PGRP
#       define PRIO_PGRP PRIO_PGRP
#   endif
#   ifndef PRIO_USER
#       define PRIO_USER PRIO_USER
#   endif
#endif

#if !defined(RLIMIT_OPEN_MAX) && defined(RLIMIT_NOFILE)
#   define RLIMIT_OPEN_MAX RLIMIT_NOFILE
#endif

#if !defined(RLIMIT_NOFILE) && defined(RLIMIT_OPEN_MAX)
#   define RLIMIT_NOFILE RLIMIT_OPEN_MAX
#endif

#if !defined(RLIMIT_OFILE) && defined(RLIMIT_NOFILE)
#   define RLIMIT_OFILE RLIMIT_NOFILE
#endif

#if !defined(RLIMIT_VMEM) && defined(RLIMIT_AS)
#   define RLIMIT_VMEM RLIMIT_AS
#else
#   if !defined(RLIMIT_AS) && defined(RLIMIT_VMEM)
#       define RLIMIT_AS RLIMIT_VMEM
#   endif
#endif

#ifdef TRY_GETRUSAGE_AS_SYSCALL
#   include <sys/syscall.h>
#   if defined(SYS_GETRUSAGE)
#       define getrusage(a, b)	syscall(SYS_GETRUSAGE, (a), (b))
#	define HAS_GETRUSAGE
#   endif
#endif

#ifndef Rlim_t
#   ifdef Quad_t
#       define Rlim_t Quad_t
#   else
#       define Rlim_t unsigned long
#   endif
#endif

#if defined(RLIM_INFINITY)	/* this is the only one we can count on (?) */
#define HAS_GETRLIMIT
#define HAS_SETRLIMIT
#endif

#ifndef PRIO_MAX
#   define PRIO_MAX  20
#endif

#ifndef PRIO_MIN
#   define PRIO_MIN -20
#endif

#if defined(PRIO_USER)
#ifndef HAS_GETPRIORITY
#define HAS_GETPRIORITY
#endif
#ifndef HAS_SETPRIORITY
#define HAS_SETPRIORITY
#endif
#endif

#ifndef HAS_GETPRIORITY
#define _getpriority(a,b)   not_here("getpriority")
#endif

#ifndef HAS_GETRLIMIT
#define _getrlimit(a)       not_here("getrlimit")
#endif

#ifndef HAS_GETRUSAGE
#define _getrusage(a)       not_here("getrusage")
#endif

#ifndef HAS_SETPRIORITY
#define _setpriority(a,b,c) not_here("setpriority")
#endif

#ifndef HAS_SETRLIMIT
#define _setrlimit(a,b,c)   not_here("setrlimit")
#endif

static int
not_here(s)
char *s;
{
    croak("BSD::Resource::%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'E':
	if (strEQ(name, "EINVAL"))
#ifdef EINVAL
	  return EINVAL;
#else
	  goto not_there;
#endif
	if (strEQ(name, "ENOENT"))
#ifdef ENOENT
	  return ENOENT;
#else
	  goto not_there;
#endif
      break;
    case 'P':
	if (strnEQ(name, "PRIO_", 5)) {
	    if (strEQ(name, "PRIO_CONTRACT"))
#if defined(PRIO_CONTRACT) || defined(HAS_PRIO_CONTRACT)
		return PRIO_CONTRACT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_LWP"))
#if defined(PRIO_LWP) || defined(HAS_PRIO_LWP)
		return PRIO_LWP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_MIN"))
#if defined(PRIO_MIN) || defined(HAS_PRIO_MIN)
		return PRIO_MIN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_MAX"))
#if defined(PRIO_MAX) || defined(HAS_PRIO_MAX)
		return PRIO_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_PGRP"))
#if defined(PRIO_PGRP) || defined(HAS_PRIO_PGRP)
		return PRIO_PGRP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_PROCESS"))
#if defined(PRIO_PROCESS) || defined(HAS_PRIO_PROCESS)
		return PRIO_PROCESS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_PROJECT"))
#if defined(PRIO_PROJECT) || defined(HAS_PRIO_PROJECT)
		return PRIO_PROJECT;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_SESSION"))
#if defined(PRIO_SESSION) || defined(HAS_PRIO_SESSION)
		return PRIO_SESSION;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_USER"))
#if defined(PRIO_USER) || defined(HAS_PRIO_USER)
		return PRIO_USER;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_USER"))
#if defined(PRIO_USER) || defined(HAS_PRIO_USER)
		return PRIO_USER;
#else
		goto not_there;
#endif
	    if (strEQ(name, "PRIO_ZONE"))
#if defined(PRIO_ZONE) || defined(HAS_PRIO_ZONE)
		return PRIO_ZONE;
#else
		goto not_there;
#endif
	}
    goto not_there;
    case 'R':
	if (strnEQ(name, "RLIM", 4)) {
	    if (strEQ(name, "RLIMIT_AIO_MEM"))
#if defined(RLIMIT_AIO_MEM) || defined(HAS_RLIMIT_AIO_MEM)
		return RLIMIT_AIO_MEM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_AIO_OPS"))
#if defined(RLIMIT_AIO_OPS) || defined(HAS_RLIMIT_AIO_OPS)
		return RLIMIT_AIO_OPS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_AS"))
#if defined(RLIMIT_AS) || defined(HAS_RLIMIT_AS)
		return RLIMIT_AS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_CORE"))
#if defined(RLIMIT_CORE) || defined(HAS_RLIMIT_CORE)
		return RLIMIT_CORE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_CPU"))
#if defined(RLIMIT_CPU) || defined(HAS_RLIMIT_CPU)
		return RLIMIT_CPU;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_DATA"))
#if defined(RLIMIT_DATA) || defined(HAS_RLIMIT_DATA)
		return RLIMIT_DATA;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_FREEMEM"))
#if defined(RLIMIT_FREEMEM) || defined(HAS_RLIMIT_FREEMEM)
		return RLIMIT_FREEMEM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_FSIZE"))
#if defined(RLIMIT_FSIZE) || defined(HAS_RLIMIT_FSIZE)
		return RLIMIT_FSIZE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_LOCKS"))
#if defined(RLIMIT_LOCKS) || defined(HAS_RLIMIT_LOCKS)
		return RLIMIT_LOCKS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_MEMLOCK"))
#if defined(RLIMIT_MEMLOCK) || defined(HAS_RLIMIT_MEMLOCK)
		return RLIMIT_MEMLOCK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_MSGQUEUE"))
#if defined(RLIMIT_MSGQUEUE) || defined(HAS_RLIMIT_MSGQUEUE)
		return RLIMIT_MSGQUEUE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_NICE"))
#if defined(RLIMIT_NICE) || defined(HAS_RLIMIT_NICE)
		return RLIMIT_NICE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_NOFILE"))
#if defined(RLIMIT_NOFILE) || defined(HAS_RLIMIT_NOFILE)
		return RLIMIT_NOFILE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_NPROC"))
#if defined(RLIMIT_NPROC) || defined(HAS_RLIMIT_NPROC)
		return RLIMIT_NPROC;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_NPTS"))
#if defined(RLIMIT_NPTS) || defined(HAS_RLIMIT_NPTS)
		return RLIMIT_NPTS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_OFILE"))
#if defined(RLIMIT_OFILE) || defined(HAS_RLIMIT_OFILE)
		return RLIMIT_OFILE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_OPEN_MAX"))
#if defined(RLIMIT_OPEN_MAX) || defined(HAS_RLIMIT_OPEN_MAX)
		return RLIMIT_OPEN_MAX;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_POSIXLOCKS"))
#if defined(RLIMIT_POSIXLOCKS) || defined(HAS_RLIMIT_POSIXLOCKS)
		return RLIMIT_POSIXLOCKS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_PTHREAD"))
#if defined(RLIMIT_PTHREAD) || defined(HAS_RLIMIT_PTHREAD)
		return RLIMIT_PTHREAD;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_RSESTACK"))
#if defined(RLIMIT_RSESTACK) || defined(HAS_RLIMIT_RSESTACK)
		return RLIMIT_RSESTACK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_RSS"))
#if defined(RLIMIT_RSS) || defined(HAS_RLIMIT_RSS)
		return RLIMIT_RSS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_RTPRIO"))
#if defined(RLIMIT_RTPRIO) || defined(HAS_RLIMIT_RTPRIO)
		return RLIMIT_RTPRIO;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_RTTIME"))
#if defined(RLIMIT_RTTIME) || defined(HAS_RLIMIT_RTTIME)
		return RLIMIT_RTTIME;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_SBSIZE"))
#if defined(RLIMIT_SBSIZE) || defined(HAS_RLIMIT_SBSIZE)
		return RLIMIT_SBSIZE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_SIGPENDING"))
#if defined(RLIMIT_SIGPENDING) || defined(HAS_RLIMIT_SIGPENDING)
		return RLIMIT_SIGPENDING;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_STACK"))
#if defined(RLIMIT_STACK) || defined(HAS_RLIMIT_STACK)
		return RLIMIT_STACK;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_SWAP"))
#if defined(RLIMIT_SWAP) || defined(HAS_RLIMIT_SWAP)
		return RLIMIT_SWAP;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_TCACHE"))
#if defined(RLIMIT_TCACHE) || defined(HAS_RLIMIT_TCACHE)
		return RLIMIT_TCACHE;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIMIT_VMEM"))
#if defined(RLIMIT_VMEM) || defined(HAS_RLIMIT_VMEM)
		return RLIMIT_VMEM;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIM_INFINITY"))
#if defined(RLIM_INFINITY) || defined(HAS_RLIM_INFINITY)
		return -1.0;	/* trust me */
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIM_NLIMITS"))
#if defined(RLIM_NLIMITS) || defined(HAS_RLIM_NLIMITS)
		return RLIM_NLIMITS;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIM_SAVED_CUR"))
#if defined(RLIM_SAVED_CUR) || defined(HAS_RLIM_SAVED_CUR)
		return RLIM_SAVED_CUR;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RLIM_SAVED_MAX"))
#if defined(RLIM_SAVED_MAX) || defined(HAS_RLIM_SAVED_MAX)
		return RLIM_SAVED_MAX;
#else
		goto not_there;
#endif
	    break;
	 }
	if (strnEQ(name, "RUSAGE_", 7)) {
	    if (strEQ(name, "RUSAGE_BOTH"))
#if defined(RUSAGE_BOTH) || defined(HAS_RUSAGE_BOTH)
		return RUSAGE_BOTH;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RUSAGE_CHILDREN"))
#if defined(RUSAGE_CHILDREN) || defined(HAS_RUSAGE_CHILDREN)
		return RUSAGE_CHILDREN;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RUSAGE_SELF"))
#if defined(RUSAGE_SELF) || defined(HAS_RUSAGE_SELF)
		return RUSAGE_SELF;
#else
		goto not_there;
#endif
	    if (strEQ(name, "RUSAGE_THREAD"))
#if defined(RUSAGE_THREAD) || defined(HAS_RUSAGE_THREAD)
		return RUSAGE_THREAD;
#else
		goto not_there;
#endif
	    break;
	 }
    }

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

#define HV_STORE_RES(h, l) (void)hv_store(h, #l, sizeof(#l)-1, newSViv(l), 0)

MODULE = BSD::Resource		PACKAGE = BSD::Resource

PROTOTYPES: enable

double
constant(name,arg)
	char *		name
	int		arg

void
_getpriority(which = PRIO_PROCESS, who = 0)
	int		which
	int		who
    CODE:
	{
	  int		prio;

	  ST(0) = sv_newmortal();
	  errno = 0; /* getpriority() can successfully return <= 0 */
	  prio = getpriority(which, who);
	  if (errno == 0) 
	    sv_setiv(ST(0), prio);
	  else
	    ST(0) = &PL_sv_undef;
	}

void
_getrlimit(resource)
	int		resource
    PPCODE:
	struct rlimit rl;
	if (getrlimit(resource, &rl) == 0) {
	    EXTEND(sp, 2);
	    PUSHs(sv_2mortal(newSVnv((double)(rl.rlim_cur == RLIM_INFINITY ? -1.0 : rl.rlim_cur))));
	    PUSHs(sv_2mortal(newSVnv((double)(rl.rlim_max == RLIM_INFINITY ? -1.0 : rl.rlim_max))));
	}

void
_getrusage(who = RUSAGE_SELF)
	int		who
    PPCODE:
	{
	  struct rusage ru;
#ifdef SOLARIS_PROCFS
	  Struct_psinfo  psi;
	  Struct_pstatus pst;
	  struct prusage pru;
	  pid_t  pid = getpid();
	  int    res, fd;
	  char psib[40], pstb[40], prub[40];
	  ru.ru_utime.tv_sec   = 0;
	  ru.ru_utime.tv_usec  = 0;
	  ru.ru_stime.tv_sec   = 0;
	  ru.ru_stime.tv_usec  = 0;
          ru.ru_maxrss   = 0;
          ru.ru_ixrss    = 0;
	  ru.ru_idrss    = 0;
	  ru.ru_isrss    = 0;
	  ru.ru_minflt   = 0;
	  ru.ru_majflt   = 0;
	  ru.ru_nswap    = 0;
	  ru.ru_inblock  = 0;
	  ru.ru_oublock  = 0;
	  ru.ru_msgsnd   = 0;
	  ru.ru_msgrcv   = 0;
	  ru.ru_nsignals = 0;
       	  ru.ru_nvcsw    = 0;
	  ru.ru_nivcsw   = 0;
#   ifndef SOLARIS_STRUCTURED_PROC
/* The time fields come okay from getrusage() but would be bad
 * from PIOCUSAGE.  Argh. */
	  res = getrusage(who, &ru);
	  if (res)
	     goto failed;
#   endif
/* With 64-bit pids "/proc/18446744073709551616/psinfo" takes 34 bytes. */
	  sprintf(psib, "/proc/%d", pid);
	  sprintf(pstb, "/proc/%d", pid);
	  sprintf(prub, "/proc/%d", pid);
#   ifdef SOLARIS_STRUCTURED_PROC
	  res = strlen(psib);
	  sprintf(psib + res, "/psinfo");
	  sprintf(pstb + res, "/status");
	  sprintf(prub + res, "/usage" );
#   endif
	  fd = open(psib, O_RDONLY);
	  if (fd >= 0) {
#   ifdef SOLARIS_STRUCTURED_PROC
	      res = read(fd, &psi, sizeof(psi));
              if (res == sizeof(psi))
	          ru.ru_maxrss = psi.pr_rssize * 1024;
              else
                  goto failed;
#   else  
	      res = ioctl(fd, PIOCPSINFO, &psi);
	      if (res != -1)
		  ru.ru_maxrss = psi.pr_byrssize;
              else
                  goto failed;
#   endif
              close(fd);
          } else
	    goto failed;
	  fd = open(pstb, O_RDONLY);
	  if (fd >= 0) {
#   ifdef SOLARIS_STRUCTURED_PROC
	      res = read(fd, &pst, sizeof(pst));
              res = res == sizeof(pst) ? 1 : 0;
#   else  
	      res = ioctl(fd, PIOCUSAGE, &pst);
	      res = res == -1 ? 0 : 1;
#   endif
	      if (res) {
#   ifdef SOLARIS_STRUCTURED_PROC
/* Structured proc seems to have okay values in struct psinfo but
 * zero values from the earlier getrusage() so get the better ones. */
	          if (who == RUSAGE_SELF) {
		      ru.ru_utime.tv_sec   = pst.pr_utime.tv_sec;
		      ru.ru_utime.tv_usec  = pst.pr_utime.tv_nsec  / 1000;
		      ru.ru_stime.tv_sec   = pst.pr_stime.tv_sec;
		      ru.ru_stime.tv_usec  = pst.pr_stime.tv_nsec  / 1000;
	          } else if (who == RUSAGE_CHILDREN) {
		      ru.ru_utime.tv_sec   = pst.pr_cutime.tv_sec;
		      ru.ru_utime.tv_usec  = pst.pr_cutime.tv_nsec  / 1000;
		      ru.ru_stime.tv_sec   = pst.pr_cstime.tv_sec;
		      ru.ru_stime.tv_usec  = pst.pr_cstime.tv_nsec  / 1000;
                  }
#   endif
                  /* Current values, not really integrals. */
	          ru.ru_idrss = pst.pr_brksize;
	          ru.ru_isrss = pst.pr_stksize;
	      } else
	          goto failed;
              close(fd);
          } else
              goto failed;
	  fd = open(prub, O_RDONLY);
	  if (fd >= 0) {
#   ifdef SOLARIS_STRUCTURED_PROC
	      res = read(fd, &pru, sizeof(pru));
              res = res == sizeof(pru) ? 1 : 0;
#   else  
	      res = ioctl(fd, PIOCUSAGE, &pru);
	      res = res == -1 ? 0 : 1;
#   endif
	      if (res) {
		  ru.ru_minflt   = pru.pr_minf;
		  ru.ru_majflt   = pru.pr_majf;
		  ru.ru_nswap    = pru.pr_nswap;
		  ru.ru_inblock  = pru.pr_inblk;
		  ru.ru_oublock  = pru.pr_oublk;
		  ru.ru_msgsnd   = pru.pr_msnd;
		  ru.ru_msgrcv   = pru.pr_mrcv;
		  ru.ru_nsignals = pru.pr_sigs;
		  ru.ru_nvcsw    = pru.pr_vctx;
		  ru.ru_nivcsw   = pru.pr_ictx;
	      } else
	          goto failed;
              close(fd);
	  } else
	      goto failed;
#else
	  if (getrusage(who, &ru))
              goto failed;
#endif
          EXTEND(sp, 16);
          PUSHs(sv_2mortal(newSVnv(TV2DS(ru.ru_utime))));
	  PUSHs(sv_2mortal(newSVnv(TV2DS(ru.ru_stime))));
	  PUSHs(sv_2mortal(newSViv(ru.ru_maxrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_ixrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_idrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_isrss)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_minflt)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_majflt)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nswap)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_inblock)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_oublock)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_msgsnd)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_msgrcv)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nsignals)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nvcsw)));
	  PUSHs(sv_2mortal(newSVnv(ru.ru_nivcsw)));
	failed:
          ;
	}

void
_setpriority(which = PRIO_PROCESS,who = 0,priority = PRIO_MAX/2)
	int		which
	int		who
	int		priority
    CODE:
	{
	  if (items == 2) {
	    /* if two arguments they are (which, priority),
	     * not (which, who). who defaults to 0. */
	      priority = who;
	      who = 0;
	  }
	  ST(0) = sv_newmortal();
	  ST(0) = (setpriority(which, who, priority) == 0) ?
	    &PL_sv_yes : &PL_sv_undef;
	}

void
_setrlimit(resource,soft,hard)
	int	resource
	double 	soft
	double	hard
    CODE:
	{
	    struct rlimit rl;

            rl.rlim_cur = soft == -1.0 ? RLIM_INFINITY : (Rlim_t) soft;
            rl.rlim_max = hard == -1.0 ? RLIM_INFINITY : (Rlim_t) hard;

	    ST(0) = sv_newmortal();
            ST(0) = (setrlimit(resource, &rl) == 0) ? &PL_sv_yes: &PL_sv_undef;
	}

HV *
_get_rlimits()
    CODE:
	RETVAL = newHV();
	sv_2mortal((SV*)RETVAL);
#if defined(RLIMIT_AIO_MEM) || defined(HAS_RLIMIT_AIO_MEM)
	HV_STORE_RES(RETVAL, RLIMIT_AIO_MEM);
#endif
#if defined(RLIMIT_AIO_OPS) || defined(HAS_RLIMIT_AIO_OPS)
	HV_STORE_RES(RETVAL, RLIMIT_AIO_OPS);
#endif
#if defined(RLIMIT_AS) || defined(HAS_RLIMIT_AS)
	HV_STORE_RES(RETVAL, RLIMIT_AS);
#endif
#if defined(RLIMIT_CORE) || defined(HAS_RLIMIT_CORE)
	HV_STORE_RES(RETVAL, RLIMIT_CORE);
#endif
#if defined(RLIMIT_CPU) || defined(HAS_RLIMIT_CPU)
	HV_STORE_RES(RETVAL, RLIMIT_CPU);
#endif
#if defined(RLIMIT_DATA) || defined(HAS_RLIMIT_DATA)
	HV_STORE_RES(RETVAL, RLIMIT_DATA);
#endif
#if defined(RLIMIT_FSIZE) || defined(HAS_RLIMIT_FSIZE)
	HV_STORE_RES(RETVAL, RLIMIT_FSIZE);
#endif
#if defined(RLIMIT_FSIZE) || defined(HAS_RLIMIT_FREEMEM)
	HV_STORE_RES(RETVAL, RLIMIT_FSIZE);
#endif
#if defined(RLIMIT_LOCKS) || defined(HAS_RLIMIT_LOCKS)
	HV_STORE_RES(RETVAL, RLIMIT_LOCKS);
#endif
#if defined(RLIMIT_MEMLOCK) || defined(HAS_RLIMIT_MEMLOCK)
	HV_STORE_RES(RETVAL, RLIMIT_MEMLOCK);
#endif
#if defined(RLIMIT_MSGQUEUE) || defined(HAS_RLIMIT_MSGQUEUE)
	HV_STORE_RES(RETVAL, RLIMIT_MSGQUEUE);
#endif
#if defined(RLIMIT_NICE) || defined(HAS_RLIMIT_NICE)
	HV_STORE_RES(RETVAL, RLIMIT_NICE);
#endif
#if defined(RLIMIT_NOFILE) || defined(HAS_RLIMIT_NOFILE)
	HV_STORE_RES(RETVAL, RLIMIT_NOFILE);
#endif
#if defined(RLIMIT_NPROC) || defined(HAS_RLIMIT_NPROC)
	HV_STORE_RES(RETVAL, RLIMIT_NPROC);
#endif
#if defined(RLIMIT_NPTS) || defined(HAS_RLIMIT_NPTS)
	HV_STORE_RES(RETVAL, RLIMIT_NPTS);
#endif
#if defined(RLIMIT_NPTS) || defined(HAS_RLIMIT_NTHR)
	HV_STORE_RES(RETVAL, RLIMIT_NPTS);
#endif
#if defined(RLIMIT_OFILE) || defined(HAS_RLIMIT_OFILE)
	HV_STORE_RES(RETVAL, RLIMIT_OFILE);
#endif
#if defined(RLIMIT_OPEN_MAX) || defined(HAS_RLIMIT_OPEN_MAX)
	HV_STORE_RES(RETVAL, RLIMIT_OPEN_MAX);
#endif
#if defined(RLIMIT_POSIXLOCKS) || defined(HAS_RLIMIT_POSIXLOCKS)
	HV_STORE_RES(RETVAL, RLIMIT_POSIXLOCKS);
#endif
#if defined(RLIMIT_PTHREAD) || defined(HAS_RLIMIT_PTHREAD)
	HV_STORE_RES(RETVAL, RLIMIT_PTHREAD);
#endif
#if defined(RLIMIT_RSS) || defined(HAS_RLIMIT_RSS)
	HV_STORE_RES(RETVAL, RLIMIT_RSS);
#endif
#if defined(RLIMIT_RSESTACK) || defined(HAS_RLIMIT_RSESTACK)
	HV_STORE_RES(RETVAL, RLIMIT_RSESTACK);
#endif
#if defined(RLIMIT_RTPRIO) || defined(HAS_RLIMIT_RTPRIO)
	HV_STORE_RES(RETVAL, RLIMIT_RTPRIO);
#endif
#if defined(RLIMIT_RTTIME) || defined(HAS_RLIMIT_RTTIME)
	HV_STORE_RES(RETVAL, RLIMIT_RTTIME);
#endif
#if defined(RLIMIT_SBSIZE) || defined(HAS_RLIMIT_SBSIZE)
	HV_STORE_RES(RETVAL, RLIMIT_SBSIZE);
#endif
#if defined(RLIMIT_SIGPENDING) || defined(HAS_RLIMIT_SIGPENDING)
	HV_STORE_RES(RETVAL, RLIMIT_SIGPENDING);
#endif
#if defined(RLIMIT_STACK) || defined(HAS_RLIMIT_STACK)
	HV_STORE_RES(RETVAL, RLIMIT_STACK);
#endif
#if defined(RLIMIT_SWAP) || defined(HAS_RLIMIT_SWAP)
	HV_STORE_RES(RETVAL, RLIMIT_SWAP);
#endif
#if defined(RLIMIT_TCACHE) || defined(HAS_RLIMIT_TCACHE)
	HV_STORE_RES(RETVAL, RLIMIT_TCACHE);
#endif
#if defined(RLIMIT_VMEM) || defined(HAS_RLIMIT_VMEM)
	HV_STORE_RES(RETVAL, RLIMIT_VMEM);
#endif
    OUTPUT:
	RETVAL

HV *
_get_prios()
    CODE:
	RETVAL = newHV();
	sv_2mortal((SV*)RETVAL);
#if defined(PRIO_CONTRACT)
	HV_STORE_RES(RETVAL, PRIO_CONTRACT);
#endif
#if defined(PRIO_LWP)
	HV_STORE_RES(RETVAL, PRIO_LWP);
#endif
#if defined(PRIO_PGRP)
	HV_STORE_RES(RETVAL, PRIO_PGRP);
#endif
#if defined(PRIO_PROCESS)
	HV_STORE_RES(RETVAL, PRIO_PROCESS);
#endif
#if defined(PRIO_PROJECT)
	HV_STORE_RES(RETVAL, PRIO_PROJECT);
#endif
#if defined(PRIO_SESSION)
	HV_STORE_RES(RETVAL, PRIO_SESSION);
#endif
#if defined(PRIO_THREAD)
	HV_STORE_RES(RETVAL, PRIO_THREAD);
#endif
#if defined(PRIO_TASK)
	HV_STORE_RES(RETVAL, PRIO_TASK);
#endif
#if defined(PRIO_USER)
	HV_STORE_RES(RETVAL, PRIO_USER);
#endif
#if defined(PRIO_ZONE)
	HV_STORE_RES(RETVAL, PRIO_ZONE);
#endif
    OUTPUT:
	RETVAL
