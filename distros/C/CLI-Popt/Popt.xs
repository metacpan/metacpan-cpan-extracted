#include "easyxs/easyxs.h"
#include <popt.h>
#include <stdio.h>
#include <string.h>

#define PERL_NS "CLI::Popt"

struct popt_option_callback_userdata {
#ifdef MULTIPLICITY
    pTHX;
#endif
    HV* result;
};

typedef struct {
    poptContext popt;
    pid_t pid;
    char* name;
    char** last_argv;
    struct poptOption *options;
    struct popt_option_callback_userdata callback_userdata;
} perl_popt_st;

static char** _dup_argv_deep(pTHX_ const char** argv, const char* first) {
    unsigned argc=0;
    while (argv[argc] != NULL) argc++;

    char** new_argv;
    Newxz(new_argv, (first ? 1 : 0) + 1 + argc, char*);

    unsigned cur=0;
    if (first) {
        new_argv[cur++] = savepv(first);
    }

    for (unsigned i=0; i<argc; i++) {
        new_argv[cur++] = savepv(argv[i]);
    }

    return new_argv;
}

static void _free_argv_deep(pTHX_ char** argv) {
    unsigned i=0;

    while (argv[i] != NULL) {
        Safefree(argv[i]);
        i++;
    }

    Safefree(argv);
}

static char* _copy_str_or_null(pTHX_ const char* src_const) {
    char* src_copy;
    if (src_const && strlen(src_const)) {
        src_copy = savepv(src_const);
    }
    else {
        src_copy = NULL;
    }

    return src_copy;
}

#if 0
static char** _copy_perl_argv(pTHX_ SV* argv_ar, int *argc_p) {
    AV* argv_av = (AV*) SvRV(argv_ar);

    char** argv;
    *argc_p = 1 + av_len(argv_av);

    if (*argc_p) {
        Newx(argv, 1 + av_len(argv_av), char*);

        for (int i=0; i < *argc_p; i++) {
            SV** arg_p = av_fetch(argv_av, i, 0);
            assert(arg_p);
            assert(*arg_p);

            const char* argstr = exs_SvPVbyte_nolen(*arg_p);
            argv[i] = _copy_str_or_null(aTHX_ argstr);
        }
    }
    else {
        argv = NULL;
    }

    return argv;
}
#endif

static void _free_popt_options(pTHX_ struct poptOption *opts) {
    if (!opts) return;

    struct poptOption *cur = opts;

    while (cur->longName || cur->shortName) {

        if (cur->argInfo & POPT_ARG_ARGV) {
            ASSUME(0);
        }
        else {
            if (cur->arg) Safefree(cur->arg);
        }

        if (cur->longName) Safefree(cur->longName);

        if ((cur->argInfo & POPT_ARG_MASK) != POPT_ARG_CALLBACK) {
            if (cur->descrip) Safefree(cur->descrip);
        }

        if (cur->argDescrip) Safefree(cur->argDescrip);

        cur++;
    }

    Safefree(opts);
}

static char* _copy_perl_popt_string(pTHX_ HV* curopt_perl, const char* name) {
    char* valcopy;

    SV** svp = hv_fetch(curopt_perl, name, strlen(name), 0);
    if (svp) {
        const char* from_sv = exs_SvPVbyte_nolen(*svp);
        valcopy = _copy_str_or_null(aTHX_ from_sv);
    }
    else {
        valcopy = NULL;
    }

    return valcopy;
}

static void _store_opt_in_hv (pTHX_ const struct poptOption* curopt, HV* hv) {
    SV* val_sv;

    switch (curopt->argInfo & POPT_ARG_MASK) {
        case POPT_ARG_NONE:
        case POPT_ARG_INT:
        case POPT_ARG_VAL:
            val_sv = newSViv( *( (int *) curopt->arg ) );
            break;
        case POPT_ARG_STRING:
            val_sv = newSVpv( *( (char **) curopt->arg ), 0 );
            break;
        case POPT_ARG_ARGV: {
            AV* strs_av = newAV();

            val_sv = newRV_noinc((SV*) strs_av);

            char** argv = *( (char ***) curopt->arg );

            char* curstr;

            while ( (curstr = *argv++) ) {
                av_push(strs_av, newSVpv(curstr, 0));
            }

            } break;
        case POPT_ARG_SHORT:
            val_sv = newSViv( *( (short *) curopt->arg ) );
            break;
        case POPT_ARG_LONG:
            val_sv = newSViv( *( (long *) curopt->arg ) );
            break;
        case POPT_ARG_LONGLONG:
            val_sv = newSViv( *( (long long *) curopt->arg ) );
            break;
        case POPT_ARG_FLOAT:
            val_sv = newSVnv( *( (float *) curopt->arg ) );
            break;
        case POPT_ARG_DOUBLE:
            val_sv = newSVnv( *( (double *) curopt->arg ) );
            break;
        default:
            val_sv = NULL;   // silence compiler warning
            ASSUME(0);
    }

    hv_store(hv, curopt->longName, strlen(curopt->longName), val_sv, 0);
}

