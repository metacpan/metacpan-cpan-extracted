#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#define MY_CXT_KEY "AnyEvent::YACurl::_guts" XS_VERSION

#include <curl/curl.h>

typedef struct {
    SV *watchset_fn;
    SV *timerset_fn;
    HV *curlopt;
} my_cxt_t;

typedef struct {
    CURLM *multi;
    SV *weak_self_ref;

    int needs_invoke_timeout;
    int needs_read_info;
    int last_running;
} AnyEvent__YACurl;

typedef struct {
    SV *self_rv;
    CURL *easy;
    curl_mime *mimepost;

    AV *held_references;
    int slists_count;
    struct curl_slist **slists;
    char errbuf[CURL_ERROR_SIZE];

    SV *callback;
} AnyEvent__YACurl__Response;

START_MY_CXT

void maybe_warn_eval(pTHX)
{
    SV *error = ERRSV;
    if (SvTRUE(error)) {
        warn("Error in callback: %s", SvPV_nolen(error));
    }
}

int mcurl_socket_callback(CURL* easy,
                          curl_socket_t s,
                          int what,
                          void* userp,
                          void* socketp)
{
    dTHX;
    dMY_CXT;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs((SV*)userp); /* XXX This is a weakened reference, will it ever be undef? */
    PUSHs(sv_2mortal(newSViv(s)));
    PUSHs(sv_2mortal(newSViv(what)));
    PUTBACK;

    call_sv(MY_CXT.watchset_fn, G_DISCARD | G_VOID);

    FREETMPS;
    LEAVE;

    return 0;
}

int mcurl_timer_callback(CURLM* multi,
                         long timeout_ms,
                         void *userp)
{
    dTHX;

    if (timeout_ms == 0) {
        /* We short-circuit timeout_ms==0, as we're very likely to call do_post_work shortly
         * after reaching this code path. A timer of 0sec in AnyEvent would almost always turn
         * into a 1ms wait, which is unnecessary and slow. Same goes for AE::postpone. */
        IV tmp = SvIV((SV*)SvRV((SV*)userp));
        AnyEvent__YACurl *client = INT2PTR(AnyEvent__YACurl*, tmp);

        client->needs_invoke_timeout = 1;
        return 0;
    }

    dMY_CXT;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs((SV*)userp); /* XXX This is a weakened reference, will it ever be undef? */
    PUSHs(sv_2mortal(newSViv(timeout_ms)));
    PUTBACK;

    call_sv(MY_CXT.timerset_fn, G_DISCARD | G_VOID);

    FREETMPS;
    LEAVE;

    return 0;
}

/* write callback: used for WRITEFUNCTION and HEADERFUNCTION */
size_t mcurl_write_callback(char *ptr,
                           size_t size,
                           size_t nmemb,
                           void *userdata)
{
    dTHX;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn(ptr, size*nmemb)));
    PUTBACK;

    call_sv((SV*)userdata, G_DISCARD | G_VOID | G_EVAL);

    SPAGAIN;
    maybe_warn_eval(aTHX);
    PUTBACK;

    FREETMPS;
    LEAVE;

    return size * nmemb;
}

size_t mcurl_read_callback(char *buffer,
                           size_t size,
                           size_t nitems,
                           void *userdata)
{
    size_t result;

    dTHX;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSViv(size * nitems)));
    PUTBACK;

    call_sv((SV*)userdata, G_SCALAR | G_EVAL);

    SPAGAIN;
    maybe_warn_eval(aTHX);
    SV *data = POPs;
    if (!SvOK(data)) {
        /* undef. We also go here if the callback croaked... how convenient */
        result = CURL_READFUNC_ABORT;
    } else {
        STRLEN pvlen;
        char *pv = SvPV(data, pvlen);

        if (pvlen > size*nitems) {
            warn("Read callback returned more data than allowed; aborting stream");
            result = CURL_READFUNC_ABORT;

        } else {
            result = pvlen;
            Copy(pv, buffer, pvlen, char);
        }
    }
    PUTBACK;

    FREETMPS;
    LEAVE;

    return result;
}

