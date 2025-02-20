/*@ s-bsdipa-io: I/O (compression) layer for s-bsdipa-lib.
 *@ Use as follows:
 *@ - Define s_BSDIPA_IO to one of s_BSDIPA_IO_(RAW|ZLIB),
 *@ - Define s_BSDIPA_IO_READ and/or s_BSDIPA_IO_WRITE, as desired,
 *@ - and include this header.
 *@ It then provides the according s_BSDIPA_IO_NAME preprocessor literal
 *@ and s_bsdipa_io_{read,write}_..(), which (are) fe(e)d data to/from hooks.
 *@ The functions have s_BSDIPA_IO_LINKAGE storage, or static if not defined.
 *@ There may be additional static helper functions.
 *@
 *@ Notes:
 *@ - it is up to the user to provide according linker flags, like -lz!
 *@ - this is not a step-by-step filter: a complete s_bsdipa_diff() result
 *@   is serialized, or serialized data is turned into a complete data set
 *@   that then can be fed into s_bsdipa_patch().
 *@   (A custom I/O (compression) layer may be less memory hungry.)
 *@ - s_BSDIPA_IO == s_BSDIPA_IO_ZLIB:
 *@   -- s_BSDIPA_IO_ZLIB_LEVEL may be defined as the "level" argument of
 *@      zlib's deflateInit() (default is 9).
 *@ - the header may be included multiple times, shall multiple BSDIPA_IO
 *@   variants be desired.  Still, only the _IO_LINKAGE as well as _IO_READ
 *@   and _IO_WRITE of the first inclusion are valid.
 *@
 *@ Remarks:
 *@ - code requires ISO STD C99 (for now).
 *
 * Copyright (c) 2024 - 2025 Steffen Nurpmeso <steffen@sdaoden.eu>.
 * SPDX-License-Identifier: ISC
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#ifndef s_BSDIPA_IO_H
# define s_BSDIPA_IO_H 0
#elif s_BSDIPA_IO_H == 0
# undef s_BSDIPA_IO_H
# define s_BSDIPA_IO_H 1
#else
# error Only two I/O layers exist.
#endif

#if s_BSDIPA_IO_H == 0
# include <s-bsdipa-lib.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if s_BSDIPA_IO_H == 0
# if !defined s_BSDIPA_IO_READ && !defined s_BSDIPA_IO_WRITE
#  error At least one of s_BSDIPA_IO_READ and s_BSDIPA_IO_WRITE is needed
# endif

/* Compression types (preprocessor so sources can adapt) */
# define s_BSDIPA_IO_RAW 0
# define s_BSDIPA_IO_ZLIB 1

# ifndef s_BSDIPA_IO_LINKAGE
#  define s_BSDIPA_IO_LINKAGE static
# endif
#endif

#if s_BSDIPA_IO_H == 0
# ifdef s_BSDIPA_IO_WRITE
/* I/O write hook.
 * If is_last is set the hook will not be called again; in this case len may be 0.
 * If try_oneshot is set and it matters to the I/O layer then it shall try to invoke hook only once;
 * if try_oneshot is given negative, and if the layer succeeds to comply, then is_last will also be
 * negative and the ownership of dat is transferred to the hook by definition -- and only then:
 * in fact the absolute value of is_last is the buffer size, of which len bytes are useful.
 * Note that *only* in this case the buffer size is at least one greater than len! */
typedef enum s_bsdipa_state (*s_bsdipa_io_write_ptf)(void *cookie, uint8_t const *dat, s_bsdipa_off_t len,
		s_bsdipa_off_t is_last);
/*s_BSDIPA_IO_LINKAGE enum s_bsdipa_state s_bsdipa_io_write_*(struct s_bsdipa_diff_ctx const *dcp,
		s_bsdipa_io_write_ptf hook, void *cookie, int try_oneshot);*/
# endif

