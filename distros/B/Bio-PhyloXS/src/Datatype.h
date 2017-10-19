#ifndef DATATYPE_H
#define DATATYPE_H

# include "src/Writable.h"

#define _DNA_ 1
#define _RNA_ 2
#define _PROTEIN_ 3
#define _STANDARD_ 4
#define _CONTINUOUS_ 5

typedef struct {
	Writable writable;
	int datatype;
	char missing;
	char gap;
} Datatype;

void initialize_datatype(Datatype* self);
void destroy_datatype(Datatype* self);
void _to_set_type(Datatype* self, char* type);
char* _to_get_type(Datatype* self);

#endif
