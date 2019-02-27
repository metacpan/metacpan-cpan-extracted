#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define MY_CXT_KEY "AnyEvent::XSPromises::_guts" XS_VERSION

typedef struct xspr_callback_s xspr_callback_t;
typedef struct xspr_promise_s xspr_promise_t;
typedef struct xspr_result_s xspr_result_t;
typedef struct xspr_callback_queue_s xspr_callback_queue_t;

typedef enum {
    XSPR_STATE_NONE,
    XSPR_STATE_PENDING,
    XSPR_STATE_FINISHED,
} xspr_promise_state_t;

typedef enum {
    XSPR_RESULT_NONE,
    XSPR_RESULT_RESOLVED,
    XSPR_RESULT_REJECTED,
    XSPR_RESULT_BOTH
} xspr_result_state_t;

typedef enum {
    XSPR_CALLBACK_PERL,
    XSPR_CALLBACK_FINALLY,
    XSPR_CALLBACK_CHAIN
} xspr_callback_type_t;

struct xspr_callback_s {
    xspr_callback_type_t type;
    union {
        struct {
            SV* on_resolve;
            SV* on_reject;
            xspr_promise_t* next;
        } perl;
        struct {
            SV* on_finally;
            xspr_promise_t* next;
        } finally;
        xspr_promise_t* chain;
    };
};

struct xspr_result_s {
    xspr_result_state_t state;
    SV** result;
    int count;
    int refs;
};

struct xspr_promise_s {
    xspr_promise_state_t state;
    int refs;
    union {
        struct {
            xspr_callback_t** callbacks;
            int callbacks_count;
        } pending;
        struct {
            xspr_result_t *result;
        } finished;
    };
};

struct xspr_callback_queue_s {
    xspr_promise_t* origin;
    xspr_callback_t* callback;
    xspr_callback_queue_t* next;
};

void xspr_queue_flush(pTHX);
void xspr_queue_add(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin);
void xspr_queue_maybe_schedule(pTHX);

xspr_callback_t* xspr_callback_new_perl(pTHX_ SV* on_resolve, SV* on_reject, xspr_promise_t* next);
xspr_callback_t* xspr_callback_new_chain(pTHX_ xspr_promise_t* chain);
void xspr_callback_process(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin);
void xspr_callback_free(pTHX_ xspr_callback_t* callback);

xspr_promise_t* xspr_promise_new(pTHX);
void xspr_promise_then(pTHX_ xspr_promise_t* promise, xspr_callback_t* callback);
void xspr_promise_finish(pTHX_ xspr_promise_t* promise, xspr_result_t *result);
void xspr_promise_incref(pTHX_ xspr_promise_t* promise);
void xspr_promise_decref(pTHX_ xspr_promise_t* promise);

xspr_result_t* xspr_result_new(pTHX_ xspr_result_state_t state, int count);
xspr_result_t* xspr_result_from_error(pTHX_ const char *error);
void xspr_result_incref(pTHX_ xspr_result_t* result);
void xspr_result_decref(pTHX_ xspr_result_t* result);

xspr_result_t* xspr_invoke_perl(pTHX_ SV* perl_fn, SV** input, int input_count);
xspr_promise_t* xspr_promise_from_sv(pTHX_ SV* input);


typedef struct {
    xspr_callback_queue_t* queue_head;
    xspr_callback_queue_t* queue_tail;
    int in_flush;
    int backend_scheduled;
    SV* conversion_helper;
    SV* backend_fn;
} my_cxt_t;

typedef struct {
    xspr_promise_t* promise;
} AnyEvent__XSPromises__Deferred;

typedef struct {
    xspr_promise_t* promise;
} AnyEvent__XSPromises__Promise;

START_MY_CXT

