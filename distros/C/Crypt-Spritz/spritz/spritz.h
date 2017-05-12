/* spritz.h, spritz C implementation, header
 *
 * Copyright (c) 2015 Marc Alexander Lehmann <libev@schmorp.de>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modifica-
 * tion, are permitted provided that the following conditions are met:
 *
 *   1.  Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *   2.  Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MER-
 * CHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPE-
 * CIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTH-
 * ERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU General Public License ("GPL") version 2 or any later version,
 * in which case the provisions of the GPL are applicable instead of
 * the above. If you wish to allow the use of your version of this file
 * only under the terms of the GPL and not to allow others to use your
 * version of this file under the BSD license, indicate your decision
 * by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL. If you do not delete the
 * provisions above, a recipient may use your version of this file under
 * either the BSD or the GPL.
 */
#ifndef SPRITZ_H
#define SPRITZ_H

#include <stdint.h>
#include <sys/types.h>

/*******************************************************************************/
/* spritz parameters/state type */

enum {
  spritz_N              = 256,
  spritz_aead_blocksize = spritz_N >> 2 /* 64 */
};

typedef struct
{
  uint8_t a, i, j, k, z, w;
  uint8_t S[spritz_N];
} spritz_state;

/*******************************************************************************/
/* the spritz primitives */

void    spritz_init            (spritz_state *s);
void    spritz_update          (spritz_state *s);
void    spritz_whip            (spritz_state *s, uint_fast16_t r);
void    spritz_crush           (spritz_state *s);
void    spritz_shuffle         (spritz_state *s);
void    spritz_absorb          (spritz_state *s, const void *I, size_t I_len);
void    spritz_absorb_stop     (spritz_state *s);
void    spritz_absorb_and_stop (spritz_state *s, const void *I, size_t I_len); /* commonly used helper function */
uint8_t spritz_output          (spritz_state *s);
void    spritz_squeeze         (spritz_state *s, void *P, size_t P_len);
uint8_t spritz_drip            (spritz_state *s);

/*******************************************************************************/
/* the spritz cipher */

/* no IV is used if IV_len == 0 */
void spritz_cipher_init    (spritz_state *s, const void *K, size_t K_len, const void *IV, size_t IV_len);

/* can be called multiple times/incrementally */
/* can work inplace */
void spritz_cipher_encrypt (spritz_state *s, const void *I, void *O, size_t len);
void spritz_cipher_decrypt (spritz_state *s, const void *I, void *O, size_t len);

/*******************************************************************************/
/* the spritz-xor cipher */

/* no IV is used if IV_len == 0 */
static void spritz_cipher_xor_init  (spritz_state *s, const void *K, size_t K_len, const void *IV, size_t IV_len);

/* can be called multiple times/incrementally */
/* can work inplace */
/* works for both encryption and decryption */
       void spritz_cipher_xor_crypt (spritz_state *s, const void *I, void *O, size_t len);

/*******************************************************************************/
/* the spritz hash */

static void spritz_hash_init   (spritz_state *s);
static void spritz_hash_add    (spritz_state *s, const void *M, size_t M_len); /* can be called multiple times/incrementally */
       void spritz_hash_finish (spritz_state *s, void *H, size_t H_len); /* must be called at most once at the end */

/*******************************************************************************/
/* the spritz MAC */

       void spritz_mac_init   (spritz_state *s, const void *K, size_t K_len);
static void spritz_mac_add    (spritz_state *s, const void *M, size_t M_len); /* can be called multiple times/incrementally */
static void spritz_mac_finish (spritz_state *s, void *H, size_t H_len); /* must be called at most once at the end */

/*******************************************************************************/
/* spritz authenticated encryption */

static void spritz_aead_init            (spritz_state *s, const void *K, size_t K_len);
static void spritz_aead_nonce           (spritz_state *s, const void *N, size_t N_len); /* must be called after construction, before associated_data */
static void spritz_aead_associated_data (spritz_state *s, const void *D, size_t D_len); /* must be called after nonce, before crypt */
       void spritz_aead_encrypt         (spritz_state *s, const void *I, void *O, size_t len);
       void spritz_aead_decrypt         (spritz_state *s, const void *I, void *O, size_t len);
