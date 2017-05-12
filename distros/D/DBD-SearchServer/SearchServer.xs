/*

  Project	: DBD::Fulcrum
  Module/Library:
  Author	: $Author: shari $
  Revision	: $Revision: 1.6 $
  Check-in date	: $Date: 1999/03/02 13:43:22 $
  Locked by	: $Locker:  $

  Description	: 

*/

static char rcsid[]="$Id: SearchServer.xs,v 1.6 1999/03/02 13:43:22 shari Exp $ (c) 1996, Inferentia S.r.l. (Milano) IT";

#include "SearchServer.h"


/* --- Variables --- */

DBISTATE_DECLARE;
 
MODULE = DBD::SearchServer    PACKAGE = DBD::SearchServer

INCLUDE: SearchServer.xsi

MODULE = DBD::SearchServer    PACKAGE = DBD::SearchServer::st


