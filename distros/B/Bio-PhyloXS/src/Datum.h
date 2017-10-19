#ifndef DATUM_H
#define DATUM_H

# include "src/TypeSafeData.h"

typedef struct {
	TypeSafeData type;
	int position;
	double weight;
	AV* annotations;
} Datum;

void initialize_datum(Datum* self);
void destroy_datum(Datum* self);

#endif
