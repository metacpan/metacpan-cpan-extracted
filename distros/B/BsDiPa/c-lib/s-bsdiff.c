/*@ Implementation of s-bsdipa-lib.h: s_bsdipa_diff() and support.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2024 - 2026 Steffen Nurpmeso <steffen@sdaoden.eu>.
 * (Technical surroundings, bsdiff algorithm is solely Colin Percival.)
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

#include <assert.h>
#include <stdint.h>
#include <string.h>

#ifndef s_BSDIPA_SMALL
# define DIVSUFSORT_API static
# include "libdivsufsort/divsufsort.h"
#endif

/* Number of control block instances per s_bsdipa_ctrl_chunk */
#define a_BSDIPA_CTRL_NO 41

/* What seems a good default */
#ifndef s_BSDIPA_MAGIC_WINDOW
# define s_BSDIPA_MAGIC_WINDOW 16
#endif

#ifdef s_BSDIPA_SMALL
# define saidx_t s_bsdipa_off_t
#endif

/* */
#undef MIN
#define MIN(x,y) (((x) < (y)) ? (x) : (y))

/* With 32-bit off_t for now only s_BSDIPA_32 mode is supported */
#ifndef s_BSDIPA_32
# define OFF_MAX (sizeof(off_t) == 4 ? INT32_MAX : INT64_MAX)
typedef char ASSERTION_failed__off_max[OFF_MAX != INT32_MAX ? 1 : -1];
# undef OFF_MAX
#endif

/* Checks use saidx_t, but the patch code uses s_bsdipa_off_t, so these must be of EQ size! */
typedef char ASSERTION_failed__bsdipa_off_eq_saidx[sizeof(s_bsdipa_off_t) == sizeof(saidx_t) ? 1 : -1];

struct a_bsdiff_ctrl{
	struct s_bsdipa_ctrl_chunk **c_ccpp;
	struct s_bsdipa_ctrl_chunk *c_ccp;
	uint32_t c_no; /* Left entries in .c_ccp */
	int8_t c_need_dump; /* Delayed dump of ctrl_triple.ct_seek_bytes for <> .c_join_rel_pos */
	int8_t c_pad[3];
	s_bsdipa_off_t c_join_rel_pos; /* Join multiple successive data-less triples by moving once */
	s_bsdipa_off_t c_len_max; /* Maximum possible header:h_ctrl_len for input data <> BSDIFF_CTL_LEN_MAX() */
#define a_BSDIFF_CTL_LEN_MAX(BEFLEN) (s_BSDIPA_OFF_MAX - (BEFLEN) - (sizeof(s_bsdipa_off_t) * 3) - 1)
};

/* (Could be shared with s-bspatch.c) */
static void *a_bsdiff_alloc(void *vp, size_t size);
static void a_bsdiff_free(void *vp, void *dat);

/**/
static inline void a_bsdiff_xout(s_bsdipa_off_t x, uint8_t *bp);

/**/
static enum s_bsdipa_state a_bsdiff_xout_ctrl(struct s_bsdipa_diff_ctx *dcp, struct a_bsdiff_ctrl *ctrlp,
		s_bsdipa_off_t diffl, s_bsdipa_off_t extral);

/* below public fns */

/* Colin Percival's code to turn suffix-sorted data into output */
static inline s_bsdipa_off_t a_bsdiff_matchlen(uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		uint8_t const *befdat, s_bsdipa_off_t beflen);
static s_bsdipa_off_t a_bsdiff_search(s_bsdipa_off_t const *Ip, uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		uint8_t const *befdat, s_bsdipa_off_t beflenp,
		s_bsdipa_off_t st, s_bsdipa_off_t en, s_bsdipa_off_t *posp);

static enum s_bsdipa_state a_bsdiff_bsdiff(struct s_bsdipa_diff_ctx *dcp);

/* Later imported original BSDiff string suffix sort algorithm by Colin Percival.
 * (It was replaced with libdivsufsort in the FreeBSD codebase to which he pointed me due to "existing fixes",
 * because of notable performance improvements.)
 * Except for types and names i did not adapt syntax to my style for those */
static void a_bsdiff_split(s_bsdipa_off_t *I, s_bsdipa_off_t *V, s_bsdipa_off_t start, s_bsdipa_off_t len,
		s_bsdipa_off_t h);
static int a_bsdiff_qsufsort(s_bsdipa_off_t *I, uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		struct s_bsdipa_diff_ctx *dcp);

