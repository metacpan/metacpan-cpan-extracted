#if defined(__linux) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(__CYGWIN__)
# define ENABLE_IPV6 1 // if you get compilation problems try to disable IPv6
#else
# define ENABLE_IPV6 0
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pthread.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <time.h>
#include <poll.h>
#include <unistd.h>
#include <inttypes.h>
#include <fcntl.h>
#include <errno.h>
#include <limits.h>

#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>

#include <netinet/in.h>
#include <arpa/inet.h>

#ifdef __linux
# include <linux/icmp.h>
#endif
#if ENABLE_IPV6 && !defined (__CYGWIN__)
# include <netinet/icmp6.h>
#endif

#define ICMP4_ECHO       8
#define ICMP4_ECHO_REPLY 0
#define ICMP6_ECHO       128
#define ICMP6_ECHO_REPLY 129

#define DRAIN_INTERVAL 1e-6 // how long to wait when sendto returns ENOBUFS, in seconds
#define MIN_INTERVAL   1e-6 // minimum packet send interval, in seconds

#define HDR_SIZE_IP4  20
#define HDR_SIZE_IP6  48

static int thr_res[2]; // worker thread finished status
static int icmp4_fd = -1;
static int icmp6_fd = -1;

/*****************************************************************************/

typedef double tstamp;

static tstamp
NOW (void)
{
  struct timeval tv;

  gettimeofday (&tv, 0);

  return tv.tv_sec + tv.tv_usec * 1e-6;
}

static void
ssleep (tstamp wait)
{
#if defined (__SVR4) && defined (__sun)
  struct timeval tv;

  tv.tv_sec  = wait;
  tv.tv_usec = (wait - tv.tv_sec) * 1e6;

  select (0, 0, 0, 0, &tv);
#elif defined(_WIN32)
  Sleep ((unsigned long)(delay * 1e3));
#else
  struct timespec ts;

  ts.tv_sec  = wait;
  ts.tv_nsec = (wait - ts.tv_sec) * 1e9;

  nanosleep (&ts, 0);
#endif
}

/*****************************************************************************/

typedef struct
{
  uint8_t version_ihl;
  uint8_t tos;
  uint16_t tot_len;

  uint16_t id;
  uint16_t flags;

  uint8_t ttl;
  uint8_t protocol;
  uint16_t cksum;

  uint32_t src;
  uint32_t dst;
} IP4HDR;

/*****************************************************************************/

typedef uint8_t addr_tt[16];

typedef struct
{
  tstamp next;
  tstamp interval;
  int addrlen;

  addr_tt lo, hi; /* only if !addrcnt */

  int addrcnt;
  /* addrcnt addresses follow */
} RANGE;

typedef struct
{
  RANGE **ranges;
  int rangecnt, rangemax;

  tstamp next;
  tstamp interval;

  tstamp maxrtt;

  uint16_t magic1;
  uint16_t magic2;
  uint16_t magic3;

  int id;

  AV *recvq; /* receive queue */
  int nextrecv;
  SV *recvcb;

  pthread_t thrid;
  int running;
} PINGER;

static PINGER **pingers;
static int *pingerfree; /* freelist next */
static int pingercnt;
static int pingermax;
static int firstfree = -1;
static int firstrecv = -1;

/*****************************************************************************/

typedef struct
{
  uint8_t type, code;
  uint16_t cksum;

  uint16_t id, seq;

  uint16_t pinger;
  uint16_t magic;

  uint32_t stamp_hi;
  uint32_t stamp_lo;
} PKT;

static int
pkt_is_valid_for (PKT *pkt, PINGER *pinger)
{
  return pkt->id    == pinger->magic1
      && pkt->seq   == pinger->magic2
      && pkt->magic == pinger->magic3;
}

static void
ts_to_pkt (PKT *pkt, tstamp ts)
{
  /* move 12 bits of seconds into the 32 bit fractional part */
  /* leaving 20 bits subsecond resolution and 44 bits of integers */
  /* (of which 32 are typically usable) */
  ts *= 1. / 4096.;

  pkt->stamp_hi = ts;
  pkt->stamp_lo = (ts - pkt->stamp_hi) * 4294967296.;
}

