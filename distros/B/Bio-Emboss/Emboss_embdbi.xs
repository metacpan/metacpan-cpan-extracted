#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embdbi		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embdbi.c: automatically generated

EmbPField
embDbiFieldNew ()
    OUTPUT:
       RETVAL

ajint
embDbiCmpId (a, b)
       const char* a
       const char* b
    OUTPUT:
       RETVAL

ajint
embDbiCmpFieldId (a, b)
       const char* a
       const char* b
    OUTPUT:
       RETVAL

ajint
embDbiCmpFieldField (a, b)
       const char* a
       const char* b
    OUTPUT:
       RETVAL

EmbPEntry
embDbiEntryNew (nfields)
       ajint nfields
    OUTPUT:
       RETVAL

void
embDbiEntryDel (Pentry)
       EmbPEntry& Pentry
    OUTPUT:
       Pentry

AjPList
embDbiFileList (dir, wildfile, trim)
       const AjPStr dir
       const AjPStr wildfile
       AjBool trim
    OUTPUT:
       RETVAL

AjPList
embDbiFileListExc (dir, wildfile, exclude)
       const AjPStr dir
       const AjPStr wildfile
       const AjPStr exclude
    OUTPUT:
       RETVAL

AjBool
embDbiFlatOpenlib (lname, libr)
       const AjPStr lname
       AjPFile& libr
    OUTPUT:
       RETVAL

void
embDbiRmFile (dbname, ext, nfiles, cleanup)
       const AjPStr dbname
       const char* ext
       ajint nfiles
       AjBool cleanup

void
embDbiRmFileI (dbname, ext, ifile, cleanup)
       const AjPStr dbname
       const char* ext
       ajint ifile
       AjBool cleanup

void
embDbiRmEntryFile (dbname, cleanup)
       const AjPStr dbname
       AjBool cleanup

void
embDbiSortFile (dbname, ext1, ext2, nfiles, cleanup, sortopt)
       const AjPStr dbname
       const char* ext1
       const char* ext2
       ajint nfiles
       AjBool cleanup
       const AjPStr sortopt

void
embDbiSysCmd (cmdstr)
       const AjPStr cmdstr

void
embDbiHeaderSize (file, filesize, recordcnt)
       AjPFile file
       ajint filesize
       ajint recordcnt

void
embDbiHeader (file, filesize, recordcnt, recordlen, dbname, release, date)
       AjPFile file
       ajint filesize
       ajint recordcnt
       short recordlen
       const AjPStr dbname
       const AjPStr release
       const char* date

AjPFile
embDbiFileSingle (dbname, extension, num)
       const AjPStr dbname
       const char* extension
       ajint num
    OUTPUT:
       RETVAL

AjPFile
embDbiFileIn (dbname, extension)
       const AjPStr dbname
       const char* extension
    OUTPUT:
       RETVAL

AjPFile
embDbiFileOut (dbname, extension)
       const AjPStr dbname
       const char* extension
    OUTPUT:
       RETVAL

AjPFile
embDbiFileIndex (indexdir, field, extension)
       const AjPStr indexdir
       const AjPStr field
       const char* extension
    OUTPUT:
       RETVAL

void
embDbiWriteDivision (indexdir, dbname, release, date, maxfilelen, nfiles, divfiles, seqfiles)
       const AjPStr indexdir
       const AjPStr dbname
       const AjPStr release
       const char* date
       ajint maxfilelen
       ajint nfiles
       AjPStr const * divfiles
       AjPStr const * seqfiles

void
embDbiWriteDivisionRecord (file, maxnamlen, recnum, datfile, seqfile)
       AjPFile file
       ajint maxnamlen
       short recnum
       const AjPStr datfile
       const AjPStr seqfile

void
embDbiWriteEntryRecord (file, maxidlen, id, rpos, spos, filenum)
       AjPFile file
       ajint maxidlen
       const AjPStr id
       ajint rpos
       ajint spos
       short filenum

