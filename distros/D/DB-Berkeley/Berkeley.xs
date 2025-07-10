#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <db.h>
#include <string.h>
#include <stdio.h>

// #define DEBUG_LOG(fmt, ...) fprintf(stderr, "[DB::Berkeley DEBUG] " fmt "\n", ##__VA_ARGS__)
#define	DEBUG_LOG(fmt, ...)

/*
 * Internal C struct to wrap a Berkeley DB handle.
 * We'll store a pointer to this inside a Perl scalar reference.
 */
typedef struct {
	DB *dbp;  // Pointer to Berkeley DB handle
	DBC *cursor; // for iterator
} Berk;

/*
 * Helper function to open a Berkeley DB file as a HASH.
 * Takes filename, flags, and mode.
 * Dies (croaks) on failure.
 */
static DB *
_bdb_open(const char *file, u_int32_t flags, int mode) {
    DB *dbp;
    int ret;

    // Create the database handle
    ret = db_create(&dbp, NULL, 0);
    if (ret != 0) {
        croak("db_create failed: %s", db_strerror(ret));
    }

    // Open the database file as a HASH type
    ret = dbp->open(dbp, NULL, file, NULL, DB_HASH, flags | DB_CREATE, mode);
    if (ret != 0) {
        dbp->close(dbp, 0);
        croak("db->open failed: %s", db_strerror(ret));
    }

    return dbp;
}

MODULE = DB::Berkeley    PACKAGE = DB::Berkeley
PROTOTYPES: ENABLE

SV *
new(class, file, flags, mode)
    char *class
    char *file
    int flags
    int mode
PREINIT:
    Berk *obj;
    DB *dbp;
    SV *ret_sv;
CODE:

    DEBUG_LOG("new() called with file='%s', flags=%d, mode=%o", file, flags, mode);

    // Use default file mode if not specified
    if (mode == 0)
        mode = 0666;

    dbp = _bdb_open(file, flags, mode);  // Open Berkeley DB file

    obj = (Berk *)malloc(sizeof(Berk));
    if (!obj) {
        dbp->close(dbp, 0);
        croak("Out of memory");
    }
    obj->dbp = dbp;
    obj->cursor = NULL;

    // Bless the object reference
    ret_sv = sv_setref_pv(newSV(0), class, (void *)obj);
    DEBUG_LOG("DB handle created at %p", obj);

    RETVAL = ret_sv;
OUTPUT:
    RETVAL

int
put(self, key, value)
    SV *self
    SV *key
    SV *value
