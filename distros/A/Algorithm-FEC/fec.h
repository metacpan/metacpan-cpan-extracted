/*
 * fec.h -- forward error correction based on Vandermonde matrices
 * 980614
 * (C) 1997-98 Luigi Rizzo (luigi@iet.unipi.it)
 *
 * Portions derived from code by Phil Karn (karn@ka9q.ampr.org),
 * Robert Morelos-Zaragoza (robert@spectra.eng.hawaii.edu) and Hari
 * Thirumoorthy (harit@spectra.eng.hawaii.edu), Aug 1995
 * modified by Marc Lehmann <fec@schmorp.de>, Sep 2003.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:

 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 */

/*
 * The following parameter defines how many bits are used for
 * field elements. The code supports any value from 2 to 16
 * but fastest operation is achieved with 8 bit elements
 * This is the only parameter you may want to change.
 */
#define GF_BITS8   8	/* code over GF(2**GF_BITS) - change to suit */
#define GF_BITS16  16	/* code over GF(2**GF_BITS) - change to suit */

#define	GF_SIZE8  ((1 << GF_BITS8 ) - 1)	/* powers of \alpha */
#define	GF_SIZE16 ((1 << GF_BITS16) - 1)	/* powers of \alpha */

void fec8_free(void *p) ;
void *fec8_new(int k, int n) ;
void fec8_encode(void *code, void *src[], void *dst, int index, int sz) ;
int fec8_decode(void *code, void *pkt[], int index[], int sz) ;

void fec16_free(void *p) ;
void *fec16_new(int k, int n) ;
void fec16_encode(void *code, void *src[], void *dst, int index, int sz) ;
int fec16_decode(void *code, void *pkt[], int index[], int sz) ;

/* end of file */