int finish_request(pTHX_ AnyEvent__YACurl* client, CURL* easy, CURLcode code)
{
    AnyEvent__YACurl__Response *response;
    curl_easy_getinfo(easy, CURLINFO_PRIVATE, (void*)&response);

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);

    if (code == CURLE_OK) {
        PUSHs(response->self_rv);
        PUSHs(&PL_sv_undef);
    } else {
        PUSHs(&PL_sv_undef);
        if (strlen(response->errbuf)) {
            PUSHs(sv_2mortal(newSVpv(response->errbuf, 0)));
        } else {
            PUSHs(sv_2mortal(newSVpv(curl_easy_strerror(code), 0)));
        }
    }

    PUTBACK;

    call_sv(response->callback, G_DISCARD | G_VOID | G_EVAL);

    SPAGAIN;
    maybe_warn_eval(aTHX);
    PUTBACK;

    FREETMPS;
    LEAVE;

    /* Clean some fields we don't need anymore. We do this now instead of via DESTROY, to break
     * potential reference cycles. */
    SvREFCNT_dec(response->held_references);
    response->held_references = NULL;
    SvREFCNT_dec(response->callback);
    response->callback = NULL;

    /* But, the request is done, so let Perl clean things up when ready */
    SV *self_rv = response->self_rv;
    response->self_rv = NULL;
    SvREFCNT_dec(self_rv);

    return 0;
}

int update_running(pTHX_ AnyEvent__YACurl* client, int new_running)
{
    if (client->last_running == new_running) {
        return 0;
    }

    client->last_running = new_running;
    client->needs_read_info = 1;

    return 0;
}

int do_post_work(pTHX_ AnyEvent__YACurl* client)
{
    while (client->needs_invoke_timeout || client->needs_read_info) {
        {
            int running;

            client->needs_invoke_timeout = 0;
            curl_multi_socket_action(client->multi, CURL_SOCKET_TIMEOUT, 0, &running);
            update_running(aTHX_ client, running);
        }

        {
            struct CURLMsg *m = NULL;

            client->needs_read_info = 0;
            do {
                int msgq;
                m = curl_multi_info_read(client->multi, &msgq);
                if (m && (m->msg == CURLMSG_DONE)) {
                    CURL *e = m->easy_handle;

                    finish_request(aTHX_ client, e, m->data.result);
                    curl_multi_remove_handle(client->multi, e);

                    /* XXX: finish_request can invoke callbacks which could call us again and then call do_post_work
                     * while we're still running, thus calling curl_multi_info_read again which can clear previous events.
                     * Not good. */
                }
            } while(m);
        }
    }

    return 0;
}

AnyEvent__YACurl* sv_to_client(pTHX_ SV* the_sv)
{
    /* XXX This needs better sanity checking */
    IV tmp = SvIV((SV*)SvRV(the_sv));
    AnyEvent__YACurl *client = INT2PTR(AnyEvent__YACurl*, tmp);
    return client;
}

AnyEvent__YACurl__Response* sv_to_response(pTHX_ SV* the_sv)
{
    /* XXX This needs better sanity checking */
    IV tmp = SvIV((SV*)SvRV(the_sv));
    AnyEvent__YACurl__Response *response = INT2PTR(AnyEvent__YACurl__Response*, tmp);
    return response;
}

int fill_hv_with_constants(pTHX_ HV* the_hv)
{
#include "constants.inc"
    return 0;
}

struct curl_slist *slist_from_av(pTHX_ AV *input)
{
    SSize_t i;
    struct curl_slist *list = NULL;
    for (i = 0; i <= av_len(input); i++) {
        char *pv_ptr, *new_ptr;
        STRLEN pv_len;

        SV **entry = av_fetch(input, i, 0);
        assert(entry != NULL);

        pv_ptr = SvPV(*entry, pv_len);
        Newx(new_ptr, pv_len+1, char);
        strncpy(new_ptr, pv_ptr, pv_len);
        new_ptr[pv_len] = 0x00;

        list = curl_slist_append(list, new_ptr);

        Safefree(new_ptr);
    }

    return list;
}

