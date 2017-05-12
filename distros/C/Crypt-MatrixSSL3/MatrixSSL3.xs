#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

#include "core/coreApi.h"
#include "crypto/cryptoApi.h"
#include "matrixssl/matrixssllib.h"
#include "matrixssl/matrixsslApi.h"
#include "matrixssl/version.h"
#include "MatrixSSL3.h"

#ifndef WIN32
#include "regex.h"
#endif

#include "inc/const-c.inc"

/******************************************************************************/

typedef sslKeys_t       Crypt_MatrixSSL3_Keys;
typedef sslSessionId_t  Crypt_MatrixSSL3_SessID;
typedef ssl_t           Crypt_MatrixSSL3_Sess;
typedef tlsExtension_t  Crypt_MatrixSSL3_HelloExt;

static int matrixssl_initialized = 0;

#ifdef MATRIX_DEBUG
static int objects = 0;
#endif

sslSessOpts_t sslOpts;


/*****************************************************************************
    ALPN extension helper structure. This holds the protocols the server is
    implementing. Since ALPN usage is optional, if a virtual hosts has the
    protocols specified, this list will be used when an ALPN extension is
    received from the client. If not, the default server protocol list is
    used if provided. If neither the virtual host or the default server have
    protocols specified, the ALPN extension is ignored.
*/

typedef struct s_ALPN_data {
    short protoCount;
    char *proto[MAX_PROTO_EXT];
    int32 protoLen[MAX_PROTO_EXT];
} t_ALPN_data;

#define SZ_ALPN_DATA sizeof(t_ALPN_data)
typedef t_ALPN_data *p_ALPN_data;


/*****************************************************************************
    SNI entries  a.k.a virtual hosts

    For each host we can have:
        Hostname regex
        Certificate (not stored, used to initialize SSL keys)
        Key (not stored, used to initialize SSL keys)
        In the SSL keys:
            - Session tickets keys
            - DH params
            - OCSP staple
            - Certificate Transparency files
        Protocols
*/

#define MAX_SNI_ENTRIES     16

typedef struct s_SNI_entry {
#ifndef WIN32
    regex_t regex_hostname;
#else
    int32 hostnameLen;
    unsigned char hostname[255];
#endif
    sslKeys_t *keys;
    p_ALPN_data alpn;
} t_SNI_entry;

#define SZ_SNI_ENTRY sizeof(t_SNI_entry)
typedef t_SNI_entry *p_SNI_entry;

/*****************************************************************************
    SSL servers

    Each server can have maximum MAX_SNI_ENTRIES virtual hosts

    We can handle maximum MAX_SNI_SERVERS servers

    For each server we can have:
        Virtual hosts
        Protocols
*/

#define MAX_SSL_SERVERS     16

typedef struct s_SSL_server {
    t_SNI_entry *SNI_entries[MAX_SNI_ENTRIES];
    int16 SNI_entries_number;
    sslKeys_t *keys;
    p_ALPN_data alpn;
} t_SSL_server;

#define SZ_SSL_SERVER sizeof(t_SSL_server)
typedef t_SSL_server *p_SSL_server;

p_SSL_server SSL_servers[MAX_SSL_SERVERS];
int16 SSL_server_index = 0;


/*****************************************************************************
    SSL extra data

    For each SSL session we keep:
        SSL ID - equal to the socket file number
        ALPN data
        Pointer to the server data on which the connection was accepted
*/

typedef struct s_SSL_data {
    uint32_t ssl_id;
    int server_index;
    int cbALPN_done;
    int cbSNI_done;
    sslKeys_t *keys;
} t_SSL_data;

#define SZ_SSL_DATA sizeof(t_SSL_data)
typedef t_SSL_data *p_SSL_data;


/*****************************************************************************
    Support function
*/

void add_obj() {
    int rc;

    if (!matrixssl_initialized) {
        matrixssl_initialized = 1;
        
        rc = matrixSslOpen();
        if (rc != PS_SUCCESS)
            croak("%d", rc);
    }
#ifdef MATRIX_DEBUG
    warn("add_obj: objects number %d -> %d", objects, objects + 1);
    objects++;
#endif
}


#ifdef MATRIX_DEBUG
void del_obj() {
    if (matrixssl_initialized) {
        warn("del_obj: objects number %d -> %d", objects, objects - 1);
        objects--;
    }
}
#else
#define del_obj()
#endif


/*
 * my_hv_store() helper macro to avoid writting hash key names twice or
 * hardcoding their length
#define myVAL_LEN(k)        (k), strlen((k))
 */

#define my_hv_store(myh1,myh2,myh3,myh4)    hv_store((myh1),(myh2),(strlen((myh2))),(myh3),(myh4))

/*
 * Hash which will contain perl's certValidate CODEREF
 * between matrixSslNew*Session() and matrixSslDeleteSession().
 * 
 * Hash format:
 *  key     integer representation of $ssl (ssl_t *)
 *  value   \&cb_certValidate
 */
static HV * certValidatorArg = NULL;

