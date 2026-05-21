/*@ s-bsdipa-io: I/O (compression) layer for s-bsdipa-lib.
 *@ Use as follows:
 *@ - Define s_BSDIPA_IO to one of s_BSDIPA_IO_(BZ2|RAW|XZ|ZLIB|ZSTD);
 *@ - Define s_BSDIPA_IO_READ and/or s_BSDIPA_IO_WRITE, as desired;
 *@ - And include this header.
 *@ It then provides the according s_BSDIPA_IO_NAME preprocessor literal
 *@ and s_bsdipa_io_{read,write}_..(), which (are) fe(e)d data to/from hooks.
 *@ Dependent upon the type a specialized io_cookie type may be available.
 *@
 *@ Notes:
 *@ - The functions have s_BSDIPA_IO_LINKAGE storage, or static if not defined.
 *@   There may be additional static helper functions.
 *@ - It is up to the user to provide according linker flags, like -lz!
 *@ - This is not a step-by-step filter: a complete s_bsdipa_diff() result
 *@   is serialized, or serialized data is turned into a complete data set
 *@   that then can be fed into s_bsdipa_patch().
 *@   (A custom I/O (compression) layer may be less memory hungry.)
 *@ - Layers default to the strongest possible compression, unless that is "excessive".
 *@   (Note: s-bsdipa.c uses defaults, and needs (manual) adjustments on change.)
 *@
 *@ - s_BSDIPA_IO == s_BSDIPA_IO_BZ2 (-lbz2 (bzip2)):
 *@   -- s_BSDIPA_IO_BZ2_BLOCKSIZE may be defined (default 9).
 *@   -- s_BSDIPA_IO_BZ2_VERBOSITY may be defined (default 0).
 *@   -- s_BSDIPA_IO_BZ2_SMALL may be defined to reduce memory usage (default 0).
 *@   -- Note: INT_MAX is maximum allocation size! (XXX could "split" via n/size)
 *@ - s_BSDIPA_IO == s_BSDIPA_IO_RAW:
 *@   -- no checksum.
 *@ - s_BSDIPA_IO == s_BSDIPA_IO_XZ (-llzma):
 *@   -- s_BSDIPA_IO_XZ_PRESET may be defined as the "preset" argument of
 *@      lzma_easy_encoder() (default 8).
 *@   -- s_BSDIPA_IO_XZ_CHECK may be defined as the "check" argument of
 *@      lzma_easy_encoder() (default is LZMA_CHECK_CRC32 for s_BSDIPA_32, and
 *@      LZMA_CHECK_CRC64 otherwise).
 *@ - s_BSDIPA_IO == s_BSDIPA_IO_ZLIB (-lz):
 *@   -- s_BSDIPA_IO_ZLIB_LEVEL may be defined as the "level" argument of
 *@      zlib's deflateInit() (default 9).
 *@   -- Checksum Adler-32 (what inflate() gives you).
 *@   -- Note: UINT_MAX is maximum allocation size! (XXX could "split" via n/size)
 *@ - s_BSDIPA_IO == s_BSDIPA_IO_ZSTD (-lzstd):
 *@   -- s_BSDIPA_IO_ZSTD_LEVEL is *not* zstd.h:ZSTD_c_compressionLevel, but instead in our own
 *@      scale 1..9, but then mapped accordingly.
 *@   -- s_BSDIPA_IO_ZSTD_CHECKSUM may be defined as 0 or 1 to dis-/enable ZSTD_c_checksumFlag
 *@      (default 1, meaning XXH64).
 *@ - The header may be included multiple times, shall multiple BSDIPA_IO
 *@   variants be desired.  Still, only the _IO_LINKAGE as well as _IO_READ
 *@   and _IO_WRITE of the first inclusion are valid.
 *@ - TODO For most compression I/O layers, try_oneshot could be used to drive the I/O layer
 *@   TODO in a special oneshot mode; this optimization is not yet implemented.
 *@
 *@ Remarks:
 *@ - Code requires ISO STD C99.
 *
 * Copyright (c) 2024 - 2026 Steffen Nurpmeso <steffen@sdaoden.eu>.
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
#elif s_BSDIPA_IO_H == 1
# undef s_BSDIPA_IO_H
# define s_BSDIPA_IO_H 2
#elif s_BSDIPA_IO_H == 2
# undef s_BSDIPA_IO_H
# define s_BSDIPA_IO_H 3
#elif s_BSDIPA_IO_H == 3
# undef s_BSDIPA_IO_H
# define s_BSDIPA_IO_H 4
#else
# error Only five I/O layers exist.
#endif

#if s_BSDIPA_IO_H == 0
# include <s-bsdipa-lib.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if s_BSDIPA_IO_H == 0 /* {{{ */
# if !defined s_BSDIPA_IO_READ && !defined s_BSDIPA_IO_WRITE
#  error At least one of s_BSDIPA_IO_READ and s_BSDIPA_IO_WRITE is needed
# endif

/* Compression types and names (preprocessor so sources can adapt -- *alphabetical* order!) */
# define s_BSDIPA_IO_BZ2 0
#  define s_BSDIPA_IO_NAME_BZ2 "BZ2"
# define s_BSDIPA_IO_RAW 1
#  define s_BSDIPA_IO_NAME_RAW "RAW"
# define s_BSDIPA_IO_XZ 2
#  define s_BSDIPA_IO_NAME_XZ "XZ"
# define s_BSDIPA_IO_ZLIB 3
#  define s_BSDIPA_IO_NAME_ZLIB "ZLIB"
# define s_BSDIPA_IO_ZSTD 4
#  define s_BSDIPA_IO_NAME_ZSTD "ZSTD"
# define s_BSDIPA_IO_MAX 4

# ifndef s_BSDIPA_IO_LINKAGE
#  define s_BSDIPA_IO_LINKAGE static
# endif

/* An optional cookie that may be used by the I/O layer for caching purposes if set.
 *
 * The actual I/O layer may have a specific "subclass", plus an optional s_bsdipa_io_cookie_gut_*() function,
 * in which the subclass must be used, and the gut function be called.
 * It must be zeroed before first use, then .ioc_type be set to the s_BSDIPA_IO_.. type;
 * setting .ioc_level is optional: it *must* be within 1-9, which the layers maps to mean minimum..maximum.
 *
 * A cookie may then be passed to read and write functions, from within one thread at a time, non-interchangeably.
 * Once no more use is to be expected, the according _gut_*() function must be called.
 *
 * Note: during all the life time the memory allocator must not change!
 * If the cookie is used for s_bsdipa_diff() as well as s_bsdipa_patch(), then the memory allocator and its cookie
 * (if used) must be the same throughout the lifetime of the I/O cookie!
 *
 * Remarks: "super type" alignment may mismatch actual "subclass", but assumed "ok through instantiation". */
struct s_bsdipa_io_cookie{
	uint8_t ioc_is_init;
	uint8_t ioc_type; /* s_BSDIPA_IO_..: actual type */
	uint8_t ioc_level; /* Always 0, or 1-9, then I/O layer puts meaning onto *that* */
	uint8_t ioc__dummy[5];
};

/* The function to free resources of a io_cookie, if any were ever allocated. */
typedef void (*s_bsdipa_io_gut_fun)(struct s_bsdipa_io_cookie *io_cookie);

# ifdef s_BSDIPA_IO_WRITE
/* I/O write hook.
 * If is_last is set the hook will not be called again; in this case len may be 0.
 * If try_oneshot was given to an I/O layer to which it matters it will try to invoke the hook only once;
 * if a negative try_oneshot was given, and if the layer succeeds to comply, then is_last will also be
 * negative and the ownership of dat is transferred to the hook by definition -- and only then:
 * in fact the absolute value of is_last is the buffer size, of which len bytes are useful;
 * Note that *only* in this case the buffer size is at least one greater than len! */
