#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "NSS.h"

#define BUFFER_SIZE 8192

static const char * config_dir = NULL;

static SV * PasswordHook = NULL;

char *
pkcs11_password_hook(PK11SlotInfo *info, PRBool retry, void *arg) {
    dSP;
    char * password = NULL, * tmp;
    SV * rv;
    I32 rcount;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(boolSV(retry)));
    XPUSHs(sv_2mortal(newSVsv((SV *) arg)));

    PUTBACK;

    rcount = call_sv(PasswordHook, G_SCALAR);

    SPAGAIN;

    if (rcount == 1) {
        rv = POPs;
        if (SvTRUE(rv) && SvPOK(rv)) {
            tmp = SvPV_nolen(rv);
            password = PORT_Strdup((char *) tmp);
        }
    }
    
    PUTBACK;
    FREETMPS;
    LEAVE;

    return password;
}

/* This is out ignore verification hook */
SECStatus
verify_certificate_ignore_hook(void * arg, PRFileDesc * fd, PRBool check_sig, PRBool is_server) {
    return SECSuccess;
}

/* This is called when we need to verify an incoming certificate */
SECStatus
verify_certificate_hook(void * arg, PRFileDesc * fd, PRBool check_sig, PRBool is_server) {    
    dSP;
    Net__NSS__SSL socket = (Net__NSS__SSL) arg;
    SV * rv, * self;
    IV tmp, rcount;
    
    SECStatus status = SECSuccess;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    /* Hack to prevent FREETMPS from closing socket */
    socket->do_not_free = TRUE;
    
    self = sv_newmortal();
	sv_setref_pv(self, "Net::NSS::SSL", (void *) socket);
	
    XPUSHs(self);
    XPUSHs(sv_2mortal(newSVsv(socket->client_certificate_hook_arg)));
    
    PUTBACK;

    rcount = call_sv(socket->client_certificate_hook, G_SCALAR);

    SPAGAIN;
        
    return status;
}

SECStatus
bad_certificate_hook(void * arg, PRFileDesc * fd) { 
    fprintf(stderr, "In bad_certificate_hook\n");
}

