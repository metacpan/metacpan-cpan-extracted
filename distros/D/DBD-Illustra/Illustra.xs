/*##############################################################################
#
#   File name: Illustra.xs
#   Project: DBD::Illustra
#   Description: XS code
#
#   Author: Peter Haworth
#   Date created: 17/07/1998
#
#   sccs version: 1.5    last changed: 10/13/99
#
#   Copyright (c) 1998 Institute of Physics Publishing
#   You may distribute under the terms of the Artistic License,
#   as distributed with Perl, with the exception that it cannot be placed
#   on a CD-ROM or similar media for commercial distribution without the
#   prior approval of the author.
#
##############################################################################*/


#include "Illustra.h"

DBISTATE_DECLARE;

MODULE = DBD::Illustra  PACKAGE = DBD::Illustra

INCLUDE: Illustra.xsi


MODULE = DBD::Illustra  PACKAGE = DBD::Illustra::db


# read_large_object
SV *
read_large_object(dbh, lohandle, offset, len)
  SV *dbh
  char *lohandle
  long offset
  long len
PREINIT:
  MI_LODESC lodesc;
  MI_LOSTAT *st;
  STRLEN losize,bytes_read=0;
  char *p;
  D_imp_dbh(dbh);
CODE:
  /* Open large object */
  if((lodesc=mi_large_object_open(imp_dbh->conn,lohandle,MI_LO_RDONLY))
  ==MI_ERROR){
    do_error(dbh,0,"Error opening large object");
    XSRETURN_UNDEF;
  }

  /* Stat large object to get size */
  if((st=mi_large_object_stat(imp_dbh->conn,lodesc))==NULL){
    do_error(dbh,0,"Error stat\'ing large object");
    mi_large_object_close(imp_dbh->conn,lodesc);
    XSRETURN_UNDEF;
  }
  losize=st->mist_size;
  mi_free((char*)st);

  /* Check we're not being asked for data past the end */
  if(offset>losize){
    XSRETURN_UNDEF;
  }

  /* Create buffer */
  RETVAL=newSVpv("",0);
  SvGROW(RETVAL,len+1);
  SvCUR_set(RETVAL,0);
  sv_2mortal(RETVAL);
  SvREFCNT_inc(RETVAL);

  /* Read the data into the buffer */
  if((bytes_read=mi_large_object_readwithseek(imp_dbh->conn,lodesc,SvPVX(RETVAL),len,offset,MI_LO_SEEK_SET))==MI_ERROR){
    do_error(dbh,0,"Error reading large object");
    SvREFCNT_dec(RETVAL);
    RETVAL=&sv_undef;
  }else{
    /* Set size */
    SvCUR_set(RETVAL,bytes_read);
    *SvEND(RETVAL)=0;
  }

  /* Close large object */
  mi_large_object_close(imp_dbh->conn,lodesc);
OUTPUT:
  RETVAL

