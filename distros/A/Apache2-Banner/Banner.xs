#include <mod_perl.h>
#include <util_time.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = Apache2::Banner   PACKAGE = Apache2::Banner

const char*
banner()
  CODE:
    RETVAL=ap_get_server_banner();
  OUTPUT:
    RETVAL

const char*
description()
  CODE:
    RETVAL=ap_get_server_description();
  OUTPUT:
    RETVAL

char*
date(time)
    apr_time_t time
  CODE:
    char date[APR_RFC822_DATE_LEN];
    ap_recent_rfc822_date(date, time);
    RETVAL=date;
  OUTPUT:
    RETVAL