/* Process a single callback */
void xspr_callback_process(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin)
{
    assert(origin->state == XSPR_STATE_FINISHED);

    if (callback->type == XSPR_CALLBACK_CHAIN) {
        xspr_promise_finish(aTHX_ callback->chain, origin->finished.result);

    } else if (callback->type == XSPR_CALLBACK_PERL) {
        SV* callback_fn;

        if (origin->finished.result->state == XSPR_RESULT_RESOLVED) {
            callback_fn = callback->perl.on_resolve;
        } else if (origin->finished.result->state == XSPR_RESULT_REJECTED) {
            callback_fn = callback->perl.on_reject;
        } else {
            callback_fn = NULL; /* Be quiet, bad compiler! */
            assert(0);
        }

        if (callback_fn != NULL) {
            xspr_result_t* result;
            result = xspr_invoke_perl(aTHX_
                                      callback_fn,
                                      origin->finished.result->result,
                                      origin->finished.result->count);

            if (callback->perl.next != NULL) {
                int skip_passthrough = 0;

                if (result->count == 1 && result->state == XSPR_RESULT_RESOLVED) {
                    xspr_promise_t* promise = xspr_promise_from_sv(aTHX_ result->result[0]);
                    if (promise != NULL && promise == callback->perl.next) {
                        /* This is an extreme corner case the A+ spec made us implement: we need to reject
                         * cases where the promise created from then() is passed back to its own callback */
                        xspr_result_t* chain_error = xspr_result_from_error(aTHX_ "TypeError");
                        xspr_promise_finish(aTHX_ callback->perl.next, chain_error);

                        xspr_result_decref(aTHX_ chain_error);
                        xspr_promise_decref(aTHX_ promise);
                        skip_passthrough= 1;

                    } else if (promise != NULL) {
                        /* Fairly normal case: we returned a promise from the callback */
                        xspr_callback_t* chainback = xspr_callback_new_chain(aTHX_ callback->perl.next);
                        xspr_promise_then(aTHX_ promise, chainback);

                        xspr_promise_decref(aTHX_ promise);
                        skip_passthrough = 1;
                    }
                }

                if (!skip_passthrough) {
                    xspr_promise_finish(aTHX_ callback->perl.next, result);
                }
            }

            xspr_result_decref(aTHX_ result);

        } else if (callback->perl.next) {
            /* No callback, so we're just passing the result along. */
            xspr_result_t* result = origin->finished.result;
            xspr_promise_finish(aTHX_ callback->perl.next, result);
        }

    } else if (callback->type == XSPR_CALLBACK_FINALLY) {
        SV* callback_fn = callback->finally.on_finally;
        if (callback_fn != NULL) {
            xspr_result_t* result;
            result = xspr_invoke_perl(aTHX_
                                      callback_fn,
                                      origin->finished.result->result,
                                      origin->finished.result->count);
            xspr_result_decref(aTHX_ result);
        }

        if (callback->finally.next != NULL) {
            xspr_promise_finish(aTHX_ callback->finally.next, origin->finished.result);
        }

    } else {
        assert(0);
    }
}

/* Frees the xspr_callback_t structure */
void xspr_callback_free(pTHX_ xspr_callback_t *callback)
{
    if (callback->type == XSPR_CALLBACK_CHAIN) {
        xspr_promise_decref(aTHX_ callback->chain);

    } else if (callback->type == XSPR_CALLBACK_PERL) {
        SvREFCNT_dec(callback->perl.on_resolve);
        SvREFCNT_dec(callback->perl.on_reject);
        if (callback->perl.next != NULL)
            xspr_promise_decref(aTHX_ callback->perl.next);

    } else if (callback->type == XSPR_CALLBACK_FINALLY) {
        SvREFCNT_dec(callback->finally.on_finally);
        if (callback->finally.next != NULL)
            xspr_promise_decref(aTHX_ callback->finally.next);

    } else {
        assert(0);
    }

    Safefree(callback);
}

/* Process the queue until it's empty */
void xspr_queue_flush(pTHX)
{
    dMY_CXT;

    if (MY_CXT.in_flush) {
        /* XXX: is there a reasonable way to trigger this? */
        warn("Rejecting request to flush promises queue: already processing");
        return;
    }
    MY_CXT.in_flush = 1;

    while (MY_CXT.queue_head != NULL) {
        /* Save some typing... */
        xspr_callback_queue_t *cur = MY_CXT.queue_head;

        /* Process the callback. This could trigger some Perl code, meaning we
         * could end up with additional queue entries after this */
        xspr_callback_process(aTHX_ cur->callback, cur->origin);

        /* Free-ing the callback structure could theoretically trigger DESTROY subs,
         * enqueueing new callbacks, so we can't assume the loop ends here! */
        MY_CXT.queue_head = cur->next;
        if (cur->next == NULL) {
            MY_CXT.queue_tail = NULL;
        }

        /* Destroy the structure */
        xspr_callback_free(aTHX_ cur->callback);
        xspr_promise_decref(aTHX_ cur->origin);
        Safefree(cur);
    }

    MY_CXT.in_flush = 0;
    MY_CXT.backend_scheduled = 0;
}

