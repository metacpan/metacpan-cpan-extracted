/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <doublefann.h>
#include "morefann.h"
#include "constants.h"

#define WANT_MORTAL 1

typedef fann_type *fta; /* fta: fann_type array */
typedef fta fta_input;
typedef fta fta_output;

static SV *
_obj2sv(pTHX_ void *ptr, SV * klass, char * ctype) {
    if (ptr) {
	SV *rv;
	SV *sv = newSVpvf("%s(0x%p)", ctype, ptr);
	SV *mgobj = sv_2mortal(newSViv(PTR2IV(ptr)));
	SvREADONLY_on(mgobj);
	sv_magic(sv, mgobj, '~', ctype, 0);
	/* SvREADONLY_on(sv); */
	rv = newRV_noinc(sv);
	if (SvOK(klass)) {
	    HV *stash;
	    if (SvROK(klass))
		stash = SvSTASH(klass);
	    else
		stash = gv_stashsv(klass, 1);
	    
	    sv_bless(rv, stash);
	}
	return rv;
    }
    return &PL_sv_undef;
}

static void *
_sv2obj(pTHX_ SV* self, char * ctype, int required) {
    SV *sv = SvRV(self);
    if (sv) {
        if (SvTYPE(sv) == SVt_PVMG) {
            MAGIC *mg = mg_find(sv, '~');
            if (mg) {
                if (strcmp(ctype, mg->mg_ptr) == 0 && mg->mg_obj) {
                    return INT2PTR(void *, SvIV(mg->mg_obj));
                }
            }
        }
    }
    if (required) {
        Perl_croak(aTHX_ "object of class %s expected", ctype);
    }
    return NULL;
}

static SV *
_fta2sv(pTHX_ fann_type *fta, unsigned int len) {
    unsigned int i;
    AV *av = newAV();
    av_extend(av, len - 1);
    for (i = 0; i < len; i++) {
        SV *sv = newSVnv(fta[i]);
        av_store(av, i, sv);
    }
    return newRV_noinc((SV*)av);
}

static AV*
_srv2av(pTHX_ SV* sv, unsigned int len, char * const name) {
    if (SvROK(sv)) {
        AV *av = (AV*)SvRV(sv);
        if (SvTYPE((SV*)av)==SVt_PVAV) {
            if (av_len(av)+1 == len) {
                return av;
            }
            else {
                Perl_croak(aTHX_ "wrong number of elements in %s array, %d found when %d were required",
                           name, (unsigned int)(av_len(av)+1), len);
            }
        }
    }
    Perl_croak(aTHX_ "wrong type for %s argument, array reference expected", name);
}

static fann_type*
_sv2fta(pTHX_ SV *sv, unsigned int len, int flags, char * const name) {
    unsigned int i;
    fann_type *fta;
    AV *av = _srv2av(aTHX_ sv, len, name);

    Newx(fta, len, fann_type);
    if (flags & WANT_MORTAL) SAVEFREEPV(fta);

    for (i = 0; i < len; i++) {
        SV ** svp = av_fetch(av, i, 0);
        fta[i] = SvNV(svp ? *svp : &PL_sv_undef);
    }
    return fta;
}

static void
_check_error(pTHX_ struct fann_error *self) {
    if (self) {
        if (fann_get_errno(self) != FANN_E_NO_ERROR) {
            ERRSV = newSVpv(self->errstr, strlen(self->errstr) - 2);
            fann_get_errstr(self);
            Perl_croak(aTHX_ Nullch);
        }
    }
    else {
        Perl_croak(aTHX_ "Constructor failed");
    }
}

static unsigned int
_sv2enum(pTHX_ SV *sv, unsigned int top, char * const name) {
	unsigned int value = SvUV(sv);
	if (value > top) {
		Perl_croak(aTHX_ "value %d is out of range for %s", value, name);
	}
	return value;
}

static SV *
_enum2sv(pTHX_ unsigned int value, char const * const * const names, unsigned int top, char const * const name) {
    SV *sv;
    if (value > top) {
        Perl_croak(aTHX_ "internal error: value %d out of range for %s", value, name);
    }
    sv = newSVpv(names[value], 0);
    SvUPGRADE(sv, SVt_PVIV);
    SvUV_set(sv, value);
    SvIOK_on(sv);
    SvIsUV_on(sv);
    return sv;
}

