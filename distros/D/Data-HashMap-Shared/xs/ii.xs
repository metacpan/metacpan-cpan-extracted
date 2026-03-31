MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::II
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0, UV lru_skip = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_ii_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, (uint32_t)lru_skip, errbuf);
        if (!map) croak("HashMap::Shared::II: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

SV*
new_sharded(char* class, char* path_prefix, UV num_shards, UV max_entries, UV lru_max = 0, UV ttl_default = 0, UV lru_skip = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_ii_create_sharded(path_prefix, (uint32_t)num_shards, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, (uint32_t)lru_skip, errbuf);
        if (!map) croak("HashMap::Shared::II: %s", errbuf[0] ? errbuf : "unknown error");
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
put(SV* self_sv, int64_t key, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_put(h, key, value);
    OUTPUT:
        RETVAL

UV
set_multi(SV* self_sv, ...)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        if ((items - 1) % 2 != 0) croak("set_multi requires even number of arguments (key, value pairs)");
        uint32_t count = 0;
        if (h->shard_handles) {
            for (int i = 1; i < items; i += 2)
                count += shm_ii_put(h, (int64_t)SvIV(ST(i)), (int64_t)SvIV(ST(i + 1)));
        } else {
            ShmHeader *hdr = h->hdr;
            shm_rwlock_wrlock(hdr);
            shm_seqlock_write_begin(&hdr->seq);
            for (int i = 1; i < items; i += 2)
                count += shm_ii_put_inner(h, (int64_t)SvIV(ST(i)), (int64_t)SvIV(ST(i + 1)), SHM_TTL_USE_DEFAULT);
            shm_seqlock_write_end(&hdr->seq);
            shm_rwlock_wrunlock(hdr);
        }
        RETVAL = count;
    OUTPUT:
        RETVAL

void
get_multi(SV* self_sv, ...)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int nkeys = items - 1;
        if (nkeys == 0) XSRETURN_EMPTY;
        EXTEND(SP, nkeys);
        if (h->shard_handles) {
            for (int i = 0; i < nkeys; i++) {
                int64_t key = (int64_t)SvIV(ST(i + 1));
                int64_t val;
                if (shm_ii_get(h, key, &val))
                    mPUSHi(val);
                else
                    PUSHs(&PL_sv_undef);
            }
        } else {
            ShmHeader *hdr = h->hdr;
            ShmNodeII *nodes = (ShmNodeII *)h->nodes;
            uint8_t *states = h->states;
            uint32_t now = h->expires_at ? shm_now() : 0;
            /* Phase 1: compute hashes and prefetch first probe positions */
            uint32_t *hashes = NULL;
            Newx(hashes, nkeys, uint32_t);
            SAVEFREEPV(hashes);
            RDLOCK_GUARD(hdr);
            uint32_t mask = hdr->table_cap - 1;
            for (int i = 0; i < nkeys; i++) {
                hashes[i] = shm_hash_int64((int64_t)SvIV(ST(i + 1)));
                __builtin_prefetch(&states[hashes[i] & mask], 0, 0);
                __builtin_prefetch(&nodes[hashes[i] & mask], 0, 0);
            }
            /* Phase 2: probe each key */
            for (int i = 0; i < nkeys; i++) {
                int64_t key = (int64_t)SvIV(ST(i + 1));
                uint32_t hash = hashes[i];
                uint32_t pos = hash & mask;
                uint8_t tag = SHM_MAKE_TAG(hash);
                int found = 0;
                int64_t val = 0;
                for (uint32_t j = 0; j <= mask; j++) {
                    uint32_t idx = (pos + j) & mask;
                    uint8_t st = states[idx];
                    if (st == SHM_EMPTY) break;
                    if (st != tag) continue;
                    if (nodes[idx].key == key) {
                        if (h->expires_at && h->expires_at[idx] && now >= h->expires_at[idx]) break;
                        val = nodes[idx].value;
                        found = 1;
                        break;
                    }
                }
                if (found) mPUSHi(val);
                else PUSHs(&PL_sv_undef);
                /* Prefetch next key's probe position */
                if (i + 1 < nkeys) {
                    uint32_t npos = hashes[i + 1] & mask;
                    __builtin_prefetch(&states[npos], 0, 0);
                    __builtin_prefetch(&nodes[npos], 0, 0);
                }
            }
        }

SV*
stats(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        HV *hv = newHV();
        hv_store(hv, "size", 4, newSVuv(shm_ii_size(h)), 0);
        hv_store(hv, "capacity", 8, newSVuv(shm_ii_capacity(h)), 0);
        hv_store(hv, "max_entries", 11, newSVuv(shm_ii_max_entries(h)), 0);
        hv_store(hv, "tombstones", 10, newSVuv(shm_ii_tombstones(h)), 0);
        hv_store(hv, "mmap_size", 9, newSVuv(shm_ii_mmap_size(h)), 0);
        hv_store(hv, "arena_used", 10, newSVuv(shm_ii_arena_used(h)), 0);
        hv_store(hv, "arena_cap", 9, newSVuv(shm_ii_arena_cap(h)), 0);
        hv_store(hv, "evictions", 9, newSVuv(shm_ii_stat_evictions(h)), 0);
        hv_store(hv, "expired", 7, newSVuv(shm_ii_stat_expired(h)), 0);
        hv_store(hv, "recoveries", 10, newSVuv(shm_ii_stat_recoveries(h)), 0);
        hv_store(hv, "max_size", 8, newSVuv(shm_ii_max_size(h)), 0);
        hv_store(hv, "ttl", 3, newSVuv(shm_ii_ttl(h)), 0);
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
cas(SV* self_sv, int64_t key, int64_t expected, int64_t desired)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_cas(h, key, expected, desired);
    OUTPUT:
        RETVAL

bool
persist(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_persist(h, key);
    OUTPUT:
        RETVAL

bool
set_ttl(SV* self_sv, int64_t key, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_set_ttl(h, key, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t value;
        if (!shm_ii_get(h, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_exists(h, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int ok;
        int64_t val = shm_ii_incr_by(h, key, 1, &ok);
        if (!ok) croak("HashMap::Shared::II: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int ok;
        int64_t val = shm_ii_incr_by(h, key, -1, &ok);
        if (!ok) croak("HashMap::Shared::II: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int64_t key, int64_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int ok;
        int64_t val = shm_ii_incr_by(h, key, delta, &ok);
        if (!ok) croak("HashMap::Shared::II: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeII *nodes = (ShmNodeII *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now))
                    mXPUSHi(nodes[i].key);
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeII *nodes = (ShmNodeII *)sh->nodes;
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
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeII *nodes = (ShmNodeII *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            EXTEND(SP, hdr->size * 2);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    mXPUSHi(nodes[i].key);
                    mXPUSHi(nodes[i].value);
                }
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_key, out_value;
        if (shm_ii_each(h, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_ii_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        shm_ii_iter_reset(h);
        shm_ii_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        shm_ii_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        HV* hv = newHV();
        uint32_t ns = h->shard_handles ? h->num_shards : 1;
        for (uint32_t si = 0; si < ns; si++) {
            ShmHandle *sh = h->shard_handles ? h->shard_handles[si] : h;
            ShmHeader *hdr = sh->hdr;
            ShmNodeII *nodes = (ShmNodeII *)sh->nodes;
            uint32_t now = sh->expires_at ? shm_now() : 0;
            RDLOCK_GUARD(hdr);
            for (uint32_t i = 0; i < hdr->table_cap; i++) {
                if (SHM_IS_LIVE(sh->states[i]) && !SHM_IS_EXPIRED(sh, i, now)) {
                    SV* val = newSViv(nodes[i].value);
                    char kbuf[24];
                    int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                    if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
                }
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int64_t key, int64_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out;
        int rc = shm_ii_get_or_set(h, key, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int64_t key, int64_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_ii_put_ttl(h, key, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_ttl(h);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_value;
        if (!shm_ii_take(h, key, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

void
pop(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_key;
        int64_t out_val;
        if (!shm_ii_pop(h, &out_key, &out_val)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        mPUSHi(out_key);
        mPUSHi(out_val);

void
shift(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_key;
        int64_t out_val;
        if (!shm_ii_shift(h, &out_key, &out_val)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        mPUSHi(out_key);
        mPUSHi(out_val);

void
drain(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        if (limit == 0) XSRETURN_EMPTY;
        shm_ii_drain_entry *entries;
        Newxz(entries, limit, shm_ii_drain_entry);
        
        SAVEFREEPV(entries);
        char *buf = NULL; uint32_t buf_cap = 0;
        uint32_t n = shm_ii_drain(h, (uint32_t)limit, entries, &buf, &buf_cap);
        
        EXTEND(SP, n * 2);
        for (uint32_t i = 0; i < n; i++) {
            mPUSHi(entries[i].key);
            mPUSHi(entries[i].value);
        }
        if (buf) free(buf);
        

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_flush_expired(h);
    OUTPUT:
        RETVAL

void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int done = 0;
        uint32_t flushed = shm_ii_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_mmap_size(h);
    OUTPUT:
        RETVAL

bool
touch(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_stat_expired(h);
    OUTPUT:
        RETVAL

UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_stat_recoveries(h);
    OUTPUT:
        RETVAL

UV
arena_used(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_arena_used(h);
    OUTPUT:
        RETVAL

UV
arena_cap(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_arena_cap(h);
    OUTPUT:
        RETVAL

bool
add(SV* self_sv, int64_t key, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_add(h, key, value);
    OUTPUT:
        RETVAL

bool
update(SV* self_sv, int64_t key, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_update(h, key, value);
    OUTPUT:
        RETVAL

SV*
swap(SV* self_sv, int64_t key, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_value;
        int rc = shm_ii_swap(h, key, value, &out_value);
        if (rc != 1) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL

bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::II object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::II->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) ?
            shm_unlink_sharded(INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)))) :
            shm_unlink_path(p);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t remaining = shm_ii_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::II::Cursor", (void*)c);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::II::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->current;
        shm_cursor_destroy(c);
        if (h) shm_ii_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::II::Cursor", self_sv);
        int64_t out_key; int64_t out_value;
        if (shm_ii_cursor_next(c, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::II::Cursor", self_sv);
        shm_ii_cursor_reset(c);

bool
seek(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::II::Cursor", self_sv);
        RETVAL = shm_ii_cursor_seek(c, key);
    OUTPUT:
        RETVAL

