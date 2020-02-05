#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "const-c.inc"

#include <ucl.h>

bool implicit_unicode;
int ucl_string_flags;

static ucl_object_t *
_iterate_perl (pTHX_ SV* obj) {
    if ( SvTYPE(obj) == SVt_NULL ) {
        return ucl_object_new();
    }
    else if (
        sv_isobject(obj) && (
               sv_isa(obj, "JSON::PP::Boolean")
            || sv_isa(obj, "Types::Serialiser::BooleanBase")
            || sv_isa(obj, "JSON::XS::Boolean")
            || sv_isa(obj, "Data::MessagePack::Boolean")
            || sv_isa(obj, "boolean")
            || sv_isa(obj, "Mojo::JSON::_Bool")
        )
    ) {
        return ucl_object_frombool( SvTRUE(obj) );
    }
    else if ( SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVAV ) {
        ucl_object_t *top, *elm;
        top = ucl_object_typed_new(UCL_ARRAY);
        size_t nums_len = av_len((AV*)SvRV(obj)) + 1;
        for (int i = 0; i < nums_len; i++) {
            SV** num_sv_ptr = av_fetch((AV*)SvRV(obj), i, FALSE);
            SV* num_sv = num_sv_ptr ? *num_sv_ptr : &PL_sv_undef;
            elm = _iterate_perl(aTHX_ num_sv);
            ucl_array_append(top, elm);
        }
        return top;
    }
    else if ( SvROK(obj) && SvTYPE(SvRV(obj)) == SVt_PVHV ) {
        ucl_object_t *top, *elm;
        char *keystr = NULL;
        top = ucl_object_typed_new(UCL_OBJECT);
        HV *hash= (HV*)SvRV(obj);
        HE *iter;
        hv_iterinit(hash);
        int *len;
        for (iter=hv_iternext(hash); iter; iter=hv_iternext(hash)) {
            char* key;
            key = HeKEY(iter);
            elm = _iterate_perl(aTHX_ HeVAL(iter));
            ucl_object_insert_key(top, elm, key, 0, true);
        }
        return top;
    }
    else if ( SvIOK(obj) ) {
        return ucl_object_fromint(SvIV(obj));
    }
    else if ( SvNOK(obj) ) {
        return ucl_object_fromdouble(SvNV(obj));
    }
    else if ( SvPOK(obj) || SvPOKp(obj)) {
        // https://github.com/vstakhov/libucl/blob/master/doc/api.md#ucl_object_fromstring_common
        return ucl_object_fromstring_common( SvPV_nolen(obj), strlen(SvPV_nolen(obj)), ucl_string_flags );
    }
    else if ( !SvOK(obj) ) { // undef
        return ucl_object_new();
    }

    croak("unknown type %d", SvTYPE(obj) );
}

SV *
_ucl_type (pTHX_ ucl_object_t const *obj)
{
    switch (obj->type) {
        case UCL_INT:
            return newSViv((long long)ucl_object_toint (obj));
        case UCL_FLOAT:
            return newSVnv(ucl_object_todouble (obj));
        case UCL_STRING: {
            SV *sv = newSVpv(ucl_object_tostring (obj), 0);
            if (implicit_unicode) {
                SvUTF8_on(sv);
            }
            return sv;
        }
        case UCL_BOOLEAN: {
            SV* rv = newSV_type(SVt_IV);
            sv_setref_iv(rv, "JSON::PP::Boolean", ucl_object_toboolean(obj) ? 1 : 0);
            return rv;
        }
        case UCL_TIME:
            return newSVnv(ucl_object_todouble (obj));
        case UCL_NULL:
            return &PL_sv_undef;
    }
    return NULL;
}

