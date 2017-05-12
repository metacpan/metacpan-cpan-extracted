#ifndef ALLOCATE_STRUCT_H
#define ALLOCATE_STRUCT_H

#include "ctx_def.h"

struct allocation_blob {
	struct allocation_blob *next;
	unsigned int left, offset;
	unsigned char data[];
};

struct allocator_struct {
	const char *name;
	struct allocation_blob *blobs;
	unsigned int alignment;
	unsigned int chunking;
	void *freelist;
	/* statistics */
	unsigned int allocations, total_bytes, useful_bytes;
	unsigned int nofree : 1;
};

#ifndef DO_CTX
#define __DO_ALLOCATOR_DATA(type, objsize, objalign, objname, x, norel)	\
	static struct allocator_struct x##_allocator = {	\
		.name = objname,				\
		.alignment = objalign,				\
		.chunking = CHUNK,				\
		.nofree = norel					\
	};							
#define __DO_ALLOCATOR_DATA_INIT(type, objsize, objalign, objname, x, norel) 
#else
#define __DO_ALLOCATOR_DATA(type, objsize, objalign, objname, x, norel)	
#define __DO_ALLOCATOR_DATA_INIT(type, objsize, objalign, objname, x, norel) \
  sctxp x##_allocator	.name = objname;				\
  sctxp x##_allocator	.alignment = objalign;				\
  sctxp x##_allocator	.chunking = CHUNK;				\
  sctxp x##_allocator	.nofree = norel;

#endif

#define ALLOCATOR_DEF(x, n, norel) \
	struct allocator_struct x##_allocator;

#endif
