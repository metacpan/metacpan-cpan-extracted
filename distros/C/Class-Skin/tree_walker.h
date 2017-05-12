#if !defined(LIB_SKIN)
#define LIB_SKIN
#include "libskin/skin.h"
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


void walk_the_tree(SV* self,
		   SV* buffer,
		   struct tnode * node,
		   HV* vars);

void write_log(SV* self, char * message, int level);


