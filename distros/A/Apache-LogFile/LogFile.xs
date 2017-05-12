/* ====================================================================
 * Copyright (c) 1995-1998 The Apache Group.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * 4. The names "Apache Server" and "Apache Group" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission.
 *
 * 5. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the Apache Group
 *    for use in the Apache HTTP server project (http://www.apache.org/)."
 *
 * THIS SOFTWARE IS PROVIDED BY THE APACHE GROUP ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE APACHE GROUP OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Group and was originally based
 * on public domain software written at the National Center for
 * Supercomputing Applications, University of Illinois, Urbana-Champaign.
 * For more information on the Apache Group and the Apache HTTP server
 * project, please see <http://www.apache.org/>.
 *
 */

/* $Id: LogFile.xs,v 1.1.1.1 1998/11/16 20:44:25 dougm Exp $ */

#include "modules/perl/mod_perl.h"

/* some stuff borrowed from mod_log_config.c */
static int xfer_flags = (O_WRONLY | O_APPEND | O_CREAT);
#if defined(__EMX__) || defined(WIN32)
/* OS/2 dosen't support users and groups */
static mode_t xfer_mode = (S_IREAD | S_IWRITE);
#else
static mode_t xfer_mode = (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
#endif

typedef struct {
    char *fname;
    array_header *format;
    int log_fd;
#ifdef BUFFERED_LOGS
    int outcnt;
    char outbuf[LOG_BUFSIZE];
#endif
} config_log_state;

typedef config_log_state *Apache__LogFile;

/* when the startup pool is cleared, delete the caller's file
 * from %INC so the log is re-opened
 */
static void inc_delete(void *data)
{
    SV *file = (SV*)data;
    /*fprintf(stderr, "removing %s from INC\n", SvPV(file,na));*/
    (void)hv_delete_ent(GvHV(incgv), file, G_DISCARD, FALSE);
    SvREFCNT_dec(file);
}

static void mark_for_inc_delete(SV *file)
{
    pool *p = perl_get_startup_pool();
    if(!p) croak("can't get startup pool!");

    register_cleanup(p, (void*)SvREFCNT_inc(file), 
		     inc_delete, inc_delete);
}

MODULE = Apache::LogFile		PACKAGE = Apache::LogFile		
Apache::LogFile
_new(self, file)
    SV *self
    char *file

    PREINIT:
    pool *p = perl_get_startup_pool();

    CODE:
    if(!p) croak("can't get startup pool!");

    RETVAL = (config_log_state *)palloc(p, sizeof(config_log_state));
    RETVAL->fname = file;
 
    if (*RETVAL->fname == '|') {
        char *pname = server_root_relative(p, (RETVAL->fname+1));
        piped_log *pl = open_piped_log(p, pname);
        if(pl == NULL) croak("can't open piped log `%s'", pname);
        RETVAL->log_fd = piped_log_write_fd(pl);
    }
    else {
        char *fname = server_root_relative(p, RETVAL->fname);
        if ((RETVAL->log_fd = popenf(p, fname, xfer_flags, xfer_mode)) < 0) {
            fprintf(stderr, "Apache::LogFile: could not open log file %s.\n",
                    fname);
            exit(1);
        }
    }

    OUTPUT:
    RETVAL

int
print(self, ...)
    Apache::LogFile self

    ALIAS:
    Apache::LogFile::PRINT = 1

    PREINIT:
    int i;
    STRLEN len;
    char *str;

    CODE:
    for(i=1; i<items; i++) {
        str = SvPV(ST(i),len);
        RETVAL += write(self->log_fd, str, len);
    }
    if(*(SvEND(ST(i-1)) - 1) != '\n')
        RETVAL += write(self->log_fd, "\n", 1);

    OUTPUT:
    RETVAL

void
mark_for_inc_delete(file)
    SV *file