long option_from_sv_or_croak(pTHX_ pMY_CXT_ SV *option, U32 optionhash, int *opt_from_str)
{
    if (SvIOK(option) || SvNOK(option)) {
        *opt_from_str = 0;
        return SvIV(option);

    } else if (SvPOK(option) && SvPVX(option) != NULL && SvCUR(option) > 0 && SvPVX(option)[0] != 'C') {
        /* POK (it's a string), PVX!=NULL (there's a body),
         * CUR>0 (it has length), PVX[0]!=C (it doesn't start with a C).
         * All curl options start with 'CURL', so are we looking at a number instead? */
        *opt_from_str = 0;
        return SvIV(option);

    } else {
        HE *lookedup = hv_fetch_ent(MY_CXT.curlopt, option, 0, optionhash);
        if (!lookedup || !SvIOK(HeVAL(lookedup))) {
            croak("Don't understand CURL option %s", SvPV_nolen(option));
        }
        *opt_from_str = 1;
        return SvIV(HeVAL(lookedup));
    }
}

CURLcode setopt_sv_or_croak(pTHX_ AnyEvent__YACurl__Response *request, CURLoption option, SV* parameter)
{
    CURLcode result;

    switch (option) {
        /* Strings */
#include "curlopt-str.inc"
        {
            char *str;
            STRLEN len;
            str = SvPV(parameter, len);

            char *str_copy;
            Newx(str_copy, len+1, char);
            strncpy(str_copy, str, len);
            str_copy[len] = 0x00;

            result = curl_easy_setopt(request->easy, option, str_copy);

            Safefree(str_copy);
            break;
        }

        /* Longs */
#include "curlopt-long.inc"
        {
            long param = SvIV(parameter);
            result = curl_easy_setopt(request->easy, option, param);
            break;
        }

        /* off_t's */
#include "curlopt-off-t.inc"
        {
            curl_off_t param = SvIV(parameter);
            result = curl_easy_setopt(request->easy, option, param);
            break;
        }

        /* string lists */
        case CURLOPT_HTTPHEADER:
        case CURLOPT_PROXYHEADER:
        case CURLOPT_HTTP200ALIASES:
        case CURLOPT_MAIL_RCPT:
        case CURLOPT_POSTQUOTE:
        case CURLOPT_PREQUOTE:
        case CURLOPT_QUOTE:
        case CURLOPT_RESOLVE:
        case CURLOPT_TELNETOPTIONS:
        case CURLOPT_CONNECT_TO:
        {
            if (!SvROK(parameter) || SvTYPE(SvRV(parameter)) != SVt_PVAV) {
                croak("Cannot convert %s to ARRAY reference", SvPV_nolen(parameter));

            } else {
                struct curl_slist *list = slist_from_av(aTHX_ (AV*)SvRV(parameter));
                result = curl_easy_setopt(request->easy, option, list);

                Renew(request->slists, request->slists_count+1, struct curl_slist*);
                request->slists[request->slists_count] = list;
                request->slists_count++;
            }
            break;
        }

        /* Special functions */
        case CURLOPT_WRITEFUNCTION:
        case CURLOPT_HEADERFUNCTION:
        case CURLOPT_READFUNCTION:
        {
            SV* fn_copy = newSVsv(parameter);
            av_push(request->held_references, fn_copy);

            switch (option) {
                case CURLOPT_WRITEFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_WRITEFUNCTION, mcurl_write_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_WRITEDATA, fn_copy);
                    break;
                }
                case CURLOPT_HEADERFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_HEADERFUNCTION, mcurl_write_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_HEADERDATA, fn_copy);
                    break;
                }
                case CURLOPT_READFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_READFUNCTION, mcurl_read_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_READDATA, fn_copy);
                    break;
                }
                default: { result = CURLE_OK; } /* To keep compilers quiet */
            }
            break;
        }

        /* Post fields are a bit special because of how they are copied (and can contain zero-bytes) */
        case CURLOPT_POSTFIELDS:
        {
            STRLEN pvlen;
            char *pv = SvPV(parameter, pvlen);

            result = curl_easy_setopt(request->easy, CURLOPT_POSTFIELDSIZE, pvlen);
            result = curl_easy_setopt(request->easy, CURLOPT_COPYPOSTFIELDS, pv);
            break;
        }

        /* MIME posts are specified as an arrayref of hashes with a 'name' and a 'value' */
        case CURLOPT_MIMEPOST:
        {
            if (!SvROK(parameter) || SvTYPE(SvRV(parameter)) != SVt_PVAV) {
                croak("Cannot convert %s to ARRAY reference", SvPV_nolen(parameter));
            }
            AV *param_av = (AV*)SvRV(parameter);

            curl_mimepart *part;
            if (request->mimepost) {
                curl_mime_free(request->mimepost);
            }
            request->mimepost = curl_mime_init(request->easy);

            int i;
            for (i = 0; i <= av_len(param_av); i++) {
                SV *entry = *av_fetch(param_av, i, TRUE);
                if (!SvROK(entry) || SvTYPE(SvRV(entry)) != SVt_PVHV) {
                    croak("Cannot convert %s to HASH reference", SvPV_nolen(entry));
                }

                HV *entry_hv = (HV*)SvRV(entry);
                part = curl_mime_addpart(request->mimepost);

                {
                    SV **name_sv = hv_fetchs(entry_hv, "name", FALSE);
                    if (!name_sv)
                        croak("MIMEPOST must be specified as an array of hashrefs "
                              "containing 'name' and 'value' entries");

                    curl_mime_name(part, SvPV_nolen(*name_sv));
                }

                {
                    SV **value_sv = hv_fetchs(entry_hv, "value", FALSE);
                    if (!value_sv)
                        croak("MIMEPOST must be specified as an array of hashrefs "
                              "containing 'name' and 'value' entries");

                    STRLEN valuelen;
                    char *value = SvPV(*value_sv, valuelen);
                    curl_mime_data(part, value, valuelen);
                }
            }

            /* If this fails, we'll still free the mimepost properly later */
            result = curl_easy_setopt(request->easy, CURLOPT_MIMEPOST, request->mimepost);

            break;
        }

        /* Don't know... */
        default:
        {
            croak("Not sure what to do with CURL option %d", option);
            break;
        }
    }

    return result;
}

