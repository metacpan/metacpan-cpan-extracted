MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0, UV lru_skip = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_si_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, (uint32_t)lru_skip, errbuf);
        if (!map) croak("HashMap::Shared::SI: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

SV*
new_sharded(char* class, char* path_prefix, UV num_shards, UV max_entries, UV lru_max = 0, UV ttl_default = 0, UV lru_skip = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_si_create_sharded(path_prefix, (uint32_t)num_shards, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, (uint32_t)lru_skip, errbuf);
        if (!map) croak("HashMap::Shared::SI: %s", errbuf[0] ? errbuf : "unknown error");
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
put(SV* self_sv, SV* key_sv, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_put(h, _kstr, (uint32_t)_klen, _kutf8, value);
    OUTPUT:
        RETVAL

UV
set_multi(SV* self_sv, ...)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        if ((items - 1) % 2 != 0) croak("set_multi requires even number of arguments (key, value pairs)");
        uint32_t count = 0;
        if (h->shard_handles) {
            for (int i = 1; i < items; i += 2) {
                STRLEN _klen; const char *_kstr = SvPV(ST(i), _klen);
                bool _kutf8 = SvUTF8(ST(i)) ? 1 : 0;
                count += shm_si_put(h, _kstr, (uint32_t)_klen, _kutf8, (int64_t)SvIV(ST(i + 1)));
            }
        } else {
            ShmHeader *hdr = h->hdr;
            shm_rwlock_wrlock(hdr);
            shm_seqlock_write_begin(&hdr->seq);
            for (int i = 1; i < items; i += 2) {
                STRLEN _klen; const char *_kstr = SvPV(ST(i), _klen);
                bool _kutf8 = SvUTF8(ST(i)) ? 1 : 0;
                if (_klen > SHM_MAX_STR_LEN) { shm_seqlock_write_end(&hdr->seq); shm_rwlock_wrunlock(hdr); croak("key too long"); }
                count += shm_si_put_inner(h, _kstr, (uint32_t)_klen, _kutf8, (int64_t)SvIV(ST(i + 1)), SHM_TTL_USE_DEFAULT);
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
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        int nkeys = items - 1;
        if (nkeys == 0) XSRETURN_EMPTY;
        EXTEND(SP, nkeys);
        if (h->shard_handles) {
            for (int i = 0; i < nkeys; i++) {
                STRLEN _kl; const char *_ks = SvPV(ST(i + 1), _kl);
                bool _ku = SvUTF8(ST(i + 1)) ? 1 : 0;
                int64_t val;
                if (shm_si_get(h, _ks, (uint32_t)_kl, _ku, &val))
                    mPUSHi(val);
                else
                    PUSHs(&PL_sv_undef);
            }
        } else {
            ShmHeader *hdr = h->hdr;
            ShmNodeSI *nodes = (ShmNodeSI *)h->nodes;
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
                int64_t val = 0;
                for (uint32_t j = 0; j <= mask; j++) {
                    uint32_t idx = (pos + j) & mask;
                    uint8_t st = states[idx];
                    if (st == SHM_EMPTY) break;
                    if (st != tag) continue;
                    if (shm_si__key_eq_str(&nodes[idx], arena, _ks, (uint32_t)_kl, _ku)) {
                        if (h->expires_at && h->expires_at[idx] && now >= h->expires_at[idx]) break;
                        val = nodes[idx].value;
                        found = 1; break;
                    }
                }
                if (found) mPUSHi(val);
                else PUSHs(&PL_sv_undef);
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
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        HV *hv = newHV();
        hv_store(hv, "size", 4, newSVuv(shm_si_size(h)), 0);
        hv_store(hv, "capacity", 8, newSVuv(shm_si_capacity(h)), 0);
        hv_store(hv, "max_entries", 11, newSVuv(shm_si_max_entries(h)), 0);
        hv_store(hv, "tombstones", 10, newSVuv(shm_si_tombstones(h)), 0);
        hv_store(hv, "mmap_size", 9, newSVuv(shm_si_mmap_size(h)), 0);
        hv_store(hv, "arena_used", 10, newSVuv(shm_si_arena_used(h)), 0);
        hv_store(hv, "arena_cap", 9, newSVuv(shm_si_arena_cap(h)), 0);
        hv_store(hv, "evictions", 9, newSVuv(shm_si_stat_evictions(h)), 0);
        hv_store(hv, "expired", 7, newSVuv(shm_si_stat_expired(h)), 0);
        hv_store(hv, "recoveries", 10, newSVuv(shm_si_stat_recoveries(h)), 0);
        hv_store(hv, "max_size", 8, newSVuv(shm_si_max_size(h)), 0);
        hv_store(hv, "ttl", 3, newSVuv(shm_si_ttl(h)), 0);
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
cas(SV* self_sv, SV* key_sv, int64_t expected, int64_t desired)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_cas(h, _kstr, (uint32_t)_klen, _kutf8, expected, desired);
    OUTPUT:
        RETVAL

bool
persist(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_persist(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
set_ttl(SV* self_sv, SV* key_sv, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_set_ttl(h, _kstr, (uint32_t)_klen, _kutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int64_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_si_put_ttl(h, _kstr, (uint32_t)_klen, _kutf8, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t value;
        if (!shm_si_get(h, _kstr, (uint32_t)_klen, _kutf8, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_remove(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_exists(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int64_t val = shm_si_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, 1, &ok);
        if (!ok) croak("HashMap::Shared::SI: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int64_t val = shm_si_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, -1, &ok);
        if (!ok) croak("HashMap::Shared::SI: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int64_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int64_t val = shm_si_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, delta, &ok);
        if (!ok) croak("HashMap::Shared::SI: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSI *nodes = (ShmNodeSI *)sh->nodes;
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
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSI *nodes = (ShmNodeSI *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now))
                    mXPUSHi(nodes[i].value);
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSI *nodes = (ShmNodeSI *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size * 2);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    char _ib[SHM_INLINE_MAX]; uint32_t klen;
                    const char *kp = shm_str_ptr(nodes[i].key_off, nodes[i].key_len, sh->arena, _ib, &klen);
                    SV* sv = newSVpvn(kp, klen);
                    if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                    mXPUSHi(nodes[i].value);
                }
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int64_t out_value;
        if (shm_si_each(h, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_si_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        shm_si_iter_reset(h);
        shm_si_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        shm_si_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        HV* hv = newHV();
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeSI *nodes = (ShmNodeSI *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    char _ib[SHM_INLINE_MAX]; uint32_t klen;
                    const char *kp = shm_str_ptr(nodes[i].key_off, nodes[i].key_len, sh->arena, _ib, &klen);
                    bool kutf8 = SHM_UNPACK_UTF8(nodes[i].key_len);
                    SV* val = newSViv(nodes[i].value);
                    if (!hv_store(hv, kp,
                                   kutf8 ? -(I32)klen : (I32)klen, val, 0)) SvREFCNT_dec(val);
                }
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int64_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t out;
        int rc = shm_si_get_or_set(h, _kstr, (uint32_t)_klen, _kutf8, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t out_value;
        if (!shm_si_take(h, _kstr, (uint32_t)_klen, _kutf8, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

void
pop(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int64_t out_val;
        if (!shm_si_pop(h, &out_key, &out_klen, &out_kutf8, &out_val)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        SV *ksv = newSVpvn(out_key, out_klen);
        if (out_kutf8) SvUTF8_on(ksv);
        mPUSHs(ksv);
        mPUSHi(out_val);

void
shift(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int64_t out_val;
        if (!shm_si_shift(h, &out_key, &out_klen, &out_kutf8, &out_val)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        SV *ksv = newSVpvn(out_key, out_klen);
        if (out_kutf8) SvUTF8_on(ksv);
        mPUSHs(ksv);
        mPUSHi(out_val);

void
drain(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        if (limit == 0) XSRETURN_EMPTY;
        shm_si_drain_entry *entries;
        Newxz(entries, limit, shm_si_drain_entry);
        
        SAVEFREEPV(entries);
        char *buf = NULL; uint32_t buf_cap = 0;
        uint32_t n = shm_si_drain(h, (uint32_t)limit, entries, &buf, &buf_cap);
        
        EXTEND(SP, n * 2);
        for (uint32_t i = 0; i < n; i++) {
            SV *ksv = newSVpvn(buf + entries[i].key_off, entries[i].key_len);
            if (entries[i].key_utf8) SvUTF8_on(ksv);
            mPUSHs(ksv);
            mPUSHi(entries[i].value);
        }
        if (buf) free(buf);
        

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_flush_expired(h);
    OUTPUT:
        RETVAL

void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        int done = 0;
        uint32_t flushed = shm_si_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_mmap_size(h);
    OUTPUT:
        RETVAL

bool
touch(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_touch(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = shm_si_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_stat_expired(h);
    OUTPUT:
        RETVAL

UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_stat_recoveries(h);
    OUTPUT:
        RETVAL

UV
arena_used(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_arena_used(h);
    OUTPUT:
        RETVAL

UV
arena_cap(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_arena_cap(h);
    OUTPUT:
        RETVAL

bool
add(SV* self_sv, SV* key_sv, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_add(h, _kstr, (uint32_t)_klen, _kutf8, value);
    OUTPUT:
        RETVAL

bool
update(SV* self_sv, SV* key_sv, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_update(h, _kstr, (uint32_t)_klen, _kutf8, value);
    OUTPUT:
        RETVAL

SV*
swap(SV* self_sv, SV* key_sv, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t out_value;
        int rc = shm_si_swap(h, _kstr, (uint32_t)_klen, _kutf8, value, &out_value);
        if (rc != 1) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL

bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::SI object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::SI->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) ?
            shm_unlink_sharded(INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)))) :
            shm_unlink_path(p);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t remaining = shm_si_ttl_remaining(h, _kstr, (uint32_t)_klen, _kutf8);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::SI::Cursor", (void*)c);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->current;
        shm_cursor_destroy(c);
        if (h) shm_si_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI::Cursor", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int64_t out_value;
        if (shm_si_cursor_next(c, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI::Cursor", self_sv);
        shm_si_cursor_reset(c);

bool
seek(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI::Cursor", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_cursor_seek(c, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

