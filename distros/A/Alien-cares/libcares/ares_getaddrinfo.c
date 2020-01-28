/* Copyright 1998, 2011, 2013 by the Massachusetts Institute of Technology.
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies and that both that copyright
 * notice and this permission notice appear in supporting
 * documentation, and that the name of M.I.T. not be used in
 * advertising or publicity pertaining to distribution of the
 * software without specific, written prior permission.
 * M.I.T. makes no representations about the suitability of
 * this software for any purpose.  It is provided "as is"
 * without express or implied warranty.
 */

#include "ares_setup.h"

#ifdef HAVE_GETSERVBYNAME_R
#  if !defined(GETSERVBYNAME_R_ARGS) || \
     (GETSERVBYNAME_R_ARGS < 4) || (GETSERVBYNAME_R_ARGS > 6)
#    error "you MUST specifiy a valid number of arguments for getservbyname_r"
#  endif
#endif

#ifdef HAVE_NETINET_IN_H
#  include <netinet/in.h>
#endif
#ifdef HAVE_NETDB_H
#  include <netdb.h>
#endif
#ifdef HAVE_ARPA_INET_H
#  include <arpa/inet.h>
#endif
#ifdef HAVE_ARPA_NAMESER_H
#  include <arpa/nameser.h>
#else
#  include "nameser.h"
#endif
#ifdef HAVE_ARPA_NAMESER_COMPAT_H
#  include <arpa/nameser_compat.h>
#endif

#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif

#include "ares.h"
#include "ares_inet_net_pton.h"
#include "bitncmp.h"
#include "ares_platform.h"
#include "ares_nowarn.h"
#include "ares_private.h"
#include <assert.h>
#include <stdint.h>

#ifdef WATT32
#undef WIN32
#endif

#define IPV6_ADDR_SCOPE_NODELOCAL       0x01
#define IPV6_ADDR_SCOPE_INTFACELOCAL    0x01
#define IPV6_ADDR_SCOPE_LINKLOCAL       0x02
#define IPV6_ADDR_SCOPE_SITELOCAL       0x05
#define IPV6_ADDR_SCOPE_ORGLOCAL        0x08
#define IPV6_ADDR_SCOPE_GLOBAL          0x0e

#define IPV6_ADDR_MC_SCOPE(a) ((a)->s6_addr[1] & 0x0f)

/* RFC 4193. */
#define IN6_IS_ADDR_ULA(a) (((a)->s6_addr[0] & 0xfe) == 0xfc)

#define IN_LOOPBACK(a) ((((long int)(a)) & 0xff000000) == 0x7f000000)

/* These macros are modelled after the ones in <netinet/in6.h>. */
/* RFC 4380, section 2.6 */
#define IN6_IS_ADDR_TEREDO(a)	 \
	((*(const uint32_t *)(const void *)(&(a)->s6_addr[0]) == ntohl(0x20010000)))
/* RFC 3056, section 2. */
#define IN6_IS_ADDR_6TO4(a)	 \
	(((a)->s6_addr[0] == 0x20) && ((a)->s6_addr[1] == 0x02))
/* 6bone testing address area (3ffe::/16), deprecated in RFC 3701. */
#define IN6_IS_ADDR_6BONE(a)      \
	(((a)->s6_addr[0] == 0x3f) && ((a)->s6_addr[1] == 0xfe))

struct host_query
{
  ares_channel channel;
  char *name;
  unsigned short port; /* in host order */
  ares_addrinfo_callback callback;
  void *arg;
  struct ares_addrinfo hints;
  int sent_family; /* this family is what was is being used */
  int timeouts;    /* number of timeouts we saw for this request */
  const char *remaining_lookups; /* types of lookup we need to perform ("fb" by
                                    default, file and dns respectively) */
  struct ares_addrinfo *ai; /* store results between lookups */
  char *cname; /* store canonical name between lookups */
};

struct addrinfo_sort_elem
{
  struct ares_addrinfo *ai;
  int has_src_addr;
  ares_sockaddr src_addr;
  int original_order;
};

static void next_lookup(struct host_query *hquery, int status_code);
static void host_callback(void *arg, int status, int timeouts,
                          unsigned char *abuf, int alen);
