#include <iostream>

#include "CegoXS.h"

DBISTATE_DECLARE;

// we have to set dNOOP hard here, since this causes some compilation problems
#ifdef dNOOP
#undef dNOOP
#define dNOOP /*EMPTY*/(void)0 /* Older g++ has no __attribute((unused))__ */
#endif

MODULE = DBD::Driver    PACKAGE = DBD::Driver::db

PROTOTYPES: DISABLE

MODULE = DBD::Cego          PACKAGE = DBD::Cego::st

PROTOTYPES: DISABLE

MODULE = DBD::Cego          PACKAGE = DBD::Cego

INCLUDE: Cego.xsi


