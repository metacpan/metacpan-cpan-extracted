
/* Astro::SkyCat */

/* Tim Jenness 
   Copyright (C) 2001 Particle Physics and Astronomy
   Research Council. All Rights Reserved. */

#include <iostream.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */
#ifdef __cplusplus
}
#endif  

#include "AstroCatalog.h"


/* Helper routines to take the place of typemaps when using ... */
/* These could be called from the typemaps */
const WorldOrImageCoords * SvToWorldOrImageCoords( SV * sv ) {
  const WorldOrImageCoords * outwc;

  if (sv_derived_from(sv, "Astro::SkyCat::WorldOrImageCoords")) {
    IV tmp = SvIV((SV*)SvRV(sv));
    outwc = INT2PTR(const WorldOrImageCoords * ,tmp);
  }
  else
    croak("input is not of type Astro::SkyCat::WorldOrImageCoords");

  return outwc;
}


AstroQuery * SvToAstroQuery( SV * sv ) {
  AstroQuery * outq;

  if (sv_derived_from(sv, "Astro::SkyCat::AstroQuery")) {
    IV tmp = SvIV((SV*)SvRV(sv));
    outq = INT2PTR(AstroQuery * ,tmp);
  }
  else
    croak("input is not of type Astro::SkyCat::AstroQuery");

  return outq;
}


MODULE = Astro::SkyCat   PACKAGE = Astro::SkyCat


# Have to use new here to force xsubpp to treat it as a constructor

AstroCatalog *
AstroCatalog::new( serverName )
  char * serverName
 ALIAS:
  Astro::SkyCat::Open = 1
 CODE:
  RETVAL = AstroCatalog::open( serverName );
 OUTPUT:
  RETVAL  

MODULE = Astro::SkyCat   PACKAGE = Astro::SkyCat::Catalog

# Leave off the file name for now
# Need to decide whether to return the pos argument
# rather than the int to make it more perly

#int
#AstroCatalog::nameToWorldCoords(objName, pos, ... )
#  const char * objName
#  WorldOrImageCoords * pos
# PREINIT:
#  const char * nameServer;
#  FILE * feedback;
# CODE:
# 


# Query - this should really return the Result object and
# maybe the number of objects found

## CHANGE IN API reuquired

int
AstroCatalog::query(q, filename, result)
  AstroQuery * q
  const char * filename
  QueryResult * result;
 CODE:
  RETVAL = THIS->query(*q, filename, *result);
 OUTPUT:
  RETVAL

const char *
AstroCatalog::symbol()

const char *
AstroCatalog::searchCols()

const char *
AstroCatalog::sortCols()

const char *
AstroCatalog::sortOrder()

const char *
AstroCatalog::showCols()

const char *
AstroCatalog::copyright()

const char *
AstroCatalog::help()

int
AstroCatalog::id_col()

int
AstroCatalog::ra_col()

int
AstroCatalog::dec_col()

int
AstroCatalog::x_col()

int
AstroCatalog::y_col()

int
AstroCatalog::is_tcs()

int
AstroCatalog::isWcs()

int
AstroCatalog::isPix()

double
AstroCatalog::equinox()

void
AstroCatalog::feedback( f )
  FILE * f


int
AstroCatalog::status()

const char *
AstroCatalog::name()

const char *
AstroCatalog::longName()

const char *
AstroCatalog::shortName()

const char *
AstroCatalog::servType()

const char *
AstroCatalog::url()

int
AstroCatalog::numCols()

# This is the same as AstroQuery::colNames

void
AstroCatalog::colNames()
 PREINIT:
  int i;
  int len;
  char ** names;
 PPCODE:
  names = THIS->colNames();
  for (i = 0; i < THIS->numCols(); i++) {
    len = strlen( *names );
    XPUSHs(sv_2mortal(newSVpv( *names++, len)));
  }



const char *
AstroCatalog::colName( col )
  int col

int
AstroCatalog::colIndex( colName )
  const char * colName

int
AstroCatalog::hasCol( name )
  const char * name

int
AstroCatalog::more()

const char *
AstroCatalog::tmpfile()

# The image is either a URL or a Astro::SkyCat::Query object
# Take an SV as the arg

int
AstroCatalog::getImage( arg  )
  SV * arg;
 PREINIT:
  const char * url;
  AstroQuery * q;
 CODE:
  /* See if we have a blessed Astro::SkyCat::Query object */
  if (sv_derived_from(arg, "Astro::SkyCat::Query")) {
    IV tmp = SvIV((SV*)SvRV(arg));
    q = INT2PTR(AstroQuery * ,tmp);

    /* run the method */
    RETVAL = THIS->getImage( *q );

  } else {

    /* A char * */
    char * url = (char *)SvPV(arg,PL_na); 

    RETVAL = THIS->getImage( url );

  }


const char *
AstroCatalog::getError()

void
AstroCatalog::clearError()

void
AstroCatalog::DESTROY();

     
MODULE = Astro::SkyCat   PACKAGE = Astro::SkyCat::Query


AstroQuery *
AstroQuery::new()


# Can be used to set or return
# A pain since we cant use typemaps

# ID is tricky since when it is used as an accessor
# it returns a char and when it is used to set the ID
# it returns an int
# Can either break the interface and have setid, getid
# or we have to use PPCODE to handle with the return value
# Essentially means we are doing everything by hand

void
AstroQuery::id( ... )
 PREINIT:
  int retint;
  const char * retchar;
  const char * inchar;
 PPCODE:
  if (items == 2) {
    /* Setting the attribute */
    inchar = (const char *)SvPV(ST(1),PL_na);  
    retint = THIS->id( inchar );
    PUSHs(sv_2mortal( newSViv( retint )));

  } else {
    /* returning the attribute */
    retchar = THIS->id();
    PUSHs(sv_2mortal( newSVpv(retchar, strlen(retchar))));
  }

