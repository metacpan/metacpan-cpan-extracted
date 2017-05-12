#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define metachar(c) (c == '"' || c == '\n')

MODULE = Ace::Freesubs	PACKAGE = Ace

SV*
freeprotect(CLASS,string)
     char*  CLASS
     char*  string
PREINIT:
	unsigned long count = 2;
	char *cp,*new,*a;
CODE:
	/* count the number of characters that need to be escaped */
	for (cp = string; *cp; cp++ ) {
	   count += metachar(*cp) ? 2 : 1;
	}

	/* create a new char* large enough to hold the result */
	New(0,new,count+1,char);
	if (new == NULL) XSRETURN_UNDEF;
	a = new;
	*a++ = '"';
	cp = string;
	for (cp = string; *cp; *a++ = *cp++) {
	   if (metachar(*cp)) *a++ = '\\';
	   if (*cp == '\n') { *a++ = 'n' ; cp++ ; }
	}
	*a++ = '"';
	*a++ = '\0';
	RETVAL = newSVpv("",0);
	sv_usepvn(RETVAL,new,count);
OUTPUT:
	RETVAL

void
split(CLASS,string)
     char*  CLASS
     char*  string
PREINIT:
	char *class,*name,*cp,*dest,*timestamp;
	SV* c,n;
	int class_size,name_size,timestamp_size,total_size;
PPCODE:
	if (*string != '?') XSRETURN_EMPTY;
	/* first scan for the class */
	total_size = strlen(string) + 1;
	Newz(0,class,total_size,char);
	SAVEFREEPV(class);

	for (cp = string+1,dest=class; *cp; *cp && (*dest++ = *cp++) ) {
		while (*cp && *cp == '\\') {
			cp++;             /* skip character */
			if (!*cp) break;
			if (*cp == 'n') {
			  *dest++ = '\n';
			  cp++;
			}
			else if (*cp == 't') {
			  *dest++ = '\t';
			  cp++;
			}
			else
			  *dest++ = *cp++; /* copy next character */
		}
		if (*cp == '?') break;
	}
	*dest = '\0';  /* paranoia */
	if (!*cp) XSRETURN_EMPTY;

	/* dest should now point at the '?' character, and class holds
	the class name */
	class_size = dest-class;

	/* now we go after the object name */
	Newz(0,name,total_size - (cp-string),char);
	SAVEFREEPV(name);

	for (++cp, dest=name; *cp ; *cp && (*dest++ = *cp++) ) {
		while (*cp && *cp == '\\') {
		  cp++;             /* skip character */
		  if (!*cp) break;
		  if (*cp == 'n') {
		    *dest++ = '\n';
		    cp++;
		  }
		  else if (*cp == 't') {
		    *dest++ = '\t';
		    cp++;
		  }
		  else
		    *dest++ = *cp++; /* copy next character */
		}
		if (*cp == '?') break;
	}
	*dest = '\0';
	name_size = dest - name;

	if (!*cp) XSRETURN_EMPTY;

        XPUSHs(sv_2mortal(newSVpv(class,class_size)));
	XPUSHs(sv_2mortal(newSVpv(name,name_size)));

        /* dest should now point at the '?' character, and name holds the object id */
        if (*++cp) {
	  Newz(0,timestamp,total_size - (cp-string),char);
	  SAVEFREEPV(timestamp);
	  for (dest=timestamp; *cp ; *cp && (*dest++ = *cp++) ) ;
	  *dest = '\0';
	  timestamp_size = dest - timestamp - 1;
	  XPUSHs(sv_2mortal(newSVpv(timestamp,timestamp_size)));
	}

