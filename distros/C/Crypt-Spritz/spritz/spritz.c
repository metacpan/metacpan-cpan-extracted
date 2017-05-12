/* spritz.c, spritz C implementation
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

#include "spritz.h"

#include <assert.h>

/*****************************************************************************/

#define SPRITZ_SWAP(a,b) { uint8_t ss_c = (a); (a) = (b); (b) = ss_c; }

void
spritz_init (spritz_state *s)
{
  s->a =
  s->i =
  s->j =
  s->k =
  s->z = 0;
  s->w = 1;

  uint_fast8_t v = spritz_N - 1;
  do
    s->S[v] = v;
  while (v--);
}

void
spritz_update (spritz_state *s)
{
  s->i = s->i + s->w;
  s->j = s->k + s->S[(uint8_t)(s->j + s->S[s->i])];
  s->k = s->k + s->i + s->S[s->j];
  SPRITZ_SWAP (s->S[s->i], s->S[s->j]);
}

void
spritz_whip (spritz_state *s, uint_fast16_t r)
{
  while (r--)
    spritz_update (s);

  s->w += 2;
}

void
spritz_crush (spritz_state *s)
{
  uint_fast16_t v;

  for (v = 0; v < (spritz_N >> 1); ++v)
    if (s->S[v] > s->S[spritz_N - 1 - v])
      SPRITZ_SWAP (s->S[v], s->S[spritz_N - 1 - v]);
}

void
spritz_shuffle (spritz_state *s)
{
  spritz_whip (s, 2 * spritz_N); spritz_crush (s);
  spritz_whip (s, 2 * spritz_N); spritz_crush (s);
  spritz_whip (s, 2 * spritz_N);

  s->a = 0;
}

static void
spritz_shuffle_absorb (spritz_state *s)
{
  if (s->a == (spritz_N >> 1))
    spritz_shuffle (s);
}

static void
spritz_absorb_nibble (spritz_state *s, uint8_t x)
{
  spritz_shuffle_absorb (s);

  SPRITZ_SWAP (s->S[s->a], s->S[(uint8_t)((spritz_N >> 1) + x)]);
  ++s->a;
}

static void
spritz_absorb_byte (spritz_state *s, uint8_t b)
{
  spritz_absorb_nibble (s, b & 15);
  spritz_absorb_nibble (s, b >> 4);
}

void
spritz_absorb (spritz_state *s, const void *I, size_t I_len)
{
  uint8_t *i = (uint8_t *)I;

  while (I_len--)
    spritz_absorb_byte (s, *i++);
}

void
spritz_absorb_stop (spritz_state *s)
{
  spritz_shuffle_absorb (s);

  ++s->a;
}

void
spritz_absorb_and_stop (spritz_state *s, const void *I, size_t I_len)
{
  spritz_absorb (s, I, I_len);
  spritz_absorb_stop (s);
}

static void
spritz_shuffle_squeeze (spritz_state *s)
{
  if (s->a)
    spritz_shuffle (s);
}

uint8_t
spritz_output (spritz_state *s)
{
  uint8_t r = s->z + s->k;

  r = s->i + s->S[r];
  r = s->j + s->S[r];

  return s->z = s->S[r];
}

/* slightly faster internal helper, drip without squeeze preparation */
static uint8_t
spritz_drip_nosqueeze (spritz_state *s)
{
  spritz_update (s);
  return spritz_output (s);
}

void
spritz_squeeze (spritz_state *s, void *P, size_t P_len)
{
  spritz_shuffle_squeeze (s);

  uint8_t *p = (uint8_t *)P;

  while (P_len--)
    *p++ = spritz_drip_nosqueeze (s);
}

uint8_t
spritz_drip (spritz_state *s)
{
  spritz_shuffle_squeeze (s);

  return spritz_drip_nosqueeze (s);
}

/*****************************************************************************/

void
spritz_cipher_init (spritz_state *s, const void *K, size_t K_len, const void *IV, size_t IV_len)
{
  spritz_init (s);

  spritz_absorb (s, K, K_len);

  if (IV)
    {
      spritz_absorb_stop (s);
      spritz_absorb (s, IV, IV_len);
    }

  spritz_shuffle_squeeze (s);
}

void
spritz_cipher_encrypt (spritz_state *s, const void *I, void *O, size_t len)
{
  const uint8_t *i = (const uint8_t *)I;
        uint8_t *o = (      uint8_t *)O;

  while (len--)
    *o++ = *i++ + spritz_drip_nosqueeze (s);
}

void
spritz_cipher_decrypt (spritz_state *s, const void *I, void *O, size_t len)
{
  const uint8_t *i = (const uint8_t *)I;
        uint8_t *o = (      uint8_t *)O;

  while (len--)
    *o++ = *i++ - spritz_drip_nosqueeze (s);
}

/*****************************************************************************/

void
spritz_cipher_xor_crypt (spritz_state *s, const void *I, void *O, size_t len)
{
  const uint8_t *i = (const uint8_t *)I;
        uint8_t *o = (      uint8_t *)O;

  while (len--)
    *o++ = *i++ ^ spritz_drip_nosqueeze (s);
}

/*****************************************************************************/

void
spritz_hash_finish (spritz_state *s, void *H, size_t H_len)
{
  spritz_absorb_stop (s);
  assert (H_len <= 0xff);
  spritz_absorb_byte (s, H_len);

  spritz_squeeze (s, H, H_len);
}

/*****************************************************************************/

void
spritz_mac_init (spritz_state *s, const void *K, size_t K_len)
{
  spritz_init (s);
  spritz_absorb_and_stop (s, K, K_len);
}

/*****************************************************************************/

void
spritz_aead_encrypt (spritz_state *s, const void *I, void *O, size_t len)
{
  const uint8_t *i = (const uint8_t *)I;
        uint8_t *o = (      uint8_t *)O;

  while (len)
    {
      uint_fast8_t j;
      uint8_t x[spritz_aead_blocksize];
      uint8_t l = len > sizeof (x) ? sizeof (x) : len;
      len -= l;

      spritz_squeeze (s, x, l);

      for (j = 0; j < l; ++j)
        {
          *o = *i++ + x[j];
          spritz_absorb_byte (s, *o);
          ++o;
        }
    }
}

void
spritz_aead_decrypt (spritz_state *s, const void *I, void *O, size_t len)
{
  const uint8_t *i = (const uint8_t *)I;
        uint8_t *o = (      uint8_t *)O;

  while (len)
    {
      uint_fast8_t j;
      uint8_t x[spritz_aead_blocksize];
      uint8_t l = len > sizeof (x) ? sizeof (x) : len;
      len -= l;

      spritz_squeeze (s, x, l);

      for (j = 0; j < l; ++j)
        {
          spritz_absorb_byte (s, *i);
          *o = *i++ - x[j];
          ++o;
        }
    }
}

/*****************************************************************************/

void
spritz_aead_xor_crypt (spritz_state *s, const void *I, void *O, size_t len)
{
  const uint8_t *i = (const uint8_t *)I;
        uint8_t *o = (      uint8_t *)O;

  while (len)
    {
      uint_fast8_t j;
      uint8_t x[spritz_aead_blocksize];
      uint8_t l = len > sizeof (x) ? sizeof (x) : len;
      len -= l;

      spritz_squeeze (s, x, l);

      for (j = 0; j < l; ++j)
        spritz_absorb_byte (s, *o++ = *i++ ^ x[j]);
    }
}

/*****************************************************************************/

void
spritz_prng_init (spritz_state *s, const void *S, size_t S_len)
{
  spritz_init (s);
  spritz_absorb (s, S, S_len);
}

