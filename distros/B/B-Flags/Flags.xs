/* -*- mode:c tabwidth:4 -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define OPT_BITS

typedef OP  *B__OP;
typedef SV  *B__SV;

MODULE = B::Flags		PACKAGE = B::OP		
PROTOTYPES: DISABLE

SV*
flagspv(o)
    B::OP   o
    CODE:
        RETVAL = newSVpvn("", 0);
        switch (o->op_flags & OPf_WANT) {
        case OPf_WANT_VOID:
            sv_catpv(RETVAL, ",WANT_VOID");
            break;
        case OPf_WANT_SCALAR:
            sv_catpv(RETVAL, ",WANT_SCALAR");
            break;
        case OPf_WANT_LIST:
            sv_catpv(RETVAL, ",WANT_LIST");
            break;
        default:
            sv_catpv(RETVAL, ",WANT_UNKNOWN");
            break;
        }
        if (o->op_flags & OPf_KIDS)
            sv_catpv(RETVAL, ",KIDS");
        if (o->op_flags & OPf_PARENS)
            sv_catpv(RETVAL, ",PARENS");
        if (o->op_flags & OPf_STACKED)
            sv_catpv(RETVAL, ",STACKED");
        if (o->op_flags & OPf_REF)
            sv_catpv(RETVAL, ",REF");
        if (o->op_flags & OPf_MOD)
            sv_catpv(RETVAL, ",MOD");
        if (o->op_flags & OPf_SPECIAL)
            sv_catpv(RETVAL, ",SPECIAL");
#ifdef OPT_BITS
#if PERL_VERSION >= 10
        if (o->op_opt)
            sv_catpv(RETVAL, ",OPT");
#if (PERL_VERSION == 17 && PERL_SUBVERSION < 3) || PERL_VERSION < 17
        if (o->op_latefree)
            sv_catpv(RETVAL, ",LATEFREE");
        if (o->op_latefreed)
            sv_catpv(RETVAL, ",LATEFREED");
        if (o->op_attached)
            sv_catpv(RETVAL, ",ATTACHED");
#endif
#if (PERL_VERSION == 17 && PERL_SUBVERSION >= 2) || PERL_VERSION >= 18
        if (o->op_slabbed)
            sv_catpv(RETVAL, ",SLABBED");
        if (o->op_savefree)
            sv_catpv(RETVAL, ",SAVEFREE");
#if (PERL_VERSION == 17 && PERL_SUBVERSION >= 6) || PERL_VERSION >= 18
        if (o->op_static)
            sv_catpv(RETVAL, ",STATIC");
#if (PERL_VERSION == 19 && PERL_SUBVERSION > 2) || PERL_VERSION >= 20
        if (o->op_folded)
            sv_catpv(RETVAL, ",FOLDED");
#if (PERL_VERSION == 21 && PERL_SUBVERSION > 1) || PERL_VERSION >= 22
#if (PERL_VERSION == 21 && PERL_SUBVERSION < 11)
        if (o->op_lastsib)
            sv_catpv(RETVAL, ",SIBLING");
#else
        if (OpHAS_SIBLING(o))
            sv_catpv(RETVAL, ",SIBLING");
#endif
#else
        if (o->op_sibling)
            sv_catpv(RETVAL, ",SIBLING");
#endif
#endif
#endif
#endif
#endif
#endif
        if (SvCUR(RETVAL))
            sv_chop(RETVAL, SvPVX(RETVAL)+1); /* Ow. */
    OUTPUT:
        RETVAL

SV*
privatepv(o)
    B::OP   o
    CODE:
        RETVAL = newSVpvn("", 0);
        /* This needs past-proofing. :) */
        if (PL_opargs[o->op_type] & OA_TARGLEX) {
#ifdef OPpTARGET_MY
            if (o->op_private & OPpTARGET_MY)
                sv_catpv(RETVAL, ",TARGET_MY");
#endif
        }
        if (o->op_type == OP_ENTERITER || o->op_type == OP_ITER) {
#ifdef OPpITER_REVERSED
            if (o->op_private & OPpITER_REVERSED)
                sv_catpv(RETVAL, ",ITER_REVERSED");
#endif
#ifdef OPpITER_DEF
            if (o->op_private & OPpITER_DEF)
                sv_catpv(RETVAL, ",ITER_DEF");
#endif
        }