/* Even further below: simple text line-based approach to create output patch format */
#ifdef s_BSDIPA_TEXT
static enum s_bsdipa_state a_bsdiff_text(struct s_bsdipa_diff_ctx *dcp);
#endif

static void *
a_bsdiff_alloc(void *vp, size_t size){
	struct s_bsdipa_diff_ctx *dcp;

	dcp = (struct s_bsdipa_diff_ctx*)vp;
	vp = (*dcp->dc_mem.mc_alloc)(size);

	return vp;
}

static void
a_bsdiff_free(void *vp, void *dat){
	struct s_bsdipa_diff_ctx *dcp;

	dcp = (struct s_bsdipa_diff_ctx*)vp;
	(*dcp->dc_mem.mc_free)(dat);
}

static inline void
a_bsdiff_xout(s_bsdipa_off_t x, uint8_t *buf){ /* xxx use endian.h stuff */
	s_bsdipa_off_t y;
	int lt0;

	lt0 = (x < 0);
	y = lt0 ? -x : x;

#ifndef s_BSDIPA_32
	buf[7] = (uint8_t)(y & 0xFF); y >>= 8;
	buf[6] = (uint8_t)(y & 0xFF); y >>= 8;
	buf[5] = (uint8_t)(y & 0xFF); y >>= 8;
	buf[4] = (uint8_t)(y & 0xFF); y >>= 8;
#endif
	buf[3] = (uint8_t)(y & 0xFF); y >>= 8;
	buf[2] = (uint8_t)(y & 0xFF); y >>= 8;
	buf[1] = (uint8_t)(y & 0xFF); y >>= 8;
	buf[0] = (uint8_t)(y /*& 0xFF*/);
	if(lt0)
		buf[0] |= 0x80;
}

static enum s_bsdipa_state
a_bsdiff_xout_ctrl(struct s_bsdipa_diff_ctx *dcp, struct a_bsdiff_ctrl *ctrlp, s_bsdipa_off_t diffl, /* {{{ */
		s_bsdipa_off_t extral){
	enum s_bsdipa_state rv;
	struct s_bsdipa_ctrl_chunk *ccp;

	ccp = ctrlp->c_ccp;

	if(ctrlp->c_need_dump){
		a_bsdiff_xout(ctrlp->c_join_rel_pos, &ccp->cc_dat[ccp->cc_len]);
		ccp->cc_len += sizeof(s_bsdipa_off_t);
		ctrlp->c_join_rel_pos = 0;
	}

	if(ctrlp->c_ccpp == NULL || --ctrlp->c_no == 0){
		/* xxx Do not: sizeof(struct s_bsdipa_ctrl_triple) * a_BSDIPA_CTRL_NO */
		ccp = (struct s_bsdipa_ctrl_chunk*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie,
				 (sizeof(struct s_bsdipa_ctrl_chunk) +
					(3 * sizeof(s_bsdipa_off_t) * a_BSDIPA_CTRL_NO)));
		if(ccp == NULL){
			rv = s_BSDIPA_NOMEM;
			goto jleave;
		}

		if(ctrlp->c_ccpp == NULL)
			dcp->dc_ctrl = ccp;
		else
			*ctrlp->c_ccpp = ccp;
		ccp->cc_next = NULL;
		ccp->cc_len = 0;

		ctrlp->c_ccp = ccp;
		ctrlp->c_ccpp = &ccp->cc_next;
		ctrlp->c_no = a_BSDIPA_CTRL_NO;
	}

	a_bsdiff_xout(diffl, &ccp->cc_dat[ccp->cc_len]);
		ccp->cc_len += sizeof(s_bsdipa_off_t);
	a_bsdiff_xout(extral, &ccp->cc_dat[ccp->cc_len]);
		ccp->cc_len += sizeof(s_bsdipa_off_t);

	dcp->dc_ctrl_len += sizeof(s_bsdipa_off_t) * 3;
	if(dcp->dc_ctrl_len > ctrlp->c_len_max){
		rv = s_BSDIPA_FBIG;
		goto jleave;
	}

	ctrlp->c_need_dump = 1;
	rv = s_BSDIPA_OK;
jleave:
	return rv;
} /* }}} */

void
s_bsdipa_i_to_buf(uint8_t *out, s_bsdipa_off_t in){
	a_bsdiff_xout(in, out);
}

