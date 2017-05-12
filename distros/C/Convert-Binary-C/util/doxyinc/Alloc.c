#include <stdio.h>
#include "memalloc.h"

void main( void )
{
  void *p;

  SetDebugMemAlloc( printf, DB_MEMALLOC_TRACE
                          | DB_MEMALLOC_ASSERT );

  p = Alloc( 16 );      // allocate 16 bytes of memory
  AssertValidPtr( p );  // check the pointer
  Free( p );            // free the memory block
  AssertValidPtr( p );  // check the pointer (again)
}
