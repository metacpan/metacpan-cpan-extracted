#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embindex		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embindex.c: automatically generated

void
embBtreeEmblKW (kwline, kwlist, maxlen)
       const AjPStr kwline
       AjPList kwlist
       ajint maxlen
    OUTPUT:
       kwlist

void
embBtreeEmblTX (txline, txlist, maxlen)
       const AjPStr txline
       AjPList txlist
       ajint maxlen
    OUTPUT:
       txlist

void
embBtreeEmblAC (acline, aclist)
       const AjPStr acline
       AjPList aclist
    OUTPUT:
       aclist

void
embBtreeEmblSV (idline, svlist)
       const AjPStr idline
       AjPList svlist
    OUTPUT:
       svlist

void
embBtreeEmblDE (deline, delist, maxlen)
       const AjPStr deline
       AjPList delist
       ajint maxlen
    OUTPUT:
       delist

void
embBtreeGenBankAC (acline, aclist)
       const AjPStr acline
       AjPList aclist
    OUTPUT:
       aclist

void
embBtreeGenBankKW (kwline, kwlist, maxlen)
       const AjPStr kwline
       AjPList kwlist
       ajint maxlen
    OUTPUT:
       kwlist

void
embBtreeGenBankDE (kwline, kwlist, maxlen)
       const AjPStr kwline
       AjPList kwlist
       ajint maxlen
    OUTPUT:
       kwlist

void
embBtreeGenBankTX (kwline, kwlist, maxlen)
       const AjPStr kwline
       AjPList kwlist
       ajint maxlen
    OUTPUT:
       kwlist

void
embBtreeFastaDE (kwline, kwlist, maxlen)
       const AjPStr kwline
       AjPList kwlist
       ajint maxlen
    OUTPUT:
       kwlist

ajint
embBtreeReadDir (filelist, fdirectory, files, exclude)
       AjPStr*& filelist
       const AjPStr fdirectory
       const AjPStr files
       const AjPStr exclude
    OUTPUT:
       RETVAL
       filelist

EmbPBtreeEntry
embBtreeEntryNew ()
    OUTPUT:
       RETVAL

void
embBtreeEntryDel (thys)
       EmbPBtreeEntry& thys
    OUTPUT:
       thys

ajint
embBtreeSetFields (entry, fields)
       EmbPBtreeEntry entry
       AjPStr const * fields
    OUTPUT:
       RETVAL
       entry

void
embBtreeSetDbInfo (entry, name, dbrs, date, release, type, directory, idirectory)
       EmbPBtreeEntry entry
       const AjPStr name
       const AjPStr dbrs
       const AjPStr date
       const AjPStr release
       const AjPStr type
       const AjPStr directory
       const AjPStr idirectory
    OUTPUT:
       entry

ajint
embBtreeGetFiles (entry, fdirectory, files, exclude)
       EmbPBtreeEntry entry
       const AjPStr fdirectory
       const AjPStr files
       const AjPStr exclude
    OUTPUT:
       RETVAL

AjBool
embBtreeWriteEntryFile (entry)
       const EmbPBtreeEntry entry
    OUTPUT:
       RETVAL

void
embBtreeGetRsInfo (entry)
       EmbPBtreeEntry entry

AjBool
embBtreeOpenCaches (entry)
       EmbPBtreeEntry entry
    OUTPUT:
       RETVAL

AjBool
embBtreeCloseCaches (entry)
       EmbPBtreeEntry entry
    OUTPUT:
       RETVAL

AjBool
embBtreeDumpParameters (entry)
       EmbPBtreeEntry entry
    OUTPUT:
       RETVAL

