/*
 * cpx: Symbol isolation for the vendored yescrypt sources.
 *
 * Every external symbol of the vendored files is renamed with a cpx_ prefix so
 * it cannot collide with libxcrypt, libcperciva, OpenSSL or any other library
 * loaded into the same perl process.  Included first by each vendored .c file
 * and by yescrypt.h.  The list comes from `nm -g` of the compiled objects.
 */
#ifndef CPX_YESCRYPT_NAMES_H
#define CPX_YESCRYPT_NAMES_H

/* yescrypt.h / yescrypt-common.c / yescrypt-opt.c */
#define crypto_scrypt cpx_crypto_scrypt
#define yescrypt cpx_yescrypt
#define yescrypt_r cpx_yescrypt_r
#define yescrypt_kdf cpx_yescrypt_kdf
#define yescrypt_reencrypt cpx_yescrypt_reencrypt
#define yescrypt_encode_params cpx_yescrypt_encode_params
#define yescrypt_encode_params_r cpx_yescrypt_encode_params_r
#define yescrypt_init_local cpx_yescrypt_init_local
#define yescrypt_free_local cpx_yescrypt_free_local
#define yescrypt_init_shared cpx_yescrypt_init_shared
#define yescrypt_free_shared cpx_yescrypt_free_shared
#define yescrypt_digest_shared cpx_yescrypt_digest_shared

/* sha256.h already maps SHA256_* to libcperciva_SHA256_*; move those too */
#define libcperciva_SHA256_Init cpx_SHA256_Init
#define libcperciva_SHA256_Update cpx_SHA256_Update
#define libcperciva_SHA256_Final cpx_SHA256_Final
#define libcperciva_SHA256_Buf cpx_SHA256_Buf
#define libcperciva_HMAC_SHA256_Init cpx_HMAC_SHA256_Init
#define libcperciva_HMAC_SHA256_Update cpx_HMAC_SHA256_Update
#define libcperciva_HMAC_SHA256_Final cpx_HMAC_SHA256_Final
#define libcperciva_HMAC_SHA256_Buf cpx_HMAC_SHA256_Buf
#define PBKDF2_SHA256 cpx_PBKDF2_SHA256

/* insecure_memzero.c */
#define insecure_memzero_ptr cpx_insecure_memzero_ptr

#endif /* !CPX_YESCRYPT_NAMES_H */
