#ifndef CHANDRA_SOCKET_COMMON_H
#define CHANDRA_SOCKET_COMMON_H

/*
 * chandra_socket_common.h — Shared helpers for Hub and Client socket code.
 *
 * Small utility functions that eliminate repetition across
 * chandra_socket_hub.h and chandra_socket_client.h.
 */

#include <fcntl.h>

#ifndef SOCK_STREAM
#define SOCK_STREAM 1
#endif

/* ---- Call a void method on an SV with no extra args ---- */

static void
_sock_call_void(pTHX_ SV *obj, const char *method)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(obj);
    PUTBACK;
    call_method(method, G_DISCARD);
    FREETMPS; LEAVE;
}

/* ---- $obj->blocking(0) ---- */

static void
_sock_set_nonblocking(pTHX_ SV *obj)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(obj);
    XPUSHs(sv_2mortal(newSViv(0)));
    PUTBACK;
    call_method("blocking", G_DISCARD);
    FREETMPS; LEAVE;
}

/* ---- $obj->fileno  (returns IV, -1 on failure) ---- */

static IV
_sock_fileno(pTHX_ SV *obj)
{
    dSP;
    int count;
    IV result = -1;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(obj);
    PUTBACK;
    count = call_method("fileno", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *tmp = POPs; result = SvIV(tmp); }
    PUTBACK;
    FREETMPS; LEAVE;
    return result;
}

/* ---- $obj->is_connected  (returns int 0/1) ---- */

static int
_sock_is_connected(pTHX_ SV *obj)
{
    dSP;
    int count;
    int result = 0;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(obj);
    PUTBACK;
    count = call_method("is_connected", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *tmp = POPs; result = SvIV(tmp); }
    PUTBACK;
    FREETMPS; LEAVE;
    return result;
}

/* ---- $select->add($fh) ---- */

static void
_sock_select_add(pTHX_ SV *select, SV *fh)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(select);
    XPUSHs(fh);
    PUTBACK;
    call_method("add", G_DISCARD);
    FREETMPS; LEAVE;
}

/* ---- $select->remove($fh) ---- */

static void
_sock_select_remove(pTHX_ SV *select, SV *fh)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(select);
    XPUSHs(fh);
    PUTBACK;
    call_method("remove", G_DISCARD);
    FREETMPS; LEAVE;
}

/* ---- $conn->recv  (returns array of mortal SVs; caller must free) ---- */

static void
_sock_recv_messages(pTHX_ SV *conn, SV ***out_svs, int *out_count)
{
    dSP;
    int count, i;
    *out_svs = NULL;
    *out_count = 0;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(conn);
    PUTBACK;
    count = call_method("recv", G_ARRAY);
    SPAGAIN;
    if (count > 0) {
        *out_count = count;
        Newx(*out_svs, count, SV *);
        for (i = count - 1; i >= 0; i--)
            (*out_svs)[i] = newSVsv(POPs);
    }
    PUTBACK;
    FREETMPS; LEAVE;
}

/* ---- Free an array of SVs allocated by _sock_recv_messages ---- */

static void
_sock_free_sv_array(pTHX_ SV **svs, int count)
{
    if (svs) {
        int i;
        for (i = 0; i < count; i++)
            SvREFCNT_dec(svs[i]);
        Safefree(svs);
    }
}

/* ---- Resolve runtime directory: $ENV{XDG_RUNTIME_DIR} || File::Spec->tmpdir ---- */

static SV *
_sock_runtime_dir(pTHX)
{
    SV **env_svp;
    HV *env_hv = get_hv("ENV", 0);
    if (env_hv &&
        (env_svp = hv_fetchs(env_hv, "XDG_RUNTIME_DIR", 0)) &&
        SvOK(*env_svp)) {
        return newSVsv(*env_svp);
    } else {
        dSP;
        int count;
        SV *result;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("File::Spec")));
        PUTBACK;
        count = call_method("tmpdir", G_SCALAR);
        SPAGAIN;
        result = (count > 0) ? newSVsv(POPs) : newSVpvs("/tmp");
        PUTBACK;
        FREETMPS; LEAVE;
        return result;
    }
}

/* ---- File::Spec->catfile($dir, $filename)  (consumes dir_sv) ---- */

static SV *
_sock_catfile(pTHX_ SV *dir_sv, SV *filename_sv)
{
    dSP;
    int count;
    SV *result;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("File::Spec")));
    XPUSHs(sv_2mortal(dir_sv));
    XPUSHs(sv_2mortal(filename_sv));
    PUTBACK;
    count = call_method("catfile", G_SCALAR);
    SPAGAIN;
    result = (count > 0) ? newSVsv(POPs) : newSVpvs("");
    PUTBACK;
    FREETMPS; LEAVE;
    return result;
}

/* ---- Build a socket path: catfile(runtime_dir, "chandra-$name.sock") ---- */