SECStatus
client_certificate_hook(void * arg, PRFileDesc * fd, CERTDistNames * ca_names, CERTCertificate ** target_cert, SECKEYPrivateKey ** target_key) {
    dSP;
    Net__NSS__SSL socket = (Net__NSS__SSL) arg;
    SV * rv, * self;
    IV tmp, rcount;
    
    SECStatus status = SECSuccess;
        
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* Hack to prevent FREETMPS from closing socket */
    socket->do_not_free = TRUE;
    
    self = sv_newmortal();
	sv_setref_pv(self, "Net::NSS::SSL", (void *) socket);
	
    XPUSHs(self);
    XPUSHs(sv_2mortal(newSVsv(socket->client_certificate_hook_arg)));

    PUTBACK;

    rcount = call_sv(socket->client_certificate_hook, G_ARRAY);

    SPAGAIN;

    *target_cert = NULL;
    *target_key = NULL;

    if (rcount == 2) {
        rv = POPs;
        if (SvTRUE(rv) && sv_derived_from(rv, "Crypt::NSS::PrivateKey")) {
            tmp = SvIV((SV *) SvRV(rv));
            *target_key = SECKEY_CopyPrivateKey(INT2PTR(Crypt__NSS__PrivateKey, tmp));
    	}
    	else {
            status = SECFailure;
    	}
    	
        rv = POPs;
        if (SvTRUE(rv) && sv_derived_from(rv, "Crypt::NSS::Certificate")) {
            tmp = SvIV((SV *) SvRV(rv));
            *target_cert = CERT_DupCertificate(INT2PTR(Crypt__NSS__Certificate, tmp));
    	}
    	else {
            status = SECFailure;
    	}
    }
    else {
        status = SECFailure;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    /* Hack to prevent FREETMPS from closing socket */
    socket->do_not_free = FALSE;
        
    return status;
}

static void
throw_exception_from_nspr_error(const char * desc) {
    PRInt32 len;
    char * tmpbuff;
    
    if ((len = PR_GetErrorTextLength())) {
        Newz(1, tmpbuff, len + 1, char);
        PR_GetErrorText(tmpbuff);
        croak("%s: %s (%d)", desc, tmpbuff, PR_GetError());
    }
    else {
        croak("%s: %d", desc, PR_GetError());
    }
}

static IV
get_argument_as_IV(HV *args, const char *key, IV default_value) {
    SV **value;

    value = hv_fetch(args, key, strlen(key), 0);
    
    if (value == NULL) {
        /* Failed to get key, return default */
        return default_value;
    }
    
    return SvIV(*value);
}

static PRBool
get_argument_as_PRBool(HV *args, const char *key, PRBool default_value) {
    SV **value;

    value = hv_fetch(args, key, strlen(key), 0);
    
    if (value == NULL) {
        /* Failed to get key, return default */
        return default_value;
    }
    
    return (PRBool) SvTRUE(*value);
}

MODULE = Crypt::NSS     PACKAGE = Crypt::NSS::PrivateKey

void
DESTROY(self)
    Crypt::NSS::PrivateKey self;
    CODE:
        if (self != NULL) {
            SECKEY_DestroyPrivateKey(self);
        }

MODULE = Crypt::NSS        PACKAGE = Net::NSS::SSL

Net::NSS::SSL
create_socket(pkg, type)
    const char * pkg;
    const char * type;
    PREINIT:
        NSS_SSL_Socket * socket;
    CODE:
        Newz(1, socket, 1, NSS_SSL_Socket);
        if (strEQ(type, "tcp")) {
            socket->fd = PR_NewTCPSocket();
        }
        else if (strEQ(type, "udp")) {
            socket->fd = PR_NewUDPSocket();
        }
        else {
            croak("Unknown socket type '%s'. Valid types are are 'tcp' and 'udp'", type);
        }

        if (socket->fd == NULL) {
            throw_exception_from_nspr_error("Failed to create new TCP socket");
        }        

        socket->is_connected = FALSE;
        RETVAL = socket;
    OUTPUT:
        RETVAL

void 
set_option(self, option, value)
    Net::NSS::SSL self;
    SV * option;
    I32 value;
    PREINIT:
        char * name;
        I32 num;
        PRSocketOptionData sock_opt;
    CODE:
        if (SvPOK(option)) {
            name = SvPV_nolen(option);
            if (strEQ(name, "KeepAlive")) {
                sock_opt.option = PR_SockOpt_Keepalive;
                sock_opt.value.keep_alive = value ? PR_TRUE : PR_FALSE;
            }
            else if (strEQ(name, "NoDelay")) {
                sock_opt.option = PR_SockOpt_NoDelay;
                sock_opt.value.no_delay = value ? PR_TRUE : PR_FALSE;
            }
            else if (strEQ(name, "Blocking")) {
                sock_opt.option = PR_SockOpt_Nonblocking;
                sock_opt.value.non_blocking = value ? PR_FALSE : PR_TRUE;
            }
            else {
                croak("Unknown option '%s'", option);
            }
            
            SET_SOCKET_OPTION(self->fd, sock_opt, form("Failed to set option '%s' on socket", option));
        }
        else if (SvIOK(option)) {
            EVALUATE_SEC_CALL(SSL_OptionSet(self->ssl_fd, SvIV(option), value), "Failed to set option")
        }

SV *
get_option(self, option)
    Net::NSS::SSL self;
    SV * option;
    PREINIT:
        char * name;
        I32 num;
        PRSocketOptionData sock_opt;
        PRBool on;
    CODE:
        if (SvPOK(option)) {
            name = SvPV_nolen(option);
            if (strEQ(name, "KeepAlive")) {
                sock_opt.option = PR_SockOpt_Keepalive;
                GET_SOCKET_OPTION(self->fd, sock_opt, option);
                RETVAL = boolSV(sock_opt.value.keep_alive ? TRUE : FALSE);
            }
            else if (strEQ(name, "NoDelay")) {
                sock_opt.option = PR_SockOpt_NoDelay;
                GET_SOCKET_OPTION(self->fd, sock_opt, option);
                RETVAL = boolSV(sock_opt.value.no_delay ? TRUE : FALSE);
            }
            else if (strEQ(name, "Blocking")) {
                sock_opt.option = PR_SockOpt_Nonblocking;
                GET_SOCKET_OPTION(self->fd, sock_opt, option);
                RETVAL = boolSV(sock_opt.value.non_blocking ? FALSE : TRUE);
            }
            else {
                croak("Unknown option '%s'", option);            
            }
        }
        else if (SvIOK(option)) {
            EVALUATE_SEC_CALL(SSL_OptionGet(self->ssl_fd, SvIV(option), &on), "Failed to get option")
            RETVAL = newSViv(on);
        }
    OUTPUT:
        RETVAL
        
void
set_verify_certificate_hook(self, hook)
    Net::NSS::SSL self;
    SV * hook;
    CODE:
        if (self->verify_certificate_hook != NULL) {
            SvREFCNT_dec(self->verify_certificate_hook);
        }
        if (SvPOK(hook) && strEQ(SvPV_nolen(hook), "built-in-ignore")) {
            EVALUATE_SEC_CALL(SSL_AuthCertificateHook(self->ssl_fd, verify_certificate_ignore_hook, NULL), "Failed to set auth certificate hook to ignore");
        }
        else if (SvTRUE(hook)) {
            if (self->verify_certificate_hook != NULL) {
                EVALUATE_SEC_CALL(SSL_AuthCertificateHook(self->ssl_fd, verify_certificate_hook, self), "Failed to set auth certificate hook");
            }
            self->verify_certificate_hook = SvREFCNT_inc(hook);
        }
        else {
            EVALUATE_SEC_CALL(SSL_AuthCertificateHook(self->ssl_fd, SSL_AuthCertificate, NULL), "Failed to set default auth certificate hook");
        }

void
set_bad_certificate_hook(self, hook)
    Net::NSS::SSL self;
    SV * hook;
    CODE:
        if (self->bad_certificate_hook != NULL) {
            SvREFCNT_dec(self->bad_certificate_hook);
        }
        if (SvTRUE(hook)) {
            if (self->bad_certificate_hook != NULL) {
                EVALUATE_SEC_CALL(SSL_BadCertHook(self->ssl_fd, bad_certificate_hook, self), "Failed to set bad certificate hook");
            }
            if (self->bad_certificate_hook == NULL) {
                self->bad_certificate_hook = newSVsv(hook);
            }
            else {
                sv_setsv(self->bad_certificate_hook, hook);
            }
        }
        else {
            EVALUATE_SEC_CALL(SSL_BadCertHook(self->ssl_fd, NULL, NULL), "Failed to set default bad certificate hook");
        }

void
set_client_certificate_hook(self, hook, data=NULL)
    Net::NSS::SSL self;
    SV * hook;
    SV * data;
    PREINIT:
        char * tmp;
        char * nickname = NULL;
    CODE:        
        if (self->client_certificate_hook_arg) {
            SvREFCNT_dec(self->client_certificate_hook_arg);
            self->client_certificate_hook_arg = NULL;
        }
        if (self->client_certificate_hook != NULL) {
            SvREFCNT_dec(self->client_certificate_hook);
        }
        if (SvPOK(hook) && strEQ(SvPV_nolen(hook), "built-in")) {
            if (data != NULL) {
                tmp = SvPV_nolen(data);
                nickname = PL_strdup(tmp);
            }
            SSL_GetClientAuthDataHook(self->ssl_fd, NSS_GetClientAuthData, NULL);
        }
        else if (SvTRUE(hook)) {
            SSL_GetClientAuthDataHook(self->ssl_fd, client_certificate_hook, self);
            self->client_certificate_hook = SvREFCNT_inc(hook);    
            if (data) {   
                self->client_certificate_hook_arg = SvREFCNT_inc(data);
            }
        }
        else {
            SSL_GetClientAuthDataHook(self->ssl_fd, NULL, NULL);
        }

void
set_pkcs11_pin_arg(self, arg)
    Net::NSS::SSL self;
    SV * arg;
    PREINIT:
        SV * pre_arg;
    CODE:
        pre_arg = (SV *) SSL_RevealPinArg(self->ssl_fd);
        if (pre_arg != NULL) {
            SvREFCNT_dec(pre_arg);
        }
        SSL_SetPKCS11PinArg(self->ssl_fd, (void *) SvREFCNT_inc(arg));

SV *
get_pkcs11_pin_arg(self)
    Net::NSS::SSL self;
    PREINIT:
        SV * arg;
    CODE:
        arg = (SV *) SSL_RevealPinArg(self->ssl_fd);
        if (arg == NULL) {
            XSRETURN_UNDEF;
        }
        RETVAL = SvREFCNT_inc(arg);
    OUTPUT:
        RETVAL

void
set_URL(self, hostname)
    Net::NSS::SSL self;
    const char * hostname;
    CODE:
        EVALUATE_SEC_CALL(SSL_SetURL(self->ssl_fd, hostname), "Failed to set url")

const char *
get_URL(self)
    Net::NSS::SSL self;
    PREINIT:
        char * domain;
    CODE:
        domain = SSL_RevealURL(self->ssl_fd);
        RETVAL = savepv(domain);
        PR_Free(domain);
    OUTPUT:
        RETVAL

void
remove_from_session_cache(self)
    Net::NSS::SSL self;
    CODE:
        if (SSL_InvalidateSession(self->ssl_fd) < 0) {
            throw_exception_from_nspr_error("Failed to invalidate session for socket");
        }


void
connect(self, hostname, port, timeout = PR_INTERVAL_NO_TIMEOUT)
    Net::NSS::SSL self;
    const char * hostname;
    I32 port;
    I32 timeout;
    PREINIT:
        PRNetAddr addr;
        PRHostEnt hostentry;
        char buffer[PR_NETDB_BUF_SIZE];
    CODE:
        EVALUATE_PR_CALL(PR_GetHostByName(hostname, buffer, sizeof(buffer), &hostentry), "Can't lookup host")
        if (PR_EnumerateHostEnt(0, &hostentry, port, &addr) < 0) {
            throw_exception_from_nspr_error("Failed to get IP from host entry");
        }
        EVALUATE_PR_CALL(PR_Connect(self->ssl_fd, &addr, PR_INTERVAL_NO_TIMEOUT), "Connection failed")        
        self->is_connected = TRUE;

void
bind(self, hostname, port)
    Net::NSS::SSL self;
    const char * hostname;
    I32 port;
    PREINIT:
        PRNetAddr addr;
        PRHostEnt hostentry;
        char buffer[PR_NETDB_BUF_SIZE];
    CODE:
        if (hostname != NULL) {
            EVALUATE_PR_CALL(PR_GetHostByName(hostname, buffer, sizeof(buffer), &hostentry), "Can't lookup host")
            if (PR_EnumerateHostEnt(0, &hostentry, port, &addr) < 0) {
                throw_exception_from_nspr_error("Failed to get IP from host entry");
            }
        }
        else {
            addr.inet.family = PR_AF_INET;
            addr.inet.ip = PR_htonl(PR_INADDR_ANY);
            addr.inet.port = port;
        }
        EVALUATE_PR_CALL(PR_Bind(self->fd, &addr), "Connection failed")

Net::NSS::SSL
accept(self, timeout = PR_INTERVAL_NO_TIMEOUT)
    Net::NSS::SSL self
    I32 timeout;
    PREINIT:
        NSS_SSL_Socket * new_socket;
        PRNetAddr addr;
        PRFileDesc * remote_fd = NULL;
    CODE:
        remote_fd = PR_Accept(self->fd, &addr, timeout);
        if (remote_fd == NULL) {
            throw_exception_from_nspr_error("Accept failed");
        }
        Newz(1, new_socket, 1, NSS_SSL_Socket);
        new_socket->fd = remote_fd;
        new_socket->ssl_fd = SSL_ImportFD(NULL, new_socket->fd);
        new_socket->is_connected = TRUE;
        new_socket->does_ssl = TRUE;
        RETVAL = new_socket;
    OUTPUT:
        RETVAL

void
listen(self, queue_length=10)
    Net::NSS::SSL self;
    I32 queue_length;
    CODE:
        EVALUATE_PR_CALL(PR_Listen(self->fd, queue_length), "Listen failed")

void
import_into_ssl_layer(self, proto=NULL)
    Net::NSS::SSL self;
    Net::NSS::SSL proto;
    PREINIT:
        PRFileDesc * proto_sock = NULL;
    CODE:
        if (proto != NULL) {
            proto_sock = proto->ssl_fd;
        }
        self->ssl_fd = (PRFileDesc *) SSL_ImportFD(proto_sock, self->fd);
        self->does_ssl = TRUE;

void
reset_handshake(self, as_server)
    Net::NSS::SSL self;
    bool as_server;
    CODE:
        EVALUATE_SEC_CALL(SSL_ResetHandshake(self->ssl_fd, as_server ? PR_TRUE : PR_FALSE), "Failed to reset handshake");
    
void
configure_as_server(self, cert, key)
    Net::NSS::SSL self;
    Crypt::NSS::Certificate cert;
    Crypt::NSS::PrivateKey key;
    PREINIT:
        SSLKEAType certKEA;
    CODE:
        certKEA = NSS_FindCertKEAType(cert);
        EVALUATE_SEC_CALL(SSL_ConfigSecureServer(self->ssl_fd, cert, key, certKEA), "Failed to configure server socket");
    
I32
available(self)
    Net::NSS::SSL self;
    CODE:
        RETVAL = PR_Available(self->ssl_fd);
    OUTPUT:
        RETVAL

void
_peeraddr(self)
    Net::NSS::SSL self;
    PREINIT:
        char * hostname;
        PRNetAddr addr;
    PPCODE:
        if (self->ssl_fd == NULL || !self->is_connected) {
            croak("Can't get peeraddr because we're not connected");
        }
        EVALUATE_PR_CALL(PR_GetPeerName(self->ssl_fd, &addr), "Failed to get peer addr")
        Newz(1, hostname, 16, char);
        if (PR_NetAddrToString(&addr, hostname, 16) != PR_SUCCESS) {
            Safefree(hostname);
            throw_exception_from_nspr_error("Failed to convert PRNetAddr to string");
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpv(hostname, 0)));
        PUSHs(sv_2mortal(newSViv(PR_ntohs(addr.inet.port))));
        Safefree(hostname);

