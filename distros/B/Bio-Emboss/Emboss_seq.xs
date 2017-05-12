#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_seq		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajseq.c: automatically generated

AjPSeq
ajSeqNew ()
    OUTPUT:
       RETVAL

AjPSeq
ajSeqNewNameC (txt, name)
       const char* txt
       const char* name
    OUTPUT:
       RETVAL

AjPSeq
ajSeqNewNameS (str, name)
       const AjPStr str
       const AjPStr name
    OUTPUT:
       RETVAL

AjPSeq
ajSeqNewRangeC (txt, offset, offend, rev)
       const char* txt
       ajint offset
       ajint offend
       AjBool rev
    OUTPUT:
       RETVAL

AjPSeq
ajSeqNewRangeS (str, offset, offend, rev)
       const AjPStr str
       ajint offset
       ajint offend
       AjBool rev
    OUTPUT:
       RETVAL

AjPSeq
ajSeqNewRes (size)
       size_t size
    OUTPUT:
       RETVAL

AjPSeq
ajSeqNewSeq (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

void
ajSeqAssignAccC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignAccS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignDescC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignDescS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignEntryC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignEntryS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignFileC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignFileS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignFullC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignFullS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignGiC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignGiS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignNameC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignNameS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignSeqC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignSeqLenC (seq, txt, len)
       AjPSeq seq
       const char* txt
       ajint len

void
ajSeqAssignSeqS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignSvC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignSvS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignUfoC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignUfoS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqAssignUsaC (seq, txt)
       AjPSeq seq
       const char* txt

void
ajSeqAssignUsaS (seq, str)
       AjPSeq seq
       const AjPStr str

void
ajSeqSetOffsets (seq, offset, origlen)
       AjPSeq seq
       ajint offset
       ajint origlen

void
ajSeqSetRange (seq, pos1, pos2)
       AjPSeq seq
       ajint pos1
       ajint pos2

void
ajSeqSetRangeRev (seq, pos1, pos2)
       AjPSeq seq
       ajint pos1
       ajint pos2

void
ajSeqComplement (seq)
       AjPSeq seq

void
ajSeqFmtLower (seq)
       AjPSeq seq

void
ajSeqFmtUpper (seq)
       AjPSeq seq

void
ajSeqReverseDo (seq)
       AjPSeq seq

void
ajSeqReverseForce (seq)
       AjPSeq seq

void
ajSeqReverseOnly (seq)
       AjPSeq seq

const char*
ajSeqGetAccC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetAccS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetBegin (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetBeginTrue (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetDescC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetDescS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetEnd (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetEndTrue (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetEntryC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetEntryS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPFeattable
ajSeqGetFeat (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjPFeattable
ajSeqGetFeatCopy (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetGiC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetGiS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetLen (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetLenTrue (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetNameC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetNameS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetOffend (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetOffset (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajuint
ajSeqGetRange (seq, begin, end)
       const AjPSeq seq
       ajint& begin
       ajint& end
    OUTPUT:
       RETVAL
       begin
       end

AjBool
ajSeqGetRev (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetSeqC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetSeqS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

char*
ajSeqGetSeqCopyC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjPStr
ajSeqGetSeqCopyS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetSvC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetSvS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetTaxC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetTaxS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const char*
ajSeqGetUsaC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetUsaS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajSeqIsNuc (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajSeqIsProt (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajSeqIsReversedTrue (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajSeqIsReversed (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjBool
ajSeqIsTrimmed (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajint
ajSeqCalcCheckgcg (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

void
ajSeqCalcCount (seq, b)
       const AjPSeq seq
       ajint& b
    OUTPUT:
       b

float
ajSeqCalcMolwt (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

ajint
ajSeqCalcTrueposMin (seq, imin, ipos)
       const AjPSeq seq
       ajint imin
       ajint ipos
    OUTPUT:
       RETVAL

ajint
ajSeqCalcTruepos (seq, ipos)
       const AjPSeq seq
       ajint ipos
    OUTPUT:
       RETVAL

void
ajSeqExit ()

AjPSeqall
ajSeqallNew ()
    OUTPUT:
       RETVAL

void
ajSeqallDel (Pseq)
       AjPSeqall& Pseq
    OUTPUT:
       Pseq

void
ajSeqallSetRange (seq, pos1, pos2)
       AjPSeqall seq
       ajint pos1
       ajint pos2

void
ajSeqallSetRangeRev (seq, pos1, pos2)
       AjPSeqall seq
       ajint pos1
       ajint pos2

const AjPStr
ajSeqallGetFilename (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqallGetName (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqallGetUsa (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

AjPSeqset
ajSeqsetNew ()
    OUTPUT:
       RETVAL

void
ajSeqsetDel (Pseq)
       AjPSeqset& Pseq
    OUTPUT:
       Pseq

void
ajSeqsetDelarray (PPseq)
       AjPSeqset*& PPseq
    OUTPUT:
       PPseq

const AjPStr
ajSeqsetGetFilename (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqsetGetFormat (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

ajint
ajSeqsetGetRange (seq, begin, end)
       const AjPSeqset seq
       ajint& begin
       ajint& end
    OUTPUT:
       RETVAL
       begin
       end

const AjPStr
ajSeqsetGetUsa (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

ajint
ajSeqsetFill (seq)
       AjPSeqset seq
    OUTPUT:
       RETVAL

void
ajSeqsetReverse (seq)
       AjPSeqset seq

void
ajSeqsetSetRange (seq, pos1, pos2)
       AjPSeqset seq
       ajint pos1
       ajint pos2

void
ajSeqsetTrim (seq)
       AjPSeqset seq

AjBool
ajSeqsetIsDna (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

AjBool
ajSeqsetIsNuc (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

AjBool
ajSeqsetIsProt (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

AjBool
ajSeqsetIsRna (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

void
ajSeqDel (Pseq)
       AjPSeq& Pseq
    OUTPUT:
       Pseq

void
ajSeqClear (seq)
       AjPSeq seq

void
ajSeqallClear (seq)
       AjPSeqall seq

void
ajSeqTrace (seq)
       const AjPSeq seq

ajint
ajSeqcvtGetCodeAsymS (cvt, str)
       const AjPSeqCvt cvt
       const AjPStr str
    OUTPUT:
       RETVAL

void
ajSeqTrim (seq)
       AjPSeq seq

void
ajSeqGapStandard (seq, gapchar)
       AjPSeq seq
       char gapchar
    OUTPUT:
       seq

void
ajSeqstrReverse (Pseq)
       AjPStr& Pseq
    OUTPUT:
       Pseq

float
ajSeqstrCalcMolwt (seq)
       const AjPStr seq
    OUTPUT:
       RETVAL

void
ajSeqSetName (seq, setname)
       AjPSeq seq
       const AjPStr setname
    OUTPUT:
       seq

void
ajSeqSetNameMulti (seq, setname)
       AjPSeq seq
       const AjPStr setname
    OUTPUT:
       seq

void
ajSeqSetUnique (seq)
       AjPSeq seq

void
ajSeqGapFill (seq, len)
       AjPSeq seq
       ajuint len

AjBool
ajSeqConvertNum (seq, cvt, Pnumseq)
       const AjPSeq seq
       const AjPSeqCvt cvt
       AjPStr& Pnumseq
    OUTPUT:
       RETVAL
       Pnumseq

ajuint
ajSeqCountGaps (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

void
ajSeqTraceTitle (seq, title)
       const AjPSeq seq
       const char* title

ajint
ajSeqallGetseqBegin (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

ajint
ajSeqallGetseqEnd (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

ajint
ajSeqallGetseqLen (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqallGetseqName (seq)
       const AjPSeqall seq
    OUTPUT:
       RETVAL

ajint
ajSeqallGetseqRange (seq, begin, end)
       const AjPSeqall seq
       ajint& begin
       ajint& end
    OUTPUT:
       RETVAL
       begin
       end

ajint
ajSeqsetGetOffend (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

ajint
ajSeqsetGetOffset (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

void
ajSeqsetFmtLower (seq)
       AjPSeqset seq

void
ajSeqsetFmtUpper (seq)
       AjPSeqset seq

ajuint
ajSeqsetGetBegin (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

ajuint
ajSeqsetGetEnd (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

ajuint
ajSeqsetGetLen (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

const char*
ajSeqsetGetNameC (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqsetGetNameS (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

AjPSeq*
ajSeqsetGetSeqarray (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

ajuint
ajSeqsetGetSize (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

float
ajSeqsetGetTotweight (seq)
       const AjPSeqset seq
    OUTPUT:
       RETVAL

const char*
ajSeqsetGetseqAccC (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

const AjPStr
ajSeqsetGetseqAccS (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

const char*
ajSeqsetGetseqNameC (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

const AjPStr
ajSeqsetGetseqNameS (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

const AjPSeq
ajSeqsetGetseqSeq (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

const char*
ajSeqsetGetseqSeqC (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

const AjPStr
ajSeqsetGetseqSeqS (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

float
ajSeqsetGetseqWeight (seq, i)
       const AjPSeqset seq
       ajuint i
    OUTPUT:
       RETVAL

AjBool
ajSeqstrConvertNum (seq, cvt, Pnumseq)
       const AjPStr seq
       const AjPSeqCvt cvt
       AjPStr& Pnumseq
    OUTPUT:
       RETVAL
       Pnumseq

void
ajSeqcvtTrace (cvt)
       const AjPSeqCvt cvt

AjPSeqCvt
ajSeqcvtNewC (bases)
       const char* bases
    OUTPUT:
       RETVAL

AjPSeqCvt
ajSeqcvtNewEndC (bases)
       const char* bases
    OUTPUT:
       RETVAL

AjPSeqCvt
ajSeqcvtNewNumberC (bases)
       const char* bases
    OUTPUT:
       RETVAL

AjPSeqCvt
ajSeqcvtNewStr (basearray, numbases)
       AjPPStr basearray
       ajint numbases
    OUTPUT:
       RETVAL

AjPSeqCvt
ajSeqcvtNewStrAsym (basearray, numbases, matchbases, nummatch)
       AjPPStr basearray
       ajint numbases
       AjPPStr matchbases
       ajint nummatch
    OUTPUT:
       RETVAL

void
ajSeqcvtDel (Pcvt)
       AjPSeqCvt& Pcvt
    OUTPUT:
       Pcvt

ajint
ajSeqcvtGetCodeK (cvt, ch)
       const AjPSeqCvt cvt
       char ch
    OUTPUT:
       RETVAL

ajint
ajSeqcvtGetCodeS (cvt, str)
       const AjPSeqCvt cvt
       const AjPStr str
    OUTPUT:
       RETVAL

ajuint
ajSeqcvtGetLen (cvt)
       const AjPSeqCvt cvt
    OUTPUT:
       RETVAL

AjBool
ajSeqtestIsAccession (str)
       const AjPStr str
    OUTPUT:
       RETVAL

const AjPStr
ajSeqtestIsSeqversion (str)
       const AjPStr str
    OUTPUT:
       RETVAL

ajuint
ajSeqstrCountGaps (seq)
       const AjPStr seq
    OUTPUT:
       RETVAL

void
ajSeqstrComplement (Pseq)
       AjPStr& Pseq
    OUTPUT:
       Pseq

const char*
ajSeqGetDbC (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

const AjPStr
ajSeqGetDbS (seq)
       const AjPSeq seq
    OUTPUT:
       RETVAL

AjPSeqDate
ajSeqdateNew ()
    OUTPUT:
       RETVAL

AjPSeqDate
ajSeqdateNewDate (date)
       const AjPSeqDate date
    OUTPUT:
       RETVAL

void
ajSeqdateDel (Pdate)
       AjPSeqDate& Pdate
    OUTPUT:
       Pdate

AjBool
ajSeqdateSetCreateS (date, datestr)
       AjPSeqDate date
       const AjPStr datestr
    OUTPUT:
       RETVAL
       date

AjBool
ajSeqdateSetModifyS (date, datestr)
       AjPSeqDate date
       const AjPStr datestr
    OUTPUT:
       RETVAL
       date

AjBool
ajSeqdateSetModseqS (date, datestr)
       AjPSeqDate date
       const AjPStr datestr
    OUTPUT:
       RETVAL
       date

AjPSeqRef
ajSeqrefNew ()
    OUTPUT:
       RETVAL

AjPSeqRef
ajSeqrefNewRef (ref)
       const AjPSeqRef ref
    OUTPUT:
       RETVAL

void
ajSeqrefDel (Pref)
       AjPSeqRef& Pref
    OUTPUT:
       Pref

AjBool
ajSeqrefAppendAuthors (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefAppendComment (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefAppendGroupname (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefAppendLocation (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefAppendPosition (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefAppendTitle (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefAppendXref (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefFmtAuthorsEmbl (ref, Pdest)
       const AjPSeqRef ref
       AjPStr& Pdest
    OUTPUT:
       RETVAL
       Pdest

AjBool
ajSeqrefFmtAuthorsGb (ref, Pdest)
       const AjPSeqRef ref
       AjPStr& Pdest
    OUTPUT:
       RETVAL
       Pdest

AjBool
ajSeqrefFmtLocationEmbl (ref, Pdest)
       const AjPSeqRef ref
       AjPStr& Pdest
    OUTPUT:
       RETVAL
       Pdest

AjBool
ajSeqrefFmtLocationGb (ref, Pdest)
       const AjPSeqRef ref
       AjPStr& Pdest
    OUTPUT:
       RETVAL
       Pdest

AjBool
ajSeqrefFmtTitleGb (ref, Pdest)
       const AjPSeqRef ref
       AjPStr& Pdest
    OUTPUT:
       RETVAL
       Pdest

AjBool
ajSeqrefSetAuthors (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetComment (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetGroupname (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetLocation (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetLoctype (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetPosition (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetTitle (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetXref (ref, str)
       AjPSeqRef ref
       const AjPStr str
    OUTPUT:
       RETVAL

AjBool
ajSeqrefSetnumNumber (ref, num)
       AjPSeqRef ref
       ajuint num
    OUTPUT:
       RETVAL

AjBool
ajSeqrefStandard (ref)
       AjPSeqRef ref
    OUTPUT:
       RETVAL

AjBool
ajSeqreflistClone (src, dest)
       const AjPList src
       AjPList dest
    OUTPUT:
       RETVAL
       dest

AjBool
ajSeqclsSetEmbl (Pcls, clsembl)
       AjPStr& Pcls
       const AjPStr clsembl
    OUTPUT:
       RETVAL
       Pcls

AjBool
ajSeqclsSetGb (Pcls, clsgb)
       AjPStr& Pcls
       const AjPStr clsgb
    OUTPUT:
       RETVAL
       Pcls

const char*
ajSeqclsGetEmbl (cls)
       const AjPStr cls
    OUTPUT:
       RETVAL

AjBool
ajSeqdivSetEmbl (Pdivi, divembl)
       AjPStr& Pdivi
       const AjPStr divembl
    OUTPUT:
       RETVAL
       Pdivi

AjBool
ajSeqdivSetGb (Pdivi, divgb)
       AjPStr& Pdivi
       const AjPStr divgb
    OUTPUT:
       RETVAL
       Pdivi

const char*
ajSeqdivGetEmbl (divi)
       const AjPStr divi
    OUTPUT:
       RETVAL

const char*
ajSeqdivGetGb (divi)
       const AjPStr divi
    OUTPUT:
       RETVAL

AjBool
ajSeqmolSetEmbl (Pmol, molembl)
       AjPStr& Pmol
       const AjPStr molembl
    OUTPUT:
       RETVAL
       Pmol

AjBool
ajSeqmolSetGb (Pmol, molgb)
       AjPStr& Pmol
       const AjPStr molgb
    OUTPUT:
       RETVAL
       Pmol

const char*
ajSeqmolGetEmbl (mol)
       const AjPStr mol
    OUTPUT:
       RETVAL

const char*
ajSeqmolGetGb (mol)
       const AjPStr mol
    OUTPUT:
       RETVAL