static void _popt_option_callback(
    poptContext con,
    enum poptCallbackReason reason,
    const struct poptOption * opt,
    const char * arg,
    void * data
) {
    PERL_UNUSED_ARG(reason);
    ASSUME(data != NULL);

    struct popt_option_callback_userdata* userdata = data;

#ifdef MULTIPLICITY
    pTHX = userdata->aTHX;
#endif

    _store_opt_in_hv(aTHX_ opt, userdata->result);
}

#define CALLBACK_OPTS 1

static struct poptOption* _create_popt_options(pTHX_ perl_popt_st* perl_popt, SV* opts_ar) {
    AV* opts_av = (AV*) SvRV(opts_ar);

    int optslen = 1 + av_len(opts_av);

    struct poptOption *opts;

    // Include the table-ending, final empty opt:
    Newxz(opts, CALLBACK_OPTS + 1 + optslen, struct poptOption);

    if (CALLBACK_OPTS) {
        opts[0] = (struct poptOption) {
            .argInfo = POPT_ARG_CALLBACK,
            .arg = _popt_option_callback,
            .descrip = (void*) &perl_popt->callback_userdata,
        };
    }

    opts[CALLBACK_OPTS + optslen] = (struct poptOption) POPT_TABLEEND;

    // easyxs throws, so it’s important to validate before we allocate
    // memory for anything.
    //
    for (int ii=0; ii<optslen; ii++) {
        SV** cur_hrp = av_fetch(opts_av, ii, 0);
        ASSUME(cur_hrp);
        ASSUME(*cur_hrp);
        ASSUME(SvROK(*cur_hrp));

        HV* curopt_perl = (HV*) SvRV(*cur_hrp);
        ASSUME(SvTYPE(curopt_perl) == SVt_PVHV);

        SV** val_svp = hv_fetchs(curopt_perl, "val", 0);
        if (val_svp && *val_svp) exs_SvIV(*val_svp);
    }

    for (int i=0; i<optslen; i++) {
        SV** cur_hrp = av_fetch(opts_av, i, 0);

        // We validated this above.
        HV* curopt_perl = (HV*) SvRV(*cur_hrp);

        //struct poptOption* curopt = i + 1 + opts;

        char* longname = _copy_perl_popt_string(aTHX_ curopt_perl, "long_name");
        char* descrip = _copy_perl_popt_string(aTHX_ curopt_perl, "descrip");
        char* arg_descrip = _copy_perl_popt_string(aTHX_ curopt_perl, "arg_descrip");

        char shortname;

        SV** sname_svp = hv_fetchs(curopt_perl, "short_name", 0);
        if (sname_svp && *sname_svp && SvOK(*sname_svp)) {
            const char* sname_from_sv = exs_SvPVbyte_nolen(*sname_svp);
            shortname = sname_from_sv[0];
        }
        else {
            shortname = '\0';
        }

        SV** arginfo_svp = hv_fetchs(curopt_perl, "arginfo", 0);
        ASSUME(arginfo_svp);
        ASSUME(*arginfo_svp);

        IV arginfo = SvIV(*arginfo_svp);

        void* arg_p;

        switch (arginfo & POPT_ARG_MASK) {
            case POPT_ARG_NONE:
            case POPT_ARG_INT:
            case POPT_ARG_VAL:
                Newxz(arg_p, 1, int);
                break;
            case POPT_ARG_STRING:
                Newxz(arg_p, 1, char*);
                break;
            case POPT_ARG_ARGV:
                Newxz(arg_p, 1, char**);
                //*( (char***) arg_p) = NULL;
                break;
            case POPT_ARG_SHORT:
                Newxz(arg_p, 1, short);
                break;
            case POPT_ARG_LONG:
                Newxz(arg_p, 1, long);
                break;
            case POPT_ARG_LONGLONG:
                Newxz(arg_p, 1, long long);
                break;
            case POPT_ARG_FLOAT:
                Newxz(arg_p, 1, float);
                break;
            case POPT_ARG_DOUBLE:
                Newxz(arg_p, 1, double);
                break;
            default:
                arg_p = NULL;   // silence compiler warning
                ASSUME(0);
        }

        SV** val_svp = hv_fetchs(curopt_perl, "val", 0);
        int val = (val_svp && *val_svp) ? exs_SvIV(*val_svp) : 0;

        opts[CALLBACK_OPTS + i] = (struct poptOption) {
            .longName = longname,
            .shortName = shortname,
            .argInfo = arginfo,
            .arg = arg_p,
            .val = val,
            .descrip = descrip,
            .argDescrip = arg_descrip,
        };

    }

