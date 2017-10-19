#ifndef TYPESAFEDATA_H
#define TYPESAFEDATA_H

# include "src/Listable.h"
# include "src/Datatype.h"

typedef struct {
	Listable listable;
	Datatype * datatype;
} TypeSafeData;

void initialize_typesafedata(TypeSafeData* self);
void destroy_typesafedata(TypeSafeData* self);

#endif
