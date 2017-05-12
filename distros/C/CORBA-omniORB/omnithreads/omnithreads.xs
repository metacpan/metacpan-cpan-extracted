#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef HAS_PPPORT_H
#  define NEED_PL_signals
#  define NEED_newRV_noinc
#  define NEED_sv_2pv_nolen
#  define NEED_SvREFCNT_inc_void
#  include "ppport.h"
#endif

#ifndef DPTR2FPTR
#define DPTR2FPTR(t,p) ((t)(PTRV)(p))
#endif 

#include <omnithread.h>

#if !defined(USE_ITHREADS)
#error Unsupported threading model
#endif

#if !defined(HAS_GETPAGESIZE) && defined(I_SYS_PARAM)
#  include <sys/param.h>
#endif

/* Values for 'state' member */
#define PERL_ITHR_JOINABLE              0
#define PERL_ITHR_DETACHED              1
#define PERL_ITHR_JOINED                2
#define PERL_ITHR_FINISHED              4
#define PERL_ITHR_THREAD_EXIT_ONLY      8

struct ithread {
    ithread *next;      /* Next thread in the list */
    ithread *prev;      /* Prev thread in the list */
    PerlInterpreter *interp;    /* The threads interpreter */
    UV tid;                     /* Threads module's thread id */
    omni_mutex mutex;           /* Mutex for updating things in this struct */
    int count;                  /* How many SVs have a reference to us */
    int state;                  /* Detached, joined, finished, etc. */
    int gimme;                  /* Context of create */
    SV *init_function;          /* Code to run */
    SV *params;                 /* Args to pass function */
    omni_thread *thr;		/* omnithread wrapper for the thread */
    IV stack_size;

    static UV tid_counter;

    ithread(int state, int gimme)
	: next(0),
	  prev(0),
	  interp(0),
	  tid(tid_counter++),
	  count(1),
	  state(state),
	  gimme(gimme),
	  init_function(0),
	  params(0),
	  thr(0),
	  stack_size(0) {
	// Nothing else
    }
};

/* Used by Perl interpreter for thread context switching */
#define MY_CXT_KEY "omnithreads::_guts" XS_VERSION

typedef struct {
    ithread *thread;
} my_cxt_t;

START_MY_CXT

UV ithread::tid_counter = 0;

/* Structure for 'main' thread
 * Also forms the 'base' for the doubly-linked list of threads */
static ithread main_thread(PERL_ITHR_DETACHED, 0);

/* Protects the creation and destruction of threads*/
static omni_mutex create_destruct_mutex;

static IV joinable_threads = 0;
static IV running_threads = 0;
static IV detached_threads = 0;
static IV default_stack_size = 0;
static IV page_size = 0;

static UV
S_dummy_unlock(pTHX)
{
  return 0UL;
}

static UV (*unlock_interpreter)(pTHX) = S_dummy_unlock;

static void
S_dummy_relock(pTHX_ UV token)
{
}

static void (*relock_interpreter)(pTHX, UV token) = S_dummy_relock;

/* Used by Perl interpreter for thread context switching */
static void
S_ithread_set(pTHX_ ithread *thread)
{
    dMY_CXT;
    MY_CXT.thread = thread;
}

static ithread *
S_ithread_get(pTHX)
{
    dMY_CXT;
    return (MY_CXT.thread);
}


/* Free any data (such as the Perl interpreter) attached to an ithread
 * structure.  This is a bit like undef on SVs, where the SV isn't freed,
 * but the PVX is.  Must be called with thread->mutex already held.
 */
static void
S_ithread_clear(pTHX_ ithread *thread)
{
    PerlInterpreter *interp;

    assert((thread->state & PERL_ITHR_FINISHED) &&
           (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)));

    interp = thread->interp;
    if (interp) {
        dTHXa(interp);

        PERL_SET_CONTEXT(interp);
        S_ithread_set(aTHX_ thread);

        SvREFCNT_dec(thread->params);
        thread->params = Nullsv;

        perl_destruct(interp);
        perl_free(interp);
        thread->interp = NULL;
    }

    PERL_SET_CONTEXT(aTHX);
}