static void end_hquery(struct host_query *hquery, int status);
static int fake_addrinfo(const char *name,
                         unsigned short port,
                         const struct ares_addrinfo *hints,
                         ares_addrinfo_callback callback,
                         void *arg);
static int file_lookup(struct host_query *hquery);
static unsigned short lookup_service(const char *service, int flags);

static int get_scope(const struct sockaddr *addr);
static int get_label(const struct sockaddr *addr);
static int get_precedence(const struct sockaddr *addr);
static int common_prefix_len(const struct in6_addr *a1,
                             const struct in6_addr *a2);
static int rfc6724_compare(const void *ptr1, const void *ptr2);
static void sort_addrinfo(struct ares_addrinfo *ai);
static int find_src_addr(const struct sockaddr *addr,
                         struct sockaddr *src_addr);

static int is_implemented(int family)
{
  return family == AF_INET || family == AF_INET6 || family == AF_UNSPEC;
}

static const struct ares_addrinfo default_hints = 
{
    0,         /* ai_flags */
    AF_UNSPEC, /* ai_family */
    0,         /* ai_socktype */
    0,         /* ai_protocol */
    0,         /* ai_addrlen */
    NULL,      /* ai_addr */
    NULL,      /* ai_canoname */
    NULL       /* ai_next */
};

void ares_getaddrinfo(ares_channel channel,
                      const char *name,
                      const char *service,
                      const struct ares_addrinfo *hints,
                      ares_addrinfo_callback callback,
                      void *arg)
{
  unsigned short port = 0;
  struct host_query *hquery;

  if (!hints) 
    {
      hints = &default_hints;
    }

  /* Right now we only know how to look up Internet addresses - and unspec
     means try both basically. */
  if (!is_implemented(hints->ai_family))
    {
      callback(arg, ARES_ENOTIMP, 0, NULL);
      return;
    }

  if (service)
    {
      if (hints->ai_flags & ARES_AI_NUMERICSERV)
        {
          port = (unsigned short)strtoul(service, NULL, 0);
          if (!port)
            {
              callback(arg, ARES_ESERVICE, 0, NULL);
              return;
            }
        }
      else
        {
          port = lookup_service(service, 0);
          if (!port)
            {
              port = (unsigned short)strtoul(service, NULL, 0);
              if (!port)
                {
                  callback(arg, ARES_ESERVICE, 0, NULL);
                  return;
                }
            }
        }
    }
  if (fake_addrinfo(name, port, hints, callback, arg))
    return;

  /* Allocate and fill in the host query structure. */
  hquery = ares_malloc(sizeof(struct host_query));
  if (!hquery)
    {
      callback(arg, ARES_ENOMEM, 0, NULL);
      return;
    }
  hquery->name = ares_strdup(name);
  if (!hquery->name)
    {
      ares_free(hquery);
      callback(arg, ARES_ENOMEM, 0, NULL);
      return;
    }
  hquery->port = port;
  hquery->channel = channel;
  hquery->hints = *hints;
  hquery->sent_family = -1; /* nothing is sent yet */
  hquery->callback = callback;
  hquery->arg = arg;
  hquery->remaining_lookups = channel->lookups;
  hquery->timeouts = 0;
  hquery->ai = NULL;
  hquery->cname = NULL;
  
  /* Start performing lookups according to channel->lookups. */
  next_lookup(hquery, ARES_ECONNREFUSED /* initial error code */);
}

static void next_lookup(struct host_query *hquery, int status_code)
{
  const char *p;
  int status = status_code;

  for (p = hquery->remaining_lookups; *p; p++)
    {
      switch (*p)
        {
        case 'b':
          /* DNS lookup */
          hquery->remaining_lookups = p + 1;
          if ((hquery->hints.ai_family == AF_INET6) ||
              (hquery->hints.ai_family == AF_UNSPEC)) {
            /* if inet6 or unspec, start out with AAAA */
            hquery->sent_family = AF_INET6;
            ares_search(hquery->channel, hquery->name, C_IN, T_AAAA,
                        host_callback, hquery);
          }
          else {
            hquery->sent_family = AF_INET;
            ares_search(hquery->channel, hquery->name, C_IN, T_A,
                        host_callback, hquery);
          }
          return;

        case 'f':
          /* Host file lookup */
          status = file_lookup(hquery);

          /* this status check below previously checked for !ARES_ENOTFOUND,
             but we should not assume that this single error code is the one
             that can occur, as that is in fact no longer the case */
          if (status == ARES_SUCCESS)
            {
              end_hquery(hquery, status);
              return;
            }
          status = status_code;   /* Use original status code */
          break;
        }
    }
  end_hquery(hquery, status);
}

