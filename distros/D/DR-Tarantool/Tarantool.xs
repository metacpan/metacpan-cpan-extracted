/* vim: set ft=c */
/*

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "tp.h"
#include "msgpuck.h"

extern void _mpack_item(SV *res, SV *o);
extern const char *_munpack_item(const char *p,
    size_t len, SV **res, HV *ext, int utf);

#define PREALLOC_SCALAR_SIZE		0

inline static void hash_ssave(HV *h, const char *k, const char *v) {
	hv_store( h, k, strlen(k), newSVpvn( v, strlen(v) ), 0 );
}

inline static void hash_scsave(HV *h, const char *k, SV *sv) {
	hv_store( h, k, strlen(k), sv, 0);
}

inline static void hash_isave(HV *h, const char *k, uint32_t v) {
	hv_store( h, k, strlen(k), newSViv( v ), 0 );
}

static char * sv_resizer(struct tp *p, size_t req, size_t *size) {
	SV *sv = p->obj;
	STRLEN new_len = tp_size(p) + req;
	char *new_str = SvGROW(sv, new_len);
	if (!new_str)
		croak("Cannot allocate memory");
	// SvCUR_set(sv, new_len);
	*size = new_len;
	return new_str;
}


inline static void tp_av_tuple(struct tp *req, AV *tuple) {
	int i;
	tp_tuple(req);
	for (i = 0; i <= av_len(tuple); i++) {
		SV *field = *av_fetch(tuple, i, 0);
		char *fd;
		STRLEN fl;
		fd = SvPV(field, fl);
		tp_field(req, fd, fl);
	}
}


inline static int fetch_tuples( HV * ret, struct tp * rep ) {
	AV * tuples = newAV();
	hv_store( ret, "tuples", 6, newRV_noinc( ( SV * ) tuples ), 0 );

	int code;
	while ( (code = tp_next(rep)) ) {

		if (code < 0)
			return code;

		AV * t = newAV();
		av_push( tuples, newRV_noinc( ( SV * ) t ) );

		while((code = tp_nextfield(rep))) {
			if (code < 0)
				return code;
			SV * f = newSVpvn(
				tp_getfield(rep), tp_getfieldsize(rep)
			);
			av_push( t, f );
		}
	}
	return 0;
}


#define ALLOC_RET_SV(__name, __ptr, __len, __size)		\
	SV *__name = newSVpvn("", 0);                           \
	RETVAL = __name;					\
	if (__size) SvGROW(__name, __size);			\
	STRLEN __len;						\
	char *__ptr = SvPV(__name, __len);

MODULE = DR::Tarantool		PACKAGE = DR::Tarantool
PROTOTYPES: ENABLE



SV * _pkt_select( req_id, ns, idx, offset, limit, keys )
	unsigned req_id
	unsigned ns
	unsigned idx
	unsigned offset
	unsigned limit
	AV * keys


	CODE:
		ALLOC_RET_SV(ret, b, len, PREALLOC_SCALAR_SIZE);
		int k;

		struct tp req;
		tp_init(&req, b, PREALLOC_SCALAR_SIZE, sv_resizer, ret);
		tp_select(&req, ns, idx, offset, limit);

		for (k = 0; k <= av_len(keys); k++) {
			SV *t = *av_fetch(keys, k, 0);
			if (!SvROK(t) || (SvTYPE(SvRV(t)) != SVt_PVAV))
				croak("keys must be ARRAYREF of ARRAYREF");
			AV *tuple = (AV *)SvRV(t);
			tp_av_tuple(&req, (AV *)SvRV(t));
		}
		tp_reqid(&req, req_id);
		SvCUR_set(ret, tp_used(&req));
	OUTPUT:
		RETVAL


SV * _pkt_ping( req_id )
	unsigned req_id

	CODE:
		ALLOC_RET_SV(ret, b, len, 0);

		struct tp req;
		tp_init(&req, b, len, sv_resizer, ret);
		tp_ping(&req);
		tp_reqid(&req, req_id);
		SvCUR_set(ret, tp_used(&req));

	OUTPUT:
		RETVAL



SV * _pkt_insert( req_id, ns, flags, tuple )
	unsigned req_id
	unsigned ns
	unsigned flags
	AV * tuple

	CODE:
		ALLOC_RET_SV(ret, b, len, PREALLOC_SCALAR_SIZE);

		struct tp req;
		tp_init(&req, b, PREALLOC_SCALAR_SIZE, sv_resizer, ret);
		tp_insert(&req, ns, flags);
		tp_av_tuple(&req, tuple);
		tp_reqid(&req, req_id);

		SvCUR_set(ret, tp_used(&req));

	OUTPUT:
		RETVAL

SV * _pkt_delete( req_id, ns, flags, tuple )
	unsigned req_id
	unsigned ns
	unsigned flags
	AV *tuple

	CODE:
		ALLOC_RET_SV(ret, b, len, PREALLOC_SCALAR_SIZE);

		struct tp req;
		tp_init(&req, b, PREALLOC_SCALAR_SIZE, sv_resizer, ret);
		tp_delete(&req, ns, flags);
		tp_av_tuple(&req, tuple);
		tp_reqid(&req, req_id);

		SvCUR_set(ret, tp_used(&req));

	OUTPUT:
		RETVAL


SV * _pkt_call_lua( req_id, flags, proc, tuple )
	unsigned req_id
	unsigned flags
	SV *proc
	AV *tuple

	CODE:
		STRLEN name_len;
		char *name = SvPV(proc, name_len);

		ALLOC_RET_SV(ret, b, len, PREALLOC_SCALAR_SIZE);

		struct tp req;
		tp_init(&req, b, PREALLOC_SCALAR_SIZE, sv_resizer, ret);
		tp_call(&req, flags, name, name_len);
		tp_av_tuple(&req, tuple);
		tp_reqid(&req, req_id);

		SvCUR_set(ret, tp_used(&req));

	OUTPUT:
		RETVAL


SV * _pkt_update( req_id, ns, flags, tuple, operations )
	unsigned req_id
	unsigned ns
	unsigned flags
	AV *tuple
	AV *operations

	CODE:
		ALLOC_RET_SV(ret, b, len, PREALLOC_SCALAR_SIZE);
		struct tp req;
		int i;
		tp_init(&req, b, PREALLOC_SCALAR_SIZE, sv_resizer, ret);
		tp_update(&req, ns, flags);
		tp_reqid(&req, req_id);
		tp_av_tuple(&req, tuple);
		tp_updatebegin(&req);



		for (i = 0; i <= av_len( operations ); i++) {
			uint8_t opcode;

			SV *op = *av_fetch( operations, i, 0 );
			if (!SvROK(op) || SvTYPE( SvRV(op) ) != SVt_PVAV)
				croak("Wrong update operation format");
			AV *aop = (AV *)SvRV(op);

			int asize = av_len( aop ) + 1;
			if ( asize < 2 )
				croak("Too short operation argument list");

			unsigned fno = SvIV( *av_fetch( aop, 0, 0 ) );
			STRLEN size;
			char *opname = SvPV( *av_fetch( aop, 1, 0 ), size );


			/* delete */
			if ( strcmp(opname, "delete") == 0 ) {
				tp_op(&req, fno, TP_OPDELETE, "", 0);
				continue;
			}


			if (asize < 3)
				croak("Too short operation argument list");

			/* assign */
			if ( strcmp(opname, "set") == 0 ) {

				char *data =
					SvPV( *av_fetch( aop, 2, 0 ), size );
				tp_op(&req, fno, TP_OPSET, data, size);
				continue;
			}

			/* insert */
			if ( strcmp(opname, "insert") == 0 ) {
				char *data =
					 SvPV( *av_fetch( aop, 2, 0 ), size );
				tp_op(&req, fno, TP_OPINSERT, data, size);
				continue;
			}


			/* arithmetic operations */
			if ( strcmp(opname, "add") == 0 ) {
				opcode = TP_OPADD;
				goto ARITH;
			}
			if ( strcmp(opname, "and") == 0 ) {
				opcode = TP_OPAND;
				goto ARITH;
			}
			if ( strcmp(opname, "or") == 0 ) {
				opcode = TP_OPOR;
				goto ARITH;
			}
			if ( strcmp(opname, "xor") == 0 ) {
				opcode = TP_OPXOR;
				goto ARITH;
			}


			/* substr */
			if ( strcmp(opname, "substr") == 0 ) {
				if (asize < 4)
					croak("Too short argument "
						"list for substr");
				unsigned offset =
					SvIV( *av_fetch( aop, 2, 0 ) );
				unsigned length =
					SvIV( *av_fetch( aop, 3, 0 ) );
				char * data;
				if ( asize > 4 && SvOK( *av_fetch( aop, 4, 0 ) ) ) {
				    data =
					SvPV( *av_fetch( aop, 4, 0 ), size );
				} else {
				    data = "";
				    size = 0;
				}

				tp_opsplice(&req, fno, offset, length,
					 data, size);

				continue;
			}

			/* unknown command */
			croak("unknown update operation: `%s'", opname);

			ARITH: {
				char *data =
					 SvPV( *av_fetch( aop, 2, 0 ), size );
				if (sizeof(unsigned long long) < size)
				    size = sizeof(unsigned long long);
				tp_op(&req, fno, opcode, data, size);
				continue;
			}

		}

		SvCUR_set(ret, tp_used(&req));
	OUTPUT:
		RETVAL



