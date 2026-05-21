/*@ Implementation of s-bsdipa-lib.h: s_bsdipa_patch() and support.
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

#include "s-bsdipa-lib.h"

#include <string.h>

/* Compile-time state assertions to also ensure the below is correct are in s-bsdiff.c! */

/* (Could be shared with s-bsdiff.c) */
static void *a_bspatch_alloc(void *vp, size_t size);
static void a_bspatch_free(void *vp, void *dat);

static inline s_bsdipa_off_t a_bspatch_xin(uint8_t const *buf);
static inline int a_bspatch_check_add_positive(s_bsdipa_off_t a, s_bsdipa_off_t b);
static inline int a_bspatch_check_add(s_bsdipa_off_t a, s_bsdipa_off_t b);

static void *
a_bspatch_alloc(void *vp, size_t size){
	struct s_bsdipa_patch_ctx *pcp;

	pcp = (struct s_bsdipa_patch_ctx*)vp;
	vp = (*pcp->pc_mem.mc_alloc)(size);

	return vp;
}

static void
a_bspatch_free(void *vp, void *dat){
	struct s_bsdipa_patch_ctx *pcp;

	pcp = (struct s_bsdipa_patch_ctx*)vp;
	(*pcp->pc_mem.mc_free)(dat);
}

static inline s_bsdipa_off_t
a_bspatch_xin(uint8_t const *buf){
	s_bsdipa_off_t y;

	y = buf[0] & 0x7F;
	y <<= 8; y += buf[1];
	y <<= 8; y += buf[2];
	y <<= 8; y += buf[3];
#ifndef s_BSDIPA_32
	y <<= 8; y += buf[4];
	y <<= 8; y += buf[5];
	y <<= 8; y += buf[6];
	y <<= 8; y += buf[7];
#endif
	if(buf[0] & 0x80)
		y = -y;

	return y;
}

static inline int
a_bspatch_check_add_positive(s_bsdipa_off_t a, s_bsdipa_off_t b){
	int rv;

	rv = (a < s_BSDIPA_OFF_MAX - b);

	return rv;
}

static inline int
a_bspatch_check_add(s_bsdipa_off_t a, s_bsdipa_off_t b){
	int rv;

	rv = 1;
	if(b >= 0){
		if(a >= s_BSDIPA_OFF_MAX - b)
			rv = 0;
	}else if(a < s_BSDIPA_OFF_MIN - b)
		rv = 0;

	return rv;
}

s_bsdipa_off_t
s_bsdipa_buf_to_i(uint8_t const *in){
	return a_bspatch_xin(in);
}

enum s_bsdipa_state
s_bsdipa_patch_parse_header(struct s_bsdipa_header *hp, uint8_t const *dat){
	s_bsdipa_off_t x, y;
	enum s_bsdipa_state rv;

	rv = s_BSDIPA_INVAL;

	x = a_bspatch_xin(dat);
	if(x < 0)
		goto jleave;
	if(x & (sizeof(s_bsdipa_off_t) - 1))
		goto jleave;
	if(x % (sizeof(s_bsdipa_off_t) * 3))
		goto jleave;
	y = x; /* If we generated the header, data *plus* control block fits in _OFF_MAX! */
	hp->h_ctrl_len = x;
	dat += sizeof(x);

	x = a_bspatch_xin(dat);
	if(x < 0)
		goto jleave;
	if(s_BSDIPA_OFF_MAX - y <= x)
		goto jleave;
	y += x;
	hp->h_diff_len = x;
	dat += sizeof(x);

	x = a_bspatch_xin(dat);
	if(x < 0)
		goto jleave;
	if(s_BSDIPA_OFF_MAX - y <= x)
		goto jleave;
	hp->h_extra_len = x;
	dat += sizeof(x);

	x = a_bspatch_xin(dat);
	if(x < 0)
		goto jleave;
	if(x == 0){
		if(hp->h_ctrl_len != 0 || hp->h_diff_len != 0 || hp->h_extra_len != 0)
			goto jleave;
	}else{
		if(x >= s_BSDIPA_OFF_MAX || (uint64_t)x >= SIZE_MAX / sizeof(s_bsdipa_off_t))
			goto jleave;
		if(x - hp->h_extra_len != hp->h_diff_len)
			goto jleave;

		/* Since v0.9.0 bsdipa generates patches testable like so */
		if(x + 1 < hp->h_ctrl_len / ((s_bsdipa_off_t)sizeof(s_bsdipa_off_t) * 3))
			goto jleave;
	}
	hp->h_before_len = x;

	rv = s_BSDIPA_OK;
jleave:
	return rv;
}