static SV *
_sock_build_path(pTHX_ const char *name)
{
    SV *dir = _sock_runtime_dir(aTHX);
    SV *filename = newSVpvf("chandra-%s.sock", name);
    return _sock_catfile(aTHX_ dir, filename);
}

/* ---- Create IO::Socket::UNIX (client Peer or server Local+Listen) ---- */

static SV *
_sock_unix_connect(pTHX_ SV *path_sv)
{
    dSP;
    int count;
    SV *sock = NULL;
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Socket::UNIX"), NULL);
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("IO::Socket::UNIX")));
    XPUSHs(sv_2mortal(newSVpvs("Peer")));
    XPUSHs(path_sv);
    XPUSHs(sv_2mortal(newSVpvs("Type")));
    XPUSHs(sv_2mortal(newSViv(SOCK_STREAM)));
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
    PUTBACK;
    FREETMPS; LEAVE;
    return sock;
}

static SV *
_sock_unix_listen(pTHX_ SV *path_sv)
{
    dSP;
    int count;
    SV *sock = NULL;
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Socket::UNIX"), NULL);
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("IO::Socket::UNIX")));
    XPUSHs(sv_2mortal(newSVpvs("Local")));
    XPUSHs(path_sv);
    XPUSHs(sv_2mortal(newSVpvs("Type")));
    XPUSHs(sv_2mortal(newSViv(SOCK_STREAM)));
    XPUSHs(sv_2mortal(newSVpvs("Listen")));
    XPUSHs(sv_2mortal(newSViv(16)));
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
    PUTBACK;
    FREETMPS; LEAVE;
    return sock;
}

/* ---- Create IO::Socket::INET (client or server) ---- */

static SV *
_sock_tcp_connect(pTHX_ SV *host_sv, SV *port_sv)
{
    dSP;
    int count;
    SV *sock = NULL;
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Socket::INET"), NULL);
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("IO::Socket::INET")));
    XPUSHs(sv_2mortal(newSVpvs("PeerHost")));
    XPUSHs(host_sv);
    XPUSHs(sv_2mortal(newSVpvs("PeerPort")));
    XPUSHs(port_sv);
    XPUSHs(sv_2mortal(newSVpvs("Proto")));
    XPUSHs(sv_2mortal(newSVpvs("tcp")));
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
    PUTBACK;
    FREETMPS; LEAVE;
    return sock;
}

static SV *
_sock_tcp_listen(pTHX_ SV *host_sv, SV *port_sv)
{
    dSP;
    int count;
    SV *sock = NULL;
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Socket::INET"), NULL);
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("IO::Socket::INET")));
    XPUSHs(sv_2mortal(newSVpvs("LocalHost")));
    XPUSHs(host_sv);
    XPUSHs(sv_2mortal(newSVpvs("LocalPort")));
    XPUSHs(port_sv);
    XPUSHs(sv_2mortal(newSVpvs("Proto")));
    XPUSHs(sv_2mortal(newSVpvs("tcp")));
    XPUSHs(sv_2mortal(newSVpvs("Listen")));
    XPUSHs(sv_2mortal(newSViv(16)));
    XPUSHs(sv_2mortal(newSVpvs("ReuseAddr")));
    XPUSHs(sv_2mortal(newSViv(1)));
    XPUSHs(sv_2mortal(newSVpvs("Blocking")));
    XPUSHs(sv_2mortal(newSViv(0)));
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
    PUTBACK;
    FREETMPS; LEAVE;
    return sock;
}

/* ---- Create IO::Socket::SSL (client or server) ---- */

static SV *
_sock_tls_connect(pTHX_ SV *host_sv, SV *port_sv, SV *tls_ca_sv)
{
    dSP;
    int count;
    SV *sock = NULL;
    SV *verify_mode;

    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Socket::SSL"), NULL);

    /* Get verify mode constant */
    {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = call_pv(
            (tls_ca_sv && SvOK(tls_ca_sv))
                ? "IO::Socket::SSL::SSL_VERIFY_PEER"
                : "IO::Socket::SSL::SSL_VERIFY_NONE",
            G_SCALAR);
        SPAGAIN;
        verify_mode = (count > 0) ? newSVsv(POPs) : newSViv(0);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("IO::Socket::SSL")));
        XPUSHs(sv_2mortal(newSVpvs("PeerHost")));
        XPUSHs(host_sv);
        XPUSHs(sv_2mortal(newSVpvs("PeerPort")));
        XPUSHs(port_sv);
        XPUSHs(sv_2mortal(newSVpvs("SSL_verify_mode")));
        XPUSHs(sv_2mortal(verify_mode));
        if (tls_ca_sv && SvOK(tls_ca_sv)) {
            XPUSHs(sv_2mortal(newSVpvs("SSL_ca_file")));
            XPUSHs(tls_ca_sv);
        }
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
        PUTBACK;
        FREETMPS; LEAVE;
    }
    return sock;
}