#ifdef OPpREFCOUNTED
        else if (o->op_type == OP_LEAVESUB ||
                 o->op_type == OP_LEAVE ||
                 o->op_type == OP_LEAVESUBLV ||
                 o->op_type == OP_LEAVEWRITE) {
            if (o->op_private & OPpREFCOUNTED)
                sv_catpv(RETVAL, ",REFCOUNTED");
        }
#endif
        else if (o->op_type == OP_AASSIGN) {
#ifdef  OPpASSIGN_COMMON
            if (o->op_private & OPpASSIGN_COMMON)
                sv_catpv(RETVAL, ",COMMON");
#endif
#ifdef  OPpASSIGN_HASH
            if (o->op_private & OPpASSIGN_HASH)
                sv_catpv(RETVAL, ",HASH");
#endif
        }
#ifdef  OPpASSIGN_BACKWARDS
        else if (o->op_type == OP_SASSIGN) {
            if (o->op_private & OPpASSIGN_BACKWARDS)
                sv_catpv(RETVAL, ",BACKWARDS");
        }
#endif
#ifdef OPpRUNTIME
        else if (o->op_type == OP_MATCH ||
                 o->op_type == OP_SUBST) {
            if (o->op_private & OPpRUNTIME)
                sv_catpv(RETVAL, ",RUNTIME");
        }
#endif
        else if (o->op_type == OP_TRANS) {
#ifdef OPpTRANS_FROM_UTF
            if (o->op_private & OPpTRANS_FROM_UTF)
                sv_catpv(RETVAL, ",FROM_UTF");
#endif
#ifdef OPpTRANS_TO_UTF
            if (o->op_private & OPpTRANS_TO_UTF)
                sv_catpv(RETVAL, ",TO_UTF");
#endif
#ifdef OPpTRANS_SQUASH
            if (o->op_private & OPpTRANS_SQUASH)
                sv_catpv(RETVAL, ",SQUASH");
#endif
#ifdef OPpTRANS_DELETE
            if (o->op_private & OPpTRANS_DELETE)
                sv_catpv(RETVAL, ",DELETE");
#endif
#ifdef OPpTRANS_COMPLEMENT
            if (o->op_private & OPpTRANS_COMPLEMENT)
                sv_catpv(RETVAL, ",COMPLEMENT");
#endif
#ifdef OPpTRANS_IDENTICAL
            if (o->op_private & OPpTRANS_IDENTICAL)
                sv_catpv(RETVAL, ",IDENTICAL");
#endif
#ifdef OPpTRANS_GROWS
            if (o->op_private & OPpTRANS_GROWS)
                sv_catpv(RETVAL, ",GROWS");
#endif
        }