static tstamp
pkt_to_ts (PKT *pkt)
{
  return pkt->stamp_hi *  4096.
       + pkt->stamp_lo * (4096. / 4294967296.);
}

static void
pkt_cksum (PKT *pkt)
{
  uint_fast32_t sum = 0;
  uint32_t *wp = (uint32_t *)pkt;
  int len = sizeof (*pkt) / 4;

  do
    {
      uint_fast32_t w = *(volatile uint32_t *)wp++;
      sum += (w & 0xffff) + (w >> 16);
    }
  while (--len);

  sum = (sum >> 16) + (sum & 0xffff);   /* add high 16 to low 16 */
  sum += sum >> 16;                     /* add carry */

  pkt->cksum = ~sum;
}

/*****************************************************************************/

static void
range_free (RANGE *self)
{
  free (self);
}

/* like sendto, but retries on failure */
static void
xsendto (int fd, void *buf, size_t len, int flags, void *sa, int salen)
{
  tstamp wait = DRAIN_INTERVAL / 2.;

  while (sendto (fd, buf, len, flags, sa, salen) < 0 && errno == ENOBUFS)
    ssleep (wait *= 2.);
}

// ping current address, return true and increment if more to ping
static int
range_send_ping (RANGE *self, PKT *pkt)
{
  // send ping
  uint8_t *addr;
  int addrlen;

  if (self->addrcnt)
    addr = (self->addrcnt - 1) * self->addrlen + (uint8_t *)(self + 1);
  else
    addr = sizeof (addr_tt) - self->addrlen + self->lo;

  addrlen = self->addrlen;

  /* convert ipv4 mapped addresses - this only works for host lists */
  /* this tries to match 0000:0000:0000:0000:0000:ffff:a.b.c.d */
  /* efficiently but also with few insns */
  if (addrlen == 16 && !addr [0] && icmp4_fd >= 0
      && !(              addr [ 1]
           | addr [ 2] | addr [ 3]
           | addr [ 4] | addr [ 5]
           | addr [ 6] | addr [ 7]
           | addr [ 8] | addr [ 9]
           | (255-addr [10]) | (255-addr [11])))
    {
      addr += 12;
      addrlen -= 12;
    }

  pkt->cksum = 0;

  if (addrlen == 4)
    {
      struct sockaddr_in sa;

      pkt->type = ICMP4_ECHO;
      pkt_cksum (pkt);

      sa.sin_family = AF_INET;
      sa.sin_port   = 0;

      memcpy (&sa.sin_addr, addr, sizeof (sa.sin_addr));

      xsendto (icmp4_fd, pkt, sizeof (*pkt), 0, &sa, sizeof (sa));
    }
  else
    {
#if ENABLE_IPV6
      struct sockaddr_in6 sa;

      pkt->type = ICMP6_ECHO;

      sa.sin6_family   = AF_INET6;
      sa.sin6_port     = 0;
      sa.sin6_flowinfo = 0;
      sa.sin6_scope_id = 0;

      memcpy (&sa.sin6_addr, addr, sizeof (sa.sin6_addr));

      xsendto (icmp6_fd, pkt, sizeof (*pkt), 0, &sa, sizeof (sa));
#endif
    }

  // see if we have any more addresses
  if (self->addrcnt)
    {
      if (!--self->addrcnt)
        return 0;
    }
  else
    {
      if (!memcmp (&self->lo, &self->hi, sizeof (addr_tt)))
        return 0;

      // increment self->lo
      {
        int len = sizeof (addr_tt) - 1;

        while (!++self->lo [len])
          --len;
      }
    }

  return 1;
}

/*****************************************************************************/

static void
downheap (PINGER *self)
{
  RANGE *elem = self->ranges [0]; /* always exists */
  int Nm1 = self->rangecnt - 1;
  int j;
  int k;

  for (k = 0; ; )
    {
      int j = k * 2 + 1;

      if (j > Nm1)
        break;

      if (j < Nm1
          && self->ranges [j]->next > self->ranges [j + 1]->next)
        ++j;

      if (self->ranges [j]->next >= elem->next)
        break;

      self->ranges [k] = self->ranges [j];

      k = j;
    }

  self->ranges [k] = elem;
}