/* Free an ithread structure and any attached data if its count == 0 */
static void
S_ithread_destruct(pTHX_ ithread *thread)
{
    /* Return if thread is still being used */
    if (thread->count != 0) {
        return;
    }

    /* Main thread (0) is immortal and should never get here */
    assert(thread->tid != 0);

    /* Remove from circular list of threads */
    {
	omni_mutex_lock lock(create_destruct_mutex);
	thread->next->prev = thread->prev;
	thread->prev->next = thread->next;
	thread->next = NULL;
	thread->prev = NULL;
    }
    
    /* Thread is now disowned */
    thread->mutex.lock();
    S_ithread_clear(aTHX_ thread);

    thread->mutex.unlock();

    delete thread;
}


/* Warn if exiting with any unjoined threads */
static int
S_exit_warning(pTHX)
{
    int veto_cleanup;

    {
	omni_mutex_lock lock(create_destruct_mutex);
	veto_cleanup = (running_threads || joinable_threads);
    }

    if (veto_cleanup) {
        if (ckWARN_d(WARN_THREADS)) {
            Perl_warn(aTHX_ "Perl exited with active threads:\n\t%"
                            IVdf " running and unjoined\n\t%"
                            IVdf " finished and unjoined\n\t%"
                            IVdf " running and detached\n",
                            running_threads,
                            joinable_threads,
                            detached_threads);
        }
    }

    return (veto_cleanup);
}

/* Called on exit from main thread */
int
Perl_ithread_hook(pTHX)
{
    return ((aTHX == PL_curinterp) ? S_exit_warning(aTHX) : 0);
}


/* MAGIC (in mg.h sense) hooks */

int
ithread_mg_get(pTHX_ SV *sv, MAGIC *mg)
{
    ithread *thread = (ithread *)mg->mg_ptr;
    SvIV_set(sv, PTR2IV(thread));
    SvIOK_on(sv);
    return (0);
}

int
ithread_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    ithread *thread = (ithread *)mg->mg_ptr;
    int cleanup;

    {
	omni_mutex_lock lock(thread->mutex);
	cleanup = ((--thread->count == 0) &&
		   (thread->state & PERL_ITHR_FINISHED) &&
		   (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)));
    }

    if (cleanup) {
        S_ithread_destruct(aTHX_ thread);
    }
    return (0);
}

int
ithread_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    ithread *thread = (ithread *)mg->mg_ptr;
    omni_mutex_lock lock(thread->mutex);
    thread->count++;
    return (0);
}

MGVTBL ithread_vtbl = {
    ithread_mg_get,     /* get */
    0,                  /* set */
    0,                  /* len */
    0,                  /* clear */
    ithread_mg_free,    /* free */
    0,                  /* copy */
    ithread_mg_dup      /* dup */
};


/* Starts executing the thread.
 * Passed as the C level function to run in the new thread.
 */
