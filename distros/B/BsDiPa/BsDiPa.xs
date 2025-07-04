/*@ BsDiPa.xs: perl XS interface of/to S-bsdipa.
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

/* assert()ions (otherwise uncomment OPTIMIZE in Makefile.PL) */
/*#define DEBUGGING*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>

#define s_BSDIPA_IO_READ
#define s_BSDIPA_IO_WRITE
/**/
#define s_BSDIPA_IO s_BSDIPA_IO_ZLIB
#include "c-lib/s-bsdipa-io.h"
/**/
#if s__BSDIPA_XZ
# undef s_BSDIPA_IO
# define s_BSDIPA_IO s_BSDIPA_IO_XZ
# include "c-lib/s-bsdipa-io.h"
#endif
/**/
#undef s_BSDIPA_IO
#define s_BSDIPA_IO s_BSDIPA_IO_RAW
#include "c-lib/s-bsdipa-io.h"

#include <c-lib/s-bsdiff.c>
#include <c-lib/s-bspatch.c>

#include <c-lib/libdivsufsort/divsufsort.c>
#undef lg_table
#define lg_table a_sssort_lg_table
#include <c-lib/libdivsufsort/sssort.c>
#undef lg_table
#define lg_table a_trsort_lg_table
#include <c-lib/libdivsufsort/trsort.c>

union a_io_cookie{
	void *ioc_vp;
	struct s_bsdipa_io_cookie *ioc_iocp;
#if s__BSDIPA_XZ
	struct s_bsdipa_io_cookie_xz *ioc_iocxp;
#endif
};

/* For testing purposes allow changes via _try_oneshot_set() */
static IV a_try_oneshot = -1;
static IV const a_have_xz = s__BSDIPA_XZ;

static void *a_alloc(size_t size);
static void a_free(void *vp);

static SV *a_core_diff(int what, SV *before_sv, SV *after_sv, SV *patch_sv, SV *magic_window, SV *is_equal_data,
		SV *io_cookie);
static enum s_bsdipa_state a_core_diff__write(void *user_cookie, uint8_t const *dat, s_bsdipa_off_t len,
		s_bsdipa_off_t is_last);

static SV *a_core_patch(int what, SV *after_sv, SV *patch_sv, SV *before_sv, SV *max_allowed_restored_len,
		SV *io_cookie);

static void *
a_alloc(size_t size){
	char *vp;

	Newx(vp, size, char);

	return vp;
}

static void
a_free(void *vp){
	Safefree(vp);
}

static SV *
a_core_diff(int what, SV *before_sv, SV *after_sv, SV *patch_sv, SV *magic_window, SV *is_equal_data, SV *io_cookie){
	struct s_bsdipa_diff_ctx d;
	struct s_bsdipa_io_cookie *iocp;
	SV *pref, *iseq;
	enum s_bsdipa_state s;

	s = s_BSDIPA_INVAL;

	pref = NULL;
	if(/*!SvOK(patch_sv) ||*/ !SvROK(patch_sv))
		goto jleave;
	pref = SvRV(patch_sv);

	if(/*!SvOK(before_sv) ||*/ !SvPOK(before_sv))
		goto jleave;

	if(/*!SvOK(after_sv) ||*/ !SvPOK(after_sv))
		goto jleave;

	if(magic_window == NULL || !SvOK(magic_window))
		d.dc_magic_window = 0;
	else if(!SvIOK(magic_window))
		goto jleave;
	else{
		IV i;

		i = SvIV(magic_window);
		if(i > 4096) /* <> docu! */
			goto jleave;
		d.dc_magic_window = (int32_t)i;
	}

	if(is_equal_data == NULL || !SvOK(is_equal_data))
		iseq = NULL;
	else if(!SvROK(is_equal_data))
		goto jleave;
	else
		iseq = SvRV(is_equal_data);

	if(io_cookie == NULL || !SvIOK(io_cookie))
		iocp = NULL;
	else
		iocp = INT2PTR(struct s_bsdipa_io_cookie*,SvIV(io_cookie));

	d.dc_mem.mc_alloc = &a_alloc;
	d.dc_mem.mc_free = &a_free;
	d.dc_before_len = SvCUR(before_sv);
	d.dc_before_dat = SvPVbyte_nolen(before_sv);
	d.dc_after_len = SvCUR(after_sv);
	d.dc_after_dat = SvPVbyte_nolen(after_sv);

	s = s_bsdipa_diff(&d);
	if(s != s_BSDIPA_OK)
		goto jdone;

	if(iseq != NULL)
		SvIV_set(iseq, d.dc_is_equal_data);

	SvPVCLEAR(pref);
	if(what == s_BSDIPA_IO_ZLIB)
		s = s_bsdipa_io_write_zlib(&d, &a_core_diff__write, pref, a_try_oneshot, iocp);
#if s__BSDIPA_XZ
	else if(what == s_BSDIPA_IO_XZ)
		s = s_bsdipa_io_write_xz(&d, &a_core_diff__write, pref, a_try_oneshot, iocp);
#endif
	else /*if(what == s_BSDIPA_IO_RAW)*/{
		s_bsdipa_off_t x;

		x = sizeof(d.dc_header) + d.dc_ctrl_len + d.dc_diff_len + d.dc_extra_len +1;
		SvGROW(pref, x);
		SvCUR_set(pref, 0);
		s = s_bsdipa_io_write_raw(&d, &a_core_diff__write, pref, a_try_oneshot, iocp);
	}

jdone:
	s_bsdipa_diff_free(&d);

jleave:
	if(s != s_BSDIPA_OK && pref != NULL)
		sv_setsv(pref, &PL_sv_undef);

	return newSViv(s);
}