void
embDbiWriteHit (file, idnum)
       AjPFile file
       ajint idnum

void
embDbiWriteTrg (file, maxfieldlen, idnum, idcnt, hitstr)
       AjPFile file
       ajint maxfieldlen
       ajint idnum
       ajint idcnt
       const AjPStr hitstr

AjPFile
embDbiSortOpen (alistfile, ifile, dbname, fields, nfields)
       AjPFile& alistfile
       ajint ifile
       const AjPStr dbname
       AjPStr const * fields
       ajint nfields
    OUTPUT:
       RETVAL
       alistfile

void
embDbiSortClose (elistfile, alistfile, nfields)
       AjPFile& elistfile
       AjPFile& alistfile
       ajint nfields

void
embDbiMemEntry (idlist, fieldList, nfields, entry, ifile)
       AjPList idlist
       AjPList& fieldList
       ajint nfields
       EmbPEntry entry
       ajint ifile

ajint
embDbiSortWriteEntry (entFile, maxidlen, dbname, nfiles, cleanup, sortopt)
       AjPFile entFile
       ajint maxidlen
       const AjPStr dbname
       ajint nfiles
       AjBool cleanup
       const AjPStr sortopt
    OUTPUT:
       RETVAL

ajint
embDbiMemWriteEntry (entFile, maxidlen, idlist, ids)
       AjPFile entFile
       ajint maxidlen
       const AjPList idlist
       void**& ids
    OUTPUT:
       RETVAL
       ids

ajint
embDbiSortWriteFields (dbname, release, date, indexdir, fieldname, maxFieldLen, nfiles, nentries, cleanup, sortopt)
       const AjPStr dbname
       const AjPStr release
       const char* date
       const AjPStr indexdir
       const AjPStr fieldname
       ajint maxFieldLen
       ajint nfiles
       ajint nentries
       AjBool cleanup
       const AjPStr sortopt
    OUTPUT:
       RETVAL

ajint
embDbiMemWriteFields (dbname, release, date, indexdir, fieldname, maxFieldLen, fieldList, ids)
       const AjPStr dbname
       const AjPStr release
       const char* date
       const AjPStr indexdir
       const AjPStr fieldname
       ajint maxFieldLen
       const AjPList fieldList
       void** ids
    OUTPUT:
       RETVAL

void
embDbiDateSet (datestr, date)
       const AjPStr datestr
       char* date
    OUTPUT:
       date

void
embDbiMaxlen (token, maxlen)
       AjPStr& token
       ajint& maxlen

void
embDbiLogHeader (logfile, dbname, release, datestr, indexdir, maxindex)
       AjPFile logfile
       const AjPStr dbname
       const AjPStr release
       const AjPStr datestr
       const AjPStr indexdir
       ajint maxindex

void
embDbiLogFields (logfile, fields, nfields)
       AjPFile logfile
       AjPStr const * fields
       ajint nfields

void
embDbiLogSource (logfile, directory, filename, exclude, inputFiles, nfiles)
       AjPFile logfile
       const AjPStr directory
       const AjPStr filename
       const AjPStr exclude
       AjPStr const * inputFiles
       ajint nfiles

void
embDbiLogCmdline (logfile)
       AjPFile logfile

void
embDbiLogFile (logfile, curfilename, idCountFile, fields, countField, nfields)
       AjPFile logfile
       const AjPStr curfilename
       ajint idCountFile
       AjPStr const * fields
       const ajint* countField
       ajint nfields

void
embDbiLogFinal (logfile, maxindex, maxFieldLen, fields, fieldTot, nfields, nfiles, idDone, idCount)
       AjPFile logfile
       ajint maxindex
       const ajint* maxFieldLen
       AjPStr const * fields
       const ajint* fieldTot
       ajint nfields
       ajint nfiles
       ajint idDone
       ajint idCount

void
embDbiExit ()