void
_sockaddr(self)
    Net::NSS::SSL self;
    PREINIT:
        char * hostname;
        PRNetAddr addr;
    PPCODE:
        EVALUATE_PR_CALL(PR_GetSockName(self->ssl_fd, &addr), "Failed to get peer addr")
        Newz(1, hostname, 16, char);
        if (PR_NetAddrToString(&addr, hostname, 16) != PR_SUCCESS) {
            Safefree(hostname);
            throw_exception_from_nspr_error("Failed to convert PRNetAddr to string");
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpv(hostname, 0)));
        PUSHs(sv_2mortal(newSViv(PR_ntohs(addr.inet.port))));
        Safefree(hostname);
                
I32
keysize(self)
    Net::NSS::SSL self;
    PREINIT:
        int keysize;
    CODE:
        EVALUATE_SEC_CALL(SSL_SecurityStatus(self->ssl_fd, NULL, NULL, &keysize, NULL, NULL, NULL), 
                          "Failed to get session key length")
        RETVAL = keysize;
    OUTPUT:
        RETVAL

I32
secret_keysize(self)
    Net::NSS::SSL self;
    PREINIT:
        int secret_keysize;
    CODE:
        EVALUATE_SEC_CALL(SSL_SecurityStatus(self->ssl_fd, NULL, NULL, NULL, &secret_keysize, NULL, NULL), 
                         "Failed to get session secret key length")
        RETVAL = secret_keysize;
    OUTPUT:
        RETVAL