static void
upheap (PINGER *self, int k)
{
  RANGE *elem = self->ranges [k];

  while (k)
    {
      int j = (k - 1) >> 1;

      if (self->ranges [j]->next <= elem->next)
        break;

      self->ranges [k] = self->ranges [j];

      k = j;
    }

  self->ranges [k] = elem;
}

static void *
ping_proc (void *self_)
{
  PINGER *self = (PINGER *)self_;
  PKT pkt;

  memset (&pkt, 0, sizeof (pkt));

  tstamp now = NOW ();

  pkt.code   = 0;
  pkt.id     = self->magic1;
  pkt.seq    = self->magic2;
  pkt.magic  = self->magic3;
  pkt.pinger = self->id;

  if (self->next < now)
    self->next = now;

  while (self->rangecnt)
    {
      RANGE *range = self->ranges [0];

      // ranges [0] is always the next range to ping
      tstamp wait = range->next - now;

      // compare with the global frequency limit
      {
        tstamp diff = self->next - now;

        if (wait < diff)
          wait = diff; // global rate limit overrides
        else
          self->next = range->next; // fast forward
      }

      if (wait > 0.)
        ssleep (wait);

      now = NOW ();

      ts_to_pkt (&pkt, now);

      if (!range_send_ping (range, &pkt))
        {
          self->ranges [0] = self->ranges [--self->rangecnt];
          range_free (range);
        }
      else
        range->next = self->next + range->interval;

      downheap (self);

      self->next += self->interval;
      now = NOW ();
    }

  ssleep (self->maxrtt);

  {
    uint16_t id = self->id;

    write (thr_res [1], &id, sizeof (id));
  }

  return 0;
}

/*****************************************************************************/

/* NetBSD, Solaris... */
#ifndef PTHREAD_STACK_MIN
# define PTHREAD_STACK_MIN 0
#endif

static void
pinger_start (PINGER *self)
{
  sigset_t fullsigset, oldsigset;
  pthread_attr_t attr;

  if (self->running)
    return;

  sigfillset (&fullsigset);

  pthread_attr_init (&attr);
  pthread_attr_setstacksize (&attr, PTHREAD_STACK_MIN < sizeof (long) * 2048 ? sizeof (long) * 2048 : PTHREAD_STACK_MIN);

  pthread_sigmask (SIG_SETMASK, &fullsigset, &oldsigset);

  if (pthread_create (&self->thrid, &attr, ping_proc, (void *)self))
    croak ("AnyEvent::FastPing: unable to create pinger thread");

  pthread_sigmask (SIG_SETMASK, &oldsigset, 0);

  self->running = 1;
}

static void
pinger_stop (PINGER *self)
{
  if (!self->running)
    return;

  self->running = 0;
  pthread_cancel (self->thrid);
  pthread_join (self->thrid, 0);
}

static void
pinger_init (PINGER *self)
{
  memset (self, 0, sizeof (PINGER));

  if (firstfree >= 0)
    {
      self->id = firstfree;
      firstfree = pingerfree [firstfree];
    }
  else if (pingercnt == 0xffff)
    croak ("unable to create more than 65536 AnyEvent::FastPing objects");
  else
    {
      if (pingercnt == pingermax)
        {
          pingermax = pingermax * 2 + 16;
          pingers    = realloc (pingers   , sizeof (pingers    [0]) * pingermax);
          pingerfree = realloc (pingerfree, sizeof (pingerfree [0]) * pingermax);
        }

      self->id = pingercnt++;
    }

  pingers [self->id] = self;

  self->recvcb   = &PL_sv_undef;
  self->next     = 0.;
  self->interval = MIN_INTERVAL;
  self->maxrtt   = 0.5;
  self->rangemax = 16;
  self->ranges   = malloc (sizeof (self->ranges [0]) * self->rangemax);
}

static void
pinger_free (PINGER *self)
{
  pinger_stop (self);

  pingers [self->id] = 0;

  SvREFCNT_dec (self->recvq);
  SvREFCNT_dec (self->recvcb);

  pingerfree [self->id] = firstfree;
  firstfree = self->id;

  while (self->rangecnt)
    range_free (self->ranges [--self->rangecnt]);

  free (self->ranges);
}