HV * _pkt_parse_response( response )
	SV *response

	INIT:
		RETVAL = newHV();
		sv_2mortal((SV *)RETVAL);

	CODE:
		/* asm("break"); */
		if ( !SvOK(response) )
			croak( "response is undefined" );
		STRLEN size;
		char *data = SvPV( response, size );

		struct tp rep;
		tp_init(&rep, data, size, NULL, 0);
		// tp_use(&rep, size);

		ssize_t code = tp_reply(&rep);

		if (code == -1) {
			hash_ssave(RETVAL, "status", "buffer");
			hash_ssave(RETVAL, "errstr", "Input data too short");
		} else if (code >= 0) {
			uint32_t type = tp_replyop(&rep);
			hash_isave(RETVAL, "code", tp_replycode(&rep) );
			hash_isave(RETVAL, "req_id", tp_getreqid(&rep) );
			hash_isave(RETVAL, "type", type );
			hash_isave(RETVAL, "count", tp_replycount(&rep) );
			if (code == 0) {
			    if (type != TP_PING)
				code = fetch_tuples(RETVAL, &rep);
				if (code != 0) {
					hash_ssave(RETVAL, "status", "buffer");
					hash_ssave(RETVAL, "errstr",
						"Broken response");
				} else {
					hash_ssave(RETVAL, "status", "ok");
				}
			} else {
				hash_ssave(RETVAL, "status", "error");
				size_t el = tp_replyerrorlen(&rep);
				SV *err;
				if (el) {
					char *s = tp_replyerror(&rep);
					if (s[el - 1] == 0)
						el--;
					err = newSVpvn(s, el);
				} else {
					err = newSVpvn("", 0);
				}

				hash_scsave(RETVAL, "errstr", err);
			}
		}
	OUTPUT:
		RETVAL