static void *
S_ithread_run(void * arg)
{
    ithread *thread = (ithread *)arg;
    int jmp_rc = 0;
    I32 oldscope;
    int exit_app = 0;
    int exit_code = 0;
    int cleanup;

    dJMPENV;

    dTHXa(thread->interp);

    /* Blocked until ->create() call finishes */
    thread->mutex.lock();
    thread->mutex.unlock();

    PERL_SET_CONTEXT(thread->interp);
    S_ithread_set(aTHX_ thread);

    PL_perl_destruct_level = 2;

    {
        AV *params = (AV *)SvRV(thread->params);
        int len = (int)av_len(params)+1;
        int ii;

        dSP;
        ENTER;
        SAVETMPS;

        /* Put args on the stack */
        PUSHMARK(SP);
        for (ii=0; ii < len; ii++) {
            XPUSHs(av_shift(params));
        }
        PUTBACK;

        oldscope = PL_scopestack_ix;
        JMPENV_PUSH(jmp_rc);
        if (jmp_rc == 0) {
            /* Run the specified function */
            len = (int)call_sv(thread->init_function, thread->gimme|G_EVAL);
        } else if (jmp_rc == 2) {
            /* Thread exited */
            exit_app = 1;
            exit_code = STATUS_CURRENT;
            while (PL_scopestack_ix > oldscope) {
                LEAVE;
            }
        }
        JMPENV_POP;

        /* Remove args from stack and put back in params array */
        SPAGAIN;
        for (ii=len-1; ii >= 0; ii--) {
            SV *sv = POPs;
            if (jmp_rc == 0) {
                av_store(params, ii, SvREFCNT_inc(sv));
            }
        }

        FREETMPS;
        LEAVE;

        /* Check for failure */
        if (SvTRUE(ERRSV) && ckWARN_d(WARN_THREADS)) {
            oldscope = PL_scopestack_ix;
            JMPENV_PUSH(jmp_rc);
            if (jmp_rc == 0) {
                /* Warn that thread died */
                Perl_warn(aTHX_ "Thread %" UVuf " terminated abnormally: %" SVf, thread->tid, ERRSV);
            } else if (jmp_rc == 2) {
                /* Warn handler exited */
                exit_app = 1;
                exit_code = STATUS_CURRENT;
                while (PL_scopestack_ix > oldscope) {
                    LEAVE;
                }
            }
            JMPENV_POP;
        }

        /* Release function ref */
        SvREFCNT_dec(thread->init_function);
        thread->init_function = Nullsv;
    }

    PerlIO_flush((PerlIO *)NULL);

    create_destruct_mutex.lock();
    thread->mutex.lock();
    /* Mark as finished */
    thread->state |= PERL_ITHR_FINISHED;
    /* Clear exit flag if required */
    if (thread->state & PERL_ITHR_THREAD_EXIT_ONLY) {
        exit_app = 0;
    }
    /* Cleanup if detached */
    cleanup = (thread->state & PERL_ITHR_DETACHED);
    thread->mutex.unlock();

    /* Adjust thread status counts */
    if (cleanup) {
        detached_threads--;
    } else {
        running_threads--;
        joinable_threads++;
    }
    create_destruct_mutex.unlock();

    /* Exit application if required */
    if (exit_app) {
        oldscope = PL_scopestack_ix;
        JMPENV_PUSH(jmp_rc);
        if (jmp_rc == 0) {
            /* Warn if there are unjoined threads */
            S_exit_warning(aTHX);
        } else if (jmp_rc == 2) {
            /* Warn handler exited */
            exit_code = STATUS_CURRENT;
            while (PL_scopestack_ix > oldscope) {
                LEAVE;
            }
        }
        JMPENV_POP;

        my_exit(exit_code);
    }

    /* Clean up detached thread */
    if (cleanup) {
        S_ithread_destruct(aTHX_ thread);
    }

    return (0);
}


/* Type conversion helper functions */

static SV *
ithread_to_SV(pTHX_ SV *obj, ithread *thread, char *classname, bool inc)
{
    SV *sv;
    MAGIC *mg;

    /* If incrementing thread ref count, then call within mutex lock */
    if (inc) {
        omni_mutex_lock lock(thread->mutex);
        thread->count++;
    }

    if (! obj) {
        obj = newSV(0);
    }

    sv = newSVrv(obj, classname);
    sv_setiv(sv, PTR2IV(thread));
    mg = sv_magicext(sv, Nullsv, PERL_MAGIC_shared_scalar, &ithread_vtbl, (char *)thread, 0);
    mg->mg_flags |= MGf_DUP;
    SvREADONLY_on(sv);

    return (obj);
}

static ithread *
SV_to_ithread(pTHX_ SV *sv)
{
    /* Argument is a thread */
    if (SvROK(sv)) {
      return (INT2PTR(ithread *, SvIV(SvRV(sv))));
    }
    /* Argument is classname, therefore return current thread */
    return (S_ithread_get(aTHX));
}


/* threads->create()
 * Called in context of parent thread.
 */
