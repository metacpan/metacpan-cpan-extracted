/*@ s-bsdipa-lib: port of Colin Percival's BSDiff(/bspatch) to a library.
 *@ BSDiff: create or apply binary difference patch.
 *@
 *@ Remarks:
 *@ - if s_BSDIPA_32 is configured, 31-bit instead of 63-bit limits.
 *@ - Note: the real limit is maximally SIZE_MAX/sizeof(s_bsdipa_off_t)
 *@   (with 32-bit size_t this can be restrictive)!
 *@ - algorithm requires a lot of memory, multiple times the input size!
 *@   With s_BSDIPA_32 the overhead can almost be halved.
 *@ - code requires an ISO STD C99 environment.
 *@
 *@ Changes to original bsdiff / libdivsufsort:
 *@ - optional (s_BSDIPA_32) 31-bit limits, thus smaller header/control data,
 *@   as well as smaller (about halved) memory overhead.
 *@ - the s_BSDIPA_MAGIC_WINDOW is configurable: the original is bound to
 *@   (32- and) 64-bit binary diffs (8), but eg 16 or 32 are better (for text).
 *@ - data serialization is in big endian/network byte order.
 *@ - no bzip2 compression: callee should compress result.
 *@   NOTE: compression is necessary since data is stored in full, meaning
 *@   that identical bytes are stored as NUL.
 *@   The s-bsdipa-io.h header is a readily available layer for this.
 *@ - no file I/O, everything is stored on the heap.
 *@ - internally diff- and extra data share heap to reduce memory overhead.
 *@ -- as a result diff data is stored in reverse order, last byte first.
 *@ - memory allocation is solely done via user provided allocator.
 *@ - the header includes the extra data length, so that all information
 *@   is available through it.
 *@
 *@ Informational: original bsdiff file format:
 *@	0	8	"BSDIFF40"
 *@	8	8	X
 *@	16	8	Y
 *@	24	8	sizeof(result[file])
 *@	32	X	bzip2(control block)
 *@	32+X	Y	bzip2(diff block)
 *@	32+X+Y	???	bzip2(extra block)
 *@ With control block being a set of triples (x,y,z) meaning "read x bytes of
 *@ diff data into NEW, then add x bytes from OLD to these x bytes in NEW;
 *@ copy y bytes from the extra block onto NEW; seek forwards in OLD by z".
 */
#define s_BSDIPA_COPYRIGHT \
	"S-bsdipa is\n" \
	"	Copyright (c) 2024 - 2025 Steffen Nurpmeso\n" \
	"	SPDX-License-Identifier: ISC\n" \
	"The used BSDiff algorithm is\n" \
	"	Copyright 2003-2005 Colin Percival\n" \
	"	SPDX-License-Identifier: BSD-2-Clause\n" \
	"and it uses libdivsufsort that is\n" \
	"	Copyright (c) 2003 Yuta Mori All rights reserved.\n" \
	"	SPDX-License-Identifier: MIT\n"
/* L5E> */
/*@ S-bsdipa copyright:
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
/*@ The algorithm as is used inside the library actually is:
 *
 * SPDX-License-Identifier: BSD-2-Clause
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
/*@ The library used by the algorithm actually is:
 *
 * SPDX-License-Identifier: MIT
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2003 Yuta Mori All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
/* L5E< */
#ifndef s_BSDIPA_LIB_H
#define s_BSDIPA_LIB_H

#include <s-bsdipa-config.h> /* s_BSDIPA_{VERSION,CONTACT,32,MAGIC_WINDOW} */

#include <sys/types.h>

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Integer type for header and control block triples: file size / offsets.
 * For easy overflow avoidance (left hand value) we also test >s_BSDOFF_MAX-1.
 * The real limit is even smaller (patch preparation ~SIZE_MAX/sizeof(s_bsdipa_off_t)). */
#ifdef s_BSDIPA_32
# define s_BSDIPA_OFF_MAX INT32_MAX
# define s_BSDIPA_OFF_MIN INT32_MIN
typedef int32_t s_bsdipa_off_t;
#else
# define s_BSDIPA_OFF_MAX INT64_MAX
# define s_BSDIPA_OFF_MIN INT64_MIN
typedef int64_t s_bsdipa_off_t;
#endif

