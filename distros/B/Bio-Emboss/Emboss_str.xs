#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_str		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajstr.c: automatically generated

char*
ajCharNewC (txt)
       const char* txt
    OUTPUT:
       RETVAL

char*
ajCharNewS (str)
       const AjPStr str
    OUTPUT:
       RETVAL

char*
ajCharNewRes (size)
       ajuint size
    OUTPUT:
       RETVAL

char*
ajCharNewResC (txt, size)
       const char* txt
       ajuint size
    OUTPUT:
       RETVAL

char*
ajCharNewResS (str, size)
       const AjPStr str
       ajuint size
    OUTPUT:
       RETVAL

char*
ajCharNewResLenC (txt, size, len)
       const char* txt
       ajuint size
       ajuint len
    OUTPUT:
       RETVAL

void
ajCharDel (Ptxt)
       char*& Ptxt
    OUTPUT:
       Ptxt

AjBool
ajCharFmtLower (txt)
       char* txt
    OUTPUT:
       RETVAL
       txt

AjBool
ajCharFmtUpper (txt)
       char* txt
    OUTPUT:
       RETVAL
       txt

AjBool
ajCharMatchC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharMatchCaseC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildS (txt, str)
       const char* txt
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildNextC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildWordC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharPrefixC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharPrefixS (txt, str)
       const char* txt
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajCharPrefixCaseC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharPrefixCaseS (txt, str)
       const char* txt
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajCharSuffixC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharSuffixS (txt, str)
       const char* txt
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajCharSuffixCaseC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharSuffixCaseS (txt, str)
       const char* txt
       const AjPStr str
    OUTPUT:
       RETVAL

