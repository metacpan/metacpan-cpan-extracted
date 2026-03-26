MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SS
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0, UV lru_skip = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_ss_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, (uint32_t)lru_skip, errbuf);
        if (!map) croak("HashMap::Shared::SS: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

SV*
new_sharded(char* class, char* path_prefix, UV num_shards, UV max_entries, UV lru_max = 0, UV ttl_default = 0, UV lru_skip = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_ss_create_sharded(path_prefix, (uint32_t)num_shards, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, (uint32_t)lru_skip, errbuf);
        if (!map) croak("HashMap::Shared::SS: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, SV* value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = shm_ss_put(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

UV
set_multi(SV* self_sv, ...)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        if ((items - 1) % 2 != 0) croak("set_multi requires even number of arguments (key, value pairs)");
        uint32_t count = 0;
        if (h->shard_handles) {
            for (int i = 1; i < items; i += 2) {
                STRLEN _kl; const char *_ks = SvPV(ST(i), _kl);
                bool _ku = SvUTF8(ST(i)) ? 1 : 0;
                STRLEN _vl; const char *_vs = SvPV(ST(i+1), _vl);
                bool _vu = SvUTF8(ST(i+1)) ? 1 : 0;
                count += shm_ss_put(h, _ks, (uint32_t)_kl, _ku, _vs, (uint32_t)_vl, _vu);
            }
        } else {
            ShmHeader *hdr = h->hdr;
            shm_rwlock_wrlock(hdr);
            shm_seqlock_write_begin(&hdr->seq);
            for (int i = 1; i < items; i += 2) {
                STRLEN _kl; const char *_ks = SvPV(ST(i), _kl);
                bool _ku = SvUTF8(ST(i)) ? 1 : 0;
                if (_kl > SHM_MAX_STR_LEN) { shm_seqlock_write_end(&hdr->seq); shm_rwlock_wrunlock(hdr); croak("key too long"); }
                STRLEN _vl; const char *_vs = SvPV(ST(i+1), _vl);
                bool _vu = SvUTF8(ST(i+1)) ? 1 : 0;
                if (_vl > SHM_MAX_STR_LEN) { shm_seqlock_write_end(&hdr->seq); shm_rwlock_wrunlock(hdr); croak("value too long"); }
                count += shm_ss_put_inner(h, _ks, (uint32_t)_kl, _ku, _vs, (uint32_t)_vl, _vu, SHM_TTL_USE_DEFAULT);
            }
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
        }
        RETVAL = count;
    OUTPUT:
        RETVAL

void
get_multi(SV* self_sv, ...)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        int nkeys = items - 1;
        if (nkeys == 0) XSRETURN_EMPTY;
        EXTEND(SP, nkeys);
        if (h->shard_handles) {
            for (int i = 0; i < nkeys; i++) {
                STRLEN _kl; const char *_ks = SvPV(ST(i + 1), _kl);
                bool _ku = SvUTF8(ST(i + 1)) ? 1 : 0;
                const char *out_s; uint32_t out_l; bool out_u;
                if (shm_ss_get(h, _ks, (uint32_t)_kl, _ku, &out_s, &out_l, &out_u)) {
                    SV *sv = newSVpvn(out_s, out_l);
                    if (out_u) SvUTF8_on(sv);
                    mPUSHs(sv);
                } else PUSHs(&PL_sv_undef);
            }
        } else {
            ShmHeader *hdr = h->hdr;
            ShmNodeSS *nodes = (ShmNodeSS *)h->nodes;
            uint8_t *states = h->states;
            char *arena = h->arena;
            uint32_t now = h->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            uint32_t mask = hdr->table_cap - 1;
            for (int i = 0; i < nkeys; i++) {
                STRLEN _kl; const char *_ks = SvPV(ST(i + 1), _kl);
                bool _ku = SvUTF8(ST(i + 1)) ? 1 : 0;
                uint32_t hash = shm_hash_string(_ks, (uint32_t)_kl);
                uint32_t pos = hash & mask;
                uint8_t tag = SHM_MAKE_TAG(hash);
                int found = 0;
                uint32_t vidx = 0;
                for (uint32_t j = 0; j <= mask; j++) {
                    uint32_t idx = (pos + j) & mask;
                    uint8_t st = states[idx];
                    if (st == SHM_EMPTY) break;
                    if (st != tag) continue;
                    if (shm_ss__key_eq_str(&nodes[idx], arena, _ks, (uint32_t)_kl, _ku)) {
                        if (h->expires_at && h->expires_at[idx] && now >= h->expires_at[idx]) break;
                        vidx = idx; found = 1; break;
                    }
                }
                if (found) {
                    char _vib[SHM_INLINE_MAX]; uint32_t vl;
                    const char *vp = shm_str_ptr(nodes[vidx].val_off, nodes[vidx].val_len, arena, _vib, &vl);
                    SV *sv = newSVpvn(vp, vl);
                    if (SHM_UNPACK_UTF8(nodes[vidx].val_len)) SvUTF8_on(sv);
                    mPUSHs(sv);
                } else PUSHs(&PL_sv_undef);
                /* Prefetch next key's probe start */
                if (i + 1 < nkeys) {
                    STRLEN nkl; const char *nks = SvPV(ST(i + 2), nkl);
                    uint32_t nh = shm_hash_string(nks, (uint32_t)nkl);
                    __builtin_prefetch(&states[nh & mask], 0, 0);
                }
            }
        }

SV*
stats(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        HV *hv = newHV();
        hv_store(hv, "size", 4, newSVuv(shm_ss_size(h)), 0);
        hv_store(hv, "capacity", 8, newSVuv(shm_ss_capacity(h)), 0);
        hv_store(hv, "max_entries", 11, newSVuv(shm_ss_max_entries(h)), 0);
        hv_store(hv, "tombstones", 10, newSVuv(shm_ss_tombstones(h)), 0);
        hv_store(hv, "mmap_size", 9, newSVuv(shm_ss_mmap_size(h)), 0);
        hv_store(hv, "arena_used", 10, newSVuv(shm_ss_arena_used(h)), 0);
        hv_store(hv, "arena_cap", 9, newSVuv(shm_ss_arena_cap(h)), 0);
        hv_store(hv, "evictions", 9, newSVuv(shm_ss_stat_evictions(h)), 0);
        hv_store(hv, "expired", 7, newSVuv(shm_ss_stat_expired(h)), 0);
        hv_store(hv, "recoveries", 10, newSVuv(shm_ss_stat_recoveries(h)), 0);
        hv_store(hv, "max_size", 8, newSVuv(shm_ss_max_size(h)), 0);
        hv_store(hv, "ttl", 3, newSVuv(shm_ss_ttl(h)), 0);
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
persist(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_persist(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
set_ttl(SV* self_sv, SV* key_sv, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_set_ttl(h, _kstr, (uint32_t)_klen, _kutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, SV* value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(value);
        REQUIRE_TTL(h);
        RETVAL = shm_ss_put_ttl(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (!shm_ss_get(h, _kstr, (uint32_t)_klen, _kutf8, &val, &val_len, &val_utf8))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_remove(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_exists(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSS *nodes = (ShmNodeSS *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    char _ib[SHM_INLINE_MAX]; uint32_t klen;
                    const char *kp = shm_str_ptr(nodes[i].key_off, nodes[i].key_len, sh->arena, _ib, &klen);
                    SV* sv = newSVpvn(kp, klen);
                    if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                }
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSS *nodes = (ShmNodeSS *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    char _ib[SHM_INLINE_MAX]; uint32_t vlen;
                    const char *vp = shm_str_ptr(nodes[i].val_off, nodes[i].val_len, sh->arena, _ib, &vlen);
                    SV* sv = newSVpvn(vp, vlen);
                    if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                }
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSS *nodes = (ShmNodeSS *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size * 2);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    char _kib[SHM_INLINE_MAX]; uint32_t klen;
                    const char *kp = shm_str_ptr(nodes[i].key_off, nodes[i].key_len, sh->arena, _kib, &klen);
                    SV* ksv = newSVpvn(kp, klen);
                    if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(ksv);
                    mXPUSHs(ksv);
                    char _vib[SHM_INLINE_MAX]; uint32_t vlen;
                    const char *vp = shm_str_ptr(nodes[i].val_off, nodes[i].val_len, sh->arena, _vib, &vlen);
                    SV* vsv = newSVpvn(vp, vlen);
                    if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(vsv);
                    mXPUSHs(vsv);
                }
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        const char *out_key, *out_val;
        uint32_t out_klen, out_vlen;
        bool out_kutf8, out_vutf8;
        if (shm_ss_each(h, &out_key, &out_klen, &out_kutf8, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            SV* vsv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(vsv);
            mXPUSHs(vsv);
            XSRETURN(2);
        }
        shm_ss_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        shm_ss_iter_reset(h);
        shm_ss_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        shm_ss_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        HV* hv = newHV();
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSS *nodes = (ShmNodeSS *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    char _kib[SHM_INLINE_MAX]; uint32_t klen;
                    const char *kp = shm_str_ptr(nodes[i].key_off, nodes[i].key_len, sh->arena, _kib, &klen);
                    bool kutf8 = SHM_UNPACK_UTF8(nodes[i].key_len);
                    char _vib[SHM_INLINE_MAX]; uint32_t vlen;
                    const char *vp = shm_str_ptr(nodes[i].val_off, nodes[i].val_len, sh->arena, _vib, &vlen);
                    SV* val = newSVpvn(vp, vlen);
                    if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(val);
                    if (!hv_store(hv, kp,
                                   kutf8 ? -(I32)klen : (I32)klen, val, 0)) SvREFCNT_dec(val);
                }
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, SV* default_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        EXTRACT_STR_VAL(default_sv);
        int rc = shm_ss_get_or_set(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8, &out_str, &out_len, &out_utf8);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t remaining = shm_ss_ttl_remaining(h, _kstr, (uint32_t)_klen, _kutf8);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::SS::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        if (!shm_ss_take(h, _kstr, (uint32_t)_klen, _kutf8, &out_str, &out_len, &out_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

void
pop(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (!shm_ss_pop(h, &out_key, &out_klen, &out_kutf8, &out_val, &out_vlen, &out_vutf8)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        SV *ksv = newSVpvn(out_key, out_klen);
        if (out_kutf8) SvUTF8_on(ksv);
        mPUSHs(ksv);
        SV *vsv = newSVpvn(out_val, out_vlen);
        if (out_vutf8) SvUTF8_on(vsv);
        mPUSHs(vsv);

void
shift(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (!shm_ss_shift(h, &out_key, &out_klen, &out_kutf8, &out_val, &out_vlen, &out_vutf8)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        SV *ksv = newSVpvn(out_key, out_klen);
        if (out_kutf8) SvUTF8_on(ksv);
        mPUSHs(ksv);
        SV *vsv = newSVpvn(out_val, out_vlen);
        if (out_vutf8) SvUTF8_on(vsv);
        mPUSHs(vsv);

void
drain(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        if (limit == 0) XSRETURN_EMPTY;
        shm_ss_drain_entry *entries = (shm_ss_drain_entry *)calloc(limit, sizeof(shm_ss_drain_entry));
        if (!entries) croak("drain: out of memory");
        SAVEFREEPV(entries);
        char *buf = NULL; uint32_t buf_cap = 0;
        uint32_t n = shm_ss_drain(h, (uint32_t)limit, entries, &buf, &buf_cap);
        if (buf) SAVEFREEPV(buf);
        EXTEND(SP, n * 2);
        for (uint32_t i = 0; i < n; i++) {
            SV *ksv = newSVpvn(buf + entries[i].key_off, entries[i].key_len);
            if (entries[i].key_utf8) SvUTF8_on(ksv);
            mPUSHs(ksv);
            SV *vsv = newSVpvn(buf + entries[i].val_off, entries[i].val_len);
            if (entries[i].val_utf8) SvUTF8_on(vsv);
            mPUSHs(vsv);
        }
        

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_flush_expired(h);
    OUTPUT:
        RETVAL

void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        int done = 0;
        uint32_t flushed = shm_ss_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_mmap_size(h);
    OUTPUT:
        RETVAL

bool
touch(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_touch(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = shm_ss_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_stat_expired(h);
    OUTPUT:
        RETVAL

UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_stat_recoveries(h);
    OUTPUT:
        RETVAL

UV
arena_used(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_arena_used(h);
    OUTPUT:
        RETVAL

UV
arena_cap(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_arena_cap(h);
    OUTPUT:
        RETVAL

bool
add(SV* self_sv, SV* key_sv, SV* val_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(val_sv);
        RETVAL = shm_ss_add(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

bool
update(SV* self_sv, SV* key_sv, SV* val_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(val_sv);
        RETVAL = shm_ss_update(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

SV*
swap(SV* self_sv, SV* key_sv, SV* val_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(val_sv);
        const char *out_s; uint32_t out_l; bool out_u;
        int rc = shm_ss_swap(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8, &out_s, &out_l, &out_u);
        if (rc != 1) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_s, out_l);
        if (out_u) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL

bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::SS object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::SS->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) ?
            shm_unlink_sharded(INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)))) :
            shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SS::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->current;
        shm_cursor_destroy(c);
        if (h) shm_ss_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SS::Cursor", self_sv);
        const char *out_key, *out_val;
        uint32_t out_klen, out_vlen;
        bool out_kutf8, out_vutf8;
        if (shm_ss_cursor_next(c, &out_key, &out_klen, &out_kutf8, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            SV* vsv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(vsv);
            mXPUSHs(vsv);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SS::Cursor", self_sv);
        shm_ss_cursor_reset(c);

bool
seek(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SS::Cursor", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_cursor_seek(c, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