static int file_lookup(struct host_query *hquery)
{
  FILE *fp;
  int error;
  int status;

#ifdef WIN32
  char PATH_HOSTS[MAX_PATH];
  win_platform platform;

  PATH_HOSTS[0] = '\0';

  platform = ares__getplatform();

  if (platform == WIN_NT) {
    char tmp[MAX_PATH];
    HKEY hkeyHosts;

    if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_NS_NT_KEY, 0, KEY_READ,
                     &hkeyHosts) == ERROR_SUCCESS)
    {
      DWORD dwLength = MAX_PATH;
      RegQueryValueEx(hkeyHosts, DATABASEPATH, NULL, NULL, (LPBYTE)tmp,
                      &dwLength);
      ExpandEnvironmentStrings(tmp, PATH_HOSTS, MAX_PATH);
      RegCloseKey(hkeyHosts);
    }
  }
  else if (platform == WIN_9X)
    GetWindowsDirectory(PATH_HOSTS, MAX_PATH);
  else
    return ARES_ENOTFOUND;

  strcat(PATH_HOSTS, WIN_PATH_HOSTS);

#elif defined(WATT32)
  extern const char *_w32_GetHostsFile (void);
  const char *PATH_HOSTS = _w32_GetHostsFile();

  if (!PATH_HOSTS)
    return ARES_ENOTFOUND;
#endif

  fp = fopen(PATH_HOSTS, "r");
  if (!fp)
    {
      error = ERRNO;
      switch(error)
        {
        case ENOENT:
        case ESRCH:
          return ARES_ENOTFOUND;
        default:
          DEBUGF(fprintf(stderr, "fopen() failed with error: %d %s\n",
                         error, strerror(error)));
          DEBUGF(fprintf(stderr, "Error opening file: %s\n",
                         PATH_HOSTS));
          return ARES_EFILE;
        }
    }
  status = ares__get_addrinfo(fp, hquery->name, hquery->port, &hquery->hints, &hquery->ai);
  fclose(fp);
  return status;
}

/* Resolve service name into port number given in host byte order. 
 * If not resolved, return 0.
 */
static unsigned short lookup_service(const char *service, int flags)
{
  const char *proto;
  struct servent *sep;
#ifdef HAVE_GETSERVBYNAME_R
  struct servent se;
  char tmpbuf[4096];
#endif

  if (service)
    {
      if (flags & ARES_NI_UDP)
        proto = "udp";
      else if (flags & ARES_NI_SCTP)
        proto = "sctp";
      else if (flags & ARES_NI_DCCP)
        proto = "dccp";
      else
        proto = "tcp";
#ifdef HAVE_GETSERVBYNAME_R
      memset(&se, 0, sizeof(se));
      sep = &se;
      memset(tmpbuf, 0, sizeof(tmpbuf));
#if GETSERVBYNAME_R_ARGS == 6
      if (getservbyname_r(service, proto, &se, (void *)tmpbuf, sizeof(tmpbuf),
                          &sep) != 0)
        sep = NULL; /* LCOV_EXCL_LINE: buffer large so this never fails */
#elif GETSERVBYNAME_R_ARGS == 5
      sep = getservbyname_r(service, proto, &se, (void *)tmpbuf, sizeof(tmpbuf));
#elif GETSERVBYNAME_R_ARGS == 4
      if (getservbyname_r(service, proto, &se, (void *)tmpbuf) != 0)
        sep = NULL;
#else
      /* Lets just hope the OS uses TLS! */
      sep = getservbyname(service, proto);
#endif
#else
        /* Lets just hope the OS uses TLS! */
#if (defined(NETWARE) && !defined(__NOVELL_LIBC__))
      sep = getservbyname(service, (char *)proto);
#else
      sep = getservbyname(service, proto);
#endif
#endif
      return (sep ? ntohs((unsigned short)sep->s_port) : 0);
    }
  return 0;
}

/* If the name looks like an IP address, fake up a host entry, end the
 * query immediately, and return true.  Otherwise return false.
 */
