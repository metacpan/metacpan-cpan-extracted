#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_nam		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajnam.c: automatically generated

void
ajNamPrintDbAttr (outf, full)
       AjPFile outf
       AjBool full

void
ajNamPrintRsAttr (outf, full)
       AjPFile outf
       AjBool full

AjBool
ajNamDbDetails (name, type, id, qry, all, comment, release, methods, defined)
       const AjPStr name
       AjPStr& type
       AjBool& id
       AjBool& qry
       AjBool& all
       AjPStr& comment
       AjPStr& release
       AjPStr& methods
       AjPStr& defined
    OUTPUT:
       RETVAL
       type
       id
       qry
       all
       comment
       release
       methods
       defined

void
ajNamListOrigin ()

void
ajNamDebugOrigin ()

void
ajNamListDatabases ()

void
ajNamDebugDatabases ()

void
ajNamDebugResources ()

void
ajNamDebugVariables ()

void
ajNamListListDatabases (dbnames)
       AjPList dbnames
    OUTPUT:
       dbnames

void
ajNamListListResources (rsnames)
       AjPList rsnames
    OUTPUT:
       rsnames

void
ajNamVariables ()

AjBool
ajNamIsDbname (name)
       const AjPStr name
    OUTPUT:
       RETVAL

AjBool
ajNamGetenv (name, value)
       const AjPStr name
       AjPStr& value
    OUTPUT:
       RETVAL
       value

AjBool
ajNamGetenvC (name, value)
       const char* name
       AjPStr& value
    OUTPUT:
       RETVAL
       value

AjBool
ajNamGetValue (name, value)
       const AjPStr name
       AjPStr& value
    OUTPUT:
       RETVAL
       value

AjBool
ajNamGetValueC (name, value)
       const char* name
       AjPStr& value
    OUTPUT:
       RETVAL
       value

AjBool
ajNamDatabase (name)
       const AjPStr name
    OUTPUT:
       RETVAL

void
ajNamInit (prefix)
       const char* prefix

void
ajNamExit ()

AjBool
ajNamDbTest (dbname)
       const AjPStr dbname
    OUTPUT:
       RETVAL

AjBool
ajNamDbGetUrl (dbname, url)
       const AjPStr dbname
       AjPStr& url
    OUTPUT:
       RETVAL
       url

AjBool
ajNamDbGetDbalias (dbname, dbalias)
       const AjPStr dbname
       AjPStr& dbalias
    OUTPUT:
       RETVAL
       dbalias

AjBool
ajNamDbData (qry)
       AjPSeqQuery qry
    OUTPUT:
       RETVAL

AjBool
ajNamDbQuery (qry)
       AjPSeqQuery qry
    OUTPUT:
       RETVAL

AjBool
ajNamRootInstall (root)
       AjPStr& root
    OUTPUT:
       RETVAL
       root

AjBool
ajNamRootPack (pack)
       AjPStr& pack
    OUTPUT:
       RETVAL
       pack

AjBool
ajNamRootVersion (version)
       AjPStr& version
    OUTPUT:
       RETVAL
       version

AjBool
ajNamRoot (root)
       AjPStr& root
    OUTPUT:
       RETVAL
       root

AjBool
ajNamRootBase (rootbase)
       AjPStr& rootbase
    OUTPUT:
       RETVAL
       rootbase

AjBool
ajNamResolve (name)
       AjPStr& name
    OUTPUT:
       RETVAL
       name

AjBool
ajNamSetControl (optionName)
       const char* optionName
    OUTPUT:
       RETVAL

AjBool
ajNamRsAttrValue (name, attribute, value)
       const AjPStr name
       const AjPStr attribute
       AjPStr & value
    OUTPUT:
       RETVAL
       value

AjBool
ajNamRsAttrValueC (name, attribute, value)
       const char * name
       const char * attribute
       AjPStr & value
    OUTPUT:
       RETVAL
       value

AjBool
ajNamRsListValue (name, value)
       const AjPStr name
       AjPStr & value
    OUTPUT:
       RETVAL
       value