#define _sv2fann_train_enum(sv) _sv2enum(aTHX_ sv, FANN_TRAIN_QUICKPROP, "fann_train_enum")
#define _sv2fann_activationfunc_enum(sv) _sv2enum(aTHX_ sv, FANN_LINEAR_PIECE_SYMMETRIC, "fann_activationfunc_enum")
#define _sv2fann_errorfunc_enum(sv) _sv2enum(aTHX_ sv, FANN_ERRORFUNC_TANH, "fann_errorfunc_enum")
#define _sv2fann_stopfunc_enum(sv) _sv2enum(aTHX_ sv, FANN_STOPFUNC_BIT, "fann_stopfunc_enum")

#define _fann_train_enum2sv(sv) _enum2sv(aTHX_ sv, FANN_TRAIN_NAMES, FANN_TRAIN_QUICKPROP, "fann_train_enum")
#define _fann_activationfunc_enum2sv(sv) _enum2sv(aTHX_ sv, FANN_ACTIVATIONFUNC_NAMES, FANN_LINEAR_PIECE_SYMMETRIC, "fann_activationfunc_enum")
#define _fann_errorfunc_enum2sv(sv) _enum2sv(aTHX_ sv, FANN_ERRORFUNC_NAMES, FANN_ERRORFUNC_TANH, "fann_errorfunc_enum")
#define _fann_stopfunc_enum2sv(sv) _enum2sv(aTHX_ sv, FANN_STOPFUNC_NAMES, FANN_STOPFUNC_BIT, "fann_stopfunc_enum")



/* normalized names for train_data methods */

#define fann_train_data_create_from_file fann_read_train_from_file
#define fann_train_data_shuffle fann_shuffle_train_data
#define fann_train_data_scale_input fann_scale_input_train_data
#define fann_train_data_scale_output fann_scale_output_train_data
#define fann_train_data_scale fann_scale_train_data
#define fann_train_data_merge fann_merge_train_data
#define fann_train_data_subset fann_subset_train_data
#define fann_train_data_length fann_length_train_data
#define fann_train_data_num_input fann_num_input_train_data
#define fann_train_data_num_output fann_num_output_train_data
#define fann_train_data_save fann_save_train

MODULE = AI::FANN		PACKAGE = AI::FANN		PREFIX = fann_

PROTOTYPES: DISABLE

BOOT:
    fann_set_error_log(0, 0);

void
_constants()
  PREINIT:
    unsigned int i;
  PPCODE:
    for (i = 0; my_constant_names[i]; i++) {
        SV *sv = sv_2mortal(newSVpv(my_constant_names[i], 0));
        SvUPGRADE(sv, SVt_PVIV);
        SvUV_set(sv, my_constant_values[i]);
        SvIOK_on(sv);
        SvIsUV_on(sv);
		XPUSHs(sv);
	}
    XSRETURN(i);

struct fann *
fann_new_standard(klass, ...)
    SV *klass;
  PREINIT:
    unsigned int *layers;
    unsigned int i;
    unsigned int num_layers;
  CODE:
    num_layers = items - 1;
    Newx(layers, num_layers, unsigned int);
    SAVEFREEPV(layers);
    for (i = 0; i < num_layers; i++) {
		layers[i] = SvIV(ST(i+1));
    }
    RETVAL = fann_create_standard_array(num_layers, layers);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);

struct fann *
fann_new_sparse(klass, connection_rate, ...)
    SV *klass;
    double connection_rate;
  PREINIT:
    unsigned int *layers;
    unsigned int i;
    unsigned int num_layers;
  CODE:
    num_layers = items - 2;
    Newx(layers, num_layers, unsigned int);
    SAVEFREEPV(layers);
    for (i = 0; i < num_layers; i++) {
		layers[i] = SvIV(ST(i+2));
    }
    RETVAL = fann_create_sparse_array(connection_rate, num_layers, layers);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);

struct fann *
fann_new_shortcut(klass, ...)
    SV *klass;
  PREINIT:
    unsigned int *layers;
    unsigned int i;
    unsigned int num_layers;
  CODE:
    num_layers = items - 1;
    Newx(layers, num_layers, unsigned int);
    SAVEFREEPV(layers);
    for (i = 0; i < num_layers; i++) {
		layers[i] = SvIV(ST(i+1));
    }
    RETVAL = fann_create_shortcut_array(num_layers, layers);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);

struct fann *
fann_new_from_file(klass, filename)
    SV *klass;
    char *filename;
  CODE:
    RETVAL = fann_create_from_file(filename);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);

void
fann_DESTROY(self)
    struct fann * self;
  CODE:
    fann_destroy(self);
    sv_unmagic(SvRV(ST(0)), '~');