enum s_bsdipa_state
s_bsdipa_diff(struct s_bsdipa_diff_ctx *dcp){ /* {{{ */
	enum s_bsdipa_state rv;

	if(dcp->dc_mem.mc_alloc != NULL){
		dcp->dc_mem.mc_custom_cookie = dcp;
		dcp->dc_mem.mc_custom_alloc = &a_bsdiff_alloc;
		dcp->dc_mem.mc_custom_free = &a_bsdiff_free;
	}

	if(
#ifdef s_BSDIPA_TEXT
			!dcp->dc_text_mode &&
#endif
			dcp->dc_magic_window <= 0)
		dcp->dc_magic_window = s_BSDIPA_MAGIC_WINDOW;

	/* Enable s_bsdipa_diff_free() */
	memset(&dcp->dc_ctrl_len, 0, sizeof(*dcp) - (size_t)((uint8_t*)&dcp->dc_ctrl_len - (uint8_t*)dcp));

	rv = s_BSDIPA_FBIG;

	/* Fail early if we cannot create a patch with a header and one control triple */
	if(dcp->dc_before_len >= s_BSDIPA_OFF_MAX -sizeof(struct s_bsdipa_header) -sizeof(struct s_bsdipa_ctrl_triple))
		goto jleave;
	if(dcp->dc_before_len + 1 >= SIZE_MAX / sizeof(saidx_t))
		goto jleave;

	if(dcp->dc_after_len >= s_BSDIPA_OFF_MAX)
		goto jleave;
	if(dcp->dc_after_len + 1 >= SIZE_MAX / sizeof(saidx_t))
		goto jleave;

	rv = s_BSDIPA_NOMEM;

	dcp->dc_extra_dat = (uint8_t*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie,
				(size_t)(dcp->dc_before_len + 1));
	if(dcp->dc_extra_dat == NULL)
		goto jleave;
	/* Let's share that buffer */
	dcp->dc_diff_dat = &dcp->dc_extra_dat[(size_t)(dcp->dc_before_len + 1)];

	/* Compute the differences, writing ctrl as we go */
	if((dcp->dc_after_len | dcp->dc_before_len) == 0){
		dcp->dc_is_equal_data = 1;
		rv = s_BSDIPA_OK;
	}else if(dcp->dc_before_len == 0){
		dcp->dc_is_equal_data = 0;
		rv = s_BSDIPA_OK;
	}
#ifdef s_BSDIPA_TEXT
	else if(dcp->dc_text_mode)
		rv = a_bsdiff_text(dcp);
#endif
	else
		rv = a_bsdiff_bsdiff(dcp);

	if(rv == s_BSDIPA_OK){
		/* Create readily prepared header; as documented, sum of lengths does not exceed _OFF_MAX */
		a_bsdiff_xout(dcp->dc_ctrl_len, &dcp->dc_header[0]);
		a_bsdiff_xout(dcp->dc_diff_len, &dcp->dc_header[sizeof(s_bsdipa_off_t)]);
		a_bsdiff_xout(dcp->dc_extra_len, &dcp->dc_header[sizeof(s_bsdipa_off_t) * 2]);
		a_bsdiff_xout(dcp->dc_before_len, &dcp->dc_header[sizeof(s_bsdipa_off_t) * 3]);
	}

jleave:
	return rv;
} /* }}} */

void
s_bsdipa_diff_free(struct s_bsdipa_diff_ctx *dcp){
	struct s_bsdipa_ctrl_chunk *ccp;

	while((ccp = dcp->dc_ctrl) != NULL){
		dcp->dc_ctrl = ccp->cc_next;
		(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, ccp);
	}

	if(dcp->dc_extra_dat != NULL)
		(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, dcp->dc_extra_dat);
}

/*
 * Percivals BSDiff {{{
 */
static inline s_bsdipa_off_t
a_bsdiff_matchlen(uint8_t const *aftdat, s_bsdipa_off_t aftlen, uint8_t const *befdat, s_bsdipa_off_t beflen){
	s_bsdipa_off_t i;

	aftlen = MIN(aftlen, beflen);
	for(i = 0; i < aftlen; ++i)
		if(aftdat[i] != befdat[i])
			break;

	return i;
}