static SV *
_sock_tls_listen(pTHX_ SV *host_sv, SV *port_sv,
                 SV *cert_sv, SV *key_sv)
{
    dSP;
    int count;
    SV *sock = NULL;

    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Socket::SSL"), NULL);

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("IO::Socket::SSL")));
    XPUSHs(sv_2mortal(newSVpvs("LocalHost")));
    XPUSHs(host_sv);
    XPUSHs(sv_2mortal(newSVpvs("LocalPort")));
    XPUSHs(port_sv);
    XPUSHs(sv_2mortal(newSVpvs("Proto")));
    XPUSHs(sv_2mortal(newSVpvs("tcp")));
    XPUSHs(sv_2mortal(newSVpvs("Listen")));
    XPUSHs(sv_2mortal(newSViv(16)));
    XPUSHs(sv_2mortal(newSVpvs("ReuseAddr")));
    XPUSHs(sv_2mortal(newSViv(1)));
    XPUSHs(sv_2mortal(newSVpvs("SSL_cert_file")));
    XPUSHs(cert_sv);
    XPUSHs(sv_2mortal(newSVpvs("SSL_key_file")));
    XPUSHs(key_sv);
    XPUSHs(sv_2mortal(newSVpvs("SSL_server")));
    XPUSHs(sv_2mortal(newSViv(1)));
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
    PUTBACK;
    FREETMPS; LEAVE;
    return sock;
}

/* ---- $listener->accept ---- */

static SV *
_sock_accept(pTHX_ SV *listener)
{
    dSP;
    int count;
    SV *sock = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(listener);
    PUTBACK;
    count = call_method("accept", G_SCALAR);
    SPAGAIN;
    if (count > 0) { SV *s = POPs; if (SvOK(s)) sock = newSVsv(s); }
    PUTBACK;
    FREETMPS; LEAVE;
    return sock;
}

/* ---- Chandra::Socket::Connection->new(socket => $sock, name => $name) ---- */

static SV *
_sock_connection_new(pTHX_ SV *sock, SV *name_sv)
{
    dSP;
    int count;
    SV *conn = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Chandra::Socket::Connection")));
    XPUSHs(sv_2mortal(newSVpvs("socket")));
    XPUSHs(sock);
    if (name_sv) {
        XPUSHs(sv_2mortal(newSVpvs("name")));
        XPUSHs(name_sv);
    }
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count > 0) conn = newSVsv(POPs);
    PUTBACK;
    FREETMPS; LEAVE;
    return conn;
}

/* ---- $conn->send($channel, $data_ref) ---- */

static void
_sock_conn_send(pTHX_ SV *conn, const char *channel, SV *data)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(conn);
    XPUSHs(sv_2mortal(newSVpv(channel, 0)));
    XPUSHs(data);
    PUTBACK;
    call_method("send", G_DISCARD);
    FREETMPS; LEAVE;
}

/* ---- $select->can_read(0) → array of SVs (caller must free) ---- */

static void
_sock_can_read(pTHX_ SV *select, SV ***out_svs, int *out_count)
{
    dSP;
    int count, i;
    *out_svs = NULL;
    *out_count = 0;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(select);
    XPUSHs(sv_2mortal(newSViv(0)));
    PUTBACK;
    count = call_method("can_read", G_ARRAY);
    SPAGAIN;
    if (count > 0) {
        *out_count = count;
        Newx(*out_svs, count, SV *);
        for (i = count - 1; i >= 0; i--)
            (*out_svs)[i] = newSVsv(POPs);
    }
    PUTBACK;
    FREETMPS; LEAVE;
}

/* ---- Dispatch a callback: call_sv(cb, data) ---- */

static void
_sock_dispatch_cb(pTHX_ SV *cb, SV *data)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(data ? data : &PL_sv_undef);
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS; LEAVE;
}

/* ---- Read a token file into a buffer (C-level I/O) ---- */

static SV *
_sock_read_token_file(pTHX_ const char *path)
{
    char token_path[4096];
    int fd;
    my_snprintf(token_path, sizeof(token_path), "%s.token", path);
    fd = open(token_path, O_RDONLY);
    if (fd >= 0) {
        char buf[256];
        ssize_t n = read(fd, buf, sizeof(buf) - 1);
        close(fd);
        if (n > 0)
            return newSVpvn(buf, n);
    }
    return NULL;
}

/* ---- Write a token file (C-level I/O) ---- */

static void
_sock_write_token_file(const char *path, const char *token, STRLEN tlen)
{
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd >= 0) {
        ssize_t n = write(fd, token, tlen);
        (void)n;
        close(fd);
    }
}

#endif /* CHANDRA_SOCKET_COMMON_H */
