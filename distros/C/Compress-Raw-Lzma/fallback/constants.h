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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LZMA_FINISH LZMA_MF_BT2 LZMA_MF_BT3 LZMA_MF_BT4 LZMA_MF_HC3 LZMA_MF_HC4
     LZMA_PB_MAX LZMA_PB_MIN */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case '2':
    if (memEQ(name, "LZMA_MF_BT", 10)) {
    /*                         2      */
#if 1
      *iv_return = LZMA_MF_BT2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "LZMA_MF_BT", 10)) {
    /*                         3      */
#if 1
      *iv_return = LZMA_MF_BT3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LZMA_MF_HC", 10)) {
    /*                         3      */
#if 1
      *iv_return = LZMA_MF_HC3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "LZMA_MF_BT", 10)) {
    /*                         4      */
#if 1
      *iv_return = LZMA_MF_BT4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LZMA_MF_HC", 10)) {
    /*                         4      */
#if 1
      *iv_return = LZMA_MF_HC4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "LZMA_FINIS", 10)) {
    /*                         H      */
#if 1
      *iv_return = LZMA_FINISH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LZMA_PB_MI", 10)) {
    /*                         N      */
#ifdef LZMA_PB_MIN
      *iv_return = LZMA_PB_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "LZMA_PB_MA", 10)) {
    /*                         X      */
#ifdef LZMA_PB_MAX
      *iv_return = LZMA_PB_MAX;
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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LZMA_LCLP_MAX LZMA_LCLP_MIN LZMA_NO_CHECK */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "LZMA_LCLP_MAX", 13)) {
    /*                          ^        */
#ifdef LZMA_LCLP_MAX
      *iv_return = LZMA_LCLP_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "LZMA_NO_CHECK", 13)) {
    /*                          ^        */
#if 1
      *iv_return = LZMA_NO_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LZMA_LCLP_MIN", 13)) {
    /*                          ^        */
#ifdef LZMA_LCLP_MIN
      *iv_return = LZMA_LCLP_MIN;
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
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LZMA_BUF_ERROR LZMA_GET_CHECK LZMA_MEM_ERROR LZMA_MODE_FAST */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'D':
    if (memEQ(name, "LZMA_MODE_FAST", 14)) {
    /*                      ^             */
#if 1
      *iv_return = LZMA_MODE_FAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "LZMA_BUF_ERROR", 14)) {
    /*                      ^             */
#if 1
      *iv_return = LZMA_BUF_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LZMA_MEM_ERROR", 14)) {
    /*                      ^             */
#if 1
      *iv_return = LZMA_MEM_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LZMA_GET_CHECK", 14)) {
    /*                      ^             */
#if 1
      *iv_return = LZMA_GET_CHECK;
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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LZMA_CHECK_NONE LZMA_DATA_ERROR LZMA_FILTER_ARM LZMA_FILTER_X86
     LZMA_FULL_FLUSH LZMA_LC_DEFAULT LZMA_LP_DEFAULT LZMA_PB_DEFAULT
     LZMA_PROG_ERROR LZMA_STREAM_END LZMA_SYNC_FLUSH */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "LZMA_DATA_ERROR", 15)) {
    /*                     ^               */
#if 1
      *iv_return = LZMA_DATA_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "LZMA_PB_DEFAULT", 15)) {
    /*                     ^               */
#ifdef LZMA_PB_DEFAULT
      *iv_return = LZMA_PB_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "LZMA_LC_DEFAULT", 15)) {
    /*                     ^               */
#ifdef LZMA_LC_DEFAULT
      *iv_return = LZMA_LC_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "LZMA_CHECK_NONE", 15)) {
    /*                     ^               */
#if 1
      *iv_return = LZMA_CHECK_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LZMA_FILTER_ARM", 15)) {
    /*                     ^               */
#ifdef LZMA_FILTER_ARM
      *iv_return = LZMA_FILTER_ARM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LZMA_FILTER_X86", 15)) {
    /*                     ^               */
#ifdef LZMA_FILTER_X86
      *iv_return = LZMA_FILTER_X86;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "LZMA_LP_DEFAULT", 15)) {
    /*                     ^               */
#ifdef LZMA_LP_DEFAULT
      *iv_return = LZMA_LP_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LZMA_PROG_ERROR", 15)) {
    /*                     ^               */
#if 1
      *iv_return = LZMA_PROG_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LZMA_STREAM_END", 15)) {
    /*                     ^               */
#if 1
      *iv_return = LZMA_STREAM_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "LZMA_FULL_FLUSH", 15)) {
    /*                     ^               */
#if 1
      *iv_return = LZMA_FULL_FLUSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "LZMA_SYNC_FLUSH", 15)) {
    /*                     ^               */
#if 1
      *iv_return = LZMA_SYNC_FLUSH;
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
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LZMA_CHECK_CRC32 LZMA_CHECK_CRC64 LZMA_FILTERS_MAX LZMA_FILTER_IA64
     LZMA_MODE_NORMAL */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'C':
    if (memEQ(name, "LZMA_CHECK_CRC32", 16)) {
    /*                          ^           */
#if 1
      *iv_return = LZMA_CHECK_CRC32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LZMA_CHECK_CRC64", 16)) {
    /*                          ^           */
#if 1
      *iv_return = LZMA_CHECK_CRC64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LZMA_MODE_NORMAL", 16)) {
    /*                          ^           */
#if 1
      *iv_return = LZMA_MODE_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LZMA_FILTERS_MAX", 16)) {
    /*                          ^           */
#ifdef LZMA_FILTERS_MAX
      *iv_return = LZMA_FILTERS_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "LZMA_FILTER_IA64", 16)) {
    /*                          ^           */
#ifdef LZMA_FILTER_IA64
      *iv_return = LZMA_FILTER_IA64;
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
     LZMA_CHECK_ID_MAX LZMA_CHECK_SHA256 LZMA_CONCATENATED LZMA_FILTER_DELTA
     LZMA_FILTER_LZMA2 LZMA_FILTER_SPARC LZMA_FORMAT_ERROR */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case '2':
    if (memEQ(name, "LZMA_FILTER_LZMA", 16)) {
    /*                               2      */
#ifdef LZMA_FILTER_LZMA2
      *iv_return = LZMA_FILTER_LZMA2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "LZMA_CHECK_SHA25", 16)) {
    /*                               6      */
#if 1
      *iv_return = LZMA_CHECK_SHA256;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "LZMA_FILTER_DELT", 16)) {
    /*                               A      */
#ifdef LZMA_FILTER_DELTA
      *iv_return = LZMA_FILTER_DELTA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "LZMA_FILTER_SPAR", 16)) {
    /*                               C      */
#ifdef LZMA_FILTER_SPARC
      *iv_return = LZMA_FILTER_SPARC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "LZMA_CONCATENATE", 16)) {
    /*                               D      */
#ifdef LZMA_CONCATENATED
      *iv_return = LZMA_CONCATENATED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LZMA_FORMAT_ERRO", 16)) {
    /*                               R      */
#if 1
      *iv_return = LZMA_FORMAT_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "LZMA_CHECK_ID_MA", 16)) {
    /*                               X      */
#ifdef LZMA_CHECK_ID_MAX
      *iv_return = LZMA_CHECK_ID_MAX;
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
     LZMA_DICT_SIZE_MIN LZMA_OPTIONS_ERROR LZMA_TELL_NO_CHECK
     LZMA_VERSION_MAJOR LZMA_VERSION_MINOR LZMA_VERSION_PATCH */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'E':
    if (memEQ(name, "LZMA_TELL_NO_CHECK", 18)) {
    /*                              ^         */
#ifdef LZMA_TELL_NO_CHECK
      *iv_return = LZMA_TELL_NO_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "LZMA_VERSION_MAJOR", 18)) {
    /*                              ^         */
#ifdef LZMA_VERSION_MAJOR
      *iv_return = LZMA_VERSION_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LZMA_DICT_SIZE_MIN", 18)) {
    /*                              ^         */
#ifdef LZMA_DICT_SIZE_MIN
      *iv_return = LZMA_DICT_SIZE_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LZMA_VERSION_MINOR", 18)) {
    /*                              ^         */
#ifdef LZMA_VERSION_MINOR
      *iv_return = LZMA_VERSION_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LZMA_OPTIONS_ERROR", 18)) {
    /*                              ^         */
#if 1
      *iv_return = LZMA_OPTIONS_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LZMA_VERSION_PATCH", 18)) {
    /*                              ^         */
#ifdef LZMA_VERSION_PATCH
      *iv_return = LZMA_VERSION_PATCH;
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
constant_19 (pTHX_ const char *name, IV *iv_return, const char **pv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LZMA_CHECK_SIZE_MAX LZMA_DELTA_DIST_MAX LZMA_DELTA_DIST_MIN
     LZMA_FILTER_POWERPC LZMA_MEMLIMIT_ERROR LZMA_PRESET_DEFAULT
     LZMA_PRESET_EXTREME LZMA_TELL_ANY_CHECK LZMA_VERSION_STRING */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'A':
    if (memEQ(name, "LZMA_CHECK_SIZE_MAX", 19)) {
    /*                                ^        */
#ifdef LZMA_CHECK_SIZE_MAX
      *iv_return = LZMA_CHECK_SIZE_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LZMA_DELTA_DIST_MAX", 19)) {
    /*                                ^        */
#ifdef LZMA_DELTA_DIST_MAX
      *iv_return = LZMA_DELTA_DIST_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "LZMA_TELL_ANY_CHECK", 19)) {
    /*                                ^        */
#ifdef LZMA_TELL_ANY_CHECK
      *iv_return = LZMA_TELL_ANY_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LZMA_DELTA_DIST_MIN", 19)) {
    /*                                ^        */
#ifdef LZMA_DELTA_DIST_MIN
      *iv_return = LZMA_DELTA_DIST_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LZMA_PRESET_DEFAULT", 19)) {
    /*                                ^        */
#ifdef LZMA_PRESET_DEFAULT
      *iv_return = LZMA_PRESET_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LZMA_PRESET_EXTREME", 19)) {
    /*                                ^        */
#ifdef LZMA_PRESET_EXTREME
      *iv_return = LZMA_PRESET_EXTREME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LZMA_VERSION_STRING", 19)) {
    /*                                ^        */
#ifdef LZMA_VERSION_STRING 
      *pv_return = LZMA_VERSION_STRING;
      return PERL_constant_ISPV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LZMA_MEMLIMIT_ERROR", 19)) {
    /*                                ^        */
#if 1
      *iv_return = LZMA_MEMLIMIT_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "LZMA_FILTER_POWERPC", 19)) {
    /*                                ^        */
#ifdef LZMA_FILTER_POWERPC
      *iv_return = LZMA_FILTER_POWERPC;
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
     LZMA_BACKWARD_SIZE_MIN LZMA_DICT_SIZE_DEFAULT LZMA_PRESET_LEVEL_MASK
     LZMA_UNSUPPORTED_CHECK LZMA_VERSION_STABILITY */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "LZMA_BACKWARD_SIZE_MIN", 22)) {
    /*                     ^                      */
#ifdef LZMA_BACKWARD_SIZE_MIN
      *iv_return = LZMA_BACKWARD_SIZE_MIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LZMA_VERSION_STABILITY", 22)) {
    /*                     ^                      */
#ifdef LZMA_VERSION_STABILITY
      *iv_return = LZMA_VERSION_STABILITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LZMA_DICT_SIZE_DEFAULT", 22)) {
    /*                     ^                      */
#ifdef LZMA_DICT_SIZE_DEFAULT
      *iv_return = LZMA_DICT_SIZE_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LZMA_UNSUPPORTED_CHECK", 22)) {
    /*                     ^                      */
#if 1
      *iv_return = LZMA_UNSUPPORTED_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LZMA_PRESET_LEVEL_MASK", 22)) {
    /*                     ^                      */
#ifdef LZMA_PRESET_LEVEL_MASK
      *iv_return = LZMA_PRESET_LEVEL_MASK;
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
constant (pTHX_ const char *name, STRLEN len, IV *iv_return, const char **pv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/linux-shared/base/perl/install/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV PV)};
my @names = (qw(LZMA_BACKWARD_SIZE_MIN LZMA_BLOCK_HEADER_SIZE_MAX
	       LZMA_BLOCK_HEADER_SIZE_MIN LZMA_CHECK_ID_MAX LZMA_CHECK_SIZE_MAX
	       LZMA_CONCATENATED LZMA_DELTA_DIST_MAX LZMA_DELTA_DIST_MIN
	       LZMA_DICT_SIZE_DEFAULT LZMA_DICT_SIZE_MIN LZMA_FILTERS_MAX
	       LZMA_FILTER_ARM LZMA_FILTER_ARMTHUMB LZMA_FILTER_DELTA
	       LZMA_FILTER_IA64 LZMA_FILTER_LZMA2 LZMA_FILTER_POWERPC
	       LZMA_FILTER_SPARC LZMA_FILTER_X86 LZMA_LCLP_MAX LZMA_LCLP_MIN
	       LZMA_LC_DEFAULT LZMA_LP_DEFAULT LZMA_PB_DEFAULT LZMA_PB_MAX
	       LZMA_PB_MIN LZMA_PRESET_DEFAULT LZMA_PRESET_EXTREME
	       LZMA_PRESET_LEVEL_MASK LZMA_STREAM_HEADER_SIZE
	       LZMA_TELL_ANY_CHECK LZMA_TELL_NO_CHECK
	       LZMA_TELL_UNSUPPORTED_CHECK LZMA_VERSION LZMA_VERSION_MAJOR
	       LZMA_VERSION_MINOR LZMA_VERSION_PATCH LZMA_VERSION_STABILITY),
            {name=>"LZMA_BUF_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_CHECK_CRC32", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_CHECK_CRC64", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_CHECK_NONE", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_CHECK_SHA256", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_DATA_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_DELTA_TYPE_BYTE", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_FINISH", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_FORMAT_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_FULL_FLUSH", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_GET_CHECK", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MEMLIMIT_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MEM_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MF_BT2", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MF_BT3", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MF_BT4", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MF_HC3", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MF_HC4", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MODE_FAST", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_MODE_NORMAL", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_NO_CHECK", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_OK", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_OPTIONS_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_PROG_ERROR", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_RUN", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_STREAM_END", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_SYNC_FLUSH", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_UNSUPPORTED_CHECK", type=>"IV", macro=>["#if 1\n", "#endif\n"]},
            {name=>"LZMA_VERSION_STABILITY_STRING", type=>"PV", macro=>["#ifdef LZMA_VERSION_STABILITY_STRING \n", "#endif\n"]},
            {name=>"LZMA_VERSION_STRING", type=>"PV", macro=>["#ifdef LZMA_VERSION_STRING \n", "#endif\n"]});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Lzma", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Lzma", $types);