int
fann_save(self, filename)
    struct fann *self;
    char * filename;
  CODE:
    RETVAL = !fann_save(self, filename);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

fta_output
fann_run(self, input)
    struct fann *self;
    fta_input input;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_randomize_weights(self, min_weight, max_weight)
    struct fann *self;
    fann_type min_weight;
    fann_type max_weight;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_train(self, input, desired_output)
    struct fann *self;
    fta_input input;
    fta_output desired_output;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

fta_output
fann_test(self, input, desired_output)
    struct fann *self;
    fta_input input;
    fta_output desired_output;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_reset_MSE(self)
    struct fann * self;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_train_on_file(self, filename, max_epochs, epochs_between_reports, desired_error) 
    struct fann *self;
    const char *filename;
    unsigned int max_epochs;
    unsigned int epochs_between_reports;
    double desired_error;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_train_on_data(self, data, max_epochs, epochs_between_reports, desired_error)
    struct fann *self;
    struct fann_train_data *data;
    unsigned int max_epochs;
    unsigned int epochs_between_reports;
    double desired_error;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);
    _check_error(aTHX_ (struct fann_error *)data);

void
fann_cascadetrain_on_file(self, filename, max_neurons, neurons_between_reports, desired_error)
    struct fann *self;
	const char *filename;
    unsigned int max_neurons;
    unsigned int neurons_between_reports;
    double desired_error;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_cascadetrain_on_data(self, data, max_neurons, neurons_between_reports, desired_error)
    struct fann *self;
    struct fann_train_data *data;
    unsigned int max_neurons;
    unsigned int neurons_between_reports;
    double desired_error;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);
    _check_error(aTHX_ (struct fann_error *)data);

double
fann_train_epoch(self, data)
    struct fann *self;
    struct fann_train_data *data;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);
    _check_error(aTHX_ (struct fann_error *)data);

void
fann_print_connections(self)
    struct fann * self;

void
fann_print_parameters(self)
    struct fann * self;

void
fann_cascade_activation_functions(self, ...)
    struct fann *self;
  PREINIT:
    unsigned int count;
  PPCODE:
    if (items > 1) {
        unsigned int i;
        enum fann_activationfunc_enum * funcs;
        count = items - 1;
        Newx(funcs, items - 1, enum fann_activationfunc_enum);
        SAVEFREEPV(funcs);
        for (i = 0; i < count; i++) {
            funcs[i] = _sv2fann_activationfunc_enum(ST(i+1));
        }
        fann_set_cascade_activation_functions(self, funcs, count);
    }
    count = fann_get_cascade_activation_functions_count(self);
    if (GIMME_V == G_ARRAY) {
        unsigned int i;
        enum fann_activationfunc_enum * funcs = fann_get_cascade_activation_functions(self);
        EXTEND(SP, count);
        for (i = 0; i < count; i++) {
            ST(i) = sv_2mortal(_fann_activationfunc_enum2sv(funcs[i]));
        }
        XSRETURN(count);
    }
    else {
        ST(0) = sv_2mortal(newSVuv(count));
        XSRETURN(1);
    }

void
fann_cascade_activation_steepnesses(self, ...)
    struct fann *self;
  PREINIT:
    unsigned int count;
  PPCODE:
    if (items > 1) {
        unsigned int i;
        fann_type * steepnesses;
        count = items - 1;
        Newx(steepnesses, items - 1, fann_type);
        SAVEFREEPV(steepnesses);
        for (i = 0; i < count; i++) {
            steepnesses[i] = SvNV(ST(i+1));
        }
        fann_set_cascade_activation_steepnesses(self, steepnesses, count);
    }
    count = fann_get_cascade_activation_steepnesses_count(self);
    if (GIMME_V == G_ARRAY) {
        unsigned int i;
        fann_type * steepnesses = fann_get_cascade_activation_steepnesses(self);
        EXTEND(SP, count);
        for (i = 0; i < count; i++) {
            ST(i) = sv_2mortal(newSVuv(steepnesses[i]));
        }
        XSRETURN(count);
    }
    else {
        ST(0) = sv_2mortal(newSVuv(count));
        XSRETURN(1);
    }


MODULE = AI::FANN		PACKAGE = AI::FANN::TrainData		PREFIX = fann_train_data_

struct fann_train_data *
fann_train_data_new_from_file(klass, filename)
    SV *klass;
    const char *filename;
  CODE:
    RETVAL = fann_train_data_create_from_file(filename);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);

