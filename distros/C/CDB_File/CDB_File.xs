/*

Most of this is reasonably straightforward.  The complications arise
when we are "iterating" over the CDB file, that is to say, using `keys'
or `values' or `each' to retrieve all the data in the file in order.
This interface stores extra data to allow us to track iterations: end
is a pointer to the end of data in the CDB file, and also a flag which
indicates whether we are iterating or not (note that the end of data
occurs at a position >= 2048); curkey is a copy of the current key;
curpos is the file offset of curkey; and fetch_advance is 0 for

    FIRSTKEY, fetch, NEXTKEY, fetch, NEXTKEY, fetch, ...

but 1 for

    FIRSTKEY, NEXTKEY, NEXTKEY, ..., fetch, fetch, fetch, ...

Don't tell the OO Police, but there are actually two different objects
called CDB_File.  One is created by TIEHASH, and accessed by the usual
tied hash methods (FETCH, FIRSTKEY, etc.).  The other is created by new,
and accessed by insert and finish.

In both cases, the object is a blessed reference to a scalar.  The
scalar contains either a struct cdbobj or a struct cdbmakeobj.

It gets a little messy in DESTROY: since this method will automatically
be called for both sorts of object, it distinguishes them by their
different sizes.

*/

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#ifdef WIN32
#define fsync _commit
#endif

#ifdef HASMMAP
#include <sys/mman.h>
#endif

/* We need to whistle up an error number for a file that is not a CDB
file.  The BSDish EFTYPE probably gives the most useful error message;
failing that we'll settle for the Single Unix Specification v2 EPROTO;
and finally the rather inappropriate, but universally(?) implemented,
EINVAL. */
#ifdef EFTYPE
#else
#ifdef EPROTO
#define EFTYPE EPROTO
#else
#define EFTYPE EINVAL
#endif
#endif

#ifdef __cplusplus
}
#endif

#if PERL_VERSION_LE(5,13,7)
  #define CDB_FILE_HAS_UTF8_HASH_MACROS
#endif

#if defined(SV_COW_REFCNT_MAX)
#   define CDB_CAN_COW 1
#else
#   define CDB_CAN_COW 0
#endif

#if CDB_CAN_COW
#    define CDB_DO_COW(sv) STMT_START { SvIsCOW_on(sv); CowREFCNT(sv) = 1; } STMT_END
#else
#    define CDB_DO_COW(sv)
#endif

#define cdb_datapos(c) ((c)->dpos)
#define cdb_datalen(c) ((c)->dlen)

#define SET_FINDER_LEN(s, l) STMT_START { s.len = l; s.hash = 0; } STMT_END

struct t_string_finder {
    char *pv;
    STRLEN len;
    bool is_utf8;
    bool pv_needs_free;
    U32 hash;
};
typedef struct t_string_finder  string_finder;

struct t_cdb {
    PerlIO *fh;   /* */

#ifdef HASMMAP
    char *map;
#endif

    U32 end;    /* If non zero, the file offset of the first byte of hash tables. */
    bool is_utf8; /* will we be reading in utf8 encoded data? If so we'll set SvUTF8 = true; */
    string_finder curkey; /* While iterating: the current key; */
    STRLEN curkey_allocated;
    U32 curpos; /*                  the file offset of the current record. */
    int fetch_advance; /* the kludge */
    U32 size; /* initialized if map is nonzero */
    U32 loop; /* number of hash slots searched under this key */
    U32 khash; /* initialized if loop is nonzero */
    U32 kpos; /* initialized if loop is nonzero */
    U32 hpos; /* initialized if loop is nonzero */
    U32 hslots; /* initialized if loop is nonzero */
    U32 dpos; /* initialized if cdb_findnext() returns 1 */
    U32 dlen; /* initialized if cdb_findnext() returns 1 */
};

typedef struct t_cdb  cdb;

#define CDB_HPLIST 1000

struct cdb_hp { U32 h; U32 p; };

struct cdb_hplist {
    struct cdb_hp hp[CDB_HPLIST];
    struct cdb_hplist *next;
    int num;
};