static ithread *
S_ithread_create(
        pTHX_ SV *init_function,
        IV        stack_size,
        int       gimme,
        int       exit_opt,
        SV       *params)
{
    ithread     *thread;
    CLONE_PARAMS clone_param;
    ithread     *current_thread = S_ithread_get(aTHX);

    SV         **tmps_tmp = PL_tmps_stack;
    IV           tmps_ix  = PL_tmps_ix;

    /* Allocate thread structure */
    thread = new ithread(exit_opt, gimme);
    if (!thread) {
        create_destruct_mutex.unlock();
        PerlLIO_write(PerlIO_fileno(Perl_error_log),
		      PL_no_mem, strlen(PL_no_mem));
        my_exit(1);
    }

    /* Add to threads list */
    thread->next = &main_thread;
    thread->prev = main_thread.prev;
    main_thread.prev = thread;
    thread->prev->next = thread;

    /* Block new thread until ->create() call finishes */
    thread->mutex.lock();

    /* "Clone" our interpreter into the thread's interpreter.
     * This gives thread access to "static data" and code.
     */
    PerlIO_flush((PerlIO *)NULL);
    S_ithread_set(aTHX_ thread);

    SAVEBOOL(PL_srand_called); /* Save this so it becomes the correct value */
    PL_srand_called = FALSE;   /* Set it to false so we can detect if it gets
                                  set during the clone */

#ifdef WIN32
    thread->interp
	= perl_clone(aTHX, CLONEf_KEEP_PTR_TABLE | CLONEf_CLONE_HOST);
#else
    thread->interp
	= perl_clone(aTHX, CLONEf_KEEP_PTR_TABLE);
#endif

    /* perl_clone() leaves us in new interpreter's context.  As it is tricky
     * to spot an implicit aTHX, create a new scope with aTHX matching the
     * context for the duration of our work for new interpreter.
     */
    {
        dTHXa(thread->interp);

        MY_CXT_CLONE;

        /* Here we remove END blocks since they should only run in the thread
         * they are created
         */
        SvREFCNT_dec(PL_endav);
        PL_endav = newAV();

        if (SvPOK(init_function)) {
            thread->init_function = newSV(0);
            sv_copypv(thread->init_function, init_function);
        } else {
            clone_param.flags = 0;
            thread->init_function = sv_dup(init_function, &clone_param);
            if (SvREFCNT(thread->init_function) == 0) {
                SvREFCNT_inc_void(thread->init_function);
            }
        }

        thread->params = sv_dup(params, &clone_param);
        SvREFCNT_inc_void(thread->params);

        /* The code below checks that anything living on the tmps stack and
         * has been cloned (so it lives in the ptr_table) has a refcount
         * higher than 0.
         *
         * If the refcount is 0 it means that a something on the stack/context
         * was holding a reference to it and since we init_stacks() in
         * perl_clone that won't get cleaned and we will get a leaked scalar.
         * The reason it was cloned was that it lived on the @_ stack.
         *
         * Example of this can be found in bugreport 15837 where calls in the
         * parameter list end up as a temp.
         *
         * One could argue that this fix should be in perl_clone.
         */
        while (tmps_ix > 0) {
            SV* sv = (SV*)ptr_table_fetch(PL_ptr_table, tmps_tmp[tmps_ix]);
            tmps_ix--;
            if (sv && SvREFCNT(sv) == 0) {
                SvREFCNT_inc_void(sv);
                SvREFCNT_dec(sv);
            }
        }

        SvTEMP_off(thread->init_function);
        ptr_table_free(PL_ptr_table);
        PL_ptr_table = NULL;
        PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    }
    S_ithread_set(aTHX_ current_thread);
    PERL_SET_CONTEXT(aTHX);

    /* Create/start the thread */
    thread->thr = new omni_thread(S_ithread_run, (void *) thread);

    /* Check for errors */
    if (thread->thr) {
	thread->thr->start();
    }
    else {
        create_destruct_mutex.unlock();
        sv_2mortal(params);
        S_ithread_destruct(aTHX_ thread);
        return (NULL);
    }

    running_threads++;
    sv_2mortal(params);
    return (thread);
}

MODULE = omnithreads    PACKAGE = omnithreads    PREFIX = ithread_
PROTOTYPES: DISABLE

