#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "libRepFormat/RepFormat.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FORMAT_HEADER"))
#ifdef FORMAT_HEADER
	    return FORMAT_HEADER;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    return 0;
}


MODULE = Data::Reporte::RepFormat		PACKAGE = Data::Reporter::RepFormat	PREFIX = RepFormat_

double
constant(name,arg)
	char *		name
	int		arg

char *
RepFormat_ToPicture(value, picture)
	char *	value
	char *	picture
	PROTOTYPE: $$
	

RepFormat *
RepFormat_new(CLASS, col, row)
	char *CLASS
	int	col
	int	row
	PROTOTYPE: $$$
	CODE:
		RETVAL = RepFormat_new(col, row);
	OUTPUT:
		RETVAL

MODULE = Data::Reporter::RepFormat		PACKAGE = RepFormatPtr	PREFIX = RepFormat_

void 
DESTROY(format)
	RepFormat *format
	PROTOTYPE: $
	CODE:
		RepFormat_Destroy(format);

void
RepFormat_Clear(self)
	RepFormat *	self
	PROTOTYPE: $

void
RepFormat_Move(self, col, row)
	RepFormat *	self
	int	col
	int	row
	PROTOTYPE: $$$

void
RepFormat_Print(self, str)
	RepFormat *	self
	char *	str
	PROTOTYPE: $$

void
RepFormat_MVPrint(self, col, row, str)
	RepFormat *	self
	int	col
	int	row
	char *	str
	PROTOTYPE: $$$$

void
RepFormat_PrintP(self, value, picture)
	RepFormat *	self
	char *	value
	char *	picture
	PROTOTYPE: $$$

void
RepFormat_MVPrintP(self, col, row, value, picture)
	RepFormat *	self
	int	col
	int	row
	char *	value
	char *	picture
	PROTOTYPE: $$$$$

char *
RepFormat_Center(self, value, size)
	RepFormat *	self
	char *	value
	int	size
	PROTOTYPE: $$$

void
RepFormat_PrintC(self, value)
	RepFormat *	self
	char *	value
	PROTOTYPE: $$

char *
RepFormat_Getline(self, row)
	RepFormat *	self
	int	row
	PROTOTYPE: $$$

int
RepFormat_Nlines(self)
	RepFormat *	self
	PROTOTYPE: $

int
RepFormat_getX(self)
	RepFormat *	self
	PROTOTYPE: $

int
RepFormat_getY(self)
	RepFormat *	self
	PROTOTYPE: $

void
RepFormat_Skip(self, ...)
	RepFormat *	self
	PROTOTYPE: $;$
	PREINIT:
	int rows = 1;
	CODE:
		if (items > 1)
			rows = SvIV(ST(1));
		RepFormat_Skip(self, rows);

void
RepFormat_Copy(self, other)
	RepFormat *	self
	RepFormat *	other
	PROTOTYPE: $$

void
RepFormat_Destroy(self)
	RepFormat *	self
	PROTOTYPE: $
