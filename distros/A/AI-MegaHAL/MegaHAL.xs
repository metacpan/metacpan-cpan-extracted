#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "megahal.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
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
	if (strEQ(name, "MEGAHAL_H"))
#ifdef MEGAHAL_H
	    return MEGAHAL_H;
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


MODULE = AI::MegaHAL		PACKAGE = AI::MegaHAL
PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

void
megahal_setnoprompt ()

void
megahal_setnowrap ()

void
megahal_setnobanner ()

void
megahal_seterrorfile(filename)
        char*   filename

void
megahal_setstatusfile(filename)
        char*   filename

void
megahal_initialize()

char*
megahal_initial_greeting()

int
megahal_command(input)
        char*   input

char*
megahal_do_reply(input,log)
        char*   input
        int     log

void
megahal_learn(input,log)
        char*   input
        int     log

void
megahal_output(output)
        char*   output

char*
megahal_input(prompt)
        char* prompt

void
megahal_cleanup()