enum s_bsdipa_state
s_bsdipa_patch(struct s_bsdipa_patch_ctx *pcp){
	uint8_t any_tick;
	s_bsdipa_off_t aftpos, respos, ctrl[3];
	enum s_bsdipa_state rv;

	if(pcp->pc_mem.mc_alloc != NULL){
		pcp->pc_mem.mc_custom_cookie = pcp;
		pcp->pc_mem.mc_custom_alloc = &a_bspatch_alloc;
		pcp->pc_mem.mc_custom_free = &a_bspatch_free;
	}

	/* Enable s_bsdipa_patch_free() */
	pcp->pc_restored_dat = NULL;
	pcp->pc_restored_len = 0;

	rv = s_BSDIPA_INVAL;

	if(pcp->pc_patch_dat != NULL){
		uint64_t x;

		pcp->pc_diff_dat = pcp->pc_ctrl_dat = pcp->pc_patch_dat;

		x = pcp->pc_patch_len;

		respos = pcp->pc_header.h_ctrl_len;
		if(respos < 0 || x < (uint64_t)respos)
			goto jleave;
		x -= (uint64_t)respos;
		pcp->pc_diff_dat += respos;

		respos = pcp->pc_header.h_diff_len;
		if(respos < 0 || x < (uint64_t)respos)
			goto jleave;
		x -= (uint64_t)respos;
		pcp->pc_diff_dat += respos;

		pcp->pc_extra_dat = pcp->pc_diff_dat;
		respos = pcp->pc_header.h_extra_len;
		if(respos < 0 || x < (uint64_t)respos)
			goto jleave;
		/* xxx Do not care about excess data in patch? */
	}else{
		respos = pcp->pc_header.h_ctrl_len;
		if(respos < 0 || respos >= s_BSDIPA_OFF_MAX)
			goto jleave;
		respos = pcp->pc_header.h_diff_len;
		if(respos < 0 || respos >= s_BSDIPA_OFF_MAX)
			goto jleave;
		aftpos = pcp->pc_header.h_extra_len;
		if(aftpos < 0 || aftpos >= s_BSDIPA_OFF_MAX)
			goto jleave;
		if(s_BSDIPA_OFF_MAX - aftpos <= respos)
			goto jleave;
		respos += aftpos;
		if(s_BSDIPA_OFF_MAX - respos <= pcp->pc_header.h_ctrl_len)
			goto jleave;
	}

	/* The effective limit is smaller, but that is up to diff generation: "just do it" */
	if(pcp->pc_after_len >= s_BSDIPA_OFF_MAX)
		goto jleave;

	if((respos = pcp->pc_header.h_before_len) == 0){
		if(pcp->pc_header.h_ctrl_len != 0 || pcp->pc_header.h_diff_len != 0 || pcp->pc_header.h_extra_len != 0)
			goto jleave;
	}else if(respos < 0 || respos >= s_BSDIPA_OFF_MAX)
		goto jleave;
	else if(respos - pcp->pc_header.h_extra_len != pcp->pc_header.h_diff_len)
		goto jleave;

	rv = s_BSDIPA_FBIG;

	/* 32-bit size_t excess? */
	if((uint64_t)pcp->pc_header.h_before_len >= SIZE_MAX - 1)
		goto jleave;

	if(pcp->pc_max_allowed_restored_len != 0 &&
			pcp->pc_max_allowed_restored_len < (uint64_t)pcp->pc_header.h_before_len)
		goto jleave;
	pcp->pc_restored_len = pcp->pc_header.h_before_len;

	/* Ensure room for one additional byte, as documented. */
	pcp->pc_restored_dat = (uint8_t*)(*pcp->pc_mem.mc_custom_alloc)(pcp->pc_mem.mc_custom_cookie,
			(size_t)pcp->pc_restored_len +1);
	if(pcp->pc_restored_dat == NULL){
		rv = s_BSDIPA_NOMEM;
		goto jleave;
	}

	rv = s_BSDIPA_INVAL;

	for(any_tick = 0, aftpos = respos = 0; respos < pcp->pc_header.h_before_len; any_tick = 1){
		s_bsdipa_off_t i, j, k;

		if(pcp->pc_header.h_ctrl_len < (s_bsdipa_off_t)sizeof(s_bsdipa_off_t) * 3)
			goto jleave;
		pcp->pc_header.h_ctrl_len -= (s_bsdipa_off_t)sizeof(s_bsdipa_off_t) * 3;

		for(i = 0; i < 3; ++i){
			ctrl[i] = a_bspatch_xin(pcp->pc_ctrl_dat);
			pcp->pc_ctrl_dat += sizeof(s_bsdipa_off_t);
		}

		if((k = ctrl[1]) < 0 || k >= s_BSDIPA_OFF_MAX)
			goto jleave;
		if((j = ctrl[0]) < 0 || j >= s_BSDIPA_OFF_MAX)
			goto jleave;

		/* A data-less control (but the first) is "malicious" */
		if(any_tick && k == 0 && j == 0)
			goto jleave;

		/* Add in diff */
		/*j = ctrl[0];*/
		if(j != 0){
			if(pcp->pc_header.h_diff_len < j)
				goto jleave;
			pcp->pc_header.h_diff_len -= j;

			if(!a_bspatch_check_add_positive(respos, j) || respos + j > pcp->pc_header.h_before_len)
				goto jleave;
			if(!a_bspatch_check_add_positive(aftpos, j) || aftpos + j > (s_bsdipa_off_t)pcp->pc_after_len)
				goto jleave;

			while(j-- != 0)
				pcp->pc_restored_dat[respos++] = *--pcp->pc_diff_dat + pcp->pc_after_dat[aftpos++];
		}

		/* Extra dat */
		j = ctrl[1];
		if(j != 0){
			if(pcp->pc_header.h_extra_len < j)
				goto jleave;
			pcp->pc_header.h_extra_len -= j;

			if(!a_bspatch_check_add_positive(respos, j) || respos + j > pcp->pc_header.h_before_len)
				goto jleave;

			memcpy(&pcp->pc_restored_dat[respos], pcp->pc_extra_dat, (size_t)j);
			pcp->pc_extra_dat += j;

			respos += j;
		}

		/**/
		j = ctrl[2];
		if(j != 0){
			if(!a_bspatch_check_add(aftpos, j))
				goto jleave;
			aftpos += j;
			if(aftpos < 0)
				goto jleave;
		}
	}

	if(pcp->pc_header.h_ctrl_len == 0)
		rv = s_BSDIPA_OK;

jleave:
	return rv;
}

void
s_bsdipa_patch_free(struct s_bsdipa_patch_ctx *pcp){
	if(pcp->pc_restored_dat != NULL)
		(*pcp->pc_mem.mc_custom_free)(pcp->pc_mem.mc_custom_cookie, pcp->pc_restored_dat);
}

/* s-itt-mode */
