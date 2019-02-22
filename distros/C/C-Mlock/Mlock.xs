#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "store.h"

typedef AddressRegion *C__Mlock;

MODULE = C::Mlock		PACKAGE = C::Mlock		

PROTOTYPES: ENABLE

C::Mlock
new(package, nSize = 0)
	char *package
	int   nSize;
	CODE:
	RETVAL = new(nSize);
	OUTPUT:
	RETVAL

void 
DESTROY(pAddressRegion)
	C::Mlock pAddressRegion

void 
dump(pAddressRegion)
	C::Mlock pAddressRegion

char *
get(pAddressRegion)
	C::Mlock pAddressRegion

int
store(pAddressRegion, data, len)
	C::Mlock pAddressRegion
	int	 len
	char	*data

int
lockall(pAddressRegion)
	C::Mlock pAddressRegion

int
unlockall(pAddressRegion)
	C::Mlock pAddressRegion

int
is_locked(pAddressRegion)
	C::Mlock pAddressRegion

int
process_locked(pAddressRegion)
	C::Mlock pAddressRegion

int
initialize(pAddressRegion)
	C::Mlock pAddressRegion

int
set_pages(pAddressRegion, pages)
	C::Mlock pAddressRegion
	int	 pages

int
set_size(pAddressRegion, bytes)
	C::Mlock pAddressRegion
	int	 bytes

int
pagesize(pAddressRegion)
	C::Mlock pAddressRegion

