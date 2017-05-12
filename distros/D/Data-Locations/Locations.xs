

/*****************************************************************************/
/*                                                                           */
/*    Copyright (c) 1997 - 2009 by Steffen Beyer.                            */
/*    All rights reserved.                                                   */
/*                                                                           */
/*    This package is free software; you can redistribute it                 */
/*    and/or modify it under the same terms as Perl itself.                  */
/*                                                                           */
/*****************************************************************************/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


static char *DataLocations = "Data::Locations";


#define DATA_LOCATIONS_OBJECT(ref,obj) \
    ( ref && SvROK(ref) && \
    (obj = (GV *)SvRV(ref)) && \
    SvOBJECT(obj) && (SvTYPE(obj) == SVt_PVGV) && \
    (strEQ(HvNAME(SvSTASH(obj)),DataLocations)) )

#define DATA_LOCATIONS_NUMERIC(ref,typ,var) \
    ( ref && !(SvROK(ref)) && ((var = (typ)SvIV(ref)) | 1) )

#define DATA_LOCATIONS_ERROR(name,error) \
    croak("Data::Locations::" name "(): " error)

#define DATA_LOCATIONS_OBJECT_ERROR(name) \
    DATA_LOCATIONS_ERROR(name,"item is not a \"Data::Locations\" object")

#define DATA_LOCATIONS_NUMERIC_ERROR(name) \
    DATA_LOCATIONS_ERROR(name,"item is not numeric")


MODULE = Data::Locations		PACKAGE = Data::Locations


PROTOTYPES: DISABLE


void
_mortalize_(ref)
SV *	ref
PPCODE:
{
    GV *obj;

    if ( DATA_LOCATIONS_OBJECT(ref,obj) )
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSViv((IV)( obj->sv_refcnt - 1 ))));
        obj->sv_refcnt = 1;
    }
    else DATA_LOCATIONS_OBJECT_ERROR("_mortalize_");
}


void
_resurrect_(ref,cnt)
SV *	ref
SV *	cnt
CODE:
{
    GV *obj;
    U32 val;

    if ( DATA_LOCATIONS_OBJECT(ref,obj) )
    {
        if ( DATA_LOCATIONS_NUMERIC(cnt,U32,val) )
        {
            obj->sv_refcnt += val;
        }
        else DATA_LOCATIONS_NUMERIC_ERROR("_resurrect_");
    }
    else DATA_LOCATIONS_OBJECT_ERROR("_resurrect_");
}


void
Version(...)
PPCODE:
{
    if ((items >= 0) && (items <= 1))
    {
        EXTEND(sp,1);
        PUSHs(sv_2mortal(newSVpv((char *)"5.5",0)));
    }
    else croak("Usage: Data::Locations->Version()");
}