struct fann_train_data *
fann_train_data_new_empty(klass, num_data, num_input, num_output)
    SV *klass;
    unsigned int num_data;
    unsigned int num_input;
    unsigned int num_output;
  CODE:
    RETVAL = fann_train_data_create(num_data, num_input, num_output);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);

void
fann_train_data_data(self, index, ...)
    struct fann_train_data *self;
    unsigned int index;
  PREINIT:
    AV *input;
    AV *output;
    unsigned int i;
  PPCODE:
    if (index >= self->num_data)
        Perl_croak(aTHX_"index %d is out of range", index);
    switch (items) {
    case 4:
        input = _srv2av(aTHX_ ST(2), self->num_input, "input");
        for (i = 0; i < self->num_input; i++) {
            SV **svp = av_fetch(input, i, 0);
            self->input[index][i] = SvNV(svp ? *svp : &PL_sv_undef);
        }
        output = _srv2av(aTHX_ ST(3), self->num_output, "output");
        for (i = 0; i < self->num_output; i++) {
            SV **svp = av_fetch(output, i, 0);
            self->output[index][i] = SvNV(svp ? *svp : &PL_sv_undef);
        }
    case 2:
        if (GIMME_V == G_ARRAY) {
            input = newAV();
            output = newAV();
            av_extend(input, self->num_input - 1);
            av_extend(output, self->num_output - 1);
            for (i = 0; i < self->num_input; i++) {
                SV *sv = newSVnv(self->input[index][i]);
                av_store(input, i, sv);
            }
            for (i = 0; i < self->num_output; i++) {
                SV *sv = newSVnv(self->output[index][i]);
                av_store(output, i, sv);
            }
            ST(0) = sv_2mortal(newRV_inc((SV*)input));
            ST(1) = sv_2mortal(newRV_inc((SV*)output));
            XSRETURN(2);
        }
        else {
            ST(0) = &PL_sv_yes;
            XSRETURN(1);
        }
        break;
    default:
        Perl_croak(aTHX_ "Usage: AI::FANN::TrainData::data(self, index [, input, output])");
    }

struct fann_train_data *
fann_train_data_new(klass, input, output, ...)
    SV *klass;
    AV *input;
    AV *output;
  PREINIT:
    unsigned int num_data;
    unsigned int num_input;
    unsigned int num_output;
    unsigned int i;
  CODE:
    if (!(items & 1)) {
		Perl_croak(aTHX_ "wrong number of arguments in constructor");
    }
    num_data = items >> 1;
    num_input = av_len(input) + 1;
    if (!num_input)
        Perl_croak(aTHX_ "input array is empty");
    num_output = av_len(output) + 1;
    if (!num_output)
        Perl_croak(aTHX_ "output array is empty");
    RETVAL = fann_train_data_create(num_data, num_input, num_output);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)RETVAL);
    /* we do that at cleanup to ensure that the just created object is
     * freed if we croak */
    if (RETVAL) {
        for (i = 0; i < num_data; i++) {
            unsigned int j;
            input = _srv2av(aTHX_ ST(1 + i * 2), num_input, "input");
            for (j = 0; j < num_input; j++) {
                SV **svp = av_fetch(input, j, 0);
                RETVAL->input[i][j] = SvNV(svp ? *svp : &PL_sv_undef);
            }
            output = _srv2av(aTHX_ ST(2 + i * 2), num_output, "output");
            for (j = 0; j < num_output; j++) {
                SV **svp = av_fetch(output, j, 0);
                RETVAL->output[i][j] = SvNV(svp ? *svp : &PL_sv_undef);
            }
        }
    }

void
fann_train_data_DESTROY(self)
    struct fann_train_data * self;
  CODE:
    fann_destroy_train(self);
    sv_unmagic(SvRV(ST(0)), '~');

void
fann_train_data_shuffle(self)
    struct fann_train_data *self;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_train_data_scale_input(self, new_min, new_max)
    struct fann_train_data *self;
    fann_type new_min;
    fann_type new_max;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_train_data_scale_output(self, new_min, new_max)
    struct fann_train_data *self;
    fann_type new_min;
    fann_type new_max;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

void
fann_train_data_scale(self, new_min, new_max)
    struct fann_train_data *self;
    fann_type new_min;
    fann_type new_max;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

struct fann_train_data*
fann_train_data_subset(self, pos, length)
    struct fann_train_data *self;
    unsigned int pos;
    unsigned int length;
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);
    _check_error(aTHX_ (struct fann_error *)RETVAL);


INCLUDE: accessors.xsh