MODULE = AnyEvent::YACurl       PACKAGE = AnyEvent::YACurl

PROTOTYPES: DISABLE

BOOT:
{
    /* XXX: Needs a CLONE */

    MY_CXT_INIT;
    MY_CXT.watchset_fn = NULL;
    MY_CXT.timerset_fn = NULL;
    MY_CXT.curlopt = newHV();
    fill_hv_with_constants(aTHX_ MY_CXT.curlopt);

    curl_global_init(CURL_GLOBAL_ALL);
}

void
new(class, args)
        char *class
        HV *args
    PPCODE:
        dMY_CXT;

        (void)class;
        AnyEvent__YACurl *client;

        Newxz(client, 1, AnyEvent__YACurl);

        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), "AnyEvent::YACurl", (void*)client);

        /* XXX When we destroy the client, do we pass undefs to the timer/watch functions? */
        client->weak_self_ref = newSVsv(ST(0));
        sv_rvweaken(client->weak_self_ref);

        client->multi = curl_multi_init();
        curl_multi_setopt(client->multi, CURLMOPT_SOCKETFUNCTION, mcurl_socket_callback);
        curl_multi_setopt(client->multi, CURLMOPT_TIMERFUNCTION, mcurl_timer_callback);
        curl_multi_setopt(client->multi, CURLMOPT_SOCKETDATA, (void*)client->weak_self_ref);
        curl_multi_setopt(client->multi, CURLMOPT_TIMERDATA, (void*)client->weak_self_ref);

        {
            hv_iterinit(args);
            HE *iterentry;
            while ((iterentry = hv_iternext(args)) != NULL) {
                long opt;
                int opt_from_str;
                SV *key = HeSVKEY_force(iterentry);
                opt = option_from_sv_or_croak(aTHX_ aMY_CXT_ key, HeHASH(iterentry), &opt_from_str);

                switch (opt) {
                    /* Longs */
                    case CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE:
                    case CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE:
                    case CURLMOPT_MAX_HOST_CONNECTIONS:
                    case CURLMOPT_MAX_PIPELINE_LENGTH:
                    case CURLMOPT_MAX_TOTAL_CONNECTIONS:
                    case CURLMOPT_MAXCONNECTS:
                    case CURLMOPT_PIPELINING:
                    {
                        long value = SvIV(HeVAL(iterentry));
                        CURLMcode mcode = curl_multi_setopt(client->multi, opt, value);
                        if (mcode != CURLM_OK) {
                            croak("Failed to set %d (%s): %s", opt, SvPV_nolen(key), curl_multi_strerror(mcode));
                        }
                        break;
                    }

                    /* String arrays */
                    case CURLMOPT_PIPELINING_SITE_BL:
                    case CURLMOPT_PIPELINING_SERVER_BL:
                    {
                        char **strings;
                        if (!SvROK(HeVAL(iterentry)) || SvTYPE(SvRV(HeVAL(iterentry))) != SVt_PVAV) {
                            croak("%d (%s): cannot convert value to ARRAYREF", opt, SvPV_nolen(key));
                        }

                        AV *array = (AV*)SvRV(HeVAL(iterentry));
                        int arraylen = av_len(array) + 1;

                        Newxz(strings, arraylen+1, char*);

                        int i;
                        for (i = 0; i < arraylen; i++) {
                            char *strcopy, *pv;
                            STRLEN pvlen;
                            pv = SvPV(*av_fetch(array, i, TRUE), pvlen);

                            Newxz(strcopy, pvlen+1, char);
                            Copy(pv, strcopy, pvlen, char);
                            strings[i] = strcopy;
                        }

                        CURLMcode mcode = curl_multi_setopt(client->multi, opt, strings);

                        for (i = 0; i < arraylen; i++) {
                            Safefree(strings[i]);
                        }
                        Safefree(strings);

                        if (mcode != CURLM_OK) {
                            croak("Failed to set %d (%s): %s", opt, SvPV_nolen(key), curl_multi_strerror(mcode));
                        }
                        break;
                    }
                }
            }
        }

        do_post_work(aTHX_ client);

        XSRETURN(1);

