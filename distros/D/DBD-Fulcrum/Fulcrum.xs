/*

  Project	: DBD::Fulcrum
  Module/Library:
  Author	: $Author: shari $
  Revision	: $Revision: 1.5 $
  Check-in date	: $Date: 1998/09/17 17:50:28 $
  Locked by	: $Locker:  $

  Description	: 

*/

static char rcsid[]="$Id: Fulcrum.xs,v 1.5 1998/09/17 17:50:28 shari Exp $ (c) 1996, Inferentia S.r.l. (Milano) IT";

#include "Fulcrum.h"


/* --- Variables --- */

DBISTATE_DECLARE;
 
MODULE = DBD::Fulcrum    PACKAGE = DBD::Fulcrum

INCLUDE: Fulcrum.xsi

MODULE = DBD::Fulcrum    PACKAGE = DBD::Fulcrum::st