# ifdef s_BSDIPA_IO_READ
/* I/O read hook.  It is assumed that pcp->pc_patch_dat and .pc_patch_len represent the entire (constant) patch data.
 * Output will be allocated via .pc_mem and stored in .pc_restored_dat and .pc_restored_len as a continuous chunk.
 * .pc_max_allowed_restored_len must also be set as it is already evaluated as documented.
 * On error that memory, if any, will be freed, and .pc_restored_dat will be NULL.
 * On success .pc_header is filled in; it is up to the user to update .pc_patch* with the .pc_restored* fields
 * and call s_bsdipa_patch() to apply the real patch.  (.pc_restored_dat will be overwritten by s_bsdipa_patch().) */
/*s_BSDIPA_IO_LINKAGE enum s_bsdipa_state s_bsdipa_io_read_*(struct s_bsdipa_patch_ctx *pcp);*/
# endif
#endif

#undef s_BSDIPA_IO_NAME
#if !defined s_BSDIPA_IO || s_BSDIPA_IO == s_BSDIPA_IO_RAW /* {{{ */
# undef s_BSDIPA_IO
# define s_BSDIPA_IO s_BSDIPA_IO_RAW
# define s_BSDIPA_IO_NAME "RAW"

# include <assert.h>

# ifdef s_BSDIPA_IO_WRITE
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_raw(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *cookie, int try_oneshot){
	struct s_bsdipa_ctrl_chunk *ccp;
	enum s_bsdipa_state rv;
	(void)try_oneshot;

	if((rv = (*hook)(cookie, dcp->dc_header, sizeof(dcp->dc_header), 0)) != s_BSDIPA_OK)
		goto jleave;

	s_BSDIPA_DIFF_CTX_FOREACH_CTRL(dcp, ccp){
		if((rv = (*hook)(cookie, ccp->cc_dat, ccp->cc_len, 0)) != s_BSDIPA_OK)
			goto jleave;
	}

	if(dcp->dc_diff_len > 0 && (rv = (*hook)(cookie, dcp->dc_diff_dat, dcp->dc_diff_len, 0)) != s_BSDIPA_OK)
		goto jleave;

	if(dcp->dc_extra_len > 0 && (rv = (*hook)(cookie, dcp->dc_extra_dat, dcp->dc_extra_len, 0)) != s_BSDIPA_OK)
		goto jleave;

	rv = (*hook)(cookie, NULL, 0, 1);
jleave:
	return rv;
}
# endif /* s_BSDIPA_IO_WRITE */

# ifdef s_BSDIPA_IO_READ
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_read_raw(struct s_bsdipa_patch_ctx *pcp){
	enum s_bsdipa_state rv;
	uint64_t pl;
	uint8_t const *pd;
	uint8_t *rd;

	rd = NULL;
	pd = pcp->pc_patch_dat;
	pl = pcp->pc_patch_len;

	if(pl < sizeof(struct s_bsdipa_header)){
		rv = s_BSDIPA_INVAL;
		goto jleave;
	}
	rv = s_bsdipa_patch_parse_header(&pcp->pc_header, pd);
	if(rv != s_BSDIPA_OK)
		goto jleave;

	/* Do not perform any action at all on size excess */
	if(pcp->pc_max_allowed_restored_len != 0 &&
			pcp->pc_max_allowed_restored_len < (uint64_t)pcp->pc_header.h_before_len){
		rv = s_BSDIPA_FBIG;
		goto jleave;
	}

	pl -= sizeof(pcp->pc_header);
	pd += sizeof(pcp->pc_header);

	/* Not truly right, the latter at least, but good enough for now */
	if(pl > s_BSDIPA_OFF_MAX - 1 || pl != (size_t)pl){
		rv = s_BSDIPA_FBIG;
		goto jleave;
	}

	if(pl != (uint64_t)(pcp->pc_header.h_ctrl_len + pcp->pc_header.h_diff_len + pcp->pc_header.h_extra_len)){
		rv = s_BSDIPA_INVAL;
		goto jleave;
	}

	rd = (uint8_t*)((pcp->pc_mem.mc_alloc != NULL) ? (*pcp->pc_mem.mc_alloc)((size_t)pl)
			: (*pcp->pc_mem.mc_custom_alloc)(pcp->pc_mem.mc_custom_cookie, (size_t)pl));
	if(rd == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jleave;
	}

	memcpy(rd, pd, (size_t)pl);

	rv = s_BSDIPA_OK;
jleave:
	if(rv == s_BSDIPA_OK){
		pcp->pc_restored_dat = rd;
		pcp->pc_restored_len = (s_bsdipa_off_t)pl;
	}else{
		if(rd != NULL)
			(pcp->pc_mem.mc_alloc != NULL) ? (*pcp->pc_mem.mc_free)(rd)
				: (*pcp->pc_mem.mc_custom_free)(pcp->pc_mem.mc_custom_cookie, rd);
		pcp->pc_restored_dat = NULL;
	}

	return rv;
}
# endif /* s_BSDIPA_IO_READ */
/* }}} */