/* Add a callback invocation into the queue for the given origin promise.
 * Takes ownership of the callback structure */
void xspr_queue_add(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin)
{
    dMY_CXT;

    xspr_callback_queue_t* entry;
    Newxz(entry, 1, xspr_callback_queue_t);
    entry->origin = origin;
    xspr_promise_incref(aTHX_ entry->origin);
    entry->callback = callback;

    if (MY_CXT.queue_head == NULL) {
        assert(MY_CXT.queue_tail == NULL);
        /* Empty queue, so now it's just us */
        MY_CXT.queue_head = entry;
        MY_CXT.queue_tail = entry;

    } else {
        assert(MY_CXT.queue_tail != NULL);
        /* Existing queue, add to the tail */
        MY_CXT.queue_tail->next = entry;
        MY_CXT.queue_tail = entry;
    }
}

void xspr_queue_maybe_schedule(pTHX)
{
    dMY_CXT;
    if (MY_CXT.queue_head == NULL || MY_CXT.backend_scheduled || MY_CXT.in_flush) {
        return;
    }

    MY_CXT.backend_scheduled = 1;
    /* We trust our backends to be sane, so little guarding against errors here */
    dSP;
    PUSHMARK(SP);
    call_sv(MY_CXT.backend_fn, G_DISCARD|G_NOARGS);
}

/* Invoke the user's perl code. We need to be really sure this doesn't return early via croak/next/etc. */
xspr_result_t* xspr_invoke_perl(pTHX_ SV* perl_fn, SV** input, int input_count)
{
    dSP;
    int count, i;
    SV* error;
    xspr_result_t* result;

    if (!SvROK(perl_fn)) {
        return xspr_result_from_error(aTHX_ "promise callbacks need to be a CODE reference");
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, input_count);
    for (i = 0; i < input_count; i++) {
        PUSHs(input[i]);
    }
    PUTBACK;

    /* Clear $_ so that callbacks don't end up talking to each other by accident */
    SAVE_DEFSV;
    DEFSV_set(sv_newmortal());

    count = call_sv(perl_fn, G_EVAL|G_ARRAY);

    SPAGAIN;
    error = ERRSV;
    if (SvTRUE(error)) {
        result = xspr_result_new(aTHX_ XSPR_RESULT_REJECTED, 1);
        result->result[0] = newSVsv(error);
    } else {
        result = xspr_result_new(aTHX_ XSPR_RESULT_RESOLVED, count);
        for (i = 0; i < count; i++) {
            result->result[count-i-1] = SvREFCNT_inc(POPs);
        }
    }
    PUTBACK;

    FREETMPS;
    LEAVE;

    return result;
}

/* Increments the ref count for xspr_result_t */
void xspr_result_incref(pTHX_ xspr_result_t* result)
{
    result->refs++;
}

/* Decrements the ref count for the xspr_result_t, freeing the structure if needed */
void xspr_result_decref(pTHX_ xspr_result_t* result)
{
    if (--(result->refs) == 0) {
        int i;
        for (i = 0; i < result->count; i++) {
            SvREFCNT_dec(result->result[i]);
        }
        Safefree(result->result);
        Safefree(result);
    }
}

/* Transitions a promise from pending to finished, using the given result */
void xspr_promise_finish(pTHX_ xspr_promise_t* promise, xspr_result_t* result)
{
    assert(promise->state == XSPR_STATE_PENDING);
    xspr_callback_t** pending_callbacks = promise->pending.callbacks;
    int count = promise->pending.callbacks_count;

    promise->state = XSPR_STATE_FINISHED;
    promise->finished.result = result;
    xspr_result_incref(aTHX_ promise->finished.result);

    int i;
    for (i = 0; i < count; i++) {
        xspr_queue_add(aTHX_ pending_callbacks[i], promise);
    }
    Safefree(pending_callbacks);
}