static void
pinger_add_range (PINGER *self, RANGE *range)
{
  if (self->rangecnt == self->rangemax)
    self->ranges = realloc (self->ranges, sizeof (self->ranges [0]) * (self->rangemax <<= 1));

  self->ranges [self->rangecnt] = range;
  upheap (self, self->rangecnt);
  ++self->rangecnt;
}

/*****************************************************************************/

static void
recv_feed (PINGER *self, void *addr, int addrlen, tstamp rtt)
{
  if (!self->recvq)
    {
      /* first seen this round */
      if (!SvOK (self->recvcb))
        return;

      self->recvq = newAV ();

      self->nextrecv = firstrecv;
      firstrecv = self->id;
    }

  {
    AV *pkt = newAV ();

    av_extend (pkt, 2-1);

    AvARRAY (pkt)[0] = newSVpvn (addr, addrlen);
    AvARRAY (pkt)[1] = newSVnv (rtt);
    AvFILLp (pkt) = 2-1;

    av_push (self->recvq, newRV_noinc ((SV *)pkt));
  }
}

static void
recv_flush (void)
{
  if (firstrecv < 0)
    return;

  ENTER;
  SAVETMPS;

  do
    {
      dSP;
      PINGER *self = pingers [firstrecv];
      firstrecv = self->nextrecv;

      self->nextrecv = -1;

      PUSHMARK (SP);
      XPUSHs (sv_2mortal (newRV_noinc ((SV *)self->recvq)));
      self->recvq = 0;
      PUTBACK;
      call_sv (self->recvcb, G_DISCARD | G_VOID);
    }
  while (firstrecv >= 0);

  FREETMPS;
  LEAVE;
}

/*****************************************************************************/

#if 0
static void
feed_reply (AV *res_av)
{
  dSP;
  SV *res = sv_2mortal (newRV_inc ((SV *)res_av));
  int i;

  if (av_len (res_av) < 0)
    return;

  ENTER;
  SAVETMPS;

  for (i = av_len (cbs) + 1; i--; )
    {
      SV *cb = *av_fetch (cbs, i, 1);

      PUSHMARK (SP);
      XPUSHs (res);
      PUTBACK;
      call_sv (cb, G_DISCARD | G_VOID);
    }

  FREETMPS;
  LEAVE;
}
#endif

static void
boot_protocols (void)
{
  icmp4_fd = socket (AF_INET, SOCK_RAW, IPPROTO_ICMP);
  fcntl (icmp4_fd, F_SETFL, O_NONBLOCK);
#ifdef ICMP_FILTER
  {
    struct icmp_filter oval;
    oval.data = 0xffffffff & ~(1 << ICMP4_ECHO_REPLY);
    setsockopt (icmp4_fd, SOL_RAW, ICMP_FILTER, &oval, sizeof oval);
  }
#endif

#if ENABLE_IPV6
  icmp6_fd = socket (AF_INET6, SOCK_RAW, IPPROTO_ICMPV6);
  fcntl (icmp6_fd, F_SETFL, O_NONBLOCK);
# ifdef ICMP6_FILTER
  {
    struct icmp6_filter oval;
    ICMP6_FILTER_SETBLOCKALL (&oval);
    ICMP6_FILTER_SETPASS (ICMP6_ECHO_REPLY, &oval);
    setsockopt (icmp6_fd, IPPROTO_ICMPV6, ICMP6_FILTER, &oval, sizeof oval);
  }
# endif
#endif
}

static void
boot (void)
{
  if (pipe (thr_res) < 0)
    croak ("AnyEvent::FastPing: unable to create receive pipe");

  sv_setiv (get_sv ("AnyEvent::FastPing::THR_RES_FD", 1), thr_res [0]);

  boot_protocols ();

  sv_setiv (get_sv ("AnyEvent::FastPing::ICMP4_FD", 1), icmp4_fd);
  sv_setiv (get_sv ("AnyEvent::FastPing::ICMP6_FD", 1), icmp6_fd);
}

#define NOT_RUNNING \
  if (self->running) \
    croak ("AnyEvent::FastPing object has been started - you have to stop it first before calling this method, caught");

MODULE = AnyEvent::FastPing		PACKAGE = AnyEvent::FastPing		PREFIX = pinger_

PROTOTYPES: DISABLE