struct t_cdb_make {
    PerlIO *f;            /* Handle of file being created. */
    bool is_utf8; /* Coerce the PV to utf8 before writing out the data? */
    char *fn;             /* Final name of file. */
    char *fntemp;         /* Temporary name of file. */
    char final[2048];
    char bspace[1024];
    U32 count[256];
    U32 start[256];
    struct cdb_hplist *head;
    struct cdb_hp *split; /* includes space for hash */
    struct cdb_hp *hash;
    U32 numentries;
    U32 pos;
    int fd;
};

typedef struct t_cdb_make cdb_make;

static int cdb_read(cdb *c, char *buf, unsigned int len, U32 pos);

static void writeerror() { croak("Write to CDB_File failed: %s", Strerror(errno)); }

static void readerror() { croak("Read of CDB_File failed: %s", Strerror(errno)); }

static void nomem() { croak("Out of memory!"); }

static inline SV * sv_from_datapos(cdb *c, STRLEN len) {
    SV *sv;
    char *buf;

    sv = newSV(len + 1 + CDB_CAN_COW);
    SvPOK_on(sv);
    CDB_DO_COW(sv);
    if(c->is_utf8)
        SvUTF8_on(sv);
    buf = SvPVX(sv);
    if (cdb_read(c, buf, len, cdb_datapos(c)) == -1)
        readerror();
    buf[len] = '\0';
    SvCUR_set(sv, len);

    return sv;
}

static inline SV * sv_from_curkey (cdb *c) {
    SV* sv;
    sv = newSV(c->curkey.len + 1 + CDB_CAN_COW);
    sv_setpvn(sv, c->curkey.pv, c->curkey.len);
    CDB_DO_COW(sv);
    if(c->is_utf8)
        SvUTF8_on(sv);

    return sv;
}

static int cdb_make_start(cdb_make *c) {
    c->head = 0;
    c->split = 0;
    c->hash = 0;
    c->numentries = 0;
    c->pos = sizeof c->final;
    return PerlIO_seek(c->f, c->pos, SEEK_SET);
}

static int posplus(cdb_make *c, U32 len) {
    U32 newpos = c->pos + len;
    if (newpos < len) {
        errno = ENOMEM; return -1;
    }
    c->pos = newpos;
    return 0;
}

static int cdb_make_addend(cdb_make *c, unsigned int keylen, unsigned int datalen, U32 h) {
    struct cdb_hplist *head;

    head = c->head;
    if (!head || (head->num >= CDB_HPLIST)) {
        New(0xCDB, head, 1, struct cdb_hplist);
        head->num = 0;
        head->next = c->head;
        c->head = head;
    }
    head->hp[head->num].h = h;
    head->hp[head->num].p = c->pos;
    ++head->num;
    ++c->numentries;
    if (posplus(c, 8) == -1)
        return -1;
    if (posplus(c, keylen) == -1)
        return -1;
    if (posplus(c, datalen) == -1)
        return -1;
    return 0;
}

#define CDB_HASHSTART 5381

#define cdb_hashadd(hh, cc) ((hh + (hh << 5)) ^ (unsigned char) cc)

static U32 cdb_hash(char *buf, unsigned int len) {
    U32 h;

    h = CDB_HASHSTART;
    while (len) {
        h = cdb_hashadd(h,*buf++);
        --len;
    }
    return h;
}

static void uint32_pack(char s[4], U32 u) {
    s[0] = u & 255;
    u >>= 8;
    s[1] = u & 255;
    u >>= 8;
    s[2] = u & 255;
    s[3] = u >> 8;
}

static void uint32_unpack(char s[4], U32 *u) {
    U32 result;

    result = (unsigned char) s[3];
    result <<= 8;
    result += (unsigned char) s[2];
    result <<= 8;
    result += (unsigned char) s[1];
    result <<= 8;
    result += (unsigned char) s[0];

    *u = result;
}

static void cdb_findstart(cdb *c) {
    c->loop = 0;
}

#ifdef HASMMAP
static inline char * cdb_map_addr(cdb *c, STRLEN len, U32 pos) {
    if(c->map == NULL) croak("Called cdb_map_addr on a system without mmap");

    if ((pos > c->size) || (c->size - pos < len)) {
        errno = EFTYPE;
        return NULL;
    }
    return c->map + pos;
}
#endif

