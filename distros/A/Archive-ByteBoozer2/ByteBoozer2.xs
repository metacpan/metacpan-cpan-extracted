#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cruncher.h"

MODULE = Archive::ByteBoozer2  PACKAGE = Archive::ByteBoozer2
PROTOTYPES: ENABLE

File *
alloc_file()
  CODE:
    File *myFile;
    Newxz(myFile, 1, File);
    if (myFile == NULL)
      XSRETURN_UNDEF;
    myFile->name = (char *)NULL;
    myFile->size = 0;
    myFile->data = (byte *)NULL;
    RETVAL = myFile;
  OUTPUT:
    RETVAL

SV *
file_name(file)
    File *file
  CODE:
    RETVAL = newSVpv(file->name, 0);
  OUTPUT:
    RETVAL

_bool
crunch_file(aSource, aTarget, startAdress, decrFlag, isRelocated)
    File *aSource
    File *aTarget
    uint startAdress
   _bool decrFlag
   _bool isRelocated
  CODE:
    RETVAL = crunch(aSource, aTarget, startAdress, decrFlag, isRelocated);
  OUTPUT:
    RETVAL

void
free_file(...)
  CODE:
    int i;
    File *aFile;
    SV *sv;
    for (i = 0; i < items; i++) {
      sv = (SV *)SvRV(ST(i));
      aFile = (File *)SvIV(sv);
      freeFile(aFile);
      Safefree(aFile);
    }
    XSRETURN_UNDEF;

_bool
read_file(aFile, fileName)
    File *aFile
    const char *fileName
  CODE:
    RETVAL = readFile(aFile, fileName);
  OUTPUT:
    RETVAL

_bool
write_file(aFile, fileName)
    File *aFile
    const char *fileName
  CODE:
    RETVAL = writeFile(aFile, fileName);
  OUTPUT:
    RETVAL