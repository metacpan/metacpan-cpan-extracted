/* ====================================================================
 * Copyright (c) 1995-1999 The Apache Group.  All rights reserved.
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
 *    prior written permission. For written permission, please contact
 *    apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache"
 *    nor may "Apache" appear in their names without prior written
 *    permission of the Apache Group.
 *
 * 6. Redistributions of any form whatsoever must retain the following
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

#include "mod_icon.h"

struct icon_item {
    char *type;
    char *apply_to;
    char *apply_path;
    char *data;
};

static char c_by_encoding, c_by_type, c_by_path;

#define BY_ENCODING &c_by_encoding
#define BY_TYPE &c_by_type
#define BY_PATH &c_by_path

#define dICON \
    icon_dir_config *d = (icon_dir_config *) \
	ap_get_module_config(r->per_dir_config, &icon_module)

#define sICON \
    icon_srv_config *s = (icon_srv_config *) \
	ap_get_module_config(parms->server->module_config, &icon_module)

static void push_item(array_header *arr, char *type, char *to, char *path,
		      char *data)
{
    struct icon_item *p = (struct icon_item *) ap_push_array(arr);

    if (!to) {
	to = "";
    }
    if (!path) {
	path = "";
    }

    p->type = type;
    p->data = data ? ap_pstrdup(arr->pool, data) : NULL;
    p->apply_path = ap_pstrcat(arr->pool, path, "*", NULL);

    if ((type == BY_PATH) && (!ap_is_matchexp(to))) {
	p->apply_to = ap_pstrcat(arr->pool, "*", to, NULL);
    }
    else if (to) {
	p->apply_to = ap_pstrdup(arr->pool, to);
    }
    else {
	p->apply_to = NULL;
    }
}

static const char *add_alt(cmd_parms *cmd, void *d, char *alt, char *to)
{
    if (cmd->info == BY_PATH) {
        if (!strcmp(to, "**DIRECTORY**")) {
	    to = "^^DIRECTORY^^";
	}
    }
    if (cmd->info == BY_ENCODING) {
	ap_str_tolower(to);
    }

    push_item(((icon_dir_config *) d)->alt_list, cmd->info, to,
	      cmd->path, alt);
    return NULL;
}

static const char *add_icon(cmd_parms *cmd, void *d, char *icon, char *to)
{
    char *iconbak = ap_pstrdup(cmd->pool, icon);

    if (icon[0] == '(') {
	char *alt;
	char *cl = strchr(iconbak, ')');

	if (cl == NULL) {
	    return "missing closing paren";
	}
	alt = ap_getword_nc(cmd->pool, &iconbak, ',');
	*cl = '\0';				/* Lose closing paren */
	add_alt(cmd, d, &alt[1], to);
    }
    if (cmd->info == BY_PATH) {
        if (!strcmp(to, "**DIRECTORY**")) {
	    to = "^^DIRECTORY^^";
	}
    }
    if (cmd->info == BY_ENCODING) {
	ap_str_tolower(to);
    }

    push_item(((icon_dir_config *) d)->icon_list, cmd->info, to,
	      cmd->path, iconbak);
    return NULL;
}

typedef const char * (*iter2_func) 
    (cmd_parms *c, void *d, char *a, char *b);

static const char *add_raw(cmd_parms *parms, void *d, const char *args, iter2_func fp)
{
    char *w, *w2;
    const char *errmsg;
    const command_rec *cmd = parms->cmd;

    w = ap_getword_conf(parms->pool, &args);

    if (*w == '\0' || *args == 0) {
	return ap_pstrcat(parms->pool, cmd->name,
			    " requires at least two arguments",
			    cmd->errmsg ? ", " : NULL, cmd->errmsg, NULL);
    }

    while (*(w2 = ap_getword_conf(parms->pool, &args)) != '\0') {
	if ((errmsg = (*fp)(parms, d, w, w2))) {
	    return errmsg;
	}
    }

    return NULL;
}

static const char *add_icon_raw(cmd_parms *parms, void *d, char *args)
{
    sICON;
    const char *retval = add_raw(parms, d, args, add_icon);
    return s->decline_cmd ? DECLINE_CMD : retval;
}

static const char *add_alt_raw(cmd_parms *parms, void *d, char *args)
{
    sICON;
    const char *retval = add_raw(parms, d, args, add_alt);
    return s->decline_cmd ? DECLINE_CMD : retval;
}

static const char *set_default_icon(cmd_parms *parms, void *d, char *arg)
{
    sICON;
    ((icon_dir_config *)d)->default_icon = ap_pstrdup(parms->pool, arg);
    return s->decline_cmd ? DECLINE_CMD : NULL;
}

static const char *set_double_icon(cmd_parms *parms, void *d, int arg)
{
    sICON;
    s->decline_cmd = arg;
    return NULL;
}

#define DIR_CMD_PERMS OR_INDEXES

