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

/* $Id: Module.xs,v 1.2 1998/10/23 00:13:57 dougm Exp $ */
#include "modules/perl/mod_perl.h"

typedef int (*handler_func) (request_rec *);
extern module *top_module;

XS(XS_Apache__Module_handler_dispatch)
{
    dXSARGS;
    request_rec *r = sv2request_rec(ST(0), "Apache", cv);
    int result;
    handler_func handler = (handler_func) CvXSUBANY(cv).any_ptr;

    result = (*handler)(r);

    ST(0) = sv_2mortal(newSViv(result));

    XSRETURN(1);
}

static CV *install_method(char *name, void *any)
{
    CV *cv = newXS(name, XS_Apache__Module_handler_dispatch, __FILE__);
    CvXSUBANY(cv).any_ptr = any;
    return cv;
}

static SV *handler2cv(handler_func fp)
{
    CV *meth;
    SV *RETVAL = Nullsv;

    if(fp) {
	meth = install_method(NULL, (void*)fp);
        RETVAL = newRV_noinc((SV*)meth);
    }
    
    return RETVAL;
}

#define handler2cvrv(fp) \
    if(!(RETVAL = handler2cv(fp))) XSRETURN_UNDEF

#define member_boolean(thing) \
    RETVAL = (thing) ? TRUE : FALSE

#define member_member(thing) \
    if(!(RETVAL = (thing))) XSRETURN_UNDEF

MODULE = Apache::Module		PACKAGE = Apache::Module	PREFIX=ap_

INCLUDE: handlers.xsubs


Apache::Module
top_module(class)
    SV *class

    CODE:
    RETVAL = top_module;

    OUTPUT:
    RETVAL

void
add(modp)
    Apache::Module modp

    CODE:
    ap_add_module(modp);

void
remove(modp)
    Apache::Module modp

    CODE:
    ap_remove_module(modp);

Apache::Module
next(modp)
    Apache::Module modp

    CODE:
    RETVAL = modp->next;

    OUTPUT:
    RETVAL

const char *
name(modp)
    Apache::Module modp

    CODE:
    RETVAL = modp->name;

    OUTPUT:
    RETVAL

Apache::Handler
handlers(modp)
    Apache::Module modp

    CODE:
    if(modp->handlers)
        RETVAL = (Apache__Handler)modp->handlers;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

Apache::Command
cmds(modp)
    Apache::Module modp

    CODE:
    if(modp->cmds)
        RETVAL = (Apache__Command)modp->cmds;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

MODULE = Apache::Module		PACKAGE = Apache::Handler

const char *
content_type(hand)
    Apache::Handler hand

    CODE:
    if(hand && hand->content_type) 
        RETVAL = hand->content_type;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

SV *
handler(hand)
    Apache::Handler hand

    CODE:
    handler2cvrv(hand->handler);

    OUTPUT:
    RETVAL

Apache::Handler
next(hand)
    Apache::Handler hand

    CODE:
    hand++;
    if(hand && hand->content_type)
        RETVAL = hand;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

MODULE = Apache::Module		PACKAGE = Apache::Command

Apache::Command
find(cmd, name)
    Apache::Command cmd
    char *name

    CODE:
    while (cmd->name) {
	if (strEQ(name, cmd->name)) {
	    RETVAL = cmd;
	    break;
	}
	else 
	    ++cmd;
    }

    if(!(RETVAL = cmd)) 
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

Apache::Command
next(cmd)
    Apache::Command cmd

    CODE:
    cmd++;
    if(cmd && cmd->name)
        RETVAL = cmd;
    else
        XSRETURN_UNDEF;

    OUTPUT:
    RETVAL

const char *
name(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = cmd->name;

    OUTPUT:
    RETVAL

const char *
errmsg(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = cmd->errmsg;

    OUTPUT:
    RETVAL

int
req_override(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = cmd->req_override; 

    OUTPUT:
    RETVAL

SV *
args_how(cmd)
    Apache::Command cmd

    CODE:
    RETVAL = newSV(0);

    sv_setnv(RETVAL, (double)cmd->args_how); 

    switch(cmd->args_how) {
    case RAW_ARGS:
	sv_setpv(RETVAL, "RAW_ARGS");
        break;
    case TAKE1:
	sv_setpv(RETVAL, "TAKE1");
        break;
    case TAKE2:
	sv_setpv(RETVAL, "TAKE2");
        break;
    case ITERATE:
	sv_setpv(RETVAL, "ITERATE");
        break;
    case ITERATE2:
	sv_setpv(RETVAL, "ITERATE2");
        break;
    case FLAG:
	sv_setpv(RETVAL, "FLAG");
        break;
    case NO_ARGS:
	sv_setpv(RETVAL, "NO_ARGS");
        break;
    case TAKE12:
	sv_setpv(RETVAL, "TAKE12");
        break;
    case TAKE3:
	sv_setpv(RETVAL, "TAKE3");
        break;
    case TAKE23:
	sv_setpv(RETVAL, "TAKE23");
        break;
    case TAKE123:
	sv_setpv(RETVAL, "TAKE123");
        break;
    case TAKE13:
	sv_setpv(RETVAL, "TAKE13");
        break;
    default:
	sv_setpv(RETVAL, "__UNKNOWN__");
        break;
    };

    SvNOK_on(RETVAL); /* ah, magic */ 

    OUTPUT:
    RETVAL