#elif s_BSDIPA_IO == s_BSDIPA_IO_ZLIB /* _IO_RAW {{{ */
# define s_BSDIPA_IO_NAME "ZLIB"

# include <assert.h>

# include <zlib.h>

# ifndef s_BSDIPA_IO_ZLIB_LEVEL
#  define s_BSDIPA_IO_ZLIB_LEVEL 9
# endif

 /* For testing purposes */
# define s__BSDIPA_IO_ZLIB_LIMIT (INT32_MAX - 1)

static voidpf s__bsdipa_io_zlib_alloc(voidpf my_cookie, uInt no, uInt size);
static void s__bsdipa_io_zlib_free(voidpf my_cookie, voidpf dat);

# ifdef s_BSDIPA_IO_WRITE /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_zlib(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *cookie, int try_oneshot){
	z_stream zs;
	struct s_bsdipa_ctrl_chunk *ccp;
	char x;
	enum s_bsdipa_state rv;
	uint8_t *obuf;
	size_t olen;
	s_bsdipa_off_t diflen, extlen;
	z_streamp zsp;

	zsp = &zs;
	zs.zalloc = &s__bsdipa_io_zlib_alloc;
	zs.zfree = &s__bsdipa_io_zlib_free;
	zs.opaque = (void*)&dcp->dc_mem;

	switch(deflateInit(zsp, s_BSDIPA_IO_ZLIB_LEVEL)){
	case Z_OK: break;
	case Z_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jleave;
	default: rv = s_BSDIPA_INVAL; goto jleave;
	}

	diflen = dcp->dc_diff_len;
	extlen = dcp->dc_extra_len;

	/* All lengths fit in s_BSDIPA_OFF_MAX, which is signed: addition and cast ok */
	olen = (size_t)(sizeof(dcp->dc_header) + dcp->dc_ctrl_len + diflen + extlen);
	if(try_oneshot){
		uLong ulo;

		ulo = (uLong)olen; /* XXX check overflow? s_bsdipa_off_t>uLong case? */
		ulo = deflateBound(zsp, ulo);
		if(ulo >= s_BSDIPA_OFF_MAX){
			try_oneshot = 0;
			goto jolenmax;
		}
		/* Add "one additional byte" already here in case buffer takeover succeeds */
		++ulo;
		if(ulo != (uInt)ulo){
			try_oneshot = 0;
			goto jolenmax;
		}
		olen = (size_t)ulo;
	}else if(olen <= 1000 * 150)
		olen = 4096 * 4;
	else if(olen <= 1000 * 1000)
		olen = 4096 * 31;
	else
