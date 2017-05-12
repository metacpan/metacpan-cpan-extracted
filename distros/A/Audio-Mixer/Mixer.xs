#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Mix.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static char *
constant(char *name, int arg)
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
	if (strEQ(name, "MIXER"))
#ifdef MIXER
	    return MIXER;
#else
	    goto not_there;
#endif
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
    errno = ENOENT;
    return 0;
}


MODULE = Audio::Mixer		PACKAGE = Audio::Mixer		


char *
constant(name,arg)
	char *		name
	int		arg


int
get_param_val(cntrl)
     char *		cntrl
   OUTPUT:
     RETVAL

int
set_param_val(cntrl, lcval, rcval)
     char *		cntrl
     int 		lcval
     int 		rcval
   OUTPUT:
     RETVAL

int
init_mixer()
   OUTPUT:
     RETVAL

int
close_mixer()
   OUTPUT:
     RETVAL

int
get_params_num()
   OUTPUT:
     RETVAL

char *
get_params_list()
   OUTPUT:
     RETVAL

int
set_mixer_dev(fname)
     char *		fname
   OUTPUT:
     RETVAL


char *
get_source()
   OUTPUT:
     RETVAL

int
set_source(cntrl)
     char *		cntrl
   OUTPUT:
     RETVAL