static enum s_bsdipa_state
a_core_diff__write(void *user_cookie, uint8_t const *dat, s_bsdipa_off_t len, s_bsdipa_off_t is_last){
	SV *p;
	enum s_bsdipa_state rv;

	if(is_last >= 0 && len <= 0)
		goto jok;

	p = (SV*)user_cookie;

	/* Buffer takeover?  Even though likely short living, minimize wastage to XXX something reasonable */
	if(is_last < 0 && (is_last > -65535 || is_last / 10 > -len)){
		/* In this case the additional byte is guaranteed! */
		((uint8_t*)dat)[(unsigned long)len] = '\0';
		sv_usepvn_flags(p, (char*)dat, len, SV_SMAGIC | SV_HAS_TRAILING_NUL);
		assert(SvPVbyte_nolen(p)[SvCUR(p)] == '\0');
		/*xxx instead sv_setpvn(p, dat, len);*/
	}else{
		char *cp;
		s_bsdipa_off_t l;

		l = (s_bsdipa_off_t)SvCUR(p);

		cp = SvGROW(p, l + len +1);
		if(cp == NULL){
			rv = s_BSDIPA_NOMEM;
			goto jleave;
		}

		memcpy(&cp[(unsigned long)l], dat, len);
		l += len;
		cp[(unsigned long)l] = '\0'; /* mumble */
		SvCUR_set(p, l);
		SvPOK_only(p);
		SvSETMAGIC(p);
		assert(SvPVbyte_nolen(p)[SvCUR(p)] == '\0');

		if(is_last < 0)
			a_free((void*)dat);
	}

jok:
	rv = s_BSDIPA_OK;
jleave:
	return rv;
}