#ifdef OPpREPEAT_DOLIST
        else if (o->op_type == OP_REPEAT) {
            if (o->op_private & OPpREPEAT_DOLIST)
                sv_catpv(RETVAL, ",DOLIST");
#endif
        }
        else if (o->op_type == OP_ENTERSUB ||
                 o->op_type == OP_RV2SV ||
                 o->op_type == OP_GVSV ||
                 o->op_type == OP_RV2AV ||
                 o->op_type == OP_RV2HV ||
                 o->op_type == OP_RV2GV ||
                 o->op_type == OP_AELEM ||
                 o->op_type == OP_HELEM )
        {
            if (o->op_type == OP_ENTERSUB) {
#ifdef OPpENTERSUB_AMPER
                if (o->op_private & OPpENTERSUB_AMPER)
                    sv_catpv(RETVAL, ",AMPER");
#endif
#ifdef OPpENTERSUB_DB
                if (o->op_private & OPpENTERSUB_DB)
                    sv_catpv(RETVAL, ",DB");
#endif
#ifdef OPpENTERSUB_HASTARG
                if (o->op_private & OPpENTERSUB_HASTARG)
                    sv_catpv(RETVAL, ",HASTARG");
#endif
#ifdef OPpENTERSUB_NOPAREN
                if (o->op_private & OPpENTERSUB_NOPAREN)
                    sv_catpv(RETVAL, ",NOPAREN");
#endif
#ifdef OPpENTERSUB_INARGS
                if (o->op_private & OPpENTERSUB_INARGS)
                    sv_catpv(RETVAL, ",INARGS");
#endif
            }
            else {
#ifdef OPpDEREF
                switch (o->op_private & OPpDEREF) {
            case OPpDEREF_SV:
                sv_catpv(RETVAL, ",SV");
                break;
            case OPpDEREF_AV:
                sv_catpv(RETVAL, ",AV");
                break;
            case OPpDEREF_HV:
                sv_catpv(RETVAL, ",HV");
                break;
            }
#endif
#ifdef OPpMAYBE_LVSUB
                if (o->op_private & OPpMAYBE_LVSUB)
                    sv_catpv(RETVAL, ",MAYBE_LVSUB");
#endif
            }
            if (o->op_type == OP_AELEM || o->op_type == OP_HELEM) {
#ifdef OPpLVAL_DEFER
                if (o->op_private & OPpLVAL_DEFER)
                    sv_catpv(RETVAL, ",LVAL_DEFER");
#endif
            }
            else {
                if (o->op_private & HINT_STRICT_REFS)
                    sv_catpv(RETVAL, ",STRICT_REFS");
#ifdef OPpOUR_INTRO
                if (o->op_private & OPpOUR_INTRO)
                    sv_catpv(RETVAL, ",OUR_INTRO");
#endif
            }
        }
#ifdef OPpPAD_STATE
        else if ((o->op_type == OP_PADSV) && (o->op_private & OPpPAD_STATE))
		sv_catpv(RETVAL, ",PAD_STATE");
#endif
#ifdef OPpDONT_INIT_GV
        else if ((o->op_type == OP_RV2GV) && (o->op_private & OPpDONT_INIT_GV))
		sv_catpv(RETVAL, ",DONT_INIT_GV");
#endif
        else if (o->op_type == OP_CONST) {
#ifdef OPpCONST_BARE
            if (o->op_private & OPpCONST_BARE)
                sv_catpv(RETVAL, ",BARE");
#endif
#ifdef OPpCONST_STRICT
            if (o->op_private & OPpCONST_STRICT)
                sv_catpv(RETVAL, ",STRICT");
#endif
#ifdef OPpCONST_ARYBASE
            if (o->op_private & OPpCONST_ARYBASE)
                sv_catpv(RETVAL, ",ARYBASE");
#endif
#ifdef OPpCONST_WARNING
            if (o->op_private & OPpCONST_WARNING)
                sv_catpv(RETVAL, ",WARNING");
#endif
#ifdef OPpCONST_ENTERED
            if (o->op_private & OPpCONST_ENTERED)
                sv_catpv(RETVAL, ",ENTERED");
#endif
#ifdef OPpCONST_NOVER
            if (o->op_private & OPpCONST_NOVER)
                sv_catpv(RETVAL, ",NOVER");
#endif
#ifdef OPpCONST_SHORTCIRCUIT
            if (o->op_private & OPpCONST_SHORTCIRCUIT)
                sv_catpv(RETVAL, ",SHORTCIRCUIT");
#endif
        }
#ifdef OPpFLIP_LINENUM
        else if (o->op_type == OP_FLIP) {
            if (o->op_private & OPpFLIP_LINENUM)
                sv_catpv(RETVAL, ",LINENUM");
        }
        else if (o->op_type == OP_FLOP) {
            if (o->op_private & OPpFLIP_LINENUM)
                sv_catpv(RETVAL, ",LINENUM");
        }
