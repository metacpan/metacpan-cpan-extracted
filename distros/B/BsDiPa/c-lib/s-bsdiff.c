/*@ Implementation of s-bsdipa-lib.h: s_bsdipa_diff() and support.
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

#include <assert.h>
#include <string.h>

#ifndef s_BSDIPA_SMALL
# define DIVSUFSORT_API static
# include "divsufsort.h"
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

/* (Could be shared with s-bspatch.c) */
static void *a_bsdiff_alloc(void *vp, size_t size);
static void a_bsdiff_free(void *vp, void *dat);

static inline s_bsdipa_off_t a_bsdiff_matchlen(uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		uint8_t const *befdat, s_bsdipa_off_t beflen);
static s_bsdipa_off_t a_bsdiff_search(s_bsdipa_off_t const *Ip, uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		uint8_t const *befdat, s_bsdipa_off_t beflenp,
		s_bsdipa_off_t st, s_bsdipa_off_t en, s_bsdipa_off_t *posp);
static inline void a_bsdiff_xout(s_bsdipa_off_t x, uint8_t *bp);

/* Later imported original BSDiff suffix sort by Colin Percival; at EOF.
 * (It was replaced with libdivsufsort in the FreeBSD codebase to which he pointed me due to "existing fixes",
 * because of performance improvements: 10-15 percent for large binaries (megabytes); for smaller files his is better.)
 * Except for types and names i did not adapt syntax to my style for those. */
static void a_bsdiff_split(s_bsdipa_off_t *I, s_bsdipa_off_t *V, s_bsdipa_off_t start, s_bsdipa_off_t len,
		s_bsdipa_off_t h);
static int a_bsdiff_qsufsort(s_bsdipa_off_t *I, uint8_t const *aftdat, s_bsdipa_off_t aftlen,
		struct s_bsdipa_diff_ctx *dcp);

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
		if(memcmp(aftdat + Ip[x], befdat, y) < 0)
			r = a_bsdiff_search(Ip, aftdat, aftlen, befdat, beflen, x, en, posp);
		else
			r = a_bsdiff_search(Ip, aftdat, aftlen, befdat, beflen, st, x, posp);
	}

	return r;
}

static inline void
a_bsdiff_xout(s_bsdipa_off_t x, uint8_t *buf){ /* xxx use endian.h stuff */
	s_bsdipa_off_t y;
	int lt0;

	lt0 = (x < 0);
	y = lt0 ? -x : x;

#ifndef s_BSDIPA_32
			buf[7] = y % 256; y -= buf[7];
	y = y / 256;	buf[6] = y % 256; y -= buf[6];
	y = y / 256;	buf[5] = y % 256; y -= buf[5];
	y = y / 256;	buf[4] = y % 256; y -= buf[4];
	y = y / 256;
#endif
			buf[3] = y % 256; y -= buf[3];
	y = y / 256;	buf[2] = y % 256; y -= buf[2];
	y = y / 256;	buf[1] = y % 256; y -= buf[1];
	y = y / 256;	buf[0] = y % 256;
	if(lt0)
		buf[0] |= 0x80;
}

void
s_bsdipa_i_to_buf(uint8_t *out, s_bsdipa_off_t in){
	a_bsdiff_xout(in, out);
}