BOOT:
{
	HV *stash = gv_stashpv ("AnyEvent::FastPing", 1);
	
	if (sizeof (PKT) & 3)
	  croak ("size of PKT structure is not a multiple of 4");

	newCONSTSUB (stash, "icmp4_pktsize", newSViv (HDR_SIZE_IP4 + sizeof (PKT)));
	newCONSTSUB (stash, "icmp6_pktsize", newSViv (HDR_SIZE_IP6 + sizeof (PKT)));

        boot_protocols ();
	
	newCONSTSUB (stash, "ipv4_supported", newSViv (icmp4_fd >= 0));
	newCONSTSUB (stash, "ipv6_supported", newSViv (icmp6_fd >= 0));
	
        close (icmp4_fd);
        close (icmp6_fd);
}

void
_boot ()
	CODE:
	boot ();

void
_recv_icmp4 (...)
	CODE:
{
	char buf [512];
        struct sockaddr_in sa;
        int maxrecv;

        for (maxrecv = 256+1; --maxrecv; )
          {
            PINGER *pinger;
            IP4HDR *iphdr = (IP4HDR *)buf;
            socklen_t sl = sizeof (sa);
            int len = recvfrom (icmp4_fd, buf, sizeof (buf), MSG_TRUNC, (struct sockaddr *)&sa, &sl);
            int hdrlen, totlen;
            PKT *pkt;

            if (len <= HDR_SIZE_IP4)
              break;

            hdrlen = (iphdr->version_ihl & 15) * 4;
            totlen = ntohs (iphdr->tot_len);

            if (totlen > len
                || iphdr->protocol != IPPROTO_ICMP
                || hdrlen < HDR_SIZE_IP4 || hdrlen + sizeof (PKT) != totlen)
              continue;

            pkt = (PKT *)(buf + hdrlen);

            if (pkt->type != ICMP4_ECHO_REPLY
                || pkt->pinger >= pingercnt
                || !pingers [pkt->pinger])
              continue;

            pinger = pingers [pkt->pinger];

            if (!pkt_is_valid_for (pkt, pinger))
              continue;

            recv_feed (pinger, &sa.sin_addr, 4, NOW () - pkt_to_ts (pkt));
          }

        recv_flush ();
}

void
_recv_icmp6 (...)
	CODE:
{
        struct sockaddr_in6 sa;
        PKT pkt;
        int maxrecv;

        for (maxrecv = 256+1; --maxrecv; )
          {
            PINGER *pinger;
            socklen_t sl = sizeof (sa);
            int len = recvfrom (icmp6_fd, &pkt, sizeof (pkt), MSG_TRUNC, (struct sockaddr *)&sa, &sl);

            if (len != sizeof (PKT))
              break;

            if (pkt.type != ICMP6_ECHO_REPLY
                || pkt.pinger >= pingercnt
                || !pingers [pkt.pinger])
              continue;

            pinger = pingers [pkt.pinger];

            if (!pkt_is_valid_for (&pkt, pinger))
              continue;

            recv_feed (pinger, &sa.sin6_addr, 16, NOW () - pkt_to_ts (&pkt));
          }

        recv_flush ();
}

void
_new (SV *klass, UV magic1, UV magic2, UV magic3)
	PPCODE:
{
        SV *pv = NEWSV (0, sizeof (PINGER));
        PINGER *self = (PINGER *)SvPVX (pv);

        SvPOK_only (pv);
        XPUSHs (sv_2mortal (sv_bless (newRV_noinc (pv), gv_stashpv (SvPVutf8_nolen (klass), 1))));
        pinger_init (self);
        self->magic1 = magic1;
        self->magic2 = magic2;
        self->magic3 = magic3;
}

void
_free (PINGER *self)
	CODE:
        pinger_free (self);

IV
id (PINGER *self, ...)
	CODE:
        RETVAL = self->id;
	OUTPUT:
        RETVAL

void pinger_start (PINGER *self)

void pinger_stop (PINGER *self)

void
_stop_id (UV id)
	CODE:
        if (id < pingercnt && pingers [id])
          pinger_stop (pingers [id]);

void
interval (PINGER *self, NV interval)
	CODE:
        NOT_RUNNING;
        self->interval = interval > MIN_INTERVAL ? interval : MIN_INTERVAL;