int32 appCertValidator(ssl_t *ssl, psX509Cert_t *certInfo, int32 alert) {
    dSP;
    SV *key;
    SV *callback;
    AV *certs;
    int res;

    ENTER;
    SAVETMPS;

    key = sv_2mortal(newSViv(PTR2IV(ssl)));
    callback = HeVAL(hv_fetch_ent(certValidatorArg, key, 0, 0));

    /* Convert (psX509Cert_t *) structs into array of hashes. */
    certs = (AV *)sv_2mortal((SV *)newAV());
    for (; certInfo != NULL; certInfo=certInfo->next) {
        HV *sslCertInfo;
        HV *subjectAltName;
        HV *subject;
        HV *issuer;

        subjectAltName = newHV();

        subject = newHV();
        if (certInfo->subject.country != NULL)
            my_hv_store(subject, "country",
                newSVpv(certInfo->subject.country, 0), 0);
        if (certInfo->subject.state != NULL)
            my_hv_store(subject, "state",
                newSVpv(certInfo->subject.state, 0), 0);
        if (certInfo->subject.locality != NULL)
            my_hv_store(subject, "locality",
                newSVpv(certInfo->subject.locality, 0), 0);
        if (certInfo->subject.organization != NULL)
            my_hv_store(subject, "organization",
                newSVpv(certInfo->subject.organization, 0), 0);
        if (certInfo->subject.orgUnit != NULL)
            my_hv_store(subject, "orgUnit",
                newSVpv(certInfo->subject.orgUnit, 0), 0);
        if (certInfo->subject.commonName != NULL)
            my_hv_store(subject, "commonName",
                newSVpv(certInfo->subject.commonName, 0), 0);

        issuer = newHV();
        if (certInfo->issuer.country != NULL)
            my_hv_store(issuer, "country",
                newSVpv(certInfo->issuer.country, 0), 0);
        if (certInfo->issuer.state != NULL)
            my_hv_store(issuer, "state",
                newSVpv(certInfo->issuer.state, 0), 0);
        if (certInfo->issuer.locality != NULL)
            my_hv_store(issuer, "locality",
                newSVpv(certInfo->issuer.locality, 0), 0);
        if (certInfo->issuer.organization != NULL)
            my_hv_store(issuer, "organization",
                newSVpv(certInfo->issuer.organization, 0), 0);
        if (certInfo->issuer.orgUnit != NULL)
            my_hv_store(issuer, "orgUnit",
                newSVpv(certInfo->issuer.orgUnit, 0), 0);
        if (certInfo->issuer.commonName != NULL)
            my_hv_store(issuer, "commonName",
                newSVpv(certInfo->issuer.commonName, 0), 0);

        sslCertInfo = newHV();
        if (certInfo->notBefore != NULL)
            my_hv_store(sslCertInfo, "notBefore",
                newSVpv(certInfo->notBefore, 0), 0);
        if (certInfo->notAfter != NULL)
            my_hv_store(sslCertInfo, "notAfter",
                newSVpv(certInfo->notAfter, 0), 0);
        my_hv_store(sslCertInfo, "subjectAltName",
            newRV_inc(sv_2mortal((SV *)subjectAltName)), 0);
        my_hv_store(sslCertInfo, "subject",
            newRV_inc(sv_2mortal((SV *)subject)), 0);
        my_hv_store(sslCertInfo, "issuer",
            newRV_inc(sv_2mortal((SV *)issuer)), 0);
        my_hv_store(sslCertInfo, "authStatus",
            newSViv(certInfo->authStatus), 0);

        /* TODO There is a lot more (less useful) fields available… */

        av_push(certs, newRV_inc(sv_2mortal((SV *)sslCertInfo)));
    }

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV *)certs)));
    XPUSHs(sv_2mortal(newSViv(alert)));
    PUTBACK;

    res = call_sv(callback, G_EVAL|G_SCALAR);

    SPAGAIN;

    if (res != 1)
        croak("Internal error: perl callback doesn't return 1 scalar!");

    if (SvTRUE(ERRSV)) {
        warn("%s", SvPV_nolen(ERRSV));
        warn("die() in certValidate callback not allowed, continue...\n");
        POPs;
        res = -1;
    } else {
        res = POPi;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

/*
 * Hash which will contain perl's extCallback CODEREF
 * between matrixSslNew*Session() and matrixSslDeleteSession().
 * 
 * Hash format:
 *  key     integer representation of $ssl (ssl_t *)
 *  value   \&cb_certValidate
 */
static HV * extensionCbackArg = NULL;

int32 appExtensionCback(ssl_t *ssl, uint16_t type, uint8_t len, void *data) {
    dSP;
    SV *key;
    SV *callback;
    int res;

    ENTER;
    SAVETMPS;

    key = sv_2mortal(newSViv(PTR2IV(ssl)));
    callback = HeVAL(hv_fetch_ent(extensionCbackArg, key, 0, 0));

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(type)));
    XPUSHs(sv_2mortal(newSVpvn((const char*) data, len)));
    PUTBACK;

    res = call_sv(callback, G_EVAL|G_SCALAR);

    SPAGAIN;

    if (res != 1)
        croak("Internal error: perl callback doesn't return 1 scalar!");

    if (SvTRUE(ERRSV)) {
        warn("%s", SvPV_nolen(ERRSV));
        warn("die() in extensionCback callback not allowed, continue...\n");
        POPs;
        res = -1;
    } else {
        res = POPi;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

/* Perl callback that will get called when a client protocol is selected */
static SV* ALPNCallback = NULL;

/* Perl callback that will get called when a hostname is successfully matched. */
static SV* VHIndexCallback = NULL;

/*
 * ALPN callback that gets called from matrixSSL whenever a client sends an ALPN extension.
 *
 * This function gets called only in a server socket context.
 *
 * ssl->userPtr is a pointer to a t_SSL_data structure containing our custom data
 *
 * Params:
 * (in) ssl         - pointer to the SSL session
 * (in) protoCount  - how many protocols does the client implement
 * (in) proto       - array with protocols
 * (in) protoLen    - length of each protocol name (in bytes)
 * (out) index      - it will be set to the index of the protocol the server supports or -1 if the server
 *                    doesn't support any of the client's protocols
 */
void ALPNCallbackXS(void *ssl, short protoCount, char *proto[MAX_PROTO_EXT], int32 protoLen[MAX_PROTO_EXT], int32 *index) {
    ssl_t *pssl;
    int32 res_cl = -1, res_sv = -1, i, j, res;
    uint32_t ssl_id;
    p_ALPN_data alpn = NULL;
    p_SSL_data ssl_data;
    p_SSL_server ss;
#ifndef WIN32
    int regex_res = 0;
#if defined(MATRIX_DEBUG)
    char regex_error[255];
#endif
#endif
#ifdef MATRIX_DEBUG
    warn("alpncb: ssl = %p, userptr = %p, expectdName = %s", ssl, ((ssl_t *) ssl)->userPtr, ((ssl_t *) ssl)->expectedName);
#endif
    /* get SSL session and our custom SSL session data */
    pssl = (ssl_t *) ssl;
    ssl_data = (p_SSL_data) pssl->userPtr;
    ssl_id = ssl_data->ssl_id;
    ss = SSL_servers[ssl_data->server_index];

    /* was there a SNI extension parsed? */
    if (pssl->expectedName != NULL) {
        for (i = 0; i < ss->SNI_entries_number; i++)
#ifndef WIN32
            if ((regex_res = regexec(&(ss->SNI_entries[i]->regex_hostname), (const char *) pssl->expectedName, 0, NULL, 0)) == 0) {
#else
            if (!stricmp(pssl->expectedName, ss->SNI_entries[i]->hostname)) {
#endif
#ifdef MATRIX_DEBUG
                warn("SNI match for %s on %d", pssl->expectedName, i);
#endif
                /* found a matching hostname so save the keys in case the SNI callback is called */
                ssl_data->keys = ss->SNI_entries[i]->keys;

                break;
#if defined(MATRIX_DEBUG) && !defined(WIN32)
            } else {
                regerror(regex_res, &(ss->SNI_entries[i]->regex_hostname), regex_error, 255);
                warn("Error matching %d SNI entry: %s", i, regex_error);
#endif
            }

        /* test if a matching hostname was found */
        if (i < ss->SNI_entries_number) {
            /* get the protocols for the virtual host */
            alpn = ss->SNI_entries[i]->alpn;

            /* test Perl SNI callback present and not already called */
            if ((VHIndexCallback != NULL) && !ssl_data->cbSNI_done) {
                /* execute Perl SNI callback */
                dSP;

                ENTER;
                SAVETMPS;

                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSViv(ssl_id)));
                XPUSHs(sv_2mortal(newSViv(i)));
                XPUSHs(sv_2mortal(newSVpv(pssl->expectedName, strlen(pssl->expectedName))));
                PUTBACK;

                res = call_sv(VHIndexCallback, G_EVAL|G_SCALAR);

                SPAGAIN;

                if (SvTRUE(ERRSV)) {
                    warn("%s", SvPV_nolen(ERRSV));
                    warn("die() in SNI_callback callback not allowed, continue...\n");
                    POPs;
                    res = -1;
                }

                PUTBACK;
                FREETMPS;
                LEAVE;

                ssl_data->cbSNI_done;
            }
        } else {
            /* even if we didn't find a matching virtual host and we know the SSL connection
               will fail, we will choose a protocol and let the SNI callback return NULL keys
               so the client will get the apropiate SSL alert
            */
            alpn = ss->alpn;
        }
    } else {
        /* no SNI extension was received from the client, use default server protocols */
        alpn = ss->alpn;
    }

    /* test if the server has protocol defines (it should) */
    if (alpn != NULL) {
#ifdef MATRIX_DEBUG
        warn("ALPN callback XS: protoCount = %d, server protoCount = %d, ssl_data = %p, ssl_id = %d", protoCount, alpn->protoCount, ssl_data, ssl_id);
#endif
        for (i = 0; i < alpn->protoCount; i++) {
            for (j = 0; j < protoCount; j++) {
#ifdef MATRIX_DEBUG
                warn("Client protocol: %.*s, Server protocol: %.*s", protoLen[j], proto[j], alpn->protoLen[i], alpn->proto[i]);
#endif
                if ((alpn->protoLen[i] == protoLen[j]) && !strncmp(alpn->proto[i], proto[j], protoLen[j])) {
#ifdef MATRIX_DEBUG
                    warn("Match on cl = %d, sv = %d: %.*s", j, i, protoLen[j], proto[j]);
#endif
                    res_sv = i;
                    res_cl = j;
                    break;
                }
            }

            if (res_cl != -1) break;
        }
    }

    /* execute Perl ALPN callback */
    if ((ALPNCallback != NULL) && (res_sv != -1)) {
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(ssl_id)));
        XPUSHs(sv_2mortal(newSVpv(alpn->proto[res_sv], alpn->protoLen[res_sv])));
        PUTBACK;

        call_sv(ALPNCallback, G_DISCARD|G_SCALAR);

        SPAGAIN;

        if (SvTRUE(ERRSV)) {
            warn("%s", SvPV_nolen(ERRSV));
            warn("die() in ALPNCallback callback not allowed, continue...\n");
            res_cl = -1;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
#ifdef MATRIX_DEBUG
    else
        warn("ALPN data present but no ALPN callback set or no protocol could be selected (res_sv = %d)", res_sv);
#endif

    /* remember that the ALPN callback was executed */
    ssl_data->cbALPN_done = 1;

    /* return selected protocol */
    *index = res_cl;
}

/*
 * SNI callback that gets called from matrixSSL whenever a client send a SNI
 * extension.
 *
 * ssl->userPtr is a pointer to a t_SSL_data structure containing our custom data
 *
 * This function gets called only in a server socket context.
 *
 * Params:
 * (in) ssl         - pointer to the SSL session
 * (in) hostname    - the hostname specified by the client in the SNI extension
 * (in) hostnameLed - hostname length in bytes
 * (out) newKeys    - pointer that holds a pointer to a sslKeys_t structure. We will search through
 *                    all the SNI entries of the specified SNI server (see below) and if we find a hostname
 *                    that matches we will set this pointer to the address of the keys for the found SNI entry.
 *                    The keys strcuture holds certificate, private key, session ticket keys, DH param) for
 *                    a certain virtual host. This is initialized only once and is shared between all sessions
 *                    accepted by the server socket
 */
void SNI_callback(void *ssl, char *hostname, int32 hostnameLen, sslKeys_t **newKeys) {
    int32 i = 0, res;
    uint32_t ssl_id;
    p_SSL_data ssl_data;
    p_SSL_server ss;
    unsigned char _hostname[255];
#ifndef WIN32
    int regex_res = 0;
#if defined(MATRIX_DEBUG)
    char regex_error[255];
#endif
#endif
    /* get SSL session and our custom SSL session data */
    ssl_data = (p_SSL_data) ((ssl_t *) ssl)->userPtr;
    ssl_id = ssl_data->ssl_id;
    ss = SSL_servers[ssl_data->server_index];

    /* check if the keys are already set in our custom SSL data
       by a previous call to the ALPN callback */
    if (ssl_data->keys != NULL) {
#ifdef MATRIX_DEBUG
        warn("SNI_callback: Valid keys found, set by the ALPN callback. Returning");
#endif
        *newKeys = ssl_data->keys;
        return;
    }

    /* TODO: modify matrixSSL so it returns a null terminated hostname so this is no longer necessary */
    if (hostnameLen > 254) hostnameLen = 254;
    memcpy(_hostname, hostname, hostnameLen);
    _hostname[hostnameLen] = 0;

#ifdef MATRIX_DEBUG
    warn("SNI_callback: looking for hostname %s, ssl_data %p, ssl_id %d", _hostname, ssl_data, ssl_id);
#endif

    *newKeys = NULL;

    for (i = 0; i < ss->SNI_entries_number; i++)
#ifndef WIN32
        if ((regex_res = regexec(&(ss->SNI_entries[i]->regex_hostname), (const char *) _hostname, 0, NULL, 0)) == 0) {
#else
        if ((hostnameLen == ss->SNI_entries[i]->hostnameLen) && !stricmp(_hostname, ss->SNI_entries[i]->hostname)) {
#endif
#ifdef MATRIX_DEBUG
            warn("SNI match for %s on %d", _hostname, i);
#endif
            *newKeys = ss->SNI_entries[i]->keys;

            break;
#if defined(MATRIX_DEBUG) && !defined(WIN32)
        } else {
            regerror(regex_res, &(ss->SNI_entries[i]->regex_hostname), regex_error, 255);
            warn("Error matching %d SNI entry: %s", i, regex_error);
#endif
        }

    /* if the requested virtual host was not found we try to return the default server keys (if they are set) */
    if (*newKeys == NULL) {
        if (ss->keys != NULL) {
            *newKeys = ss->keys;
            /* set the index to -1 to singal that the default server keys are used */
            i = -1;
        }
    }

    /* execute Perl SNI callback if necessary (might have been called already from the ALPN callback) */
    if ((i < ss->SNI_entries_number) && (VHIndexCallback != NULL) && !ssl_data->cbSNI_done) {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(ssl_id)));
        XPUSHs(sv_2mortal(newSViv(i)));
        XPUSHs(sv_2mortal(newSVpv(hostname, hostnameLen)));
        PUTBACK;

        res = call_sv(VHIndexCallback, G_EVAL|G_SCALAR);

        SPAGAIN;

        if (SvTRUE(ERRSV)) {
            warn("%s", SvPV_nolen(ERRSV));
            warn("die() in SNI_callback callback not allowed, continue...\n");
            POPs;
            res = -1;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        ssl_data->cbSNI_done = 1;
    }
}

