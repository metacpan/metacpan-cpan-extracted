/* LibTomCrypt, modular cryptographic library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#include "tomcrypt_private.h"

/**
  @file crypt_register_all_ciphers.c

  Steffen Jaeckel
*/

#define REGISTER_CIPHER(h) do {\
   LTC_ARGCHK(register_cipher(h) != -1); \
} while(0)

int register_all_ciphers(void)
{
#ifdef LTC_RIJNDAEL
   /* `aesni_desc` is explicitely not registered, since it's handled from within the `aes_desc` */
#ifdef ENCRYPT_ONLY
   /* alternative would be
    * register_cipher(&rijndael_enc_desc);
    */
   REGISTER_CIPHER(&aes_enc_desc);
#else
   /* alternative would be
    * register_cipher(&rijndael_desc);
    */
   REGISTER_CIPHER(&aes_desc);
#endif
#endif
#ifdef LTC_BLOWFISH
   REGISTER_CIPHER(&blowfish_desc);
#endif
#ifdef LTC_XTEA
   REGISTER_CIPHER(&xtea_desc);
#endif
#ifdef LTC_RC5
   REGISTER_CIPHER(&rc5_desc);
#endif
#ifdef LTC_RC6
   REGISTER_CIPHER(&rc6_desc);
#endif
#ifdef LTC_SAFERP
   REGISTER_CIPHER(&saferp_desc);
#endif
#ifdef LTC_TWOFISH
   REGISTER_CIPHER(&twofish_desc);
#endif
#ifdef LTC_SAFER
   REGISTER_CIPHER(&safer_k64_desc);
   REGISTER_CIPHER(&safer_sk64_desc);
   REGISTER_CIPHER(&safer_k128_desc);
   REGISTER_CIPHER(&safer_sk128_desc);
#endif
#ifdef LTC_RC2
   REGISTER_CIPHER(&rc2_desc);
#endif
#ifdef LTC_DES
   REGISTER_CIPHER(&des_desc);
   REGISTER_CIPHER(&desx_desc);
   REGISTER_CIPHER(&des3_desc);
#endif
#ifdef LTC_SM4
   REGISTER_CIPHER(&sm4_desc);
#endif
#ifdef LTC_CAST5
   REGISTER_CIPHER(&cast5_desc);
#endif
#ifdef LTC_NOEKEON
   REGISTER_CIPHER(&noekeon_desc);
#endif
#ifdef LTC_SKIPJACK
   REGISTER_CIPHER(&skipjack_desc);
#endif
#ifdef LTC_ANUBIS
   REGISTER_CIPHER(&anubis_desc);
#endif
#ifdef LTC_KHAZAD
   REGISTER_CIPHER(&khazad_desc);
#endif
#ifdef LTC_KSEED
   REGISTER_CIPHER(&kseed_desc);
#endif
#ifdef LTC_KASUMI
   REGISTER_CIPHER(&kasumi_desc);
#endif
#ifdef LTC_MULTI2
   REGISTER_CIPHER(&multi2_desc);
#endif
#ifdef LTC_CAMELLIA
   REGISTER_CIPHER(&camellia_desc);
#endif
#ifdef LTC_IDEA
   REGISTER_CIPHER(&idea_desc);
#endif
#ifdef LTC_SERPENT
   REGISTER_CIPHER(&serpent_desc);
#endif
#ifdef LTC_TEA
   REGISTER_CIPHER(&tea_desc);
#endif
   return CRYPT_OK;
}