SV *
_iterate_ucl (pTHX_ ucl_object_t const *obj) {
    const ucl_object_t *tmp;
    ucl_object_iter_t it = NULL;

    tmp = obj;

    while ((obj = ucl_object_iterate (tmp, &it, false))) {
        SV *val;

        val = _ucl_type(aTHX_ obj);
        if (!val) {
            SV *key = NULL;

            if (obj->key != NULL) {
                key = newSVpv(ucl_object_key(obj),0);
            }

            if (obj->type == UCL_OBJECT) {
                const ucl_object_t *cur;
                ucl_object_iter_t it_obj = NULL;

                val = sv_2mortal((SV*)newHV());

                while ((cur = ucl_object_iterate (obj, &it_obj, true))) {
                    SV *key = newSVpv(ucl_object_key(cur),0);
                    if (implicit_unicode)
                        SvUTF8_on(key);
                    hv_store_ent((HV*)val, sv_2mortal(key), _iterate_ucl(aTHX_ cur), 0);
                }
                val = newRV(val);
            } else if (obj->type == UCL_ARRAY) {
                const ucl_object_t *cur;
                ucl_object_iter_t it_obj = NULL;

                val = sv_2mortal((SV*)newAV());

                while ((cur = ucl_object_iterate (obj, &it_obj, true))) {
                    av_push((AV*)val, newRV((SV*)_iterate_ucl(aTHX_ cur)));
                }
                val = newRV(val);
            } else if (obj->type == UCL_USERDATA) {
                val = newSVpv(obj->value.ud, 0);
            }
        }
        return val;
    }

    croak("unhandled type");
}

SV *
_load_ucl(pTHX_ struct ucl_parser *parser) {
    SV *ret;
    const char *err = ucl_parser_get_error(parser);

    if (err) {
        croak(err);
    }
    else {
        ucl_object_t *uclobj = ucl_parser_get_object(parser);
        ret = _iterate_ucl(aTHX_ uclobj);
    }

    return ret;
}


MODULE = Config::UCL       PACKAGE = Config::UCL

INCLUDE: const-xs.inc
PROTOTYPES: ENABLED

SV *
_ucl_dump(SV *sv, bool _implicit_unicode, ucl_emitter_t emitter)
    CODE:
        implicit_unicode = _implicit_unicode;
	ucl_object_t *root = NULL;
	root = _iterate_perl(aTHX_ sv);
	if (root) {
            RETVAL = newSVpv((char *)ucl_object_emit(root, emitter), 0);
            if (implicit_unicode)
                SvUTF8_on(RETVAL);
            ucl_object_unref(root);
	}
    OUTPUT:
        RETVAL

bool
ucl_validate(SV *schema_sv, SV *data_sv)
    CODE:
        ucl_object_t *data, *schema;
        bool r;
        struct ucl_schema_error err;

        SV *schema_error = get_sv("Config::UCL::ucl_schema_error", 0);
        sv_setpv(schema_error, "\0");

        schema = _iterate_perl(aTHX_ schema_sv);
        if (!schema) {
            croak("aaa");
            RETVAL = NULL;
            return;
        }

        data = _iterate_perl(aTHX_ data_sv);
        if (!data) {
            croak("aaa");
            RETVAL = NULL;
            return;
        }

        // validation
        r = ucl_object_validate(schema, data, &err);
        ucl_object_unref(schema);
        ucl_object_unref(data);

        if (!r) {
            //PyErr_SetString (SchemaError, err.msg);
            sv_setpv(schema_error, err.msg);
            RETVAL = false;
        }
        else {
            RETVAL = true;
        }
    OUTPUT:
        RETVAL

MODULE = Config::UCL       PACKAGE = Config::UCL::Parser
 
struct ucl_parser *
new(char *klass, int flags)
    CODE:
	struct ucl_parser *parser = ucl_parser_new(flags);
        RETVAL = parser;
    OUTPUT:
        RETVAL

void
ucl_parser_register_variable (struct ucl_parser *parser, const char *var, const char *value);

bool
ucl_parser_set_filevars(struct ucl_parser *parser, const char *filename, bool need_expand)

bool
ucl_parser_add_string(struct ucl_parser *parser, const char *data, size_t len);

bool
ucl_parser_add_chunk_full (struct ucl_parser *parser, const unsigned char *data, size_t len, unsigned priority, enum ucl_duplicate_strategy strat, enum ucl_parse_type parse_type);

bool
ucl_parser_add_file(struct ucl_parser *parser, const char *filename);

bool
ucl_parser_add_file_full (struct ucl_parser *parser, const char *filename, unsigned priority, enum ucl_duplicate_strategy strat, enum ucl_parse_type parse_type);

void
DESTROY(struct ucl_parser *parser)
    CODE:
        ucl_parser_free(parser);

SV *
ucl_load(struct ucl_parser *parser, bool _implicit_unicode, int _ucl_string_flags)
    CODE:
        implicit_unicode = _implicit_unicode;
        ucl_string_flags = _ucl_string_flags;
        RETVAL = _load_ucl(aTHX_ parser);
    OUTPUT:
        RETVAL
