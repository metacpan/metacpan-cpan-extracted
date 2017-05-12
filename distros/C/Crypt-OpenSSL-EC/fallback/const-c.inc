#include "ppport.h"
#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_KEY_COPY EC_F_EC_WNAF_MUL EC_R_WRONG_ORDER */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'E':
    if (memEQ(name, "EC_F_EC_KEY_COPY", 16)) {
    /*                        ^             */
#ifdef EC_F_EC_KEY_COPY
      *iv_return = EC_F_EC_KEY_COPY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "EC_R_WRONG_ORDER", 16)) {
    /*                        ^             */
#ifdef EC_R_WRONG_ORDER
      *iv_return = EC_R_WRONG_ORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_EC_WNAF_MUL", 16)) {
    /*                        ^             */
#ifdef EC_F_EC_WNAF_MUL
      *iv_return = EC_F_EC_WNAF_MUL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_COMPUTE_WNAF EC_F_EC_GROUP_NEW EC_F_EC_KEY_PRINT EC_F_EC_POINT_ADD
     EC_F_EC_POINT_CMP EC_F_EC_POINT_DBL EC_F_EC_POINT_MUL EC_F_EC_POINT_NEW
     EC_F_PKEY_EC_CTRL EC_F_PKEY_EC_SIGN EC_PKEY_NO_PUBKEY EC_R_DECODE_ERROR
     EC_R_INVALID_FORM EC_R_KEYS_NOT_SET EC_R_NO_FIELD_MOD */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "EC_F_EC_POINT_ADD", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_POINT_ADD
      *iv_return = EC_F_EC_POINT_ADD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "EC_F_EC_POINT_CMP", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_POINT_CMP
      *iv_return = EC_F_EC_POINT_CMP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "EC_F_EC_POINT_DBL", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_POINT_DBL
      *iv_return = EC_F_EC_POINT_DBL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_EC_KEY_PRINT", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_KEY_PRINT
      *iv_return = EC_F_EC_KEY_PRINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_PKEY_EC_SIGN", 17)) {
    /*                             ^         */
#ifdef EC_F_PKEY_EC_SIGN
      *iv_return = EC_F_PKEY_EC_SIGN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "EC_PKEY_NO_PUBKEY", 17)) {
    /*                             ^         */
#ifdef EC_PKEY_NO_PUBKEY
      *iv_return = EC_PKEY_NO_PUBKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "EC_F_EC_POINT_MUL", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_POINT_MUL
      *iv_return = EC_F_EC_POINT_MUL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_R_NO_FIELD_MOD", 17)) {
    /*                             ^         */
#ifdef EC_R_NO_FIELD_MOD
      *iv_return = EC_R_NO_FIELD_MOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_COMPUTE_WNAF", 17)) {
    /*                             ^         */
#ifdef EC_F_COMPUTE_WNAF
      *iv_return = EC_F_COMPUTE_WNAF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_GROUP_NEW", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_GROUP_NEW
      *iv_return = EC_F_EC_GROUP_NEW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_POINT_NEW", 17)) {
    /*                             ^         */
#ifdef EC_F_EC_POINT_NEW
      *iv_return = EC_F_EC_POINT_NEW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EC_R_INVALID_FORM", 17)) {
    /*                             ^         */
#ifdef EC_R_INVALID_FORM
      *iv_return = EC_R_INVALID_FORM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_R_DECODE_ERROR", 17)) {
    /*                             ^         */
#ifdef EC_R_DECODE_ERROR
      *iv_return = EC_R_DECODE_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_R_KEYS_NOT_SET", 17)) {
    /*                             ^         */
#ifdef EC_R_KEYS_NOT_SET
      *iv_return = EC_R_KEYS_NOT_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EC_F_PKEY_EC_CTRL", 17)) {
    /*                             ^         */
#ifdef EC_F_PKEY_EC_CTRL
      *iv_return = EC_F_PKEY_EC_CTRL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GROUP_COPY EC_F_EC_POINT_COPY EC_R_INVALID_CURVE
     EC_R_INVALID_FIELD EC_R_UNKNOWN_GROUP EC_R_UNKNOWN_ORDER */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'E':
    if (memEQ(name, "EC_R_UNKNOWN_ORDER", 18)) {
    /*                               ^        */
#ifdef EC_R_UNKNOWN_ORDER
      *iv_return = EC_R_UNKNOWN_ORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EC_R_INVALID_FIELD", 18)) {
    /*                               ^        */
#ifdef EC_R_INVALID_FIELD
      *iv_return = EC_R_INVALID_FIELD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EC_F_EC_GROUP_COPY", 18)) {
    /*                               ^        */
#ifdef EC_F_EC_GROUP_COPY
      *iv_return = EC_F_EC_GROUP_COPY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_POINT_COPY", 18)) {
    /*                               ^        */
#ifdef EC_F_EC_POINT_COPY
      *iv_return = EC_F_EC_POINT_COPY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EC_R_UNKNOWN_GROUP", 18)) {
    /*                               ^        */
#ifdef EC_R_UNKNOWN_GROUP
      *iv_return = EC_R_UNKNOWN_GROUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "EC_R_INVALID_CURVE", 18)) {
    /*                               ^        */
#ifdef EC_R_INVALID_CURVE
      *iv_return = EC_R_INVALID_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GROUP_CHECK EC_F_PKEY_EC_DERIVE EC_F_PKEY_EC_KEYGEN */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'E':
    if (memEQ(name, "EC_F_EC_GROUP_CHECK", 19)) {
    /*                               ^         */
#ifdef EC_F_EC_GROUP_CHECK
      *iv_return = EC_F_EC_GROUP_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "EC_F_PKEY_EC_KEYGEN", 19)) {
    /*                               ^         */
#ifdef EC_F_PKEY_EC_KEYGEN
      *iv_return = EC_F_PKEY_EC_KEYGEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_PKEY_EC_DERIVE", 19)) {
    /*                               ^         */
#ifdef EC_F_PKEY_EC_DERIVE
      *iv_return = EC_F_PKEY_EC_DERIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_DO_EC_KEY_PRINT EC_F_EC_KEY_PRINT_FP EC_F_EC_POINT_INVERT
     EC_F_EC_PRE_COMP_DUP EC_F_EC_PRE_COMP_NEW EC_F_I2O_ECPUBLICKEY
     EC_F_O2I_ECPUBLICKEY EC_R_FIELD_TOO_LARGE EC_R_NOT_IMPLEMENTED
     EC_R_NOT_INITIALIZED EC_R_UNDEFINED_ORDER */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'D':
    if (memEQ(name, "EC_F_EC_PRE_COMP_DUP", 20)) {
    /*                                ^         */
#ifdef EC_F_EC_PRE_COMP_DUP
      *iv_return = EC_F_EC_PRE_COMP_DUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_R_UNDEFINED_ORDER", 20)) {
    /*                                ^         */
#ifdef EC_R_UNDEFINED_ORDER
      *iv_return = EC_R_UNDEFINED_ORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EC_F_EC_POINT_INVERT", 20)) {
    /*                                ^         */
#ifdef EC_F_EC_POINT_INVERT
      *iv_return = EC_F_EC_POINT_INVERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_DO_EC_KEY_PRINT", 20)) {
    /*                                ^         */
#ifdef EC_F_DO_EC_KEY_PRINT
      *iv_return = EC_F_DO_EC_KEY_PRINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "EC_F_I2O_ECPUBLICKEY", 20)) {
    /*                                ^         */
#ifdef EC_F_I2O_ECPUBLICKEY
      *iv_return = EC_F_I2O_ECPUBLICKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_O2I_ECPUBLICKEY", 20)) {
    /*                                ^         */
#ifdef EC_F_O2I_ECPUBLICKEY
      *iv_return = EC_F_O2I_ECPUBLICKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_EC_PRE_COMP_NEW", 20)) {
    /*                                ^         */
#ifdef EC_F_EC_PRE_COMP_NEW
      *iv_return = EC_F_EC_PRE_COMP_NEW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_R_FIELD_TOO_LARGE", 20)) {
    /*                                ^         */
#ifdef EC_R_FIELD_TOO_LARGE
      *iv_return = EC_R_FIELD_TOO_LARGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EC_R_NOT_IMPLEMENTED", 20)) {
    /*                                ^         */
#ifdef EC_R_NOT_IMPLEMENTED
      *iv_return = EC_R_NOT_IMPLEMENTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "EC_R_NOT_INITIALIZED", 20)) {
    /*                                ^         */
#ifdef EC_R_NOT_INITIALIZED
      *iv_return = EC_R_NOT_INITIALIZED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "EC_F_EC_KEY_PRINT_FP", 20)) {
    /*                                ^         */
#ifdef EC_F_EC_KEY_PRINT_FP
      *iv_return = EC_F_EC_KEY_PRINT_FP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_D2I_ECPARAMETERS EC_F_D2I_ECPRIVATEKEY EC_F_ECKEY_PARAM2TYPE
     EC_F_ECKEY_PUB_DECODE EC_F_ECKEY_PUB_ENCODE EC_F_ECKEY_TYPE2PARAM
     EC_F_ECP_NIST_MOD_192 EC_F_ECP_NIST_MOD_224 EC_F_ECP_NIST_MOD_256
     EC_F_ECP_NIST_MOD_521 EC_F_EC_KEY_CHECK_KEY EC_F_I2D_ECPARAMETERS
     EC_F_I2D_ECPRIVATEKEY EC_F_PKEY_EC_CTRL_STR EC_F_PKEY_EC_PARAMGEN
     EC_PKEY_NO_PARAMETERS EC_R_BUFFER_TOO_SMALL EC_R_INVALID_ARGUMENT
     EC_R_INVALID_ENCODING EC_R_NOT_A_NIST_PRIME */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case '1':
    if (memEQ(name, "EC_F_ECP_NIST_MOD_52", 20)) {
    /*                                   1      */
#ifdef EC_F_ECP_NIST_MOD_521
      *iv_return = EC_F_ECP_NIST_MOD_521;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "EC_F_ECP_NIST_MOD_19", 20)) {
    /*                                   2      */
#ifdef EC_F_ECP_NIST_MOD_192
      *iv_return = EC_F_ECP_NIST_MOD_192;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "EC_F_ECP_NIST_MOD_22", 20)) {
    /*                                   4      */
#ifdef EC_F_ECP_NIST_MOD_224
      *iv_return = EC_F_ECP_NIST_MOD_224;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "EC_F_ECP_NIST_MOD_25", 20)) {
    /*                                   6      */
#ifdef EC_F_ECP_NIST_MOD_256
      *iv_return = EC_F_ECP_NIST_MOD_256;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EC_F_ECKEY_PARAM2TYP", 20)) {
    /*                                   E      */
#ifdef EC_F_ECKEY_PARAM2TYPE
      *iv_return = EC_F_ECKEY_PARAM2TYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_ECKEY_PUB_DECOD", 20)) {
    /*                                   E      */
#ifdef EC_F_ECKEY_PUB_DECODE
      *iv_return = EC_F_ECKEY_PUB_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_ECKEY_PUB_ENCOD", 20)) {
    /*                                   E      */
#ifdef EC_F_ECKEY_PUB_ENCODE
      *iv_return = EC_F_ECKEY_PUB_ENCODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_R_NOT_A_NIST_PRIM", 20)) {
    /*                                   E      */
#ifdef EC_R_NOT_A_NIST_PRIME
      *iv_return = EC_R_NOT_A_NIST_PRIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "EC_R_INVALID_ENCODIN", 20)) {
    /*                                   G      */
#ifdef EC_R_INVALID_ENCODING
      *iv_return = EC_R_INVALID_ENCODING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EC_R_BUFFER_TOO_SMAL", 20)) {
    /*                                   L      */
#ifdef EC_R_BUFFER_TOO_SMALL
      *iv_return = EC_R_BUFFER_TOO_SMALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "EC_F_ECKEY_TYPE2PARA", 20)) {
    /*                                   M      */
#ifdef EC_F_ECKEY_TYPE2PARAM
      *iv_return = EC_F_ECKEY_TYPE2PARAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_PKEY_EC_PARAMGE", 20)) {
    /*                                   N      */
#ifdef EC_F_PKEY_EC_PARAMGEN
      *iv_return = EC_F_PKEY_EC_PARAMGEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_F_PKEY_EC_CTRL_ST", 20)) {
    /*                                   R      */
#ifdef EC_F_PKEY_EC_CTRL_STR
      *iv_return = EC_F_PKEY_EC_CTRL_STR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_F_D2I_ECPARAMETER", 20)) {
    /*                                   S      */
#ifdef EC_F_D2I_ECPARAMETERS
      *iv_return = EC_F_D2I_ECPARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_I2D_ECPARAMETER", 20)) {
    /*                                   S      */
#ifdef EC_F_I2D_ECPARAMETERS
      *iv_return = EC_F_I2D_ECPARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_PKEY_NO_PARAMETER", 20)) {
    /*                                   S      */
#ifdef EC_PKEY_NO_PARAMETERS
      *iv_return = EC_PKEY_NO_PARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EC_R_INVALID_ARGUMEN", 20)) {
    /*                                   T      */
#ifdef EC_R_INVALID_ARGUMENT
      *iv_return = EC_R_INVALID_ARGUMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "EC_F_D2I_ECPRIVATEKE", 20)) {
    /*                                   Y      */
#ifdef EC_F_D2I_ECPRIVATEKEY
      *iv_return = EC_F_D2I_ECPRIVATEKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_KEY_CHECK_KE", 20)) {
    /*                                   Y      */
#ifdef EC_F_EC_KEY_CHECK_KEY
      *iv_return = EC_F_EC_KEY_CHECK_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_I2D_ECPRIVATEKE", 20)) {
    /*                                   Y      */
#ifdef EC_F_I2D_ECPRIVATEKEY
      *iv_return = EC_F_I2D_ECPRIVATEKEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_ECKEY_PRIV_DECODE EC_F_ECKEY_PRIV_ENCODE EC_R_NO_PARAMETERS_SET
     EC_R_POINT_AT_INFINITY EC_R_UNSUPPORTED_FIELD OPENSSL_EC_NAMED_CURVE */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'C':
    if (memEQ(name, "OPENSSL_EC_NAMED_CURVE", 22)) {
    /*                                ^           */
#ifdef OPENSSL_EC_NAMED_CURVE
      *iv_return = OPENSSL_EC_NAMED_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EC_F_ECKEY_PRIV_DECODE", 22)) {
    /*                                ^           */
#ifdef EC_F_ECKEY_PRIV_DECODE
      *iv_return = EC_F_ECKEY_PRIV_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "EC_R_UNSUPPORTED_FIELD", 22)) {
    /*                                ^           */
#ifdef EC_R_UNSUPPORTED_FIELD
      *iv_return = EC_R_UNSUPPORTED_FIELD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_R_POINT_AT_INFINITY", 22)) {
    /*                                ^           */
#ifdef EC_R_POINT_AT_INFINITY
      *iv_return = EC_R_POINT_AT_INFINITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_ECKEY_PRIV_ENCODE", 22)) {
    /*                                ^           */
#ifdef EC_F_ECKEY_PRIV_ENCODE
      *iv_return = EC_F_ECKEY_PRIV_ENCODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_R_NO_PARAMETERS_SET", 22)) {
    /*                                ^           */
#ifdef EC_R_NO_PARAMETERS_SET
      *iv_return = EC_R_NO_PARAMETERS_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_D2I_ECPKPARAMETERS EC_F_ECKEY_PARAM_DECODE EC_F_ECPARAMETERS_PRINT
     EC_F_EC_GROUP_GET_ORDER EC_F_EC_POINT_OCT2POINT EC_F_EC_POINT_POINT2OCT
     EC_F_I2D_ECPKPARAMETERS EC_F_OLD_EC_PRIV_DECODE EC_R_ASN1_UNKNOWN_FIELD
     EC_R_MISSING_PARAMETERS POINT_CONVERSION_HYBRID */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'D':
    if (memEQ(name, "EC_F_I2D_ECPKPARAMETERS", 23)) {
    /*                      ^                      */
#ifdef EC_F_I2D_ECPKPARAMETERS
      *iv_return = EC_F_I2D_ECPKPARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_OLD_EC_PRIV_DECODE", 23)) {
    /*                      ^                      */
#ifdef EC_F_OLD_EC_PRIV_DECODE
      *iv_return = EC_F_OLD_EC_PRIV_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_D2I_ECPKPARAMETERS", 23)) {
    /*                      ^                      */
#ifdef EC_F_D2I_ECPKPARAMETERS
      *iv_return = EC_F_D2I_ECPKPARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "EC_F_ECKEY_PARAM_DECODE", 23)) {
    /*                      ^                      */
#ifdef EC_F_ECKEY_PARAM_DECODE
      *iv_return = EC_F_ECKEY_PARAM_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_R_ASN1_UNKNOWN_FIELD", 23)) {
    /*                      ^                      */
#ifdef EC_R_ASN1_UNKNOWN_FIELD
      *iv_return = EC_R_ASN1_UNKNOWN_FIELD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "POINT_CONVERSION_HYBRID", 23)) {
    /*                      ^                      */
      *iv_return = POINT_CONVERSION_HYBRID;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EC_F_ECPARAMETERS_PRINT", 23)) {
    /*                      ^                      */
#ifdef EC_F_ECPARAMETERS_PRINT
      *iv_return = EC_F_ECPARAMETERS_PRINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_R_MISSING_PARAMETERS", 23)) {
    /*                      ^                      */
#ifdef EC_R_MISSING_PARAMETERS
      *iv_return = EC_R_MISSING_PARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "EC_F_EC_GROUP_GET_ORDER", 23)) {
    /*                      ^                      */
#ifdef EC_F_EC_GROUP_GET_ORDER
      *iv_return = EC_F_EC_GROUP_GET_ORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_POINT_OCT2POINT", 23)) {
    /*                      ^                      */
#ifdef EC_F_EC_POINT_OCT2POINT
      *iv_return = EC_F_EC_POINT_OCT2POINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_POINT_POINT2OCT", 23)) {
    /*                      ^                      */
#ifdef EC_F_EC_POINT_POINT2OCT
      *iv_return = EC_F_EC_POINT_POINT2OCT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_ASN1_GROUP2CURVE EC_F_EC_EX_DATA_SET_DATA EC_F_EC_GROUP_GET_DEGREE
     EC_F_EC_KEY_GENERATE_KEY EC_R_INVALID_DIGEST_TYPE EC_R_INVALID_GROUP_ORDER
     EC_R_INVALID_PRIVATE_KEY EC_R_MISSING_PRIVATE_KEY EC_R_UNDEFINED_GENERATOR
     */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'E':
    if (memEQ(name, "EC_F_EC_KEY_GENERATE_KEY", 24)) {
    /*                        ^                     */
#ifdef EC_F_EC_KEY_GENERATE_KEY
      *iv_return = EC_F_EC_KEY_GENERATE_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "EC_R_UNDEFINED_GENERATOR", 24)) {
    /*                        ^                     */
#ifdef EC_R_UNDEFINED_GENERATOR
      *iv_return = EC_R_UNDEFINED_GENERATOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_R_MISSING_PRIVATE_KEY", 24)) {
    /*                        ^                     */
#ifdef EC_R_MISSING_PRIVATE_KEY
      *iv_return = EC_R_MISSING_PRIVATE_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EC_R_INVALID_DIGEST_TYPE", 24)) {
    /*                        ^                     */
#ifdef EC_R_INVALID_DIGEST_TYPE
      *iv_return = EC_R_INVALID_DIGEST_TYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_R_INVALID_GROUP_ORDER", 24)) {
    /*                        ^                     */
#ifdef EC_R_INVALID_GROUP_ORDER
      *iv_return = EC_R_INVALID_GROUP_ORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_R_INVALID_PRIVATE_KEY", 24)) {
    /*                        ^                     */
#ifdef EC_R_INVALID_PRIVATE_KEY
      *iv_return = EC_R_INVALID_PRIVATE_KEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_F_EC_GROUP_GET_DEGREE", 24)) {
    /*                        ^                     */
#ifdef EC_F_EC_GROUP_GET_DEGREE
      *iv_return = EC_F_EC_GROUP_GET_DEGREE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_F_EC_ASN1_GROUP2CURVE", 24)) {
    /*                        ^                     */
#ifdef EC_F_EC_ASN1_GROUP2CURVE
      *iv_return = EC_F_EC_ASN1_GROUP2CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "EC_F_EC_EX_DATA_SET_DATA", 24)) {
    /*                        ^                     */
#ifdef EC_F_EC_EX_DATA_SET_DATA
      *iv_return = EC_F_EC_EX_DATA_SET_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_ECPKPARAMETERS_PRINT EC_F_EC_POINT_IS_ON_CURVE
     EC_F_EC_POINT_MAKE_AFFINE EC_R_DISCRIMINANT_IS_ZERO
     EC_R_INCOMPATIBLE_OBJECTS */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "EC_R_DISCRIMINANT_IS_ZERO", 25)) {
    /*                             ^                 */
#ifdef EC_R_DISCRIMINANT_IS_ZERO
      *iv_return = EC_R_DISCRIMINANT_IS_ZERO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "EC_R_INCOMPATIBLE_OBJECTS", 25)) {
    /*                             ^                 */
#ifdef EC_R_INCOMPATIBLE_OBJECTS
      *iv_return = EC_R_INCOMPATIBLE_OBJECTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EC_F_ECPKPARAMETERS_PRINT", 25)) {
    /*                             ^                 */
#ifdef EC_F_ECPKPARAMETERS_PRINT
      *iv_return = EC_F_ECPKPARAMETERS_PRINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_EC_POINT_IS_ON_CURVE", 25)) {
    /*                             ^                 */
#ifdef EC_F_EC_POINT_IS_ON_CURVE
      *iv_return = EC_F_EC_POINT_IS_ON_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "EC_F_EC_POINT_MAKE_AFFINE", 25)) {
    /*                             ^                 */
#ifdef EC_F_EC_POINT_MAKE_AFFINE
      *iv_return = EC_F_EC_POINT_MAKE_AFFINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_ECPARAMETERS_PRINT_FP EC_F_EC_ASN1_GROUP2FIELDID
     EC_F_EC_GFP_MONT_FIELD_MUL EC_F_EC_GFP_MONT_FIELD_SQR
     EC_F_EC_GFP_NIST_FIELD_MUL EC_F_EC_GFP_NIST_FIELD_SQR
     EC_F_EC_GROUP_GET_COFACTOR EC_F_EC_POINTS_MAKE_AFFINE
     EC_R_PASSED_NULL_PARAMETER EC_R_POINT_IS_NOT_ON_CURVE
     OPENSSL_ECC_MAX_FIELD_BITS */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case 'E':
    if (memEQ(name, "EC_R_PASSED_NULL_PARAMETER", 26)) {
    /*                                       ^        */
#ifdef EC_R_PASSED_NULL_PARAMETER
      *iv_return = EC_R_PASSED_NULL_PARAMETER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "EC_F_ECPARAMETERS_PRINT_FP", 26)) {
    /*                                       ^        */
#ifdef EC_F_ECPARAMETERS_PRINT_FP
      *iv_return = EC_F_ECPARAMETERS_PRINT_FP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_EC_ASN1_GROUP2FIELDID", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_ASN1_GROUP2FIELDID
      *iv_return = EC_F_EC_ASN1_GROUP2FIELDID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_EC_POINTS_MAKE_AFFINE", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_POINTS_MAKE_AFFINE
      *iv_return = EC_F_EC_POINTS_MAKE_AFFINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EC_F_EC_GROUP_GET_COFACTOR", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_GROUP_GET_COFACTOR
      *iv_return = EC_F_EC_GROUP_GET_COFACTOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "EC_F_EC_GFP_MONT_FIELD_SQR", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_GFP_MONT_FIELD_SQR
      *iv_return = EC_F_EC_GFP_MONT_FIELD_SQR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_GFP_NIST_FIELD_SQR", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_GFP_NIST_FIELD_SQR
      *iv_return = EC_F_EC_GFP_NIST_FIELD_SQR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "OPENSSL_ECC_MAX_FIELD_BITS", 26)) {
    /*                                       ^        */
#ifdef OPENSSL_ECC_MAX_FIELD_BITS
      *iv_return = OPENSSL_ECC_MAX_FIELD_BITS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EC_F_EC_GFP_MONT_FIELD_MUL", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_GFP_MONT_FIELD_MUL
      *iv_return = EC_F_EC_GFP_MONT_FIELD_MUL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_GFP_NIST_FIELD_MUL", 26)) {
    /*                                       ^        */
#ifdef EC_F_EC_GFP_NIST_FIELD_MUL
      *iv_return = EC_F_EC_GFP_NIST_FIELD_MUL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "EC_R_POINT_IS_NOT_ON_CURVE", 26)) {
    /*                                       ^        */
#ifdef EC_R_POINT_IS_NOT_ON_CURVE
      *iv_return = EC_R_POINT_IS_NOT_ON_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GROUP_GET_CURVE_GFP EC_F_EC_GROUP_NEW_FROM_DATA
     EC_F_EC_GROUP_SET_CURVE_GFP EC_F_EC_GROUP_SET_GENERATOR
     POINT_CONVERSION_COMPRESSED */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'N':
    if (memEQ(name, "EC_F_EC_GROUP_SET_GENERATOR", 27)) {
    /*                                   ^             */
#ifdef EC_F_EC_GROUP_SET_GENERATOR
      *iv_return = EC_F_EC_GROUP_SET_GENERATOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EC_F_EC_GROUP_NEW_FROM_DATA", 27)) {
    /*                                   ^             */
#ifdef EC_F_EC_GROUP_NEW_FROM_DATA
      *iv_return = EC_F_EC_GROUP_NEW_FROM_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "POINT_CONVERSION_COMPRESSED", 27)) {
    /*                                   ^             */
      *iv_return = POINT_CONVERSION_COMPRESSED;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EC_F_EC_GROUP_GET_CURVE_GFP", 27)) {
    /*                                   ^             */
#ifdef EC_F_EC_GROUP_GET_CURVE_GFP
      *iv_return = EC_F_EC_GROUP_GET_CURVE_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_GROUP_SET_CURVE_GFP", 27)) {
    /*                                   ^             */
#ifdef EC_F_EC_GROUP_SET_CURVE_GFP
      *iv_return = EC_F_EC_GROUP_SET_CURVE_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_28 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_ECPKPARAMETERS_PRINT_FP EC_F_EC_GFP_SIMPLE_OCT2POINT
     EC_F_EC_GFP_SIMPLE_POINT2OCT EC_F_EC_GROUP_GET0_GENERATOR
     EC_F_EC_GROUP_GET_CURVE_GF2M EC_F_EC_GROUP_SET_CURVE_GF2M
     EC_F_EC_GROUP_SET_EXTRA_DATA EC_F_EC_POINT_IS_AT_INFINITY
     EC_F_EC_WNAF_PRECOMPUTE_MULT EC_R_INVALID_COMPRESSION_BIT
     EC_R_INVALID_TRINOMIAL_BASIS */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'A':
    if (memEQ(name, "EC_R_INVALID_TRINOMIAL_BASIS", 28)) {
    /*                                   ^              */
#ifdef EC_R_INVALID_TRINOMIAL_BASIS
      *iv_return = EC_R_INVALID_TRINOMIAL_BASIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_OCT2POINT", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_GFP_SIMPLE_OCT2POINT
      *iv_return = EC_F_EC_GFP_SIMPLE_OCT2POINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EC_F_EC_GROUP_GET0_GENERATOR", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_GROUP_GET0_GENERATOR
      *iv_return = EC_F_EC_GROUP_GET0_GENERATOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_EC_POINT_IS_AT_INFINITY", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_POINT_IS_AT_INFINITY
      *iv_return = EC_F_EC_POINT_IS_AT_INFINITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_POINT2OCT", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_GFP_SIMPLE_POINT2OCT
      *iv_return = EC_F_EC_GFP_SIMPLE_POINT2OCT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EC_F_ECPKPARAMETERS_PRINT_FP", 28)) {
    /*                                   ^              */
#ifdef EC_F_ECPKPARAMETERS_PRINT_FP
      *iv_return = EC_F_ECPKPARAMETERS_PRINT_FP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_F_EC_GROUP_GET_CURVE_GF2M", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_GROUP_GET_CURVE_GF2M
      *iv_return = EC_F_EC_GROUP_GET_CURVE_GF2M;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_GROUP_SET_CURVE_GF2M", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_GROUP_SET_CURVE_GF2M
      *iv_return = EC_F_EC_GROUP_SET_CURVE_GF2M;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_R_INVALID_COMPRESSION_BIT", 28)) {
    /*                                   ^              */
#ifdef EC_R_INVALID_COMPRESSION_BIT
      *iv_return = EC_R_INVALID_COMPRESSION_BIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EC_F_EC_GROUP_SET_EXTRA_DATA", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_GROUP_SET_EXTRA_DATA
      *iv_return = EC_F_EC_GROUP_SET_EXTRA_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EC_F_EC_WNAF_PRECOMPUTE_MULT", 28)) {
    /*                                   ^              */
#ifdef EC_F_EC_WNAF_PRECOMPUTE_MULT
      *iv_return = EC_F_EC_WNAF_PRECOMPUTE_MULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_ASN1_GROUP2PARAMETERS EC_F_EC_ASN1_PARAMETERS2GROUP
     EC_F_EC_GF2M_SIMPLE_OCT2POINT EC_F_EC_GF2M_SIMPLE_POINT2OCT
     EC_F_EC_GFP_MONT_FIELD_DECODE EC_F_EC_GFP_MONT_FIELD_ENCODE
     EC_F_EC_GROUP_PRECOMPUTE_MULT EC_F_EC_POINT_SET_TO_INFINITY
     EC_R_INVALID_COMPRESSED_POINT POINT_CONVERSION_UNCOMPRESSED */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'C':
    if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_OCT2POINT", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_GF2M_SIMPLE_OCT2POINT
      *iv_return = EC_F_EC_GF2M_SIMPLE_OCT2POINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "EC_F_EC_GFP_MONT_FIELD_DECODE", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_GFP_MONT_FIELD_DECODE
      *iv_return = EC_F_EC_GFP_MONT_FIELD_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_GFP_MONT_FIELD_ENCODE", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_GFP_MONT_FIELD_ENCODE
      *iv_return = EC_F_EC_GFP_MONT_FIELD_ENCODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EC_R_INVALID_COMPRESSED_POINT", 29)) {
    /*                                    ^              */
#ifdef EC_R_INVALID_COMPRESSED_POINT
      *iv_return = EC_R_INVALID_COMPRESSED_POINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EC_F_EC_POINT_SET_TO_INFINITY", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_POINT_SET_TO_INFINITY
      *iv_return = EC_F_EC_POINT_SET_TO_INFINITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "POINT_CONVERSION_UNCOMPRESSED", 29)) {
    /*                                    ^              */
      *iv_return = POINT_CONVERSION_UNCOMPRESSED;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_POINT2OCT", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_GF2M_SIMPLE_POINT2OCT
      *iv_return = EC_F_EC_GF2M_SIMPLE_POINT2OCT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_F_EC_ASN1_GROUP2PARAMETERS", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_ASN1_GROUP2PARAMETERS
      *iv_return = EC_F_EC_ASN1_GROUP2PARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_ASN1_PARAMETERS2GROUP", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_ASN1_PARAMETERS2GROUP
      *iv_return = EC_F_EC_ASN1_PARAMETERS2GROUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EC_F_EC_GROUP_PRECOMPUTE_MULT", 29)) {
    /*                                    ^              */
#ifdef EC_F_EC_GROUP_PRECOMPUTE_MULT
      *iv_return = EC_F_EC_GROUP_PRECOMPUTE_MULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_ASN1_GROUP2PKPARAMETERS EC_F_EC_ASN1_PKPARAMETERS2GROUP
     EC_F_EC_GROUP_NEW_BY_CURVE_NAME EC_R_D2I_ECPKPARAMETERS_FAILURE
     EC_R_GROUP2PKPARAMETERS_FAILURE EC_R_I2D_ECPKPARAMETERS_FAILURE
     EC_R_NOT_A_SUPPORTED_NIST_PRIME EC_R_PKPARAMETERS2GROUP_FAILURE */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case '2':
    if (memEQ(name, "EC_R_GROUP2PKPARAMETERS_FAILURE", 31)) {
    /*                         ^                           */
#ifdef EC_R_GROUP2PKPARAMETERS_FAILURE
      *iv_return = EC_R_GROUP2PKPARAMETERS_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "EC_R_PKPARAMETERS2GROUP_FAILURE", 31)) {
    /*                         ^                           */
#ifdef EC_R_PKPARAMETERS2GROUP_FAILURE
      *iv_return = EC_R_PKPARAMETERS2GROUP_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "EC_R_D2I_ECPKPARAMETERS_FAILURE", 31)) {
    /*                         ^                           */
#ifdef EC_R_D2I_ECPKPARAMETERS_FAILURE
      *iv_return = EC_R_D2I_ECPKPARAMETERS_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_R_I2D_ECPKPARAMETERS_FAILURE", 31)) {
    /*                         ^                           */
#ifdef EC_R_I2D_ECPKPARAMETERS_FAILURE
      *iv_return = EC_R_I2D_ECPKPARAMETERS_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_EC_ASN1_GROUP2PKPARAMETERS", 31)) {
    /*                         ^                           */
#ifdef EC_F_EC_ASN1_GROUP2PKPARAMETERS
      *iv_return = EC_F_EC_ASN1_GROUP2PKPARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_ASN1_PKPARAMETERS2GROUP", 31)) {
    /*                         ^                           */
#ifdef EC_F_EC_ASN1_PKPARAMETERS2GROUP
      *iv_return = EC_F_EC_ASN1_PKPARAMETERS2GROUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EC_F_EC_GROUP_NEW_BY_CURVE_NAME", 31)) {
    /*                         ^                           */
#ifdef EC_F_EC_GROUP_NEW_BY_CURVE_NAME
      *iv_return = EC_F_EC_GROUP_NEW_BY_CURVE_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "EC_R_NOT_A_SUPPORTED_NIST_PRIME", 31)) {
    /*                         ^                           */
#ifdef EC_R_NOT_A_SUPPORTED_NIST_PRIME
      *iv_return = EC_R_NOT_A_SUPPORTED_NIST_PRIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GFP_MONT_GROUP_SET_CURVE EC_F_EC_GFP_NIST_GROUP_SET_CURVE
     EC_F_EC_GROUP_CHECK_DISCRIMINANT */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'M':
    if (memEQ(name, "EC_F_EC_GFP_MONT_GROUP_SET_CURVE", 32)) {
    /*                           ^                          */
#ifdef EC_F_EC_GFP_MONT_GROUP_SET_CURVE
      *iv_return = EC_F_EC_GFP_MONT_GROUP_SET_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EC_F_EC_GFP_NIST_GROUP_SET_CURVE", 32)) {
    /*                           ^                          */
#ifdef EC_F_EC_GFP_NIST_GROUP_SET_CURVE
      *iv_return = EC_F_EC_GFP_NIST_GROUP_SET_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EC_F_EC_GROUP_CHECK_DISCRIMINANT", 32)) {
    /*                           ^                          */
#ifdef EC_F_EC_GROUP_CHECK_DISCRIMINANT
      *iv_return = EC_F_EC_GROUP_CHECK_DISCRIMINANT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_33 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GFP_MONT_FIELD_SET_TO_ONE EC_F_EC_GROUP_GET_TRINOMIAL_BASIS
     EC_R_EC_GROUP_NEW_BY_NAME_FAILURE */
  /* Offset 30 gives the best switch position.  */
  switch (name[30]) {
  case 'O':
    if (memEQ(name, "EC_F_EC_GFP_MONT_FIELD_SET_TO_ONE", 33)) {
    /*                                             ^         */
#ifdef EC_F_EC_GFP_MONT_FIELD_SET_TO_ONE
      *iv_return = EC_F_EC_GFP_MONT_FIELD_SET_TO_ONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_F_EC_GROUP_GET_TRINOMIAL_BASIS", 33)) {
    /*                                             ^         */
#ifdef EC_F_EC_GROUP_GET_TRINOMIAL_BASIS
      *iv_return = EC_F_EC_GROUP_GET_TRINOMIAL_BASIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EC_R_EC_GROUP_NEW_BY_NAME_FAILURE", 33)) {
    /*                                             ^         */
#ifdef EC_R_EC_GROUP_NEW_BY_NAME_FAILURE
      *iv_return = EC_R_EC_GROUP_NEW_BY_NAME_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_35 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GF2M_SIMPLE_GROUP_SET_CURVE EC_F_EC_GROUP_GET_PENTANOMIAL_BASIS
     EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case 'N':
    if (memEQ(name, "EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID", 35)) {
    /*                                       ^                 */
#ifdef EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID
      *iv_return = EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EC_F_EC_GROUP_GET_PENTANOMIAL_BASIS", 35)) {
    /*                                       ^                 */
#ifdef EC_F_EC_GROUP_GET_PENTANOMIAL_BASIS
      *iv_return = EC_F_EC_GROUP_GET_PENTANOMIAL_BASIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_GROUP_SET_CURVE", 35)) {
    /*                                       ^                 */
#ifdef EC_F_EC_GF2M_SIMPLE_GROUP_SET_CURVE
      *iv_return = EC_F_EC_GF2M_SIMPLE_GROUP_SET_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_38 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GF2M_MONTGOMERY_POINT_MULTIPLY
     EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE_GFP
     EC_F_EC_GFP_SIMPLE_GROUP_SET_GENERATOR */
  /* Offset 31 gives the best switch position.  */
  switch (name[31]) {
  case 'N':
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_GROUP_SET_GENERATOR", 38)) {
    /*                                              ^             */
#ifdef EC_F_EC_GFP_SIMPLE_GROUP_SET_GENERATOR
      *iv_return = EC_F_EC_GFP_SIMPLE_GROUP_SET_GENERATOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE_GFP", 38)) {
    /*                                              ^             */
#ifdef EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE_GFP
      *iv_return = EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EC_F_EC_GF2M_MONTGOMERY_POINT_MULTIPLY", 38)) {
    /*                                              ^             */
#ifdef EC_F_EC_GF2M_MONTGOMERY_POINT_MULTIPLY
      *iv_return = EC_F_EC_GF2M_MONTGOMERY_POINT_MULTIPLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_45 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES
     EC_F_EC_POINT_GET_JPROJECTIVE_COORDINATES_GFP
     EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GF2M
     EC_F_EC_POINT_SET_JPROJECTIVE_COORDINATES_GFP */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'O':
    if (memEQ(name, "EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GF2M", 45)) {
    /*                                  ^                                */
#ifdef EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GF2M
      *iv_return = EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GF2M;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EC_F_EC_POINT_GET_JPROJECTIVE_COORDINATES_GFP", 45)) {
    /*                                  ^                                */
#ifdef EC_F_EC_POINT_GET_JPROJECTIVE_COORDINATES_GFP
      *iv_return = EC_F_EC_POINT_GET_JPROJECTIVE_COORDINATES_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EC_F_EC_POINT_SET_JPROJECTIVE_COORDINATES_GFP", 45)) {
    /*                                  ^                                */
#ifdef EC_F_EC_POINT_SET_JPROJECTIVE_COORDINATES_GFP
      *iv_return = EC_F_EC_POINT_SET_JPROJECTIVE_COORDINATES_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES", 45)) {
    /*                                  ^                                */
#ifdef EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES
      *iv_return = EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(EC_F_COMPUTE_WNAF EC_F_D2I_ECPARAMETERS EC_F_D2I_ECPKPARAMETERS
	       EC_F_D2I_ECPRIVATEKEY EC_F_DO_EC_KEY_PRINT EC_F_ECKEY_PARAM2TYPE
	       EC_F_ECKEY_PARAM_DECODE EC_F_ECKEY_PRIV_DECODE
	       EC_F_ECKEY_PRIV_ENCODE EC_F_ECKEY_PUB_DECODE
	       EC_F_ECKEY_PUB_ENCODE EC_F_ECKEY_TYPE2PARAM
	       EC_F_ECPARAMETERS_PRINT EC_F_ECPARAMETERS_PRINT_FP
	       EC_F_ECPKPARAMETERS_PRINT EC_F_ECPKPARAMETERS_PRINT_FP
	       EC_F_ECP_NIST_MOD_192 EC_F_ECP_NIST_MOD_224
	       EC_F_ECP_NIST_MOD_256 EC_F_ECP_NIST_MOD_521
	       EC_F_EC_ASN1_GROUP2CURVE EC_F_EC_ASN1_GROUP2FIELDID
	       EC_F_EC_ASN1_GROUP2PARAMETERS EC_F_EC_ASN1_GROUP2PKPARAMETERS
	       EC_F_EC_ASN1_PARAMETERS2GROUP EC_F_EC_ASN1_PKPARAMETERS2GROUP
	       EC_F_EC_EX_DATA_SET_DATA EC_F_EC_GF2M_MONTGOMERY_POINT_MULTIPLY
	       EC_F_EC_GF2M_SIMPLE_GROUP_CHECK_DISCRIMINANT
	       EC_F_EC_GF2M_SIMPLE_GROUP_SET_CURVE
	       EC_F_EC_GF2M_SIMPLE_OCT2POINT EC_F_EC_GF2M_SIMPLE_POINT2OCT
	       EC_F_EC_GF2M_SIMPLE_POINT_GET_AFFINE_COORDINATES
	       EC_F_EC_GF2M_SIMPLE_POINT_SET_AFFINE_COORDINATES
	       EC_F_EC_GF2M_SIMPLE_SET_COMPRESSED_COORDINATES
	       EC_F_EC_GFP_MONT_FIELD_DECODE EC_F_EC_GFP_MONT_FIELD_ENCODE
	       EC_F_EC_GFP_MONT_FIELD_MUL EC_F_EC_GFP_MONT_FIELD_SET_TO_ONE
	       EC_F_EC_GFP_MONT_FIELD_SQR EC_F_EC_GFP_MONT_GROUP_SET_CURVE
	       EC_F_EC_GFP_MONT_GROUP_SET_CURVE_GFP EC_F_EC_GFP_NIST_FIELD_MUL
	       EC_F_EC_GFP_NIST_FIELD_SQR EC_F_EC_GFP_NIST_GROUP_SET_CURVE
	       EC_F_EC_GFP_SIMPLE_GROUP_CHECK_DISCRIMINANT
	       EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE
	       EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE_GFP
	       EC_F_EC_GFP_SIMPLE_GROUP_SET_GENERATOR
	       EC_F_EC_GFP_SIMPLE_MAKE_AFFINE EC_F_EC_GFP_SIMPLE_OCT2POINT
	       EC_F_EC_GFP_SIMPLE_POINT2OCT
	       EC_F_EC_GFP_SIMPLE_POINTS_MAKE_AFFINE
	       EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES
	       EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES_GFP
	       EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES
	       EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES_GFP
	       EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES
	       EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES_GFP
	       EC_F_EC_GROUP_CHECK EC_F_EC_GROUP_CHECK_DISCRIMINANT
	       EC_F_EC_GROUP_COPY EC_F_EC_GROUP_GET0_GENERATOR
	       EC_F_EC_GROUP_GET_COFACTOR EC_F_EC_GROUP_GET_CURVE_GF2M
	       EC_F_EC_GROUP_GET_CURVE_GFP EC_F_EC_GROUP_GET_DEGREE
	       EC_F_EC_GROUP_GET_ORDER EC_F_EC_GROUP_GET_PENTANOMIAL_BASIS
	       EC_F_EC_GROUP_GET_TRINOMIAL_BASIS EC_F_EC_GROUP_NEW
	       EC_F_EC_GROUP_NEW_BY_CURVE_NAME EC_F_EC_GROUP_NEW_FROM_DATA
	       EC_F_EC_GROUP_PRECOMPUTE_MULT EC_F_EC_GROUP_SET_CURVE_GF2M
	       EC_F_EC_GROUP_SET_CURVE_GFP EC_F_EC_GROUP_SET_EXTRA_DATA
	       EC_F_EC_GROUP_SET_GENERATOR EC_F_EC_KEY_CHECK_KEY
	       EC_F_EC_KEY_COPY EC_F_EC_KEY_GENERATE_KEY EC_F_EC_KEY_NEW
	       EC_F_EC_KEY_PRINT EC_F_EC_KEY_PRINT_FP
	       EC_F_EC_POINTS_MAKE_AFFINE EC_F_EC_POINT_ADD EC_F_EC_POINT_CMP
	       EC_F_EC_POINT_COPY EC_F_EC_POINT_DBL
	       EC_F_EC_POINT_GET_AFFINE_COORDINATES_GF2M
	       EC_F_EC_POINT_GET_AFFINE_COORDINATES_GFP
	       EC_F_EC_POINT_GET_JPROJECTIVE_COORDINATES_GFP
	       EC_F_EC_POINT_INVERT EC_F_EC_POINT_IS_AT_INFINITY
	       EC_F_EC_POINT_IS_ON_CURVE EC_F_EC_POINT_MAKE_AFFINE
	       EC_F_EC_POINT_MUL EC_F_EC_POINT_NEW EC_F_EC_POINT_OCT2POINT
	       EC_F_EC_POINT_POINT2OCT
	       EC_F_EC_POINT_SET_AFFINE_COORDINATES_GF2M
	       EC_F_EC_POINT_SET_AFFINE_COORDINATES_GFP
	       EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GF2M
	       EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GFP
	       EC_F_EC_POINT_SET_JPROJECTIVE_COORDINATES_GFP
	       EC_F_EC_POINT_SET_TO_INFINITY EC_F_EC_PRE_COMP_DUP
	       EC_F_EC_PRE_COMP_NEW EC_F_EC_WNAF_MUL
	       EC_F_EC_WNAF_PRECOMPUTE_MULT EC_F_I2D_ECPARAMETERS
	       EC_F_I2D_ECPKPARAMETERS EC_F_I2D_ECPRIVATEKEY
	       EC_F_I2O_ECPUBLICKEY EC_F_O2I_ECPUBLICKEY
	       EC_F_OLD_EC_PRIV_DECODE EC_F_PKEY_EC_CTRL EC_F_PKEY_EC_CTRL_STR
	       EC_F_PKEY_EC_DERIVE EC_F_PKEY_EC_KEYGEN EC_F_PKEY_EC_PARAMGEN
	       EC_F_PKEY_EC_SIGN EC_PKEY_NO_PARAMETERS EC_PKEY_NO_PUBKEY
	       EC_R_ASN1_ERROR EC_R_ASN1_UNKNOWN_FIELD EC_R_BUFFER_TOO_SMALL
	       EC_R_D2I_ECPKPARAMETERS_FAILURE EC_R_DECODE_ERROR
	       EC_R_DISCRIMINANT_IS_ZERO EC_R_EC_GROUP_NEW_BY_NAME_FAILURE
	       EC_R_FIELD_TOO_LARGE EC_R_GROUP2PKPARAMETERS_FAILURE
	       EC_R_I2D_ECPKPARAMETERS_FAILURE EC_R_INCOMPATIBLE_OBJECTS
	       EC_R_INVALID_ARGUMENT EC_R_INVALID_COMPRESSED_POINT
	       EC_R_INVALID_COMPRESSION_BIT EC_R_INVALID_CURVE
	       EC_R_INVALID_DIGEST_TYPE EC_R_INVALID_ENCODING
	       EC_R_INVALID_FIELD EC_R_INVALID_FORM EC_R_INVALID_GROUP_ORDER
	       EC_R_INVALID_PENTANOMIAL_BASIS EC_R_INVALID_PRIVATE_KEY
	       EC_R_INVALID_TRINOMIAL_BASIS EC_R_KEYS_NOT_SET
	       EC_R_MISSING_PARAMETERS EC_R_MISSING_PRIVATE_KEY
	       EC_R_NOT_A_NIST_PRIME EC_R_NOT_A_SUPPORTED_NIST_PRIME
	       EC_R_NOT_IMPLEMENTED EC_R_NOT_INITIALIZED EC_R_NO_FIELD_MOD
	       EC_R_NO_PARAMETERS_SET EC_R_PASSED_NULL_PARAMETER
	       EC_R_PKPARAMETERS2GROUP_FAILURE EC_R_POINT_AT_INFINITY
	       EC_R_POINT_IS_NOT_ON_CURVE EC_R_SLOT_FULL
	       EC_R_UNDEFINED_GENERATOR EC_R_UNDEFINED_ORDER EC_R_UNKNOWN_GROUP
	       EC_R_UNKNOWN_ORDER EC_R_UNSUPPORTED_FIELD EC_R_WRONG_ORDER
	       EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID OPENSSL_ECC_MAX_FIELD_BITS
	       OPENSSL_EC_NAMED_CURVE),
            {name=>"POINT_CONVERSION_COMPRESSED", type=>"IV", macro=>"1"},
            {name=>"POINT_CONVERSION_HYBRID", type=>"IV", macro=>"1"},
            {name=>"POINT_CONVERSION_UNCOMPRESSED", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Crypt::OpenSSL::EC", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Crypt::OpenSSL::EC", $types);
__END__
   */

  switch (len) {
  case 14:
    if (memEQ(name, "EC_R_SLOT_FULL", 14)) {
#ifdef EC_R_SLOT_FULL
      *iv_return = EC_R_SLOT_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* EC_F_EC_KEY_NEW EC_R_ASN1_ERROR */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'A':
      if (memEQ(name, "EC_R_ASN1_ERROR", 15)) {
      /*                    ^                */
#ifdef EC_R_ASN1_ERROR
        *iv_return = EC_R_ASN1_ERROR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "EC_F_EC_KEY_NEW", 15)) {
      /*                    ^                */
#ifdef EC_F_EC_KEY_NEW
        *iv_return = EC_F_EC_KEY_NEW;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    return constant_28 (aTHX_ name, iv_return);
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 30:
    /* Names all of length 30.  */
    /* EC_F_EC_GFP_SIMPLE_MAKE_AFFINE EC_R_INVALID_PENTANOMIAL_BASIS */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'N':
      if (memEQ(name, "EC_R_INVALID_PENTANOMIAL_BASIS", 30)) {
      /*                              ^                     */
#ifdef EC_R_INVALID_PENTANOMIAL_BASIS
        *iv_return = EC_R_INVALID_PENTANOMIAL_BASIS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "EC_F_EC_GFP_SIMPLE_MAKE_AFFINE", 30)) {
      /*                              ^                     */
#ifdef EC_F_EC_GFP_SIMPLE_MAKE_AFFINE
        *iv_return = EC_F_EC_GFP_SIMPLE_MAKE_AFFINE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 31:
    return constant_31 (aTHX_ name, iv_return);
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 34:
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE", 34)) {
#ifdef EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE
      *iv_return = EC_F_EC_GFP_SIMPLE_GROUP_SET_CURVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 35:
    return constant_35 (aTHX_ name, iv_return);
    break;
  case 36:
    if (memEQ(name, "EC_F_EC_GFP_MONT_GROUP_SET_CURVE_GFP", 36)) {
#ifdef EC_F_EC_GFP_MONT_GROUP_SET_CURVE_GFP
      *iv_return = EC_F_EC_GFP_MONT_GROUP_SET_CURVE_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 37:
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_POINTS_MAKE_AFFINE", 37)) {
#ifdef EC_F_EC_GFP_SIMPLE_POINTS_MAKE_AFFINE
      *iv_return = EC_F_EC_GFP_SIMPLE_POINTS_MAKE_AFFINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 38:
    return constant_38 (aTHX_ name, iv_return);
    break;
  case 40:
    /* Names all of length 40.  */
    /* EC_F_EC_POINT_GET_AFFINE_COORDINATES_GFP
       EC_F_EC_POINT_SET_AFFINE_COORDINATES_GFP */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'G':
      if (memEQ(name, "EC_F_EC_POINT_GET_AFFINE_COORDINATES_GFP", 40)) {
      /*                             ^                                */
#ifdef EC_F_EC_POINT_GET_AFFINE_COORDINATES_GFP
        *iv_return = EC_F_EC_POINT_GET_AFFINE_COORDINATES_GFP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "EC_F_EC_POINT_SET_AFFINE_COORDINATES_GFP", 40)) {
      /*                             ^                                */
#ifdef EC_F_EC_POINT_SET_AFFINE_COORDINATES_GFP
        *iv_return = EC_F_EC_POINT_SET_AFFINE_COORDINATES_GFP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 41:
    /* Names all of length 41.  */
    /* EC_F_EC_POINT_GET_AFFINE_COORDINATES_GF2M
       EC_F_EC_POINT_SET_AFFINE_COORDINATES_GF2M */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'G':
      if (memEQ(name, "EC_F_EC_POINT_GET_AFFINE_COORDINATES_GF2M", 41)) {
      /*                             ^                                 */
#ifdef EC_F_EC_POINT_GET_AFFINE_COORDINATES_GF2M
        *iv_return = EC_F_EC_POINT_GET_AFFINE_COORDINATES_GF2M;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "EC_F_EC_POINT_SET_AFFINE_COORDINATES_GF2M", 41)) {
      /*                             ^                                 */
#ifdef EC_F_EC_POINT_SET_AFFINE_COORDINATES_GF2M
        *iv_return = EC_F_EC_POINT_SET_AFFINE_COORDINATES_GF2M;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 43:
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_GROUP_CHECK_DISCRIMINANT", 43)) {
#ifdef EC_F_EC_GFP_SIMPLE_GROUP_CHECK_DISCRIMINANT
      *iv_return = EC_F_EC_GFP_SIMPLE_GROUP_CHECK_DISCRIMINANT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 44:
    /* Names all of length 44.  */
    /* EC_F_EC_GF2M_SIMPLE_GROUP_CHECK_DISCRIMINANT
       EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GFP */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'M':
      if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_GROUP_CHECK_DISCRIMINANT", 44)) {
      /*                          ^                                       */
#ifdef EC_F_EC_GF2M_SIMPLE_GROUP_CHECK_DISCRIMINANT
        *iv_return = EC_F_EC_GF2M_SIMPLE_GROUP_CHECK_DISCRIMINANT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GFP", 44)) {
      /*                          ^                                       */
#ifdef EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GFP
        *iv_return = EC_F_EC_POINT_SET_COMPRESSED_COORDINATES_GFP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 45:
    return constant_45 (aTHX_ name, iv_return);
    break;
  case 46:
    if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_SET_COMPRESSED_COORDINATES", 46)) {
#ifdef EC_F_EC_GF2M_SIMPLE_SET_COMPRESSED_COORDINATES
      *iv_return = EC_F_EC_GF2M_SIMPLE_SET_COMPRESSED_COORDINATES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 47:
    /* Names all of length 47.  */
    /* EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES
       EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES */
    /* Offset 25 gives the best switch position.  */
    switch (name[25]) {
    case 'G':
      if (memEQ(name, "EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES", 47)) {
      /*                                        ^                            */
#ifdef EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES
        *iv_return = EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES", 47)) {
      /*                                        ^                            */
#ifdef EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES
        *iv_return = EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 48:
    /* Names all of length 48.  */
    /* EC_F_EC_GF2M_SIMPLE_POINT_GET_AFFINE_COORDINATES
       EC_F_EC_GF2M_SIMPLE_POINT_SET_AFFINE_COORDINATES */
    /* Offset 26 gives the best switch position.  */
    switch (name[26]) {
    case 'G':
      if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_POINT_GET_AFFINE_COORDINATES", 48)) {
      /*                                         ^                            */
#ifdef EC_F_EC_GF2M_SIMPLE_POINT_GET_AFFINE_COORDINATES
        *iv_return = EC_F_EC_GF2M_SIMPLE_POINT_GET_AFFINE_COORDINATES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "EC_F_EC_GF2M_SIMPLE_POINT_SET_AFFINE_COORDINATES", 48)) {
      /*                                         ^                            */
#ifdef EC_F_EC_GF2M_SIMPLE_POINT_SET_AFFINE_COORDINATES
        *iv_return = EC_F_EC_GF2M_SIMPLE_POINT_SET_AFFINE_COORDINATES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 49:
    if (memEQ(name, "EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES_GFP", 49)) {
#ifdef EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES_GFP
      *iv_return = EC_F_EC_GFP_SIMPLE_SET_COMPRESSED_COORDINATES_GFP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 51:
    /* Names all of length 51.  */
    /* EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES_GFP
       EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES_GFP */
    /* Offset 25 gives the best switch position.  */
    switch (name[25]) {
    case 'G':
      if (memEQ(name, "EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES_GFP", 51)) {
      /*                                        ^                                */
#ifdef EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES_GFP
        *iv_return = EC_F_EC_GFP_SIMPLE_POINT_GET_AFFINE_COORDINATES_GFP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES_GFP", 51)) {
      /*                                        ^                                */
#ifdef EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES_GFP
        *iv_return = EC_F_EC_GFP_SIMPLE_POINT_SET_AFFINE_COORDINATES_GFP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