static s_bsdipa_off_t
a_bsdiff_search(s_bsdipa_off_t const *Ip, uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		uint8_t const *befdat, s_bsdipa_off_t beflen,
		s_bsdipa_off_t st, s_bsdipa_off_t en, s_bsdipa_off_t *posp){
	s_bsdipa_off_t x, y, r;

	if(en - st < 2){
		x = a_bsdiff_matchlen(aftdat + Ip[st], aftlen - Ip[st], befdat, beflen);
		y = a_bsdiff_matchlen(aftdat + Ip[en], aftlen - Ip[en], befdat, beflen);

		if(x > y){
			*posp = Ip[st];
			r = x;
		}else{
			*posp = Ip[en];
			r = y;
		}
	}else{
		x = st + ((en - st) / 2);
		y = aftlen - Ip[x];
		y = MIN(y, beflen);
		if(memcmp(aftdat + Ip[x], befdat, (size_t)y) < 0)
			r = a_bsdiff_search(Ip, aftdat, aftlen, befdat, beflen, x, en, posp);
		else
			r = a_bsdiff_search(Ip, aftdat, aftlen, befdat, beflen, st, x, posp);
	}

	return r;
}

static enum s_bsdipa_state
a_bsdiff_bsdiff(struct s_bsdipa_diff_ctx *dcp){ /* {{{ */
	struct a_bsdiff_ctrl ctrl;
	int maxoffdecr, isneq;
	saidx_t *Ip;
	uint8_t *extrap, *diffp;
	uint8_t const *befdat, *aftdat;
	s_bsdipa_off_t beflen, aftlen, scan, len, pos, lastscan, aftpos, lastoff, aftscore, i;
	enum s_bsdipa_state rv;
	assert(dcp->dc_before_len > 0);

	memset(&ctrl, 0, sizeof(ctrl));

	rv = s_BSDIPA_NOMEM;

	beflen = (s_bsdipa_off_t)dcp->dc_before_len;
	befdat = dcp->dc_before_dat;
	aftlen = (s_bsdipa_off_t)dcp->dc_after_len;
	aftdat = dcp->dc_after_dat;
	extrap = dcp->dc_extra_dat;
	diffp = dcp->dc_diff_dat;

	Ip = (saidx_t*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie,
			(size_t)(aftlen + 1) * sizeof(saidx_t));
	if(Ip == NULL)
		goto jleave;

	maxoffdecr = 0;
#ifndef s_BSDIPA_SMALL
	/* Limit is "a bit arbitrary", and surely also depends on memory cache performance etc */
	if(aftlen > 4096 * 25){
		/* divsufsort(): effectively only ENOMEM */
		if(divsufsort(aftdat, Ip, aftlen, dcp))
			goto jleave;
		maxoffdecr = 1;
	}else
#endif
		/* Only ENOMEM */
		if(a_bsdiff_qsufsort(Ip, aftdat, aftlen, dcp))
			goto jleave;

	ctrl.c_len_max = a_BSDIFF_CTL_LEN_MAX(beflen);

	isneq = (aftlen != beflen);
	scan = len = pos = lastscan = aftpos = lastoff = 0;

	/* a_bsdiff_search() is called with aftlen - 1, so bypass algorithm as such, then */
	if(aftlen == 0)
		goto Jaftlen0_bypass;

	while(scan < beflen){
		aftscore = 0;

		for(i = (scan += len); scan < beflen; ++scan){
			len = a_bsdiff_search(Ip, aftdat, aftlen, befdat + scan, beflen - scan, 0,
					aftlen - maxoffdecr, &pos);

			for(; i < scan + len; ++i)
				if(i + lastoff < aftlen && aftdat[i + lastoff] == befdat[i])
					++aftscore;

			if((len == aftscore && len != 0) || len > aftscore + dcp->dc_magic_window)
				break;

			if(scan + lastoff < aftlen && aftdat[scan + lastoff] == befdat[scan])
				--aftscore;
		}

		if(len != aftscore || scan == beflen) Jaftlen0_bypass:{
			s_bsdipa_off_t s, Sf, diffl, lenb, extral;

			if(aftlen == 0){
				diffl = lenb = 0;
				extral = scan = beflen;
				goto j_aftlen0_bypass;
			}

			s = Sf = diffl = 0;

			for(i = 0; lastscan + i < scan && aftpos + i < aftlen;){
				if(aftdat[aftpos + i] == befdat[lastscan + i])
					++s;
				++i;
				if((s * 2) - i > (Sf * 2) - diffl){
					Sf = s;
					diffl = i;
				}
			}

			lenb = 0;
			if(scan < beflen){
				s_bsdipa_off_t Sb;

				s = Sb = 0;
				for(i = 1; scan >= lastscan + i && pos >= i; ++i){
					if(aftdat[pos - i] == befdat[scan - i])
						++s;
					if((s * 2) - i > (Sb * 2) - lenb){
						Sb = s;
						lenb = i;
					}
				}
			}

			if(lastscan + diffl > scan - lenb){
				s_bsdipa_off_t overlap, Ss, lens;

				overlap = (lastscan + diffl) - (scan - lenb);
				s = Ss = lens = 0;
				for(i = 0; i < overlap; ++i){
					if(befdat[lastscan + diffl - overlap + i
							] == aftdat[aftpos + diffl - overlap + i])
						++s;
					if(befdat[scan - lenb + i] == aftdat[pos - lenb + i])
						--s;
					if(s > Ss){
						Ss = s;
						lens = i + 1;
					}
				}

				diffl += lens - overlap;
				lenb -= lens;
			}

			for(i = 0; i < diffl; ++i){
				uint8_t u;

				u = befdat[lastscan + i] - aftdat[aftpos + i];
				isneq |= (u != 0);
				*--diffp = u;
			}
			dcp->dc_diff_len += diffl;
			assert(diffp > extrap);

			extral = (scan - lenb) - (lastscan + diffl);
j_aftlen0_bypass:
			isneq |= (extral > 0);
			for(i = 0; i < extral; ++i)
				*extrap++ = befdat[lastscan + diffl + i];
			dcp->dc_extra_len += extral;
			assert(extrap <= diffp);

			/* Since v0.9.0 we only create control chunks with data.
			 * We allow for a data-less first, but do not generate it for binary BSDiff */
			assert(diffl != 0 || extral != 0 || ctrl.c_ccpp != NULL);
			if(diffl != 0 || extral != 0){
				rv = a_bsdiff_xout_ctrl(dcp, &ctrl, diffl, extral);
				if(rv != s_BSDIPA_OK)
					goto jleave;
			}

			ctrl.c_join_rel_pos += (pos - lenb) - (aftpos + diffl);
			lastscan = scan - lenb;
			aftpos = pos - lenb;
			lastoff = pos - scan;
		}
	}

	if(ctrl.c_need_dump){
		a_bsdiff_xout(0, &ctrl.c_ccp->cc_dat[ctrl.c_ccp->cc_len]);
			ctrl.c_ccp->cc_len += sizeof(s_bsdipa_off_t);
		/*ctrl.c_need_dump = 0;*/
	}

	dcp->dc_is_equal_data = !isneq;
	dcp->dc_diff_dat = diffp;

	rv = s_BSDIPA_OK;
jleave:
	if(Ip != NULL)
		(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, Ip);

	return rv;
} /* }}} */
/* }}} */

