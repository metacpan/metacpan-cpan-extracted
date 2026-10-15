#ifndef YESCRYPT_CRYPT_H
#define YESCRYPT_CRYPT_H

#include <stddef.h>

/* "$y$", up to 8 params, '$', salt (<= 86 chars), '$', hash (43), NUL: < 256 */
#define CPX_YESCRYPT_BUFLEN 256

/*
 * Returns the full "$y$..." hash of key, or "" if the setting is malformed,
 * is not a "$y$" setting, or fails cpx_yescrypt_check_params() (over the
 * memory-times-passes budget, r > 32, p > 1, a ROM or a hash upgrade g).
 * The result is written to buf (buflen bytes, normally CPX_YESCRYPT_BUFLEN) and
 * buf is returned, so concurrent callers with their own buffers do not collide.
 * Returns NULL, writing nothing, if buflen is 0.
 */
char *cpx_yescrypt_crypt (const char *key, const char *salt, char *buf, size_t buflen);

#endif /* YESCRYPT_CRYPT_H */
