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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CEPH_OSD_TMAP_HDR CEPH_OSD_TMAP_SET LIBRADOS_SNAP_DIR */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'D':
    if (memEQ(name, "CEPH_OSD_TMAP_HDR", 17)) {
    /*                              ^        */
#ifdef CEPH_OSD_TMAP_HDR
      *iv_return = CEPH_OSD_TMAP_HDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CEPH_OSD_TMAP_SET", 17)) {
    /*                              ^        */
#ifdef CEPH_OSD_TMAP_SET
      *iv_return = CEPH_OSD_TMAP_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LIBRADOS_SNAP_DIR", 17)) {
    /*                              ^        */
#ifdef LIBRADOS_SNAP_DIR
      *iv_return = LIBRADOS_SNAP_DIR;
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
     LIBRADOS_SNAP_HEAD LIBRADOS_VER_EXTRA LIBRADOS_VER_MAJOR
     LIBRADOS_VER_MINOR */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'E':
    if (memEQ(name, "LIBRADOS_SNAP_HEAD", 18)) {
    /*                              ^         */
#ifdef LIBRADOS_SNAP_HEAD
      *iv_return = LIBRADOS_SNAP_HEAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "LIBRADOS_VER_MAJOR", 18)) {
    /*                              ^         */
#ifdef LIBRADOS_VER_MAJOR
      *iv_return = LIBRADOS_VER_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LIBRADOS_VER_MINOR", 18)) {
    /*                              ^         */
#ifdef LIBRADOS_VER_MINOR
      *iv_return = LIBRADOS_VER_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LIBRADOS_VER_EXTRA", 18)) {
    /*                              ^         */
#ifdef LIBRADOS_VER_EXTRA
      *iv_return = LIBRADOS_VER_EXTRA;
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
     LIBRADOS_CMPXATTR_OP_EQ LIBRADOS_CMPXATTR_OP_GT LIBRADOS_CMPXATTR_OP_LT
     LIBRADOS_CMPXATTR_OP_NE LIBRADOS_OP_FLAG_FAILOK LIBRADOS_SUPPORTS_WATCH */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'C':
    if (memEQ(name, "LIBRADOS_SUPPORTS_WATCH", 23)) {
    /*                                    ^        */
#ifdef LIBRADOS_SUPPORTS_WATCH
      *iv_return = LIBRADOS_SUPPORTS_WATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LIBRADOS_CMPXATTR_OP_EQ", 23)) {
    /*                                    ^        */
      *iv_return = LIBRADOS_CMPXATTR_OP_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "LIBRADOS_CMPXATTR_OP_GT", 23)) {
    /*                                    ^        */
      *iv_return = LIBRADOS_CMPXATTR_OP_GT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBRADOS_CMPXATTR_OP_LT", 23)) {
    /*                                    ^        */
      *iv_return = LIBRADOS_CMPXATTR_OP_LT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LIBRADOS_CMPXATTR_OP_NE", 23)) {
    /*                                    ^        */
      *iv_return = LIBRADOS_CMPXATTR_OP_NE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LIBRADOS_OP_FLAG_FAILOK", 23)) {
    /*                                    ^        */
#ifdef LIBRADOS_OP_FLAG_FAILOK
      *iv_return = LIBRADOS_OP_FLAG_FAILOK;
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
     LIBRADOS_CMPXATTR_OP_GTE LIBRADOS_CMPXATTR_OP_LTE LIBRADOS_LOCK_FLAG_RENEW
     */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'G':
    if (memEQ(name, "LIBRADOS_CMPXATTR_OP_GTE", 24)) {
    /*                                    ^         */
      *iv_return = LIBRADOS_CMPXATTR_OP_GTE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LIBRADOS_CMPXATTR_OP_LTE", 24)) {
    /*                                    ^         */
      *iv_return = LIBRADOS_CMPXATTR_OP_LTE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "LIBRADOS_LOCK_FLAG_RENEW", 24)) {
    /*                                    ^         */
#ifdef LIBRADOS_LOCK_FLAG_RENEW
      *iv_return = LIBRADOS_LOCK_FLAG_RENEW;
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
my @names = (qw(CEPH_OSD_TMAP_CREATE CEPH_OSD_TMAP_HDR CEPH_OSD_TMAP_RM
	       CEPH_OSD_TMAP_SET LIBRADOS_CREATE_EXCLUSIVE
	       LIBRADOS_CREATE_IDEMPOTENT LIBRADOS_LOCK_FLAG_RENEW
	       LIBRADOS_OP_FLAG_EXCL LIBRADOS_OP_FLAG_FAILOK LIBRADOS_SNAP_DIR
	       LIBRADOS_SNAP_HEAD LIBRADOS_SUPPORTS_WATCH LIBRADOS_VERSION_CODE
	       LIBRADOS_VER_EXTRA LIBRADOS_VER_MAJOR LIBRADOS_VER_MINOR),
            {name=>"LIBRADOS_CMPXATTR_OP_EQ", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_CMPXATTR_OP_GT", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_CMPXATTR_OP_GTE", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_CMPXATTR_OP_LT", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_CMPXATTR_OP_LTE", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_CMPXATTR_OP_NE", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_BALANCE_READS", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_IGNORE_CACHE", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_IGNORE_OVERLAY", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_LOCALIZE_READS", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_NOFLAG", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_ORDER_READS_WRITES", type=>"IV", macro=>"1"},
            {name=>"LIBRADOS_OPERATION_SKIPRWLOCKS", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Ceph::Rados", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Ceph::Rados", $types);
__END__
   */

  switch (len) {
  case 16:
    if (memEQ(name, "CEPH_OSD_TMAP_RM", 16)) {
#ifdef CEPH_OSD_TMAP_RM
      *iv_return = CEPH_OSD_TMAP_RM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 20:
    if (memEQ(name, "CEPH_OSD_TMAP_CREATE", 20)) {
#ifdef CEPH_OSD_TMAP_CREATE
      *iv_return = CEPH_OSD_TMAP_CREATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    /* Names all of length 21.  */
    /* LIBRADOS_OP_FLAG_EXCL LIBRADOS_VERSION_CODE */
    /* Offset 19 gives the best switch position.  */
    switch (name[19]) {
    case 'C':
      if (memEQ(name, "LIBRADOS_OP_FLAG_EXCL", 21)) {
      /*                                  ^        */
#ifdef LIBRADOS_OP_FLAG_EXCL
        *iv_return = LIBRADOS_OP_FLAG_EXCL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'D':
      if (memEQ(name, "LIBRADOS_VERSION_CODE", 21)) {
      /*                                  ^        */
#ifdef LIBRADOS_VERSION_CODE
        *iv_return = LIBRADOS_VERSION_CODE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    /* Names all of length 25.  */
    /* LIBRADOS_CREATE_EXCLUSIVE LIBRADOS_OPERATION_NOFLAG */
    /* Offset 24 gives the best switch position.  */
    switch (name[24]) {
    case 'E':
      if (memEQ(name, "LIBRADOS_CREATE_EXCLUSIV", 24)) {
      /*                                       E      */
#ifdef LIBRADOS_CREATE_EXCLUSIVE
        *iv_return = LIBRADOS_CREATE_EXCLUSIVE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'G':
      if (memEQ(name, "LIBRADOS_OPERATION_NOFLA", 24)) {
      /*                                       G      */
        *iv_return = LIBRADOS_OPERATION_NOFLAG;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 26:
    if (memEQ(name, "LIBRADOS_CREATE_IDEMPOTENT", 26)) {
#ifdef LIBRADOS_CREATE_IDEMPOTENT
      *iv_return = LIBRADOS_CREATE_IDEMPOTENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 30:
    if (memEQ(name, "LIBRADOS_OPERATION_SKIPRWLOCKS", 30)) {
      *iv_return = LIBRADOS_OPERATION_SKIPRWLOCKS;
      return PERL_constant_ISIV;
    }
    break;
  case 31:
    if (memEQ(name, "LIBRADOS_OPERATION_IGNORE_CACHE", 31)) {
      *iv_return = LIBRADOS_OPERATION_IGNORE_CACHE;
      return PERL_constant_ISIV;
    }
    break;
  case 32:
    if (memEQ(name, "LIBRADOS_OPERATION_BALANCE_READS", 32)) {
      *iv_return = LIBRADOS_OPERATION_BALANCE_READS;
      return PERL_constant_ISIV;
    }
    break;
  case 33:
    /* Names all of length 33.  */
    /* LIBRADOS_OPERATION_IGNORE_OVERLAY LIBRADOS_OPERATION_LOCALIZE_READS */
    /* Offset 19 gives the best switch position.  */
    switch (name[19]) {
    case 'I':
      if (memEQ(name, "LIBRADOS_OPERATION_IGNORE_OVERLAY", 33)) {
      /*                                  ^                    */
        *iv_return = LIBRADOS_OPERATION_IGNORE_OVERLAY;
        return PERL_constant_ISIV;
      }
      break;
    case 'L':
      if (memEQ(name, "LIBRADOS_OPERATION_LOCALIZE_READS", 33)) {
      /*                                  ^                    */
        *iv_return = LIBRADOS_OPERATION_LOCALIZE_READS;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 37:
    if (memEQ(name, "LIBRADOS_OPERATION_ORDER_READS_WRITES", 37)) {
      *iv_return = LIBRADOS_OPERATION_ORDER_READS_WRITES;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