/*
 * Percivals BSDiff: used string suffix sort algorithm(s) {{{
 */
static void
a_bsdiff_split(s_bsdipa_off_t *I, s_bsdipa_off_t *V, s_bsdipa_off_t start, s_bsdipa_off_t len, s_bsdipa_off_t h){
	s_bsdipa_off_t i,j,k,x,tmp,jj,kk;

	if(len<16) {
		for(k=start;k<start+len;k+=j) {
			j=1;x=V[I[k]+h];
			for(i=1;k+i<start+len;i++) {
				if(V[I[k+i]+h]<x) {
					x=V[I[k+i]+h];
					j=0;
				}
				if(V[I[k+i]+h]==x) {
					tmp=I[k+j];I[k+j]=I[k+i];I[k+i]=tmp;
					j++;
				}
			}
			for(i=0;i<j;i++) V[I[k+i]]=k+j-1;
			if(j==1) I[k]=-1;
		}
		return;
	}

	x=V[I[start+len/2]+h];
	jj=0;kk=0;
	for(i=start;i<start+len;i++) {
		if(V[I[i]+h]<x) jj++;
		if(V[I[i]+h]==x) kk++;
	}
	jj+=start;kk+=jj;

	i=start;j=0;k=0;
	while(i<jj) {
		if(V[I[i]+h]<x) {
			i++;
		} else if(V[I[i]+h]==x) {
			tmp=I[i];I[i]=I[jj+j];I[jj+j]=tmp;
			j++;
		} else {
			tmp=I[i];I[i]=I[kk+k];I[kk+k]=tmp;
			k++;
		}
	}

	while(jj+j<kk) {
		if(V[I[jj+j]+h]==x) {
			j++;
		} else {
			tmp=I[jj+j];I[jj+j]=I[kk+k];I[kk+k]=tmp;
			k++;
		}
	}

	if(jj>start) a_bsdiff_split(I,V,start,jj-start,h);

	for(i=0;i<kk-jj;i++) V[I[jj+i]]=kk-1;
	if(jj==kk-1) I[jj]=-1;

	if(start+len>kk) a_bsdiff_split(I,V,kk,start+len-kk,h);
}