__END__
   */

  switch (len) {
  case 7:
    if (memEQ(name, "LZMA_OK", 7)) {
#if 1
      *iv_return = LZMA_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    if (memEQ(name, "LZMA_RUN", 8)) {
#if 1
      *iv_return = LZMA_RUN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    if (memEQ(name, "LZMA_VERSION", 12)) {
#ifdef LZMA_VERSION
      *iv_return = LZMA_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
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
    return constant_19 (aTHX_ name, iv_return, pv_return);
    break;
  case 20:
    /* Names all of length 20.  */
    /* LZMA_DELTA_TYPE_BYTE LZMA_FILTER_ARMTHUMB */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'D':
      if (memEQ(name, "LZMA_DELTA_TYPE_BYTE", 20)) {
      /*                    ^                     */
#if 1
        *iv_return = LZMA_DELTA_TYPE_BYTE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'F':
      if (memEQ(name, "LZMA_FILTER_ARMTHUMB", 20)) {
      /*                    ^                     */
#ifdef LZMA_FILTER_ARMTHUMB
        *iv_return = LZMA_FILTER_ARMTHUMB;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    if (memEQ(name, "LZMA_STREAM_HEADER_SIZE", 23)) {
#ifdef LZMA_STREAM_HEADER_SIZE
      *iv_return = LZMA_STREAM_HEADER_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    /* Names all of length 26.  */
    /* LZMA_BLOCK_HEADER_SIZE_MAX LZMA_BLOCK_HEADER_SIZE_MIN */
    /* Offset 24 gives the best switch position.  */
    switch (name[24]) {
    case 'A':
      if (memEQ(name, "LZMA_BLOCK_HEADER_SIZE_MAX", 26)) {
      /*                                       ^        */
#ifdef LZMA_BLOCK_HEADER_SIZE_MAX
        *iv_return = LZMA_BLOCK_HEADER_SIZE_MAX;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "LZMA_BLOCK_HEADER_SIZE_MIN", 26)) {
      /*                                       ^        */
#ifdef LZMA_BLOCK_HEADER_SIZE_MIN
        *iv_return = LZMA_BLOCK_HEADER_SIZE_MIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 27:
    if (memEQ(name, "LZMA_TELL_UNSUPPORTED_CHECK", 27)) {
#ifdef LZMA_TELL_UNSUPPORTED_CHECK
      *iv_return = LZMA_TELL_UNSUPPORTED_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    if (memEQ(name, "LZMA_VERSION_STABILITY_STRING", 29)) {
#ifdef LZMA_VERSION_STABILITY_STRING 
      *pv_return = LZMA_VERSION_STABILITY_STRING;
      return PERL_constant_ISPV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

