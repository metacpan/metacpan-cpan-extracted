#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include "ppport.h" */

#include "camellia-GPL-1.2.0/camellia.h"
#include "camellia-GPL-1.2.0/camellia.c"

static KEY_TABLE_TYPE keyTable;

SV *keygen(char *key, int keysize){
    SV * retval;
    KEY_TABLE_TYPE keyTable;
    Camellia_Ekeygen(keysize, (U8 *)key, keyTable);
    retval = newSVpv((char *)keyTable, sizeof(keyTable));
    return retval;
}

SV *_enc(SV* src, SV *table, int keysize){
    U8 buf[16];
    SvGROW(src, 16);
    Camellia_EncryptBlock(keysize, (U8 *)SvPV_nolen(src),
			  (unsigned int *)SvPV_nolen(table), buf);
    return newSVpv((char *)buf, 16);
}

SV *_dec(SV* src, SV *table, int keysize){
    U8 buf[16];
    SvGROW(src, 16);
    Camellia_DecryptBlock(keysize, (U8 *)SvPV_nolen(src),
			  (unsigned int *)SvPV_nolen(table), buf);
    return newSVpv((char *)buf, 16);
}

MODULE = Crypt::Camellia PACKAGE = Crypt::Camellia		

SV *
keygen(key, keysize)
    char *key
    int  keysize
CODE:
    RETVAL = keygen(key, keysize);
OUTPUT:
    RETVAL

SV *
crypt(src, table, keysize, direction)
    SV *src
    SV *table
    int keysize
    int direction
CODE:
    RETVAL = direction ? _enc(src, table, keysize)
                       : _dec(src, table, keysize);
OUTPUT:
    RETVAL