void
ithread_create(...)
    PREINIT:
        char *classname;
        ithread *thread;
        SV *function_to_call;
        AV *params;
        HV *specs;
        IV stack_size;
        int context;
        int exit_opt;
        SV *thread_exit_only;
        char *str;
        int idx;
        int ii;
    CODE:
        if ((items >= 2) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1)))==SVt_PVHV) {
            if (--items < 2) {
                Perl_croak(aTHX_ "Usage: threads->create(\\%specs, function, ...)");
            }
            specs = (HV*)SvRV(ST(1));
            idx = 1;
        } else {
            if (items < 2) {
                Perl_croak(aTHX_ "Usage: threads->create(function, ...)");
            }
            specs = NULL;
            idx = 0;
        }

        if (sv_isobject(ST(0))) {
            /* $thr->create() */
            classname = HvNAME(SvSTASH(SvRV(ST(0))));
            thread = INT2PTR(ithread *, SvIV(SvRV(ST(0))));
            stack_size = thread->stack_size;
            exit_opt = thread->state & PERL_ITHR_THREAD_EXIT_ONLY;
        } else {
            /* threads->create() */
            classname = (char *)SvPV_nolen(ST(0));
            stack_size = default_stack_size;
            thread_exit_only = get_sv("omnithreads::thread_exit_only", TRUE);
            exit_opt = (SvTRUE(thread_exit_only))
                                    ? PERL_ITHR_THREAD_EXIT_ONLY : 0;
        }

        function_to_call = ST(idx+1);

        context = -1;
        if (specs) {
            /* stack_size */
            if (hv_exists(specs, "stack", 5)) {
                stack_size = SvIV(*hv_fetch(specs, "stack", 5, 0));
            } else if (hv_exists(specs, "stacksize", 9)) {
                stack_size = SvIV(*hv_fetch(specs, "stacksize", 9, 0));
            } else if (hv_exists(specs, "stack_size", 10)) {
                stack_size = SvIV(*hv_fetch(specs, "stack_size", 10, 0));
            }

            /* context */
            if (hv_exists(specs, "context", 7)) {
                str = (char *)SvPV_nolen(*hv_fetch(specs, "context", 7, 0));
                switch (*str) {
                    case 'a':
                    case 'A':
                        context = G_ARRAY;
                        break;
                    case 's':
                    case 'S':
                        context = G_SCALAR;
                        break;
                    case 'v':
                    case 'V':
                        context = G_VOID;
                        break;
                    default:
                        Perl_croak(aTHX_ "Invalid context: %s", str);
                }
            } else if (hv_exists(specs, "array", 5)) {
                if (SvTRUE(*hv_fetch(specs, "array", 5, 0))) {
                    context = G_ARRAY;
                }
            } else if (hv_exists(specs, "scalar", 6)) {
                if (SvTRUE(*hv_fetch(specs, "scalar", 6, 0))) {
                    context = G_SCALAR;
                }
            } else if (hv_exists(specs, "void", 4)) {
                if (SvTRUE(*hv_fetch(specs, "void", 4, 0))) {
                    context = G_VOID;
                }
            }

            /* exit => thread_only */
            if (hv_exists(specs, "exit", 4)) {
                str = (char *)SvPV_nolen(*hv_fetch(specs, "exit", 4, 0));
                exit_opt = (*str == 't' || *str == 'T')
                                    ? PERL_ITHR_THREAD_EXIT_ONLY : 0;
            }
        }
        if (context == -1) {
            context = GIMME_V;  /* Implicit context */
        } else {
            context |= (GIMME_V & (~(G_ARRAY|G_SCALAR|G_VOID)));
        }

        /* Function args */
        params = newAV();
        if (items > 2) {
            for (ii=2; ii < items ; ii++) {
                av_push(params, SvREFCNT_inc(ST(idx+ii)));
            }
        }

        /* Create thread */
        create_destruct_mutex.lock();
        thread = S_ithread_create(aTHX_ function_to_call,
                                        stack_size,
                                        context,
                                        exit_opt,
                                        newRV_noinc((SV*)params));
        if (! thread) {
            XSRETURN_UNDEF;
        }
        ST(0) = sv_2mortal(ithread_to_SV(aTHX_ Nullsv, thread, classname, FALSE));

        /* Let thread run */
        thread->mutex.unlock();
        create_destruct_mutex.unlock();

        /* XSRETURN(1); - implied */


void
ithread_list(...)
    PREINIT:
        char *classname;
        ithread *thread;
        int list_context;
        IV count = 0;
        int want_running;
    PPCODE:
        /* Class method only */
        if (SvROK(ST(0))) {
            Perl_croak(aTHX_ "Usage: threads->list(...)");
        }
        classname = (char *)SvPV_nolen(ST(0));

        /* Calling context */
        list_context = (GIMME_V == G_ARRAY);

        /* Running or joinable parameter */
        if (items > 1) {
            want_running = SvTRUE(ST(1));
        }

        /* Walk through threads list */
        create_destruct_mutex.lock();
        for (thread = main_thread.next;
             thread != &main_thread;
             thread = thread->next)
        {
            /* Ignore detached or joined threads */
            if (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)) {
                continue;
            }

            /* Filter per parameter */
            if (items > 1) {
                if (want_running) {
                    if (thread->state & PERL_ITHR_FINISHED) {
                        continue;   /* Not running */
                    }
                } else {
                    if (! (thread->state & PERL_ITHR_FINISHED)) {
                        continue;   /* Still running - not joinable yet */
                    }
                }
            }

            /* Push object on stack if list context */
            if (list_context) {
                XPUSHs(sv_2mortal(ithread_to_SV(aTHX_ Nullsv, thread, classname, TRUE)));
            }
            count++;
        }
        create_destruct_mutex.unlock();
        /* If scalar context, send back count */
        if (! list_context) {
            XSRETURN_IV(count);
        }