static int fake_addrinfo(const char *name,
                         unsigned short port,
                         const struct ares_addrinfo *hints,
                         ares_addrinfo_callback callback,
                         void *arg)
{
  struct ares_addrinfo *ai;
  ares_sockaddr addr;
  size_t addrlen;
  int result = 0;
  int family = hints->ai_family;
  if (family == AF_INET || family == AF_INET6 || family == AF_UNSPEC)
    {
      /* It only looks like an IP address if it's all numbers and dots. */
      int numdots = 0, valid = 1;
      const char *p;
      for (p = name; *p; p++)
        {
          if (!ISDIGIT(*p) && *p != '.')
            {
              valid = 0;
              break;
            }
          else if (*p == '.')
            {
              numdots++;
            }
        }

      memset(&addr, 0, sizeof(addr));

      /* if we don't have 3 dots, it is illegal
       * (although inet_addr doesn't think so).
       */
      if (numdots != 3 || !valid)
        result = 0;
      else
        result =
            ((addr.sa4.sin_addr.s_addr = inet_addr(name)) 
             == INADDR_NONE ? 0 : 1);

      if (result)
        {
          family = addr.sa.sa_family = AF_INET;
          addr.sa4.sin_port = htons(port);
          addrlen = sizeof(addr.sa4);
        }
    }

  if (family == AF_INET6 || family == AF_UNSPEC)
    {
      result = (ares_inet_pton(AF_INET6, name, &addr.sa6.sin6_addr) < 1 ? 0 : 1);
      addr.sa6.sin6_family = AF_INET6;
      addr.sa6.sin6_port = htons(port);
      addrlen = sizeof(addr.sa6);
    }

  if (!result)
    return 0;

  ai = ares__malloc_addrinfo();
  if (!ai)
    {
      callback(arg, ARES_ENOMEM, 0, NULL);
      return 1;
    }

  ai->ai_addr = ares_malloc(addrlen);
  if (!ai->ai_addr)
    {
      ares_free(ai);
      callback(arg, ARES_ENOMEM, 0, NULL);
      return 1;
    }

  ai->ai_addrlen = (unsigned int)addrlen;
  ai->ai_family = addr.sa.sa_family;
  if (addr.sa.sa_family == AF_INET)
    memcpy(ai->ai_addr, &addr.sa4, sizeof(addr.sa4));
  else
    memcpy(ai->ai_addr, &addr.sa6, sizeof(addr.sa6));

  if (hints->ai_flags & ARES_AI_CANONNAME)
    {
      /* Duplicate the name, to avoid a constness violation. */
      ai->ai_canonname = ares_strdup(name);
      if (!ai->ai_canonname)
        {
          ares_free(ai->ai_addr);
          ares_free(ai);
          callback(arg, ARES_ENOMEM, 0, NULL);
          return 1;
        }
    }

  callback(arg, ARES_SUCCESS, 0, ai);
  return 1;
}

static void host_callback(void *arg, int status, int timeouts,
                          unsigned char *abuf, int alen)
{
  struct host_query *hquery = (struct host_query *) arg;
  hquery->timeouts += timeouts;
  if (status == ARES_SUCCESS)
    {
      if (hquery->sent_family == AF_INET)
        {
          status =
              ares__parse_a_reply(abuf, alen, NULL, &hquery->ai, hquery->port,
                                  &hquery->cname, NULL, NULL);
        }
      else if (hquery->sent_family == AF_INET6)
        {
          status =
              ares__parse_aaaa_reply(abuf, alen, NULL, &hquery->ai,
                                     hquery->port, &hquery->cname, NULL, NULL);
          if (hquery->hints.ai_family == AF_UNSPEC)
            {
              /* Now look for A records and append them to existing results. */
              hquery->sent_family = AF_INET;
              ares_search(hquery->channel, hquery->name, C_IN, T_A,
                          host_callback, hquery);
              return;
            }
        }
      end_hquery(hquery, status);
    }
  else if ((status == ARES_ENODATA || status == ARES_EBADRESP ||
            status == ARES_ETIMEOUT) && (hquery->sent_family == AF_INET6 &&
            hquery->hints.ai_family == AF_UNSPEC))
    {
      /* The AAAA query yielded no useful result.  Now look up an A instead. */
      hquery->sent_family = AF_INET;
      ares_search(hquery->channel, hquery->name, C_IN, T_A, host_callback,
                  hquery);
    }
  else if (status == ARES_EDESTRUCTION)
    end_hquery(hquery, status);
  else
    next_lookup(hquery, status);
}