/* Create a new xspr_result_t object with the given number of item slots */
xspr_result_t* xspr_result_new(pTHX_ xspr_result_state_t state, int count)
{
    xspr_result_t* result;
    Newxz(result, 1, xspr_result_t);
    Newxz(result->result, count, SV*);
    result->state = state;
    result->refs = 1;
    result->count = count;
    return result;
}

xspr_result_t* xspr_result_from_error(pTHX_ const char *error)
{
    xspr_result_t* result = xspr_result_new(aTHX_ XSPR_RESULT_REJECTED, 1);
    result->result[0] = newSVpv(error, 0);
    return result;
}

/* Increments the ref count for xspr_promise_t */
void xspr_promise_incref(pTHX_ xspr_promise_t* promise)
{
    (promise->refs)++;
}

/* Decrements the ref count for the xspr_promise_t, freeing the structure if needed */
void xspr_promise_decref(pTHX_ xspr_promise_t *promise)
{
    if (--(promise->refs) == 0) {
        if (promise->state == XSPR_STATE_PENDING) {
            /* XXX: is this a bad thing we should warn for? */
            int count = promise->pending.callbacks_count;
            xspr_callback_t **callbacks = promise->pending.callbacks;
            int i;
            for (i = 0; i < count; i++) {
                xspr_callback_free(aTHX_ callbacks[i]);
            }
            Safefree(callbacks);

        } else if (promise->state == XSPR_STATE_FINISHED) {
            xspr_result_decref(aTHX_ promise->finished.result);

        } else {
            assert(0);
        }

        Safefree(promise);
    }
}

/* Creates a new promise. It's that simple. */
xspr_promise_t* xspr_promise_new(pTHX)
{
    xspr_promise_t* promise;
    Newxz(promise, 1, xspr_promise_t);
    promise->refs = 1;
    promise->state = XSPR_STATE_PENDING;
    return promise;
}

xspr_callback_t* xspr_callback_new_perl(pTHX_ SV* on_resolve, SV* on_reject, xspr_promise_t* next)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_PERL;
    if (SvOK(on_resolve))
        callback->perl.on_resolve = newSVsv(on_resolve);
    if (SvOK(on_reject))
        callback->perl.on_reject = newSVsv(on_reject);
    callback->perl.next = next;
    if (next)
        xspr_promise_incref(aTHX_ callback->perl.next);
    return callback;
}

xspr_callback_t* xspr_callback_new_finally(pTHX_ SV* on_finally, xspr_promise_t* next)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_FINALLY;
    if (SvOK(on_finally))
        callback->finally.on_finally = newSVsv(on_finally);
    callback->finally.next = next;
    if (next)
        xspr_promise_incref(aTHX_ callback->finally.next);
    return callback;
}

xspr_callback_t* xspr_callback_new_chain(pTHX_ xspr_promise_t* chain)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_CHAIN;
    callback->chain = chain;
    xspr_promise_incref(aTHX_ chain);
    return callback;
}

/* Adds a then to the promise. Takes ownership of the callback */
void xspr_promise_then(pTHX_ xspr_promise_t* promise, xspr_callback_t* callback)
{
    if (promise->state == XSPR_STATE_PENDING) {
        promise->pending.callbacks_count++;
        Renew(promise->pending.callbacks, promise->pending.callbacks_count, xspr_callback_t*);
        promise->pending.callbacks[promise->pending.callbacks_count-1] = callback;

    } else if (promise->state == XSPR_STATE_FINISHED) {
        xspr_queue_add(aTHX_ callback, promise);

    } else {
        assert(0);
    }
}