    return opts;
}

#if 0
static void _stuff_svs_to_argv (pTHX_ poptContext popt, const char* name, SV** svs, int count) {
    const char* my_argv[2 + count];    // need trailing ptr to NULL
    my_argv[0] = name ? name : "";
    for (int i=0; i<count; i++) {
        my_argv[1 + i] = exs_SvPVbyte_nolen(svs[i]);
    }
    my_argv[1 + count] = NULL;

    int err = poptStuffArgs(popt, my_argv);
fprintf(stderr, "stuffargs: %d\n", err);
    if (err) {
        fprintf(stderr, "poptStuffArgs: %d (%s)\n", err, poptStrerror(err));
        assert(0);
    }
}
#endif

#define _CREATE_PERL_CONST(constname) \
    newCONSTSUB( gv_stashpv(PERL_NS, 0), #constname, newSViv(constname) )

// poptStuffArgs causes crashes in some popt releases, so we avoid it;
// instead, we recreate the popt every time argv changes:
//
static void _refresh_popt_ctx(pTHX_ perl_popt_st* perl_popt, int argc, char** argv) {
    if (perl_popt->popt != NULL) {
        poptFreeContext(perl_popt->popt);
    }

    if (perl_popt->last_argv != NULL) {
        _free_argv_deep(aTHX_ perl_popt->last_argv);
    }

    perl_popt->last_argv = argv;

    perl_popt->popt = poptGetContext(
        perl_popt->name,
        argc, (const char**) argv,
        perl_popt->options,
        POPT_CONTEXT_NO_EXEC
    );
}

// ----------------------------------------------------------------------

MODULE = CLI::Popt      PACKAGE = CLI::Popt

PROTOTYPES: DISABLE

BOOT:
{
    _CREATE_PERL_CONST(POPT_ARG_NONE);
    _CREATE_PERL_CONST(POPT_ARG_STRING);
    _CREATE_PERL_CONST(POPT_ARG_ARGV);
    _CREATE_PERL_CONST(POPT_ARG_SHORT);
    _CREATE_PERL_CONST(POPT_ARG_INT);
    _CREATE_PERL_CONST(POPT_ARG_LONG);
    _CREATE_PERL_CONST(POPT_ARG_LONGLONG);
    _CREATE_PERL_CONST(POPT_ARG_VAL);
    _CREATE_PERL_CONST(POPT_ARG_FLOAT);
    _CREATE_PERL_CONST(POPT_ARG_DOUBLE);

    _CREATE_PERL_CONST(POPT_ARGFLAG_ONEDASH);
    _CREATE_PERL_CONST(POPT_ARGFLAG_DOC_HIDDEN);
    _CREATE_PERL_CONST(POPT_ARGFLAG_OPTIONAL);
    _CREATE_PERL_CONST(POPT_ARGFLAG_SHOW_DEFAULT);
    _CREATE_PERL_CONST(POPT_ARGFLAG_RANDOM);
    _CREATE_PERL_CONST(POPT_ARGFLAG_TOGGLE);
    _CREATE_PERL_CONST(POPT_ARGFLAG_OR);
    _CREATE_PERL_CONST(POPT_ARGFLAG_AND);
    _CREATE_PERL_CONST(POPT_ARGFLAG_XOR);
    _CREATE_PERL_CONST(POPT_ARGFLAG_NOT);
}

SV*
_new_xs (const char* classname, SV* name_sv, SV* options_ar )
    CODE:
        const char *name_const = SvOK(name_sv) ? exs_SvPVbyte_nolen(name_sv) : NULL;
        char* name_copy = _copy_str_or_null(aTHX_ name_const);

        RETVAL = exs_new_structref(perl_popt_st, classname);
        perl_popt_st* perl_popt = exs_structref_ptr(RETVAL);

        struct poptOption* options = _create_popt_options(aTHX_ perl_popt, options_ar);

        char** faux_argv;
        Newxz(faux_argv, 1 + (name_copy ? 1 : 0), char*);
        if (name_copy) {
            *faux_argv = savepv(name_copy);
        }

        *perl_popt = (perl_popt_st) {
            .name = name_copy,
            .pid = getpid(),
            .options = options,
            .callback_userdata = {
#ifdef MULTIPLICITY
                .aTHX = aTHX,
#endif
            },
        };

        _refresh_popt_ctx(aTHX_ perl_popt, name_copy ? 1 : 0, faux_argv);

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        perl_popt_st* perl_popt = exs_structref_ptr(self_sv);

        if (PL_dirty && perl_popt->pid == getpid()) {
            warn("DESTROYing %" SVf " at global destruction; memory leak likely!\n", self_sv);
        }

        poptFreeContext(perl_popt->popt);

        if (perl_popt->name) {
            Safefree(perl_popt->name);
        }

        _free_popt_options(aTHX_ perl_popt->options);

void
parse (SV* self_sv, ...)
    PPCODE:
        perl_popt_st* perl_popt = exs_structref_ptr(self_sv);

        // trailing NUL - self_sv = 0
        const char* stack_argv[items];
        stack_argv[items - 1] = NULL;
        for (unsigned i=1; i<items; i++) {
            stack_argv[i - 1] = exs_SvPVbyte_nolen(ST(i));
        }

        char** new_argv = _dup_argv_deep(aTHX_ stack_argv, perl_popt->name);
        _refresh_popt_ctx(aTHX_ perl_popt, items - (perl_popt->name ? 0 : 1), new_argv);

        struct poptOption* options = perl_popt->options;

        HV* named_args = newHV();

        perl_popt->callback_userdata.result = named_args;

        int rc;
        while ((rc = poptGetNextOpt(perl_popt->popt)) >= 0) {

            // The compiler should optimize this away:
            if (CALLBACK_OPTS) {
                struct poptOption* curopt = options + (rc - 1);
                _store_opt_in_hv(aTHX_ curopt, named_args);
            }
        }

        if (rc != -1) {
            SvREFCNT_dec((SV*) named_args);

            const char *opt = poptBadOption(perl_popt->popt, 0);
            const char *errdesc = poptStrerror(rc);

            SV* args[] = {
                newSVpvs("BadOption"),
                newSViv(rc),
                newSVpv(errdesc, 0),
                newSVpv(opt, 0),
                NULL,
            };

            SV* err = exs_call_method_scalar(
                newSVpvs_flags(PERL_NS "::X", SVs_TEMP),
                "create",
                args
            );

            croak_sv(err);
        }

        const char** leftovers = poptGetArgs(perl_popt->popt);
        unsigned leftovers_count = 0;

        const char** curstr_p = leftovers;

        if (leftovers != NULL) {
            while (*curstr_p++) leftovers_count++;
        }

        EXTEND(SP, 1 + leftovers_count);
        mPUSHs( newRV_noinc((SV*) named_args) );

        for (unsigned l=0; l<leftovers_count; l++) {
            mPUSHp(leftovers[l], strlen(leftovers[l]));
        }

SV*
get_help (SV* self_sv)
    ALIAS:
        get_usage = 1
    CODE:
        perl_popt_st* perl_popt = exs_structref_ptr(self_sv);

        FILE* tf = tmpfile();
        if (!tf) {
            croak("tmpfile: %s", strerror(errno));
        }

        if (ix) {
            poptPrintUsage( perl_popt->popt, tf, 0 );
        }
        else {
            poptPrintHelp( perl_popt->popt, tf, 0 );
        }

        long size = ftell(tf);

        if (fseek(tf, SEEK_SET, 0)) {
            croak("fseek: %s", strerror(errno));
        }

        RETVAL = newSV(size);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, size);

        size_t got = fread(SvPVX(RETVAL), 1, size, tf);

        // silence unused-var warning
        (void) got;

        ASSUME(got == size);    // can this fail?

    OUTPUT:
        RETVAL
