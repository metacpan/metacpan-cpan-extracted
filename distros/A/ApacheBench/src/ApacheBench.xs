/* ====================================================================
 * Copyright (c) 1998-1999 The Apache Group.  All rights reserved.
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

/*
   ** This program is based on ZeusBench V1.0 written by Adam Twiss
   ** which is Copyright (c) 1996 by Zeus Technology Ltd. http://www.zeustech.net/
   **
   ** This software is provided "as is" and any express or implied waranties,
   ** including but not limited to, the implied warranties of merchantability and
   ** fitness for a particular purpose are disclaimed.  In no event shall
   ** Zeus Technology Ltd. be liable for any direct, indirect, incidental, special,
   ** exemplary, or consequential damaged (including, but not limited to,
   ** procurement of substitute good or services; loss of use, data, or profits;
   ** or business interruption) however caused and on theory of liability.  Whether
   ** in contract, strict liability or tort (including negligence or otherwise)
   ** arising in any way out of the use of this software, even if advised of the
   ** possibility of such damage.
   **
 */

/*
   ** HISTORY:
   **    - Originally written by Adam Twiss <adam@zeus.co.uk>, March 1996
   **      with input from Mike Belshe <mbelshe@netscape.com> and
   **      Michael Campanella <campanella@stevms.enet.dec.com>
   **    - Enhanced by Dean Gaudet <dgaudet@apache.org>, November 1997
   **    - Cleaned up by Ralf S. Engelschall <rse@apache.org>, March 1998
   **    - POST and verbosity by Kurt Sussman <kls@merlot.com>, August 1998
   **    - HTML table output added by David N. Welton <davidw@prosa.it>, January 1999
   **    - Added Cookie, Arbitrary header and auth support. <dirkx@webweaving.org>, April 1999
   **
   **    - CODE FORK: added Perl XS interface and is now released on CPAN as
   **      HTTPD::Bench::ApacheBench, September 2000
   **    - merged code from Apache 1.3.22 ab, October-November 2001
   **    - various refactors, rewrites, and improvements; see Changes
   **
 */

/*
 * BUGS:
 *
 * - uses strcpy/etc.
 * - has various other poor buffer attacks related to the lazy parsing of
 *   response headers from the server
 * - doesn't implement much of HTTP/1.x, only accepts certain forms of
 *   responses
 * - (performance problem) heavy use of strstr shows up top in profile
 *   only an issue for loopback usage
 */

/*  ------------------ DEBUGGING --------------------------------------- */

// uncomment to turn on debugging messages
//#define AB_DEBUG 1

/*  -------------------------------------------------------------------- */

#ifdef AB_DEBUG
#define AB_DEBUG_XS 1
#else
#define AB_DEBUG_XS 0
#endif

/* XS library */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* ApacheBench source code */
#include "apachebench/util.c"
#include "apachebench/xs_util.c"
#include "apachebench/http_util.c"
#include "apachebench/socket_io.c"
#include "apachebench/execute.c"
#include "apachebench/regression_data.c"

/* ------------------- MACROS -------------------------- */
#define ap_min(a,b) ((a)<(b))?(a):(b)
#define ap_max(a,b) ((a)>(b))?(a):(b)


MODULE = HTTPD::Bench::ApacheBench	PACKAGE = HTTPD::Bench::ApacheBench
PROTOTYPES: ENABLE

