/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <phk@login.dknet.dk> wrote this file.  As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.   Poul-Henning Kamp
 * ----------------------------------------------------------------------------
 *
 * $FreeBSD: src/lib/libcrypt/crypt-md5.c,v 1.5.2.1 2001/05/24 12:20:02 markm Exp $
 * $DragonFly: src/lib/libcrypt/crypt-md5.c,v 1.3 2005/08/04 17:27:09 drhodus Exp $
 */

#ifndef MD5CRYPT_H
#define MD5CRYPT_H

char *cpx_crypt_md5(const char *pw, const char *salt);
char *cpx_crypt_apr1(const char *pw, const char *salt);

#endif /* MD5CRYPT_H */
