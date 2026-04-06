MODULE = Data::Buffer::Shared    PACKAGE = Data::Buffer::Shared::U64
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV capacity)
    CODE:
        char errbuf[BUF_ERR_BUFLEN];
        BufHandle* buf = buf_u64_create(path, (uint64_t)capacity, errbuf);
        if (!buf) croak("Data::Buffer::Shared::U64: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)buf);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        BufHandle* h = INT2PTR(BufHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        buf_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

SV*
get(SV* self_sv, UV idx)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        uint64_t val;
        if (!buf_u64_get(h, (uint64_t)idx, &val)) XSRETURN_UNDEF;
        RETVAL = newSVuv(val);
    OUTPUT:
        RETVAL

bool
set(SV* self_sv, UV idx, UV val)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = buf_u64_set(h, (uint64_t)idx, (uint64_t)val);
    OUTPUT:
        RETVAL

void
slice(SV* self_sv, UV from, UV count)
    PPCODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (count == 0) XSRETURN_EMPTY;
        uint64_t *tmp;
        Newx(tmp, count, uint64_t);
        SAVEFREEPV(tmp);
        if (!buf_u64_get_slice(h, (uint64_t)from, (uint64_t)count, tmp))
            croak("Data::Buffer::Shared::U64: slice out of bounds");
        EXTEND(SP, count);
        for (UV i = 0; i < count; i++)
            mPUSHu(tmp[i]);

bool
set_slice(SV* self_sv, UV from, ...)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        UV count = items - 2;
        if (count == 0) XSRETURN(1);
        uint64_t *tmp;
        Newx(tmp, count, uint64_t);
        SAVEFREEPV(tmp);
        for (UV i = 0; i < count; i++)
            tmp[i] = (uint64_t)SvUV(ST(i + 2));
        RETVAL = buf_u64_set_slice(h, (uint64_t)from, (uint64_t)count, tmp);
    OUTPUT:
        RETVAL

void
fill(SV* self_sv, UV val)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_u64_fill(h, (uint64_t)val);

SV*
incr(SV* self_sv, UV idx)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_incr(h, (uint64_t)idx));
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, UV idx)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_decr(h, (uint64_t)idx));
    OUTPUT:
        RETVAL

SV*
add(SV* self_sv, UV idx, UV delta)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_add(h, (uint64_t)idx, (uint64_t)delta));
    OUTPUT:
        RETVAL

bool
cas(SV* self_sv, UV idx, UV expected, UV desired)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = buf_u64_cas(h, (uint64_t)idx, (uint64_t)expected, (uint64_t)desired);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = (UV)buf_u64_capacity(h);
    OUTPUT:
        RETVAL

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = (UV)buf_u64_mmap_size(h);
    OUTPUT:
        RETVAL