static void end_hquery(struct host_query *hquery, int status)
{
  struct ares_addrinfo sentinel;
  if (status == ARES_SUCCESS)
    {
      if (hquery->ai)
        {
          if (hquery->hints.ai_flags & ARES_AI_CANONNAME)
            {
              hquery->ai->ai_canonname = hquery->cname;
              hquery->cname = NULL;
            }
          if (hquery->ai->ai_next)
            {
              sentinel.ai_next = hquery->ai;
              sort_addrinfo(&sentinel);
              hquery->ai = sentinel.ai_next;
            }
        }
      else
        {
          status = ARES_ENODATA;
        }
    }
  else
    {
      /* Clean up what we have collected by so far. */
      ares_freeaddrinfo(hquery->ai);
      hquery->ai = NULL;
    }

  hquery->callback(hquery->arg, status, hquery->timeouts, hquery->ai);
  ares_free(hquery->name);
  ares_free(hquery->cname);
  ares_free(hquery);
}

static void sort_addrinfo(struct ares_addrinfo *list_sentinel)
{
  struct ares_addrinfo *cur;
  int nelem = 0, i;
  int has_src_addr;
  struct addrinfo_sort_elem *elems;

  cur = list_sentinel->ai_next;
  while (cur)
    {
      ++nelem;
      cur = cur->ai_next;
    }
  elems = (struct addrinfo_sort_elem *)ares_malloc(
      nelem * sizeof(struct addrinfo_sort_elem));
  if (!elems)
    {
      goto error;
    }

  /*
   * Convert the linked list to an array that also contains the candidate
   * source address for each destination address.
   */
  for (i = 0, cur = list_sentinel->ai_next; i < nelem; ++i, cur = cur->ai_next)
    {
      assert(cur != NULL);
      elems[i].ai = cur;
      elems[i].original_order = i;
      has_src_addr = find_src_addr(cur->ai_addr, &elems[i].src_addr.sa);
      if (has_src_addr == -1)
        {
          goto error;
        }
      elems[i].has_src_addr = has_src_addr;
    }

  /* Sort the addresses, and rearrange the linked list so it matches the sorted
   * order. */
  qsort((void *)elems, nelem, sizeof(struct addrinfo_sort_elem),
        rfc6724_compare);

  list_sentinel->ai_next = elems[0].ai;
  for (i = 0; i < nelem - 1; ++i)
    {
      elems[i].ai->ai_next = elems[i + 1].ai;
    }
  elems[nelem - 1].ai->ai_next = NULL;

error:
  ares_free(elems);
}

static int find_src_addr(const struct sockaddr *addr,
                          struct sockaddr *src_addr)
{
  int sock;
  int ret;
  socklen_t len;

  switch (addr->sa_family)
    {
    case AF_INET:
      len = sizeof(struct sockaddr_in);
      break;
    case AF_INET6:
      len = sizeof(struct sockaddr_in6);
      break;
    default:
      /* No known usable source address for non-INET families. */
      return 0;
    }

  sock = socket(addr->sa_family, SOCK_DGRAM, IPPROTO_UDP);
  if (sock == -1)
    {
      if (errno == EAFNOSUPPORT)
        {
          return 0;
        }
      else
        {
          return -1;
        }
    }

  do
    {
      ret = connect(sock, addr, len);
    }
  while (ret == -1 && errno == EINTR);

  if (ret == -1)
    {
      close(sock);
      return 0;
    }

  if (getsockname(sock, src_addr, &len) == -1)
    {
      close(sock);
      return -1;
    }

  close(sock);
  
  return 1;
}

