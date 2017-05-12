#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_pdb		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajpdb.c: automatically generated

AjPList
ajPdbtospReadAllRawNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPPdbtosp
ajPdbtospReadNew (inf, entry)
       AjPFile inf
       const AjPStr entry
    OUTPUT:
       RETVAL

AjPPdbtosp
ajPdbtospReadCNew (inf, entry)
       AjPFile inf
       const char* entry
    OUTPUT:
       RETVAL

AjPList
ajPdbtospReadAllNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPCmap
ajCmapReadINew (inf, chn, mod)
       AjPFile inf
       ajint chn
       ajint mod
    OUTPUT:
       RETVAL

AjPCmap
ajCmapReadCNew (inf, chn, mod)
       AjPFile inf
       char chn
       ajint mod
    OUTPUT:
       RETVAL

AjPList
ajCmapReadAllNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPCmap
ajCmapReadNew (inf, mode, chn, mod)
       AjPFile inf
       ajint mode
       ajint chn
       ajint mod
    OUTPUT:
       RETVAL

AjPVdwall
ajVdwallReadNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPHet
ajHetReadNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPHet
ajHetReadRawNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPPdb
ajPdbReadFirstModelNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPPdb
ajPdbReadAllModelsNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPPdb
ajPdbReadNew (inf, mode)
       AjPFile inf
       ajint mode
    OUTPUT:
       RETVAL

AjPPdb
ajPdbReadoldNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPPdb
ajPdbReadoldFirstModelNew (inf)
       AjPFile inf
    OUTPUT:
       RETVAL

AjPAtom
ajAtomNew ()
    OUTPUT:
       RETVAL

AjPResidue
ajResidueNew ()
    OUTPUT:
       RETVAL

AjPChain
ajChainNew ()
    OUTPUT:
       RETVAL

AjPPdb
ajPdbNew (n)
       ajint n
    OUTPUT:
       RETVAL

AjPHetent
ajHetentNew ()
    OUTPUT:
       RETVAL

AjPHet
ajHetNew (n)
       ajint n
    OUTPUT:
       RETVAL

AjPVdwall
ajVdwallNew (n)
       ajint n
    OUTPUT:
       RETVAL

AjPVdwres
ajVdwresNew (n)
       ajint n
    OUTPUT:
       RETVAL

AjPCmap
ajCmapNew (n)
       ajint n
    OUTPUT:
       RETVAL

AjPPdbtosp
ajPdbtospNew (n)
       ajint n
    OUTPUT:
       RETVAL

void
ajAtomDel (ptr)
       AjPAtom& ptr
    OUTPUT:
       ptr

void
ajResidueDel (ptr)
       AjPResidue& ptr
    OUTPUT:
       ptr

void
ajChainDel (ptr)
       AjPChain& ptr
    OUTPUT:
       ptr

void
ajPdbDel (ptr)
       AjPPdb& ptr
    OUTPUT:
       ptr

void
ajHetentDel (ptr)
       AjPHetent& ptr
    OUTPUT:
       ptr

void
ajHetDel (ptr)
       AjPHet& ptr
    OUTPUT:
       ptr

void
ajVdwallDel (ptr)
       AjPVdwall& ptr
    OUTPUT:
       ptr

void
ajVdwresDel (ptr)
       AjPVdwres& ptr
    OUTPUT:
       ptr

void
ajCmapDel (ptr)
       AjPCmap& ptr
    OUTPUT:
       ptr

void
ajPdbtospDel (ptr)
       AjPPdbtosp& ptr
    OUTPUT:
       ptr

AjBool
ajAtomCopy (to, from)
       AjPAtom& to
       const AjPAtom from
    OUTPUT:
       RETVAL
       to

AjBool
ajResidueCopy (to, from)
       AjPResidue& to
       AjPResidue from
    OUTPUT:
       RETVAL
       to

AjBool
ajAtomListCopy (to, from)
       AjPList & to
       const AjPList from
    OUTPUT:
       RETVAL
       to

AjBool
ajResidueListCopy (to, from)
       AjPList & to
       const AjPList from
    OUTPUT:
       RETVAL
       to

AjBool
ajPdbCopy (to, from)
       AjPPdb& to
       const AjPPdb from
    OUTPUT:
       RETVAL
       to

AjBool
ajResidueSSEnv (res, SEnv, logf)
       AjPResidue res
       char& SEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       SEnv
       logf

ajint
ajResidueEnv1 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv2 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv3 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv4 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv5 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv6 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv7 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv8 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv9 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv10 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv11 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv12 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv13 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv14 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv15 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajResidueEnv16 (res, SEnv, OEnv, logf)
       AjPResidue res
       char SEnv
       AjPStr& OEnv
       AjPFile logf
    OUTPUT:
       RETVAL
       OEnv
       logf

ajint
ajPdbGetEStrideType (obj, chn, EStrideType)
       const AjPPdb obj
       ajint chn
       AjPStr & EStrideType
    OUTPUT:
       RETVAL
       EStrideType

AjBool
ajPdbChnidToNum (id, pdb, chn)
       char id
       const AjPPdb pdb
       ajint & chn
    OUTPUT:
       RETVAL
       chn

ajint
ajPdbtospArrFindPdbid (arr, siz, id)
       AjPPdbtosp const * arr
       ajint siz
       const AjPStr id
    OUTPUT:
       RETVAL

AjBool
ajPdbWriteAll (outf, obj)
       AjPFile outf
       const AjPPdb obj
    OUTPUT:
       RETVAL
       outf

AjBool
ajPdbWriteSegment (outf, pdb, segment, chnid, domain, errf)
       AjPFile outf
       const AjPPdb pdb
       const AjPStr segment
       char chnid
       const AjPStr domain
       AjPFile errf
    OUTPUT:
       RETVAL
       outf
       errf

AjBool
ajHetWrite (outf, obj, dogrep)
       AjPFile outf
       const AjPHet obj
       AjBool dogrep
    OUTPUT:
       RETVAL
       outf

AjBool
ajPdbtospWrite (outf, list)
       AjPFile outf
       const AjPList list
    OUTPUT:
       RETVAL
       outf

AjBool
ajCmapWrite (outf, cmap)
       AjPFile outf
       const AjPCmap cmap
    OUTPUT:
       RETVAL