static SV *
a_core_patch(int what, SV *after_sv, SV *patch_sv, SV *before_sv, SV *max_allowed_restored_len, SV *io_cookie){
	struct s_bsdipa_patch_ctx p;
	struct s_bsdipa_io_cookie *iocp;
	SV *bref;
	enum s_bsdipa_state s;

	s = s_BSDIPA_INVAL;

	bref = NULL;
	if(/*!SvOK(before_sv) ||*/ !SvROK(before_sv))
		goto jleave;
	bref = SvRV(before_sv);

	if(/*!SvOK(after_sv) ||*/ !SvPOK(after_sv))
		goto jleave;

	if(/*!SvOK(patch_sv) ||*/ !SvPOK(patch_sv))
		goto jleave;

	p.pc_max_allowed_restored_len = 0;
	if(max_allowed_restored_len != NULL && SvOK(max_allowed_restored_len)){
		if(!SvIOK(max_allowed_restored_len))
			goto jleave;
		else{
			IV i;

			i = SvIV(max_allowed_restored_len);
			if(i < 0 || (uint64_t)i != (s_bsdipa_off_t)i ||
					(s_bsdipa_off_t)i >= s_BSDIPA_OFF_MAX)
				goto jleave;
			p.pc_max_allowed_restored_len = (uint64_t)i;
		}
	}

	if(io_cookie == NULL || !SvIOK(io_cookie))
		iocp = NULL;
	else
		iocp = INT2PTR(struct s_bsdipa_io_cookie*,SvIV(io_cookie));

	p.pc_mem.mc_alloc = &a_alloc;
	p.pc_mem.mc_free = &a_free;
	p.pc_after_len = SvCUR(after_sv);
	p.pc_after_dat = SvPVbyte_nolen(after_sv);

	p.pc_patch_len = SvCUR(patch_sv);
	p.pc_patch_dat = SvPVbyte_nolen(patch_sv);

	if(what == s_BSDIPA_IO_ZLIB)
		s = s_bsdipa_io_read_zlib(&p, iocp);
#if s__BSDIPA_XZ
	else if(what == s_BSDIPA_IO_XZ)
		s = s_bsdipa_io_read_xz(&p, iocp);
#endif
	else /*if(what == s_BSDIPA_IO_RAW)*/
		s = s_bsdipa_io_read_raw(&p, iocp);
	if(s != s_BSDIPA_OK)
		goto jleave;

	p.pc_patch_dat = p.pc_restored_dat;
	p.pc_patch_len = p.pc_restored_len;

	s = s_bsdipa_patch(&p);

	a_free((void*)p.pc_patch_dat);

	if(s != s_BSDIPA_OK)
		goto jdone;

	/* Hand buffer over to perl */
	p.pc_restored_dat[(size_t)p.pc_restored_len] = '\0';
	SvPVCLEAR(bref); /* xxx needless? */
	sv_usepvn_flags(bref, (char*)p.pc_restored_dat, p.pc_restored_len, SV_SMAGIC | SV_HAS_TRAILING_NUL);
	assert(SvPVbyte_nolen(bref)[SvCUR(bref)] == '\0');
	p.pc_restored_dat = NULL;

jdone:
	s_bsdipa_patch_free(&p);

jleave:
	if(s != s_BSDIPA_OK && bref != NULL)
		sv_setsv(bref, &PL_sv_undef);

	return newSViv(s);
}

MODULE = BsDiPa PACKAGE = BsDiPa
VERSIONCHECK: DISABLE
PROTOTYPES: ENABLE

void
_try_oneshot_set(nval)
	SV *nval
CODE:
	if(SvIOK(nval))
		a_try_oneshot = SvIV(nval);

SV *
VERSION()
CODE:
	RETVAL = newSVpv(s_BSDIPA_VERSION, sizeof(s_BSDIPA_VERSION) -1);
OUTPUT:
	RETVAL

SV *
CONTACT()
CODE:
	RETVAL = newSVpv(s_BSDIPA_CONTACT, sizeof(s_BSDIPA_CONTACT) -1);
OUTPUT:
	RETVAL

SV *
COPYRIGHT()
CODE:
	RETVAL = newSVpv(s_BSDIPA_COPYRIGHT, sizeof(s_BSDIPA_COPYRIGHT) -1);
OUTPUT:
	RETVAL

SV *
HAVE_XZ()
CODE:
	RETVAL = newSViv(a_have_xz);
OUTPUT:
	RETVAL

SV *
OK()
CODE:
	RETVAL = newSViv(s_BSDIPA_OK);
OUTPUT:
	RETVAL

SV *
FBIG()
CODE:
	RETVAL = newSViv(s_BSDIPA_FBIG);
OUTPUT:
	RETVAL

SV *
NOMEM()
CODE:
	RETVAL = newSViv(s_BSDIPA_NOMEM);
OUTPUT:
	RETVAL

SV *
INVAL()
CODE:
	RETVAL = newSViv(s_BSDIPA_INVAL);
OUTPUT:
	RETVAL

SV *
core_diff_raw(before_sv, after_sv, patch_sv, magic_window=NULL, is_equal_data=NULL, io_cookie=NULL)
	SV *before_sv
	SV *after_sv
	SV *patch_sv
	SV *magic_window
	SV *is_equal_data
	SV *io_cookie