static int rfc6724_compare(const void *ptr1, const void *ptr2)
{
  const struct addrinfo_sort_elem *a1 = (const struct addrinfo_sort_elem *)ptr1;
  const struct addrinfo_sort_elem *a2 = (const struct addrinfo_sort_elem *)ptr2;
  int scope_src1, scope_dst1, scope_match1;
  int scope_src2, scope_dst2, scope_match2;
  int label_src1, label_dst1, label_match1;
  int label_src2, label_dst2, label_match2;
  int precedence1, precedence2;
  int prefixlen1, prefixlen2;

  /* Rule 1: Avoid unusable destinations. */
  if (a1->has_src_addr != a2->has_src_addr)
    {
      return a2->has_src_addr - a1->has_src_addr;
    }

  /* Rule 2: Prefer matching scope. */
  scope_src1 = get_scope(&a1->src_addr.sa);
  scope_dst1 = get_scope(a1->ai->ai_addr);
  scope_match1 = (scope_src1 == scope_dst1);

  scope_src2 = get_scope(&a2->src_addr.sa);
  scope_dst2 = get_scope(a2->ai->ai_addr);
  scope_match2 = (scope_src2 == scope_dst2);

  if (scope_match1 != scope_match2)
    {
      return scope_match2 - scope_match1;
    }

  /* Rule 3: Avoid deprecated addresses.  */

  /* Rule 4: Prefer home addresses.  */

  /* Rule 5: Prefer matching label. */
  label_src1 = get_label(&a1->src_addr.sa);
  label_dst1 = get_label(a1->ai->ai_addr);
  label_match1 = (label_src1 == label_dst1);

  label_src2 = get_label(&a2->src_addr.sa);
  label_dst2 = get_label(a2->ai->ai_addr);
  label_match2 = (label_src2 == label_dst2);

  if (label_match1 != label_match2)
    {
      return label_match2 - label_match1;
    }

  /* Rule 6: Prefer higher precedence. */
  precedence1 = get_precedence(a1->ai->ai_addr);
  precedence2 = get_precedence(a2->ai->ai_addr);
  if (precedence1 != precedence2)
    {
      return precedence2 - precedence1;
    }

  /* Rule 7: Prefer native transport.  */

  /* Rule 8: Prefer smaller scope. */
  if (scope_dst1 != scope_dst2)
    {
      return scope_dst1 - scope_dst2;
    }

  /* Rule 9: Use longest matching prefix. */
  if (a1->has_src_addr && a1->ai->ai_addr->sa_family == AF_INET6 &&
      a2->has_src_addr && a2->ai->ai_addr->sa_family == AF_INET6)
    {
      const struct sockaddr_in6 *a1_src = &a1->src_addr.sa6;
      const struct sockaddr_in6 *a1_dst =
          (const struct sockaddr_in6 *)a1->ai->ai_addr;
      const struct sockaddr_in6 *a2_src = &a2->src_addr.sa6;
      const struct sockaddr_in6 *a2_dst =
          (const struct sockaddr_in6 *)a2->ai->ai_addr;
      prefixlen1 = common_prefix_len(&a1_src->sin6_addr, &a1_dst->sin6_addr);
      prefixlen2 = common_prefix_len(&a2_src->sin6_addr, &a2_dst->sin6_addr);
      if (prefixlen1 != prefixlen2)
        {
          return prefixlen2 - prefixlen1;
        }
    }

  /*
   * Rule 10: Leave the order unchanged.
   * We need this since qsort() is not necessarily stable.
   */
  return a1->original_order - a2->original_order;
}

static int get_scope(const struct sockaddr *addr)
{
  if (addr->sa_family == AF_INET6)
    {
      const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *)addr;
      if (IN6_IS_ADDR_MULTICAST(&addr6->sin6_addr))
        {
          return IPV6_ADDR_MC_SCOPE(&addr6->sin6_addr);
        }
      else if (IN6_IS_ADDR_LOOPBACK(&addr6->sin6_addr) ||
               IN6_IS_ADDR_LINKLOCAL(&addr6->sin6_addr))
        {
          /*
           * RFC 4291 section 2.5.3 says loopback is to be treated as having
           * link-local scope.
           */
          return IPV6_ADDR_SCOPE_LINKLOCAL;
        }
      else if (IN6_IS_ADDR_SITELOCAL(&addr6->sin6_addr))
        {
          return IPV6_ADDR_SCOPE_SITELOCAL;
        }
      else
        {
          return IPV6_ADDR_SCOPE_GLOBAL;
        }
    }
  else if (addr->sa_family == AF_INET)
    {
      const struct sockaddr_in *addr4 = (const struct sockaddr_in *)addr;
      unsigned long int na = ntohl(addr4->sin_addr.s_addr);
      if (IN_LOOPBACK(na) || /* 127.0.0.0/8 */
          (na & 0xffff0000) == 0xa9fe0000)
        { /* 169.254.0.0/16 */
          return IPV6_ADDR_SCOPE_LINKLOCAL;
        }
      else
        {
          /*
           * RFC 6724 section 3.2. Other IPv4 addresses, including private
           * addresses and shared addresses (100.64.0.0/10), are assigned global
           * scope.
           */
          return IPV6_ADDR_SCOPE_GLOBAL;
        }
    }
  else
    {
      /*
       * This should never happen.
       * Return a scope with low priority as a last resort.
       */
      return IPV6_ADDR_SCOPE_NODELOCAL;
    }
}