unsigned TNT_PING()
	CODE:
		RETVAL = TP_PING;
	OUTPUT:
		RETVAL


unsigned TNT_CALL()
	CODE:
		RETVAL = TP_CALL;
	OUTPUT:
		RETVAL

unsigned TNT_INSERT()
	CODE:
		RETVAL = TP_INSERT;
	OUTPUT:
		RETVAL

unsigned TNT_UPDATE()
	CODE:
		RETVAL = TP_UPDATE;
	OUTPUT:
		RETVAL

unsigned TNT_DELETE()
	CODE:
		RETVAL = TP_DELETE;
	OUTPUT:
		RETVAL

unsigned TNT_SELECT()
	CODE:
		RETVAL = TP_SELECT;
	OUTPUT:
		RETVAL


unsigned TNT_FLAG_RETURN()
	CODE:
		RETVAL = TP_BOX_RETURN_TUPLE;
	OUTPUT:
		RETVAL

unsigned TNT_FLAG_ADD()
	CODE:
		RETVAL = TP_BOX_ADD;
	OUTPUT:
		RETVAL

unsigned TNT_FLAG_REPLACE()
	CODE:
		RETVAL = TP_BOX_REPLACE;
	OUTPUT:
		RETVAL



SV * _msgpack(o)
	SV *o
	CODE:
		SV *res = newSVpvn("", 0);
		RETVAL = res;

		_mpack_item(res, o);
	OUTPUT:
		RETVAL

SV * _msgunpack(str, utf)
	SV *str;
	SV *utf;
	PROTOTYPE: $$
	CODE:
		SV *sv = 0;
		size_t len;
		const char *s = SvPV(str, len);
		if (items > 1)
			_munpack_item(s, len, &sv, (HV *)ST(1), SvIV(utf));
		else
			_munpack_item(s, len, &sv, NULL, SvIV(utf));
		RETVAL = sv;

	OUTPUT:
		RETVAL

size_t _msgcheck(str)
        SV *str
        PROTOTYPE: $
        CODE:
            int res;
            size_t len;
            if (SvOK(str)) {
                const char *p = SvPV(str, len);
                if (len > 0) {
                    const char *pe = p + len;
                    const char *begin = p;
                    if (mp_check(&p, pe) == 0) {
                        RETVAL = p - begin;
                    } else {
                        RETVAL = 0;
                    }
                } else {
                    RETVAL = 0;
                }
            } else {
                RETVAL = 0;
            }
        OUTPUT:
            RETVAL