int
ajCharCmpCase (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

int
ajCharCmpCaseLen (txt, txt2, len)
       const char* txt
       const char* txt2
       ajuint len
    OUTPUT:
       RETVAL

int
ajCharCmpWild (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjPStr
ajCharParseC (txt, txtdelim)
       const char* txt
       const char* txtdelim
    OUTPUT:
       RETVAL

AjPStr
ajStrNew ()
    OUTPUT:
       RETVAL

AjPStr
ajStrNewC (txt)
       const char* txt
    OUTPUT:
       RETVAL

AjPStr
ajStrNewS (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjPStr
ajStrNewRef (refstr)
       AjPStr refstr
    OUTPUT:
       RETVAL

AjPStr
ajStrNewRes (size)
       ajuint size
    OUTPUT:
       RETVAL

AjPStr
ajStrNewResC (txt, size)
       const char* txt
       ajuint size
    OUTPUT:
       RETVAL

AjPStr
ajStrNewResS (str, size)
       const AjPStr str
       ajuint size
    OUTPUT:
       RETVAL

AjPStr
ajStrNewResLenC (txt, size, len)
       const char* txt
       ajuint size
       ajuint len
    OUTPUT:
       RETVAL

void
ajStrDel (Pstr)
       AjPStr& Pstr
    OUTPUT:
       Pstr

AjBool
ajStrDelStatic (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

void
ajStrDelarray (PPstr)
       AjPStr*& PPstr
    OUTPUT:
       PPstr

AjBool
ajStrAssignC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignK (Pstr, chr)
       AjPStr& Pstr
       char chr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignS (Pstr, str)
       AjPStr& Pstr
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignEmptyC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignEmptyS (Pstr, str)
       AjPStr& Pstr
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignLenC (Pstr, txt, len)
       AjPStr& Pstr
       const char* txt
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignRef (Pstr, refstr)
       AjPStr& Pstr
       AjPStr refstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignResC (Pstr, size, txt)
       AjPStr& Pstr
       ajuint size
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignResS (Pstr, size, str)
       AjPStr& Pstr
       ajuint size
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignSubC (Pstr, txt, pos1, pos2)
       AjPStr& Pstr
       const char* txt
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAssignSubS (Pstr, str, pos1, pos2)
       AjPStr& Pstr
       const AjPStr str
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAppendC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAppendK (Pstr, chr)
       AjPStr& Pstr
       char chr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAppendS (Pstr, str)
       AjPStr& Pstr
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAppendCountK (Pstr, chr, num)
       AjPStr& Pstr
       char chr
       ajuint num
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAppendLenC (Pstr, txt, len)
       AjPStr& Pstr
       const char* txt
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrAppendSubS (Pstr, str, pos1, pos2)
       AjPStr& Pstr
       const AjPStr str
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrInsertC (Pstr, pos, txt)
       AjPStr& Pstr
       ajint pos
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrInsertK (Pstr, pos, chr)
       AjPStr& Pstr
       ajint pos
       char chr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrInsertS (Pstr, pos, str)
       AjPStr& Pstr
       ajint pos
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrJoinC (Pstr, pos, txt, posb)
       AjPStr& Pstr
       ajint pos
       const char* txt
       ajint posb
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrJoinS (Pstr, pos, str, posb)
       AjPStr& Pstr
       ajint pos
       const AjPStr str
       ajint posb
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrMask (Pstr, pos1, pos2, maskchr)
       AjPStr& Pstr
       ajint pos1
       ajint pos2
       char maskchr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrPasteS (Pstr, pos, str)
       AjPStr& Pstr
       ajint pos
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrPasteCountK (Pstr, pos, chr, num)
       AjPStr& Pstr
       ajint pos
       char chr
       ajuint num
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrPasteMaxC (Pstr, pos, txt, len)
       AjPStr& Pstr
       ajint pos
       const char* txt
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrPasteMaxS (Pstr, pos, str, len)
       AjPStr& Pstr
       ajint pos
       const AjPStr str
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrCutComments (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrCutCommentsStart (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrCutEnd (Pstr, len)
       AjPStr& Pstr
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrCutRange (Pstr, pos1, pos2)
       AjPStr& Pstr
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrCutStart (Pstr, len)
       AjPStr& Pstr
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrKeepRange (Pstr, pos1, pos2)
       AjPStr& Pstr
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrKeepSetC (Pstr, txt)
       AjPStr & Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrKeepSetAlphaC (Pstr, txt)
       AjPStr & Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrQuoteStrip (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrQuoteStripAll (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveGap (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveHtml (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveLastNewline (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveSetC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveWhite (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveWhiteExcess (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveWild (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTrimC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTrimEndC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTrimStartC (Pstr, txt)
       AjPStr& Pstr
       const char* txt
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTrimWhite (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTrimWhiteEnd (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTruncateLen (Pstr, len)
       AjPStr& Pstr
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrTruncatePos (Pstr, pos)
       AjPStr& Pstr
       ajint pos
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeCC (Pstr, txt, txtnew)
       AjPStr& Pstr
       const char* txt
       const char* txtnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeCS (Pstr, txt, strnew)
       AjPStr& Pstr
       const char* txt
       const AjPStr strnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeKK (Pstr, chr, chrnew)
       AjPStr& Pstr
       char chr
       char chrnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeSC (Pstr, str, txtnew)
       AjPStr& Pstr
       const AjPStr str
       const char* txtnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeSS (Pstr, str, strnew)
       AjPStr& Pstr
       const AjPStr str
       const AjPStr strnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeSetCC (Pstr, txt, txtnew)
       AjPStr& Pstr
       const char* txt
       const char* txtnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeSetSS (Pstr, str, strnew)
       AjPStr& Pstr
       const AjPStr str
       const AjPStr strnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRandom (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrReverse (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

ajuint
ajStrCalcCountC (str, txt)
       const AjPStr str
       const char* txt
    OUTPUT:
       RETVAL

ajuint
ajStrCalcCountK (str, chr)
       const AjPStr str
       char chr
    OUTPUT:
       RETVAL

AjBool
ajStrHasParentheses (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsAlnum (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsAlpha (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsBool (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsDouble (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsFloat (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsHex (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsInt (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsLong (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsLower (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsNum (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsUpper (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsWhite (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsWild (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrIsWord (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrWhole (str, pos1, pos2)
       const AjPStr str
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL

char
ajStrGetCharFirst (str)
       const AjPStr str
    OUTPUT:
       RETVAL

char
ajStrGetCharLast (str)
       const AjPStr str
    OUTPUT:
       RETVAL

char
ajStrGetCharPos (str, pos)
       const AjPStr str
       ajint pos
    OUTPUT:
       RETVAL

ajuint
ajStrGetLen (str)
       const AjPStr str
    OUTPUT:
       RETVAL

const char*
ajStrGetPtr (str)
       const AjPStr str
    OUTPUT:
       RETVAL

ajuint
ajStrGetRes (str)
       const AjPStr str
    OUTPUT:
       RETVAL

ajuint
ajStrGetRoom (str)
       const AjPStr str
    OUTPUT:
       RETVAL

ajuint
ajStrGetUse (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajStrGetValid (str)
       const AjPStr str
    OUTPUT:
       RETVAL

char*
ajStrGetuniquePtr (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjPStr
ajStrGetuniqueStr (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrSetClear (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrSetRes (Pstr, size)
       AjPStr& Pstr
       ajuint size
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrSetResRound (Pstr, size)
       AjPStr& Pstr
       ajuint size
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrSetValid (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrSetValidLen (Pstr, len)
       AjPStr& Pstr
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrToBool (str, Pval)
       const AjPStr str
       AjBool& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrToDouble (str, Pval)
       const AjPStr str
       double& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrToFloat (str, Pval)
       const AjPStr str
       float& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrToHex (str, Pval)
       const AjPStr str
       ajint& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrToInt (str, Pval)
       const AjPStr str
       ajint& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrToLong (str, Pval)
       const AjPStr str
       ajlong& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrFromBool (Pstr, val)
       AjPStr& Pstr
       AjBool val
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFromDouble (Pstr, val, precision)
       AjPStr& Pstr
       double val
       ajint precision
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFromDoubleExp (Pstr, val, precision)
       AjPStr& Pstr
       double val
       ajint precision
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFromFloat (Pstr, val, precision)
       AjPStr& Pstr
       float val
       ajint precision
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFromInt (Pstr, val)
       AjPStr& Pstr
       ajint val
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFromLong (Pstr, val)
       AjPStr& Pstr
       ajlong val
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtBlock (Pstr, len)
       AjPStr& Pstr
       ajuint len
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtLower (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtLowerSub (Pstr, pos1, pos2)
       AjPStr& Pstr
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtQuote (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtTitle (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtUpper (Pstr)
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtUpperSub (Pstr, pos1, pos2)
       AjPStr& Pstr
       ajint pos1
       ajint pos2
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtWrap (Pstr, width)
       AjPStr& Pstr
       ajuint width
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtWrapLeft (Pstr, width, margin)
       AjPStr& Pstr
       ajuint width
       ajuint margin
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrMatchC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildWordC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildWordS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWordAllS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWordOneS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrSuffixC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrSuffixS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

int
ajStrCmpC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

int
ajStrCmpLenC (str, txt2, len)
       const AjPStr str
       const char* txt2
       ajuint len
    OUTPUT:
       RETVAL

int
ajStrCmpS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

int
ajStrCmpCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

int
ajStrCmpLenS (str, str2, len)
       const AjPStr str
       const AjPStr str2
       ajuint len
    OUTPUT:
       RETVAL

int
ajStrCmpWildC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

int
ajStrCmpWildS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

int
ajStrVcmp (str, str2)
       const char* str
       const char* str2
    OUTPUT:
       RETVAL

ajint
ajStrFindC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

ajint
ajStrFindS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

ajint
ajStrFindAnyC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

ajint
ajStrFindAnyK (str, chr)
       const AjPStr str
       char chr
    OUTPUT:
       RETVAL

ajint
ajStrFindAnyS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

ajint
ajStrFindCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

ajint
ajStrFindCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

ajint
ajStrFindlastC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

ajint
ajStrFindlastS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrExtractFirst (str, Prest, Pword)
       const AjPStr str
       AjPStr& Prest
       AjPStr& Pword
    OUTPUT:
       RETVAL
       Prest
       Pword

AjBool
ajStrExtractWord (str, Prest, Pword)
       const AjPStr str
       AjPStr& Prest
       AjPStr& Pword
    OUTPUT:
       RETVAL
       Prest
       Pword

const AjPStr
ajStrParseC (str, txtdelim)
       const AjPStr str
       const char* txtdelim
    OUTPUT:
       RETVAL

ajuint
ajStrParseCount (str)
       const AjPStr str
    OUTPUT:
       RETVAL

ajuint
ajStrParseCountC (str, txtdelim)
       const AjPStr str
       const char * txtdelim
    OUTPUT:
       RETVAL

ajuint
ajStrParseCountS (str, strdelim)
       const AjPStr str
       const AjPStr strdelim
    OUTPUT:
       RETVAL

ajuint
ajStrParseCountMultiC (str, txtdelim)
       const AjPStr str
       const char * txtdelim
    OUTPUT:
       RETVAL

ajuint
ajStrParseSplit (str, PPstr)
       const AjPStr str
       AjPStr*& PPstr
    OUTPUT:
       RETVAL
       PPstr

const AjPStr
ajStrParseWhite (str)
       const AjPStr str
    OUTPUT:
       RETVAL

void
ajStrStat (title)
       const char* title

void
ajStrTrace (str)
       const AjPStr str

void
ajStrTraceFull (str)
       const AjPStr str

void
ajStrTraceTitle (str, title)
       const AjPStr str
       const char* title

void
ajStrExit ()

AjIStr
ajStrIterNew (str)
       const AjPStr str
    OUTPUT:
       RETVAL

AjIStr
ajStrIterNewBack (str)
       const AjPStr str
    OUTPUT:
       RETVAL

void
ajStrIterDel (iter)
       AjIStr& iter
    OUTPUT:
       iter

AjBool
ajStrIterDone (iter)
       const AjIStr iter
    OUTPUT:
       RETVAL

AjBool
ajStrIterDoneBack (iter)
       const AjIStr iter
    OUTPUT:
       RETVAL

void
ajStrIterBegin (iter)
       AjIStr iter

void
ajStrIterEnd (iter)
       AjIStr iter

const char*
ajStrIterGetC (iter)
       const AjIStr iter
    OUTPUT:
       RETVAL

char
ajStrIterGetK (iter)
       const AjIStr iter
    OUTPUT:
       RETVAL

void
ajStrIterPutK (iter, chr)
       AjIStr iter
       char chr

AjIStr
ajStrIterNext (iter)
       AjIStr iter
    OUTPUT:
       RETVAL

AjIStr
ajStrIterNextBack (iter)
       AjIStr iter
    OUTPUT:
       RETVAL

AjPStrTok
ajStrTokenNewC (str, txtdelim)
       const AjPStr str
       const char* txtdelim
    OUTPUT:
       RETVAL

AjPStrTok
ajStrTokenNewS (str, strdelim)
       const AjPStr str
       const AjPStr strdelim
    OUTPUT:
       RETVAL

void
ajStrTokenDel (Ptoken)
       AjPStrTok& Ptoken
    OUTPUT:
       Ptoken

AjBool
ajStrTokenAssign (Ptoken, str)
       AjPStrTok& Ptoken
       const AjPStr str
    OUTPUT:
       RETVAL
       Ptoken

AjBool
ajStrTokenAssignC (Ptoken, str, txtdelim)
       AjPStrTok& Ptoken
       const AjPStr str
       const char* txtdelim
    OUTPUT:
       RETVAL
       Ptoken

AjBool
ajStrTokenAssignS (Ptoken, str, strdelim)
       AjPStrTok& Ptoken
       const AjPStr str
       const AjPStr strdelim
    OUTPUT:
       RETVAL
       Ptoken

void
ajStrTokenReset (Ptoken)
       AjPStrTok& Ptoken
    OUTPUT:
       Ptoken

void
ajStrTokenTrace (token)
       const AjPStrTok token

AjBool
ajStrTokenNextFind (Ptoken, Pstr)
       AjPStrTok& Ptoken
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Ptoken
       Pstr

AjBool
ajStrTokenNextFindC (Ptoken, txtdelim, Pstr)
       AjPStrTok& Ptoken
       const char* txtdelim
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Ptoken
       Pstr

AjBool
ajStrTokenNextParse (Ptoken, Pstr)
       AjPStrTok& Ptoken
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Ptoken
       Pstr

AjBool
ajStrTokenNextParseC (Ptoken, txtdelim, Pstr)
       AjPStrTok& Ptoken
       const char* txtdelim
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Ptoken
       Pstr

AjBool
ajStrTokenNextParseS (Ptoken, strdelim, Pstr)
       AjPStrTok& Ptoken
       const AjPStr strdelim
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Ptoken
       Pstr

AjBool
ajStrTokenRestParse (Ptoken, Pstr)
       AjPStrTok& Ptoken
       AjPStr& Pstr
    OUTPUT:
       RETVAL
       Ptoken
       Pstr

AjBool
ajCharMatchWildCaseC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildCaseS (txt, str)
       const char* txt
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildNextCaseC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajCharMatchWildWordCaseC (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

int
ajCharCmpWildCase (txt, txt2)
       const char* txt
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrKeepSetS (Pstr, str)
       AjPStr & Pstr
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrKeepSetAlpha (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrRemoveWhiteSpaces (Pstr)
       AjPStr & Pstr
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeSetRestCK (Pstr, txt, chrnew)
       AjPStr& Pstr
       const char* txt
       char chrnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrExchangeSetRestSK (Pstr, str, chrnew)
       AjPStr& Pstr
       const AjPStr str
       char chrnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrIsCharsetC (str, txt)
       const AjPStr str
       const char* txt
    OUTPUT:
       RETVAL

AjBool
ajStrIsCharsetS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrIsCharsetCaseC (str, txt)
       const AjPStr str
       const char* txt
    OUTPUT:
       RETVAL

AjBool
ajStrIsCharsetCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrToUint (str, Pval)
       const AjPStr str
       ajuint& Pval
    OUTPUT:
       RETVAL
       Pval

AjBool
ajStrFromUint (Pstr, val)
       AjPStr& Pstr
       ajuint val
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrMatchWildCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildWordCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildWordCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrSuffixCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

AjBool
ajStrSuffixCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

int
ajStrCmpWildCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

int
ajStrCmpWildCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

ajint
ajStrFindRestC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

ajint
ajStrFindRestS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

ajint
ajStrFindRestCaseC (str, txt2)
       const AjPStr str
       const char* txt2
    OUTPUT:
       RETVAL

ajint
ajStrFindRestCaseS (str, str2)
       const AjPStr str
       const AjPStr str2
    OUTPUT:
       RETVAL

AjBool
ajStrKeepSetAlphaS (Pstr, str)
       AjPStr & Pstr
       const AjPStr str
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrKeepSetAlphaRest (Pstr, Prest)
       AjPStr & Pstr
       AjPStr & Prest
    OUTPUT:
       RETVAL
       Pstr
       Prest

AjBool
ajStrKeepSetAlphaRestC (Pstr, txt, Prest)
       AjPStr & Pstr
       const char* txt
       AjPStr & Prest
    OUTPUT:
       RETVAL
       Pstr
       Prest

AjBool
ajStrKeepSetAlphaRestS (Pstr, str, Prest)
       AjPStr & Pstr
       const AjPStr str
       AjPStr & Prest
    OUTPUT:
       RETVAL
       Pstr
       Prest

AjBool
ajStrExchangePosCC (Pstr, ipos, txt, txtnew)
       AjPStr& Pstr
       ajint ipos
       const char* txt
       const char* txtnew
    OUTPUT:
       RETVAL
       Pstr

AjBool
ajStrFmtWrapAt (Pstr, width, ch)
       AjPStr& Pstr
       ajuint width
       char ch
    OUTPUT:
       RETVAL
       Pstr

