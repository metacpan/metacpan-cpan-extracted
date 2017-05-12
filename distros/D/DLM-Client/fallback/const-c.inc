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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ECANCEL EINPROG EUNLOCK */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'L':
    if (memEQ(name, "EUNLOCK", 7)) {
    /*                  ^         */
#ifdef EUNLOCK
      *iv_return = EUNLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "ECANCEL", 7)) {
    /*                  ^         */
#ifdef ECANCEL
      *iv_return = ECANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EINPROG", 7)) {
    /*                  ^         */
#ifdef EINPROG
      *iv_return = EINPROG;
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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LKF_CANCEL LKF_ORPHAN LKF_QUECVT LKF_VALBLK LKM_CRMODE LKM_CWMODE
     LKM_EXMODE LKM_NLMODE LKM_PRMODE LKM_PWMODE */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'C':
    if (memEQ(name, "LKF_CANCEL", 10)) {
    /*                   ^            */
#ifdef LKF_CANCEL
      *iv_return = LKF_CANCEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LKM_CRMODE", 10)) {
    /*                   ^            */
#ifdef LKM_CRMODE
      *iv_return = LKM_CRMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LKM_CWMODE", 10)) {
    /*                   ^            */
#ifdef LKM_CWMODE
      *iv_return = LKM_CWMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LKM_EXMODE", 10)) {
    /*                   ^            */
#ifdef LKM_EXMODE
      *iv_return = LKM_EXMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LKM_NLMODE", 10)) {
    /*                   ^            */
#ifdef LKM_NLMODE
      *iv_return = LKM_NLMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LKF_ORPHAN", 10)) {
    /*                   ^            */
#ifdef LKF_ORPHAN
      *iv_return = LKF_ORPHAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "LKM_PRMODE", 10)) {
    /*                   ^            */
#ifdef LKM_PRMODE
      *iv_return = LKM_PRMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LKM_PWMODE", 10)) {
    /*                   ^            */
#ifdef LKM_PWMODE
      *iv_return = LKM_PWMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "LKF_QUECVT", 10)) {
    /*                   ^            */
#ifdef LKF_QUECVT
      *iv_return = LKF_QUECVT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "LKF_VALBLK", 10)) {
    /*                   ^            */
#ifdef LKF_VALBLK
      *iv_return = LKF_VALBLK;
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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DLM_LSFL_FS DLM_LVB_LEN LKF_CONVERT LKF_HEADQUE LKF_NOORDER LKF_NOQUEUE
     LKF_TIMEOUT */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "LKF_HEADQUE", 11)) {
    /*                     ^           */
#ifdef LKF_HEADQUE
      *iv_return = LKF_HEADQUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DLM_LVB_LEN", 11)) {
    /*                     ^           */
#ifdef DLM_LVB_LEN
      *iv_return = DLM_LVB_LEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "DLM_LSFL_FS", 11)) {
    /*                     ^           */
#ifdef DLM_LSFL_FS
      *iv_return = DLM_LSFL_FS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LKF_TIMEOUT", 11)) {
    /*                     ^           */
#ifdef LKF_TIMEOUT
      *iv_return = LKF_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LKF_CONVERT", 11)) {
    /*                     ^           */
#ifdef LKF_CONVERT
      *iv_return = LKF_CONVERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LKF_NOORDER", 11)) {
    /*                     ^           */
#ifdef LKF_NOORDER
      *iv_return = LKF_NOORDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "LKF_NOQUEUE", 11)) {
    /*                     ^           */
#ifdef LKF_NOQUEUE
      *iv_return = LKF_NOQUEUE;
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
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LKF_EXPEDITE LKF_IVVALBLK LKF_NODLCKWT */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'E':
    if (memEQ(name, "LKF_EXPEDITE", 12)) {
    /*                   ^              */
#ifdef LKF_EXPEDITE
      *iv_return = LKF_EXPEDITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LKF_IVVALBLK", 12)) {
    /*                   ^              */
#ifdef LKF_IVVALBLK
      *iv_return = LKF_IVVALBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LKF_NODLCKWT", 12)) {
    /*                   ^              */
#ifdef LKF_NODLCKWT
      *iv_return = LKF_NODLCKWT;
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
     DLM_LSFL_NODIR LKF_CONVDEADLK LKF_PERSISTENT */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'I':
    if (memEQ(name, "DLM_LSFL_NODIR", 14)) {
    /*                           ^        */
#ifdef DLM_LSFL_NODIR
      *iv_return = DLM_LSFL_NODIR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LKF_CONVDEADLK", 14)) {
    /*                           ^        */
#ifdef LKF_CONVDEADLK
      *iv_return = LKF_CONVDEADLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LKF_PERSISTENT", 14)) {
    /*                           ^        */
#ifdef LKF_PERSISTENT
      *iv_return = LKF_PERSISTENT;
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
     DLM_SBF_ALTMODE DLM_SBF_DEMOTED LKF_FORCEUNLOCK LKF_NOQUEUEBAST */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'B':
    if (memEQ(name, "LKF_NOQUEUEBAST", 15)) {
    /*                          ^          */
#ifdef LKF_NOQUEUEBAST
      *iv_return = LKF_NOQUEUEBAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LKF_FORCEUNLOCK", 15)) {
    /*                          ^          */
#ifdef LKF_FORCEUNLOCK
      *iv_return = LKF_FORCEUNLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "DLM_SBF_ALTMODE", 15)) {
    /*                          ^          */
#ifdef DLM_SBF_ALTMODE
      *iv_return = DLM_SBF_ALTMODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DLM_SBF_DEMOTED", 15)) {
    /*                          ^          */
#ifdef DLM_SBF_DEMOTED
      *iv_return = DLM_SBF_DEMOTED;
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
my @names = (qw(DLM_LOCKSPACE_LEN DLM_LSFL_FS DLM_LSFL_NEWEXCL DLM_LSFL_NODIR
	       DLM_LSFL_TIMEWARN DLM_LVB_LEN DLM_RESNAME_MAXLEN DLM_SBF_ALTMODE
	       DLM_SBF_DEMOTED DLM_SBF_VALNOTVALID ECANCEL EINPROG EUNLOCK
	       LKF_ALTCW LKF_ALTPR LKF_CANCEL LKF_CONVDEADLK LKF_CONVERT
	       LKF_EXPEDITE LKF_FORCEUNLOCK LKF_HEADQUE LKF_IVVALBLK
	       LKF_NODLCKBLK LKF_NODLCKWT LKF_NOORDER LKF_NOQUEUE
	       LKF_NOQUEUEBAST LKF_ORPHAN LKF_PERSISTENT LKF_QUECVT LKF_TIMEOUT
	       LKF_VALBLK LKF_WAIT LKM_CRMODE LKM_CWMODE LKM_EXMODE LKM_NLMODE
	       LKM_PRMODE LKM_PWMODE));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("DLM::Client", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("DLM::Client", $types);
__END__
   */

  switch (len) {
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    if (memEQ(name, "LKF_WAIT", 8)) {
#ifdef LKF_WAIT
      *iv_return = LKF_WAIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    /* Names all of length 9.  */
    /* LKF_ALTCW LKF_ALTPR */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'R':
      if (memEQ(name, "LKF_ALTP", 8)) {
      /*                       R     */
#ifdef LKF_ALTPR
        *iv_return = LKF_ALTPR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'W':
      if (memEQ(name, "LKF_ALTC", 8)) {
      /*                       W     */
#ifdef LKF_ALTCW
        *iv_return = LKF_ALTCW;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    if (memEQ(name, "LKF_NODLCKBLK", 13)) {
#ifdef LKF_NODLCKBLK
      *iv_return = LKF_NODLCKBLK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    if (memEQ(name, "DLM_LSFL_NEWEXCL", 16)) {
#ifdef DLM_LSFL_NEWEXCL
      *iv_return = DLM_LSFL_NEWEXCL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* DLM_LOCKSPACE_LEN DLM_LSFL_TIMEWARN */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'K':
      if (memEQ(name, "DLM_LOCKSPACE_LEN", 17)) {
      /*                      ^                */
#ifdef DLM_LOCKSPACE_LEN
        *iv_return = DLM_LOCKSPACE_LEN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'L':
      if (memEQ(name, "DLM_LSFL_TIMEWARN", 17)) {
      /*                      ^                */
#ifdef DLM_LSFL_TIMEWARN
        *iv_return = DLM_LSFL_TIMEWARN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    if (memEQ(name, "DLM_RESNAME_MAXLEN", 18)) {
#ifdef DLM_RESNAME_MAXLEN
      *iv_return = DLM_RESNAME_MAXLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    if (memEQ(name, "DLM_SBF_VALNOTVALID", 19)) {
#ifdef DLM_SBF_VALNOTVALID
      *iv_return = DLM_SBF_VALNOTVALID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

