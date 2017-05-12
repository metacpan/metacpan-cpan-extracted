

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "awadapter.h"
#include "aweb.h"

#include "awxs.h"
#include "awxs.def"
#include "Util.h"

#ifdef AWXS_WARNS
/* keep this simple for now, don't count % tokens, etc */
char *
setErrMsg ( char ** gErrMsg, int count, ... )
{
int i;
int argLength = 1, length;
char * strings[5];

	va_list ap;
	va_start ( ap, count );

	for ( i = 0; i < count; i++ ) {
		strings[i] =  va_arg ( ap, char* );
		argLength += strlen ( strings[i] );
	}

	va_end ( ap );

	if ( *gErrMsg )
	  free ( *gErrMsg );

	*gErrMsg = (char *)safemalloc ( argLength * sizeof (char) );

	switch ( count ) {
		case 1:
			strcpy ( *gErrMsg, strings[0] );
			break;
		case 2:
			sprintf ( *gErrMsg, strings[0], strings[1] );
			break;
		case 3:
			sprintf ( *gErrMsg, strings[0], strings[1], strings[2] );
			break;
		case 4:
			sprintf ( *gErrMsg, strings[0], strings[1], strings[2], strings[3] );
			break;
		case 5:
			sprintf ( *gErrMsg, strings[0], strings[1], strings[2], strings[3], strings[4] );
			break;
	}

	// sv_setpv ( perl_get_sv("!",0), gErrMsg );
	sv_setpv ( perl_get_sv("@",0), *gErrMsg );

	return ( *gErrMsg );

}

#endif /* AWXS_WARNS */



char *
stradd ( char* stringA, char* stringB )
{
char * returnString = NULL;

	if ( stringB == NULL )
		return ( NULL );
	
	if ( stringA == NULL )
		returnString = strdup (stringB);
	else
	  {
		returnString = (char *)safemalloc ( sizeof(char)*( strlen(stringA) + strlen(stringB) + 1) );

		sprintf ( returnString, "%s%s", stringA, stringB );	
	  }

	return ( returnString );
}