enum s_bsdipa_state{
	s_BSDIPA_OK, /* Result is usable. */
	s_BSDIPA_FBIG, /* Data or resulting control block length too large. */
	s_BSDIPA_NOMEM, /* Allocation failure. */
	s_BSDIPA_INVAL /* Any other error. */
};

/* Memory accessor with two possibilities:
 * - .mc_alloc is not NULL, then .mc_free has to be set, too.
 * - Otherwise .mc_custom_alloc and .mc_custom_free need to be set, and .mc_custom_cookie will
 *   be passed as their first argument.
 * - Internally the custom variant is always used: s_bsdipa_{diff,patch}() check that on entry,
 *   and prepare the custom variant as necessary. */
struct s_bsdipa_memory_ctx{
	void *(*mc_alloc)(size_t);
	void (*mc_free)(void *);
	void *mc_custom_cookie;
	void *(*mc_custom_alloc)(void *, size_t);
	void (*mc_custom_free)(void *, void *);
};

/* [Informational:] Header.  It is guaranteed that .h_ctrl_len+.h_diff_len+.h_extra_len < s_BSDIPA_OFF_MAX! */
struct s_bsdipa_header{
	s_bsdipa_off_t h_ctrl_len; /* Length of control block. */
	s_bsdipa_off_t h_diff_len; /* Length of difference data block. */
	s_bsdipa_off_t h_extra_len; /* Length of extra data block. */
	s_bsdipa_off_t h_before_len; /* Equals s_bsdipa_diff_ctx::dc_before_len. */
};

/* Informational: a control triple. */
struct s_bsdipa_ctrl_triple{
	s_bsdipa_off_t ct_diff_len; /* Copy that much from diff block. */
	s_bsdipa_off_t ct_extra_len; /* Copy that much from extra block. */
	s_bsdipa_off_t ct_seek_bytes; /* Seek in source ("after") data by that many bytes. */
};

/* Storage for serialized ctrl_triple's. (Internal constant: 41 triples at the time of this writing.) */
struct s_bsdipa_ctrl_chunk{
	struct s_bsdipa_ctrl_chunk *cc_next; /* Next node or NULL. */
	s_bsdipa_off_t cc_len; /* Bytes in .cc_dat.  Never more than a few kilobytes. */
	uint8_t cc_dat[]; /* ISO C99 */
};

struct s_bsdipa_diff_ctx{
	struct s_bsdipa_memory_ctx dc_mem; /* Memory accessor: first!  (May be modified!) */
	/* Inputs (64-bit type for easy user assignment, effective limit is s_BSDIPA_OFF_MAX): */
	uint8_t const *dc_before_dat; /* Source: old data before changes, plus length. */
	uint64_t dc_before_len;
	uint8_t const *dc_after_dat; /* New data after changes, plus length. */
	uint64_t dc_after_len;
	/* Number of bytes in "a window".  If <=0 s_BSDIPA_MAGIC_WINDOW is assigned and used.
	 * For binary data sizeof(void*) is useful, higher values (16, 32) impose savings for text.
	 * There is no maximum imposed, but the algorithm does *not* perform integer overflow checks! */
	int32_t dc_magic_window;
	int8_t dc__dummy[3];
	/* Outputs: (allocated result data; freed by s_bsdipa_diff_free()). */
	int8_t dc_is_equal_data; /* Whether .dc_before_dat and .dc_after_dat and their lengths are equal */
	s_bsdipa_off_t dc_ctrl_len; /* Sum of dc_ctrl lengths.  (Struct field offset used - do not move!) */
	s_bsdipa_off_t dc_diff_len; /* Length of .dc_diff_dat. */
	s_bsdipa_off_t dc_extra_len; /* Length of .dc_extra_dat. */
	struct s_bsdipa_ctrl_chunk *dc_ctrl; /* Control block result list. */
	uint8_t *dc_diff_dat; /* Differences (stored in reverse order). */
	uint8_t *dc_extra_dat; /* Extra data. */
	uint8_t dc_header[sizeof(struct s_bsdipa_header)]; /* Readily prepared (serialized) header. */
};