const char *
cipher(self)
    Net::NSS::SSL self;
    PREINIT:
        char *cipher;
    CODE:
        EVALUATE_SEC_CALL(SSL_SecurityStatus(self->ssl_fd, NULL, &cipher, NULL, NULL, NULL, NULL),
                                             "Failed to get session cipher")
        RETVAL = savepv(cipher);
        PR_Free(cipher);
    OUTPUT:
        RETVAL

const char *
issuer(self)
    Net::NSS::SSL self;
    PREINIT:
        char *issuer;
    CODE:
        EVALUATE_SEC_CALL(SSL_SecurityStatus(self->ssl_fd, NULL, NULL, NULL, NULL, &issuer, NULL),
                                             "Failed to get session issuer")
        RETVAL = savepv(issuer);
        PR_Free(issuer);
    OUTPUT:
        RETVAL

const char *
subject(self)
    Net::NSS::SSL self;
    PREINIT:
        char *subject;
    CODE:
        EVALUATE_SEC_CALL(SSL_SecurityStatus(self->ssl_fd, NULL, NULL, NULL, NULL, NULL, &subject),
                                             "Failed to get session subject")
        RETVAL = savepv(subject);
        PR_Free(subject);
    OUTPUT:
        RETVAL
    
I32
write(self, data, length = 0, offset = 0)
    Net::NSS::SSL self;
    SV * data;
    I32 length;
    I32 offset;
    PREINIT:
        char *buf;
        PRInt32 bytes_written = 0;
        STRLEN blen;
    CODE:
        buf = SvPVx(data, blen);
        length = length > 0 ? length : blen;
        if (offset < 0) {
            if (-offset > blen) {
                croak("Offset outside string");
            }
        }
        else if (offset >= blen && blen > 0) {
            croak("Offset outside string");
        }
        if (length > blen - offset) {
            length = blen - offset;
        }
        bytes_written = PR_Write(self->ssl_fd, buf + offset, length);
        if (bytes_written < 0) {
            throw_exception_from_nspr_error("Failed to write to socket");
        }
        RETVAL = bytes_written;
    OUTPUT:
        RETVAL
        
