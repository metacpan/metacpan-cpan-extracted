#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xs/openssl.h"


MODULE = Crypt::Keyczar		PACKAGE = Crypt::Keyczar

INCLUDE: xs/openssl/Util.xst
INCLUDE: xs/openssl/AesEngine.xst
INCLUDE: xs/openssl/HmacEngine.xst
INCLUDE: xs/openssl/RsaPrivateKeyEngine.xst
INCLUDE: xs/openssl/RsaPublicKeyEngine.xst
INCLUDE: xs/openssl/DsaPrivateKeyEngine.xst
INCLUDE: xs/openssl/DsaPublicKeyEngine.xst