PREINIT:
    Berk *obj;
    DB *dbp;
    DBT k, v;
    char *kptr, *vptr;
    STRLEN klen, vlen;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    dbp = obj->dbp;

    kptr = SvPV(key, klen);
    vptr = SvPV(value, vlen);

    memset(&k, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;

    memset(&v, 0, sizeof(DBT));
    v.data = vptr;
    v.size = vlen;

    ret = dbp->put(dbp, NULL, &k, &v, 0);
    if (ret != 0) {
        croak("DB::Berkeley put(): %s", db_strerror(ret));
    }

    RETVAL = 1;
OUTPUT:
    RETVAL

SV *
get(self, key)
    SV *self
    SV *key
PREINIT:
    Berk *obj;
    DBT k, v;
    char *kptr;
    STRLEN klen;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    kptr = SvPV(key, klen);  // Extract raw key string

    memset(&k, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;

    memset(&v, 0, sizeof(DBT));
    v.flags = DB_DBT_MALLOC;  // Let DB allocate value buffer

    ret = obj->dbp->get(obj->dbp, NULL, &k, &v, 0);  // Perform DB->get
    if (ret == DB_NOTFOUND) {
        RETVAL = &PL_sv_undef;
    } else if (ret != 0) {
        croak("db->get failed: %s", db_strerror(ret));
    } else {
        RETVAL = newSVpvn((char *)v.data, v.size);  // Return as Perl scalar
        free(v.data);
    }
OUTPUT:
    RETVAL

int
delete(self, key)
    SV *self
    SV *key
PREINIT:
    Berk *obj;
    DB *dbp;
    DBT k;
    char *kptr;
    STRLEN klen;
    int ret;
CODE:
    obj = (Berk*)SvIV(SvRV(self));
    dbp = obj->dbp;
    kptr = SvPV(key, klen);

    memset(&k, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;

    ret = dbp->del(dbp, NULL, &k, 0);
    RETVAL = (ret == 0) ? 1 : 0;
OUTPUT:
    RETVAL

int
exists(self, key)
    SV *self
    SV *key
PREINIT:
    Berk *obj;
    DB *dbp;
    DBT k, v;
    char *kptr;
    STRLEN klen;
    int ret;
CODE:
    obj = (Berk*)SvIV(SvRV(self));
    dbp = obj->dbp;
    kptr = SvPV(key, klen);

    memset(&k, 0, sizeof(DBT));
    memset(&v, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;
    v.flags = DB_DBT_PARTIAL;  // No need to retrieve full value

    ret = dbp->get(dbp, NULL, &k, &v, 0);
    RETVAL = (ret == 0) ? 1 : 0;
OUTPUT:
    RETVAL

AV *
keys(self)
    SV *self
PREINIT:
    Berk *obj;
    DB *dbp;
    DBC *cursor;
    DBT key, val;
    AV *av;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));
    dbp = obj->dbp;
    av = newAV();

    // Clear key and value structures
    memset(&key, 0, sizeof(DBT));
    memset(&val, 0, sizeof(DBT));

    // Open a cursor
    ret = dbp->cursor(dbp, NULL, &cursor, 0);
    if (ret != 0) {
        croak("DB::Berkeley keys(): cursor open failed: %s", db_strerror(ret));
    }

    // Iterate over the database using the cursor
    while ((ret = cursor->get(cursor, &key, &val, DB_NEXT)) == 0) {
        av_push(av, newSVpvn((char *)key.data, key.size));
    }

    // DB_NOTFOUND means clean end
    if (ret != DB_NOTFOUND) {
        cursor->close(cursor);
        croak("DB::Berkeley keys(): cursor iteration failed: %s", db_strerror(ret));
    }

    cursor->close(cursor);
    RETVAL = av;
OUTPUT:
    RETVAL

AV *
values(self)
    SV *self
PREINIT:
    Berk *obj;
    DBC *cursor;
    DBT k, v;
    int ret;
    AV *av;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    ret = obj->dbp->cursor(obj->dbp, NULL, &cursor, 0);
    if (ret != 0) {
        croak("db->cursor failed: %s", db_strerror(ret));
    }

    av = newAV();

    memset(&k, 0, sizeof(DBT));
    memset(&v, 0, sizeof(DBT));

    while ((ret = cursor->get(cursor, &k, &v, DB_NEXT)) == 0) {
        SV *sv = newSVpvn((char *)v.data, v.size);
        av_push(av, sv);
    }

    if (ret != DB_NOTFOUND) {
        cursor->close(cursor);
        croak("cursor->get failed: %s", db_strerror(ret));
    }

    cursor->close(cursor);
    RETVAL = av;
OUTPUT:
    RETVAL

void
rewind(self)
    SV *self
PREINIT:
    Berk *obj;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    // Close previous cursor if it exists
    if (obj->cursor) {
        obj->cursor->close(obj->cursor);
        obj->cursor = NULL;
    }

    ret = obj->dbp->cursor(obj->dbp, NULL, &obj->cursor, 0);
    if (ret != 0) {
        croak("Failed to create cursor: %s", db_strerror(ret));
    }

void
iterator_reset(self)
    SV *self
PREINIT:
    Berk *obj;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    if (obj->cursor) {
        obj->cursor->close(obj->cursor);
        obj->cursor = NULL;
    }

    ret = obj->dbp->cursor(obj->dbp, NULL, &obj->cursor, 0);
    if (ret != 0) {
        croak("iterator_reset: Failed to create cursor: %s", db_strerror(ret));
    }

SV *
next_key(self)
    SV *self
PREINIT:
    Berk *obj;
    DBT k, v;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    if (!obj->cursor) {
        croak("Iterator not initialized. Call iterator_reset() first.");
    }

    memset(&k, 0, sizeof(DBT));
    memset(&v, 0, sizeof(DBT));

    ret = obj->cursor->get(obj->cursor, &k, &v, DB_NEXT);
    if (ret == DB_NOTFOUND) {
        RETVAL = &PL_sv_undef;
    } else if (ret != 0) {
        croak("next_key: cursor->get failed: %s", db_strerror(ret));
    } else {
        RETVAL = newSVpvn((char *)k.data, k.size);
    }
OUTPUT:
    RETVAL

SV *
each(self)
    SV *self
PREINIT:
    Berk *obj;
    DBT k, v;
    int ret;
    AV *av;
CODE:
    obj = (Berk *)SvIV(SvRV(self));

    if (!obj->cursor) {
        // First call to each() – create cursor
        ret = obj->dbp->cursor(obj->dbp, NULL, &obj->cursor, 0);
        if (ret != 0) {
            croak("each: cursor creation failed: %s", db_strerror(ret));
        }
    }

    memset(&k, 0, sizeof(DBT));
    memset(&v, 0, sizeof(DBT));
    v.flags = DB_DBT_MALLOC;

    ret = obj->cursor->get(obj->cursor, &k, &v, DB_NEXT);
    if (ret == DB_NOTFOUND) {
        obj->cursor->close(obj->cursor);
        obj->cursor = NULL;
        RETVAL = &PL_sv_undef;
    } else if (ret != 0) {
        croak("each: cursor->get failed: %s", db_strerror(ret));
    } else {
        av = newAV();
        av_push(av, newSVpvn((char *)k.data, k.size));
        av_push(av, newSVpvn((char *)v.data, v.size));
        free(v.data);
        RETVAL = newRV_noinc((SV *)av);
    }
OUTPUT:
    RETVAL

int
store(self, key, value)
    SV *self
    SV *key
    SV *value
PREINIT:
    Berk *obj;
    DB *dbp;
    DBT k, v;
    char *kptr, *vptr;
    STRLEN klen, vlen;
    int ret;
CODE:
    obj = (Berk*)SvIV((SV*)SvRV(self));
    dbp = obj->dbp;

    kptr = SvPV(key, klen);
    vptr = SvPV(value, vlen);

    memset(&k, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;

    memset(&v, 0, sizeof(DBT));
    v.data = vptr;
    v.size = vlen;

    ret = dbp->put(dbp, NULL, &k, &v, 0);
    if (ret != 0) {
        croak("DB->store error: %s", db_strerror(ret));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

int
set(self, key, value)
    SV *self
    SV *key
    SV *value
PREINIT:
    Berk *obj;
    DB *dbp;
    DBT k, v;
    char *kptr, *vptr;
    STRLEN klen, vlen;
    int ret;
CODE:
    obj = (Berk*)SvIV((SV*)SvRV(self));
    dbp = obj->dbp;

    kptr = SvPV(key, klen);
    vptr = SvPV(value, vlen);

    memset(&k, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;

    memset(&v, 0, sizeof(DBT));
    v.data = vptr;
    v.size = vlen;

    ret = dbp->put(dbp, NULL, &k, &v, 0);
    if (ret != 0) {
        croak("DB->set error: %s", db_strerror(ret));
    }
    RETVAL = 1;
OUTPUT:
    RETVAL

SV *
fetch(self, key)
    SV *self
    SV *key
PREINIT:
    Berk *obj;
    DB *dbp;
    DBT k, v;
    char *kptr;
    STRLEN klen;
    int ret;
CODE:
    obj = (Berk*)SvIV((SV*)SvRV(self));
    dbp = obj->dbp;

    kptr = SvPV(key, klen);

    memset(&k, 0, sizeof(DBT));
    k.data = kptr;
    k.size = klen;

    memset(&v, 0, sizeof(DBT));
    v.flags = DB_DBT_MALLOC;

    ret = dbp->get(dbp, NULL, &k, &v, 0);
    if (ret == DB_NOTFOUND) {
        RETVAL = &PL_sv_undef;
    }
    else if (ret != 0) {
        croak("DB->fetch error: %s", db_strerror(ret));
    }
    else {
        RETVAL = newSVpvn((char*)v.data, v.size);
        free(v.data);
    }
OUTPUT:
    RETVAL


void
DESTROY(self)
    SV *self
PREINIT:
    Berk *obj;
    int ret;
CODE:
    obj = (Berk *)SvIV(SvRV(self));
    DEBUG_LOG("DESTROY() called");
    if (obj) {
        if (obj->cursor) {
	    DEBUG_LOG("DESTROY() closing cursor");
            obj->cursor->close(obj->cursor);
            obj->cursor = NULL;
        }
        if (obj->dbp) {
	    DEBUG_LOG("DESTROY() closing handle");
            obj->dbp->close(obj->dbp, 0);  // Close DB handle
        }
	DEBUG_LOG("DESTROY() freeing the structure");
        free(obj);  // Free the struct
    }
    DEBUG_LOG("DESTROY() left");