void
max_rtt (PINGER *self, NV maxrtt)
	CODE:
        NOT_RUNNING;
        self->maxrtt = maxrtt;

void
on_recv (PINGER *self, SV *cb)
	CODE:
        SvREFCNT_dec (self->recvcb);
        self->recvcb = newSVsv (cb);

void
add_range (PINGER *self, SV *lo_, SV *hi_, NV interval = 0)
	CODE:
{
	STRLEN lo_len, hi_len;
  	char *lo = SvPVbyte (lo_, lo_len);
  	char *hi = SvPVbyte (hi_, hi_len);
        RANGE *range;
        NOT_RUNNING;

        if (lo_len != hi_len || (lo_len != 4 && lo_len != 16))
          croak ("AnyEvent::FastPing::add_range address range must be specified as two binary IPv4 or IPv6 addresses");

        if (lo_len ==  4 && icmp4_fd < 0) croak ("IPv4 support unavailable");
        if (lo_len == 16 && icmp6_fd < 0) croak ("IPv6 support unavailable");

        if (memcmp (lo, hi, lo_len) > 0)
          croak ("AnyEvent::FastPing::add_range called with lo > hi");

        range = calloc (1, sizeof (RANGE));

        range->next     = 0;
        range->interval = interval > MIN_INTERVAL ? interval : MIN_INTERVAL;
        range->addrlen  = lo_len;

        memcpy (sizeof (addr_tt) - lo_len + (char *)&range->lo, lo, lo_len);
        memcpy (sizeof (addr_tt) - lo_len + (char *)&range->hi, hi, lo_len);

        pinger_add_range (self, range);
}

void
add_hosts (PINGER *self, SV *addrs, NV interval = 0, UV interleave = 1)
	CODE:
{
  	AV *av;
        int i, j, k;
        int cnt;
        int addrlen = 0;
        RANGE *range;
        NOT_RUNNING;

        if (!SvROK (addrs) || SvTYPE (SvRV (addrs)) != SVt_PVAV)
          croak ("AnyEvent::FastPing::add_hosts expects an arrayref with binary IPv4 or IPv6 addresses");

        av = (AV *)SvRV (addrs);
        cnt = av_len (av) + 1;

        for (i = 0; i < cnt; ++i)
          {
            SV *sv = *av_fetch (av, i, 1);
            sv_utf8_downgrade (sv, 0);

            j = SvCUR (sv);

            if (j != 4 && j != 16)
              croak ("AnyEvent::FastPing::add_hosts addresses must be specified as binary IPv4 or IPv6 addresses");

            if (j > addrlen)
              addrlen = j;
          }

        if (!cnt)
          XSRETURN_EMPTY;

        range = calloc (1, sizeof (RANGE) + cnt * addrlen);

        range->next     = 0;
        range->interval = interval > MIN_INTERVAL ? interval : MIN_INTERVAL;
        range->addrlen  = addrlen;
        range->addrcnt  = cnt;

        if (interleave == 0)
          interleave = cnt <= 256 * 256 ? 256 : (int)sqrtf (cnt);

        k = cnt;
        for (j = 0; j < interleave; ++j)
          for (i = j; i < cnt; i += interleave)
            {
              uint8_t *dst = (uint8_t *)(range + 1) + --k * addrlen;
              char *pv;
              STRLEN pvlen;
              SV *sv = *av_fetch (av, i, 1);
              sv_utf8_downgrade (sv, 0);

              pv = SvPVbyte (sv, pvlen);

              if (pvlen != addrlen)
                {
                  dst [ 0] = 0x00; dst [ 1] = 0x00; dst [ 2] = 0x00; dst [ 3] = 0x00;
                  dst [ 4] = 0x00; dst [ 5] = 0x00; dst [ 6] = 0x00; dst [ 7] = 0x00;
                  dst [ 8] = 0x00; dst [ 9] = 0x00; dst [10] = 0xff; dst [11] = 0xff;
                  dst [12] = pv [0]; dst [13] = pv [1]; dst [14] = pv [2]; dst [15] = pv [3];
                }
              else
                memcpy (dst, pv, addrlen);
            }

        pinger_add_range (self, range);
}