CODE:
	RETVAL = a_core_diff(s_BSDIPA_IO_RAW, before_sv, after_sv, patch_sv, magic_window, is_equal_data, io_cookie);
OUTPUT:
	RETVAL

SV *
core_diff_zlib(before_sv, after_sv, patch_sv, magic_window=NULL, is_equal_data=NULL, io_cookie=NULL)
	SV *before_sv
	SV *after_sv
	SV *patch_sv
	SV *magic_window
	SV *is_equal_data
	SV *io_cookie
CODE:
	RETVAL = a_core_diff(s_BSDIPA_IO_ZLIB, before_sv, after_sv, patch_sv, magic_window, is_equal_data, io_cookie);
OUTPUT:
	RETVAL

#if s__BSDIPA_XZ
SV *
core_diff_xz(before_sv, after_sv, patch_sv, magic_window=NULL, is_equal_data=NULL, io_cookie=NULL)
	SV *before_sv
	SV *after_sv
	SV *patch_sv
	SV *magic_window
	SV *is_equal_data
	SV *io_cookie
CODE:
	RETVAL = a_core_diff(s_BSDIPA_IO_XZ, before_sv, after_sv, patch_sv, magic_window, is_equal_data, io_cookie);
OUTPUT:
	RETVAL
#endif

SV *
core_patch_raw(after_sv, patch_sv, before_sv, max_allowed_restored_len=NULL, io_cookie=NULL)
	SV *after_sv
	SV *patch_sv
	SV *before_sv
	SV *max_allowed_restored_len
	SV *io_cookie
CODE:
	RETVAL = a_core_patch(s_BSDIPA_IO_RAW, after_sv, patch_sv, before_sv, max_allowed_restored_len, io_cookie);
OUTPUT:
	RETVAL

SV *
core_patch_zlib(after_sv, patch_sv, before_sv, max_allowed_restored_len=NULL, io_cookie=NULL)
	SV *after_sv
	SV *patch_sv
	SV *before_sv
	SV *max_allowed_restored_len
	SV *io_cookie
CODE:
	RETVAL = a_core_patch(s_BSDIPA_IO_ZLIB, after_sv, patch_sv, before_sv, max_allowed_restored_len, io_cookie);
OUTPUT:
	RETVAL

#if s__BSDIPA_XZ
SV *
core_patch_xz(after_sv, patch_sv, before_sv, max_allowed_restored_len=NULL, io_cookie=NULL)
	SV *after_sv
	SV *patch_sv
	SV *before_sv
	SV *max_allowed_restored_len
	SV *io_cookie
CODE:
	RETVAL = a_core_patch(s_BSDIPA_IO_XZ, after_sv, patch_sv, before_sv, max_allowed_restored_len, io_cookie);
OUTPUT:
	RETVAL
#endif

#if s__BSDIPA_XZ
SV *
core_io_cookie_new_xz(level=NULL)
	SV *level
CODE:
	struct s_bsdipa_io_cookie_xz *iocxp;
	IV lvl;

	lvl = (level != NULL && SvIOK(level)) ? SvIV(level) : 0;

	iocxp = (struct s_bsdipa_io_cookie_xz*)a_alloc(sizeof(*iocxp));
	memset(iocxp, 0, sizeof(*iocxp));
	iocxp->iocx_super.ioc_type = s_BSDIPA_IO_XZ;
	iocxp->iocx_super.ioc_level = lvl;
	RETVAL = newSViv(PTR2IV(iocxp));
OUTPUT:
	RETVAL
#endif

void
core_io_cookie_gut(io_cookie)
	SV *io_cookie
CODE:
	if(io_cookie != NULL && SvIOK(io_cookie)){
		union a_io_cookie ioc;

		ioc.ioc_vp = INT2PTR(void*,SvIV(io_cookie));

		if(ioc.ioc_vp != NULL){
#if s__BSDIPA_XZ
			if(ioc.ioc_iocp->ioc_type == s_BSDIPA_IO_XZ)
				s_bsdipa_io_cookie_gut_xz(ioc.ioc_iocp);
#endif
			a_free(ioc.ioc_vp);
		}
	}