static int cdb_read(cdb *c, char *buf, unsigned int len, U32 pos) {

#ifdef HASMMAP
    if (c->map) {
        if ((pos > c->size) || (c->size - pos < len)) {
            errno = EFTYPE;
            return -1;
        }
        memcpy(buf, c->map + pos, len);
        return 0;
    }
#endif

    if (PerlIO_seek(c->fh, pos, SEEK_SET) == -1) return -1;
    while (len > 0) {
        int r;
        do
            r = PerlIO_read(c->fh, buf, len);
        while ((r == -1) && (errno == EINTR));
        if (r == -1) return -1;
        if (r == 0) {
            errno = EFTYPE;
            return -1;
        }
        buf += r;
        len -= r;
    }
    return 0;
}

static bool cdb_key_eq (string_finder *left, string_finder *right) {

#if PERL_VERSION_GT(5,13,7)
    if( left->is_utf8 != right->is_utf8 ) {
        if(left->is_utf8)
            return (bytes_cmp_utf8( (const U8 *) right->pv, right->len, (const U8 *) left->pv,  left->len)  == 0);
        else
            return (bytes_cmp_utf8( (const U8 *) left->pv,  left->len,  (const U8 *) right->pv, right->len) == 0);
    }
#endif

    return (left->len == right->len) && memEQ(left->pv, right->pv, right->len);
}

#define CDB_MATCH_BUFFER 256

static int match(cdb *c, string_finder *to_find, U32 pos) {
    string_finder nextkey;

#ifdef HASMMAP
    /* We don't have to allocate any memory if we're using mmap. */
    nextkey.is_utf8 = c->is_utf8;
    SET_FINDER_LEN(nextkey, to_find->len);
    nextkey.pv      = cdb_map_addr(c, to_find->len, pos);
    return cdb_key_eq(&nextkey, to_find);
#else
    /* If we don't have windows, then we have to read the file in */
    int ret;
    int len;
    char static_buffer[CDB_MATCH_BUFFER];

    nextkey.is_utf8 = c->is_utf8;
    SET_FINDER_LEN(nextkey, to_find->len);
    len = nextkey.len;

    /* We only need to malloc a buffer if len >= 256 */
    if(len < CDB_MATCH_BUFFER)
        nextkey.pv = static_buffer;
    else
        Newx(nextkey.pv, len, char);

    if(cdb_read(c, nextkey.pv, len, pos) == -1)
        return -1;

    ret = cdb_key_eq(&nextkey, to_find) ? 1 : 0;

    /* Only free if we had to malloc */
    if (nextkey.pv != static_buffer)
        Safefree(nextkey.pv);

    return ret;
#endif
}

static int cdb_findnext(cdb *c, string_finder *to_find) {
    char buf[8];
    U32 pos;
    U32 u;
    U32 next_key_len;
    
    /* Matt: reset these so if a search fails they are zero'd */
    c->dpos = 0;
    c->dlen = 0;
    if (!c->loop) {
        if(to_find->hash != 0) /* hash cache (except when the value is 0) */
            u = to_find->hash;
        else
            u = to_find->hash = cdb_hash(to_find->pv, to_find->len);


        if (cdb_read(c,buf,8,(u << 3) & 2047) == -1)
            return -1;
        uint32_unpack(buf + 4, &c->hslots);
        if (!c->hslots)
            return 0;
        uint32_unpack(buf,&c->hpos);
        c->khash = u;
        u >>= 8;
        u %= c->hslots;
        u <<= 3;
        c->kpos = c->hpos + u;
    }

    while (c->loop < c->hslots) {
        if (cdb_read(c,buf,8,c->kpos) == -1)
            return -1;
        uint32_unpack(buf + 4,&pos);
        if (!pos)
            return 0;
        c->loop += 1;
        c->kpos += 8;
        if (c->kpos == c->hpos + (c->hslots << 3))
            c->kpos = c->hpos;
        uint32_unpack(buf,&u);
        if (u == c->khash) {
            if (cdb_read(c,buf,8,pos) == -1)
                return -1;
            uint32_unpack(buf, &next_key_len);
            if (next_key_len == to_find->len) {
                switch(match(c, to_find, pos + 8)) {
                    case -1:
                        return -1;
                    case 0:
                        return 0;
                    default:
                        uint32_unpack(buf + 4,&c->dlen);
                        c->dpos = pos + 8 + next_key_len;
                        return 1;
                }
            }
        }
    }

    return 0;
}