/* Returns a promise if the given SV is a thenable. Ownership handed to the caller! */
xspr_promise_t* xspr_promise_from_sv(pTHX_ SV* input)
{
    if (input == NULL || !sv_isobject(input)) {
        return NULL;
    }

    /* If we got one of our own promises: great, not much to do here! */
    if (sv_derived_from(input, "AnyEvent::XSPromises::PromisePtr")) {
        IV tmp = SvIV((SV*)SvRV(input));
        AnyEvent__XSPromises__Promise* promise = INT2PTR(AnyEvent__XSPromises__Promise*, tmp);
        xspr_promise_incref(aTHX_ promise->promise);
        return promise->promise;
    }

    /* Maybe we got another type of promise. Let's convert it */
    GV* method_gv = gv_fetchmethod_autoload(SvSTASH(SvRV(input)), "then", FALSE);
    if (method_gv != NULL && isGV(method_gv) && GvCV(method_gv) != NULL) {
        dMY_CXT;

        xspr_result_t* new_result = xspr_invoke_perl(aTHX_ MY_CXT.conversion_helper, &input, 1);
        if (new_result->state == XSPR_RESULT_RESOLVED &&
            new_result->count == 1 &&
            new_result->result[0] != NULL &&
            SvROK(new_result->result[0]) &&
            sv_derived_from(new_result->result[0], "AnyEvent::XSPromises::PromisePtr")) {
            /* This is expected: our conversion function returned us one of our own promises */
            IV tmp = SvIV((SV*)SvRV(new_result->result[0]));
            AnyEvent__XSPromises__Promise* new_promise = INT2PTR(AnyEvent__XSPromises__Promise*, tmp);

            xspr_promise_t* promise = new_promise->promise;
            xspr_promise_incref(aTHX_ promise);

            xspr_result_decref(aTHX_ new_result);
            return promise;

        } else {
            xspr_promise_t* promise = xspr_promise_new(aTHX);
            xspr_promise_finish(aTHX_ promise, new_result);
            xspr_result_decref(aTHX_ new_result);
            return promise;
        }
    }

    /* We didn't get a promise. */
    return NULL;
}


MODULE = AnyEvent::XSPromises     PACKAGE = AnyEvent::XSPromises

PROTOTYPES: ENABLE

TYPEMAP: <<EOT
TYPEMAP
AnyEvent::XSPromises::Deferred* T_PTROBJ
AnyEvent::XSPromises::Promise* T_PTROBJ
EOT

BOOT:
{
    /* XXX: do we need a CLONE? */

    MY_CXT_INIT;
    MY_CXT.queue_head = NULL;
    MY_CXT.queue_tail = NULL;
    MY_CXT.in_flush = 0;
    MY_CXT.backend_scheduled = 0;
    MY_CXT.conversion_helper = NULL;
    MY_CXT.backend_fn = NULL;
}

AnyEvent::XSPromises::Deferred*
deferred()
    CODE:
        Newxz(RETVAL, 1, AnyEvent__XSPromises__Deferred);
        xspr_promise_t* promise = xspr_promise_new(aTHX);
        RETVAL->promise = promise;
    OUTPUT:
        RETVAL

void
___flush()
    CODE:
        xspr_queue_flush(aTHX);

void
___set_conversion_helper(helper)
        SV* helper
    CODE:
        dMY_CXT;
        if (MY_CXT.conversion_helper != NULL)
            croak("Refusing to set a conversion helper twice");
        MY_CXT.conversion_helper = newSVsv(helper);

void
___set_backend(backend)
        SV* backend
    CODE:
        dMY_CXT;
        if (MY_CXT.backend_fn != NULL)
            croak("Refusing to set a backend twice");
        MY_CXT.backend_fn = newSVsv(backend);


MODULE = AnyEvent::XSPromises     PACKAGE = AnyEvent::XSPromises::DeferredPtr

AnyEvent::XSPromises::Promise*
promise(self)
        AnyEvent::XSPromises::Deferred* self
    CODE:
        Newxz(RETVAL, 1, AnyEvent__XSPromises__Promise);
        RETVAL->promise = self->promise;
        xspr_promise_incref(aTHX_ RETVAL->promise);
    OUTPUT:
        RETVAL

void
resolve(self, ...)
        AnyEvent::XSPromises::Deferred* self
    CODE:
        if (self->promise->state != XSPR_STATE_PENDING) {
            croak("Cannot resolve deferred: not pending");
        }

        xspr_result_t* result = xspr_result_new(aTHX_ XSPR_RESULT_RESOLVED, items-1);
        int i;
        for (i = 0; i < items-1; i++) {
            result->result[i] = newSVsv(ST(1+i));
        }
        xspr_promise_finish(aTHX_ self->promise, result);
        xspr_result_decref(aTHX_ result);
        xspr_queue_maybe_schedule(aTHX);