jolenmax:
		olen = 4096 * 244;

	obuf = (uint8_t*)s__bsdipa_io_zlib_alloc((void*)&dcp->dc_mem, 1, (uInt)olen);
	if(obuf == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}
	olen -= (try_oneshot != 0);

	zsp->next_out = obuf;
	zsp->avail_out = (uInt)olen;
	ccp = dcp->dc_ctrl;

	for(x = 0;;){
		int flusht;

		flusht = Z_NO_FLUSH;
		if(x == 0){
			zsp->next_in = (Bytef*)&dcp->dc_header;
			zsp->avail_in = sizeof(dcp->dc_header);
			x = 1;
		}else if(x == 1){
			if(ccp != NULL){
				zsp->next_in = ccp->cc_dat;
				zsp->avail_in = (uInt)ccp->cc_len;
				ccp = ccp->cc_next;
			}
			if(ccp == NULL)
				x = 2;
		}else if(x < 4){
			if(x == 2)
				zsp->next_in = dcp->dc_diff_dat;
			if(diflen > s__BSDIPA_IO_ZLIB_LIMIT){
				zsp->avail_in = s__BSDIPA_IO_ZLIB_LIMIT;
				diflen -= s__BSDIPA_IO_ZLIB_LIMIT;
				x = 3;
			}else{
				zsp->avail_in = (uInt)diflen;
				x = 4;
			}
		}else if(x < 6){
			if(x == 4)
				zsp->next_in = dcp->dc_extra_dat;
			if(extlen > s__BSDIPA_IO_ZLIB_LIMIT){
				zsp->avail_in = s__BSDIPA_IO_ZLIB_LIMIT;
				extlen -= s__BSDIPA_IO_ZLIB_LIMIT;
				x = 5;
			}else{
				zsp->avail_in = (uInt)extlen;
				x = 6;
			}
		}else{
			zsp->avail_in = 0; /* xxx redundant */
			flusht = Z_FINISH;
			x = 7;
		}

		if(zsp->avail_in > 0 || flusht == Z_FINISH) for(;;){
			s_bsdipa_off_t z;
			int y;

			y = deflate(zsp, flusht);

			switch(y){
			case Z_OK: break;
			case Z_STREAM_END: assert(flusht == Z_FINISH); break;
			case Z_BUF_ERROR: assert(zsp->avail_out == 0); break;
			default: /* FALLTHRU */
			case Z_STREAM_ERROR: rv = s_BSDIPA_INVAL; goto jdone;
			}

			z = olen - zsp->avail_out;
			if(y == Z_STREAM_END || (z > 0 && zsp->avail_out == 0)){
				int xarg;

				/* */
				if(y != Z_STREAM_END){
					if(try_oneshot < 0)
						try_oneshot = 1;
					xarg = 0;
				}else
					xarg = (try_oneshot < 0) ? -(s_bsdipa_off_t)++olen : 1;

				if((rv = (*hook)(cookie, obuf, z, xarg)) != s_BSDIPA_OK)
					goto jdone;

				if(xarg){
					/* Did we transfer buffer ownership? */
					if(xarg < 0)
						obuf = NULL;
					goto jdone;
				}
				zsp->next_out = obuf;
				zsp->avail_out = (uInt)olen;
			}

			if(flusht == Z_FINISH){
				assert(y != Z_STREAM_END);
				continue;
			}
			if(zsp->avail_in == 0)
				break;
			/* Different to documentation this happens! */
		}
		assert(x != 7);
	}

jdone:
	if(obuf != NULL)
		s__bsdipa_io_zlib_free((void*)&dcp->dc_mem, obuf);

	deflateEnd(zsp);
jleave:
	return rv;
}
# endif /* }}} s_BSDIPA_IO_WRITE */

