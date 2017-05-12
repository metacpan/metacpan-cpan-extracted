#include <stddef.h>
#include <string.h>
typedef unsigned char des_cblock[8];

void
des_fcrypt(
	const char *password,
	size_t passwordlen,
	const char *salt,
	size_t saltlen,
	char *outbuf);

void
crypt_rounds(
	des_cblock key,
	unsigned long nrounds,
	unsigned long saltnum,
	des_cblock block);

void
trad_password_to_key(
	des_cblock key,
	const char *password,
	size_t passwordlen);

void
ext_password_to_key(
	des_cblock key,
	const char *password,
	size_t passwordlen);

void
base64_to_block(
	des_cblock block,
	const char *base64);

void
block_to_base64(
	des_cblock block,
	char *base64);

void
int24_to_base64(
	unsigned long val,
	char *base64);

unsigned long
base64_to_int24(
	const char *base64);

void
int12_to_base64(
	unsigned long val,
	char *base64);

unsigned long
base64_to_int12(
	const char *base64);