typedef enum s_bsdipa_state (*s_bsdipa_io_write_ptf)(void *hook_cookie, uint8_t const *dat, s_bsdipa_off_t len,
		s_bsdipa_off_t is_last);
typedef enum s_bsdipa_state (*s_bsdipa_io_write_fun)(struct s_bsdipa_diff_ctx const *dcp,
		s_bsdipa_io_write_ptf hook, void *hook_cookie, int try_oneshot,
		struct s_bsdipa_io_cookie *io_cookie_or_null);
# endif

# ifdef s_BSDIPA_IO_READ
/* I/O read hook.
 * It is assumed that pcp->pc_patch_dat and .pc_patch_len represent the entire (constant) patch data.
 * Output is allocated via .pc_mem, and stored in .pc_restored_dat and .pc_restored_len as a continuous chunk.
 * .pc_max_allowed_restored_len must also be set as it is already evaluated as documented.
 * On error that memory, if any, will be freed, and .pc_restored_dat will be NULL.
 * On success .pc_header is filled in; it is up to the user to update .pc_patch* with the .pc_restored* fields
 * and call s_bsdipa_patch() to apply the real patch.
 * (.pc_restored_dat will be overwritten by s_bsdipa_patch().) */
typedef enum s_bsdipa_state (*s_bsdipa_io_read_fun)(struct s_bsdipa_patch_ctx *pcp,
		struct s_bsdipa_io_cookie *io_cookie_or_null);
# endif
#endif /* s_BSDIPA_IO_H==0 */
/* }}} */

/* (Code blocks in implementation order) */
#undef s_BSDIPA_IO_NAME
#if !defined s_BSDIPA_IO || s_BSDIPA_IO == s_BSDIPA_IO_RAW /* {{{ */
# undef s_BSDIPA_IO
# ifdef s__BSDIPA_IO_RAW
#  error s_BSDIPA_IO==s_BSDIPA_IO_RAW already defined
# endif
# define s__BSDIPA_IO_RAW
# define s_BSDIPA_IO s_BSDIPA_IO_RAW
# define s_BSDIPA_IO_NAME s_BSDIPA_IO_NAME_RAW

# include <assert.h>

# ifdef s_BSDIPA_IO_WRITE
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_raw(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *hook_cookie,
		int try_oneshot, struct s_bsdipa_io_cookie *io_cookie_or_null){
	struct s_bsdipa_ctrl_chunk *ccp;
	enum s_bsdipa_state rv;
	(void)try_oneshot;
	(void)io_cookie_or_null;

	if((rv = (*hook)(hook_cookie, dcp->dc_header, sizeof(dcp->dc_header), 0)) != s_BSDIPA_OK)
		goto jleave;

	s_BSDIPA_DIFF_CTX_FOREACH_CTRL(dcp, ccp){
		if((rv = (*hook)(hook_cookie, ccp->cc_dat, ccp->cc_len, 0)) != s_BSDIPA_OK)
			goto jleave;
	}

	if(dcp->dc_diff_len > 0 &&
			(rv = (*hook)(hook_cookie, dcp->dc_diff_dat, dcp->dc_diff_len, 0)) != s_BSDIPA_OK)
		goto jleave;

	if(dcp->dc_extra_len > 0 &&
			(rv = (*hook)(hook_cookie, dcp->dc_extra_dat, dcp->dc_extra_len, 0)) != s_BSDIPA_OK)
		goto jleave;

	rv = (*hook)(hook_cookie, NULL, 0, 1);
jleave:
	return rv;
}
# endif /* s_BSDIPA_IO_WRITE */

# ifdef s_BSDIPA_IO_READ
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_read_raw(struct s_bsdipa_patch_ctx *pcp, struct s_bsdipa_io_cookie *io_cookie_or_null){
	enum s_bsdipa_state rv;
	uint64_t pl;
	uint8_t const *pd;
	uint8_t *rd;
	(void)io_cookie_or_null;

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
#  if 0
		if(rd != NULL)
			(pcp->pc_mem.mc_alloc != NULL) ? (*pcp->pc_mem.mc_free)(rd)
				: (*pcp->pc_mem.mc_custom_free)(pcp->pc_mem.mc_custom_cookie, rd);
#  endif
		pcp->pc_restored_dat = NULL;
	}

	return rv;
}
# endif /* s_BSDIPA_IO_READ */
/* }}} */

#elif s_BSDIPA_IO == s_BSDIPA_IO_ZLIB /* _IO_RAW {{{ */
/*# undef s_BSDIPA_IO*/
# ifdef s__BSDIPA_IO_ZLIB
#  error s_BSDIPA_IO==s_BSDIPA_IO_ZLIB already defined
# endif
# define s__BSDIPA_IO_ZLIB
# define s_BSDIPA_IO_NAME s_BSDIPA_IO_NAME_ZLIB

# include <assert.h>

# include <zlib.h>

# ifndef s_BSDIPA_IO_ZLIB_LEVEL
#  define s_BSDIPA_IO_ZLIB_LEVEL 9
# endif

 /* For testing purposes */
# define s__BSDIPA_IO_ZLIB_LIMIT (INT32_MAX - 1)

static voidpf s__bsdipa_io_zlib_alloc(voidpf my_cookie, uInt no, uInt size);
static void s__bsdipa_io_zlib_free(voidpf my_cookie, voidpf dat);

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