void
ithread_self(...)
    PREINIT:
        char *classname;
        ithread *thread;
    CODE:
        /* Class method only */
        if (SvROK(ST(0))) {
            Perl_croak(aTHX_ "Usage: threads->self()");
        }
        classname = (char *)SvPV_nolen(ST(0));

        thread = S_ithread_get(aTHX);

        ST(0) = sv_2mortal(ithread_to_SV(aTHX_ Nullsv, thread, classname, TRUE));
        /* XSRETURN(1); - implied */


void
ithread_tid(...)
    PREINIT:
        ithread *thread;
    CODE:
        thread = SV_to_ithread(aTHX_ ST(0));
        XST_mUV(0, thread->tid);
        /* XSRETURN(1); - implied */


void
ithread_join(...)
    PREINIT:
        ithread *thread;
        int join_err;
        AV *params;
        int len;
        int ii;
        void *retval;
    PPCODE:
        /* Object method only */
        if (! sv_isobject(ST(0))) {
            Perl_croak(aTHX_ "Usage: $thr->join()");
        }

        /* Check if the thread is joinable */
        thread = SV_to_ithread(aTHX_ ST(0));
        join_err = (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED));
        if (join_err) {
            if (join_err & PERL_ITHR_DETACHED) {
                Perl_croak(aTHX_ "Cannot join a detached thread");
            } else {
                Perl_croak(aTHX_ "Thread already joined");
            }
        }

        /* Join the thread */
        PUTBACK;
        {
	    UV token = unlock_interpreter(aTHX);
	    thread->thr->join(0);    
	    relock_interpreter(aTHX_ token);
	}
        SPAGAIN;

        thread->mutex.lock();
        /* Mark as joined */
        thread->state |= PERL_ITHR_JOINED;

        /* Get the return value from the call_sv */
        {
            AV *params_copy;
            PerlInterpreter *other_perl;
            CLONE_PARAMS clone_params;
            ithread *current_thread;

            params_copy = (AV *)SvRV(thread->params);
            other_perl = thread->interp;
            clone_params.stashes = newAV();
            clone_params.flags = CLONEf_JOIN_IN;
            PL_ptr_table = ptr_table_new();
            current_thread = S_ithread_get(aTHX);
            S_ithread_set(aTHX_ thread);
            /* Ensure 'meaningful' addresses retain their meaning */
            ptr_table_store(PL_ptr_table, &other_perl->Isv_undef, &PL_sv_undef);
            ptr_table_store(PL_ptr_table, &other_perl->Isv_no, &PL_sv_no);
            ptr_table_store(PL_ptr_table, &other_perl->Isv_yes, &PL_sv_yes);
            params = (AV *)sv_dup((SV*)params_copy, &clone_params);
            S_ithread_set(aTHX_ current_thread);
            SvREFCNT_dec(clone_params.stashes);
            SvREFCNT_inc_void(params);
            ptr_table_free(PL_ptr_table);
            PL_ptr_table = NULL;
        }

        /* We are finished with the thread */
        S_ithread_clear(aTHX_ thread);
        thread->mutex.unlock();

        {
	    omni_mutex_lock lock(create_destruct_mutex);
	    if (! (thread->state & PERL_ITHR_DETACHED)) {
		joinable_threads--;
	    }
	}

        /* If no return values, then just return */
        if (! params) {
            XSRETURN_UNDEF;
        }

        /* Put return values on stack */
        len = (int)AvFILL(params);
        for (ii=0; ii <= len; ii++) {
            SV* param = av_shift(params);
            XPUSHs(sv_2mortal(param));
        }

        /* Free return value array */
        SvREFCNT_dec(params);


void
ithread_yield(...)
    CODE:
        YIELD;


