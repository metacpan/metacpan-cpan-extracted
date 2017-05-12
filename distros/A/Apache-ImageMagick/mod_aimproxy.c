/*
##--------------------------------------------------------------------------
##
##  Copyright (c) 2001 Gerald Richter / ecos gmbh www.ecos.de
##
##  You may distribute under the terms of either the GNU General Public 
##  License or the Artistic License, as specified in the Perl README file.
## 
##  THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
##  WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
##  MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
##
##  $Id: mod_aimproxy.c,v 1.1 2001/08/13 06:26:24 richter Exp $
##
##--------------------------------------------------------------------------
*/


#include "httpd.h"
#include "http_config.h"
#include "http_core.h"
#include "http_request.h"
#include "util_md5.h"



static void *aimproxySrvConfig(pool *p, char *d) ;
static const char * aimproxyCmdCacheDir(cmd_parms *cmd, void *config, char *val) ;
static const char * aimproxyCmdProxyPass(cmd_parms *cmd, void *config, char *val1, char * val2) ;
static int aimproxyHandler (request_rec *r) ;


    /* the table of commands we provide */
static const command_rec command_table[] = {
    { "AIMCacheDir",   aimproxyCmdCacheDir,   NULL, RSRC_CONF, TAKE1,
      "Gives the cache directory for Apache::ImageMagick Proxy" },
    { "AIMProxyPassTo",   aimproxyCmdProxyPass,   NULL, RSRC_CONF, TAKE2,
      "Gives the destination host for images not cached" },
};


    /* the main config structure */
module MODULE_VAR_EXPORT aimproxy_module = {
   STANDARD_MODULE_STUFF,
   NULL,                        /* module initializer                  */
   NULL,			/* create per-dir    config structures */
   NULL,			/* merge  per-dir    config structures */
   aimproxySrvConfig,		/* create per-server config structures */
   NULL,			/* merge  per-server config structures */
   command_table,               /* table of config file commands       */
   NULL,                        /* [#8] MIME-typed-dispatched handlers */
   NULL,                        /* [#1] URI to filename translation    */
   NULL,                        /* [#4] validate user id from request  */
   NULL,                        /* [#5] check if the user is ok _here_ */
   NULL,                        /* [#3] check access by host address   */
   NULL,                        /* [#6] determine MIME type            */
   aimproxyHandler,             /* [#7] pre-run fixups                 */
   NULL,                        /* [#9] log a transaction              */
   NULL,                        /* [#2] header parser                  */
   NULL,                        /* child_init                          */
   NULL,                        /* child_exit                          */
   NULL                         /* [#0] post read-request              */
};


struct aimconfig
    {
    char * cachedir ;
    array_header * pass ;
    } ;

struct aimpass
    {
    char * proxysrc ;
    int    proxysrclen ;
    char * proxyhost ;
    } ;

typedef struct aimconfig aimconfig ;
typedef struct aimpass aimpass ;


static int aimproxyHandler (request_rec *r)
    {
    char * args ;
    char * path_info ;
    char * file ;
    char * uri ;
    char * md5 ;
    char * ext ;
    char * cachefn  ;
    char * cachedir  ;
    char * cachepath  ;
    aimconfig * c ;
    struct stat finfo ;
    int i, len;
    int n ;
    aimpass *ent ;
    int found = 0 ;
    char * proxyhost ;

    if (r->proxyreq != NOT_PROXY) 
	{ /* someone has already set up the proxy */
	return DECLINED ;
	}

    c = (aimconfig *) ap_get_module_config(r->server->module_config, &aimproxy_module);
    
    ent = (aimpass *) c->pass->elts;
    uri  = r -> uri ;
    n    = c -> pass -> nelts ;
    for (i = 0; i < n; i++) 
	{
        if (strncmp (uri, ent[i].proxysrc, ent[i].proxysrclen) == 0)
	    {
	    /*fprintf(stderr, "found %s -> %s\n" , ent[i].proxysrc, ent[i].proxyhost) ;*/
	    found = 1 ;
	    break ;
	    }
	}

    if (!found)
	{
        /*fprintf(stderr, "aimproxy not found %s\n" , uri) ;*/
	return DECLINED ; /* is not our request */
	}
    proxyhost = ent[i].proxyhost ;

    args = r -> args ;
    path_info = r -> path_info ;

    /* If the file exists and there are no transformation arguments
       just decline the transaction.  It will be handled as usual. */
    /*fprintf(stderr, "uri %s  args %s  path_info %s\n" , uri, args, path_info) ;*/
    /*fprintf(stderr, "r -> finfo.st_mode %d\n" , r -> finfo.st_mode) ;*/
    if ((!args || !*args) && (!path_info || !*path_info) && r -> finfo.st_mode)  
	return DECLINED ;

    /* calculate name of cache file */
    file = r->filename;
    md5  = ap_md5 (r -> pool, ap_pstrcat (r -> pool, uri, args, NULL)) ;
    ext  = strchr (file, '.') ;
    if (ext)
	ext++ ;
    else
	ext = "" ;
    cachefn = ap_pstrcat (r -> pool, md5, ".", ext, NULL) ;
    /*fprintf(stderr, "cachefn = %s\n" , cachefn) ;*/
    cachedir  = c -> cachedir ;
    cachepath = ap_pstrcat (r -> pool, cachedir, "/", cachefn, NULL) ;
    
    /*fprintf(stderr, "cachepath = %s\n" , cachepath) ;*/
    if (stat (cachepath, &finfo) == 0)
        { /* let apache do the rest if image already exists */
        r -> filename = cachepath ;
        r -> path_info = "" ;
        memcpy (&r -> finfo, &finfo, sizeof (r -> finfo)) ;
	return OK ;
        }

   /* otherwise send it to the backend */

   r->filename = ap_pstrcat(r->pool, "proxy:http://", proxyhost, r-> uri, NULL);
   r->handler = "proxy-server";
   r->proxyreq = PROXY_PASS;

   /*fprintf(stderr, "proxy to = %s\n" , r->filename) ;*/

   return OK;
   }



static void *aimproxySrvConfig(pool *p, char *d)
    {
    aimconfig *rec = (aimconfig *) ap_pcalloc(p, sizeof(aimconfig));
    memset (rec, 0, sizeof(aimconfig)) ;
    rec->pass = ap_make_array(p, 10, sizeof(aimpass));
    return rec;
    }


static const char * aimproxyCmdCacheDir(cmd_parms *cmd, void *config, char *val)
    {
    server_rec *s = cmd->server;
    aimconfig * c = (aimconfig *) ap_get_module_config(s->module_config, &aimproxy_module);

    c -> cachedir = val ;

    return NULL;
    }


static const char * aimproxyCmdProxyPass(cmd_parms *cmd, void *config, char *val1, char * val2)
    {
    server_rec *s = cmd->server;
    aimconfig * c = (aimconfig *) ap_get_module_config(s->module_config, &aimproxy_module);
    aimpass *   p = (aimpass *)ap_push_array(c->pass);
    p -> proxyhost = val2 ;
    p -> proxysrc  = val1 ;
    p -> proxysrclen = strlen (p -> proxysrc) ;

    return NULL;
    }