I32
read(self, buf, length = BUFFER_SIZE, offset = 0)
    Net::NSS::SSL self;
    I32 length;
    I32 offset;
    PREINIT:
        char *buf;
        PRInt32 bytes_read;
        STRLEN len;
    INPUT:
        SV * buf_sv = ST(1);
    CODE:
        if (!SvPOK(buf_sv)) {
            sv_setpv(buf_sv, "");
        }
        buf = SvPV_force(buf_sv, len);
        if (offset < 0) {
            if (-offset > len) {
                croak("Offset outside string");
            }
            offset += len;
        }
        if (offset > len) {
            Newz(1, buf, offset - len, char);
            sv_catpvn(buf_sv, buf, offset - len);
        }
        buf = SvGROW(buf_sv, offset + length + 1);
        bytes_read = PR_Read(self->ssl_fd, buf + offset, length);
        if (bytes_read >= 0) {
            SvCUR_set(buf_sv, offset + bytes_read);
            buf[offset + bytes_read] = '\0';
        }
        else {
            throw_exception_from_nspr_error("Failed to read from socket");
        }
        RETVAL = bytes_read;
    OUTPUT:
        RETVAL
        
void
close(self)
    Net::NSS::SSL self;
    CODE:
        if (self->ssl_fd != NULL) {
            EVALUATE_PR_CALL(PR_Close(self->ssl_fd), "Failed to close socket")
            self->ssl_fd = NULL;
            self->is_connected = PR_FALSE;
        }        
    
