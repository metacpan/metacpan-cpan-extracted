#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <bloom.h>
#include "const-c.inc"
typedef bloom Bloomer;

MODULE = Bloom::Faster	PACKAGE = Bloom::Faster

INCLUDE: const-xs.inc

Bloomer *
binit(size,hashes,capacity,error_rate)
	unsigned long size
	int hashes
	unsigned long capacity
	float error_rate
PREINIT: 
	bloom *newbloom;
CODE:
	if ((newbloom = (bloom *)malloc(sizeof(bloom))) == NULL) {
		perror("malloc");
	}
	if (bloom_init(newbloom,size,capacity,error_rate,hashes,NULL,0) != 0) {
		RETVAL = NULL;
	} else {
		RETVAL = newbloom;
	}
OUTPUT:
	RETVAL


Bloomer *
binit_sugg(n,e)
	char *n;
	char *e;
PREINIT: 
	bloom *newbloom;
CODE:
	struct bloomstat stat;
	unsigned long real_n = atoll(n);
	double real_e = atof(e);
	
	get_suggestion(&stat,real_n,real_e);
	if ((newbloom = (bloom *)malloc(sizeof(bloom))) == NULL) {
		perror("malloc");
	}
	if (bloom_init(newbloom,stat.elements,real_n,real_e,stat.ideal_hashes,NULL,1) != 0) {
		RETVAL = NULL;
	} else {
		RETVAL = newbloom;
	}
OUTPUT:
	RETVAL


void
suggestion(n,e,m,k)
	char *n;
	char *e;
	SV * m;
	int k;
PROTOTYPE: $$
CODE:
	char holder[1000];
	struct bloomstat stat;
	unsigned long real_n = atoll(n);
	double real_e = atof(e);
	
	get_suggestion(&stat,real_n,real_e);

	sprintf(holder,"%lld",stat.elements);
	m = newSVpvn(holder,strlen(holder));
	k = stat.ideal_hashes;
OUTPUT:
	m	
	k

void
bloom_destroyer(newbloom)
	Bloomer *newbloom
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom = (bloom *)newbloom;
	bloom_destroy(thisbloom);
	free(thisbloom);

static long 
bcapacity(newbloom)
	Bloomer *newbloom
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom = (bloom *)newbloom;
	RETVAL=thisbloom->stat.capacity;
OUTPUT:
	RETVAL

static long 
berror_rate(newbloom)
	Bloomer *newbloom
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom = (bloom *)newbloom;
	RETVAL=thisbloom->stat.e;
OUTPUT:
	RETVAL

static long 
belements(newbloom)
	Bloomer *newbloom
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom = (bloom *)newbloom;
	RETVAL=thisbloom->stat.elements;
OUTPUT:
	RETVAL

static long 
bhash_functions(newbloom)
	Bloomer *newbloom
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom = (bloom *)newbloom;
	RETVAL=thisbloom->stat.ideal_hashes;
OUTPUT:
	RETVAL


static long
binserts(newbloom)
	Bloomer *newbloom
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom = (bloom *)newbloom;
	RETVAL = thisbloom->inserts;
OUTPUT:
	RETVAL

static int
test_bloom(newbloom,str,mode)
	Bloomer *newbloom
	char *str;
	int mode;
PREINIT:
	bloom *thisbloom;
CODE:
	thisbloom  = (bloom *)newbloom;
	if (mode == 1) {
		RETVAL = bloom_add(thisbloom,str);
	} else {
		RETVAL = bloom_check(thisbloom,str);
	}
OUTPUT:
	RETVAL

static int
bserialize(newbloom,fname)
	Bloomer *newbloom
	char *fname
PREINIT:
	bloom *thisbloom;
CODE:	
	thisbloom  = (bloom *)newbloom;
	if (bloom_serialize(thisbloom,fname) == 0) {
		RETVAL=1;
	} else {
		RETVAL=0;
	}
OUTPUT:
	RETVAL

Bloomer *
bdeserialize(fname)
	char *fname
PREINIT:
	bloom *newbloom;
CODE:
	newbloom=bloom_deserialize(fname);
	RETVAL=newbloom;
OUTPUT:
	RETVAL


char *
get_vector(newbloom)
	Bloomer *newbloom
	PREINIT:
		char *other;
	CODE:
		if ((other = (char *)malloc(sizeof(char) * ((newbloom->stat.elements/8) + 1))) == NULL) {
			perror("malloc");
		}
		strncpy(other,newbloom->vector,(newbloom->stat.elements/8) + 1);
		RETVAL=other;
	OUTPUT:	
		RETVAL