UV
elem_size(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = (UV)buf_u64_elem_size(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (h->path) RETVAL = newSVpv(h->path, 0); else XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

void
lock_wr(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_u64_lock_wr(h);

void
unlock_wr(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_u64_unlock_wr(h);

void
lock_rd(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_u64_lock_rd(h);

void
unlock_rd(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_u64_unlock_rd(h);

void
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class)) {
            BufHandle* h = INT2PTR(BufHandle*, SvIV(SvRV(self_or_class)));
            if (h) { if (!h->path) croak("cannot unlink anonymous buffer"); p = h->path; }
            else croak("Data::Buffer::Shared::U64: destroyed object");
        } else {
            if (items < 2) croak("Usage: Data::Buffer::Shared::U64->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        unlink(p);

UV
ptr(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = PTR2UV(buf_u64_ptr(h));
    OUTPUT:
        RETVAL

UV
ptr_at(SV* self_sv, UV idx)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        void *p = buf_u64_ptr_at(h, (uint64_t)idx);
        if (!p) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = PTR2UV(p);
    OUTPUT:
        RETVAL

SV*
new_anon(char* class, UV capacity)
    CODE:
        char errbuf[BUF_ERR_BUFLEN];
        BufHandle* buf = buf_u64_create_anon((uint64_t)capacity, errbuf);
        if (!buf) croak("Data::Buffer::Shared::U64: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)buf);
    OUTPUT:
        RETVAL

void
clear(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_u64_clear(h);

SV*
get_raw(SV* self_sv, UV byte_off, UV nbytes)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = newSV(nbytes ? nbytes : 1);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, nbytes);
        if (!buf_u64_get_raw(h, (uint64_t)byte_off, (uint64_t)nbytes, SvPVX(RETVAL))) {
            SvREFCNT_dec(RETVAL);
            croak("Data::Buffer::Shared::U64: get_raw out of bounds");
        }
    OUTPUT:
        RETVAL

bool
set_raw(SV* self_sv, UV byte_off, SV* data_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        STRLEN dlen;
        const char *dptr = SvPV(data_sv, dlen);
        RETVAL = buf_u64_set_raw(h, (uint64_t)byte_off, (uint64_t)dlen, dptr);
    OUTPUT:
        RETVAL

SV*
cmpxchg(SV* self_sv, UV idx, UV expected, UV desired)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_cmpxchg(h, (uint64_t)idx, (uint64_t)expected, (uint64_t)desired));
    OUTPUT:
        RETVAL

SV*
atomic_and(SV* self_sv, UV idx, UV mask)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_atomic_and(h, (uint64_t)idx, (uint64_t)mask));
    OUTPUT:
        RETVAL

SV*
atomic_or(SV* self_sv, UV idx, UV mask)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_atomic_or(h, (uint64_t)idx, (uint64_t)mask));
    OUTPUT:
        RETVAL

SV*
atomic_xor(SV* self_sv, UV idx, UV mask)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (idx >= h->hdr->capacity) croak("Data::Buffer::Shared::U64: index out of bounds");
        RETVAL = newSVuv(buf_u64_atomic_xor(h, (uint64_t)idx, (uint64_t)mask));
    OUTPUT:
        RETVAL

SV*
new_memfd(char* class, char* name, UV capacity)
    CODE:
        char errbuf[BUF_ERR_BUFLEN];
        BufHandle* buf = buf_u64_create_memfd(name, (uint64_t)capacity, errbuf);
        if (!buf) croak("Data::Buffer::Shared::U64: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)buf);
    OUTPUT:
        RETVAL

SV*
new_from_fd(char* class, int fd)
    CODE:
        char errbuf[BUF_ERR_BUFLEN];
        BufHandle* buf = buf_u64_open_fd(fd, errbuf);
        if (!buf) croak("Data::Buffer::Shared::U64: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)buf);
    OUTPUT:
        RETVAL

SV*
fd(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (h->fd < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(h->fd);
    OUTPUT:
        RETVAL

SV*
as_scalar(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        size_t len = (size_t)(h->hdr->capacity * h->hdr->elem_size);
        SV *inner = newSV_type(SVt_PV);
        SvPV_set(inner, (char *)h->data);
        SvCUR_set(inner, len);
        SvLEN_set(inner, 0);
        SvPOK_on(inner);
        SvREADONLY_on(inner);
        MAGIC *mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, &buf_scalar_magic_vtbl, NULL, 0);
        mg->mg_obj = SvREFCNT_inc_simple_NN(self_sv);
        RETVAL = newRV_noinc(inner);
    OUTPUT:
        RETVAL

bool
add_slice(SV* self_sv, UV from, ...)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        UV count = items - 2;
        if (count == 0) XSRETURN(1);
        uint64_t *tmp;
        Newx(tmp, count, uint64_t);
        SAVEFREEPV(tmp);
        for (UV i = 0; i < count; i++)
            tmp[i] = (uint64_t)SvUV(ST(i + 2));
        RETVAL = buf_u64_add_slice(h, (uint64_t)from, (uint64_t)count, tmp);
    OUTPUT:
        RETVAL

IV
create_eventfd(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = (IV)buf_create_eventfd(h);
        if (RETVAL < 0) croak("Data::Buffer::Shared::U64: eventfd: %s", strerror(errno));
    OUTPUT:
        RETVAL

void
attach_eventfd(SV* self_sv, int efd)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        buf_attach_eventfd(h, efd);

SV*
eventfd(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        if (h->efd < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(h->efd);
    OUTPUT:
        RETVAL

bool
notify(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        RETVAL = buf_notify(h);
    OUTPUT:
        RETVAL

SV*
wait_notify(SV* self_sv)
    CODE:
        EXTRACT_BUF("Data::Buffer::Shared::U64", self_sv);
        int64_t val = buf_wait_notify(h);
        if (val < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL
