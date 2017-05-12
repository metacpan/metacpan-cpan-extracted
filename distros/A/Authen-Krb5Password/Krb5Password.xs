#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "kpass.h"


MODULE = Authen::Krb5Password		PACKAGE = Authen::Krb5Password		

int
kpass(username, password, service, host, kt_pathname="")
	char* username
	char* password
	char* service
	char* host
	char* kt_pathname
  PROTOTYPE: $$$$;$
  CODE:
	RETVAL = kpass(username, password, service, host, kt_pathname);
  OUTPUT:
	RETVAL