enum s_bsdipa_state
s_bsdipa_diff(struct s_bsdipa_diff_ctx *dcp){
	saidx_t *Ip;
	uint8_t const *befdat, *aftdat;
	uint8_t *extrap, *diffp;
	s_bsdipa_off_t beflen, aftlen;
	enum s_bsdipa_state rv;

	if(dcp->dc_mem.mc_alloc != NULL){
		dcp->dc_mem.mc_custom_cookie = dcp;
		dcp->dc_mem.mc_custom_alloc = &a_bsdiff_alloc;
		dcp->dc_mem.mc_custom_free = &a_bsdiff_free;
	}

	if(dcp->dc_magic_window <= 0)
		dcp->dc_magic_window = s_BSDIPA_MAGIC_WINDOW;

	/* Enable s_bsdipa_diff_free() */
	memset(&dcp->dc_ctrl_len, 0, sizeof(*dcp) - (size_t)((uint8_t*)&dcp->dc_ctrl_len - (uint8_t*)dcp));

	rv = s_BSDIPA_FBIG;

	/* Fail early if we cannot create a patch with a header and one control triple */
	if(dcp->dc_before_len >= s_BSDIPA_OFF_MAX -sizeof(struct s_bsdipa_header) -sizeof(struct s_bsdipa_ctrl_triple))
		goto jleave;
	if(dcp->dc_before_len + 1 >= SIZE_MAX / sizeof(saidx_t))
		goto jleave;
	beflen = (s_bsdipa_off_t)dcp->dc_before_len;
	befdat = dcp->dc_before_dat;

	if(dcp->dc_after_len >= s_BSDIPA_OFF_MAX)
		goto jleave;
	if(dcp->dc_after_len + 1 >= SIZE_MAX / sizeof(saidx_t))
		goto jleave;
	aftlen = (s_bsdipa_off_t)dcp->dc_after_len;
	aftdat = dcp->dc_after_dat;

	rv = s_BSDIPA_NOMEM;

	dcp->dc_extra_dat =
		extrap = (uint8_t*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie, (size_t)(beflen + 1));
	if(dcp->dc_extra_dat == NULL)
		goto jleave;
	/* Let's share that buffer */
	dcp->dc_diff_dat = diffp = &dcp->dc_extra_dat[(size_t)(beflen + 1)];

	Ip = (saidx_t*)(*dcp->dc_mem.mc_custom_alloc)(dcp->dc_mem.mc_custom_cookie,
			(size_t)(aftlen + 1) * sizeof(saidx_t));
	if(Ip == NULL)
		goto jleave;

	/* Compute the differences, writing ctrl as we go */
	if(aftlen == 0 && beflen == 0)
		dcp->dc_is_equal_data = 1;
	else{
		s_bsdipa_off_t ctrl_len_max, scan, len, pos, lastscan, lastpos, lastoff, super_pos, aftscore, i;
		uint32_t ctrlno;
		struct s_bsdipa_ctrl_chunk **ccpp, *ccp;
		int maxoffdecr, isneq, need_dump;

		maxoffdecr = 0;
		if(aftlen != 0 && beflen != 0){
#ifndef s_BSDIPA_SMALL
			/* Limit is "a bit arbitrary", and surely also depends on memory cache performance etc */
			if(aftlen > 4096l * 25){
				/* divsufsort(): effectively only ENOMEM */
				if(divsufsort(aftdat, Ip, aftlen, dcp))
					goto jdone;
				maxoffdecr = 1;
			}else
#endif
				if(a_bsdiff_qsufsort(Ip, aftdat, aftlen, dcp))
					goto jdone;
		}

		isneq = (aftlen != beflen);
		need_dump = 0;
		ccpp = NULL;
		ccp = NULL; /* xxx UNINIT() */
		ctrlno = 0; /* xxx UNINIT() */
		ctrl_len_max = s_BSDIPA_OFF_MAX - beflen - (sizeof(s_bsdipa_off_t) * 3) - 1;
		scan = len = pos = lastscan = lastpos = lastoff = super_pos = 0;

		/* a_bsdiff_search() is called with aftlen-a_BSDIPA_DIVSUFSORT, so bypass algorithm as such, then */
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
				s_bsdipa_off_t s, Sf, lenf, lenb, j;

				if(aftlen == 0){
					lenf = lenb = 0;
					j = scan = beflen;
					goto j_aftlen0_bypass;
				}

				if(dcp->dc_ctrl_len >= ctrl_len_max){
					rv = s_BSDIPA_FBIG;
					goto jdone;
				}

				s = Sf = lenf = 0;

				for(i = 0; lastscan + i < scan && lastpos + i < aftlen;){
					if(aftdat[lastpos + i] == befdat[lastscan + i])
						++s;
					++i;
					if((s * 2) - i > (Sf * 2) - lenf){
						Sf = s;
						lenf = i;
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

				if(lastscan + lenf > scan - lenb){
					s_bsdipa_off_t overlap, Ss, lens;

					overlap = (lastscan + lenf) - (scan - lenb);
					s = Ss = lens = 0;
					for(i = 0; i < overlap; ++i){
						if(befdat[lastscan + lenf - overlap + i
								] == aftdat[lastpos + lenf - overlap + i])
							++s;
						if(befdat[scan - lenb + i] == aftdat[pos - lenb + i])
							--s;
						if(s > Ss){
							Ss = s;
							lens = i + 1;
						}
					}

					lenf += lens - overlap;
					lenb -= lens;
				}

				for(i = 0; i < lenf; ++i){
					uint8_t u;

					u = befdat[lastscan + i] - aftdat[lastpos + i];
					isneq |= (u != 0);
					*--diffp = u;
				}
				dcp->dc_diff_len += lenf;
				assert(diffp > extrap);

				j = (scan - lenb) - (lastscan + lenf);
j_aftlen0_bypass:
				for(i = 0; i < j; ++i)
					*extrap++ = befdat[lastscan + lenf + i];
				dcp->dc_extra_len += j;
				assert(extrap <= diffp);

				/* Since v0.9.0 we only create control chunks with data (but the first) */
				if(lenf != 0 || j != 0){
					if(need_dump){
						a_bsdiff_xout(super_pos, &ccp->cc_dat[ccp->cc_len]);
						ccp->cc_len += sizeof(s_bsdipa_off_t);
						super_pos = 0;
					}

					if(ccpp == NULL || --ctrlno == 0){
						/* xxx Do not: sizeof(struct s_bsdipa_ctrl_triple) * a_BSDIPA_CTRL_NO */
						ccp = (struct s_bsdipa_ctrl_chunk*)(*dcp->dc_mem.mc_custom_alloc)
								(dcp->dc_mem.mc_custom_cookie,
								 (sizeof(struct s_bsdipa_ctrl_chunk) +
									(3 * sizeof(s_bsdipa_off_t) * a_BSDIPA_CTRL_NO)));
						if(ccp == NULL)
							goto jdone;
						if(ccpp == NULL)
							dcp->dc_ctrl = ccp;
						else
							*ccpp = ccp;
						ccp->cc_next = NULL;
						ccpp = &ccp->cc_next;
						ccp->cc_len = 0;
						ctrlno = a_BSDIPA_CTRL_NO;
					}

					a_bsdiff_xout(lenf, &ccp->cc_dat[ccp->cc_len]);
						ccp->cc_len += sizeof(s_bsdipa_off_t);
					a_bsdiff_xout(j, &ccp->cc_dat[ccp->cc_len]);
						ccp->cc_len += sizeof(s_bsdipa_off_t);
					need_dump = 1;
					dcp->dc_ctrl_len += sizeof(s_bsdipa_off_t) * 3;
				}

				super_pos += (pos - lenb) - (lastpos + lenf);
				lastscan = scan - lenb;
				lastpos = pos - lenb;
				lastoff = pos - scan;
			}
		}

		if(need_dump){
			a_bsdiff_xout(0, &ccp->cc_dat[ccp->cc_len]);
				ccp->cc_len += sizeof(s_bsdipa_off_t);
			/*need_dump = 0;*/
		}

		dcp->dc_is_equal_data = !isneq;
	}

	dcp->dc_diff_dat = diffp;

	/* Create readily prepared header; as documented, sum of lengths does not exceed _OFF_MAX */
	a_bsdiff_xout(dcp->dc_ctrl_len, &dcp->dc_header[0]);
	a_bsdiff_xout(dcp->dc_diff_len, &dcp->dc_header[sizeof(s_bsdipa_off_t)]);
	a_bsdiff_xout(dcp->dc_extra_len, &dcp->dc_header[sizeof(s_bsdipa_off_t) * 2]);
	a_bsdiff_xout(beflen, &dcp->dc_header[sizeof(s_bsdipa_off_t) * 3]);

	rv = s_BSDIPA_OK;
jdone:
	(*dcp->dc_mem.mc_custom_free)(dcp->dc_mem.mc_custom_cookie, Ip);

jleave:
	return rv;
}

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
 * The algorithm(s) {{{
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
				};
				if(V[I[k+i]+h]==x) {
					tmp=I[k+j];I[k+j]=I[k+i];I[k+i]=tmp;
					j++;
				};
			};
			for(i=0;i<j;i++) V[I[k+i]]=k+j-1;
			if(j==1) I[k]=-1;
		};
		return;
	};

	x=V[I[start+len/2]+h];
	jj=0;kk=0;
	for(i=start;i<start+len;i++) {
		if(V[I[i]+h]<x) jj++;
		if(V[I[i]+h]==x) kk++;
	};
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
		};
	};

	while(jj+j<kk) {
		if(V[I[jj+j]+h]==x) {
			j++;
		} else {
			tmp=I[jj+j];I[jj+j]=I[kk+k];I[kk+k]=tmp;
			k++;
		};
	};

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
			};
		};
		if(len) I[i-len]=-len;
	};

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

/* s-itt-mode */
