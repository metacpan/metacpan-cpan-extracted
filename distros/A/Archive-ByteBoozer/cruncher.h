#ifndef _cruncher_h_
#define _cruncher_h_

#include <strings.h>
#include <stdlib.h>

#include "file.h" // #include "bb.h"
#include "bb.h" // #include "file.h"

_bool crunch(File *aSource, File *aTarget, uint startAdress, uint decrFlag, _bool isRelocated);

#endif // _cruncher_h_