void
request(self, callback, options)
        SV* self
        SV* callback
        HV* options
    CODE:
        dMY_CXT;
        AnyEvent__YACurl *client = sv_to_client(aTHX_ self);

        /* Bit of a memory juggle to avoid leaks and allow us to croak() */
        AnyEvent__YACurl__Response *response_ctx;
        Newxz(response_ctx, 1, AnyEvent__YACurl__Response);
        response_ctx->self_rv = sv_newmortal();
        sv_setref_pv(response_ctx->self_rv, "AnyEvent::YACurl::Response", (void*)response_ctx);

        CURL* easy = curl_easy_init();
        if (!easy) {
            croak("Failed to instantiate CURL object");
        }
        response_ctx->easy = easy;

        if (curl_easy_setopt(easy, CURLOPT_PRIVATE, response_ctx) != 0) {
            croak("Failed to setup CURL object");
        }

        response_ctx->held_references = newAV();
        response_ctx->callback = newSVsv(callback);

        /* Avoid deallocating the client while the request is ongoing */
        av_push(response_ctx->held_references, newSVsv(self));

        hv_iterinit(options);
        HE *iterentry;
        while ((iterentry = hv_iternext(options)) != NULL) {
            long opt;
            int opt_from_str;
            SV *key = HeSVKEY_force(iterentry);
            opt = option_from_sv_or_croak(aTHX_ aMY_CXT_ key, HeHASH(iterentry), &opt_from_str);

            CURLcode ccode = setopt_sv_or_croak(aTHX_ response_ctx, opt, HeVAL(iterentry));
            if (ccode != CURLE_OK) {
                croak("Failed to set %s: %s", SvPV_nolen(key), curl_easy_strerror(ccode));
            }
        }

        CURLMcode error = curl_multi_add_handle(client->multi, easy);
        if (error != CURLM_OK) {
            croak("Failed to perform CURL request: %s", curl_multi_strerror(error));
        }

        /* At this point we succeeded, so we want to be sure we retain the structs until we're done */
        SvREFCNT_inc(response_ctx->self_rv);

        update_running(aTHX_ client, client->last_running + 1);
        client->needs_invoke_timeout = 1;

        do_post_work(aTHX_ client);

