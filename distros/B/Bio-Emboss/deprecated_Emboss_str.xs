#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_str_deprecated		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajstr.h: automatically generated

void
ajCharFree (txt)
       char** txt


char*
ajCharNew (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

char*
ajCharNewL (len)
       ajint len
    OUTPUT:
       RETVAL

char*
ajCharNewLS (size, thys)
       size_t size
       const AjPStr  thys
    OUTPUT:
       RETVAL

ajint
ajCharPos (thys, ipos)
       const char* thys
       ajint ipos
    OUTPUT:
       RETVAL

void
ajCharToLower (txt)
       char *txt

void
ajCharToUpper (txt)
       char *txt

AjBool
ajStrApp (pthis, src)
       AjPStr & pthis
       const AjPStr  src
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAppC (pthis, txt)
       AjPStr & pthis
       const char *txt
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAppCI (pthis, txt, i)
       AjPStr & pthis
       const char *txt
       size_t i
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAppK (pthis, chr)
       AjPStr & pthis
       const char chr
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAppKI (pthis, chr, number)
       AjPStr & pthis
       const char chr
       ajint number
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAppSub (pthis, src, begin, end)
       AjPStr & pthis
       const AjPStr  src
       ajint begin
       ajint end
    OUTPUT:
       RETVAL
       pthis

void
ajStrArrayDel (pthis)
       AjPStr *& pthis
    OUTPUT:
       pthis

AjBool
ajStrAss (pthis, str)
       AjPStr & pthis
       AjPStr  str
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssC (pthis, txt)
       AjPStr & pthis
       const char* txt
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssCI (pthis, txt, i)
       AjPStr & pthis
       const char* txt
       size_t i
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssCL (pthis, txt, i)
       AjPStr & pthis
       const char* txt
       size_t i
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssI (pthis, str, i)
       AjPStr & pthis
       const AjPStr  str
       size_t i
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssK (pthis, text)
       AjPStr & pthis
       const char text
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssL (pthis, str, i)
       AjPStr & pthis
       const AjPStr  str
       size_t i
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssS (pthis, str)
       AjPStr & pthis
       const AjPStr  str
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssSub (pthis, str, begin, end)
       AjPStr & pthis
       const AjPStr  str
       ajint begin
       ajint end
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrAssSubC (pthis, txt, begin, end)
       AjPStr & pthis
       const char* txt
       ajint begin
       ajint end
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrBlock (pthis, blksize)
       AjPStr & pthis
       ajint blksize
    OUTPUT:
       RETVAL
       pthis

char
ajStrChar (thys, pos)
       const AjPStr  thys
       ajint pos
    OUTPUT:
       RETVAL

AjBool
ajStrChomp (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrChompC (pthis, delim)
       AjPStr & pthis
       const char* delim
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrChompEnd (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrChop (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrClean (s)
       AjPStr & s
    OUTPUT:
       RETVAL
       s

AjBool
ajStrCleanWhite (s)
       AjPStr & s
    OUTPUT:
       RETVAL
       s

AjBool
ajStrClear (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis


int
ajStrCmpCase (str1, str2)
       const AjPStr  str1
       const AjPStr  str2
    OUTPUT:
       RETVAL

int
ajStrCmpCaseCC (str1, str2)
       const char* str1
       const char* str2
    OUTPUT:
       RETVAL

int
ajStrCmp (str1, str2)
       const char * str1
       const char * str2
    OUTPUT:
       RETVAL

int
ajStrCmpO (thys, anoth)
       const AjPStr  thys
       const AjPStr  anoth
    OUTPUT:
       RETVAL

int
ajStrCmpWild (thys, str)
       const AjPStr  thys
       const AjPStr  str
    OUTPUT:
       RETVAL


int
ajStrCmpWildCC (str, text)
       const char* str
       const char* text
    OUTPUT:
       RETVAL

AjBool
ajStrConvert (pthis, oldc, newc)
       AjPStr & pthis
       const AjPStr  oldc
       const AjPStr  newc
    OUTPUT:
       RETVAL
       pthis


AjBool
ajStrConvertCC (pthis, oldc, newc)
       AjPStr & pthis
       const char* oldc
       const char* newc
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrCopy (pthis, str)
       AjPStr & pthis
       AjPStr  str
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrCopyC (pthis, str)
       AjPStr & pthis
       const char* str
    OUTPUT:
       RETVAL
       pthis

ajint
ajStrCountC (thys, str)
       const AjPStr  thys
       const char* str
    OUTPUT:
       RETVAL

ajint
ajStrCountK (thys, ch)
       const AjPStr  thys
       char ch
    OUTPUT:
       RETVAL

AjBool
ajStrCut (pthis, begin, end)
       AjPStr & pthis
       ajint begin
       ajint end
    OUTPUT:
       RETVAL
       pthis

void
ajStrDegap (pthis)
       AjPStr & pthis
    OUTPUT:
       pthis


AjBool
ajStrDelim (pthis, ptoken, delim)
       AjPStr & pthis
       AjPStrTok  &ptoken
       const char *delim
    OUTPUT:
       RETVAL
       pthis
       ptoken

AjBool
ajStrDelReuse (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjPStr
ajStrDup (thys)
       AjPStr  thys
    OUTPUT:
       RETVAL


ajint
ajStrFind (thys, text)
       const AjPStr  thys
       const AjPStr  text
    OUTPUT:
       RETVAL



ajint
ajStrFindCase (thys, text)
       const AjPStr  thys
       const AjPStr  text
    OUTPUT:
       RETVAL


ajint
ajStrFindK (thys, chr)
       const AjPStr  thys
       const char chr
    OUTPUT:
       RETVAL

void
ajStrFill (pthis, count, fill)
       AjPStr & pthis
       ajint count
       char fill
    OUTPUT:
       pthis

void
ajStrFix (pthys)
       AjPStr  &pthys
    OUTPUT:
       pthys

void
ajStrFixI (pthys, ilen)
       AjPStr  &pthys
       ajint ilen
    OUTPUT:
       pthys


AjBool
ajStrFromDoubleE (pthis, val, precision)
       AjPStr & pthis
       double val
       ajint precision
    OUTPUT:
       RETVAL
       pthis




AjBool
ajStrInsert (pthis, pos, str)
       AjPStr & pthis
       ajint pos
       const AjPStr  str
    OUTPUT:
       RETVAL
       pthis













AjBool
ajStrIsSpace (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL





AjIStr
ajStrIter (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

AjIStr
ajStrIterBack (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

AjIStr
ajStrIterBackNext (iter)
       AjIStr  iter
    OUTPUT:
       RETVAL

void
ajStrIterFree (iter)
       AjIStr  &iter
    OUTPUT:
       iter




AjBool
ajStrKeepAlphaC (pthis, chars)
       AjPStr & pthis
       const char* chars
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrKeepC (pthis, chars)
       AjPStr & pthis
       const char* chars
    OUTPUT:
       RETVAL
       pthis

ajint
ajStrLen (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

ajint
ajStrListToArray (str, array)
       const AjPStr  str
       AjPStr  *&array
    OUTPUT:
       RETVAL
       array


AjBool
ajStrMatch (thys, str)
       const AjPStr  thys
       const AjPStr  str
    OUTPUT:
       RETVAL


AjBool
ajStrMatchCase (thys, str)
       const AjPStr  thys
       const AjPStr  str
    OUTPUT:
       RETVAL


AjBool
ajStrMatchCaseCC (thys, text)
       const char* thys
       const char* text
    OUTPUT:
       RETVAL

AjBool
ajStrMatchCC (thys, text)
       const char* thys
       const char* text
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWild (thys, wild)
       const AjPStr  thys
       const AjPStr  wild
    OUTPUT:
       RETVAL


AjBool
ajStrMatchWildCC (str, text)
       const char* str
       const char* text
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWildCO (str, wild)
       const char* str
       const AjPStr  wild
    OUTPUT:
       RETVAL

AjBool
ajStrMatchWord (str, text)
       const AjPStr  str
       const AjPStr  text
    OUTPUT:
       RETVAL


AjBool
ajStrMatchWordCC (str, text)
       const char* str
       const char* text
    OUTPUT:
       RETVAL

AjBool
ajStrMod (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrModL (pthis, size)
       AjPStr & pthis
       size_t size
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrModMinL (pthis, size)
       AjPStr & pthis
       size_t size
    OUTPUT:
       RETVAL
       pthis

ajint
ajStrNCmpC (thys, text, n)
       const AjPStr  thys
       const char *text
       ajint n
    OUTPUT:
       RETVAL

ajint
ajStrNCmpCaseCC (str1, str2, len)
       const char* str1
       const char* str2
       ajint len
    OUTPUT:
       RETVAL

ajint
ajStrNCmpO (thys, anoth, n)
       const AjPStr  thys
       const AjPStr  anoth
       ajint n
    OUTPUT:
       RETVAL



AjPStr
ajStrNewCIL (txt, len, size)
       const char *txt
       ajint len
       size_t size
    OUTPUT:
       RETVAL

AjPStr
ajStrNewCL (txt, size)
       const char *txt
       size_t size
    OUTPUT:
       RETVAL

AjPStr
ajStrNewL (size)
       size_t size
    OUTPUT:
       RETVAL


const AjPStr
ajStrNull ()
    OUTPUT:
       RETVAL

AjBool
ajStrParentheses (s)
       const AjPStr  s
    OUTPUT:
       RETVAL

ajint
ajStrPos (thys, ipos)
       const AjPStr  thys
       ajint ipos
    OUTPUT:
       RETVAL

ajint
ajStrPosI (thys, imin, ipos)
       const AjPStr  thys
       ajint imin
       ajint ipos
    OUTPUT:
       RETVAL

ajint
ajStrPosII (ilen, imin, ipos)
       ajint ilen
       ajint imin
       ajint ipos
    OUTPUT:
       RETVAL

AjBool
ajStrPrefix (thys, pref)
       const AjPStr  thys
       const AjPStr  pref
    OUTPUT:
       RETVAL


AjBool
ajStrPrefixCC (str, pref)
       const char *str
       const char* pref
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixCase (thys, pref)
       const AjPStr  thys
       const AjPStr  pref
    OUTPUT:
       RETVAL


AjBool
ajStrPrefixCaseCC (str, pref)
       const char *str
       const char* pref
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixCaseCO (thys, pref)
       const char* thys
       const AjPStr  pref
    OUTPUT:
       RETVAL

AjBool
ajStrPrefixCO (str, thys)
       const char *str
       const AjPStr  thys
    OUTPUT:
       RETVAL

void
ajStrQuote (s)
       AjPStr  &s
    OUTPUT:
       s




AjBool
ajStrReplace (pthis, pos1, overwrite, len)
       AjPStr & pthis
       ajint pos1
       const AjPStr  overwrite
       ajint len
    OUTPUT:
       RETVAL
       pthis


AjBool
ajStrReplaceC (pthis, pos1, overwrite, len)
       AjPStr & pthis
       ajint pos1
       const char* overwrite
       ajint len
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrReplaceK (pthis, pos1, overwrite, len)
       AjPStr & pthis
       ajint pos1
       char overwrite
       ajint len
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrReplaceS (pthis, begin, overwrite)
        AjPStr & pthis
       ajint begin
       const AjPStr  overwrite
    OUTPUT:
       RETVAL
       pthis

ajint
ajStrRef (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

void
ajStrRemoveCharsC (thys, strng)
       AjPStr & thys
       const char *strng
    OUTPUT:
       thys


void
ajStrRemoveNewline (pthis)
       AjPStr & pthis
    OUTPUT:
       pthis

AjBool
ajStrRev (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

ajint
ajStrRFindC (thys, text)
       const AjPStr  thys
       const char *text
    OUTPUT:
       RETVAL

ajint
ajStrRoom (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

AjBool
ajStrSet (pthis, str)
       AjPStr & pthis
       const AjPStr  str
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrSetC (pthis, str)
       AjPStr & pthis
       const char* str
    OUTPUT:
       RETVAL
       pthis

ajint
ajStrSize (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL


const char*
ajStrStr (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

char*
ajStrStrMod (thys)
       AjPStr & thys
    OUTPUT:
       RETVAL
       thys

AjBool
ajStrSub (pthis, begin, len)
       AjPStr & pthis
       ajint begin
       ajint len
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrSubstitute (pthis, replace, putin)
       AjPStr & pthis
       const AjPStr  replace
       const AjPStr  putin
    OUTPUT:
       RETVAL
       pthis


AjBool
ajStrSubstituteCC (pthis, replace, putin)
       AjPStr & pthis
       const char* replace
       const char* putin
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrSubstituteKK (pthis, replace, putin)
       AjPStr & pthis
       char replace
       char putin
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrSuffix (thys, suff)
       const AjPStr  thys
       const AjPStr  suff
    OUTPUT:
       RETVAL


AjBool
ajStrSuffixCC (str, suff)
       const char *str
       const char* suff
    OUTPUT:
       RETVAL

AjBool
ajStrSuffixCO (str, suff)
       const char *str
       const AjPStr  suff
    OUTPUT:
       RETVAL






const AjPStr
ajStrTok (thys)
       const AjPStr  thys
    OUTPUT:
       RETVAL

const AjPStr
ajStrTokC (thys, delim)
       const AjPStr  thys
       const char* delim
    OUTPUT:
       RETVAL

const AjPStr
ajStrTokCC (thys, delim)
       const char* thys
       const char* delim
    OUTPUT:
       RETVAL

AjBool
ajStrToken (pthis, ptoken, delim)
       AjPStr & pthis
       AjPStrTok  &ptoken
       const char *delim
    OUTPUT:
       RETVAL
       pthis
       ptoken

AjBool
ajStrTokenAss (ptok, thys, delim)
       AjPStrTok  &ptok
       const AjPStr  thys
       const char *delim
    OUTPUT:
       RETVAL
       ptok

void
ajStrTokenClear (token)
       AjPStrTok  &token
    OUTPUT:
       token

ajint
ajStrTokenCount (line, delim)
       const AjPStr  line
       const char *delim
    OUTPUT:
       RETVAL

ajint
ajStrTokenCountR (line, delim)
       const AjPStr  line
       const char *delim
    OUTPUT:
       RETVAL

AjPStrTok
ajStrTokenInit (thys, delim)
       const AjPStr  thys
       const char *delim
    OUTPUT:
       RETVAL


AjBool
ajStrTokenRest (pthis, ptoken)
       AjPStr & pthis
       AjPStrTok & ptoken
    OUTPUT:
       RETVAL
       pthis
       ptoken



AjBool
ajStrToLower (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrToLowerII (pthis, begin, end)
       AjPStr & pthis
       ajint begin
       ajint end
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrToTitle (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrToUpper (pthis)
       AjPStr & pthis
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrToUpperII (pthis, begin, end)
       AjPStr & pthis
       ajint begin
       ajint end
    OUTPUT:
       RETVAL
       pthis




AjBool
ajStrTrim (pthis, num)
       AjPStr & pthis
       ajint num
    OUTPUT:
       RETVAL
       pthis




AjBool
ajStrTruncate (pthis, pos)
       AjPStr & pthis
       ajint pos
    OUTPUT:
       RETVAL
       pthis


AjBool
ajStrWildPrefix (str)
       AjPStr & str
    OUTPUT:
       RETVAL
       str

AjBool
ajStrWrap (pthis, width)
       AjPStr & pthis
       ajint width
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrWrapLeft (pthis, width, left)
       AjPStr & pthis
       ajint width
       ajint left
    OUTPUT:
       RETVAL
       pthis

AjBool
ajStrUncomment (text)
       AjPStr & text
    OUTPUT:
       RETVAL
       text

AjBool
ajStrUncommentStart (text)
       AjPStr & text
    OUTPUT:
       RETVAL
       text
