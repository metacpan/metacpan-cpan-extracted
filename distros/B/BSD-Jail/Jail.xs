#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef __FreeBSD__
#error This only works on FreeBSD 4.0 or greater
#endif

#include <sys/param.h>
#include <sys/jail.h>

#define MAX_JAILS_RETURNED 32 * 1024

/* Return <0 on error, or the number of running prisons */
int _get_jids(int *jids) {
	struct xprison *sxp, *xp;
	size_t loop, len;
	if (sysctlbyname("security.jail.list", NULL, &len, NULL, 0) == -1) {
		warn("%s", strerror(errno));
		return -1;	/* sysctl does not exist */
	}
	if (len == 0)
		return 0;	/* No running jails */

	New(0, sxp, 1, struct xprison);
	if ((xp = sxp) == NULL)
		return -1;
	
	if (
		sysctlbyname("security.jail.list", sxp, &len, NULL, 0) == -1 ||
		len < sizeof(*xp) || len % sizeof(*xp) || xp->pr_version != XPRISON_VERSION
	) {
		Safefree(sxp);
		return -1;
	}
	
	for (loop = 0; loop < len / sizeof(*xp) && loop < MAX_JAILS_RETURNED; loop++) {
		jids[loop] = xp->pr_id;
		xp++;
	}
	Safefree(sxp);
	return loop;
}
	


/* Returns a point to the xprison for jid */
struct xprison *_get_xp(const int jid) {
	struct xprison *sxp, *xp;
	struct xprison *rxp;
	size_t loop, len;

	if (sysctlbyname("security.jail.list", NULL, &len, NULL, 0) == -1) {
		warn("%s", strerror(errno));
		return NULL;
	}

	if (len == 0) {
		return NULL;
	}

	New(2, sxp, 1, struct xprison);
	if ((xp = sxp) == NULL)
		return NULL;

	New(3, rxp, 1, struct xprison);
	if (rxp == NULL) {
		Safefree(sxp);
		return NULL;
	}

	if (sysctlbyname("security.jail.list", sxp, &len, NULL, 0) == -1) {
		warn("%s", strerror(errno));
		Safefree(sxp);
		Safefree(rxp);
		return NULL;
	}

	if (len < sizeof(*xp) || len % sizeof(*xp) || xp->pr_version != XPRISON_VERSION) {
		Safefree(sxp);
		Safefree(rxp);
		return NULL;
	}

	for (loop = 0; loop < len / sizeof(*xp) && loop < MAX_JAILS_RETURNED; loop++) {
		if (xp->pr_id == jid) {
			Copy(xp, rxp, 1, struct xprison);
			Safefree(sxp);
			return rxp;
		} else {
			xp++;
		}
	}
	return NULL;	/* No matching jails found */
}


MODULE = BSD::Jail		PACKAGE = BSD::Jail		

void
get_jids()
	INIT:
		int jids[MAX_JAILS_RETURNED], jcount, i;
	PPCODE:
		jcount = _get_jids(&jids[0]);
		for (i = 0; i < jcount; i++) {
			XPUSHs(sv_2mortal(newSVnv(jids[i])));
		}

void
get_xprison(jid)
		int	jid
	INIT:
		struct xprison *xp;
		struct in_addr in;
	PPCODE:
		if ((xp = _get_xp(jid)) != NULL) {
			in.s_addr = ntohl(xp->pr_ip);
			XPUSHs(sv_2mortal(newSViv(xp->pr_version)));
			XPUSHs(sv_2mortal(newSViv(xp->pr_id)));
			XPUSHs(sv_2mortal(newSVpvf(xp->pr_path)));
			XPUSHs(sv_2mortal(newSVpvf(xp->pr_host)));
			XPUSHs(sv_2mortal(newSVpvf(inet_ntoa(in))));
			Safefree(xp);
		}


int
jattach(jid)
		int	jid
	CODE:
		if ((jail_attach(jid)) == -1) {
			warn("%s", strerror(errno));
			RETVAL = 0;
		} else {
			RETVAL = jid;
		}
	OUTPUT:
		RETVAL			


int
jail(path, hostname, ipaddr)
		char *path
		char *hostname
		char *ipaddr
	INIT:
		int jid;
		struct jail j;
		struct in_addr iaddr;
	CODE:
		if (inet_aton(ipaddr, &iaddr) == 0) {
			RETVAL = 0;
			return;		/* Invalid IP */
		}
		
		Zero(&j, 1, struct jail);
		j.version = 0;
		j.path = path;
		j.hostname = hostname;
		j.ip_number = ntohl(iaddr.s_addr);
		if ((jid = jail(&j)) == -1) {
			warn("%s", strerror(errno));
			RETVAL = 0;
		} else {
			RETVAL = jid;
		}
	OUTPUT:
		RETVAL