static const command_rec icon_cmds[] =
{
    {"AddIcon", add_icon_raw, BY_PATH, DIR_CMD_PERMS, RAW_ARGS,
     "an icon URL followed by one or more filenames"},
    {"AddIconByType", add_icon_raw, BY_TYPE, DIR_CMD_PERMS, RAW_ARGS,
     "an icon URL followed by one or more MIME types"},
    {"AddIconByEncoding", add_icon_raw, BY_ENCODING, DIR_CMD_PERMS, RAW_ARGS,
     "an icon URL followed by one or more content encodings"},
    {"AddAlt", add_alt_raw, BY_PATH, DIR_CMD_PERMS, RAW_ARGS,
     "alternate descriptive text followed by one or more filenames"},
    {"AddAltByType", add_alt_raw, BY_TYPE, DIR_CMD_PERMS, RAW_ARGS,
     "alternate descriptive text followed by one or more MIME types"},
    {"AddAltByEncoding", add_alt_raw, BY_ENCODING, DIR_CMD_PERMS, RAW_ARGS,
     "alternate descriptive text followed by one or more content encodings"},
    {"DefaultIcon", set_default_icon,
     NULL,
     DIR_CMD_PERMS, TAKE1, "an icon URL"},
    {"IconDouble", set_double_icon,
     NULL,
     RSRC_CONF, FLAG, "On or Off"},
    {NULL}
};

static void *create_icon_srv_config(pool *p, server_rec *s)
{
    icon_srv_config *new =
	(icon_srv_config *) ap_pcalloc(p, sizeof(icon_srv_config));

    new->decline_cmd = ap_find_linked_module("mod_autoindex.c") ? 1 : 0;

    return (void *) new;
}

static void *create_icon_dir_config(pool *p, char *dummy)
{
    icon_dir_config *new =
    (icon_dir_config *) ap_pcalloc(p, sizeof(icon_dir_config));

    new->icon_list = ap_make_array(p, 4, sizeof(struct icon_item));
    new->alt_list = ap_make_array(p, 4, sizeof(struct icon_item));

    return (void *) new;
}

static void *merge_icon_dir_configs(pool *p, void *basev, void *addv)
{
    icon_dir_config *new;
    icon_dir_config *base = (icon_dir_config *) basev;
    icon_dir_config *add = (icon_dir_config *) addv;

    new = (icon_dir_config *) ap_pcalloc(p, sizeof(icon_dir_config));
    new->default_icon = add->default_icon ? add->default_icon
                                          : base->default_icon;

    new->alt_list = ap_append_arrays(p, add->alt_list, base->alt_list);
    new->icon_list = ap_append_arrays(p, add->icon_list, base->icon_list);

    return new;
}

static char *find_item(request_rec *r, array_header *list, int path_only)
{
    const char *content_type = r->content_type;
    const char *content_encoding = r->content_encoding;
    char *path = r->filename;

    struct icon_item *items = (struct icon_item *) list->elts;
    int i;

    for (i = 0; i < list->nelts; ++i) {
	struct icon_item *p = &items[i];

	/* Special cased for ^^DIRECTORY^^ and ^^BLANKICON^^ */
	if ((path[0] == '^') || (!ap_strcmp_match(path, p->apply_path))) {
	    if (!*(p->apply_to)) {
		return p->data;
	    }
	    else if (p->type == BY_PATH || path[0] == '^') {
	        if (!ap_strcmp_match(path, p->apply_to)) {
		    return p->data;
		}
	    }
	    else if (!path_only) {
		if (!content_encoding) {
		    if (p->type == BY_TYPE) {
			if (content_type
			    && !ap_strcasecmp_match(content_type,
						    p->apply_to)) {
			    return p->data;
			}
		    }
		}
		else {
		    if (p->type == BY_ENCODING) {
			if (!ap_strcasecmp_match(content_encoding,
						 p->apply_to)) {
			    return p->data;
			}
		    }
		}
	    }
	}
    }
    return NULL;
}

char *ap_icon_default(request_rec *r, char *name)
{
    dICON;
    request_rec rr;

    if (!name) {
	return d->default_icon;
    }

    rr.filename = name;
    rr.content_type = rr.content_encoding = NULL;

    return find_item(&rr, d->icon_list, 1);
}

char *ap_icon_find(request_rec *r, int path_only)
{
    dICON;
    return find_item(r, d->icon_list, path_only);
}

char *ap_icon_alt(request_rec *r, int path_only)
{
    dICON;
    return find_item(r, d->alt_list, path_only);
}

module MODULE_VAR_EXPORT icon_module =
{
    STANDARD_MODULE_STUFF,
    NULL,			/* initializer */
    create_icon_dir_config,	/* dir config creater */
    merge_icon_dir_configs,	/* dir merger --- default is to override */
    create_icon_srv_config,	/* server config */
    NULL,			/* merge server config */
    icon_cmds,		/* command table */
    NULL,		/* handlers */
    NULL,			/* filename translation */
    NULL,			/* check_user_id */
    NULL,			/* check auth */
    NULL,			/* check access */
    NULL,			/* type_checker */
    NULL,			/* fixups */
    NULL,			/* logger */
    NULL,			/* header parser */
    NULL,			/* child_init */
    NULL,			/* child_exit */
    NULL			/* post read-request */
};