# ifdef s_BSDIPA_IO_WRITE /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_zlib(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *hook_cookie,
		int try_oneshot, struct s_bsdipa_io_cookie *io_cookie_or_null){
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

	/* C99 */{
		int level;

		level = s_BSDIPA_IO_ZLIB_LEVEL;
		if(io_cookie_or_null != NULL && io_cookie_or_null->ioc_level != 0)
			level = (int)io_cookie_or_null->ioc_level;

		switch(deflateInit(zsp, level)){
		case Z_OK: break;
		case Z_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jleave;
		default: rv = s_BSDIPA_INVAL; goto jleave;
		}
	}

	diflen = dcp->dc_diff_len;
	extlen = dcp->dc_extra_len;

	/* All lengths fit in s_BSDIPA_OFF_MAX, which is signed: addition and cast ok */
	olen = (size_t)((s_bsdipa_off_t)sizeof(dcp->dc_header) + dcp->dc_ctrl_len + diflen + extlen);
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
			zsp->next_in = (Bytef z_const*)(void*)dcp->dc_header;
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

			z = (s_bsdipa_off_t)(olen - zsp->avail_out);
			if(y == Z_STREAM_END || (z > 0 && zsp->avail_out == 0)){
				int xarg;

				/* */
				if(y != Z_STREAM_END){
					if(try_oneshot < 0)
						try_oneshot = 1;
					xarg = 0;
				}else
					xarg = (try_oneshot < 0) ? -(int)(s_bsdipa_off_t)++olen : 1;

				if((rv = (*hook)(hook_cookie, obuf, z, xarg)) != s_BSDIPA_OK)
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
s_bsdipa_io_read_zlib(struct s_bsdipa_patch_ctx *pcp, struct s_bsdipa_io_cookie *io_cookie_or_null){
	uint8_t hbuf[sizeof(struct s_bsdipa_header)];
	z_stream zs;
	s_bsdipa_off_t reslen;
	enum s_bsdipa_state rv;
	z_streamp zsp;
	uint64_t patlen;
	(void)io_cookie_or_null;

	pcp->pc_restored_dat = NULL;
	patlen = pcp->pc_patch_len;

	/* make inflateEnd() callable; Without too much effort: we need to make available an entire frame */
	zsp = &zs;
	zs.zalloc = &s__bsdipa_io_zlib_alloc;
	zs.zfree = &s__bsdipa_io_zlib_free;
	zs.opaque = (void*)&pcp->pc_mem;

	zs.next_in = (Bytef z_const*)(void*)pcp->pc_patch_dat;
	zs.avail_in = (patlen >= INT32_MAX - 1) ? INT32_MAX - 1 : (uInt)patlen;

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

	/* But allocator may not deal */
	if((size_t)reslen != (uInt)reslen){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}
	pcp->pc_restored_len = reslen;
	pcp->pc_restored_dat = (uint8_t*)s__bsdipa_io_zlib_alloc(&pcp->pc_mem, 1, (uInt)reslen);
	if(pcp->pc_restored_dat == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}

	zsp->next_out = pcp->pc_restored_dat;
	zsp->avail_out = (reslen > s__BSDIPA_IO_ZLIB_LIMIT) ? s__BSDIPA_IO_ZLIB_LIMIT : (uInt)reslen;
	reslen -= zsp->avail_out;

	patlen -= (char const*)zsp->next_in - (char*)(void*)pcp->pc_patch_dat;
	zsp->avail_in = (patlen > s__BSDIPA_IO_ZLIB_LIMIT) ? s__BSDIPA_IO_ZLIB_LIMIT : (uInt)patlen;
	patlen -= zsp->avail_in;

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
			patlen -= zsp->avail_in;
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

# undef s__BSDIPA_IO_ZLIB_LIMIT
# undef s_BSDIPA_IO_ZLIB_LEVEL
/* }}} */

#elif s_BSDIPA_IO == s_BSDIPA_IO_XZ /* _IO_ZLIB {{{ */
/*# undef s_BSDIPA_IO*/
# ifdef s__BSDIPA_IO_XZ
#  error s_BSDIPA_IO==s_BSDIPA_IO_XZ already defined
# endif
# define s__BSDIPA_IO_XZ
# define s_BSDIPA_IO_NAME s_BSDIPA_IO_NAME_XZ

# include <assert.h>

# include <lzma.h>

# ifndef s_BSDIPA_IO_XZ_PRESET
#  define s_BSDIPA_IO_XZ_PRESET 8
# endif
# ifndef s_BSDIPA_IO_XZ_CHECK
#  ifdef s_BSDIPA_32
#   define s_BSDIPA_IO_XZ_CHECK LZMA_CHECK_CRC32
#  else
#   define s_BSDIPA_IO_XZ_CHECK LZMA_CHECK_CRC64
#  endif
# endif

 /* For testing purposes */
# define s__BSDIPA_IO_XZ_LIMIT (INT32_MAX - 1)

struct s_bsdipa_io_cookie_xz{
	struct s_bsdipa_io_cookie iocx_super;
	struct s_bsdipa_memory_ctx iocx_mctx;
	lzma_stream iocx_s;
	lzma_allocator iocx_a;
};

/* fun {{{ */
static void *s__bsdipa_io_xz_alloc(void *my_cookie, size_t no, size_t size);
static void s__bsdipa_io_xz_free(void *my_cookie, void *dat);
static inline lzma_stream *s__bsdipa_io_cookie_create_xz(struct s_bsdipa_io_cookie *iocp,
		struct s_bsdipa_memory_ctx const *mcp);
s_BSDIPA_IO_LINKAGE void s_bsdipa_io_cookie_gut_xz(struct s_bsdipa_io_cookie *iocp);

static void *
s__bsdipa_io_xz_alloc(void *my_cookie, size_t no, size_t size){
	void *rv;
	size_t memsz;
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;
	memsz = no * size;

	rv = (mcp->mc_alloc != NULL) ? (*mcp->mc_alloc)(memsz) : (*mcp->mc_custom_alloc)(mcp->mc_custom_cookie, memsz);

	return rv;
}

static void
s__bsdipa_io_xz_free(void *my_cookie, void *dat){
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;

	/* (lzma/base.h does not say, but not only what came via alloc()..) */
	if(dat != NULL)
		(mcp->mc_alloc != NULL) ? (*mcp->mc_free)(dat) : (*mcp->mc_custom_free)(mcp->mc_custom_cookie, dat);
}

static inline lzma_stream *
s__bsdipa_io_cookie_create_xz(struct s_bsdipa_io_cookie *iocp, struct s_bsdipa_memory_ctx const *mcp){
	struct s_bsdipa_io_cookie_xz *iocxp;

	iocxp = (struct s_bsdipa_io_cookie_xz*)(void*)iocp;

	if(!iocxp->iocx_super.ioc_is_init){
		iocxp->iocx_super.ioc_is_init = 1;
		if(iocxp->iocx_super.ioc_level == 0)
			iocxp->iocx_super.ioc_level = s_BSDIPA_IO_XZ_PRESET;
		iocxp->iocx_mctx = *mcp;
		iocxp->iocx_a.alloc = &s__bsdipa_io_xz_alloc;
		iocxp->iocx_a.free = &s__bsdipa_io_xz_free;
		iocxp->iocx_a.opaque = (void*)&iocxp->iocx_mctx;
		iocxp->iocx_s.allocator = &iocxp->iocx_a;
	}

	return &iocxp->iocx_s;
}

s_BSDIPA_IO_LINKAGE void
s_bsdipa_io_cookie_gut_xz(struct s_bsdipa_io_cookie *iocp){
	if(iocp != NULL && iocp->ioc_is_init && iocp->ioc_type == s_BSDIPA_IO_XZ){
		struct s_bsdipa_io_cookie_xz *iocxp;

		iocxp = (struct s_bsdipa_io_cookie_xz*)(void*)iocp;
		lzma_end(&iocxp->iocx_s);
	}
}
/* }}} */

# ifdef s_BSDIPA_IO_WRITE /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_xz(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *hook_cookie,
		int try_oneshot, struct s_bsdipa_io_cookie *io_cookie_or_null){
	lzma_stream zs, *zsp;
	lzma_allocator za;
	struct s_bsdipa_ctrl_chunk *ccp;
	char x;
	enum s_bsdipa_state rv;
	uint8_t *obuf;
	size_t olen;
	s_bsdipa_off_t diflen, extlen;
	uint32_t preset;

	if(io_cookie_or_null == NULL || io_cookie_or_null->ioc_type != s_BSDIPA_IO_XZ){
		io_cookie_or_null = NULL;
		memset(zsp = &zs, 0, sizeof(zs));
		za.alloc = &s__bsdipa_io_xz_alloc;
		za.free = &s__bsdipa_io_xz_free;
		za.opaque = (void*)&dcp->dc_mem;
		zsp->allocator = &za;
		preset = s_BSDIPA_IO_XZ_PRESET;
	}else{
		zsp = s__bsdipa_io_cookie_create_xz(io_cookie_or_null, &dcp->dc_mem);
		preset = io_cookie_or_null->ioc_level;
	}

	switch(lzma_easy_encoder(zsp, preset, s_BSDIPA_IO_XZ_CHECK)){
	case LZMA_OK: break;
	case LZMA_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jleave;
	/* LZMA_OPTIONS_ERROR: */
	/* LZMA_UNSUPPORTED_CHECK: */
	/* LZMA_PROG_ERROR: */
	default: rv = s_BSDIPA_INVAL; goto jleave;
	}

	diflen = dcp->dc_diff_len;
	extlen = dcp->dc_extra_len;

	/* All lengths fit in s_BSDIPA_OFF_MAX, which is signed: addition and cast ok */
	olen = (size_t)((s_bsdipa_off_t)sizeof(dcp->dc_header) + dcp->dc_ctrl_len + diflen + extlen);
	if(try_oneshot){
		size_t ulo;

		ulo = olen; /* XXX check overflow? s_bsdipa_off_t>size_t case? */
		ulo = lzma_stream_buffer_bound(ulo);
		if(ulo >= s_BSDIPA_OFF_MAX){
			try_oneshot = 0;
			goto jolenmax;
		}
		/* Add "one additional byte" already here in case buffer takeover succeeds */
		if(ulo >= (size_t)-1 - 1){
			try_oneshot = 0;
			goto jolenmax;
		}
		olen = ++ulo;
	}else if(olen <= 1000 * 150)
		olen = 4096 * 4;
	else if(olen <= 1000 * 1000)
		olen = 4096 * 31;
	else
jolenmax:
		olen = 4096 * 244;

	obuf = (uint8_t*)s__bsdipa_io_xz_alloc((void*)&dcp->dc_mem, 1, olen);
	if(obuf == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}
	olen -= (try_oneshot != 0);

	zsp->next_out = obuf;
	zsp->avail_out = olen;
	ccp = dcp->dc_ctrl;

	for(x = 0;;){
		lzma_action flusht;

		flusht = LZMA_RUN;
		if(x == 0){
			zsp->next_in = dcp->dc_header;
			zsp->avail_in = sizeof(dcp->dc_header);
			x = 1;
		}else if(x == 1){
			if(ccp != NULL){
				zsp->next_in = ccp->cc_dat;
				zsp->avail_in = (size_t)ccp->cc_len;
				ccp = ccp->cc_next;
			}
			if(ccp == NULL)
				x = 2;
		}else if(x < 4){
			if(x == 2)
				zsp->next_in = dcp->dc_diff_dat;
			if(diflen > s__BSDIPA_IO_XZ_LIMIT){
				zsp->avail_in = s__BSDIPA_IO_XZ_LIMIT;
				diflen -= s__BSDIPA_IO_XZ_LIMIT;
				x = 3;
			}else{
				zsp->avail_in = (size_t)diflen;
				x = 4;
			}
		}else if(x < 6){
			if(x == 4)
				zsp->next_in = dcp->dc_extra_dat;
			if(extlen > s__BSDIPA_IO_XZ_LIMIT){
				zsp->avail_in = s__BSDIPA_IO_XZ_LIMIT;
				extlen -= s__BSDIPA_IO_XZ_LIMIT;
				x = 5;
			}else{
				zsp->avail_in = (size_t)extlen;
				x = 6;
			}
		}else{
			zsp->avail_in = 0; /* xxx redundant */
			flusht = LZMA_FINISH;
			x = 7;
		}

		if(zsp->avail_in > 0 || flusht == LZMA_FINISH) for(;;){
			s_bsdipa_off_t z;
			lzma_ret y;

			y = lzma_code(zsp, flusht);

			switch(y){
			case LZMA_OK: break;
			case LZMA_MEM_ERROR: rv = s_BSDIPA_NOMEM; break;
			case LZMA_STREAM_END: assert(flusht == LZMA_FINISH); break;
			case LZMA_BUF_ERROR: assert(zsp->avail_out == 0); break;
			default: rv = s_BSDIPA_INVAL; goto jdone;
			}

			z = (s_bsdipa_off_t)(olen - zsp->avail_out);
			if(y == LZMA_STREAM_END || (z > 0 && zsp->avail_out == 0)){
				int xarg;

				/* */
				if(y != LZMA_STREAM_END){
					if(try_oneshot < 0)
						try_oneshot = 1;
					xarg = 0;
				}else
					xarg = (try_oneshot < 0) ? -(int)(s_bsdipa_off_t)++olen : 1;

				if((rv = (*hook)(hook_cookie, obuf, z, xarg)) != s_BSDIPA_OK)
					goto jdone;

				if(xarg){
					/* Did we transfer buffer ownership? */
					if(xarg < 0)
						obuf = NULL;
					goto jdone;
				}
				zsp->next_out = obuf;
				zsp->avail_out = olen;
			}

			if(flusht == LZMA_FINISH){
				assert(y != LZMA_STREAM_END);
				continue;
			}
			if(zsp->avail_in == 0)
				break;
		}
		assert(x != 7);
	}

jdone:
	if(obuf != NULL)
		s__bsdipa_io_xz_free((void*)&dcp->dc_mem, obuf);

	if(io_cookie_or_null == NULL)
		lzma_end(zsp);

jleave:
	return rv;
}
# endif /* }}} s_BSDIPA_IO_WRITE */

# ifdef s_BSDIPA_IO_READ /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_read_xz(struct s_bsdipa_patch_ctx *pcp, struct s_bsdipa_io_cookie *io_cookie_or_null){
	uint8_t hbuf[sizeof(struct s_bsdipa_header)];
	lzma_stream zs, *zsp;
	lzma_allocator za;
	s_bsdipa_off_t reslen;
	enum s_bsdipa_state rv;
	uint64_t patlen;

	pcp->pc_restored_dat = NULL;
	patlen = pcp->pc_patch_len;

	if(io_cookie_or_null == NULL || io_cookie_or_null->ioc_type != s_BSDIPA_IO_XZ){
		io_cookie_or_null = NULL;
		memset(zsp = &zs, 0, sizeof(zs));
		za.alloc = &s__bsdipa_io_xz_alloc;
		za.free = &s__bsdipa_io_xz_free;
		za.opaque = (void*)&pcp->pc_mem;
		zsp->allocator = &za;
	}else
		zsp = s__bsdipa_io_cookie_create_xz(io_cookie_or_null, &pcp->pc_mem);

	/* Without too much effort: we need to make available an entire frame */
	zsp->next_in = pcp->pc_patch_dat;
	zsp->avail_in = (patlen >= INT32_MAX - 1) ? INT32_MAX - 1 : (size_t)patlen;

	switch(lzma_stream_decoder(zsp, UINT64_MAX, 0
#  ifdef LZMA_FAIL_FAST
			| LZMA_FAIL_FAST
#  endif
		)){
	case LZMA_OK: break;
	case LZMA_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
	/* LZMA_OPTIONS_ERROR: */
	/* LZMA_PROG_ERROR: */
	default: rv = s_BSDIPA_INVAL; goto jdone;
	}

	zsp->next_out = hbuf;
	zsp->avail_out = sizeof(hbuf);

	switch(lzma_code(zsp, LZMA_RUN)){
	case LZMA_OK: break;
	case LZMA_STREAM_END: break;
	case LZMA_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
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
	pcp->pc_restored_dat = (uint8_t*)s__bsdipa_io_xz_alloc(&pcp->pc_mem, 1, (size_t)reslen);
	if(pcp->pc_restored_dat == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}

	zsp->next_out = pcp->pc_restored_dat;
	zsp->avail_out = (size_t)((reslen > s__BSDIPA_IO_XZ_LIMIT) ? s__BSDIPA_IO_XZ_LIMIT : reslen);
	reslen -= zsp->avail_out;

	patlen -= zsp->next_in - pcp->pc_patch_dat;
	zsp->avail_in = (size_t)((patlen > s__BSDIPA_IO_XZ_LIMIT) ? s__BSDIPA_IO_XZ_LIMIT : patlen);
	patlen -= zsp->avail_in;

	for(;;){
		lzma_ret y;
		lzma_action x;

		x = (reslen == 0 && patlen == 0) ? LZMA_FINISH : LZMA_RUN;
		y = lzma_code(zsp, x);

		switch(y){
		case LZMA_OK: break;
		case LZMA_BUF_ERROR:
			if(x == LZMA_FINISH){
				rv = s_BSDIPA_INVAL;
				goto jdone;
			}
			break;
		case LZMA_STREAM_END:
			if(x == LZMA_FINISH){
				rv = s_BSDIPA_OK;
				goto jdone;
			}
			break;
		case LZMA_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
		default: rv = s_BSDIPA_INVAL; goto jdone;
		}

		if(zsp->avail_out == 0){
			zsp->avail_out = (size_t)((reslen > s__BSDIPA_IO_XZ_LIMIT) ? s__BSDIPA_IO_XZ_LIMIT : reslen);
			reslen -= (s_bsdipa_off_t)zsp->avail_out;
		}
		if(zsp->avail_in == 0){
			zsp->avail_in = (size_t)((patlen > s__BSDIPA_IO_XZ_LIMIT) ? s__BSDIPA_IO_XZ_LIMIT : patlen);
			patlen -= zsp->avail_in;
		}
	}

jdone:
	if(io_cookie_or_null == NULL)
		lzma_end(zsp);

	if(rv != s_BSDIPA_OK && pcp->pc_restored_dat != NULL){
		s__bsdipa_io_xz_free(&pcp->pc_mem, pcp->pc_restored_dat);
		pcp->pc_restored_dat = NULL;
	}

	return rv;
}
# endif /* }}} s_BSDIPA_IO_READ */

# undef s__BSDIPA_IO_XZ_LIMIT
# undef s_BSDIPA_IO_XZ_CHECK
# undef s_BSDIPA_IO_XZ_PRESET
/* }}} */

#elif s_BSDIPA_IO == s_BSDIPA_IO_BZ2 /* _IO_XZ {{{ */
/*# undef s_BSDIPA_IO*/
# ifdef s__BSDIPA_IO_BZ2
#  error s_BSDIPA_IO==s_BSDIPA_IO_BZ2 already defined
# endif
# define s__BSDIPA_IO_BZ2
# define s_BSDIPA_IO_NAME s_BSDIPA_IO_NAME_BZ2

# include <assert.h>

# include <bzlib.h>

# ifndef s_BSDIPA_IO_BZ2_BLOCKSIZE
#  define s_BSDIPA_IO_BZ2_BLOCKSIZE 9
# endif
# ifndef s_BSDIPA_IO_BZ2_VERBOSITY
#  define s_BSDIPA_IO_BZ2_VERBOSITY 0
# endif
# ifndef s_BSDIPA_IO_BZ2_SMALL
#  define s_BSDIPA_IO_BZ2_SMALL 0
# endif

 /* For testing purposes */
# define s__BSDIPA_IO_BZ2_LIMIT (INT32_MAX - 1)

static void *s__bsdipa_io_bz2_alloc(void *my_cookie, int no, int size);
static void s__bsdipa_io_bz2_free(void *my_cookie, void *dat);

static void *
s__bsdipa_io_bz2_alloc(void *my_cookie, int no, int size){
	void *rv;
	size_t memsz;
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;
	memsz = (size_t)no * (size_t)size;

	rv = (mcp->mc_alloc != NULL) ? (*mcp->mc_alloc)(memsz) : (*mcp->mc_custom_alloc)(mcp->mc_custom_cookie, memsz);

	return rv;
}

static void
s__bsdipa_io_bz2_free(void *my_cookie, void *dat){
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;

	(mcp->mc_alloc != NULL) ? (*mcp->mc_free)(dat) : (*mcp->mc_custom_free)(mcp->mc_custom_cookie, dat);
}

# ifdef s_BSDIPA_IO_WRITE /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_bz2(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *hook_cookie,
		int try_oneshot, struct s_bsdipa_io_cookie *io_cookie_or_null){
	bz_stream bzs;
	struct s_bsdipa_ctrl_chunk *ccp;
	char x;
	enum s_bsdipa_state rv;
	uint8_t *obuf;
	size_t olen;
	s_bsdipa_off_t diflen, extlen;

	bzs.bzalloc = &s__bsdipa_io_bz2_alloc;
	bzs.bzfree = &s__bsdipa_io_bz2_free;
	bzs.opaque = (void*)&dcp->dc_mem;

	/* C99 */{
		int level;

		level = s_BSDIPA_IO_BZ2_BLOCKSIZE;
		if(io_cookie_or_null != NULL && io_cookie_or_null->ioc_level != 0)
			level = (int)io_cookie_or_null->ioc_level;

		switch(BZ2_bzCompressInit(&bzs, level, s_BSDIPA_IO_BZ2_VERBOSITY, 0)){
		case BZ_OK: break;
		case BZ_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jleave;
		default: rv = s_BSDIPA_INVAL; goto jleave;
		}
	}

	diflen = dcp->dc_diff_len;
	extlen = dcp->dc_extra_len;

	/* All lengths fit in s_BSDIPA_OFF_MAX, which is signed: addition and cast ok */
	olen = (size_t)((s_bsdipa_off_t)sizeof(dcp->dc_header) + dcp->dc_ctrl_len + diflen + extlen);
	if(try_oneshot){
		size_t i;

		/* Random data (eg compressor output) requires ~0.5% expansion; be safe and go for 10% */
		i = olen / 10;
		if(olen >= s_BSDIPA_OFF_MAX - i){
			try_oneshot = 0;
			goto jolenmax;
		}
		/* Add "one additional byte" already here in case buffer takeover succeeds */
		i += ++olen;
		if(i != (size_t)(int)i){
			try_oneshot = 0;
			goto jolenmax;
		}
		olen = i;
	}else if(olen <= 1000 * 150)
		olen = 4096 * 4;
	else if(olen <= 1000 * 1000)
		olen = 4096 * 31;
	else
jolenmax:
		olen = 4096 * 244;

	obuf = (uint8_t*)s__bsdipa_io_bz2_alloc((void*)&dcp->dc_mem, 1, (int)olen);
	if(obuf == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}
	olen -= (try_oneshot != 0);

	bzs.next_out = (char*)obuf;
	bzs.avail_out = (unsigned int)olen;
	ccp = dcp->dc_ctrl;

	for(x = 0;;){
		int flusht;

		flusht = BZ_RUN;
		if(x == 0){
			bzs.next_in = (char*)(void*)dcp->dc_header;
			bzs.avail_in = sizeof(dcp->dc_header);
			x = 1;
		}else if(x == 1){
			if(ccp != NULL){
				bzs.next_in = (char*)ccp->cc_dat;
				bzs.avail_in = (unsigned int)ccp->cc_len;
				ccp = ccp->cc_next;
			}
			if(ccp == NULL)
				x = 2;
		}else if(x < 4){
			if(x == 2)
				bzs.next_in = (char*)dcp->dc_diff_dat;
			if(diflen > s__BSDIPA_IO_BZ2_LIMIT){
				bzs.avail_in = s__BSDIPA_IO_BZ2_LIMIT;
				diflen -= s__BSDIPA_IO_BZ2_LIMIT;
				x = 3;
			}else{
				bzs.avail_in = (unsigned int)diflen;
				x = 4;
			}
		}else if(x < 6){
			if(x == 4)
				bzs.next_in = (char*)dcp->dc_extra_dat;
			if(extlen > s__BSDIPA_IO_BZ2_LIMIT){
				bzs.avail_in = s__BSDIPA_IO_BZ2_LIMIT;
				extlen -= s__BSDIPA_IO_BZ2_LIMIT;
				x = 5;
			}else{
				bzs.avail_in = (unsigned int)extlen;
				x = 6;
			}
		}else{
			bzs.avail_in = 0; /* xxx redundant */
			flusht = BZ_FINISH;
			x = 7;
		}

		if(bzs.avail_in > 0 || flusht == BZ_FINISH) for(;;){
			s_bsdipa_off_t z;
			int y;

			y = BZ2_bzCompress(&bzs, flusht);

			switch(y){
			case BZ_OK: /* FALLTHRU */
			case BZ_RUN_OK: /* FALLTHRU */
			case BZ_FINISH_OK: break;
			case BZ_STREAM_END: assert(flusht == BZ_FINISH); break;
			case BZ_OUTBUFF_FULL: assert(bzs.avail_out == 0); break;
			default: rv = s_BSDIPA_INVAL; goto jdone;
			}

			z = (s_bsdipa_off_t)(olen - bzs.avail_out);
			if(y == BZ_STREAM_END || (z > 0 && bzs.avail_out == 0)){
				int xarg;

				/* */
				if(y != BZ_STREAM_END){
					if(try_oneshot < 0)
						try_oneshot = 1;
					xarg = 0;
				}else
					xarg = (try_oneshot < 0) ? -(int)(s_bsdipa_off_t)++olen : 1;

				if((rv = (*hook)(hook_cookie, obuf, z, xarg)) != s_BSDIPA_OK)
					goto jdone;

				if(xarg){
					/* Did we transfer buffer ownership? */
					if(xarg < 0)
						obuf = NULL;
					goto jdone;
				}
				bzs.next_out = (char*)obuf;
				bzs.avail_out = (unsigned int)olen;
			}

			if(flusht == BZ_FINISH){
				assert(y != BZ_STREAM_END);
				continue;
			}
			if(bzs.avail_in == 0)
				break;
		}
		assert(x != 7);
	}

jdone:
	if(obuf != NULL)
		s__bsdipa_io_bz2_free((void*)&dcp->dc_mem, obuf);

	BZ2_bzCompressEnd(&bzs);
jleave:
	return rv;
}
# endif /* }}} s_BSDIPA_IO_WRITE */

# ifdef s_BSDIPA_IO_READ /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_read_bz2(struct s_bsdipa_patch_ctx *pcp, struct s_bsdipa_io_cookie *io_cookie_or_null){
	uint8_t hbuf[sizeof(struct s_bsdipa_header)];
	bz_stream bzs;
	s_bsdipa_off_t reslen;
	enum s_bsdipa_state rv;
	uint64_t patlen;
	(void)io_cookie_or_null;

	pcp->pc_restored_dat = NULL;
	patlen = pcp->pc_patch_len;

	bzs.bzalloc = &s__bsdipa_io_bz2_alloc;
	bzs.bzfree = &s__bsdipa_io_bz2_free;
	bzs.opaque = (void*)&pcp->pc_mem;

	/* Without too much effort: we need to make available an entire frame */
	bzs.next_in = (char*)(void*)pcp->pc_patch_dat;
	bzs.avail_in = (patlen >= INT32_MAX - 1) ? INT32_MAX - 1 : (unsigned int)patlen;

	switch(BZ2_bzDecompressInit(&bzs, s_BSDIPA_IO_BZ2_VERBOSITY, s_BSDIPA_IO_BZ2_SMALL)){
	case BZ_OK: break;
	case BZ_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
	default: rv = s_BSDIPA_INVAL; goto jdone;
	}

	bzs.next_out = (char*)hbuf;
	bzs.avail_out = sizeof(hbuf);

	switch(BZ2_bzDecompress(&bzs)){
	case BZ_OK: assert(bzs.next_out != NULL); break;
	case BZ_STREAM_END: bzs.next_out = NULL; break;
	case BZ_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
	default: rv = s_BSDIPA_INVAL; goto jdone;
	}
	if(bzs.avail_out != 0){
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

	/* But allocator may not deal */
	if((size_t)reslen != (size_t)(int)reslen){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}
	pcp->pc_restored_len = reslen;
	pcp->pc_restored_dat = (uint8_t*)s__bsdipa_io_bz2_alloc(&pcp->pc_mem, 1, (int)reslen);
	if(pcp->pc_restored_dat == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}

	/* BZ2 does not like continuing after a STREAM_END! */
	if(bzs.next_out == NULL){
		rv = s_BSDIPA_OK;
		goto jdone;
	}

	bzs.next_out = (char*)pcp->pc_restored_dat;
	bzs.avail_out = (reslen > s__BSDIPA_IO_BZ2_LIMIT) ? s__BSDIPA_IO_BZ2_LIMIT : (unsigned int)reslen;
	reslen -= bzs.avail_out;

	patlen -= bzs.next_in - (char const*)pcp->pc_patch_dat;
	bzs.avail_in = (patlen > s__BSDIPA_IO_BZ2_LIMIT) ? s__BSDIPA_IO_BZ2_LIMIT : (unsigned int)patlen;
	patlen -= (unsigned int)bzs.avail_in;

	for(;;){
		int x, y;

		x = (reslen == 0 && patlen == 0) ? BZ_FINISH : BZ_RUN;
		y = BZ2_bzDecompress(&bzs);

		switch(y){
		case BZ_OK: break;
		case BZ_STREAM_END:
			if(x == BZ_FINISH){
				rv = s_BSDIPA_OK;
				goto jdone;
			}
			break;
		case BZ_MEM_ERROR: rv = s_BSDIPA_NOMEM; goto jdone;
		default: rv = s_BSDIPA_INVAL; goto jdone;
		}

		if(bzs.avail_out == 0){
			bzs.avail_out = (unsigned int)((reslen > s__BSDIPA_IO_BZ2_LIMIT)
					? s__BSDIPA_IO_BZ2_LIMIT : reslen);
			reslen -= (s_bsdipa_off_t)bzs.avail_out;
		}
		if(bzs.avail_in == 0){
			bzs.avail_in = (unsigned int)((patlen > s__BSDIPA_IO_BZ2_LIMIT)
					? s__BSDIPA_IO_BZ2_LIMIT : patlen);
			patlen -= bzs.avail_in;
		}
	}

jdone:
	BZ2_bzDecompressEnd(&bzs);

	if(rv != s_BSDIPA_OK && pcp->pc_restored_dat != NULL){
		s__bsdipa_io_bz2_free(&pcp->pc_mem, pcp->pc_restored_dat);
		pcp->pc_restored_dat = NULL;
	}

	return rv;
}
# endif /* }}} s_BSDIPA_IO_READ */

# undef s__BSDIPA_IO_BZ2_LIMIT
# undef s_BSDIPA_IO_BZ2_SMALL
# undef s_BSDIPA_IO_BZ2_VERBOSITY
# undef s_BSDIPA_IO_BZ2_BLOCKSIZE
/* }}} */

#elif s_BSDIPA_IO == s_BSDIPA_IO_ZSTD /* _IO_BZ2 {{{ */
/*# undef s_BSDIPA_IO*/
# ifdef s__BSDIPA_IO_ZSTD
#  error s_BSDIPA_IO==s_BSDIPA_IO_ZSTD already defined
# endif
# define s__BSDIPA_IO_ZSTD
# define s_BSDIPA_IO_NAME s_BSDIPA_IO_NAME_ZSTD

 /* Give us the interface we want; libraries export it, anyway */
# define ZSTD_STATIC_LINKING_ONLY
# include <zstd.h>

# if ZSTD_VERSION_MAJOR < 1 || (ZSTD_VERSION_MAJOR == 1 && ZSTD_VERSION_MINOR < 4)
#  error S-bsdipa ZSTD I/O believes it requires zstd v1.4.0 or above
# endif

# ifndef s_BSDIPA_IO_ZSTD_LEVEL
#  define s_BSDIPA_IO_ZSTD_LEVEL 8
# endif
# ifndef s_BSDIPA_IO_ZSTD_CHECKSUM
#  define s_BSDIPA_IO_ZSTD_CHECKSUM 1
# endif

 /* For testing purposes */
# define s__BSDIPA_IO_ZSTD_LIMIT (INT32_MAX - 1)

struct s_bsdipa_io_cookie_zstd{
	struct s_bsdipa_io_cookie iocZ_super;
	struct s_bsdipa_memory_ctx iocZ_mctx;
	ZSTD_customMem iocZ_zcm;
	ZSTD_CCtx *iocZ_zcp;
	ZSTD_DCtx *iocZ_zdp;
};

/* fun {{{ */
static void *s__bsdipa_io_zstd_alloc(void *my_cookie, size_t size);
static void s__bsdipa_io_zstd_free(void *my_cookie, void *dat);
static enum s_bsdipa_state s__bsdipa_io_cookie_create_zstd(int xwrite, struct s_bsdipa_io_cookie *iocp,
		struct s_bsdipa_memory_ctx const *mcp);
s_BSDIPA_IO_LINKAGE void s_bsdipa_io_cookie_gut_zstd(struct s_bsdipa_io_cookie *iocp);

static void *
s__bsdipa_io_zstd_alloc(void *my_cookie, size_t size){
	void *rv;
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;

	rv = (mcp->mc_alloc != NULL) ? (*mcp->mc_alloc)(size) : (*mcp->mc_custom_alloc)(mcp->mc_custom_cookie, size);

	return rv;
}

static void
s__bsdipa_io_zstd_free(void *my_cookie, void *dat){
	struct s_bsdipa_memory_ctx *mcp;

	mcp = (struct s_bsdipa_memory_ctx*)my_cookie;

	(mcp->mc_alloc != NULL) ? (*mcp->mc_free)(dat) : (*mcp->mc_custom_free)(mcp->mc_custom_cookie, dat);
}

static enum s_bsdipa_state
s__bsdipa_io_cookie_create_zstd(int xwrite, struct s_bsdipa_io_cookie *iocp, struct s_bsdipa_memory_ctx const *mcp){
	enum s_bsdipa_state rv;
	struct s_bsdipa_io_cookie_zstd *iocZp;

	iocZp = (struct s_bsdipa_io_cookie_zstd*)(void*)iocp;

	if(!iocZp->iocZ_super.ioc_is_init){
		iocZp->iocZ_super.ioc_is_init = 1;
		iocZp->iocZ_super.ioc_type = s_BSDIPA_IO_ZSTD;
		if(iocZp->iocZ_super.ioc_level == 0)
			iocZp->iocZ_super.ioc_level = s_BSDIPA_IO_ZSTD_LEVEL;
		iocZp->iocZ_mctx = *mcp;
		iocZp->iocZ_zcm.customAlloc = &s__bsdipa_io_zstd_alloc;
		iocZp->iocZ_zcm.customFree = &s__bsdipa_io_zstd_free;
		iocZp->iocZ_zcm.opaque = (void*)&iocZp->iocZ_mctx;
	}

	if(xwrite){
		size_t r;
		ZSTD_CCtx* cp;

		if((cp = iocZp->iocZ_zcp) == NULL){
			cp = iocZp->iocZ_zcp = ZSTD_createCCtx_advanced(iocZp->iocZ_zcm);
			if(cp == NULL){
				rv = s_BSDIPA_NOMEM;
				goto jleave;
			}
		}else
			(void)ZSTD_CCtx_reset(cp, ZSTD_reset_session_and_parameters);

		rv = s_BSDIPA_INVAL;
		/* Convert from our 1-9 scale to zstd's 1..x scale */
		/* C99 */{
			int myp, zp;

			myp = ((int)iocZp->iocZ_super.ioc_level * 100) / ((9 * 100) / 100);
			zp = (((ZSTD_maxCLevel() * 100) / 100) * myp) / 100;
			r = ZSTD_CCtx_setParameter(cp, ZSTD_c_compressionLevel, zp);
		}
		if(ZSTD_isError(r))
			goto jleave;
		r = ZSTD_CCtx_setParameter(cp, ZSTD_c_strategy, iocZp->iocZ_super.ioc_level);
		if(ZSTD_isError(r))
			goto jleave;
		/* Checksum default is 0 */
# if s_BSDIPA_IO_ZSTD_CHECKSUM
		r = ZSTD_CCtx_setParameter(cp, ZSTD_c_checksumFlag, s_BSDIPA_IO_ZSTD_CHECKSUM);
		if(ZSTD_isError(r))
			goto jleave;
# endif
	}else{
		ZSTD_DCtx* dp;

		if((dp = iocZp->iocZ_zdp) == NULL){
			dp = iocZp->iocZ_zdp = ZSTD_createDCtx_advanced(iocZp->iocZ_zcm);
			if(dp == NULL){
				rv = s_BSDIPA_NOMEM;
				goto jleave;
			}
		}else
			(void)ZSTD_DCtx_reset(dp, ZSTD_reset_session_and_parameters);
	}

	rv = s_BSDIPA_OK;
jleave:
	return rv;
}

s_BSDIPA_IO_LINKAGE void
s_bsdipa_io_cookie_gut_zstd(struct s_bsdipa_io_cookie *iocp){
	if(iocp != NULL && iocp->ioc_is_init && iocp->ioc_type == s_BSDIPA_IO_ZSTD){
		struct s_bsdipa_io_cookie_zstd *iocZp;

		iocZp = (struct s_bsdipa_io_cookie_zstd*)(void*)iocp;

		if(iocZp->iocZ_zcp != NULL)
			(void)ZSTD_freeCCtx(iocZp->iocZ_zcp);
		if(iocZp->iocZ_zdp != NULL)
			(void)ZSTD_freeDCtx(iocZp->iocZ_zdp);
	}
}
/* }}} */

# ifdef s_BSDIPA_IO_WRITE /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_write_zstd(struct s_bsdipa_diff_ctx const *dcp, s_bsdipa_io_write_ptf hook, void *hook_cookie,
		int try_oneshot, struct s_bsdipa_io_cookie *io_cookie_or_null){
	ZSTD_inBuffer zib;
	ZSTD_outBuffer zob;
	struct s_bsdipa_io_cookie_zstd iocZ;
	char x;
	struct s_bsdipa_ctrl_chunk *ccp;
	enum s_bsdipa_state rv;
	uint8_t *obuf;
	size_t olen;
	s_bsdipa_off_t diflen, extlen;

	if(io_cookie_or_null == NULL || io_cookie_or_null->ioc_type != s_BSDIPA_IO_ZSTD)
		memset(io_cookie_or_null = &iocZ.iocZ_super, 0, sizeof(iocZ));

	rv = s__bsdipa_io_cookie_create_zstd(1, io_cookie_or_null, &dcp->dc_mem);
	if(rv != s_BSDIPA_OK)
		goto jleave;

	diflen = dcp->dc_diff_len;
	extlen = dcp->dc_extra_len;

	/* All lengths fit in s_BSDIPA_OFF_MAX, which is signed: addition and cast ok */
	olen = (size_t)((s_bsdipa_off_t)sizeof(dcp->dc_header) + dcp->dc_ctrl_len + diflen + extlen);
	if(try_oneshot){
		size_t ulo;

		ulo = olen; /* XXX check overflow? s_bsdipa_off_t>size_t case? */
		ulo = ZSTD_COMPRESSBOUND(ulo);
		if(ulo == 0 || ulo >= s_BSDIPA_OFF_MAX){
			try_oneshot = 0;
			goto jolenmax;
		}
		/* Add "one additional byte" already here in case buffer takeover succeeds */
		if(ulo >= (size_t)-1 - 1){
			try_oneshot = 0;
			goto jolenmax;
		}
		olen = ++ulo;
	}else if(olen <= 1000 * 150)
		olen = 4096 * 4;
	else if(olen <= 1000 * 1000)
		olen = 4096 * 31;
	else
jolenmax:
		olen = 4096 * 244;

	obuf = (uint8_t*)s__bsdipa_io_zstd_alloc((void*)&dcp->dc_mem, olen);
	if(obuf == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}
	olen -= (try_oneshot != 0);

	zob.dst = obuf;
	zob.size = olen;
	zob.pos = 0;
	ccp = dcp->dc_ctrl;

	for(x = 0;;){
		ZSTD_EndDirective zed;

		zed = ZSTD_e_continue;
		if(x == 0){
			zib.src = dcp->dc_header;
			zib.size = sizeof(dcp->dc_header);
			zib.pos = 0;
			x = 1;
		}else if(x == 1){
			if(ccp != NULL){
				zib.src = ccp->cc_dat;
				zib.size = (size_t)ccp->cc_len;
				zib.pos = 0;
				ccp = ccp->cc_next;
			}
			if(ccp == NULL)
				x = 2;
		}else if(x < 4){
			if(x == 2)
				zib.src = dcp->dc_diff_dat;
			else
				zib.src = &((char*)zib.src)[zib.pos];
			zib.pos = 0;
			if(diflen > s__BSDIPA_IO_ZSTD_LIMIT){
				zib.size = s__BSDIPA_IO_ZSTD_LIMIT;
				diflen -= s__BSDIPA_IO_ZSTD_LIMIT;
				x = 3;
			}else{
				zib.size = (size_t)diflen;
				x = 4;
			}
		}else if(x < 6){
			if(x == 4)
				zib.src = dcp->dc_extra_dat;
			else
				zib.src = &((char*)zib.src)[zib.pos];
			zib.pos = 0;
			if(extlen > s__BSDIPA_IO_ZSTD_LIMIT){
				zib.size = s__BSDIPA_IO_ZSTD_LIMIT;
				extlen -= s__BSDIPA_IO_ZSTD_LIMIT;
				x = 5;
			}else{
				zib.size = (size_t)extlen;
				x = 6;
			}
		}else{
			zib.size = zib.pos = 0; /* xxx redundant? */
			zed = ZSTD_e_end;
			x = 7;
		}

		if(zib.size > 0 || zed == ZSTD_e_end) for(;;){
			int xarg;
			s_bsdipa_off_t z;
			size_t y;

			y = ZSTD_compressStream2(((struct s_bsdipa_io_cookie_zstd*)io_cookie_or_null)->iocZ_zcp,
					&zob, &zib, zed);
			if(y != 0 && ZSTD_isError(y)){
				if(ZSTD_getErrorCode(y) == ZSTD_error_memory_allocation)
					rv = s_BSDIPA_NOMEM;
				else
					rv = s_BSDIPA_INVAL;
				goto jleave;
			}

			/* We have progress says manual */
			if(y != 0 || x != 7){
				if(try_oneshot < 0)
					try_oneshot = 1;
				xarg = 0;
			}else
				xarg = (try_oneshot < 0) ? -(int)(s_bsdipa_off_t)++olen : 1;

			z = (s_bsdipa_off_t)zob.pos;
			if((xarg || z > 0) && (rv = (*hook)(hook_cookie, obuf, z, xarg)) != s_BSDIPA_OK)
				goto jdone;

			if(xarg){
				/* Did we transfer buffer ownership? */
				if(xarg < 0)
					obuf = NULL;
				goto jdone;
			}

			assert(zob.dst == obuf);
			assert(zob.size == olen);
			zob.pos = 0;

			if(zed == ZSTD_e_end)
				continue;
			if(zib.size == zib.pos)
				break;
		}
		assert(x != 7);
	}

jdone:
	if(obuf != NULL)
		s__bsdipa_io_zstd_free((void*)&dcp->dc_mem, obuf);

jleave:
	if(io_cookie_or_null == &iocZ.iocZ_super)
		s_bsdipa_io_cookie_gut_zstd(io_cookie_or_null);

	return rv;
}
# endif /* }}} s_BSDIPA_IO_WRITE */