void
DESTROY(self)
    Net::NSS::SSL self;
    PREINIT:
        SV * pin_arg;
    CODE:
        /* Hack that prevents tmp stuff to close this */
        if (self->do_not_free)
            return;
            
        if (self->ssl_fd) {
            pin_arg = (SV *) SSL_RevealPinArg(self->ssl_fd);
            if (pin_arg != NULL) {
                SvREFCNT_dec(pin_arg);
            }
        }
        if (self->ssl_fd != NULL) {
            PR_Close(self->ssl_fd);
        }        
        if (self->client_certificate_hook_arg) {
            SvREFCNT_dec(self->client_certificate_hook_arg);
        }
        if (self->client_certificate_hook) {
            SvREFCNT_dec(self->client_certificate_hook);
        }
        Safefree(self);
        
Crypt::NSS::Certificate
peer_certificate(self)
    Net::NSS::SSL self;
    PREINIT:
        CERTCertificate * cert;
    CODE:
        cert = SSL_PeerCertificate(self->ssl_fd);
        if (cert == NULL) {
            XSRETURN_UNDEF;
        }
        RETVAL = cert;
    OUTPUT:
        RETVAL

bool
is_connected(self)
    Net::NSS::SSL self;
    CODE:
        RETVAL = self->is_connected;
    OUTPUT:
        RETVAL

bool
does_ssl(self)
    Net::NSS::SSL self;
    CODE:
        RETVAL = self->ssl_fd != 0 ? TRUE : FALSE;
    OUTPUT:
        RETVAL

MODULE = Crypt::NSS     PACKAGE = Crypt::NSS::Certificate