static int get_label(const struct sockaddr *addr)
{
  if (addr->sa_family == AF_INET)
    {
      return 4;
    }
  else if (addr->sa_family == AF_INET6)
    {
      const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *)addr;
      if (IN6_IS_ADDR_LOOPBACK(&addr6->sin6_addr))
        {
          return 0;
        }
      else if (IN6_IS_ADDR_V4MAPPED(&addr6->sin6_addr))
        {
          return 4;
        }
      else if (IN6_IS_ADDR_6TO4(&addr6->sin6_addr))
        {
          return 2;
        }
      else if (IN6_IS_ADDR_TEREDO(&addr6->sin6_addr))
        {
          return 5;
        }
      else if (IN6_IS_ADDR_ULA(&addr6->sin6_addr))
        {
          return 13;
        }
      else if (IN6_IS_ADDR_V4COMPAT(&addr6->sin6_addr))
        {
          return 3;
        }
      else if (IN6_IS_ADDR_SITELOCAL(&addr6->sin6_addr))
        {
          return 11;
        }
      else if (IN6_IS_ADDR_6BONE(&addr6->sin6_addr))
        {
          return 12;
        }
      else
        {
          /* All other IPv6 addresses, including global unicast addresses. */
          return 1;
        }
    }
  else
    {
      /*
       * This should never happen.
       * Return a semi-random label as a last resort.
       */
      return 1;
    }
}

/*
 * Get the precedence for a given IPv4/IPv6 address.
 * RFC 6724, section 2.1.
 */
static int get_precedence(const struct sockaddr *addr)
{
  if (addr->sa_family == AF_INET)
    {
      return 35;
    }
  else if (addr->sa_family == AF_INET6)
    {
      const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *)addr;
      if (IN6_IS_ADDR_LOOPBACK(&addr6->sin6_addr))
        {
          return 50;
        }
      else if (IN6_IS_ADDR_V4MAPPED(&addr6->sin6_addr))
        {
          return 35;
        }
      else if (IN6_IS_ADDR_6TO4(&addr6->sin6_addr))
        {
          return 30;
        }
      else if (IN6_IS_ADDR_TEREDO(&addr6->sin6_addr))
        {
          return 5;
        }
      else if (IN6_IS_ADDR_ULA(&addr6->sin6_addr))
        {
          return 3;
        }
      else if (IN6_IS_ADDR_V4COMPAT(&addr6->sin6_addr) ||
               IN6_IS_ADDR_SITELOCAL(&addr6->sin6_addr) ||
               IN6_IS_ADDR_6BONE(&addr6->sin6_addr))
        {
          return 1;
        }
      else
        {
          /* All other IPv6 addresses, including global unicast addresses. */
          return 40;
        }
    }
  else
    {
      return 1;
    }
}

static int common_prefix_len(const struct in6_addr *a1,
                             const struct in6_addr *a2)
{
  const char *p1 = (const char *)a1;
  const char *p2 = (const char *)a2;
  unsigned i;

  for (i = 0; i < sizeof(*a1); ++i)
    {
      int x, j;

      if (p1[i] == p2[i])
        {
          continue;
        }
      x = p1[i] ^ p2[i];
      for (j = 0; j < CHAR_BIT; ++j)
        {
          if (x & (1 << (CHAR_BIT - 1)))
            {
              return i * CHAR_BIT + j;
            }
          x <<= 1;
        }
    }
  return sizeof(*a1) * CHAR_BIT;
}
