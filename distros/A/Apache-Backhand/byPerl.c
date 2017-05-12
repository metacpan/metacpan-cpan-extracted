/* ====================================================================
 * Copyright (c) 2000 David Lowe.
 * 
 * byPerl.c
 *
 * Defines the byPerl function.
 * ==================================================================== */

/* apache headers */
#include "httpd.h"
#include "http_log.h"

/* mod_backhand header */
#include "mod_backhand.h"

/* perl headers */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"

/* This is part of mod_perl - linking will fail if mod_perl isn't present! */
extern SV *perl_bless_request_rec(request_rec *r);


/* ====================================================================
 * NAME:          byPerl
 *
 * DESCRIPTION:   This function is responsible for translating Backhand
 *                byPerl requests into perl function calls, and then
 *                translating the results back into what mod_backhand
 *                expects.
 *
 * RETURN VALUES: the number of servers left in the server list
 *
 * BUGS:          Hopefully none.
 * ==================================================================== */
int
byPerl(request_rec *r, ServerSlot *servers, int *n, char *arg) {
    int count, i;
    AV *tservers = newAV();
    SV *outref;
    dSP;

    if (arg == NULL) {
        ap_log_error(APLOG_MARK, APLOG_NOERRNO|APLOG_ERR, NULL,
                     "byPerl: I don't know what you want me to do.");
        return *n;
    }
    

    /*  This is the way we call the function,
     *  call the function,
     *  call the function.
     *  This is the way we call the function,
     *  early in the morn.
     */
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* "Borrow" mod_perl's request_rec -> blessed Apache reference function */
    XPUSHs(perl_bless_request_rec(r));

    /* Push everything else onto the stack as an array reference */
    for (i = 0; i < *n; i++) {
        av_push(tservers, newSViv(servers[i].id));
    }
    XPUSHs(sv_2mortal(newRV((SV *)tservers)));

    PUTBACK;

    /* actually call the function */
    perl_call_pv(arg, G_SCALAR|G_EVAL);
    SPAGAIN;

    /* Check for errors (most likely being that the function didn't exist) */
    if (SvTRUE(ERRSV)) {
        ap_log_error(APLOG_MARK, APLOG_NOERRNO|APLOG_ERR, NULL,
                     "byPerl: %s", SvPV(ERRSV, PL_na));
        return *n;
    }

    /* Store the output */
    outref = POPs;

    if ((outref == &PL_sv_undef) || (! SvROK(outref))) {
        ap_log_error(APLOG_MARK, APLOG_NOERRNO|APLOG_ERR, NULL,
                     "byPerl: confusing return from candidacy function");
        PUTBACK;
        FREETMPS;
        LEAVE;
        return *n;
    } else {
        /* Turn the output into something usable */
        AV *a = (AV *)SvRV(outref);

        if (av_len(a) == -1) {
            *n = 0;
            return 0;
        }
        for (i = 0; i <= av_len(a); i++) {
            servers[i].id = SvIV(*(av_fetch(a, i, FALSE)));
        }
        count = av_len(a) + 1;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    *n = count;
    return count;
}