void
ithread_detach(...)
    PREINIT:
        ithread *thread;
        int detach_err;
        int cleanup;
    CODE:
        /* Check if the thread is detachable */
        thread = SV_to_ithread(aTHX_ ST(0));
        if ((detach_err = (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)))) {
            if (detach_err & PERL_ITHR_DETACHED) {
                Perl_croak(aTHX_ "Thread already detached");
            } else {
                Perl_croak(aTHX_ "Cannot detach a joined thread");
            }
        }

        /* Detach the thread */
        create_destruct_mutex.lock();
        thread->mutex.lock();
        thread->state |= PERL_ITHR_DETACHED;

        /* The omnithread library has no 'detach thread' function */

        /* Cleanup if finished */
        cleanup = (thread->state & PERL_ITHR_FINISHED);
        thread->mutex.unlock();

        if (cleanup) {
            joinable_threads--;
        } else {
            running_threads--;
            detached_threads++;
        }
        create_destruct_mutex.unlock();

        if (cleanup) {
            S_ithread_destruct(aTHX_ thread);
        }


void
ithread_kill(...)
    PREINIT:
        ithread *thread;
        char *sig_name;
        IV signal;
    CODE:
        /* Must have safe signals */
        if (PL_signals & PERL_SIGNALS_UNSAFE_FLAG) {
            Perl_croak(aTHX_ "Cannot signal threads without safe signals");
        }

        /* Object method only */
        if (! sv_isobject(ST(0))) {
            Perl_croak(aTHX_ "Usage: $thr->kill('SIG...')");
        }

        /* Get signal */
        sig_name = SvPV_nolen(ST(1));
        if (isALPHA(*sig_name)) {
            if (*sig_name == 'S' && sig_name[1] == 'I' && sig_name[2] == 'G') {
                sig_name += 3;
            }
            if ((signal = whichsig(sig_name)) < 0) {
                Perl_croak(aTHX_ "Unrecognized signal name: %s", sig_name);
            }
        } else {
            signal = SvIV(ST(1));
        }

        /* Set the signal for the thread */
        thread = SV_to_ithread(aTHX_ ST(0));
        {
	    omni_mutex_lock lock(thread->mutex);
	    if (thread->interp) {
		dTHXa(thread->interp);
		PL_psig_pend[signal]++;
		PL_sig_pending = 1;
	    }
	}

        /* Return the thread to allow for method chaining */
        ST(0) = ST(0);
        /* XSRETURN(1); - implied */


void
ithread_DESTROY(...)
    CODE:
        sv_unmagic(SvRV(ST(0)), PERL_MAGIC_shared_scalar);


void
ithread_equal(...)
    PREINIT:
        int are_equal = 0;
    CODE:
        /* Compares TIDs to determine thread equality */
        if (sv_isobject(ST(0)) && sv_isobject(ST(1))) {
            ithread *thr1 = INT2PTR(ithread *, SvIV(SvRV(ST(0))));
            ithread *thr2 = INT2PTR(ithread *, SvIV(SvRV(ST(1))));
            are_equal = (thr1->tid == thr2->tid);
        }
        if (are_equal) {
            XST_mYES(0);
        } else {
            /* Return 0 on false for backward compatibility */
            XST_mIV(0, 0);
        }
        /* XSRETURN(1); - implied */


void
ithread_object(...)
    PREINIT:
        char *classname;
        UV tid;
        ithread *thread;
        int have_obj = 0;
    CODE:
        /* Class method only */
        if (SvROK(ST(0))) {
            Perl_croak(aTHX_ "Usage: threads->object($tid)");
        }
        classname = (char *)SvPV_nolen(ST(0));

        if ((items < 2) || ! SvOK(ST(1))) {
            XSRETURN_UNDEF;
        }

        /* threads->object($tid) */
        tid = SvUV(ST(1));

        /* Walk through threads list */
        create_destruct_mutex.lock();
        for (thread = main_thread.next;
             thread != &main_thread;
             thread = thread->next)
        {
            /* Look for TID */
            if (thread->tid == tid) {
                /* Ignore if detached or joined */
                if (! (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED))) {
                    /* Put object on stack */
                    ST(0) = sv_2mortal(ithread_to_SV(aTHX_ Nullsv, thread, classname, TRUE));
                    have_obj = 1;
                }
                break;
            }
        }
        create_destruct_mutex.unlock();

        if (! have_obj) {
            XSRETURN_UNDEF;
        }
        /* XSRETURN(1); - implied */


void
ithread__handle(...);
    PREINIT:
        ithread *thread;
    CODE:
        thread = SV_to_ithread(aTHX_ ST(0));
        XST_mUV(0, PTR2UV(&thread->thr));
        /* XSRETURN(1); - implied */