# ifdef s_BSDIPA_IO_READ /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_read_zlib(struct s_bsdipa_patch_ctx *pcp){
	uint8_t hbuf[sizeof(struct s_bsdipa_header)];
	z_stream zs;
	s_bsdipa_off_t reslen;
	enum s_bsdipa_state rv;
	z_streamp zsp;
	uint64_t patlen;

	pcp->pc_restored_dat = NULL;
	patlen = pcp->pc_patch_len;

	/* make inflateEnd() callable */
	zsp = &zs;
	zs.next_in = (Bytef*)pcp->pc_patch_dat;
	zs.avail_in = (patlen > s__BSDIPA_IO_ZLIB_LIMIT) ? s__BSDIPA_IO_ZLIB_LIMIT : (int)patlen;
	patlen -= (unsigned int)zs.avail_in;
	zs.zalloc = &s__bsdipa_io_zlib_alloc;
	zs.zfree = &s__bsdipa_io_zlib_free;
	zs.opaque = (void*)&pcp->pc_mem;

	switch(inflateInit(zsp)){
	case Z_OK: break;
	case Z_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
	default: rv = s_BSDIPA_INVAL; goto jdone;
	}

	zsp->next_out = hbuf;
	zsp->avail_out = sizeof(hbuf);

	switch(inflate(zsp, Z_SYNC_FLUSH)){
	case Z_OK: break;
	case Z_STREAM_END: break;
	case Z_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
	default: rv = s_BSDIPA_INVAL; goto jdone;
	}
	if(zsp->avail_out != 0){
		rv = s_BSDIPA_INVAL;
		goto jdone;
	}

	rv = s_bsdipa_patch_parse_header(&pcp->pc_header, hbuf);
	if(rv != s_BSDIPA_OK)
		goto jdone;

	/* Do not perform any action at all on size excess */
	if(pcp->pc_max_allowed_restored_len != 0 &&
			pcp->pc_max_allowed_restored_len < (uint64_t)pcp->pc_header.h_before_len){
		rv = s_BSDIPA_FBIG;
		goto jdone;
	}

	/* Guaranteed to work! */
	reslen = pcp->pc_header.h_ctrl_len + pcp->pc_header.h_diff_len + pcp->pc_header.h_extra_len;

	pcp->pc_restored_len = reslen;
	pcp->pc_restored_dat = (uint8_t*)s__bsdipa_io_zlib_alloc(&pcp->pc_mem, 1, (uInt)reslen); /* (s_BSDIPA_32=y) */
	if(pcp->pc_restored_dat == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}

	zsp->next_out = pcp->pc_restored_dat;
	zsp->avail_out = (reslen > s__BSDIPA_IO_ZLIB_LIMIT) ? s__BSDIPA_IO_ZLIB_LIMIT : (int)reslen;
	reslen -= zsp->avail_out;

	for(;;){
		int x, y;

		x = (reslen == 0 && patlen == 0) ? Z_FINISH : Z_NO_FLUSH;
		y = inflate(zsp, x);

		switch(y){
		case Z_OK: break;
		case Z_BUF_ERROR:
			if(x == Z_FINISH){
				rv = s_BSDIPA_INVAL;
				goto jdone;
			}
			break;
		case Z_STREAM_END:
			if(x == Z_FINISH){
				rv = s_BSDIPA_OK;
				goto jdone;
			}
			break;
		case Z_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
		default: rv = s_BSDIPA_INVAL; goto jdone;
		}

		if(zsp->avail_out == 0){
			zsp->avail_out = (uInt)((reslen > s__BSDIPA_IO_ZLIB_LIMIT) ? s__BSDIPA_IO_ZLIB_LIMIT : reslen);
			reslen -= (s_bsdipa_off_t)zsp->avail_out;
		}
		if(zsp->avail_in == 0){
			zsp->avail_in = (uInt)((patlen > s__BSDIPA_IO_ZLIB_LIMIT) ? s__BSDIPA_IO_ZLIB_LIMIT : patlen);
			patlen -= (s_bsdipa_off_t)zsp->avail_in;
		}
	}

jdone:
	inflateEnd(zsp);

	if(rv != s_BSDIPA_OK && pcp->pc_restored_dat != NULL){
		s__bsdipa_io_zlib_free(&pcp->pc_mem, pcp->pc_restored_dat);
		pcp->pc_restored_dat = NULL;
	}

	return rv;
}
# endif /* }}} s_BSDIPA_IO_READ */

static voidpf
s__bsdipa_io_zlib_alloc(voidpf my_cookie, uInt no, uInt size){
	voidpf rv;
	size_t memsz;
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;
	memsz = (size_t)no * size;

	rv = (mcp->mc_alloc != NULL) ? (*mcp->mc_alloc)(memsz) : (*mcp->mc_custom_alloc)(mcp->mc_custom_cookie, memsz);

	return rv;
}

static void
s__bsdipa_io_zlib_free(voidpf my_cookie, voidpf dat){
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;

	(mcp->mc_alloc != NULL) ? (*mcp->mc_free)(dat) : (*mcp->mc_custom_free)(mcp->mc_custom_cookie, dat);
}

# undef s__BSDIPA_IO_ZLIB_LIMIT
# undef s_BSDIPA_IO_ZLIB_LEVEL
/* }}} */

#else /* _IO_ZLIB */
# error Unknown s_BSDIPA_IO value
#endif

#ifdef __cplusplus
}
#endif
/* s-itt-mode */