#endif
        else if (o->op_type == OP_RV2CV) {
#ifdef OPpLVAL_INTRO
            if (o->op_private & OPpLVAL_INTRO)
                sv_catpv(RETVAL, ",INTRO");
#endif
#ifdef OPpMAY_RETURN_CONSTANT
            if (o->op_private & OPpMAY_RETURN_CONSTANT)
                sv_catpv(RETVAL, ",MAY_RETURN_CONSTANT");
#endif
        }
#ifdef OPpEARLY_CV
        else if (o->op_type == OP_GV) {
            if (o->op_private & OPpEARLY_CV)
                sv_catpv(RETVAL, ",EARLY_CV");
        }
#endif
#ifdef OPpLIST_GUESSED
        else if (o->op_type == OP_LIST) {
            if (o->op_private & OPpLIST_GUESSED)
                sv_catpv(RETVAL, ",GUESSED");
        }
#endif
#ifdef OPpSLICE
        else if (o->op_type == OP_DELETE) {
            if (o->op_private & OPpSLICE)
                sv_catpv(RETVAL, ",SLICE");
        }
#endif
#ifdef OPpEXISTS_SUB
        else if (o->op_type == OP_EXISTS) {
            if (o->op_private & OPpEXISTS_SUB)
                sv_catpv(RETVAL, ",EXISTS_SUB");
        }
#endif
        else if (o->op_type == OP_SORT) {
#ifdef OPpSORT_NUMERIC
            if (o->op_private & OPpSORT_NUMERIC)
                sv_catpv(RETVAL, ",NUMERIC");
#endif
#ifdef OPpSORT_INTEGER
            if (o->op_private & OPpSORT_INTEGER)
                sv_catpv(RETVAL, ",INTEGER");
#endif
#ifdef OPpSORT_REVERSE
            if (o->op_private & OPpSORT_REVERSE)
                sv_catpv(RETVAL, ",REVERSE");
#endif
#ifdef OPpSORT_INPLACE
            if (o->op_private & OPpSORT_INPLACE)
                sv_catpv(RETVAL, ",INPLACE");
#endif
#ifdef OPpSORT_DESCEND
            if (o->op_private & OPpSORT_DESCEND)
                sv_catpv(RETVAL, ",DESCEND");
#endif
#ifdef OPpSORT_QSORT
            if (o->op_private & OPpSORT_QSORT)
                sv_catpv(RETVAL, ",QSORT");
#endif
#ifdef OPpSORT_STABLE
            if (o->op_private & OPpSORT_STABLE)
                sv_catpv(RETVAL, ",STABLE");
#endif
        }
#if defined(OPpDONE_SVREF) && (PERL_VERSION < 9)
        else if (o->op_type == OP_THREADSV) {
            if (o->op_private & OPpDONE_SVREF)
                sv_catpv(RETVAL, ",SVREF");
        }
#elsif defined(OPpDONE_SVREF)
        else if (o->op_private & OPpDONE_SVREF)
                sv_catpv(RETVAL, ",SVREF");
#endif
        else if (o->op_type == OP_OPEN || o->op_type == OP_BACKTICK) {
#ifdef OPpOPEN_IN_RAW
            if (o->op_private & OPpOPEN_IN_RAW)
                sv_catpv(RETVAL, ",IN_RAW");
#endif
#ifdef OPpOPEN_IN_CRLF
            if (o->op_private & OPpOPEN_IN_CRLF)
                sv_catpv(RETVAL, ",IN_CRLF");
#endif
#ifdef OPpOPEN_OUT_RAW
            if (o->op_private & OPpOPEN_OUT_RAW)
                sv_catpv(RETVAL, ",OUT_RAW");
#endif
#ifdef OPpOPEN_OUT_CRLF
            if (o->op_private & OPpOPEN_OUT_CRLF)
                sv_catpv(RETVAL, ",OUT_CRLF");
#endif
        }
        else if (o->op_type == OP_EXIT) {
#ifdef OPpEXIT_VMSISH
            if (o->op_private & OPpEXIT_VMSISH)
                sv_catpv(RETVAL, ",EXIST_VMSISH");
#endif
#if PERL_VERSION < 19
# ifdef OPpHUSH_VMSISH
            if (o->op_private & OPpHUSH_VMSISH)
                sv_catpv(RETVAL, ",HUSH_VMSISH");
# endif
#else
        }
        else if (o->op_type == OP_NEXTSTATE || o->op_type == OP_DBSTATE) {
# ifdef OPpHUSH_VMSISH
            if (o->op_private & OPpHUSH_VMSISH)
                sv_catpv(RETVAL, ",HUSH_VMSISH");
# endif
#endif
        }