/* Iterate over all control blocks:
 *	struct s_bsdipa_ctrl_chunk *tmp;
 *	s_BSDIPA_DIFF_CTX_FOREACH_CTRL(CTXP, tmp){
 *		printf("ctrl block: len=%ld dat=%p\n", (long)tmp->cc_len, tmp->cc_dat);
 *	}
 */
#define s_BSDIPA_DIFF_CTX_FOREACH_CTRL(CTXP,TMPNODE) \
	for(TMPNODE = (CTXP)->dc_ctrl; TMPNODE != NULL; TMPNODE = (TMPNODE)->cc_next)

struct s_bsdipa_patch_ctx{
	struct s_bsdipa_memory_ctx pc_mem; /* Memory accessor: first!  (May be modified!) */
	/* Inputs (64-bit type for easy user assignment, effective limit is s_BSDIPA_OFF_MAX): */
	uint8_t const *pc_after_dat; /* Source: after ("current") data, plus length. */
	uint64_t pc_after_len;
	/* 0=unlimited, otherwise upper limit in bytes.
	 * This does not change the effective limit, but it may constrain it further.
	 * (One could instead look at pc_header.h_before_len before applying the patch,
	 * but for "minimal" users like the BsDiPa.xs perl module it is easier to simply set this field
	 * and let the C code act accordingly.) */
	uint64_t pc_max_allowed_restored_len;
	/* Patch data: one can *either* set .pc_patch_dat plus length, *or* the individual fields.
	 * For the former case s_bsdipa_patch_parse_header() can be used to create .pc_header,
	 * and .pc_patch_dat and .pc_patch_len are to be set thereafter.
	 * In and for the latter case .pc_patch_dat must be NULL, .pc_header must have been filled in,
	 * and all of .pc_ctrl_dat, .pc_diff_dat and .pc_extra_dat must be set.
	 * The lengths of .pc_header are verified in either case.
	 * NOTE: .pc_ctrl_dat, .pc_diff_dat, .pc_extra_dat and .pc_header are modified! */
	uint8_t const *pc_patch_dat;
	uint64_t pc_patch_len;
	uint8_t const *pc_ctrl_dat;
	uint8_t const *pc_diff_dat;
	uint8_t const *pc_extra_dat;
	struct s_bsdipa_header pc_header; /* Deserialized header. */
	/* Outputs (allocated result data; freed by s_bsdipa_patch_free()).
	 * (The buffer is guaranteed to have room for one additional byte.) */
	uint8_t *pc_restored_dat;
	s_bsdipa_off_t pc_restored_len; /* (Actually a copy of pc_header.h_before_len.) */
};

/* Utilities which convert s_bsdiff_off_t to/from the serialized variant.
 * The buffer must be large enough for sizeof(s_bsdipa_off_t) and thus depends upon s_BSDIPA_32. */
s_bsdipa_off_t s_bsdipa_buf_to_i(uint8_t const *in);
void s_bsdipa_i_to_buf(uint8_t *out, s_bsdipa_off_t in);

/* Create a patch from input data as documented for s_bsdipa_diff_ctx.
 * Function always initializes outputs for s_bsdipa_diff_free(). */
enum s_bsdipa_state s_bsdipa_diff(struct s_bsdipa_diff_ctx *dcp);

/* Release result memory; to be called even in case of errors. */
void s_bsdipa_diff_free(struct s_bsdipa_diff_ctx *dcp);

/* Deserialize a header from dat (at least sizeof(*hp)) into hp.
 * Returns _OK, or _INVAL if input is senseless (negative lengths, overflows, etc).
 * Note the header could be stored distinct from data, so overflow check does not account for header size.
 * However, it assumes s_bsdipa_diff() generated the header: strict verification is performed. */
enum s_bsdipa_state s_bsdipa_patch_parse_header(struct s_bsdipa_header *hp, uint8_t const *dat);

/* Create restored data as documented for s_bsdipa_patch_ctx.
 * Function always initializes outputs for s_bsdipa_patch_free(). */
enum s_bsdipa_state s_bsdipa_patch(struct s_bsdipa_patch_ctx *pcp);

/* Release result memory; to be called even in case of errors. */
void s_bsdipa_patch_free(struct s_bsdipa_patch_ctx *pcp);

#ifdef __cplusplus
}
#endif
#endif /* !s_BSDIPA_LIB_H */
/* s-itt-mode */
