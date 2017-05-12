#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Foo::Bar		PACKAGE = Foo::Bar		

int
is_even(input)
	int     input
    CODE:
	RETVAL = (input % 2 == 0);
    OUTPUT:
	RETVAL