static int
a_bsdiff_qsufsort(s_bsdipa_off_t *I,const uint8_t *aftdat,s_bsdipa_off_t aftlen,struct s_bsdipa_diff_ctx *dcp){
	s_bsdipa_off_t *V;
	s_bsdipa_off_t buckets[256];
	s_bsdipa_off_t i,h,len;

	V = (s_bsdipa_off_t*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie,
			(size_t)(aftlen + 1) * sizeof(saidx_t));
	if(V == NULL)
		return 1;

	memset(buckets, 0, sizeof(buckets)); /*for(i=0;i<256;i++) buckets[i]=0;*/
	for(i=0;i<aftlen;i++) buckets[aftdat[i]]++;
	for(i=1;i<256;i++) buckets[i]+=buckets[i-1];
	for(i=255;i>0;i--) buckets[i]=buckets[i-1];
	buckets[0]=0;

	for(i=0;i<aftlen;i++) I[++buckets[aftdat[i]]]=i;
	I[0]=aftlen;
	for(i=0;i<aftlen;i++) V[i]=buckets[aftdat[i]];
	V[aftlen]=0;
	for(i=1;i<256;i++) if(buckets[i]==buckets[i-1]+1) I[buckets[i]]=-1;
	I[0]=-1;

	for(h=1;I[0]!=-(aftlen+1);h+=h) {
		len=0;
		for(i=0;i<aftlen+1;) {
			if(I[i]<0) {
				len-=I[i];
				i-=I[i];
			} else {
				if(len) I[i-len]=-len;
				len=V[I[i]]+1-i;
				a_bsdiff_split(I,V,i,len,h);
				i+=len;
				len=0;
			}
		}
		if(len) I[i-len]=-len;
	}

	for(i=0;i<aftlen+1;i++) I[V[i]]=i;

	(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, V);
	return 0;
}

#ifndef s_BSDIPA_SMALL
# include "libdivsufsort/divsufsort.c"
# undef lg_table
# define lg_table a_sssort_lg_table
# include "libdivsufsort/sssort.c"
# undef lg_table
# define lg_table a_trsort_lg_table
# include "libdivsufsort/trsort.c"
#endif
/* }}} */