/* must be called after associated_data, only once, before finish */
/* works for both encryption and decryption */
static void spritz_aead_finish          (spritz_state *s, void *H, size_t H_len); /* must be called at most once at the end */

/*******************************************************************************/
/* spritz authenticated encryption (xor variant) */

static void spritz_aead_xor_init            (spritz_state *s, const void *K, size_t K_len);
static void spritz_aead_xor_nonce           (spritz_state *s, const void *N, size_t N_len); /* must be called after construction, before associated_data */
static void spritz_aead_xor_associated_data (spritz_state *s, const void *D, size_t D_len); /* must be called after nonce, before crypt */
       void spritz_aead_xor_crypt           (spritz_state *s, const void *I, void *O, size_t len);
/* must be called after associated_data, only once, before finish */
/* works for both encryption and decryption */
static void spritz_aead_xor_finish          (spritz_state *s, void *H, size_t H_len); /* must be called at most once at the end */

/*******************************************************************************/
/* the spritz drbg/csprng */

/* constructor takes a seed if S_len != 0, same as spritz_prng_add */
       void spritz_prng_init (spritz_state *s, const void *S, size_t S_len);
static void spritz_prng_add  (spritz_state *s, const void *S, size_t S_len); /* add additional entropy */
static void spritz_prng_get  (spritz_state *s, void *R, size_t R_len); /* get random bytes */

/*******************************************************************************/
/* inline functions - some functions are so simple, they are defined inline */

/* the spritz-xor cipher inline functions */

static void
spritz_cipher_xor_init (spritz_state *s, const void *K, size_t K_len, const void *IV, size_t IV_len)
{
  spritz_cipher_init (s, K, K_len, IV, IV_len);
}

/* the spritz hash inline functions */

static void
spritz_hash_init (spritz_state *s)
{
  spritz_init (s);
}

static void
spritz_hash_add (spritz_state *s, const void *M, size_t M_len)
{
  spritz_absorb (s, M, M_len);
}

/* the spritz MAC inline functions */

static void
spritz_mac_add (spritz_state *s, const void *M, size_t M_len)
{
  spritz_hash_add (s, M, M_len);
}

static void
spritz_mac_finish (spritz_state *s, void *H, size_t H_len)
{
  spritz_hash_finish (s, H, H_len);
}

/* spritz authenticated encryption inline functions */

static void
spritz_aead_init (spritz_state *s, const void *K, size_t K_len)
{
  spritz_mac_init (s, K, K_len);
}

static void
spritz_aead_nonce (spritz_state *s, const void *N, size_t N_len)
{
  spritz_absorb_and_stop (s, N, N_len);
}

static void
spritz_aead_associated_data (spritz_state *s, const void *D, size_t D_len)
{
  spritz_absorb_and_stop (s, D, D_len);
}

static void
spritz_aead_finish (spritz_state *s, void *H, size_t H_len)
{
  spritz_mac_finish (s, H, H_len);
}

/* spritz authenticated encryption (xor variant) inline functions */

static void
spritz_aead_xor_init (spritz_state *s, const void *K, size_t K_len)
{
  spritz_mac_init (s, K, K_len);
}

static void
spritz_aead_xor_nonce (spritz_state *s, const void *N, size_t N_len)
{
  spritz_absorb_and_stop (s, N, N_len);
}

static void
spritz_aead_xor_associated_data (spritz_state *s, const void *D, size_t D_len)
{
  spritz_absorb_and_stop (s, D, D_len);
}

static void
spritz_aead_xor_finish (spritz_state *s, void *H, size_t H_len)
{
  spritz_mac_finish (s, H, H_len);
}

/* the spritz drbg/csprng inline functions */

static void
spritz_prng_add (spritz_state *s, const void *S, size_t S_len)
{
  spritz_absorb (s, S, S_len);
}

/* get random bytes */
static void
spritz_prng_get (spritz_state *s, void *R, size_t R_len)
{
  spritz_squeeze (s, R, R_len);
}

#endif