Crypt::NSS::Certificate
from_base64_DER(pkg, data)
    const char * pkg;
    const char * data;
    CODE:
        RETVAL = CERT_ConvertAndDecodeCertificate((char *) data);
        if (RETVAL == NULL) {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

bool
verify_hostname(self, hostname)
    Crypt::NSS::Certificate self;
    const char * hostname;
    CODE:
        RETVAL = TRUE;
        if (CERT_VerifyCertName(self, hostname) != SECSuccess) {
            if (PR_GetError() == SSL_ERROR_BAD_CERT_DOMAIN) {
                RETVAL = FALSE;
            }
            else {
                throw_exception_from_nspr_error("Failed to verify hostname");
            }
        }
    OUTPUT:
        RETVAL

I32
get_validity_for_datetime(self, year, month, mday, hour = 0, min = 0, sec = 0, usec = 0)
    Crypt::NSS::Certificate self;
    I32 year;
    I32 month;
    I32 mday;
    I32 hour;
    I32 min;
    I32 sec;
    I32 usec;
    PREINIT:
        PRExplodedTime ts; 
        PRTime t;
        SECCertTimeValidity v;
    CODE:
        ts.tm_usec = usec;
        ts.tm_sec = sec;
        ts.tm_min = min;
        ts.tm_hour = hour;
        ts.tm_mday = mday;
        ts.tm_month = month;
        ts.tm_year = year;
        ts.tm_params.tp_gmt_offset = 0;
        ts.tm_params.tp_dst_offset = 0;
        t = PR_ImplodeTime(&ts);
        v = CERT_CheckCertValidTimes(self, t, PR_TRUE);
        RETVAL = v == secCertTimeValid ? 0 :
                 v == secCertTimeExpired ? -1 :
                 v == secCertTimeNotValidYet ? 1 : v;
    OUTPUT:
        RETVAL

Crypt::NSS::PublicKey
public_key(self)
    Crypt::NSS::Certificate self;
    CODE:
        RETVAL = CERT_ExtractPublicKey(self);
        if (RETVAL == NULL) {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

const char *
subject(self)
    Crypt::NSS::Certificate self;
    CODE:
        RETVAL = savepv(self->subjectName);
    OUTPUT: 
        RETVAL

const char *
issuer(self)
    Crypt::NSS::Certificate self;
    CODE:
        RETVAL = savepv(self->issuerName);
    OUTPUT: 
        RETVAL
    
const char *
email_address(self)
    Crypt::NSS::Certificate self;
    CODE:
        RETVAL = savepv(self->emailAddr);
    OUTPUT: 
        RETVAL

Crypt::NSS::Certificate
clone(self)
    Crypt::NSS::Certificate self;
    CODE:
        RETVAL = CERT_DupCertificate(self);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    Crypt::NSS::Certificate self;
    CODE:
        if (self != NULL) {
            CERT_DestroyCertificate(self);
        }


MODULE = Crypt::NSS     PACKAGE = Crypt::NSS::PKCS11

void
set_password_hook(pkg, hook)
    const char * pkg;
    SV * hook;
    CODE:
        if (PasswordHook != NULL) {
            SvREFCNT_dec(PasswordHook);
        }
        PasswordHook = SvREFCNT_inc(hook);

Crypt::NSS::Certificate
find_cert_by_nickname(pkg, nickname, pin_arg=&PL_sv_undef)
    const char * pkg;
    const char * nickname;
    SV * pin_arg;
    PREINIT:
        CERTCertificate * cert;
    CODE:
        cert = PK11_FindCertFromNickname(nickname, pin_arg);
        if (cert == NULL) {
            XSRETURN_UNDEF;
        }
        RETVAL = cert;
    OUTPUT:
        RETVAL

Crypt::NSS::PrivateKey
find_key_by_any_cert(pkg, cert, pin_arg)
    const char * pkg;
    Crypt::NSS::Certificate cert;
    SV * pin_arg;
    PREINIT:
        SECKEYPrivateKey * key;
    CODE:
        key = PK11_FindKeyByAnyCert(cert, pin_arg);
        if (key == NULL) {
            XSRETURN_UNDEF;
        }
        RETVAL = key;
    OUTPUT:
        RETVAL
      
MODULE = Crypt::NSS     PACKAGE = Crypt::NSS::PKCS11::Slot

const char *
slot_name(self)
    Crypt::NSS::PKCS11::Slot self;
    PREINIT:
        char *name;
    CODE:
        name = PK11_GetSlotName(self);
        RETVAL = savepv(name);
        PR_Free(name);
    OUTPUT:
        RETVAL
        
const char *
token_name(self)
    Crypt::NSS::PKCS11::Slot self;
    PREINIT:
        char *name;
    CODE:
        name = PK11_GetTokenName(self);
        RETVAL = savepv(name);
        PR_Free(name);
    OUTPUT:
        RETVAL

bool
is_hardware(self)
    Crypt::NSS::PKCS11::Slot self;
    CODE:
        RETVAL = PK11_IsHW(self) ? TRUE : FALSE;
    OUTPUT:
        RETVAL

bool
is_present(self)
    Crypt::NSS::PKCS11::Slot self;
    CODE:
        RETVAL = PK11_IsPresent(self) ? TRUE : FALSE;
    OUTPUT:
        RETVAL

bool
is_readonly(self)
    Crypt::NSS::PKCS11::Slot self;
    CODE:
        RETVAL = PK11_IsReadOnly(self) ? TRUE : FALSE;
    OUTPUT:
        RETVAL

MODULE = Crypt::NSS        PACKAGE = Crypt::NSS::SSL

void
set_option(pkg, option, on)
    const char * pkg;
    PRInt32 option;
    PRBool  on;
    CODE:
        EVALUATE_SEC_CALL(SSL_OptionSetDefault(option, on), "Failed to set option default")

PRBool
get_option(pkg, option)
    const char * pkg;
    PRInt32 option;
    PREINIT:
        PRBool on;
    CODE:
        EVALUATE_SEC_CALL(SSL_OptionGetDefault(option, &on), "Failed to get option default")
        RETVAL = on;
    OUTPUT:
        RETVAL

void
set_cipher(pkg, cipher, on)
    const char * pkg;
    PRInt32 cipher;
    PRBool  on;
    CODE:
        EVALUATE_SEC_CALL(SSL_CipherPrefSetDefault(cipher, on), "Failed to set cipher default")

PRBool
get_cipher(pkg, cipher)
    const char * pkg;
    PRInt32 cipher;
    PREINIT:
        PRBool on;
    CODE:
        EVALUATE_SEC_CALL(SSL_CipherPrefGetDefault(cipher, &on), "Failed to get cipher default")
        RETVAL = on;
    OUTPUT:
        RETVAL

AV *
_get_implemented_cipher_ids(pkg)
    const char * pkg;
    PREINIT:
        AV *ciphers = newAV();
        I32 i;
    CODE:
        for (i = 0; i < SSL_NumImplementedCiphers; i++) {
            av_push(ciphers, newSViv(SSL_ImplementedCiphers[i]));
        }
        RETVAL = ciphers;
    OUTPUT:
        RETVAL
        
void
set_cipher_suite(pkg, suite)
    const char * pkg;
    const char * suite;
    PREINIT:
        SECStatus status;
    CODE:
        if (strEQ(suite, "US") || strEQ(suite, "Domestic")) {
            status = NSS_SetDomesticPolicy();
        }
        else if (strEQ(suite, "France")) {
            status = NSS_SetFrancePolicy();
        }
        else if (strEQ(suite, "International") || strEQ(suite, "Export")) {
            status = NSS_SetExportPolicy();
        }
        else {
            croak("No cipher suite for '%s' exists", suite);
        }
        
        if (status != SECSuccess) {
            throw_exception_from_nspr_error("Failed to set cipher suite");
        }
        
void
clear_session_cache(pkg)
    const char * pkg;
    CODE:
        SSL_ClearSessionCache();

void
config_server_session_cache(pkg, args)
    const char * pkg;
    HV * args;
    PREINIT:
        int maxCacheEntries = 0;
        PRInt32 ssl2_timeout = 100;
        PRInt32 ssl3_timeout = 86400;
        const char *data_dir = NULL;
        bool shared = FALSE;
        SV **value;
    CODE:
        if ((value = hv_fetch(args, "max_cache_entries", 17, 0)) != NULL) {
            maxCacheEntries = SvIV(*value);
        }
        if ((value = hv_fetch(args, "ssl2_timeout", 12, 0)) != NULL) {
            ssl2_timeout = SvIV(*value);
        }
        if ((value = hv_fetch(args, "ssl3_timeout", 12, 0)) != NULL) {
            ssl3_timeout = SvIV(*value);
        }
        if ((value = hv_fetch(args, "data_dir", 8, 0)) != NULL) {
            data_dir = SvPV_nolen(*value);
        }
        if ((value = hv_fetch(args, "shared", 6, 0)) != NULL) {
            shared = SvTRUE(*value);
        }
        if (!shared) {
            EVALUATE_SEC_CALL(SSL_ConfigServerSessionIDCache(maxCacheEntries, ssl2_timeout, ssl3_timeout, data_dir),
                                                             "Failed to config server session cache")
        }
        else {
            EVALUATE_SEC_CALL(SSL_ConfigMPServerSIDCache(maxCacheEntries, ssl2_timeout, ssl3_timeout, data_dir),
                                                         "Failed to config shared server session cache")
        }

MODULE = Crypt::NSS		PACKAGE = Crypt::NSS		
PROTOTYPES: DISABLE

const char *
config_dir(pkg)
    const char * pkg;
    CODE:
        RETVAL = savepv(config_dir);
    OUTPUT:
        RETVAL

bool
set_config_dir(pkg, dir)
    const char * pkg;
    const char * dir;
    CODE:
        if (!NSS_IsInitialized()) {
            config_dir = dir;
            RETVAL = TRUE;
        }
        else
            RETVAL = FALSE;
    OUTPUT:
        RETVAL

SECStatus
initialize(pkg)
    const char * pkg;
    CODE:
        if (!NSS_IsInitialized()) {
            RETVAL = NSS_Init(config_dir);
            PK11_SetPasswordFunc(pkcs11_password_hook);
        }
        else
            RETVAL = SECFailure;
    OUTPUT:
        RETVAL

bool
is_initialized(pkg)
    const char * pkg;
    CODE:
        RETVAL = (bool) NSS_IsInitialized();
    OUTPUT:
        RETVAL

void
shutdown(pkg)
    const char * pkg;
    CODE:
        NSS_Shutdown();
        
BOOT:
    config_dir = ".";