PROTOTYPES: ENABLE

void
_ae_set_helpers(watchset, timerset)
        SV* watchset
        SV* timerset
    CODE:
        dMY_CXT;

        if (MY_CXT.watchset_fn != NULL)
            croak("watchset already set");
        MY_CXT.watchset_fn = newSVsv(watchset);

        if (MY_CXT.timerset_fn != NULL)
            croak("timerset already set");
        MY_CXT.timerset_fn = newSVsv(timerset);

void
_ae_timer_fired(self)
        SV* self
    CODE:
        AnyEvent__YACurl *client = sv_to_client(aTHX_ self);

        client->needs_invoke_timeout = 1;
        do_post_work(aTHX_ client);

void
_ae_event(self, sock, is_write)
        SV* self
        int sock
        int is_write
    CODE:
        AnyEvent__YACurl *client = sv_to_client(aTHX_ self);

        int running;
        curl_multi_socket_action(client->multi, sock, (is_write ? CURL_CSELECT_OUT : CURL_CSELECT_IN), &running);
        update_running(aTHX_ client, running);

        do_post_work(aTHX_ client);

HV*
_get_known_constants()
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV*)RETVAL); /* hehe, perl bugs! */
        fill_hv_with_constants(aTHX_ RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV* self
    CODE:
        AnyEvent__YACurl *client = sv_to_client(aTHX_ self);
        if (client->last_running)
            warn("Destroying with %d requests active", client->last_running);

        if (client->multi != NULL) {
            curl_multi_cleanup(client->multi);
        }
        if (client->weak_self_ref != NULL) {
            SvREFCNT_dec(client->weak_self_ref);
        }

        Safefree(client);



MODULE = AnyEvent::YACurl       PACKAGE = AnyEvent::YACurl::Response

SV*
getinfo(self, option)
        SV* self
        SV* option
    CODE:
        dMY_CXT;
        AnyEvent__YACurl__Response *response = sv_to_response(aTHX_ self);

        int opt_from_str;
        CURLINFO opt = option_from_sv_or_croak(aTHX_ aMY_CXT_ option, 0, &opt_from_str);

        if (opt == CURLINFO_PRIVATE) {
            /* These would be meaningless to access, so don't bother */
            croak("Refusing access to private CURL data");

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_STRING) {
            char *result;
            CURLcode ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK) {
                croak("%s", curl_easy_strerror(ccode));
            }
            RETVAL = newSVpv(result, 0);

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_LONG) {
            long result;
            CURLcode ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK) {
                croak("%s", curl_easy_strerror(ccode));
            }
            RETVAL = newSViv(result);

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_OFF_T) {
            curl_off_t result;
            CURLcode ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK) {
                croak("%s", curl_easy_strerror(ccode));
            }
            RETVAL = newSViv(result);

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_DOUBLE) {
            double result;
            CURLcode ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK) {
                croak("%s", curl_easy_strerror(ccode));
            }
            RETVAL = newSVnv(result);

        } else if (opt_from_str) {
            croak("Don't know what to do with curl's %d (%s)", opt, SvPV_nolen(option));
        } else {
            croak("Don't know what to do with curl's %d", opt);
        }

    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV* self
    CODE:
        AnyEvent__YACurl__Response *response = sv_to_response(aTHX_ self);

        if (response->easy) {
            curl_easy_cleanup(response->easy);
        }
        if (response->mimepost) {
            curl_mime_free(response->mimepost);
        }
        if (response->held_references) {
            SvREFCNT_dec(response->held_references);
        }
        if (response->slists) {
            int i;
            for (i = 0; i < response->slists_count; i++) {
                curl_slist_free_all(response->slists[i]);
            }
            Safefree(response->slists);
        }
        if (response->callback) {
            SvREFCNT_dec(response->callback);
        }

        Safefree(response);