static int cdb_find(cdb *c, string_finder *to_find) {
    cdb_findstart(c);
    return cdb_findnext( c, to_find );
}

#define CDB_DEFAULT_BUFFER_LEN 256
#define CDB_MAX_BUFFER_LEN 1024 * 64

static inline void CDB_ASSURE_CURKEY_MEM(cdb *c, STRLEN len) {
    STRLEN newlen;

    /* Nothing to do. We already have enough memory. */
    if (c->curkey_allocated >= len && c->curkey_allocated < CDB_MAX_BUFFER_LEN) return;

    /* What's the new size? */
    if(len < CDB_MAX_BUFFER_LEN && c->curkey_allocated > CDB_MAX_BUFFER_LEN) {
        newlen = (len > CDB_DEFAULT_BUFFER_LEN) ? len : CDB_DEFAULT_BUFFER_LEN;
    }
    else {
        newlen = len - len % 1024  + 1024; /* Grow by a multiple of 1024. */
    }

    if(c->curkey.pv)
        Renew(c->curkey.pv, newlen, char);
    else
        Newx (c->curkey.pv, newlen, char);

    c->curkey.pv[newlen-1] = 0;

    c->curkey_allocated = newlen;
}

static void iter_start(cdb *c) {
    char buf[4];

    c->curpos = 2048;
    if (cdb_read(c, buf, 4, 0) == -1)
        readerror();
    uint32_unpack(buf, &c->end);

    SET_FINDER_LEN(c->curkey, 0);
    c->fetch_advance = 0;
}

static int iter_key(cdb *c) {
    char buf[8];
    U32 klen;

    if (c->curpos < c->end) {
        if (cdb_read(c, buf, 8, c->curpos) == -1)
            readerror();
        uint32_unpack(buf, &klen);

        SET_FINDER_LEN(c->curkey, klen);
        CDB_ASSURE_CURKEY_MEM(c, klen);
        if (cdb_read(c, c->curkey.pv, klen, c->curpos + 8) == -1)
            readerror();
        return 1;
    }
    return 0;
}

static void iter_advance(cdb *c) {
    char buf[8];
    U32 klen, dlen;

    if (cdb_read(c, buf, 8, c->curpos) == -1)
        readerror();
    uint32_unpack(buf, &klen);
    uint32_unpack(buf + 4, &dlen);
    c->curpos += 8 + klen + dlen;
}

static void iter_end(cdb *c) {
    if (c->end != 0) {
        c->end = 0;
        SET_FINDER_LEN(c->curkey, 0);
    }
}

typedef PerlIO * InputStream;

MODULE = CDB_File        PACKAGE = CDB_File    PREFIX = cdb_

PROTOTYPES: DISABLED

 # Some accessor methods.

 # WARNING: I don't really understand enough about Perl's guts (file
 # handles / globs, etc.) to write this code.  I think this is right, and
 # it seems to work, but input from anybody with a deeper
 # understanding would be most welcome.

 # Additional: fixed by someone with a deeper understanding ;-) (Matt Sergeant)

InputStream
cdb_handle(this)
    cdb *        this

    CODE:
        /* here we dup the filehandle, because perl space will try and close
           it when it goes out of scope */
        RETVAL = PerlIO_fdopen(PerlIO_fileno(this->fh), "r");
    OUTPUT:
        RETVAL

U32
cdb_datalen(db)
    cdb *db

    CODE:
        RETVAL = cdb_datalen(db);

    OUTPUT:
        RETVAL

U32
cdb_datapos(db)
    cdb *db

    CODE:
        RETVAL = cdb_datapos(db);

    OUTPUT:
        RETVAL

cdb *
cdb_TIEHASH(CLASS, filename, option_key="", is_utf8=FALSE)
    char *CLASS
    char *filename
    char *option_key
    bool  is_utf8

    PREINIT:
        PerlIO *f;
        bool  utf8_chosen = FALSE;

    CODE:
        if(strlen(option_key) == 4 && strnEQ("utf8", option_key, 4) && is_utf8 )
#ifdef CDB_FILE_HAS_UTF8_HASH_MACROS
            croak("utf8 CDB_Files are not supported below Perl 5.14");
#else
            utf8_chosen = TRUE;
#endif

        Newxz(RETVAL, 1, cdb);
        RETVAL->fh = f = PerlIO_open(filename, "rb");
        RETVAL->is_utf8 = utf8_chosen;

        if (!f)
            XSRETURN_NO;
