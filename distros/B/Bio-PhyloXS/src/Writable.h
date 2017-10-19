#ifndef WRITABLE_H
#define WRITABLE_H

# include "src/Identifiable.h"

static const char *tag[] = {
	"node",
	"tree",
	"trees",
	"otu",
	"otus",
	"row",
	"characters",
	"char",
	"chars",
	"meta",
	"nex:nexml",
	"set",
	"states"
};

typedef struct {
	Identifiable identifiable;
	HV* attributes;
	AV* meta;
	char * url;
	char * xml_id;
	int is_identifiable;
	int is_suppress_ns;
} Writable;

void initialize_writable(Writable* self);
void destroy_writable(Writable* self);

#endif