#ifdef OPpLVAL_INTRO
        if (o->op_flags & OPf_MOD && o->op_private & OPpLVAL_INTRO)
            sv_catpv(RETVAL, ",INTRO");
#endif
#ifdef OP_IS_FILETEST_ACCESS
# if (PERL_VERSION < 11)
	if (OP_IS_FILETEST_ACCESS(o)) {
# else
	if (OP_IS_FILETEST_ACCESS(o->op_type)) {
# endif
# ifdef OPpFT_ACCESS
            if (o->op_private & OPpFT_ACCESS)
                sv_catpv(RETVAL, ",FT_ACCESS");
# endif
# ifdef OPpFT_STACKED
            if (o->op_private & OPpFT_STACKED)
                sv_catpv(RETVAL, ",FT_STACKED");
# endif
	}
#endif
#ifdef OPpGREP_LEX
        else if (o->op_type == OP_MAPSTART  ||
		 o->op_type == OP_MAPWHILE  ||
                 o->op_type == OP_GREPSTART ||
                 o->op_type == OP_GREPWHILE ) {
            if (o->op_private & OPpGREP_LEX)
                sv_catpv(RETVAL, ",GREP_LEX");
	}
#endif
#ifdef OPpEVAL_HAS_HH
        else if (o->op_type == OP_ENTEREVAL ) {
            if (o->op_private & OPpEVAL_HAS_HH)
                sv_catpv(RETVAL, ",EVAL_HAS_HH");
	}
#endif

        if (SvCUR(RETVAL))
            sv_chop(RETVAL, SvPVX(RETVAL)+1);
    OUTPUT:
        RETVAL

MODULE = B::Flags		PACKAGE = B::SV

SV*
flagspv(sv, type=-1)
    B::SV sv
    I32 type
    U32 flags = NO_INIT
    U32 sv_type = NO_INIT
    CODE:
        if (!sv) XSRETURN_UNDEF;
        RETVAL = newSVpvn("", 0);
        flags = SvFLAGS(sv);
        sv_type = SvTYPE(sv);
        if (type <= 0) {
#ifdef SVs_PADBUSY
        if (flags & SVs_PADBUSY)    sv_catpv(RETVAL, "PADBUSY,");
#endif
#ifdef SVs_PADSTALE
        if (flags & SVs_PADSTALE)   sv_catpv(RETVAL, "PADSTALE,");
#endif
        if (flags & SVs_PADTMP)     sv_catpv(RETVAL, "PADTMP,");
        if (flags & SVs_PADMY)      sv_catpv(RETVAL, "PADMY,");
        if (flags & SVs_TEMP)       sv_catpv(RETVAL, "TEMP,");
        if (flags & SVs_OBJECT)     sv_catpv(RETVAL, "OBJECT,");
        if (flags & SVs_GMG)        sv_catpv(RETVAL, "GMG,");
        if (flags & SVs_SMG)        sv_catpv(RETVAL, "SMG,");
        if (flags & SVs_RMG)        sv_catpv(RETVAL, "RMG,");

        if (flags & SVf_IOK)        sv_catpv(RETVAL, "IOK,");
        if (flags & SVf_NOK)        sv_catpv(RETVAL, "NOK,");
        if (flags & SVf_POK)        sv_catpv(RETVAL, "POK,");
        if (flags & SVf_ROK)  {
                                    sv_catpv(RETVAL, "ROK,");
            if (SvWEAKREF(sv))      sv_catpv(RETVAL, "WEAKREF,");
        }
        if (flags & SVf_OOK)        sv_catpv(RETVAL, "OOK,");
        if (flags & SVf_FAKE)       sv_catpv(RETVAL, "FAKE,");
        if (flags & SVf_READONLY)   sv_catpv(RETVAL, "READONLY,");
#ifdef SVf_PROTECT
        if (flags & SVf_PROTECT)    sv_catpv(RETVAL, "PROTECT,");
#endif
#ifdef SVf_BREAK
        if (flags & SVf_BREAK)      sv_catpv(RETVAL, "BREAK,");
#endif
        if (flags & SVf_AMAGIC)     sv_catpv(RETVAL, "OVERLOAD,");
        if (flags & SVp_IOK)        sv_catpv(RETVAL, "pIOK,");
        if (flags & SVp_NOK)        sv_catpv(RETVAL, "pNOK,");
        if (flags & SVp_POK)        sv_catpv(RETVAL, "pPOK,");
#ifdef SvVOK
        if (SvVOK(sv))              sv_catpv(RETVAL, "VOK,");
#endif
#ifdef SVphv_CLONEABLE /* since 5.8.8 */
        if ((flags & SVphv_CLONEABLE) && (sv_type == SVt_PVHV))
				    sv_catpv(RETVAL, "CLONEABLE,");
        else
#endif
#ifdef SVpgv_GP /* since 5.10 */
	  if ((flags & SVpgv_GP) && (sv_type == SVt_PVGV))
				    sv_catpv(RETVAL, "isGV_with_GP,");
          else
#endif
#ifdef SVpad_NAMELIST /* 5.19.3 - 5.21 */
	  if ((flags & SVpad_NAMELIST) && (sv_type == SVt_PVAV))
				    sv_catpv(RETVAL, "NAMELIST,");
          else
#endif
#if PERL_VERSION < 22            
#if defined(SVpad_NAME) /* 5.10 - 5.20, 5.22 see PADNAME */
          if (flags & SVpad_NAME) {
            if (flags & SVpad_STATE)  sv_catpv(RETVAL, "STATE,");
            if (flags & SVpad_TYPED)  sv_catpv(RETVAL, "TYPED,");
            if (flags & SVpad_OUR)    sv_catpv(RETVAL, "OUR,");
          }
          else
#else /* 5.6 - 5.8 */
#ifdef SVpad_TYPED
          if (flags & SVpad_TYPED)  sv_catpv(RETVAL, "TYPED,");
#endif
          if (flags & SVpad_OUR)    sv_catpv(RETVAL, "OUR,");
#endif
#endif
#ifdef SVprv_PCS_IMPORTED /* since 5.8.9, RV is a proxy for a constant */
          if (flags & SVf_ROK && flags & SVprv_PCS_IMPORTED)
                                    sv_catpv(RETVAL, "PCS_IMPORTED,");
          else
#endif
#ifdef SVp_SCREAM
          if (flags & SVp_SCREAM)   sv_catpv(RETVAL, "SCREAM,");
#endif
#ifdef SVpav_REAL
          if ((flags & SVpav_REAL) && (sv_type == SVt_PVAV))
                                    sv_catpv(RETVAL, "REAL,");
#endif
#ifdef SVpav_REIFY
          if ((flags & SVpav_REIFY) && (sv_type == SVt_PVAV)) 
                                    sv_catpv(RETVAL, "REIFY,");
#endif
	}
#ifdef SVf_IsCOW
        if (flags & SVf_IsCOW)
            sv_catpv(RETVAL, "IsCOW,");
        else
#endif
#ifdef SVf_THINKFIRST
        if (flags & SVf_THINKFIRST)
            sv_catpv(RETVAL, "THINKFIRST,");
#endif
        if (sv_type == SVt_PVHV) {
          if (HvSHAREKEYS(sv))    sv_catpv(RETVAL, "SHAREKEYS,");
          if (HvLAZYDEL(sv))      sv_catpv(RETVAL, "LAZYDEL,");
        }
      /*if (SvEVALED(sv))       sv_catpv(RETVAL, "EVALED,");*/ /* rhs regex only */
        if (SvIsUV(sv))         sv_catpv(RETVAL, "IsUV,");
        if (SvUTF8(sv))         sv_catpv(RETVAL, "UTF8,");
        switch (type == -1 ? sv_type : type) {
          /* CvFLAGS */
        case SVt_PVCV:
        case SVt_PVFM:
            if (CvANON(sv))         sv_catpv(RETVAL, "ANON,");
#ifdef CvEVAL
            if (CvEVAL(sv))         sv_catpv(RETVAL, "EVAL,");
	    else if (CvUNIQUE(sv))  sv_catpv(RETVAL, "UNIQUE,");
#else
            if (CvUNIQUE(sv))       sv_catpv(RETVAL, "UNIQUE,");
#endif
            if (CvCLONE(sv))        sv_catpv(RETVAL, "CLONE,");
            if (CvCLONED(sv))       sv_catpv(RETVAL, "CLONED,");
#ifdef CvCONST
            if (CvCONST(sv))        sv_catpv(RETVAL, "CONST,");
#endif
            if (CvNODEBUG(sv))      sv_catpv(RETVAL, "NODEBUG,");
            if (SvCOMPILED(sv))     sv_catpv(RETVAL, "COMPILED,");
#ifdef CVf_BUILTIN_ATTRS
	    if (CvFLAGS(sv) == CVf_BUILTIN_ATTRS) 
	                            sv_catpv(RETVAL, "BUILTIN_ATTRS,");
	    else {
	      if (CvLVALUE(sv))     sv_catpv(RETVAL, "LVALUE,");
	      if (CvMETHOD(sv))     sv_catpv(RETVAL, "METHOD,");
	    }
#else
            if (CvLVALUE(sv))       sv_catpv(RETVAL, "LVALUE,");
            if (CvMETHOD(sv))       sv_catpv(RETVAL, "METHOD,");
#endif
#ifdef CvWEAKOUTSIDE
            if (CvWEAKOUTSIDE(sv))  sv_catpv(RETVAL, "WEAKOUTSIDE,");
#endif
#ifdef CvISXSUB
            if (CvISXSUB(sv))       sv_catpv(RETVAL, "ISXSUB,");
#endif
#ifdef CvCVGV_RC
            if (CvCVGV_RC(sv))      sv_catpv(RETVAL, "CVGV_RC,");
#endif
            break;
#ifdef AVf_REAL
          /* AvFLAGS */
        case SVt_PVAV:
            if (AvREAL(sv))         sv_catpv(RETVAL, "REAL,");
            if (AvREIFY(sv))        sv_catpv(RETVAL, "REIFY,");
            if (AvREUSED(sv))       sv_catpv(RETVAL, "REUSED,");
            break;
#endif
        case SVt_PVBM: /* == PVMG */
#ifdef SVpbm_TAIL
            if (!(flags & SVp_SCREAM)) {
                if (SvTAIL(sv))         sv_catpv(RETVAL, "TAIL,");
#endif
#ifdef SvVALID_on
                if (SvVALID(sv))        sv_catpv(RETVAL, "VALID,");
#endif
#ifdef SVpbm_TAIL
            }
#endif
            break;
#if SVt_PVBM != SVt_PVMG
        case SVt_PVMG:
#if PERL_VERSION < 10 && defined(SvPAD_TYPED) /* 5.8 */
            if (SvPAD_TYPED(sv))    sv_catpv(RETVAL, "TYPED,");
            if (SvPAD_OUR(sv))      sv_catpv(RETVAL, "OUR,");
#endif
            break;
#endif
          /* GvFLAGS */
        case SVt_PVGV:
            if (GvINTRO(sv))        sv_catpv(RETVAL, "INTRO,");
            if (GvMULTI(sv))        sv_catpv(RETVAL, "MULTI,");
#ifdef GvSHARED
            if (GvSHARED(sv))       sv_catpv(RETVAL, "SHARED,");
#endif
            if (GvASSUMECV(sv))     sv_catpv(RETVAL, "ASSUMECV,");
            if (GvIN_PAD(sv))       sv_catpv(RETVAL, "IN_PAD,");
            if (GvIMPORTED(sv)) {
                sv_catpv(RETVAL, "IMPORTED");
                if (GvIMPORTED(sv) == GVf_IMPORTED)
                    sv_catpv(RETVAL, "_ALL,");
                else {
                    sv_catpv(RETVAL, "(");
                    if (GvIMPORTED_SV(sv))  sv_catpv(RETVAL, " SV");
                    if (GvIMPORTED_AV(sv))  sv_catpv(RETVAL, " AV");
                    if (GvIMPORTED_HV(sv))  sv_catpv(RETVAL, " HV");
                    if (GvIMPORTED_CV(sv))  sv_catpv(RETVAL, " CV");
                    sv_catpv(RETVAL, " ),");
                }
            }
            /* FALL THROUGH */
        default:
            /*sv_catpvf(RETVAL, "%d", sv_type); */
            break;
        }
        if (SvCUR(RETVAL) && (*(SvEND(RETVAL) - 1) == ',')) {
#if defined(__clang__) && __clang_major__ <= 1 && __clang_minor__ < 8
	  --SvCUR(RETVAL);
	  SvPVX(RETVAL)[SvCUR(RETVAL)] = '\0';
#else
	  SvPVX(RETVAL)[--SvCUR(RETVAL)] = '\0';
#endif
	}
    OUTPUT:
        RETVAL

MODULE = B::Flags		PACKAGE = B::PADNAME

#ifdef PadnameFLAGS

SV*
flagspv(sv, type=-1)
    B::SV sv
    I32 type
    PADNAME *pn = NO_INIT
    U32 flags = NO_INIT
    U32 sv_type = NO_INIT
    CODE:
        if (!sv) XSRETURN_UNDEF;
        RETVAL = newSVpvs("");
        pn = (PADNAME*)sv;
        flags = PadnameFLAGS(pn);
	if (PadnameOUTER(pn)) 		sv_catpv(RETVAL, "OUTER,");
	if (PadnameIsSTATE(pn)) 	sv_catpv(RETVAL, "STATE,");
	if (PadnameLVALUE(pn)) 		sv_catpv(RETVAL, "LVALUE,");
	if (SvPAD_TYPED(pn)) 		sv_catpv(RETVAL, "TYPED,");
	if (SvPAD_OUR(pn)) 		sv_catpv(RETVAL, "OUR,");
        if (flags & PAD_FAKELEX_ANON)   sv_catpv(RETVAL, "PAD_FAKELEX_ANON,");
        if (flags & PAD_FAKELEX_MULTI)  sv_catpv(RETVAL, "PAD_FAKELEX_MULTI,");
        if (SvCUR(RETVAL) && (*(SvEND(RETVAL) - 1) == ',')) {
#if defined(__clang__) && __clang_major__ <= 1 && __clang_minor__ < 8
	  --SvCUR(RETVAL);
	  SvPVX(RETVAL)[SvCUR(RETVAL)] = '\0';
#else
	  SvPVX(RETVAL)[--SvCUR(RETVAL)] = '\0';
#endif
	}
    OUTPUT:
        RETVAL

#endif

MODULE = B::Flags		PACKAGE = B::PADNAMELIST

#ifdef newPADNAMELIST

SV*
flagspv(sv, ...)
    B::SV sv
    CODE:
        RETVAL = newSVpvs("");
    OUTPUT:
        RETVAL

#endif

MODULE = B::Flags		PACKAGE = B::PADLIST

#ifdef PadlistARRAY

SV*
flagspv(sv, ...)
    B::SV sv
    CODE:
        RETVAL = newSVpvs("");
    OUTPUT:
        RETVAL

#endif
