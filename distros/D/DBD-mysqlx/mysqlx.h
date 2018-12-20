#ifndef DRIVER_H_INCLUDED
#define DRIVER_H_INCLUDED
 
#define NEED_DBIXS_VERSION 93    /* 93 for DBI versions 1.00 to 1.51+ */
#define PERL_NO_GET_CONTEXT      /* if used require DBI 1.51+ */
 
#include "dbdimp.h"

#include <DBIXS.h>      /* installed by the DBI module  */
 
#include "dbivport.h"   /* copied from DBI              */
 
#include <dbd_xsh.h>    /* installed by the DBI module  */
 
#endif /* DRIVER_H_INCLUDED */
