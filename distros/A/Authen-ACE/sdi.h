/* $Id: sdi.h,v 1.1.1.1 1997/09/18 19:02:46 carrigad Exp $ */

/* Copyright (C), 1997, Interprovincial Pipe Line Inc. */

#include "sdi_athd.h"
#include "sdi_defs.h"
#include "sdacmvls.h"
#include "sdconf.h"

typedef struct SD_CLIENT SDClient;

extern int creadcfg(void);
extern int sd_init(SDClient *);
extern int sd_auth(SDClient *);
extern int sd_check(char *, char *, SDClient *);
extern int sd_next(char *, SDClient *);
extern int sd_pin(char *, char, SDClient *);
extern int sd_close(void);
