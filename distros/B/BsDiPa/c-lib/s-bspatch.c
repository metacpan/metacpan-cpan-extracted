/*@ Implementation of s-bsdipa-lib.h: s_bsdipa_patch() and support.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2024 - 2025 Steffen Nurpmeso <steffen@sdaoden.eu>.
 * (Only technical surroundings, algorithm is solely Colin Percival.)
 *
 * Copyright 2003-2005 Colin Percival
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted providing that the following conditions 
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "s-bsdipa-lib.h"

#include <string.h>

/* Compile-time state assertions to also ensure the below is correct are in s-bsdiff.c! */

/* (Could be shared with s-bsdiff.c) */
static void *a_bspatch_alloc(void *vp, size_t size);
static void a_bspatch_free(void *vp, void *dat);

static inline s_bsdipa_off_t a_bspatch_xin(uint8_t const *buf);
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
	y = y * 256; y += buf[1];
	y = y * 256; y += buf[2];
	y = y * 256; y += buf[3];
#ifndef s_BSDIPA_32
	y = y * 256; y += buf[4];
	y = y * 256; y += buf[5];
	y = y * 256; y += buf[6];
	y = y * 256; y += buf[7];
#endif
	if(buf[0] & 0x80)
		y = -y;

	return y;
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
	/* If we generated the header, the latter is true. */
	if(x >= s_BSDIPA_OFF_MAX || (uint64_t)x >= SIZE_MAX / sizeof(s_bsdipa_off_t))
		goto jleave;
	if(x - hp->h_extra_len != hp->h_diff_len)
		goto jleave;
	hp->h_before_len = x;

	rv = s_BSDIPA_OK;
jleave:
	return rv;
}

enum s_bsdipa_state
s_bsdipa_patch(struct s_bsdipa_patch_ctx *pcp){
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
		x -= respos;
		pcp->pc_diff_dat += respos;

		respos = pcp->pc_header.h_diff_len;
		if(respos < 0 || x < (uint64_t)respos)
			goto jleave;
		x -= respos;
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

	if(pcp->pc_header.h_before_len < 0 || pcp->pc_header.h_before_len >= s_BSDIPA_OFF_MAX)
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

	for(aftpos = respos = 0; respos < pcp->pc_header.h_before_len;){
		s_bsdipa_off_t i, j;

		if(pcp->pc_header.h_ctrl_len < (s_bsdipa_off_t)sizeof(s_bsdipa_off_t) * 3)
			goto jleave;
		pcp->pc_header.h_ctrl_len -= (s_bsdipa_off_t)sizeof(s_bsdipa_off_t) * 3;

		for(i = 0; i < 3; ++i){
			ctrl[i] = a_bspatch_xin(pcp->pc_ctrl_dat);
			pcp->pc_ctrl_dat += sizeof(s_bsdipa_off_t);
		}

		if(ctrl[0] < 0 || ctrl[0] >= s_BSDIPA_OFF_MAX)
			goto jleave;
		if(ctrl[1] < 0 || ctrl[1] >= s_BSDIPA_OFF_MAX)
			goto jleave;

		/* Add in diff */
		j = ctrl[0];
		if(j != 0){
			if(pcp->pc_header.h_diff_len < j)
				goto jleave;
			pcp->pc_header.h_diff_len -= j;

			if(!a_bspatch_check_add(respos, j) || respos + j > pcp->pc_header.h_before_len)
				goto jleave;
			if(!a_bspatch_check_add(aftpos, j))
				goto jleave;

			for(i = j; i--;)
				pcp->pc_restored_dat[respos++] = *--pcp->pc_diff_dat;
			respos -= j;

			for(i = 0; i < j; ++i)
				if(a_bspatch_check_add(aftpos, i) && aftpos + i < (s_bsdipa_off_t)pcp->pc_after_len)
					pcp->pc_restored_dat[respos + i] += pcp->pc_after_dat[aftpos + i];

			respos += j;
			aftpos += j;
		}

		/* Extra dat */
		j = ctrl[1];
		if(j != 0){
			if(pcp->pc_header.h_extra_len < j)
				goto jleave;
			pcp->pc_header.h_extra_len -= j;

			if(!a_bspatch_check_add(respos, j) || respos + j > pcp->pc_header.h_before_len)
				goto jleave;

			memcpy(&pcp->pc_restored_dat[respos], pcp->pc_extra_dat, j);
			pcp->pc_extra_dat += j;

			respos += j;
		}

		/* */
		j = ctrl[2];
		if(!a_bspatch_check_add(aftpos, j))
			goto jleave;
		aftpos += j;
		if(aftpos < 0)
			goto jleave;
	}

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