# Pos returns an int when used to set and the pos object
# when used to retrieve
# We must bless this ourselves since we can not use
# a typemap

void
AstroQuery::pos( ... )
 PREINIT:
  int retint; 
  WorldOrImageCoords retwc;
  const WorldOrImageCoords * inwc;
  const WorldOrImageCoords * inwc2;
  SV * retsv;
 PPCODE:
  if (items >= 2) {
    /* Setting the attribute - unfortunately it has to be an object */
    inwc = SvToWorldOrImageCoords( ST(1) );

    if (items == 2) {
									 
      /* We might need to inc ref count here in case we free the WCS
	 object before this command completes. Problem is how to dec
	 the ref count when this object disappears */
      retint = THIS->pos( *inwc );

    } else {
    
      /* We have 2 arguments so need to read it */
      inwc2 = SvToWorldOrImageCoords( ST(2) );      

      retint = THIS->pos( *inwc, *inwc2 );

    }

    /* store the result */
    PUSHs(sv_2mortal( newSViv( retint )));

  } else {
    /* returning the attribute */
    retwc = THIS->pos();
    retsv = sv_newmortal(); /* create the return sv */
    sv_setref_pv(retsv, "Astro::SkyCat::WorldOrImageCoords", (void *)&retwc) ;
    PUSHs( retsv );
  }


# Technically these accessors return void when used
# to set a value. Here they return a pseudo-double
# No-one should really care unless it breaks something

double
AstroQuery::width( ... )
 PREINIT:
  double width;
 CODE:
  if (items == 2) {
    width = (double)SvNV( ST(1) );
    THIS->width( width );   
  }
  RETVAL = THIS->width();
 OUTPUT:
  RETVAL

double
AstroQuery::height( ... )
 PREINIT:
  double height;
 CODE:
  if (items == 2) {
    height = (double)SvNV( ST(1) );
    THIS->height( height );   
  }
  RETVAL = THIS->height();
 OUTPUT:
  RETVAL

int
AstroQuery::dim( w, h );
  double w
  double h

double
AstroQuery::mag1( )

double
AstroQuery::mag2( ... )


int
AstroQuery::mag( m, ... )
  double m
 PREINIT:
  double m2;
 CODE:
  if (items == 2) {
    RETVAL = THIS->mag( m );
  }
  if (items == 3) {
    m2 = (double)SvNV( ST(2) );
    RETVAL = THIS->mag( m, m2 );
  }
 OUTPUT:
  RETVAL


void
AstroQuery::DESTROY();

# World Coordinates - required for Query structures et al

MODULE = Astro::SkyCat  PACKAGE = Astro::SkyCat::WorldOrImageCoords


WorldOrImageCoords *
WorldOrImageCoords::new()


MODULE = Astro::SkyCat PACKAGE = Astro::SkyCat::WorldCoords

# There are many different constructors just implement
# one of them for testing (most of them share the number
# of args so can not use that to distinguish types in perl

WorldCoords *
WorldCoords::new(rh, rm, rs, dd, dm, ds, ...)
  double rh
  int rm
  double rs
  double dd
  int dm
  double ds
 PREINIT:
  double equinox;
 CODE:
  if ( items > 6 ) {
     equinox = (double)SvNV(ST(6));
     RETVAL = new WorldCoords(rh, rm, rs, dd, dm, ds, equinox);
  } else {
     RETVAL = new WorldCoords(rh, rm, rs, dd, dm, ds );
  }
 OUTPUT:
  RETVAL


MODULE = Astro::SkyCat  PACKAGE = Astro::SkyCat::CatalogInfoEntry


CatalogInfoEntry *
CatalogInfoEntry::new()


MODULE = Astro::SkyCat  PACKAGE = Astro::SkyCat::QueryResult

# Many of these are TabTable methods
# might want to subclass properly to match
# the C++

QueryResult *
QueryResult::new()

# Probably want to return the object here as well

int
QueryResult::getPos( row, pos)
  int row
  WorldOrImageCoords * pos;
 CODE:
  RETVAL = THIS->getPos( row, *pos);
 OUTPUT:
  RETVAL


# The get method really should return the value rather than
# status - return undef on error. Also we can determine whether
# we have an int or a column name using SvIOK

# Always return stringified form or we use getstring and getnum
# to return string or number

# CHANGE IN API

char *
QueryResult::get( row, col )
  int row
  SV * col
 PREINIT:
  int status;
  /* Have no idea whether I need to free this memory */
  char * cresult = new char[128]; /* hope this is large enough */
 CODE:
  if (SvIOK(col)) {
    /* an integer */
    int colnum = SvIV( col );
    status = THIS->get(row, colnum, *cresult);     
  } else {
    /* A string */
    char * colname = (char *)SvPV_nolen( col );
    status = THIS->get(row, colname, cresult);
  }
  RETVAL = cresult;
 OUTPUT:
  RETVAL


int
QueryResult::numRows()

int
QueryResult::numCols()

int
QueryResult::colIndex( name )
  const char * name

# Push each column name onto the stack

void
QueryResult::colNames()
 PREINIT:
  int i;
  int len;
  char ** names;
 PPCODE:
  names = THIS->colNames();
  for (i = 0; i < THIS->numCols(); i++) {
    len = strlen( *names );
    XPUSHs(sv_2mortal(newSVpv( *names++, len)));
  }



void
QueryResult::DESTROY()

