/*
 * $Id: Libwrap.xs,v 1.4 2003/12/18 02:53:34 james Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <tcpd.h>
#include <syslog.h>

int allow_severity = LOG_INFO;
int deny_severity = LOG_NOTICE;

MODULE = Authen::Libwrap			PACKAGE = Authen::Libwrap

int
_hosts_ctl(daemon, client_name, client_addr, client_user)
	char *daemon
	char *client_name
	char *client_addr
	char *client_user
    CODE:
        RETVAL = hosts_ctl(daemon, client_name, client_addr, client_user);
    OUTPUT:
        RETVAL
    POSTCALL:
        if( 0 == RETVAL ) {
            XSRETURN_UNDEF;
        }

/* EOF */