HV *
ab(input_hash)
    SV * input_hash;

    PREINIT:
    char *pt,**url_keys;
    int i,j,k,arrlen,arrlen2;
    int def_buffersize; /* default buffersize for all runs */
    int def_repeat; /* default number of repeats if unspecified in runs */
    int def_memory; /* default memory setting if unspecified in runs */
    bool def_keepalive = 0; /* default keepalive setting */
    struct global *registry = calloc(1, sizeof(struct global));
    int total_started = 0, total_good = 0, total_failed = 0;

    CODE:
    SV * runs;
    SV * urls = 0;
    SV * post_data = 0;
    SV * head_requests = 0;
    SV * cookies = 0;
    SV * ctypes = 0;
    SV * req_headers = 0;
    SV * keepalive = 0;
    SV * url_tlimits = 0;
    AV * run_group, *tmpav, *tmpav2;
    SV * tmpsv, *tmpsv2 = 0, *tmpsv3;
    HV * tmphv;
    STRLEN len;

    if (AB_DEBUG_XS) printf("AB_DEBUG: start of ab()\n");

    registry->concurrency = 1;
    registry->requests = 0;
    registry->tlimit = 0;
    registry->min_tlimit.tv_sec = 30;
    registry->min_tlimit.tv_usec = 0;
    registry->tail = 0;
    registry->done = 0;
    registry->need_to_be_done = 0;
    strcpy(registry->version, VERSION);
    strcpy(registry->warn_and_error, "\nWarning messages from ab():");
    registry->total_bytes_received = 0;
    registry->number_of_urls = 0;


    /*Get necessary initial information and initialize*/
    tmphv = (HV *)SvRV(input_hash);

    tmpsv = *(hv_fetch(tmphv, "concurrency", 11, 0));
    registry->concurrency = SvIV(tmpsv);

    tmpsv = *(hv_fetch(tmphv, "timelimit", 9, 0));
    if (SvOK(tmpsv)) {
        registry->tlimit = SvNV(tmpsv);
        registry->min_tlimit =
            double2timeval(ap_min(timeval2double(registry->min_tlimit),
                                  registry->tlimit));
    }

    tmpsv = *(hv_fetch(tmphv, "buffersize", 10, 0));
    def_buffersize = SvIV(tmpsv);

    tmpsv = *(hv_fetch(tmphv, "repeat", 6, 0));
    def_repeat = SvIV(tmpsv);

    tmpsv = *(hv_fetch(tmphv, "memory", 6, 0));
    def_memory = SvIV(tmpsv);

    if (AB_DEBUG_XS) printf("AB_DEBUG: ab() init - stage 1\n");

    tmpsv = *(hv_fetch(tmphv, "keepalive", 9, 0));
    if (SvTRUE(tmpsv))
        def_keepalive = 1;

    if (AB_DEBUG_XS) printf("AB_DEBUG: ab() init - stage 2\n");

    tmpsv = *(hv_fetch(tmphv, "priority", 8, 0));
    pt = SvPV(tmpsv, len);
    if (strcmp(pt, "run_priority") == 0)
        registry->priority = RUN_PRIORITY;
    else {
        registry->priority = EQUAL_OPPORTUNITY;
        if (strcmp(pt, "equal_opportunity") != 0)
            myerr(registry->warn_and_error, "Unknown priority value (the only possible priorities are run_priority and equal_opportunity), using default: equal_opportunity");
    }

    if (AB_DEBUG_XS) printf("AB_DEBUG: ab() init - stage 3\n");

    runs = *(hv_fetch(tmphv, "runs", 4, 0));
    run_group = (AV *)SvRV(runs);
    registry->number_of_runs = av_len(run_group) + 1;

    registry->order = malloc(registry->number_of_runs * sizeof(int));
    registry->repeats = malloc(registry->number_of_runs * sizeof(int));
    registry->position = malloc((registry->number_of_runs+1) * sizeof(int));
    registry->memory = malloc(registry->number_of_runs * sizeof(int));
    registry->use_auto_cookies = malloc(registry->number_of_runs * sizeof(bool));

    if (AB_DEBUG_XS) printf("AB_DEBUG: done with ab() initialization\n");

    for (i = 0,j = 0; i < registry->number_of_runs; i++) {
        if (AB_DEBUG_XS) printf("AB_DEBUG: starting run %d setup\n", i);

        tmpsv = *(av_fetch(run_group, i, 0));

        if (SvROK(tmpsv))
            tmphv = (HV *)SvRV(tmpsv);

        registry->memory[i] = def_memory;
        if (hv_exists(tmphv, "memory", 6)) {
            tmpsv = *(hv_fetch(tmphv, "memory", 6, 0));
            registry->memory[i] = SvIV(tmpsv);
        }

        registry->repeats[i] = def_repeat;
        if (hv_exists(tmphv, "repeat", 6)) {
            /* Number of requests to make */
            tmpsv = *(hv_fetch(tmphv, "repeat", 6, 0));
            registry->repeats[i] = SvIV(tmpsv);
        }

        registry->use_auto_cookies[i] = 1;
        if (hv_exists(tmphv, "use_auto_cookies", 16)) {
            tmpsv = *(hv_fetch(tmphv, "use_auto_cookies", 16, 0));
            registry->use_auto_cookies[i] = SvTRUE(tmpsv) ? 1 : 0;
        }

        registry->requests = ap_max(registry->requests, registry->repeats[i]);

        urls = *(hv_fetch(tmphv, "urls", 4, 0));
        tmpav = (AV *) SvRV(urls);
        registry->position[i] = registry->number_of_urls;
        registry->number_of_urls += av_len(tmpav) + 1;

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d: position[%d] == %d\n", i, i, registry->position[i]);

        if (hv_exists(tmphv, "order", 5)) {
            tmpsv = *(hv_fetch(tmphv, "order", 5, 0));
            pt = SvPV(tmpsv, len);
            if (strcmp(pt, "depth_first") == 0) {
                registry->order[i] = DEPTH_FIRST;
                j += 1;
            } else if (strcmp(pt, "breadth_first") == 0) {
                registry->order[i] = BREADTH_FIRST;
                j += registry->repeats[i];
            } else {
                myerr(registry->warn_and_error, "invalid order: order can only be depth_first or breadth_first");
                registry->order[i] = BREADTH_FIRST;
                j += registry->repeats[i];
            }
        } else {
            registry->order[i] = BREADTH_FIRST;
            j += registry->repeats[i];
        }
    }
    if (registry->number_of_urls <= 0) {
        myerr(registry->warn_and_error, "No urls.");
        return;
    }
    registry->position[registry->number_of_runs] = registry->number_of_urls;
    registry->concurrency = ap_min(registry->concurrency, j);

    if (AB_DEBUG_XS) printf("AB_DEBUG: set all run info, ready to call initialize()\n");

    initialize(registry);

    url_keys = malloc(registry->number_of_urls * sizeof(char *));

    for (k = 0; k < registry->number_of_runs; k++) {
        if (AB_DEBUG_XS) printf("AB_DEBUG: starting run %d setup2 - postdata + cookie\n", k);

        registry->buffersize[k] = def_buffersize;
        tmpsv = *(av_fetch(run_group, k, 0));
        if (SvROK(tmpsv)) {
            tmphv = (HV *)SvRV(tmpsv);
            if (hv_exists(tmphv, "buffersize", 10)) {
                tmpsv = *(hv_fetch(tmphv, "buffersize", 10, 0));
                registry->buffersize[k] = SvIV(tmpsv);
            }
        }

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 1\n", k);

        /* error checking: make sure all of the run specific hashkeys exist */
        if (hv_exists(tmphv, "urls", 4))
            urls = *(hv_fetch(tmphv, "urls", 4, 0));
        if (hv_exists(tmphv, "postdata", 8))
            post_data = *(hv_fetch(tmphv, "postdata", 8, 0));
        if (hv_exists(tmphv, "head_requests", 13))
            head_requests = *(hv_fetch(tmphv, "head_requests", 13, 0));
        if (hv_exists(tmphv, "cookies", 7))
            cookies = *(hv_fetch(tmphv, "cookies", 7, 0));
        if (hv_exists(tmphv, "content_types", 13))
            ctypes = *(hv_fetch(tmphv, "content_types", 13, 0));
        if (hv_exists(tmphv, "request_headers", 15))
            req_headers = *(hv_fetch(tmphv, "request_headers", 15, 0));
        if (hv_exists(tmphv, "keepalive", 9))
            keepalive = *(hv_fetch(tmphv, "keepalive", 9, 0));
        if (hv_exists(tmphv, "timelimits", 10))
            url_tlimits = *(hv_fetch(tmphv, "timelimits", 10, 0));

        /* configure urls */
        for (i = registry->position[k]; i < registry->position[k+1]; i++) {
            tmpav =(AV *) SvRV(urls);
            tmpsv = *(av_fetch(tmpav, i - registry->position[k], 0));
            if (SvPOK(tmpsv)) {
                pt = SvPV(tmpsv, len);
                url_keys[i] = pt;

                if (parse_url(registry, pt, i)) {
                    char *warn = malloc(CBUFFSIZE * sizeof(char));
                    sprintf(warn, "Invalid url: %s, the information for this url may be wrong", pt);
                    myerr(registry->warn_and_error, warn);
                    free(warn);
                }
            } else {
                myerr(registry->warn_and_error, "Undefined url in urls list");
            }
        }


        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2\n", k);

        tmpav = (AV *) SvRV(post_data);
        tmpav2 = (AV *) SvRV(head_requests);

        /* find smaller of post_data array length and urls array length */
        arrlen = av_len(tmpav);
        i = ap_min(registry->position[k+1],
                   registry->position[k] + arrlen + 1);

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.1\n", k);

        /* find larger of head_requests and post_data (to get the most data) */
        arrlen2 = av_len(tmpav2);
        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.1.1\n", k);
        i = ap_max(i, registry->position[k] + arrlen2 + 1);

        /* configure post_data or head_requests */
        for (j = registry->position[k]; j < i; j++) {
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.2, j=%d\n", k, j);
            if (j - registry->position[k] <= arrlen)
                tmpsv = *(av_fetch(tmpav, j - registry->position[k], 0));
            if (j - registry->position[k] <= arrlen2)
                tmpsv2 = *(av_fetch(tmpav2, j - registry->position[k], 0));
            if (j - registry->position[k] <= arrlen && (SvROK(tmpsv) || SvPOK(tmpsv))) {
                /* this url is a POST request */
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.3, j=%d\n", k, j);
                if (SvROK(tmpsv)) {
                    if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.4a, j=%d\n", k, j);
                    tmpsv3 = SvRV(tmpsv);
                    if (SvTYPE(tmpsv3) == SVt_PVCV) {
                        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.4a.i, j=%d\n", k, j);
                        registry->postsubs[j] = tmpsv3;
                        registry->posting[j] = 2;
                    }
                } else if (SvPOK(tmpsv)) {
                    if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.4b, j=%d\n", k, j);
                    pt = SvPV(tmpsv, len);
                    registry->postdata[j] = pt;
                    registry->postlen[j] = len;
                    registry->posting[j] = 1;
                }
            } else if (j - registry->position[k] <= arrlen2 && SvTRUE(tmpsv2))
                /* this url is a HEAD request */
                registry->posting[j] = -1;
            else
                registry->posting[j] = 0;
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.5, j=%d\n", k, j);
        }

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 2.6\n", k);

        /*If the number of postdata strings is less than
          that of urls, then assign empty strings to force GET requests*/
        for (j = i; j < registry->position[k+1]; j++)
            registry->posting[j] = 0;


        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 3\n", k);

        /* configure cookies */
        registry->cookie[k] = NULL;
        tmpav = (AV *) SvRV(cookies);
        if (av_len(tmpav) >= 0) {
            tmpsv = *(av_fetch(tmpav, 0, 0));
            if (SvPOK(tmpsv)) {
                pt = SvPV(tmpsv, len);
                if (len != 0) {
                    registry->cookie[k] = malloc((len+1) * sizeof(char));
                    strcpy(registry->cookie[k], pt);
                    if (AB_DEBUG_XS) printf("AB_DEBUG: cookie[%d] == '%s'\n", k, registry->cookie[k]);
                }
            }
        }


        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4\n", k);

        /* find smaller of req_headers array length and urls array length */
        tmpav = (AV *) SvRV(req_headers);
        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4.1\n", k);
        i = ap_min(registry->position[k+1],
                   registry->position[k] + av_len(tmpav) + 1);

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4.2\n", k);
        /* configure arbitrary request headers */
        for (j = registry->position[k]; j < i; j++) {
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4.3, j=%d\n", k, j);
            tmpsv = *(av_fetch(tmpav, j - registry->position[k], 0));
            if (SvPOK(tmpsv)) {
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4.4, j=%d\n", k, j);
                pt = SvPV(tmpsv, len);
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4.5, j=%d\n", k, j);
                registry->req_headers[j] = pt;
            } else
                registry->req_headers[j] = 0;
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 4.6, j=%d\n", k, j);
        }

        /*If the number of req_headers strings is less than
          that of urls, then assign NULL (undef) */
        for (j = i; j < registry->position[k+1]; j++)
            registry->req_headers[j] = 0;


        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 5\n", k);

        /* find smaller of ctypes array length and urls array length */
        tmpav = (AV *) SvRV(ctypes);
        i = ap_min(registry->position[k+1],
                   registry->position[k] + av_len(tmpav) + 1);

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 5.1\n", k);

        /* configure ctypes */
        for (j = registry->position[k]; j < i; j++) {
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 5.2, j=%d\n", k, j);
            tmpsv = *(av_fetch(tmpav, j - registry->position[k], 0));
            if (SvPOK(tmpsv)) {
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 5.3, j=%d\n", k, j);
                pt = SvPV(tmpsv, len);
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 5.4, j=%d\n", k, j);
                registry->ctypes[j] = pt;
            } else
                registry->ctypes[j] = 0;
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 5.5, j=%d\n", k, j);
        }

        /*If the number of ctypes strings is less than
          that of urls, then assign NULL (undef) */
        for (j = i; j < registry->position[k+1]; j++)
            registry->ctypes[j] = 0;


        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 6\n", k);

        /* find smaller of keepalive array length and urls array length */
        tmpav = (AV *) SvRV(keepalive);
        i = ap_min(registry->position[k+1],
                   registry->position[k] + av_len(tmpav) + 1);

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 6.1\n", k);

        /* configure keepalive */
        for (j = registry->position[k]; j < i; j++) {
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 6.2, j=%d\n", k, j);
            tmpsv = *(av_fetch(tmpav, j - registry->position[k], 0));
            if (SvOK(tmpsv))
                if (SvTRUE(tmpsv))
                    registry->keepalive[j] = 1;
                else
                    registry->keepalive[j] = 0;
            else
                registry->keepalive[j] = def_keepalive;
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 6.3, j=%d\n", k, j);
        }

        /*If the number of keepalive strings is less than
          that of urls, then assign object's default keepalive value */
        for (j = i; j < registry->position[k+1]; j++)
            registry->keepalive[j] = def_keepalive;


        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 7\n", k);

        /* find smaller of url_tlimits array length and urls array length */
        tmpav = (AV *) SvRV(url_tlimits);
        i = ap_min(registry->position[k+1],
                   registry->position[k] + av_len(tmpav) + 1);

        if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 7.1\n", k);

        /* configure url_tlimits */
        for (j = registry->position[k]; j < i; j++) {
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 7.2, j=%d\n", k, j);
            tmpsv = *(av_fetch(tmpav, j - registry->position[k], 0));
            if (SvOK(tmpsv)) {
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 7.3, j=%d\n", k, j);
                registry->url_tlimit[j] = SvNV(tmpsv);
                registry->min_tlimit =
                    double2timeval(ap_min(timeval2double(registry->min_tlimit),
                                          registry->url_tlimit[j]));
                if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 7.3.1, j=%d, url_tlimit=%.3f sec, min tlimit so far = %.3f sec\n", k, j, registry->url_tlimit[j], timeval2double(registry->min_tlimit));
            } else
                registry->url_tlimit[j] = 0;
            if (AB_DEBUG_XS) printf("AB_DEBUG: run %d setup2 - stage 7.4, j=%d\n", k, j);
        }

        /*If the number of url_tlimits is less than
          that of urls, then assign 0 for no time limit */
        for (j = i; j < registry->position[k+1]; j++)
            registry->url_tlimit[j] = 0;

    }

    if (AB_DEBUG_XS) printf("AB_DEBUG: ready to test()\n");

    test(registry);

    if (AB_DEBUG_XS) printf("AB_DEBUG: done with test()\n");

    RETVAL = newHV();/* ready to get information stored in global variables */

    for (k = 0; k < registry->number_of_runs; k++) {
        if (registry->memory[k] >= 1) {
            AV *started = newAV();/* number of started requests for each url */
            AV *good = newAV();   /* number of good responses for each url */
            AV *failed = newAV(); /* number of bad responses for each url */
            tmpav = newAV();      /* array to keep the thread information */

            if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression info for run %d\n", k);

            for (i = 0; i < registry->repeats[k]; i++) {
                AV *th_t = newAV();  /* times for processing and connecting */
                AV *th_r = newAV();  /* times for http request */
                AV *th_c = newAV();  /* connecting times */
                AV *page_contents = newAV(); /* pages read from servers */
                AV *request_headers = newAV(); /* HTTP requests sent to servers */
                AV *request_body = newAV(); /* HTTP requests sent to servers */
                AV *headers = newAV();
                AV *bytes_posted = newAV();
                AV *doc_length = newAV();
                AV *bytes_read = newAV();

                /* variables for calculating min/max/avg times*/
                int totalcon = 0, totalreq = 0, total = 0;
                int mincon = 999999, minreq = 999999, mintot = 999999;
                int maxcon = 0, maxreq = 0, maxtot = 0;

                /* byte counters */
                int total_bytes_posted = 0, total_bytes_read = 0;

                for (j = registry->position[k]; j < registry->position[k+1]; j++) {
                    struct data s = registry->stats[j][i];
                    mincon = ap_min(mincon, s.ctime);
                    minreq = ap_min(minreq, s.rtime);
                    mintot = ap_min(mintot, s.time);
                    maxcon = ap_max(maxcon, s.ctime);
                    maxreq = ap_max(maxreq, s.rtime);
                    maxtot = ap_max(maxtot, s.time);
                    totalcon += s.ctime;
                    totalreq += s.rtime;
                    total += s.time;
                    if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1 - i,j=%d,%d: mintot=%d maxtot=%d total=%d\n", i, j, mintot, maxtot, total);

                    total_bytes_posted += registry->totalposted[j];
                    total_bytes_read += registry->stats[j][i].read;

                    av_push(th_c, newSVnv(registry->stats[j][i].ctime));
                    av_push(th_r, newSVnv(registry->stats[j][i].rtime));
                    av_push(th_t, newSVnv(registry->stats[j][i].time));
                    if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.1 - i,j=%d,%d\n", i, j);
                    if (i == 0) {
                        av_push(started, newSViv(registry->started[j]));
                        av_push(good, newSViv(registry->good[j]));
                        av_push(failed, newSViv(registry->failed[j]));
                        total_started += registry->started[j];
                        total_good += registry->good[j];
                        total_failed += registry->failed[j];
                    }

                    if (registry->memory[k] >= 2) {
                        if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.1.0 - i,j=%d,%d  header='%s'\n", i, j, registry->stats[j][i].response_headers);
                        if (registry->stats[j][i].response_headers &&
                            strlen(registry->stats[j][i].response_headers) > 0)
                            av_push(headers, newSVpv(registry->stats[j][i].response_headers, 0));
                        else
                            av_push(headers, &PL_sv_undef);
                        if (registry->stats[j][i].request_headers &&
                            strlen(registry->stats[j][i].request_headers) > 0)
                            av_push(request_headers, newSVpv(registry->stats[j][i].request_headers, 0));
                        else
                            av_push(request_headers, &PL_sv_undef);
                        if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.1.1 - i,j=%d,%d\n", i, j);
                        av_push(doc_length, newSVnv(registry->stats[j][i].bread));
                        if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.1.2 - i,j=%d,%d\n", i, j);
                        av_push(bytes_read, newSVnv(registry->stats[j][i].read));
                        if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.1.3 - i,j=%d,%d\n", i, j);
                        /*if (registry->posting[j] > 0)*/
                        av_push(bytes_posted, newSVnv(registry->totalposted[j]));
                    }
                    if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.2 - i,j=%d,%d\n", i, j);
                    if (registry->memory[k] >= 3) {
                        if (registry->stats[j][i].response &&
                            strlen(registry->stats[j][i].response) > 0)
                            av_push(page_contents, newSVpv(registry->stats[j][i].response, 0));
                        else
                            av_push(page_contents, &PL_sv_undef);
                        if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.2.5 - i,j=%d,%d\n", i, j);
                        if (registry->stats[j][i].request &&
                            strlen(registry->stats[j][i].request) > 0)
                            av_push(request_body, newSVpv(registry->stats[j][i].request, 0));
                        else
                            av_push(request_body, &PL_sv_undef);
                    }
                    if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 1.3 - i,j=%d,%d\n", i, j);
                }

                if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 3 - i=%d\n", i);
                tmphv = newHV();
                hv_store(tmphv, "max_connect_time", 16, newSVnv(maxcon), 0);
                hv_store(tmphv, "max_request_time", 16, newSVnv(maxreq), 0);
                hv_store(tmphv, "max_response_time", 17, newSVnv(maxtot), 0);
                hv_store(tmphv, "min_connect_time", 16, newSVnv(mincon), 0);
                hv_store(tmphv, "min_request_time", 16, newSVnv(minreq), 0);
                hv_store(tmphv, "min_response_time", 17, newSVnv(mintot), 0);
                if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 4 - i=%d\n", i);
                hv_store(tmphv, "total_connect_time", 18, newSVnv(totalcon), 0);
                hv_store(tmphv, "total_request_time", 18, newSVnv(totalreq), 0);
                hv_store(tmphv, "total_response_time", 19, newSVnv(total), 0);
                hv_store(tmphv, "average_connect_time", 20, newSVnv((float)totalcon/(j-registry->position[k])), 0);
                hv_store(tmphv, "average_request_time", 20, newSVnv((float)totalreq/(j-registry->position[k])), 0);
                hv_store(tmphv, "average_response_time", 21, newSVnv((double)total/(j-registry->position[k])), 0);
                hv_store(tmphv, "total_bytes_read", 16, newSVnv(total_bytes_read), 0);
                hv_store(tmphv, "total_bytes_posted", 18, newSVnv(total_bytes_posted), 0);
                if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 5 - i=%d\n", i);

                /* started/good/failed are url-specific, store only 1st time */
                if (i == 0) {
                    hv_store(tmphv, "started", 7, newRV_inc((SV *)started), 0);
                    hv_store(tmphv, "good", 4, newRV_inc((SV *)good), 0);
                    hv_store(tmphv, "failed", 6, newRV_inc((SV *)failed), 0);
                }
                hv_store(tmphv, "connect_time", 12, newRV_inc((SV *)th_c), 0);
                hv_store(tmphv, "request_time", 12, newRV_inc((SV *)th_r), 0);
                hv_store(tmphv, "response_time", 13, newRV_inc((SV *)th_t), 0);
                if (registry->memory[k] >= 2) {
                    hv_store(tmphv, "headers", 7, newRV_inc((SV *)headers), 0);
                    hv_store(tmphv, "doc_length", 10, newRV_inc((SV *)doc_length), 0);
                    hv_store(tmphv, "bytes_read", 10, newRV_inc((SV *)bytes_read), 0);
                    hv_store(tmphv, "bytes_posted", 12, newRV_inc((SV *)bytes_posted), 0);
                    hv_store(tmphv, "request_headers", 15, newRV_inc((SV *)request_headers), 0);
                }
                if (registry->memory[k] >= 3) {
                    hv_store(tmphv, "page_content", 12, newRV_inc((SV *)page_contents), 0);
                    hv_store(tmphv, "request_body", 12, newRV_inc((SV *)request_body), 0);
                }
                if (AB_DEBUG_XS) printf("AB_DEBUG: getting regression - stage 6 - i=%d\n", i);
                av_push(tmpav, newRV_inc((SV*)tmphv));
            }
            {
                char key[10];
                sprintf(key, "run%d", k);
                hv_store(RETVAL, key, strlen(key), newRV_inc((SV *)tmpav), 0);
            }
        }
    }

    hv_store(RETVAL, "warnings", 8, newSVpv(registry->warn_and_error, 0), 0);
    hv_store(RETVAL, "total_time", 10,
             newSVnv(timedif(registry->endtime, registry->starttime)), 0);
    hv_store(RETVAL, "bytes_received", 14,
             newSVnv(registry->total_bytes_received), 0);
    hv_store(RETVAL, "started", 7, newSViv(total_started), 0);
    hv_store(RETVAL, "good", 4, newSViv(total_good), 0);
    hv_store(RETVAL, "failed", 6, newSViv(total_failed), 0);

    OUTPUT:
    RETVAL