void
ithread_get_stack_size(...)
    PREINIT:
        IV stack_size;
    CODE:
        if (sv_isobject(ST(0))) {
            /* $thr->get_stack_size() */
            ithread *thread = INT2PTR(ithread *, SvIV(SvRV(ST(0))));
            stack_size = thread->stack_size;
        } else {
            /* threads->get_stack_size() */
            stack_size = default_stack_size;
        }
        XST_mIV(0, stack_size);
        /* XSRETURN(1); - implied */


void
ithread_set_stack_size(...)
    PREINIT:
        IV old_size;
    CODE:
        if (items != 2) {
            Perl_croak(aTHX_ "Usage: threads->set_stack_size($size)");
        }
        if (sv_isobject(ST(0))) {
            Perl_croak(aTHX_ "Cannot change stack size of an existing thread");
        }

        old_size = default_stack_size;
        default_stack_size = 0;
        XST_mIV(0, old_size);
        /* XSRETURN(1); - implied */


void
ithread_is_running(...)
    PREINIT:
        ithread *thread;
    CODE:
        /* Object method only */
        if (! sv_isobject(ST(0))) {
            Perl_croak(aTHX_ "Usage: $thr->is_running()");
        }

        thread = INT2PTR(ithread *, SvIV(SvRV(ST(0))));
        ST(0) = (thread->state & PERL_ITHR_FINISHED) ? &PL_sv_no : &PL_sv_yes;
        /* XSRETURN(1); - implied */


void
ithread_is_detached(...)
    PREINIT:
        ithread *thread;
    CODE:
        thread = SV_to_ithread(aTHX_ ST(0));
        ST(0) = (thread->state & PERL_ITHR_DETACHED) ? &PL_sv_yes : &PL_sv_no;
        /* XSRETURN(1); - implied */


void
ithread_is_joinable(...)
    PREINIT:
        ithread *thread;
    CODE:
        /* Object method only */
        if (! sv_isobject(ST(0))) {
            Perl_croak(aTHX_ "Usage: $thr->is_joinable()");
        }

        thread = INT2PTR(ithread *, SvIV(SvRV(ST(0))));
        {
	    omni_mutex_lock lock(thread->mutex);
	    ST(0) = ((thread->state & PERL_ITHR_FINISHED) &&
		     ! (thread->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)))
		? &PL_sv_yes : &PL_sv_no;
	}
        /* XSRETURN(1); - implied */


void
ithread_wantarray(...)
    PREINIT:
        ithread *thread;
    CODE:
        thread = SV_to_ithread(aTHX_ ST(0));
        ST(0) = (thread->gimme & G_ARRAY) ? &PL_sv_yes :
                (thread->gimme & G_VOID)  ? &PL_sv_undef
                           /* G_SCALAR */ : &PL_sv_no;
        /* XSRETURN(1); - implied */


void
ithread_set_thread_exit_only(...)
    PREINIT:
        ithread *thread;
    CODE:
        if (items != 2) {
            Perl_croak(aTHX_ "Usage: ->set_thread_exit_only(boolean)");
        }
        thread = SV_to_ithread(aTHX_ ST(0));
        omni_mutex_lock lock(thread->mutex);
        if (SvTRUE(ST(1))) {
            thread->state |= PERL_ITHR_THREAD_EXIT_ONLY;
        } else {
            thread->state &= ~PERL_ITHR_THREAD_EXIT_ONLY;
        }


BOOT:
{
    int count;
    
    MY_CXT_INIT;

    PL_perl_destruct_level = 2;
    create_destruct_mutex.lock();

    PL_threadhook = &Perl_ithread_hook;

    /* The 'main' thread is thread 0.
     * It is detached (unjoinable) and immortal.
     */

    /* Head of the threads list */
    main_thread.next = &main_thread;
    main_thread.prev = &main_thread;

    main_thread.interp = aTHX;
    main_thread.stack_size = default_stack_size;
    main_thread.thr = omni_thread::self();

    S_ithread_set(aTHX_ &main_thread);
    create_destruct_mutex.unlock();

    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    count = call_pv("CORBA::omniORB::_entry_lock_hooks", G_ARRAY | G_EVAL);
    SPAGAIN;
    if (count == 2) {
	relock_interpreter = DPTR2FPTR(void (*)(pTHX, UV token), POPu);
	unlock_interpreter = DPTR2FPTR(UV (*)(pTHX), POPu);
	
	PUTBACK;
    }
    else {
	warn("Couldn't obtain CORBA::omniORB entry lock hooks");
    }

    FREETMPS;
    LEAVE;
}