#ifdef HASMMAP
        {
            struct stat st;
            int fd = PerlIO_fileno(f);

            RETVAL->map = 0;
            if (fstat(fd, &st) == 0) {
                if (st.st_size <= 0xffffffff) {
                    char *x;

                    x = mmap(0, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
                    if (x != (char *)-1) {
                        RETVAL->size = st.st_size;
                        RETVAL->map = x;
                    }
                }
            }
        }
#endif
    OUTPUT:
        RETVAL

SV *
cdb_FETCH(this, k)
    cdb *this
    SV  *k

    PREINIT:
        char buf[8];
        int found;
        string_finder to_find;

    CODE:
        if (!SvOK(k)) {
            XSRETURN_UNDEF;
        }

        to_find.pv = this->is_utf8 ? SvPVutf8(k, to_find.len) : SvPV(k, to_find.len);
        to_find.hash = 0;
        to_find.is_utf8 = this->is_utf8 && SvUTF8(k);

        /* Already advanced to the key we need. */
        if (this->end && cdb_key_eq(&this->curkey, &to_find)) {
            if (cdb_read(this, buf, 8, this->curpos) == -1)
                readerror();
            uint32_unpack(buf + 4, &this->dlen);
            this->dpos = this->curpos + 8 + to_find.len;
            if (this->fetch_advance) {
                iter_advance(this);
                if (!iter_key(this)) {
                    iter_end(this);
                }
            }
            found = 1;
        } else {
            /* Need to find the key first.. */
            cdb_findstart(this);
            found = cdb_findnext(this, &to_find);
            if ((found != 0) && (found != 1)) readerror();
        }

        if (found) {
            U32 dlen;
            dlen = cdb_datalen(this);
            RETVAL = sv_from_datapos(this, dlen);
        }
        else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

HV *
cdb_fetch_all(this)
    cdb *this

    PREINIT:
        U32 dlen;
        SV *keyvalue;
        SV *keysv;
        int found;

    CODE:
        RETVAL = newHV();
        sv_2mortal((SV *)RETVAL);
        iter_start(this);

        while(iter_key(this)) {
            cdb_findstart(this);
            found = cdb_findnext(this, &this->curkey);
            if ((found != 0) && (found != 1))
                readerror();

            dlen = cdb_datalen(this);

            keyvalue = sv_from_datapos(this, dlen);
            keysv    = sv_from_curkey(this);

            if (! hv_store_ent(RETVAL, keysv, keyvalue, 0)) {
                SvREFCNT_dec(keyvalue);
            }
            SvREFCNT_dec(keysv);
            iter_advance(this);
        }
        iter_end(this);

    OUTPUT:
        RETVAL


AV *
cdb_multi_get(this, k)
    cdb *this
    SV  *k

    PREINIT:
        int found;
        U32 dlen;
        SV *x;
        string_finder to_find;

    CODE:
        if (!SvOK(k)) {
            XSRETURN_UNDEF;
        }
        cdb_findstart(this);
        RETVAL = newAV();
        sv_2mortal((SV *)RETVAL);

        to_find.pv = this->is_utf8 ? SvPVutf8(k, to_find.len) : SvPV(k, to_find.len);
        to_find.hash = 0;
        to_find.is_utf8 = SvUTF8(k);

        for (;;) {
            found = cdb_findnext(this, &to_find);
            if ((found != 0) && (found != 1))
                readerror();
            if (!found)
                break;

            dlen = cdb_datalen(this);

            x = sv_from_datapos(this, dlen);
            av_push(RETVAL, x);
        }

    OUTPUT:
        RETVAL

int
cdb_EXISTS(this, k)
    cdb *this
    SV  *k

    PREINIT:
        string_finder to_find;

    CODE:
        if (!SvOK(k)) {
            XSRETURN_NO;
        }

        to_find.pv = this->is_utf8 ? SvPVutf8(k, to_find.len) : SvPV(k, to_find.len);
        to_find.hash = 0;
        to_find.is_utf8 = SvUTF8(k);

        RETVAL = cdb_find(this, &to_find);
        if (RETVAL != 0 && RETVAL != 1)
            readerror();

    OUTPUT:
        RETVAL

void
cdb_DESTROY(db)
    SV *db

    PREINIT:
        cdb *this;

    CODE:
        if (sv_isobject(db) && (SvTYPE(SvRV(db)) == SVt_PVMG) ) {
            this = (cdb*)SvIV(SvRV(db));

        if (this->curkey.pv)
            Safefree(this->curkey.pv);

            iter_end(this);
#ifdef HASMMAP
            if (this->map) {
                munmap(this->map, this->size);
                this->map = 0;
            }
#endif
            PerlIO_close(this->fh); /* close() on O_RDONLY cannot fail */
            Safefree(this);
        }

SV *
cdb_FIRSTKEY(this)
    cdb *this

    CODE:
        iter_start(this);
        if (iter_key(this)) {
            RETVAL = sv_from_curkey(this);
        } else {
            XSRETURN_UNDEF; /* empty database */
        }
    OUTPUT:
        RETVAL

SV *
cdb_NEXTKEY(this, k)
    cdb *this
    SV  *k

    PREINIT:
        string_finder to_find;

    CODE:
        if (!SvOK(k)) {
            XSRETURN_UNDEF;
        }

        to_find.pv = this->is_utf8 ? SvPVutf8(k, to_find.len) : SvPV(k, to_find.len);
        to_find.hash = 0;
        to_find.is_utf8 = SvUTF8(k);

        /* Sometimes NEXTKEY gets called before FIRSTKEY if the hash
         * gets re-tied so we call iter_start() anyway here */
        if (this->end == 0 || !cdb_key_eq(&this->curkey, &to_find))
            iter_start(this);
        iter_advance(this);
        if (iter_key(this)) {
            CDB_ASSURE_CURKEY_MEM(this, this->curkey.len);
            RETVAL = sv_from_curkey(this);
        } else {
            iter_start(this);
            (void)iter_key(this); /* prepare curkey for FETCH */
            this->fetch_advance = 1;
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

cdb_make *
cdb_new(CLASS, fn, fntemp, option_key="", is_utf8=FALSE)
    char *        CLASS
    char *        fn
    char *        fntemp
    char *        option_key
    bool          is_utf8;

    PREINIT:
        cdb_make *cdbmake;
        bool  utf8_chosen = FALSE;

    CODE:
        if(strlen(option_key) == 4 && strnEQ("utf8", option_key, 4) && is_utf8 )
#ifdef CDB_FILE_HAS_UTF8_HASH_MACROS
        croak("utf8 CDB_Files are not supported below Perl 5.14");
#else
        utf8_chosen = TRUE;
#endif

        Newxz(cdbmake, 1, cdb_make);
        cdbmake->f = PerlIO_open(fntemp, "wb");
        cdbmake->is_utf8 = utf8_chosen;

        if (!cdbmake->f) XSRETURN_UNDEF;

        if (cdb_make_start(cdbmake) < 0) XSRETURN_UNDEF;

        /* Oh, for referential transparency. */
        New(0, cdbmake->fn, strlen(fn) + 1, char);
        New(0, cdbmake->fntemp, strlen(fntemp) + 1, char);
        strcpy(cdbmake->fn, fn);
        strcpy(cdbmake->fntemp, fntemp);

        CLASS = "CDB_File::Maker"; /* OK, so this is a hack */

        RETVAL = cdbmake;

    OUTPUT:
        RETVAL

MODULE = CDB_File    PACKAGE = CDB_File::Maker    PREFIX = cdbmaker_

void
cdbmaker_DESTROY(sv)
        SV *   sv

        PREINIT:
        cdb_make *  this;

        CODE:
            if (sv_isobject(sv) && (SvTYPE(SvRV(sv)) == SVt_PVMG) ) {
                this = (cdb_make*)SvIV(SvRV(sv));
                if(this->f) {
                    PerlIO_close(this->f);
                }
                Safefree(this);
            }

void
cdbmaker_insert(this, ...)
    cdb_make *        this

    PREINIT:
        char *kp, *vp, packbuf[8];
        int  x;
        bool is_utf8;
        STRLEN klen, vlen;
        U32 h;
        SV *k;
        SV *v;

    PPCODE:
        is_utf8 = this->is_utf8;

        for (x = 1; x < items; x += 2) {
            k = ST(x);
            v = ST(x+1);

            if(!SvOK(k)) {
                Perl_warn(aTHX_ "Use of uninitialized value in hash key");
                k = sv_2mortal(newSVpv("", 0));
            }

            if(!SvOK(v)) {
                Perl_warn(aTHX_ "undef values cannot be stored in CDB_File. Storing an empty string instead");
                v = sv_2mortal(newSVpv("", 0));
            }

            kp = is_utf8 ? SvPVutf8(k, klen) : SvPV(k, klen);
            vp = is_utf8 ? SvPVutf8(v, vlen) : SvPV(v, vlen);

            uint32_pack(packbuf, klen);
            uint32_pack(packbuf + 4, vlen);

            if (PerlIO_write(this->f, packbuf, 8) < 8)
                writeerror();

            h = cdb_hash(kp, klen);
            if (PerlIO_write(this->f, kp, klen) < klen)
                writeerror();
            if (PerlIO_write(this->f, vp, vlen) < vlen)
                writeerror();

            if (cdb_make_addend(this, klen, vlen, h) == -1)
                nomem();
        }

int
cdbmaker_finish(this)
    cdb_make *this

    PREINIT:
        char buf[8];
        int i;
        U32 len, u;
        U32 count, memsize, where;
        struct cdb_hplist *x, *prev;
        struct cdb_hp *hp;

    CODE:
        for (i = 0; i < 256; ++i)
            this->count[i] = 0;

        for (x = this->head; x; x = x->next) {
            i = x->num;
            while (i--) {
                ++this->count[255 & x->hp[i].h];
            }
        }

        memsize = 1;
        for (i = 0; i < 256; ++i) {
            u = this->count[i] * 2;
            if (u > memsize)
                memsize = u;
        }

        memsize += this->numentries; /* no overflow possible up to now */
        u = (U32) 0 - (U32) 1;
        u /= sizeof(struct cdb_hp);
        if (memsize > u) {
            errno = ENOMEM;
            XSRETURN_UNDEF;
        }

        New(0xCDB, this->split, memsize, struct cdb_hp);

        this->hash = this->split + this->numentries;

        u = 0;
        for (i = 0; i < 256; ++i) {
            u += this->count[i]; /* bounded by numentries, so no overflow */
            this->start[i] = u;
        }

        prev = 0;
        for (x = this->head; x; x = x->next) {
            i = x->num;
            while (i--) {
                this->split[--this->start[255 & x->hp[i].h]] = x->hp[i];
            }

            if (prev)
                Safefree(prev);
            prev = x;
        }

        if (prev)
            Safefree(prev);

        for (i = 0; i < 256; ++i) {
            count = this->count[i];

            len = count + count; /* no overflow possible */
            uint32_pack(this->final + 8 * i, this->pos);
            uint32_pack(this->final + 8 * i + 4, len);

            for (u = 0; u < len; ++u) {
                this->hash[u].h = this->hash[u].p = 0;
            }

            hp = this->split + this->start[i];
            for (u = 0; u < count; ++u) {
                where = (hp->h >> 8) % len;
                while (this->hash[where].p) {
                    if (++where == len)
                        where = 0;
                }

                this->hash[where] = *hp++;
            }

            for (u = 0; u < len; ++u) {
                uint32_pack(buf, this->hash[u].h);
                uint32_pack(buf + 4, this->hash[u].p);

                if (PerlIO_write(this->f, buf, 8) == -1)
                    XSRETURN_UNDEF;

                if (posplus(this, 8) == -1)
                    XSRETURN_UNDEF;
            }
        }

        Safefree(this->split);

        if (PerlIO_flush(this->f) == EOF) writeerror();
        PerlIO_rewind(this->f);

        if (PerlIO_write(this->f, this->final, sizeof this->final) < sizeof this->final)
            writeerror();

        if (PerlIO_flush(this->f) == EOF)
            writeerror();

        if (fsync(PerlIO_fileno(this->f)) == -1)
            XSRETURN_NO;

        if (PerlIO_close(this->f) == EOF)
            XSRETURN_NO;
         this->f=0;

        if (rename(this->fntemp, this->fn)) {
            croak("Failed to rename %s to %s.", this->fntemp, this->fn);
        }

        Safefree(this->fn);
        Safefree(this->fntemp);

        RETVAL = 1;

    OUTPUT:
        RETVAL