/*
 * Utility function for building the 'signed_certificate_timestamp' TLS extension data.
 * This extension is sent by client who want to receive  Certificate Transparancy information
 *
 * Params:
 * (in) ar - Perl scalar - holds the file name which contains multiple SCT (Signed Certificate
 *           Timestamp) binary structures received from CT server logs. This file repesents a ready
 *           to use extension data
 *         - Perl array rference - holds as elements file names of individual SCT binary structures
 *           received from CT server logs. The function will concatenate all these files and build
 *           the extension data
 * (out) buffer - a pointer to a pointer that will be allocated and will hold the extension data
 * (out) buffer_size - a pointer to an int32 variable that will hold the extension data size
*/
int build_SCT_buffer(SV *ar, unsigned char **buffer, int32 *buffer_size) {
#ifdef WIN32
    struct _stat fstat;
#else
    struct stat fstat;
#endif
    AV *sct_array;
    SV *item_sv;
    unsigned char *item, *sct, *c;
    STRLEN item_len = 0;
    int sct_array_size = 0, i = 0, sct_total_size = 0, sct_size = 0, rc = PS_SUCCESS;

    if (SvOK(ar)) {
        if (!SvROK(ar)) {
            /* a single file */
            item = SvPV(ar, item_len);
#ifdef MATRIX_DEBUG
            warn("Loading SCT single file: %s", item);
#endif
            if (item == NULL)
                croak("build_SCT_buffer: expecting a scalar or array reference as first parameter");

            if ((rc = psGetFileBuf(NULL, item, buffer, buffer_size)) != PS_SUCCESS) {
                warn("Error %d trying to read file %s", rc, item);
                return rc;
            }

            return 1;
        } else {
            if (SvTYPE(SvRV(ar)) != SVt_PVAV)
                croak("build_SCT_buffer: expecting a scalar or array reference as first parameter");
        }
    } else {
        croak("build_SCT_buffer: expecting a scalar or array reference as first parameter");
    }

    /* get the SCT files array */
    sct_array = (AV *) SvRV(ar);

    /* get number of SCT files */
    sct_array_size = (uint16) av_len(sct_array) + 1;

#ifdef MATRIX_DEBUG
    warn("Preparing to read %d SCT files", sct_array_size);
#endif
    for (i = 0; i < sct_array_size; i++) {
        item_sv = *av_fetch(sct_array, i, 0);
        item = SvPV(item_sv, item_len);

#ifdef WIN32
        if (_stat(item, &fstat) != 0) {
#else
        if (stat(item, &fstat) != 0) {
#endif
            warn("Error reading stats for SCT file %s", item);
            return -1;
        }
#ifdef MATRIX_DEBUG
        warn("Reading SCT file %d - %s; size: %d", i, item, fstat.st_size);
#endif
        sct_total_size += (size_t) fstat.st_size;
    }

    sct_total_size += sct_array_size * 2;
    *buffer_size = sct_total_size;

    c = *buffer = (unsigned char *) psMallocNative(sct_total_size);

    for (i = 0; i < sct_array_size; i++) {
        item_sv = *av_fetch(sct_array, i, 0);
        item = SvPV(item_sv, item_len);

        if ((rc = psGetFileBuf(NULL, item, &sct, &sct_size)) != PS_SUCCESS) {
            warn("Error %d trying to read file %s", rc, item);
            psFreeNative(*buffer);
            *buffer = NULL;
            *buffer_size = 0;
            return rc;
        }

        *c = (sct_size & 0xFF00) >> 8; c++;
        *c = (sct_size & 0xFF); c++;
        memcpy(c, sct, sct_size);
        c+= sct_size;

        psFreeNative(sct);
    }

    return sct_array_size;
}


MODULE = Crypt::MatrixSSL3      PACKAGE = Crypt::MatrixSSL3     

INCLUDE: inc/const-xs.inc

PROTOTYPES: ENABLE


int _getObjCount()
    CODE:
#ifdef MATRIX_DEBUG
    RETVAL = objects;
#else
    RETVAL = 0;
#endif
    OUTPUT:
    RETVAL


int set_cipher_suite_enabled_status(cipherId, status)
    short cipherId;
    int status;

    CODE:
    add_obj();
    RETVAL = matrixSslSetCipherSuiteEnabledStatus(NULL, cipherId, status);

    OUTPUT:
    RETVAL


void Open()
    CODE:
    add_obj();


void Close()
    int i = 0, j = 0, k = 0;
    p_SNI_entry se = NULL;
    p_SSL_server ss = NULL;

    CODE:
    del_obj();

    /* release SSL servers */
#ifdef MATRIX_DEBUG
    warn("----\nReleasing %d SSL servers", SSL_server_index);
#endif

    for (j = 0; j < SSL_server_index; j++) {
        ss = SSL_servers[j];
#ifdef MATRIX_DEBUG
        warn("Releasing resources for SSL server %d", j);
#endif
        if (ss->alpn != NULL) {
#ifdef MATRIX_DEBUG
            warn("  Releasing ALPN data: %d protocols", ss->alpn->protoCount);
#endif
            for (k = 0; k < ss->alpn->protoCount; k++)
                if (ss->alpn->proto[k] != NULL) free(ss->alpn->proto[k]);

            free(ss->alpn);
        }
#ifdef MATRIX_DEBUG
        warn("  Releasing %d SNI entries", ss->SNI_entries_number);
#endif
        for (i = 0; i < ss->SNI_entries_number; i++) {
            se = ss->SNI_entries[i];
#ifndef WIN32
#ifdef MATRIX_DEBUG
            warn("  Releasing regex for SNI entry %d", i);
#endif
            regfree(&(se->regex_hostname));
#endif
#ifdef MATRIX_DEBUG
            warn("  Releasing keys for SNI entry %d", i);
#endif
            matrixSslDeleteKeys(ss->SNI_entries[i]->keys);
            del_obj();

            if (se->alpn != NULL) {
#ifdef MATRIX_DEBUG
                warn("  Releasing ALPN data: %d protocols", se->alpn->protoCount);
#endif
                for (k = 0; k < se->alpn->protoCount; k++)
                    if (se->alpn->proto[k] != NULL) free(se->alpn->proto[k]);

                free(se->alpn);
            }
#ifdef MATRIX_DEBUG
            warn("  Releasing SNI entry %d", i);
#endif
            free(se);
        }
#ifdef MATRIX_DEBUG
        warn("Releasing SSL server %d", j);
#endif
        free(ss);
    }
    SSL_server_index = 0;
#ifdef MATRIX_DEBUG
    warn("Calling matrixSslClose()");
#endif
    matrixSslClose();
    matrixssl_initialized = 0;


int create_SSL_server()
    CODE:
    /* new SSL server, check limits */
    if (SSL_server_index == MAX_SSL_SERVERS) {
        warn("We have already initiazlied the maximum number of %d SSL servers", MAX_SSL_SERVERS);
        XSRETURN_IV(-1);
    }
#ifdef MATRIX_DEBUG
    warn("create_SSL_server: allocating buffer for new SSL server at index %d", SSL_server_index);
#endif
    /* allocate a new SSL server */
    SSL_servers[SSL_server_index] = (p_SSL_server) malloc(SZ_SSL_SERVER);
    memset(SSL_servers[SSL_server_index], 0, SZ_SSL_SERVER);

    RETVAL = SSL_server_index;

    SSL_server_index++;

    OUTPUT:
    RETVAL


int refresh_OCSP_staple(server_index, index, OCSP_file)
    int server_index = SvOK(ST(0)) ? SvIV(ST(0)) : -1;
    int index = SvOK(ST(1)) ? SvIV(ST(1)): -1;
    unsigned char *OCSP_file = SvOK(ST(2)) ? SvPV_nolen(ST(2)) : NULL;
    unsigned char *buffer = NULL;
    int32 buffer_size = 0, rc = 0;

    CODE:
    if (server_index < 0)
        croak("Invalid SSL server index %d", server_index);

    if (index < 0)
        croak("OCSP staple for SSL (default) servers is refreshed using the keys now!");

    if (OCSP_file == NULL)
        croak("You must specify a valid OCSP staple file");
#ifdef MATRIX_DEBUG
    warn("Refresh OCSP staple buffer for SSL server %d/SNI entry %d", server_index, index);
#endif
    if (server_index >= SSL_server_index)
        croak("Out of range SSL server index spcified: %d > %d", server_index, SSL_server_index - 1);

    if (index >= SSL_servers[server_index]->SNI_entries_number)
        croak("Out of range SNI entry index spcified for SSL server %d: %d > %d", server_index, index, SSL_servers[server_index]->SNI_entries_number - 1);

    rc = psGetFileBuf(NULL, OCSP_file, &buffer, &buffer_size);

    if (rc != PS_SUCCESS) {
        warn("Failed to load OCSP staple %s; %d", OCSP_file, rc);
        XSRETURN_IV(rc);
    }

    rc = matrixSslLoadOCSPResponse(SSL_servers[server_index]->SNI_entries[index]->keys, buffer, buffer_size);

    if (buffer != NULL) psFreeNative(buffer);

    if (rc != PS_SUCCESS)
        croak("matrixSslLoadOCSPResponse failed for SSL server %d, SNI entry %d: $d", server_index, index, rc);

    RETVAL = rc;

    OUTPUT:
    RETVAL


int refresh_SCT_buffer(server_index, index, SCT_params)
    int server_index = SvOK(ST(0)) ? SvIV(ST(0)) : -1;
    int index = SvOK(ST(1)) ? SvIV(ST(1)): -1;
    SV *SCT_params;
    unsigned char *buffer = NULL;
    int32 buffer_size = 0, res = 0, rc = 0;

    CODE:
    if (server_index < 0)
        croak("Invalid SSL server index %d", server_index);

    if (index < 0)
        croak("SCT buffer for SSL (default) servers is refreshed using the keys now!");
#ifdef MATRIX_DEBUG
    warn("Refresh SCT buffer for SSL server %d/SNI entry %d", server_index, index);
#endif
    if (server_index >= SSL_server_index)
        croak("Out of range SSL server index spcified: %d > %d", server_index, SSL_server_index - 1);

    if (index >= SSL_servers[server_index]->SNI_entries_number)
        croak("Out of range SNI entry index spcified for SSL server %d: %d > %d", server_index, index, SSL_servers[server_index]->SNI_entries_number - 1);

    res = build_SCT_buffer(SCT_params, &buffer, &buffer_size);
#ifdef MATRIX_DEBUG
    warn("Refreshed SCT buffer: Loaded %d SCT files, %p %d", rc, buffer, buffer_size);
#endif
    if (res < 1) {
        if (buffer != NULL) psFreeNative(buffer);
        croak("Filed to build the SCT buffer for SSL server %d, SNI entry %d: %d", server_index, index, res);
    }

    rc = matrixSslLoadSCTResponse(SSL_servers[server_index]->SNI_entries[index]->keys, buffer, buffer_size);

    if (buffer != NULL) psFreeNative(buffer);

    if (rc != PS_SUCCESS) {
        croak("matrixSslLoadSCTResponse failed for SSL server %d, SNI entry %d: $d", server_index, index, rc);
        XSRETURN_IV(0);
    }

    RETVAL = res;

    OUTPUT:
    RETVAL


int refresh_ALPN_data(server_index, index, ALPN_data)
    int server_index = SvOK(ST(0)) ? SvIV(ST(0)) : -1;
    int index = SvOK(ST(1)) ? SvIV(ST(1)): -1;
    SV *ALPN_data;
    AV *aproto = NULL;
    p_ALPN_data alpn = NULL, *palpn = NULL;
    SV *tmp_sv = NULL;
    unsigned char *item = NULL;
    STRLEN item_len = 0;
    int i = 0;

    CODE:
    if (!(SvROK(ALPN_data) && SvTYPE(SvRV(ALPN_data)) == SVt_PVAV))
        croak("Expected ALPN data to be an array reference");

    if (server_index < 0)
        croak("Invalid SSL server index %d", server_index);

    if (server_index >= SSL_server_index)
        croak("Out of range SSL server index spcified: %d > %d", server_index, SSL_server_index - 1);

    if (index < 0) {
#ifdef MATRIX_DEBUG
        warn("Refresh SSL (default) server %d ALPN data", server_index);
#endif
        palpn = &(SSL_servers[server_index]->alpn);
    } else {
#ifdef MATRIX_DEBUG
        warn("Refresh ALPN_data for SSL server %d/SNI entry %d", server_index, index);
#endif
        if (index >= SSL_servers[server_index]->SNI_entries_number)
            croak("Out of range SNI entry index spcified for SSL server %d: %d > %d", server_index, index, SSL_servers[server_index]->SNI_entries_number - 1);

        palpn = &(SSL_servers[server_index]->SNI_entries[index]->alpn);
    }

    /* Check if we should allocate the ALPN data strcture */
    if (*palpn == NULL) {
        *palpn = (p_ALPN_data) malloc(SZ_ALPN_DATA);
        memset(*palpn, 0, SZ_ALPN_DATA);
    }

    alpn = *palpn;
    aproto = (AV *) SvRV(ALPN_data);

    /* Free previous allocated protocols (if any) */
#ifdef MATRIX_DEBUG
    warn("Freeing %d protocols", alpn->protoCount);
#endif
    for (i = 0; i > alpn->protoCount; i++)
        if (alpn->proto[i]) free(alpn->proto[i]);

    /* Load new protocols */
    alpn->protoCount = (short) av_len(aproto) + 1;
    if (alpn->protoCount > MAX_PROTO_EXT) alpn->protoCount = MAX_PROTO_EXT;

    for (i = 0; i < alpn->protoCount; i++) {
        tmp_sv = *av_fetch(aproto, i, 0);
        item = (unsigned char *) SvPV(tmp_sv, item_len);
#ifdef MATRIX_DEBUG
        warn("Protocol %d: %.*s", i, item_len, item);
#endif
        alpn->proto[i] = (unsigned char *) malloc(item_len);
        memcpy(alpn->proto[i], item, item_len);
        alpn->protoLen[i] = item_len;
    }

    RETVAL = alpn->protoCount;

    OUTPUT:
    RETVAL


void set_VHIndex_callback(vh_index_cb)
    SV *vh_index_cb;

    CODE:
    VHIndexCallback = SvREFCNT_inc(SvRV(vh_index_cb));


void set_ALPN_callback(alpn_cb)
    SV *alpn_cb;

    CODE:
    ALPNCallback = SvREFCNT_inc(SvRV(alpn_cb));


unsigned int capabilities()
    CODE:
    RETVAL = 0;
#ifdef USE_SHARED_SESSION_CACHE
    RETVAL |= SHARED_SESSION_CACHE_ENABLED;
#endif
#ifdef USE_STATELESS_SESSION_TICKETS
    RETVAL |= STATELESS_TICKETS_ENABLED;
#endif
#ifdef REQUIRE_DH_PARAMS
    RETVAL |= DH_PARAMS_ENABLED;
#endif
#ifdef USE_ALPN
    RETVAL |= ALPN_ENABLED;
#endif
#ifdef USE_OCSP
    RETVAL |= OCSP_STAPLES_ENABLED;
#endif
#ifdef USE_SCT
    RETVAL |= CERTIFICATE_TRANSPARENCY_ENABLED;
#endif
    RETVAL |= SNI_ENABLED;

    OUTPUT:
    RETVAL


MODULE = Crypt::MatrixSSL3  PACKAGE = Crypt::MatrixSSL3::KeysPtr    PREFIX = keys_


Crypt_MatrixSSL3_Keys *keys_new()
    INIT:
    sslKeys_t *keys;
    int rc;

    CODE:
    add_obj();
    rc = matrixSslNewKeys(&keys, NULL);
    if (rc != PS_SUCCESS) {
        del_obj();
        croak("%d", rc);
    }

    RETVAL = (Crypt_MatrixSSL3_Keys *)keys;

    OUTPUT:
    RETVAL


void keys_DESTROY(keys);
    Crypt_MatrixSSL3_Keys *keys;

    CODE:
    matrixSslDeleteKeys((sslKeys_t *)keys);
    del_obj();


int keys_load_rsa(keys, certFile, privFile, privPass, trustedCAcertFiles)
    Crypt_MatrixSSL3_Keys *keys;
    char *certFile = SvOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
    char *privFile = SvOK(ST(2)) ? SvPV_nolen(ST(2)) : NULL;
    char *privPass = SvOK(ST(3)) ? SvPV_nolen(ST(3)) : NULL;
    char *trustedCAcertFiles = SvOK(ST(4)) ? SvPV_nolen(ST(4)) : NULL;

    CODE:
    RETVAL = (int) matrixSslLoadRsaKeys((sslKeys_t *)keys, certFile, privFile, privPass, trustedCAcertFiles);

    OUTPUT:
    RETVAL


int keys_load_rsa_mem(keys, cert, priv, trustedCA)
    Crypt_MatrixSSL3_Keys *keys;
    SV *cert;
    SV *priv;
    SV *trustedCA;
    unsigned char *certBuf = NULL;
    unsigned char *privBuf = NULL;
    unsigned char *trustedCABuf = NULL;
    STRLEN certLen = 0;
    STRLEN privLen = 0;
    STRLEN trustedCALen = 0;

    CODE:
    /* All bufs can contain \0, so SvPV must be used instead of strlen() */
    certBuf = SvOK(cert) ? (unsigned char *) SvPV(cert, certLen) : NULL;
    privBuf = SvOK(priv) ? (unsigned char *) SvPV(priv, privLen) : NULL;
    trustedCABuf= SvOK(trustedCA) ? (unsigned char *) SvPV(trustedCA, trustedCALen) : NULL;

    RETVAL = matrixSslLoadRsaKeysMem((sslKeys_t *)keys, certBuf, certLen, privBuf, privLen,
                                      trustedCABuf, trustedCALen);

    OUTPUT:
    RETVAL


int keys_load_ecc(keys, certFile, privFile, privPass, trustedCAcertFiles)
    Crypt_MatrixSSL3_Keys *keys;
    char *certFile = SvOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
    char *privFile = SvOK(ST(2)) ? SvPV_nolen(ST(2)) : NULL;
    char *privPass = SvOK(ST(3)) ? SvPV_nolen(ST(3)) : NULL;
    char *trustedCAcertFiles = SvOK(ST(4)) ? SvPV_nolen(ST(4)) : NULL;

    CODE:
    RETVAL = (int) matrixSslLoadEcKeys((sslKeys_t *)keys, certFile, privFile, privPass, trustedCAcertFiles);

    OUTPUT:
    RETVAL


int keys_load_ecc_mem(keys, cert, priv, trustedCA)
    Crypt_MatrixSSL3_Keys *keys;
    SV *cert;
    SV *priv;
    SV *trustedCA;
    unsigned char *certBuf = NULL;
    unsigned char *privBuf = NULL;
    unsigned char *trustedCABuf = NULL;
    STRLEN certLen = 0;
    STRLEN privLen = 0;
    STRLEN trustedCALen = 0;

    CODE:
    /* All bufs can contain \0, so SvPV must be used instead of strlen() */
    certBuf = SvOK(cert) ? (unsigned char *) SvPV(cert, certLen) : NULL;
    privBuf = SvOK(priv) ? (unsigned char *) SvPV(priv, privLen) : NULL;
    trustedCABuf= SvOK(trustedCA) ? (unsigned char *) SvPV(trustedCA, trustedCALen) : NULL;

    RETVAL = matrixSslLoadEcKeysMem((sslKeys_t *)keys, certBuf, certLen, privBuf, privLen,
                                      trustedCABuf, trustedCALen);

    OUTPUT:
    RETVAL


int keys_load_pkcs12(keys, p12File, importPass, macPass, flags)
    Crypt_MatrixSSL3_Keys *keys;
    char *p12File = SvOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
    SV *importPass;
    SV *macPass;
    int flags;
    unsigned char *importPassBuf = NULL;
    unsigned char *macPassBuf = NULL;
    STRLEN importPassLen   = 0;
    STRLEN macPassLen  = 0;

    CODE:
    importPassBuf= SvOK(importPass) ? (unsigned char *) SvPV(importPass, importPassLen) : NULL;
    macPassBuf = SvOK(macPass) ? (unsigned char *) SvPV(macPass, macPassLen) : NULL;

    RETVAL = matrixSslLoadPkcs12((sslKeys_t *)keys, (unsigned char *) p12File, importPassBuf, importPassLen,
                                  macPassBuf, macPassLen, flags);

    OUTPUT:
    RETVAL


int keys_load_session_ticket_keys(keys, name, symkey, hashkey)
    Crypt_MatrixSSL3_Keys *keys;
    SV *name; 
    SV *symkey;
    SV *hashkey;
    char *nameBuf = NULL, *symkeyBuf = NULL, *hashkeyBuf = NULL;
    STRLEN symkeyLen = 0, hashkeyLen = 0;

    CODE:
    nameBuf = SvOK(name) ? SvPV_nolen(name) : NULL;
    symkeyBuf = SvOK(symkey) ? SvPV(symkey, symkeyLen) : NULL;
    hashkeyBuf = SvOK(hashkey) ? SvPV(hashkey, hashkeyLen) : NULL;

    RETVAL = (int) matrixSslLoadSessionTicketKeys(keys, nameBuf, symkeyBuf, symkeyLen, hashkeyBuf, hashkeyLen);

    OUTPUT:
    RETVAL


int keys_load_DH_params(keys, paramsFile)
    Crypt_MatrixSSL3_Keys *keys;
    char *paramsFile = SvOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;

    CODE:
    RETVAL = (int) matrixSslLoadDhParams((sslKeys_t *)keys, paramsFile);

    OUTPUT:
    RETVAL


int keys_load_OCSP_response(keys, OCSP_file)
    Crypt_MatrixSSL3_Keys *keys;
    char *OCSP_file = SvOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
    unsigned char *buffer = NULL;
    int32 buffer_size = 0, rc;

    CODE:
        if ((rc = psGetFileBuf(NULL, OCSP_file, &buffer, &buffer_size)) != PS_SUCCESS) {
            croak("Error %d trying to read file %s", rc, OCSP_file);
        } else {
            rc = matrixSslLoadOCSPResponse(keys, buffer, buffer_size);

            psFreeNative(buffer);

            if (rc != PS_SUCCESS) {
                croak("Error %d while setting the OCSP response");
            }
        }

        RETVAL = rc;

    OUTPUT:
    RETVAL


int keys_load_SCT_response(keys, SCT_params)
    Crypt_MatrixSSL3_Keys *keys;
    SV *SCT_params;
    unsigned char *buffer = NULL;
    int32 buffer_size = 0, res = 0, rc = 0;

    CODE:
        if ((res = build_SCT_buffer(SCT_params, &buffer, &buffer_size)) < 1) {
            croak("Error trying to build SCT buffer");
        } else {
            rc = matrixSslLoadSCTResponse(keys, buffer, buffer_size);

            psFreeNative(buffer);

            if (rc != PS_SUCCESS) {
                croak("Error %d while setting the SCT response");
            }
        }

        RETVAL = res;

    OUTPUT:
    RETVAL


MODULE = Crypt::MatrixSSL3  PACKAGE = Crypt::MatrixSSL3::SessIDPtr  PREFIX = sessid_


Crypt_MatrixSSL3_SessID *sessid_new()
    INIT:
    int rc = PS_SUCCESS;
    sslSessionId_t *sessionId = NULL;

    CODE:
    add_obj();
    rc = matrixSslNewSessionId(&sessionId, NULL);
    if (rc != PS_SUCCESS) {
        del_obj();
        croak("%d", rc);
    }

    RETVAL = (Crypt_MatrixSSL3_SessID *)sessionId;

    OUTPUT:
    RETVAL


void sessid_DESTROY(sessionId)
    Crypt_MatrixSSL3_SessID *sessionId;

    CODE:
    matrixSslDeleteSessionId((sslSessionId_t *) sessionId);
    del_obj();


void sessid_clear(sessionId)
    Crypt_MatrixSSL3_SessID *sessionId;

    CODE:
    matrixSslClearSessionId((sslSessionId_t *) sessionId);


MODULE = Crypt::MatrixSSL3  PACKAGE = Crypt::MatrixSSL3::SessPtr    PREFIX = sess_


Crypt_MatrixSSL3_Sess *sess_new_client(keys, sessionId, cipherSuites, certValidator, expectedName, extensions, extensionCback)
    Crypt_MatrixSSL3_Keys *keys;
    Crypt_MatrixSSL3_SessID *sessionId;
    SV *cipherSuites;
    SV *certValidator;
    SV *expectedName;
    Crypt_MatrixSSL3_HelloExt * extensions;
    SV *extensionCback;
    ssl_t *ssl = NULL;
    SV *key = NULL;
    int rc = 0;
    uint8_t cipherCount = 0, i = 0;
    AV *cipherSuitesArray = NULL;
    SV **item = NULL;

    PREINIT:
    uint16_t cipherSuitesBuf[64];

    INIT:
    if (SvROK(cipherSuites) && SvTYPE(SvRV(cipherSuites)) == SVt_PVAV) {
        cipherSuitesArray = (AV *) SvRV(cipherSuites);

        cipherCount = (uint16) av_len(cipherSuitesArray) + 1;
        if (cipherCount > 64)
            croak("cipherSuites should not contain more than 64 ciphers");

        for (i = 0; i < cipherCount; i++) {
            item = av_fetch(cipherSuitesArray, i, 0);
            cipherSuitesBuf[i] = (uint32) SvIV(*item);
        }
    } else if (SvOK(cipherSuites)) {
        croak("cipherSuites should be undef or ARRAYREF");
    }

    CODE:
    add_obj();

    memset((void *) &sslOpts, 0, sizeof(sslSessOpts_t));

    rc = matrixSslNewClientSession(&ssl,
            (sslKeys_t *) keys, (sslSessionId_t *) sessionId, cipherSuitesBuf, cipherCount,
            (SvOK(certValidator) ? appCertValidator : NULL),
            (SvOK(expectedName) ? (const char *) SvPV_nolen(expectedName) : NULL),
            (tlsExtension_t *) extensions,
            (SvOK(extensionCback) ? appExtensionCback : NULL),
            &sslOpts);

    if (rc != MATRIXSSL_REQUEST_SEND) {
        del_obj();
        croak("%d", rc);
    }

    RETVAL = (Crypt_MatrixSSL3_Sess *)ssl;

    ENTER;
    SAVETMPS;

    key = sv_2mortal(newSViv(PTR2IV(ssl)));

    /* keep real callback in global hash: $certValidatorArg{ssl}=certValidator */
    if(SvOK(certValidator)) {
        if(certValidatorArg==NULL)
            certValidatorArg = newHV();
        hv_store_ent(certValidatorArg, key, SvREFCNT_inc(SvRV(certValidator)), 0);
    }
    /* keep real callback in global hash: $extensionCbackArg{ssl}=extensionCback */
    if(SvOK(extensionCback)) {
        if(extensionCbackArg==NULL)
            extensionCbackArg = newHV();
        hv_store_ent(extensionCbackArg, key, SvREFCNT_inc(SvRV(extensionCback)), 0);
    }

    FREETMPS;
    LEAVE;

    OUTPUT:
    RETVAL


Crypt_MatrixSSL3_Sess *sess_new_server(keys, certValidator)
    Crypt_MatrixSSL3_Keys *keys;
    SV *certValidator;
    ssl_t *ssl = NULL;
    SV *key = NULL;
    int rc = 0;
    p_SSL_data ssl_data = NULL;

    CODE:
    add_obj();

    memset((void *) &sslOpts, 0, sizeof(sslSessOpts_t));

    ssl_data = malloc(SZ_SSL_DATA);
    memset(ssl_data, 0, SZ_SSL_DATA);

    sslOpts.userPtr = ssl_data;

    rc = matrixSslNewServerSession(&ssl, (sslKeys_t *)keys,
            (SvOK(certValidator) ? appCertValidator : NULL),
            &sslOpts);
#ifdef MATRIX_DEBUG
    warn("new server: ssl = %p, ssl_data = %p", ssl, ssl_data);
#endif
    if (rc != PS_SUCCESS) {
        del_obj();
        croak("%d", rc);
    }

    RETVAL = (Crypt_MatrixSSL3_Sess *)ssl;

    ENTER;
    SAVETMPS;

    key = sv_2mortal(newSViv(PTR2IV(ssl)));

    /* keep real callback in global hash: $certValidatorArg{ssl}=certValidator */
    if(SvOK(certValidator)) {
        if(certValidatorArg==NULL)
            certValidatorArg = newHV();
        hv_store_ent(certValidatorArg, key, SvREFCNT_inc(SvRV(certValidator)), 0);
    }

    FREETMPS;
    LEAVE;

    OUTPUT:
    RETVAL

SV *get_SSL_secrets(ssl)
    Crypt_MatrixSSL3_Sess *ssl;
    HV *rh = NULL;
    sslSec_t *sec = NULL;
    const sslCipherSpec_t *cipher = NULL;

    CODE:
    rh = (HV *)sv_2mortal((SV *)newHV());
    sec = &(ssl->sec);
    cipher = ssl->cipher;

    my_hv_store(rh, "cipher_ident", newSViv(cipher->ident), 0);
    my_hv_store(rh, "cipher_type", newSViv(cipher->type), 0);
    my_hv_store(rh, "cipher_flags", newSViv(cipher->flags), 0);
    my_hv_store(rh, "cipher_macSize", newSViv(cipher->macSize), 0);
    my_hv_store(rh, "cipher_keySize", newSViv(cipher->keySize), 0);
    my_hv_store(rh, "cipher_ivSize", newSViv(cipher->ivSize), 0);
    my_hv_store(rh, "cipher_blockSize", newSViv(cipher->blockSize), 0);

    my_hv_store(rh, "clientRandom", newSVpvn(sec->clientRandom, SSL_HS_RANDOM_SIZE), 0);
    my_hv_store(rh, "serverRandom", newSVpvn(sec->serverRandom, SSL_HS_RANDOM_SIZE), 0);
    my_hv_store(rh, "masterSecret", newSVpvn(sec->masterSecret, SSL_HS_MASTER_SIZE), 0);
    my_hv_store(rh, "premaster", newSVpvn(sec->premaster, sec->premasterSize), 0);

    my_hv_store(rh, "writeMAC", newSVpvn(sec->writeMAC, cipher->macSize), 0);
    my_hv_store(rh, "readMAC", newSVpvn(sec->readMAC, cipher->macSize), 0);
    my_hv_store(rh, "writeKey", newSVpvn(sec->writeKey, cipher->keySize), 0);
    my_hv_store(rh, "readKey", newSVpvn(sec->readMAC, cipher->keySize), 0);
    my_hv_store(rh, "writeIV", newSVpvn(sec->writeIV, cipher->ivSize), 0);
    my_hv_store(rh, "readIV", newSVpvn(sec->readIV, cipher->ivSize), 0);

    RETVAL = newRV((SV *) rh);

    OUTPUT:
    RETVAL

int sess_init_SNI(ssl, server_index, sni_data = NULL)
    Crypt_MatrixSSL3_Sess *ssl;
    int server_index = SvOK(ST(1)) ? SvIV(ST(1)) : -1;
    SV *sni_data;
    AV *sni_array = NULL;
    SV *sd_sv = NULL;
    HV *sd = NULL;
    HV *hitem = NULL;
    AV *aitem = NULL;
    SV *item_sv = NULL;
    SV *tmp_sv = NULL;
    unsigned char *buffer = NULL;
    int32 buffer_size = 0;
    unsigned char *item = NULL;
    SV *cert_sv = NULL;
    unsigned char *cert = NULL;
    SV *key_sv = NULL;
    unsigned char *key = NULL;
    SV *trustedCA_sv = NULL;
    unsigned char *trustedCA = NULL;
    STRLEN item_len = 0;
    int32 rc = PS_SUCCESS, i = 0, j = 0, res = 0;
    p_SSL_data ssl_data = NULL;

    PREINIT:
    unsigned char stk_id[16];
    unsigned char stk_ek[32];
    STRLEN stk_ek_len = 0;
    unsigned char stk_hk[32];
    STRLEN stk_hk_len = 0;
    t_SSL_server *ss = NULL;
#ifndef WIN32
    int regex_res = 0;
    char regex_error[255];
#endif
    CODE:
#ifdef MATRIX_DEBUG
    warn("init_SNI: Setting up virtual hosts for SSL server %d", server_index);
#endif
    if (server_index < 0)
        croak("Invalid SSL server index %d", server_index);

    if (server_index >= SSL_server_index)
        croak("Out of range SSL server index spcified: %d > %d", server_index, SSL_server_index - 1);

    /* set SSL server pointer */
    ss = SSL_servers[server_index];

    if (ss->SNI_entries_number > 0)
        croak("SNI already setup for SSL server %d", server_index);

    /* initialize SNI server structure */
    if (!(SvROK(sni_data) && SvTYPE(SvRV(sni_data)) == SVt_PVAV))
        croak("Expected SNI data to be an array reference");

    /* our array of arrays */
    sni_array = (AV *) SvRV(sni_data);

    /* get count */
    ss->SNI_entries_number = (uint16) av_len(sni_array) + 1;
#ifdef MATRIX_DEBUG
    warn("  Got %d SNI entries", ss->SNI_entries_number);
#endif
    /* check limits */
    if (ss->SNI_entries_number > MAX_SNI_ENTRIES)
        croak("Not enough room to load all SNI entries %d > %d", ss->SNI_entries_number, MAX_SNI_ENTRIES);

    for (i = 0; i < ss->SNI_entries_number; i++) {
        /* alocate memory for each SNI structure */
        ss->SNI_entries[i] = (t_SNI_entry *) malloc( sizeof(t_SNI_entry));
        memset(ss->SNI_entries[i], 0, sizeof(t_SNI_entry));

        /* get one array at the time */
        sd_sv = *av_fetch(sni_array, i, 0);

        /* make sure we have an array reference */
        if (!(SvROK(sd_sv) && SvTYPE(SvRV(sd_sv)) == SVt_PVHV))
            croak("Expected elements of SNI data to be hash references");

        /* get per host SNI data */
        sd = (HV *) SvRV(sd_sv);

        /* element 0 - hostname - we need to copy this in our structure */
        if (hv_exists(sd, "hostname", strlen("hostname"))) {
            item_sv = *hv_fetch(sd, "hostname", strlen("hostname"), 0);
            if (!SvOK(item_sv))
                croak("Hostname not specified in SNI entry %d", i);

            item = (unsigned char *) SvPV(item_sv , item_len);
#ifdef MATRIX_DEBUG
            warn("  SNI entry %d Hostname = %s\n", i, item);
#endif
#ifdef WIN32
            if (item_len > 254) item_len = 254;
            memcpy(ss->SNI_entries[i]->hostname, item, item_len);
            ss->SNI_entries[i]->hostname[item_len] = 0;
            ss->SNI_entries[i]->hostnameLen = item_len;
#else
            regex_res = regcomp(&(ss->SNI_entries[i]->regex_hostname), item, REG_EXTENDED | REG_ICASE | REG_NOSUB);

            if (regex_res != 0) {
                regerror(regex_res, &(ss->SNI_entries[i]->regex_hostname), regex_error, 255);
                croak("Error compiling hostname regex %s: %s", item, regex_error);
            }
#endif
        } else
            croak("Hostname not specified in SNI entry %d", i);

        if (hv_exists(sd, "cert", strlen("cert")) && hv_exists(sd, "key", strlen("key"))) {
            cert_sv = *hv_fetch(sd, "cert", strlen("cert"), 0);
            key_sv = *hv_fetch(sd, "key", strlen("key"), 0);

            /* setup trusted CA certificate files if present */
            if (hv_exists(sd, "trustCA", strlen("trustCA"))) {
                trustedCA_sv = *hv_fetch(sd, "trustCA", strlen("trustCA"), 0);

                if (SvOK(trustedCA_sv)) {
                    trustedCA = (unsigned char *) SvPV_nolen(trustedCA_sv);
                }
            }

            if (SvOK(cert_sv) && SvOK(key_sv)) {
                cert = (unsigned char *) SvPV_nolen(cert_sv);
                key = (unsigned char *) SvPV_nolen(key_sv);
#ifdef MATRIX_DEBUG
                warn("  SNI entry %d cert %s; key %s", i, cert, key);
#endif
                add_obj();
                rc = matrixSslNewKeys(&(ss->SNI_entries[i]->keys), NULL);
                if (rc != PS_SUCCESS) {
                    del_obj();
                    croak("SNI matrixSslNewKeys failed %d", rc);
                }

                rc = matrixSslLoadRsaKeys(ss->SNI_entries[i]->keys, cert, key, NULL, trustedCA);
                if (rc != PS_SUCCESS)
                    croak("SNI matrixSslLoadRsaKeys failed %d; %s; %s", rc, cert, key);
            } else
                croak("Bad cert/key specified in SNI entry %d", i);
        } else if (hv_exists(sd, "ecc_cert", strlen("ecc_cert")) && hv_exists(sd, "ecc_key", strlen("ecc_key"))) {
            cert_sv = *hv_fetch(sd, "ecc_cert", strlen("ecc_cert"), 0);
            key_sv = *hv_fetch(sd, "ecc_key", strlen("ecc_key"), 0);

            if (SvOK(cert_sv) && SvOK(key_sv)) {
                cert = (unsigned char *) SvPV_nolen(cert_sv);
                key = (unsigned char *) SvPV_nolen(key_sv);
#ifdef MATRIX_DEBUG
                warn("  SNI entry %d ecc_cert %s; ecc_key %s", i, cert, key);
#endif
                add_obj();
                rc = matrixSslNewKeys(&(ss->SNI_entries[i]->keys), NULL);
                if (rc != PS_SUCCESS) {
                    del_obj();
                    croak("SNI matrixSslNewKeys failed %d", rc);
                }

                rc = matrixSslLoadEcKeys(ss->SNI_entries[i]->keys, cert, key, NULL, NULL);
                if (rc != PS_SUCCESS)
                    croak("SNI matrixSslLoadEcKeys failed %d; %s; %s", rc, cert, key);
            } else
                croak("Bad ECC cert/key specified in SNI entry %d", i);
        } else
            croak("Missing [ECC] cert/key specified in SNI entry %d", i);

        if (hv_exists(sd, "DH_param", strlen("DH_param"))) {
            item_sv = *hv_fetch(sd, "DH_param", strlen("DH_param"), 0);
            if (!SvOK(item_sv))
                croak("undef DH param in SNI entry %d", i);

            item = (unsigned char *) SvPV_nolen(item_sv);
#ifdef MATRIX_DEBUG
            warn("  SNI entry %d DH param %s", i, item);
#endif
            rc = matrixSslLoadDhParams(ss->SNI_entries[i]->keys, item);
            if (rc != PS_SUCCESS)
                croak("SNI matrixSslLoadDhParams failed %d; %s", rc, item);
        }

        if (hv_exists(sd, "session_ticket_keys", strlen("session_ticket_keys"))) {
            hitem = (HV *) SvRV(*hv_fetch(sd, "session_ticket_keys", strlen("session_ticket_keys"), 0));

            if (!(hv_exists(hitem, "id", strlen("id")) &&
                hv_exists(hitem, "encrypt_key", strlen("encrypt_key")) &&
                hv_exists(hitem, "hash_key", strlen("hash_key"))))
                croak("id/encrypt_key/hash_key missing in session ticket for SNI entry %i", i);

            item_sv = *hv_fetch(hitem, "id", strlen("id"), 0);
            if (!SvOK(item_sv))
                croak("undef session tickets id in SNI structure %d", i);

            item = (unsigned char *) SvPV(item_sv, item_len);
#ifdef MATRIX_DEBUG
            warn("  SNI entry %d session ticket ID %.16s", i, item);
#endif
            if (item_len > 16) item_len = 16;
            memcpy(stk_id, item, item_len);

            /* get encryption key */
            item_sv = *hv_fetch(hitem, "encrypt_key", strlen("encrypt_key"), 0);
            if (!SvOK(item_sv))
                croak("undef sesion tickets encryption key in SNI structure %d", i);

            item = (unsigned char *) SvPV(item_sv, item_len);
            if (!((item_len == 16) || (item_len == 32)))
                croak("size of the encryption key in SNI structure %d must be 16/32. Now it is %d", i, item_len);
#ifdef MATRIX_DEBUG
            warn("  SNI entry %d session ticket encryption key %.32s", i, item);
#endif
            memcpy(stk_ek, item, item_len);
            stk_ek_len = item_len;

            /* hash key */
            item_sv = *hv_fetch(hitem, "hash_key", strlen("hash_key"), 0);
            if (!SvOK(item_sv))
                croak("undef hash key in SNI structure %d", i);

            item = (unsigned char *) SvPV(item_sv, item_len);
            if (item_len != 32)
                croak("size of the hash key in SNI structure %d must be 16/32. Now it is %d", i, item_len);
#ifdef MATRIX_DEBUG
            warn("  SNI entry %d session ticket hash key %.32s", i, item);
#endif
            memcpy(stk_hk, item, item_len);
            stk_hk_len = item_len;

            rc = matrixSslLoadSessionTicketKeys(ss->SNI_entries[i]->keys, stk_id, stk_ek, stk_ek_len, stk_hk, stk_hk_len);
            if (rc != PS_SUCCESS)
                croak("SNI matrixSslLoadSessionTicketKeys failed %d; %s; %s", rc, cert, key);
        }

        /* OCSP staple */
        if (hv_exists(sd, "OCSP_staple", strlen("OCSP_staple"))) {
            item_sv = *hv_fetch(sd, "OCSP_staple", strlen("OCSP_staple"), 0);
            if (!SvOK(item_sv))
                croak("undef OCSP_staple specified in SNI entry %d", i);

            item = (unsigned char *) SvPV_nolen(item_sv);
#ifdef MATRIX_DEBUG
            warn("  SNI entry %d OCSP staple file %s", i, item);
#endif
            rc = psGetFileBuf(NULL, item, &buffer, &buffer_size);
            if (rc != PS_SUCCESS)
                croak("SNI psGetFileBuf failed %d; %s", rc, item);

            rc = matrixSslLoadOCSPResponse(ss->SNI_entries[i]->keys, buffer, buffer_size);

            if (buffer != NULL) psFreeNative(buffer);
            buffer = NULL;
            buffer_size = 0;

            if (rc != PS_SUCCESS)
                croak("SNI matrixSslLoadOCSPResponse failed %d; %s", rc, item);
        }

        /* SCT params */
        if (hv_exists(sd, "SCT_params", strlen("SCT_params"))) {
            item_sv = *hv_fetch(sd, "SCT_params", strlen("SCT_params"), 0);
            if (!SvOK(item_sv))
                croak("undef SCT_params specified in SNI entry %d", i);

            res = build_SCT_buffer(item_sv, &buffer, &buffer_size);
#ifdef MATRIX_DEBUG
            warn("  Read %d SCT files for SNI entry %d", res, i);
#endif
            if (res < 1)
                croak("Failed to load SCT_params for SNI entry %d", i);

            rc = matrixSslLoadSCTResponse(ss->SNI_entries[i]->keys, buffer, buffer_size);

            if (buffer != NULL) psFreeNative(buffer);
            buffer = NULL;
            buffer_size = 0;

            if (rc != PS_SUCCESS)
                croak("SNI matrixSslLoadSCTResponse failed %d", rc);
        }

        if (hv_exists(sd, "ALPN", strlen("ALPN"))) {
            item_sv = *hv_fetch(sd, "ALPN", strlen("ALPN"), 0);

            if (!(SvROK(item_sv) && SvTYPE(SvRV(item_sv)) == SVt_PVAV))
                croak("Expected default server ALPN param to be an array reference");

            ss->SNI_entries[i]->alpn = (p_ALPN_data) malloc(SZ_ALPN_DATA);
            memset(ss->SNI_entries[i]->alpn, 0, SZ_ALPN_DATA);

            aitem = (AV *) SvRV(item_sv);

            ss->SNI_entries[i]->alpn->protoCount = (short) av_len(aitem) + 1;
            if (ss->SNI_entries[i]->alpn->protoCount > MAX_PROTO_EXT) ss->SNI_entries[i]->alpn->protoCount = MAX_PROTO_EXT;

            for (j = 0; j < ss->SNI_entries[i]->alpn->protoCount; j++) {
                tmp_sv = *av_fetch(aitem, j, 0);
                item = (unsigned char *) SvPV(tmp_sv, item_len);

                ss->SNI_entries[i]->alpn->proto[j] = (unsigned char *) malloc(item_len);
                memcpy(ss->SNI_entries[i]->alpn->proto[j], item, item_len);
                ss->SNI_entries[i]->alpn->protoLen[j] = item_len;
            }
        }
    }

    RETVAL = server_index;

    OUTPUT:
    RETVAL


int sess_set_server_params(ssl, server_index, params = NULL)
    Crypt_MatrixSSL3_Sess *ssl;
    int server_index = SvOK(ST(1)) ? SvIV(ST(1)) : -1;
    SV *params;
    HV *hparams = NULL;
    HV *haux = NULL;
    AV *aaux = NULL;
    SV *item_sv = NULL;
    SV *tmp_sv = NULL;
    unsigned char *bufer = NULL;
    int32 buffer_size = 0;
    unsigned char *item = NULL;
    STRLEN item_len = 0;
    int i = 0, rc = PS_SUCCESS, ars = 0;
    p_SSL_server ss = NULL;
    p_SSL_data ssl_data = NULL;
    IV tmp = 0;

    CODE:
#ifdef MATRIX_DEBUG
    warn("set_server_params: index %d", server_index);
#endif
    if (server_index < 0)
        croak("Invalid SSL server index %d", server_index);

    if (server_index >= SSL_server_index)
        croak("Out of range SSL server index spcified: %d > %d", server_index, SSL_server_index - 1);

    /* set SSL server pointer */
    ss = SSL_servers[server_index];

    /* initialize default server structure */
    if (!(SvROK(params) && SvTYPE(SvRV(params)) == SVt_PVHV))
        croak("Expected default server params to be a hash reference");

    hparams = (HV *) SvRV(params);

    if (hv_exists(hparams, "keys", strlen("keys"))) {
        item_sv = *hv_fetch(hparams, "keys", strlen("keys"), 0);
        tmp = SvIV((SV*)SvRV(item_sv));
        ss->keys = INT2PTR(Crypt_MatrixSSL3_Keys *, tmp);
    }

    if (hv_exists(hparams, "ALPN", strlen("ALPN"))) {
        item_sv = *hv_fetch(hparams, "ALPN", strlen("ALPN"), 0);

        if (!(SvROK(item_sv) && SvTYPE(SvRV(item_sv)) == SVt_PVAV))
            croak("Expected default server ALPN param to be an array reference");

        ss->alpn = (p_ALPN_data) malloc(SZ_ALPN_DATA);
        memset(ss->alpn, 0, SZ_ALPN_DATA);

        aaux = (AV *) SvRV(item_sv);

        ss->alpn->protoCount = (short) av_len(aaux) + 1;
        if (ss->alpn->protoCount > MAX_PROTO_EXT) ss->alpn->protoCount = MAX_PROTO_EXT;
#ifdef MATRIX_DEBUG
        warn("Loading %d protocols for SSL (default) server %d", ss->alpn->protoCount, server_index);
#endif
        for (i = 0; i < ss->alpn->protoCount; i++) {
            tmp_sv = *av_fetch(aaux, i, 0);
            item = (unsigned char *) SvPV(tmp_sv, item_len);
#ifdef MATRIX_DEBUG
        warn("Adding protocol for SSL (default) server %d: %s", server_index, item);
#endif
            ss->alpn->proto[i] = (unsigned char *) malloc(item_len);
            memcpy(ss->alpn->proto[i], item, item_len);
            ss->alpn->protoLen[i] = item_len;
        }
    }
#ifdef MATRIX_DEBUG
        warn("Returning SSL (default) server index: %d", server_index);
#endif
    RETVAL = server_index;

    OUTPUT:
    RETVAL


int sess_set_callbacks(ssl, server_index, ssl_id)
    Crypt_MatrixSSL3_Sess *ssl;
    int server_index = SvOK(ST(1)) ? SvIV(ST(1)) : -1;
    int ssl_id = SvOK(ST(2)) ? SvIV(ST(2)) : -1;
    p_SSL_data ssl_data = NULL;
    p_SSL_server ss = NULL;

    CODE:
    /* check if server_index points to a valid SSL server structure */
    if (server_index < 0)
        croak("Invalid SSL server index %d", server_index);

    if (server_index >= SSL_server_index)
        croak("Requested SSL server index out of range %d > %d", server_index, SSL_server_index - 1);

    /* just set the callback and we're done */
#ifdef MATRIX_DEBUG
    warn("Setting up SNI/ALPN callbacks for SSL server %d, ssl_id = %d, %p", server_index, ssl_id, SSL_servers[server_index]);
#endif

    /* set out SSL session custom data */
    ssl_data = (p_SSL_data) ssl->userPtr;

    ssl_data->ssl_id = ssl_id;
    ssl_data->server_index = server_index;

    /* get the SSL server strcuture */
    ss = SSL_servers[server_index];

    /* test if any visrtual hosts are present */
    if (ss->SNI_entries_number > 0) {
      /* setup SNI callback */
      matrixSslRegisterSNICallback(ssl, SNI_callback);
      /* setup ALPN callback */
      matrixSslRegisterALPNCallback(ssl, ALPNCallbackXS);
    } else {
      /* no virtual hosts, setup ALPN callback only if server has defined protocols */
      if (ss->alpn != NULL) matrixSslRegisterALPNCallback(ssl, ALPNCallbackXS);
    }

    RETVAL = server_index;

    OUTPUT:
    RETVAL


void sess_DESTROY(ssl)
    Crypt_MatrixSSL3_Sess *ssl;
    SV *key = NULL;

    CODE:
    ENTER;
    SAVETMPS;

    /* delete callback from global hashes */
    key = sv_2mortal(newSViv(PTR2IV(ssl)));
    if(hv_exists_ent(certValidatorArg, key, 0))
        hv_delete_ent(certValidatorArg, key, G_DISCARD, 0);
    if(hv_exists_ent(extensionCbackArg, key, 0))
        hv_delete_ent(extensionCbackArg, key, G_DISCARD, 0);

    FREETMPS;
    LEAVE;

    if (((ssl_t *) ssl)->userPtr != NULL) free(((ssl_t *) ssl)->userPtr);
    matrixSslDeleteSession((ssl_t *) ssl);
    del_obj();


int sess_get_outdata(ssl, outBuf)
    Crypt_MatrixSSL3_Sess *ssl;
    SV *outBuf;
    unsigned char *buf = NULL;

    CODE:
    RETVAL = matrixSslGetOutdata((ssl_t *)ssl, &buf);
    if (RETVAL < 0)
        croak("matrixSslGetOutdata returns %d", RETVAL);
    /* append answer to the output */
    if (RETVAL > 0)
        sv_catpvn_mg(outBuf, (const char *) buf, RETVAL);

    OUTPUT:
    RETVAL


int sess_sent_data(ssl, bytes)
    Crypt_MatrixSSL3_Sess *ssl;
    int bytes;

    CODE:
    RETVAL = matrixSslSentData((ssl_t *)ssl, bytes);

    OUTPUT:
    RETVAL


int sess_received_data(ssl, inBuf, ptBuf)
    Crypt_MatrixSSL3_Sess *ssl;
    SV *inBuf;
    SV *ptBuf;
    unsigned char *readbuf = NULL;
    unsigned char *buf = NULL;
    STRLEN inbufsz = 0;
    unsigned int bufsz = 0;
    int32 readbufsz = 0;

    CODE:
    readbufsz = matrixSslGetReadbuf((ssl_t *)ssl, &readbuf);
    if (readbufsz < 0) {
        /* 0 isn't an error, but shouldn't happens anyway */
        /* when readbufsz == 0 the matrixSslReceivedData call below acts like a polling machanism
           useful for client which use false start */
        croak("matrixSslGetReadbuf returns %d", readbufsz);
    }

    buf = (unsigned char *) SvPV(inBuf, inbufsz);
    if((STRLEN) readbufsz > inbufsz)
        readbufsz = inbufsz;
    memcpy(readbuf, buf, readbufsz);
    /* remove from the input whatever got processed */
    sv_setpvn_mg(inBuf, (const char *) buf+readbufsz,  inbufsz-readbufsz);
    buf = NULL;

    RETVAL = matrixSslReceivedData((ssl_t *)ssl, readbufsz, &buf, (uint32 *) &bufsz);
    sv_setpvn_mg(ptBuf, (const char *) buf, (buf==NULL ? 0 : bufsz));

    OUTPUT:
    RETVAL


int sess_false_start_received_data(ssl, ptBuf)
    Crypt_MatrixSSL3_Sess *ssl;
    SV *ptBuf;
    unsigned char *buf = NULL;
    unsigned int bufsz = 0;

    CODE:
    RETVAL = matrixSslReceivedData((ssl_t *)ssl, 0, &buf, (uint32 *) &bufsz);
    if (RETVAL > 0) sv_setpvn_mg(ptBuf, (const char *) buf, (buf==NULL ? 0 : bufsz));

    OUTPUT:
    RETVAL


int sess_processed_data(ssl, ptBuf)
    Crypt_MatrixSSL3_Sess *ssl;
    SV *ptBuf;
    unsigned char *buf = NULL;
    unsigned int bufsz = 0;

    CODE:
    RETVAL = matrixSslProcessedData((ssl_t *)ssl, &buf, (uint32 *) &bufsz);
    sv_setpvn_mg(ptBuf, (const char *) buf, (buf==NULL ? 0 : bufsz));

    OUTPUT:
    RETVAL


int sess_encode_to_outdata(ssl, outBuf)
    Crypt_MatrixSSL3_Sess *ssl;
    SV *outBuf;
    unsigned char *buf = NULL;
    STRLEN bufsz = 0;

    CODE:
    buf = (unsigned char *) SvPV(outBuf, bufsz);
    RETVAL = matrixSslEncodeToOutdata((ssl_t *)ssl, buf, bufsz);

    OUTPUT:
    RETVAL


int sess_get_anon_status(ssl)
    Crypt_MatrixSSL3_Sess *ssl;
    int32 anon = 0;

    CODE:
    matrixSslGetAnonStatus((ssl_t *)ssl, &anon);
    RETVAL = (int) anon;

    OUTPUT:
    RETVAL


int sess_set_cipher_suite_enabled_status(ssl, cipherId, status);
    Crypt_MatrixSSL3_Sess *ssl;
    short cipherId;
    int status;

    CODE:
    RETVAL = matrixSslSetCipherSuiteEnabledStatus((ssl_t *)ssl, cipherId, status);

    OUTPUT:
    RETVAL


int sess_encode_closure_alert(ssl)
    Crypt_MatrixSSL3_Sess *ssl;

    CODE:
    RETVAL = matrixSslEncodeClosureAlert((ssl_t *)ssl);

    OUTPUT:
    RETVAL


int sess_encode_rehandshake(ssl, keys, certValidator, sessionOption, cipherSpecs)
    Crypt_MatrixSSL3_Sess *ssl;
    Crypt_MatrixSSL3_Keys *keys;
    SV *certValidator;
    int sessionOption;
    SV *cipherSpecs;
    SV *key = NULL;
    uint8_t cipherCount = 0, i = 0;
    AV *cipherSpecsArray = NULL;
    SV **item = NULL;

    PREINIT:
    uint16_t cipherSpecsBuf[64];

    INIT:
    if (SvROK(cipherSpecs) && SvTYPE(SvRV(cipherSpecs)) == SVt_PVAV) {
        cipherSpecsArray = (AV *) SvRV(cipherSpecs);

        cipherCount = (uint16) av_len(cipherSpecsArray) + 1;
        if (cipherCount > 64)
            croak("cipherSuites should not contain more than 64 ciphers");

        for (i = 0; i < cipherCount; i++) {
            item = av_fetch(cipherSpecsArray, i, 0);
            cipherSpecsBuf[i] = (uint32) SvIV(*item);
        }
    } else if (SvOK(cipherSpecs)) {
        croak("cipherSpecs should be undef or ARRAYREF");
    }

    CODE:
    RETVAL = matrixSslEncodeRehandshake((ssl_t *)ssl, (sslKeys_t *)keys,
                (SvOK(certValidator) ? appCertValidator : NULL),
                sessionOption, cipherSpecsBuf, cipherCount);

    ENTER;
    SAVETMPS;

    /* keep real callback in global hash: $certValidatorArg{ssl}=certValidator */
    key = sv_2mortal(newSViv(PTR2IV(ssl)));
    if(certValidatorArg==NULL)
        certValidatorArg = newHV();
    if(hv_exists_ent(certValidatorArg, key, 0))
        hv_delete_ent(certValidatorArg, key, G_DISCARD, 0); /* delete old callback */
    if(SvOK(certValidator))
        hv_store_ent(certValidatorArg, key, SvREFCNT_inc(SvRV(certValidator)), 0);

    FREETMPS;
    LEAVE;

    OUTPUT:
    RETVAL


MODULE = Crypt::MatrixSSL3  PACKAGE = Crypt::MatrixSSL3::HelloExtPtr    PREFIX = helloext_


Crypt_MatrixSSL3_HelloExt *helloext_new()
    INIT:
    tlsExtension_t *extension;
    int rc;

    CODE:
    add_obj();
    rc = matrixSslNewHelloExtension(&extension, NULL);
    if (rc != PS_SUCCESS) {
        del_obj();
        croak("%d", rc);
    }

    RETVAL = (Crypt_MatrixSSL3_HelloExt *)extension;

    OUTPUT:
    RETVAL


void helloext_DESTROY(extension)
    Crypt_MatrixSSL3_HelloExt *extension;

    CODE:
    matrixSslDeleteHelloExtension((tlsExtension_t *)extension);
    del_obj();


int helloext_load(extension, ext, extType)
    Crypt_MatrixSSL3_HelloExt *extension;
    SV *ext;
    int extType;
    unsigned char *extData = NULL;
    STRLEN extLen = 0;

    CODE:
    extData = (unsigned char *) SvPV(ext, extLen);
    RETVAL = matrixSslLoadHelloExtension((tlsExtension_t *)extension, extData, extLen, extType);

    OUTPUT:
    RETVAL