# ifdef s_BSDIPA_IO_READ /* {{{ */
s_BSDIPA_IO_LINKAGE enum s_bsdipa_state
s_bsdipa_io_read_zstd(struct s_bsdipa_patch_ctx *pcp, struct s_bsdipa_io_cookie *io_cookie_or_null){
	uint8_t hbuf[sizeof(struct s_bsdipa_header)];
	ZSTD_inBuffer zib;
	ZSTD_outBuffer zob;
	struct s_bsdipa_io_cookie_zstd iocZ;
	s_bsdipa_off_t reslen;
	enum s_bsdipa_state rv;
	uint64_t patlen;

	pcp->pc_restored_dat = NULL;
	patlen = pcp->pc_patch_len;

	if(io_cookie_or_null == NULL || io_cookie_or_null->ioc_type != s_BSDIPA_IO_ZSTD)
		memset(io_cookie_or_null = &iocZ.iocZ_super, 0, sizeof(iocZ));

	rv = s__bsdipa_io_cookie_create_zstd(0, io_cookie_or_null, &pcp->pc_mem);
	if(rv != s_BSDIPA_OK)
		goto jdone;

	/* Read bsdipa_header */
	/* C99 */{
		size_t y;

		zob.dst = hbuf;
		zob.size = sizeof(hbuf);
		zob.pos = 0;

		/* Without too much effort: we need to make available an entire frame */
		zib.src = pcp->pc_patch_dat;
		zib.size = (size_t)patlen;
		zib.pos = 0;

		y = ZSTD_decompressStream(((struct s_bsdipa_io_cookie_zstd*)io_cookie_or_null)->iocZ_zdp, &zob, &zib);
		if(y != 0 && ZSTD_isError(y)){
			if(ZSTD_getErrorCode(y) == ZSTD_error_memory_allocation)
				rv = s_BSDIPA_NOMEM;
			else
				rv = s_BSDIPA_INVAL;
			goto jdone;
		}

		if(zob.size != zob.pos){
			rv = s_BSDIPA_INVAL;
			goto jdone;
		}
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
	pcp->pc_restored_dat = (uint8_t*)s__bsdipa_io_zstd_alloc(&pcp->pc_mem, (size_t)reslen);
	if(pcp->pc_restored_dat == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jdone;
	}

	zob.dst = pcp->pc_restored_dat;

	zib.src = &((char const*)zib.src)[zib.pos];
	patlen -= zib.pos;
	zib.pos = 0;

	if(patlen > 0) for(;;){
		size_t y;

		zob.size = (size_t)((reslen > s__BSDIPA_IO_ZSTD_LIMIT) ? s__BSDIPA_IO_ZSTD_LIMIT : reslen);
		reslen -= (s_bsdipa_off_t)zob.size;
		zob.pos = 0;

		zib.src = &((char*)zib.src)[zib.pos];
		zib.size = (size_t)((patlen > s__BSDIPA_IO_ZSTD_LIMIT) ? s__BSDIPA_IO_ZSTD_LIMIT : patlen);
		patlen -= zib.size;
		zib.pos = 0;

		y = ZSTD_decompressStream(((struct s_bsdipa_io_cookie_zstd*)io_cookie_or_null)->iocZ_zdp, &zob, &zib);
		if(y != 0 && ZSTD_isError(y)){
			if(ZSTD_getErrorCode(y) == ZSTD_error_memory_allocation)
				rv = s_BSDIPA_NOMEM;
			else
				rv = s_BSDIPA_INVAL;
			goto jdone;
		}

		if(zob.pos > 0){
			zob.dst = &((char*)zob.dst)[zob.pos];
			zob.size -= zob.pos;
		}
		reslen += zob.size;

		zib.size -= zib.pos;
		if(y == 0 && patlen == 0 && zib.size == 0)
			break;
		patlen += zib.size;
	}

jdone:
	if(io_cookie_or_null == &iocZ.iocZ_super)
		s_bsdipa_io_cookie_gut_zstd(io_cookie_or_null);

	if(rv != s_BSDIPA_OK && pcp->pc_restored_dat != NULL){
		s__bsdipa_io_zstd_free(&pcp->pc_mem, pcp->pc_restored_dat);
		pcp->pc_restored_dat = NULL;
	}

	return rv;
}
# endif /* }}} s_BSDIPA_IO_READ */

# undef s__BSDIPA_IO_ZSTD_LIMIT
# undef s_BSDIPA_IO_ZSTD_CHECKSUM
# undef s_BSDIPA_IO_ZSTD_LEVEL
/* }}} */

#else /* _IO_ZSTD */
# error Unknown s_BSDIPA_IO value
#endif

#ifdef __cplusplus
}
#endif
/* s-itt-mode */