void
reject(self, ...)
        AnyEvent::XSPromises::Deferred* self
    CODE:
        if (self->promise->state != XSPR_STATE_PENDING) {
            croak("Cannot reject deferred: not pending");
        }

        xspr_result_t* result = xspr_result_new(aTHX_ XSPR_RESULT_REJECTED, items-1);
        int i;
        for (i = 0; i < items-1; i++) {
            result->result[i] = newSVsv(ST(1+i));
        }
        xspr_promise_finish(aTHX_ self->promise, result);
        xspr_result_decref(aTHX_ result);
        xspr_queue_maybe_schedule(aTHX);

bool
is_in_progress(self)
        AnyEvent::XSPromises::Deferred* self
    CODE:
        RETVAL = (self->promise->state == XSPR_STATE_PENDING);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        AnyEvent::XSPromises::Deferred* self
    CODE:
        xspr_promise_decref(aTHX_ self->promise);
        Safefree(self);


MODULE = AnyEvent::XSPromises     PACKAGE = AnyEvent::XSPromises::PromisePtr

void
then(self, ...)
        AnyEvent::XSPromises::Promise* self
    PPCODE:
        SV* on_resolve;
        SV* on_reject;
        xspr_promise_t* next = NULL;

        if (items > 3) {
            croak_xs_usage(cv, "self, on_resolve, on_reject");
        }

        on_resolve = (items > 1) ? ST(1) : &PL_sv_undef;
        on_reject  = (items > 2) ? ST(2) : &PL_sv_undef;

        /* Many promises are just thrown away after the final callback, no need to allocate a next promise for those */
        if (GIMME_V != G_VOID) {
            AnyEvent__XSPromises__Promise* next_promise;
            Newxz(next_promise, 1, AnyEvent__XSPromises__Promise);

            next = xspr_promise_new(aTHX);
            next_promise->promise = next;

            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AnyEvent::XSPromises::PromisePtr", (void*)next_promise);
        }

        xspr_callback_t* callback = xspr_callback_new_perl(aTHX_ on_resolve, on_reject, next);
        xspr_promise_then(aTHX_ self->promise, callback);
        xspr_queue_maybe_schedule(aTHX);

        XSRETURN(1);

void
catch(self, on_reject)
        AnyEvent::XSPromises::Promise* self
        SV* on_reject
    PPCODE:
        xspr_promise_t* next = NULL;

        /* Many promises are just thrown away after the final callback, no need to allocate a next promise for those */
        if (GIMME_V != G_VOID) {
            AnyEvent__XSPromises__Promise* next_promise;
            Newxz(next_promise, 1, AnyEvent__XSPromises__Promise);

            next = xspr_promise_new(aTHX);
            next_promise->promise = next;

            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AnyEvent::XSPromises::PromisePtr", (void*)next_promise);
        }

        xspr_callback_t* callback = xspr_callback_new_perl(aTHX_ &PL_sv_undef, on_reject, next);
        xspr_promise_then(aTHX_ self->promise, callback);
        xspr_queue_maybe_schedule(aTHX);

        XSRETURN(1);

void
finally(self, on_finally)
        AnyEvent::XSPromises::Promise* self
        SV* on_finally
    PPCODE:
        xspr_promise_t* next = NULL;

        /* Many promises are just thrown away after the final callback, no need to allocate a next promise for those */
        if (GIMME_V != G_VOID) {
            AnyEvent__XSPromises__Promise* next_promise;
            Newxz(next_promise, 1, AnyEvent__XSPromises__Promise);

            next = xspr_promise_new(aTHX);
            next_promise->promise = next;

            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), "AnyEvent::XSPromises::PromisePtr", (void*)next_promise);
        }

        xspr_callback_t* callback = xspr_callback_new_finally(aTHX_ on_finally, next);
        xspr_promise_then(aTHX_ self->promise, callback);
        xspr_queue_maybe_schedule(aTHX);

        XSRETURN(1);

void
DESTROY(self)
        AnyEvent::XSPromises::Promise* self
    CODE:
        xspr_promise_decref(aTHX_ self->promise);
        Safefree(self);
