#ifndef __NSS_H__
#define __NSS_H__

#include "nss.h"
#include "ssl.h"
#include "sslerr.h"
#include "prio.h"
#include "prtypes.h"
#include "prtime.h"
#include "prnetdb.h"
#include "cert.h"
#include "pk11func.h"
#include "certt.h"
#include "keyhi.h"

#define HAS_ARGUMENT(hv, key) hv_exists(hv, key, strlen(key))
#define SET_SOCKET_OPTION(socket, option, report) if (PR_SetSocketOption(socket, &option) != SECSuccess) { \
    PR_Close(socket); \
    throw_exception_from_nspr_error(report); \
}

#define GET_SOCKET_OPTION(socket, option, str) if (PR_GetSocketOption(socket, &option) != SECSuccess) { \
    throw_exception_from_nspr_error(form("Failed to get option '%s' on socket", str)); \
}

#define EVALUATE_SEC_CALL(call, report) if (call != SECSuccess) { \
    throw_exception_from_nspr_error(report); \
}

#define EVALUATE_PR_CALL(call, report) if (call != PR_SUCCESS) { \
    throw_exception_from_nspr_error(report); \
}

struct NSS_SSL_Socket {
    PRFileDesc * fd;
    PRFileDesc * ssl_fd;
    SV * verify_certificate_hook;
    SV * bad_certificate_hook;
    SV * client_certificate_hook;
    SV * client_certificate_hook_arg;
    
    bool do_not_free; /* ugly hack to prevent hooks from killing this */
    bool is_connected;
    bool does_ssl;
};

typedef struct NSS_SSL_Socket NSS_SSL_Socket;

typedef CERTCertificate * Crypt__NSS__Certificate;
typedef PK11SlotInfo * Crypt__NSS__PKCS11__Slot;
typedef SECKEYPrivateKey * Crypt__NSS__PrivateKey;
typedef SECKEYPublicKey * Crypt__NSS__PublicKey;

typedef NSS_SSL_Socket * Net__NSS__SSL;

#endif