#ifdef s_BSDIPA_TEXT /* {{{ */
static enum s_bsdipa_state
a_bsdiff_text(struct s_bsdipa_diff_ctx *dcp){
 /* Chris Torek's hash algorithm, result stirred as shown by Bret Mulvey */
# define a_CSHASH_HASH(R,BP,L) \
do{\
	uint8_t const *a__bp = BP;\
	uint32_t a__l = L;\
	uint32_t a__h = 0;\
\
	while(a__l-- != 0){ /* xxx Duff's device, unroll 8? */\
		uint8_t c = *a__bp++;\
		a__h = (a__h << 5) + a__h + c;\
	}\
\
	if(a__h != 0){\
		a__h += a__h << 13;\
		a__h ^= a__h >> 7;\
		a__h += a__h << 3;\
		a__h ^= a__h >> 17;\
		a__h += a__h << 5;\
	}\
\
	R = a__h;\
}while(0)

	/* XXX Very simple minded and blown-up line storage */
	struct a_l{
		struct a_l *l_hashnxt;
		struct a_l *l_nxt;
		uint8_t const *l_dat;
		uint32_t l_len;
		uint32_t l_hash;
	};

	struct a_lchunk{
		struct a_lchunk *lc_nxt;
		size_t lc_no;
		struct a_l lc_la[255];
	};

	struct a_bsdiff_ctrl ctrl;
	uint32_t alhprime;
	s_bsdipa_off_t xlen;
	uint8_t const *xdat;
	struct a_l **alhpp;
	struct a_lchunk *alcp_head, *alcp;
	s_bsdipa_hash_ptf hptf;
	enum s_bsdipa_state rv;
	assert(dcp->dc_before_len > 0);

	memset(&ctrl, 0, sizeof(ctrl));

	rv = s_BSDIPA_NOMEM;

	hptf = dcp->dc_hash;
	alcp_head = NULL;
	alhpp = NULL;

	/* Create hashes for lines in "after"; create hashmap of lines {{{ */
	xdat = dcp->dc_after_dat;
	xlen = (s_bsdipa_off_t)dcp->dc_after_len;
	if(xlen > 0){
		s_bsdipa_off_t cnt, ll;
		uint8_t const *beg, *end;
		struct a_l *alp, *lp;

		alp = NULL;
		beg = NULL;
		cnt = 0;
		/*ll = 0; uninit*/
		goto Jalc_go;

		while(xlen > 0){
			beg = xdat;
			end = memchr(beg, '\n', (size_t)xlen);
			if(end != NULL){
				ll = (s_bsdipa_off_t)(++end - xdat);
				xlen -= ll;
			}else{
				ll = xlen;
				xlen = 0;
			}
			xdat += ll;

			if(/*ll >= s_BSDIPA_OFF_MAX - 1 ||*/ ll != (s_bsdipa_off_t)(uint32_t)ll){
				rv = s_BSDIPA_FBIG;
				goto jleave;
			}

			if(alcp->lc_no == sizeof(alcp->lc_la) / sizeof(alcp->lc_la[0])) Jalc_go:{
				struct a_lchunk *lcp;

				lcp = (struct a_lchunk*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie,
						sizeof(*lcp));
				if(lcp == NULL)
					goto jleave;
				memset(lcp, 0, sizeof(*lcp));

				if(alcp_head == NULL){
					alcp_head = alcp = lcp;
					continue;
				}
				alcp->lc_nxt = lcp;
				alcp = lcp;
			}

			/* cnt cannot exceed s_BSDIPA_OFF_MAX-1 */
			++cnt;
			lp = &alcp->lc_la[alcp->lc_no++];
			lp->l_hashnxt = alp;
			if(alp != NULL)
				alp->l_nxt = lp;
			alp = lp;
			/*alp->l_nxt = NULL;*/
			alp->l_dat = beg;
			alp->l_len = (uint32_t)ll;
			if(hptf == NULL)
				a_CSHASH_HASH(alp->l_hash, beg, alp->l_len);
			else
				alp->l_hash = (*hptf)(dcp->dc_hash_cookie, beg, alp->l_len);
		}

		/* Hashmap size, prime spaced: 2777, 14057, 47431 slots xxx really these fixed three only? */
		if(cnt <= 0xAD9 * 5)
			cnt = 0xAD9;
		else if(cnt <= 0x36E9 * 5)
			cnt = 0x36E9;
		else if((size_t)cnt >= (((((size_t)UINT32_MAX < (size_t)s_BSDIPA_OFF_MAX)
				? (size_t)UINT32_MAX : (size_t)s_BSDIPA_OFF_MAX) - 1) / sizeof(struct a_l*))){
			rv = s_BSDIPA_FBIG;
			goto jleave;
		}else
			cnt = 0xB947;
		ll = cnt * sizeof(struct a_l*);

		alhpp = (struct a_l**)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie, (size_t)ll);
		if(alhpp == NULL)
			goto jleave;
		memset(alhpp, 0, ll);

		while(alp != NULL){
			uint32_t i;

			lp = alp->l_hashnxt;
			i = alp->l_hash % cnt;
			alp->l_hashnxt = alhpp[i];
			alhpp[i] = alp;
			alp = lp;
		}

		alhprime = (uint32_t)cnt;
	} /* }}} */

	rv = s_BSDIPA_FBIG;

	/* Diff creation {{{ */
	/* C99 */{
		struct a_l *alp;
		s_bsdipa_off_t extral, diffl, aabspos;
		uint8_t *extrap, *diffp;
		uint32_t isneq;

		xdat = dcp->dc_before_dat;
		xlen = (s_bsdipa_off_t)dcp->dc_before_len;
		ctrl.c_len_max = a_BSDIFF_CTL_LEN_MAX(xlen);
		/*ctrl.c_join_rel_pos = 0;*/

		isneq = (xlen != (s_bsdipa_off_t)dcp->dc_after_len);

		extrap = dcp->dc_extra_dat;
		diffp = dcp->dc_diff_dat;
		aabspos = extral = diffl = 0;

		/* Walk over "before" data */
		for(alp = NULL; xlen > 0;){
			s_bsdipa_off_t ll;
			uint8_t const *beg, *end;

			beg = xdat;
			end = memchr(beg, '\n', (size_t)xlen);
			if(end != NULL){
				ll = (s_bsdipa_off_t)(++end - xdat);
				xlen -= ll;
			}else{
				ll = xlen;
				xlen = 0;
			}
			xdat += ll;

			if(/*ll >= s_BSDIPA_OFF_MAX - 1 ||*/ ll != (s_bsdipa_off_t)(uint32_t)ll)
				goto jleave;

			/* Differential data at all possible? */
			if(alhpp != NULL){
				uint32_t h;

				if(hptf == NULL)
					a_CSHASH_HASH(h, beg, ll);
				else
					h = (*hptf)(dcp->dc_hash_cookie, beg, ll);

				/* "diff" in the works? */
				if(alp != NULL){
					struct a_l *lp;

					/* Try extend that range */
					lp = alp->l_nxt;

					if(lp != NULL && h == lp->l_hash && ll == (s_bsdipa_off_t)lp->l_len &&
							!memcmp(beg, lp->l_dat, (size_t)ll)){
						if(diffl >= s_BSDIPA_OFF_MAX - ll - 1)
							goto jleave;
						alp = lp;
						aabspos += ll;
						dcp->dc_diff_len += ll;
						diffl += ll;
						diffp -= ll;
						memset(diffp, 0, ll);
						continue;
					}
				}

				/* Not continuing diff.  Maybe this line starts one? */
				alp = alhpp[h % alhprime];
				if(alp != NULL){
					do if(h == alp->l_hash && ll == (s_bsdipa_off_t)alp->l_len &&
							!memcmp(beg, alp->l_dat, ll))
						break;
					while((alp = alp->l_hashnxt) != NULL);

					if(alp != NULL){
						s_bsdipa_off_t p;

						p = (s_bsdipa_off_t)(&alp->l_dat[0] - dcp->dc_after_dat);

						/* If we already had seen diff/extra in this ctrl chunk, dump first */
						if((diffl | extral) != 0 || (!ctrl.c_need_dump && p != aabspos)){
							rv = a_bsdiff_xout_ctrl(dcp, &ctrl, diffl, extral);
							if(rv != s_BSDIPA_OK)
								goto jleave;
							rv = s_BSDIPA_FBIG;
							extral = 0;
						}

						if(p != aabspos){
							assert(ctrl.c_need_dump);
							ctrl.c_join_rel_pos = p - aabspos;
							a_bsdiff_xout(ctrl.c_join_rel_pos,
								&ctrl.c_ccp->cc_dat[ctrl.c_ccp->cc_len]);
							ctrl.c_ccp->cc_len += sizeof(s_bsdipa_off_t);
							ctrl.c_join_rel_pos = 0;
							ctrl.c_need_dump = 0;
						}

						p += ll;
						aabspos = p;
						dcp->dc_diff_len += ll;
						diffl = ll;
						diffp -= ll;
						assert(extrap <= diffp);
						memset(diffp, 0, ll);
						continue;
					}
				}
			}

			/* Extra data; can never generate an initial move */
			if(extral >= s_BSDIPA_OFF_MAX - ll - 1)
				goto jleave;
			isneq = 1;
			dcp->dc_extra_len += ll;
			extral += ll;
			memcpy(extrap, beg, (size_t)ll);
			extrap += ll;
			assert(extrap <= diffp);
		}

		if((diffl | extral) != 0){
			rv = a_bsdiff_xout_ctrl(dcp, &ctrl, diffl, extral);
			if(rv != s_BSDIPA_OK)
				goto jleave;
		}

		if(ctrl.c_need_dump){
			a_bsdiff_xout(0, &ctrl.c_ccp->cc_dat[ctrl.c_ccp->cc_len]);
				ctrl.c_ccp->cc_len += sizeof(s_bsdipa_off_t);
			/*ctrl.c_need_dump = 0;*/
		}

		dcp->dc_is_equal_data = !isneq;
		dcp->dc_diff_dat = diffp;
	} /* }}} */

	rv = s_BSDIPA_OK;
jleave:
	if(alhpp != NULL)
		(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, alhpp);

	for(alcp = alcp_head; alcp != NULL;){
		void *vp;

		vp = alcp;
		alcp = alcp->lc_nxt;
		(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, vp);
	}

	return rv;
}

# undef a_CSHASH_HASH
#endif /* s_BSDIPA_TEXT }}} */

/* s-itt-mode */
