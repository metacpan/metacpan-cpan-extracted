
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "cdb.h"

#ifdef __cplusplus
}
#endif

/* alias */
#define DOOPEN          1
#define DOCREATE        2
#define DOUPDATE        4
#define DOLOAD          8
#define WITHTEMP        (DOCREATE | DOUPDATE)
#define WITHOPEN        (DOOPEN | DOUPDATE | DOLOAD)
#define READONLY        (DOOPEN | DOLOAD)

/* opts */
#define EACH_INITIALIZED 1
#define COMMITTED       2
#define DIED            4

/* get mode */
#define DOGETALL        1
#define DOGETLAST       2

/* methods */
#define METHOD_GET      1
#define METHOD_GETALL   2
#define METHOD_KEYS     4
#define METHOD_EACH     8
#define METHOD_ADD      16
#define METHOD_INSERT   32
#define METHOD_EXISTS   64
#define METHOD_FINISH   128


/* <cdb_make_free is not public - copy from cdb_ini.h and cdb_make.c> */
struct cdb_rec {
  unsigned hval;
  unsigned rpos;
};

struct cdb_rl {
  struct cdb_rl *next;
  unsigned cnt;
  struct cdb_rec rec[254];
};
static void
cdb_make_free(struct cdb_make *cdbmp)
{
  unsigned t;
  for(t = 0; t < 256; ++t) {
    struct cdb_rl *rl = cdbmp->cdb_rec[t];
    while(rl) {
      struct cdb_rl *tm = rl;
      rl = rl->next;
      free(tm);
    }
  }
}
/* </cdb_make_free is not public - copy from cdb_int.h and cdb_make.c> */

#define GROWIFNEEDED(self, var, len, bufsize) if (len > bufsize) { \
                                                Renew(var, len + 1, char); \
                                                if ( var == NULL ) { \
                                                     memerror(self, len + 1); \
                                                }; \
                                                bufsize = len; \
                                              };

#define MAKESV(var, len)    SV *var = sv_newmortal(); \
                            SvUPGRADE( var, SVt_PV ); \
                            (void)SvPOK_only( var ); \
                            SvGROW( var, len + 1 ); \
                            SvCUR_set( var, len );

#define PUSHWITHNULL(var,len)   SvPV(var, PL_na)[len] = '\0'; \
                                XPUSHs( var );

#define ALREADY_COMMITTED croak("Database changes already committed")
#define READ_ONLY_MODE croak("Database opened in read only mode")
#define FATAL_ERROR croak("Database unstable - cannot continue")
#define CREATE_ONLY_MODE croak("Database opened in create only mode")

struct t_cdb {
    char *fn;     /* file name */
    char *fntemp;    /* tempfile name */
    PerlIO *fd;   /* file descriptor */
    PerlIO *fdtemp;    /* tempfile descriptor */
    struct cdb cdb;    /* cdb struct */
    struct cdb_make cdbm;    /* cdb_make struct */
    int alias;    /* summoned to do */
    int opts;    /* options */
    unsigned int curpos;    /* current position in file */
    int dend;    /* end position in file */
    struct {     /* container for allocated memory */
        unsigned char *buf;
        char *key;
        char *val;
    } mem;
};

typedef struct t_cdb CDB_TinyCDB;

static void memfree ( CDB_TinyCDB * self ) {
    if ( self->mem.buf ) { Safefree(self->mem.buf); self->mem.buf = 0; }
    if ( self->mem.key ) { Safefree(self->mem.key); self->mem.key = 0; }
    if ( self->mem.val ) { Safefree(self->mem.val); self->mem.val = 0; }
}
static void fileerror(CDB_TinyCDB * self, char *op, char *fn) {
    memfree(self);
    self->opts |= DIED;
    croak("Unable to %s file %s: %s", op, fn, Strerror(errno));
}
static void memerror(CDB_TinyCDB * self, const int size) {
    memfree(self);
    self->opts |= DIED;
    croak("Unable to allocate %d bytes of memory", size);
}

static void assert_status(CDB_TinyCDB * self, const int method) {
    if ( self->opts & DIED ) FATAL_ERROR;
    switch (method) {
        case METHOD_GET:
        case METHOD_GETALL:
        case METHOD_KEYS:
        case METHOD_EACH:
            if (self->alias == DOCREATE) {
                CREATE_ONLY_MODE;
            }
            break;
        case METHOD_ADD:
        case METHOD_INSERT:
            if ( self->alias & WITHTEMP ) {
                if ( self->opts & COMMITTED ) {
                    ALREADY_COMMITTED;
                }
            } else {
                READ_ONLY_MODE;
            } 
            break;
        case METHOD_FINISH:
            if ( ! ( self->alias & WITHTEMP ) ) {
                READ_ONLY_MODE;
            }
            break;
        case METHOD_EXISTS:
            if (self->alias == DOCREATE && self->opts & COMMITTED) {
                ALREADY_COMMITTED;
            }
            break;
    }
}

static void commit( CDB_TinyCDB * self, const int save_changes, const int reopen ) {
    if (self->opts & COMMITTED) return;
    self->opts |= COMMITTED;

    if ( self->alias & WITHOPEN ) {
        if (self->alias & DOLOAD) {
            cdb_free(&self->cdb);
        }
        if ( PerlIO_error( self->fd ) ) {
            fileerror(self, "close", self->fn);
        }
        PerlIO_close(self->fd);
    }
    if ( self->alias & WITHTEMP ) {
        if ( save_changes ) {
            if ( cdb_make_finish(&self->cdbm) != 0 ) {
                fileerror(self, "commit changes", self->fntemp);
            };
        } else {
            cdb_make_free(&self->cdbm);
        };
        if ( PerlIO_close(self->fdtemp) != 0 ) {
            fileerror(self, "close", self->fntemp);
        };

        if ( save_changes ) {
            if ( rename(self->fntemp, self->fn) != 0 ) {
                fileerror(self, "replace", self->fn);
            };

            if ( reopen  && ! (self->alias == DOCREATE)) {
                self->fd = PerlIO_open(self->fn, "rb");
                if ( ! self->fd ) {
                    fileerror(self, "reopen", self->fn);
                }
                if (self->alias & DOLOAD) { /* mmap to memory whole file */
                    cdb_init(&self->cdb, PerlIO_fileno( self->fd ));
                }
            }
        } else {
            if ( unlink(self->fntemp) != 0 ) {
                fileerror(self, "unlink", self->fntemp);
            };
        }
    };
}

static int perlio_bread(PerlIO *fd, void *buf, int len) {
    int l;
    while (len > 0) {
        do {
            l = PerlIO_read(fd, buf, len);
        } while (l < 0 && errno == EINTR);

        if (l <= 0) {
            if (!l) {
                errno = EIO;
            }
            return -1;
        }
        buf = (char*)buf + l;
        len -= l;
    }
    return 0;
}

MODULE = CDB::TinyCDB        PACKAGE = CDB::TinyCDB
PROTOTYPES: ENABLE


CDB_TinyCDB *
open(CLASS, ...)
    char * CLASS
    ALIAS:
        load = DOLOAD
    INIT:
        if ( sv_isobject( ST(0) ) && (SvTYPE(SvRV(ST(0))) == SVt_PVMG) ) {
            croak("%s is already blessed\n", SvPV(ST(0), PL_na));
        }
    CODE:
    {
        int mode = 0;
        if ( items == 4) {
            char *for_method = SvPV( ST(2), PL_na);
            if ( strEQ(for_method, "for_update") ) {
                mode |= DOUPDATE;
            } else {
                croak("Invalid mode %s", for_method);
            }
        } else if ( items != 2 ) {
            croak("Invalid numbers of arguments");
        }

        Newx(RETVAL, 1, CDB_TinyCDB);

        RETVAL->alias = mode | ( ix ? ix : DOOPEN );

        RETVAL->fn = savepv( SvPV( ST(1), PL_na ) );
        RETVAL->fntemp = 0;
        RETVAL->curpos = 0;
        RETVAL->opts = 0;
        RETVAL->mem.buf = 0;
        RETVAL->mem.key = 0;
        RETVAL->mem.val = 0;

        if ( RETVAL->alias & WITHOPEN ) {
            RETVAL->fd = PerlIO_open(RETVAL->fn, "rb");
            if ( ! RETVAL->fd ) {
                fileerror(RETVAL, "open", RETVAL->fn);
            }
            if (RETVAL->alias & DOLOAD) { 
                cdb_init(&RETVAL->cdb, PerlIO_fileno( RETVAL->fd ));
            }
        }
        if (RETVAL->alias & WITHTEMP) { 
            RETVAL->fntemp = savepv( SvPV( ST(3), PL_na ) );
            RETVAL->fdtemp = PerlIO_open(RETVAL->fntemp, "w+b");

            if ( ! RETVAL->fdtemp ) {
                fileerror(RETVAL, "create", RETVAL->fn);
            };
            cdb_make_start(&RETVAL->cdbm, PerlIO_fileno( RETVAL->fdtemp ));

            unsigned int kbufsize = 2048, vbufsize = 2048;
            unsigned int klen = 0, vlen = 0, curpos = 0;


            Newx(RETVAL->mem.key, kbufsize + 1, char);
            Newx(RETVAL->mem.val, vbufsize + 1, char);

            if (RETVAL->alias & DOUPDATE) {

                if (RETVAL->alias & DOLOAD) { 

                    cdb_seqinit( &curpos, &RETVAL->cdb );
                    while ( cdb_seqnext(&curpos, &RETVAL->cdb) > 0 ) {
                        klen = cdb_keylen( &RETVAL->cdb );
                        vlen = cdb_datalen( &RETVAL->cdb );

                        GROWIFNEEDED( RETVAL, RETVAL->mem.key, klen, kbufsize );
                        GROWIFNEEDED( RETVAL, RETVAL->mem.val, vlen, vbufsize );

                        cdb_read( &RETVAL->cdb, RETVAL->mem.key, klen, cdb_keypos(&RETVAL->cdb) );
                        cdb_read( &RETVAL->cdb, RETVAL->mem.val, vlen, cdb_datapos(&RETVAL->cdb) );

                        if ( cdb_make_add(&RETVAL->cdbm,
                                RETVAL->mem.key, klen,
                                RETVAL->mem.val, vlen
                            ) < 0
                        ) {
                            fileerror(RETVAL, "update", RETVAL->fntemp);
                        }
                    }
                } else { 
                    unsigned int bytes, dend;

                    Newx(RETVAL->mem.buf, 2048, unsigned char); 

                    PerlIO_rewind( RETVAL->fd );
                    bytes = PerlIO_read( RETVAL->fd, RETVAL->mem.buf, 2048 );

                    if ( bytes == 2048 ) {
                        dend = cdb_unpack(RETVAL->mem.buf);
                        curpos += bytes;

                        while ( curpos < dend - 8) {
                            bytes = PerlIO_read( RETVAL->fd, RETVAL->mem.buf, 8 );
                            if ( bytes != 8 ) {
                                fileerror(RETVAL, "read", RETVAL->fn);
                            }
                            curpos += bytes;

                            klen = cdb_unpack(RETVAL->mem.buf);
                            vlen = cdb_unpack(RETVAL->mem.buf + 4);

                            if (dend - klen < curpos || dend - vlen < curpos + klen) {
                                fileerror(RETVAL, "read", RETVAL->fn);
                            }

                            GROWIFNEEDED( RETVAL, RETVAL->mem.key, klen, kbufsize );

                            bytes = PerlIO_read( RETVAL->fd, RETVAL->mem.key, klen );
                            if (bytes != klen) {
                                fileerror(RETVAL, "read", RETVAL->fn);
                            };
                            curpos += bytes;

                            GROWIFNEEDED( RETVAL, RETVAL->mem.val, vlen, vbufsize );

                            bytes = PerlIO_read( RETVAL->fd, RETVAL->mem.val, vlen );
                            if (bytes != vlen) {
                                fileerror(RETVAL, "read", RETVAL->fn);
                            };
                            curpos += bytes;

                            if ( cdb_make_add(&RETVAL->cdbm,
                                    RETVAL->mem.key, klen,
                                    RETVAL->mem.val, vlen
                                ) < 0
                            ) {
                                fileerror(RETVAL, "update", RETVAL->fntemp);
                            }
                        };
                    } else {
                        fileerror(RETVAL, "read", RETVAL->fn);
                    }
                    PerlIO_rewind( RETVAL->fd );
                    if ( PerlIO_error( RETVAL->fd ) )
                        fileerror(RETVAL, "set position", RETVAL->fn);
                }
            }

        }
        memfree( RETVAL );
    }
    OUTPUT:
        RETVAL

CDB_TinyCDB *
create(CLASS, fn, fntemp)
    char * CLASS
    char * fn
    char * fntemp
    INIT:
        if ( sv_isobject( ST(0) ) && (SvTYPE(SvRV(ST(0))) == SVt_PVMG )) {
            croak("%s is already blessed\n", SvPV(ST(0), PL_na));
        }
    CODE:
    {
        Newx(RETVAL, 1, CDB_TinyCDB);

        RETVAL->alias = DOCREATE;

        RETVAL->fn = savepv( fn );
        RETVAL->fntemp = savepv( fntemp );
        RETVAL->curpos = 0;
        RETVAL->opts = 0;
        RETVAL->mem.buf = 0;
        RETVAL->mem.key = 0;
        RETVAL->mem.val = 0;

        RETVAL->fdtemp = PerlIO_open(fntemp, "w+b");

        if ( ! RETVAL->fdtemp ) {
            fileerror(RETVAL, "create", fn);
        };
        cdb_make_start(&RETVAL->cdbm, PerlIO_fileno( RETVAL->fdtemp ));
    }
    OUTPUT:
        RETVAL


void
get(self, key)
    CDB_TinyCDB *self
    char *key
    INIT:
        assert_status( self, METHOD_GET );
    PPCODE:
    {
        unsigned int vlen = 0;
        STRLEN klen = strlen(key);

        if (self->alias & DOLOAD) { /* tinyfile whole in memory */
            if (cdb_find(&self->cdb, key, klen) > 0) {
                vlen = cdb_datalen( &self->cdb ); /* length of data */

                MAKESV( val, vlen );
                if ( cdb_read( &self->cdb, SvPVX(val), vlen, cdb_datapos( &self->cdb )) < 0 ) {
                    fileerror(self, "read", self->fn);
                };
                PUSHWITHNULL( val, vlen );
            };
        } else {
            if ( cdb_seek(PerlIO_fileno(self->fd), key, klen, &vlen) > 0 ) {
                MAKESV( val, vlen );
                if ( cdb_bread( PerlIO_fileno(self->fd), SvPVX(val), vlen ) < 0)  {
                    fileerror(self, "read", self->fn);
                };
                XPUSHs( sv_2mortal(newSVpvn(self->mem.val, vlen)) );
                PUSHWITHNULL( val, vlen );
            };
        };
    }

int
exists(self, key)
    CDB_TinyCDB *self
    char *key
    INIT:
        assert_status( self, METHOD_EXISTS );
    CODE:
    {
        STRLEN klen = strlen(key);

        if (self->alias & WITHTEMP && !( self->opts & COMMITTED)) { /* for_create | for_update | create */
            RETVAL = cdb_make_exists(&self->cdbm, key, klen);
            if ( RETVAL < 0 ) {
                fileerror(self, "read", self->fntemp);
            }
        } else {
            if (self->alias & DOLOAD) { /* tinyfile whole in memory */
                RETVAL = cdb_find(&self->cdb, key, klen);
            } else {
                unsigned int vlen;
                RETVAL = cdb_seek(PerlIO_fileno(self->fd), key, klen, &vlen);
            };

            if ( RETVAL < 0 ) {
                fileerror(self, "read", self->fn);
            }
        }
    }
    OUTPUT:
        RETVAL


void
getall(self, key)
    CDB_TinyCDB *self
    char *key
    ALIAS:
        getlast = DOGETLAST
    INIT:
        assert_status( self, METHOD_GETALL );
    PPCODE:
    {
        unsigned int kbufsize = 2048;
        unsigned int klen = 0, vlen = 0;
        unsigned int lastpos = 0, lastvlen = 0;
        STRLEN searchklen = strlen(key);

        int mode = ix ? ix : DOGETALL;

        if (self->alias & DOLOAD) { /* tinyfile whole in memory */
            struct cdb_find cdbf;

            cdb_findinit( &cdbf, &self->cdb, key, searchklen );
            while ( cdb_findnext(&cdbf) > 0 ) {
                vlen = cdb_datalen(&self->cdb); /* length of data */
                lastpos = cdb_datapos(&self->cdb);

                if ( mode == DOGETALL ) {
                    MAKESV( val, vlen );

                    if (cdb_read(&self->cdb, SvPVX(val), vlen, lastpos) < 0 ) {
                        fileerror(self, "read", self->fn);
                    }

                    PUSHWITHNULL( val, vlen );
                }
            }
            if ( mode == DOGETLAST && lastpos ) {
                MAKESV( val, vlen );
                if (cdb_read(&self->cdb, SvPVX(val), vlen, lastpos) < 0 ) {
                    fileerror(self, "read", self->fn);
                }
                PUSHWITHNULL( val, vlen );
            }
        } else { /* open */
            unsigned int bytes, dend, curpos = 0;
            Off_t prevpos = PerlIO_tell( self->fd );

            Newx(self->mem.buf, kbufsize + 1, unsigned char); /* allocate memory */
            Newx(self->mem.key, kbufsize + 1, char); /* allocate memory */

            PerlIO_rewind( self->fd );
            bytes = PerlIO_read( self->fd, self->mem.buf, 2048 );

            if ( bytes == 2048 ) {
                dend = cdb_unpack(self->mem.buf);
                curpos += bytes;

                while ( curpos < dend - 8) {
                    bytes = PerlIO_read( self->fd, self->mem.buf, 8 );
                    if ( bytes != 8 )
                        fileerror(self, "read", self->fn);
                    curpos += bytes;

                    klen = cdb_unpack(self->mem.buf);
                    vlen = cdb_unpack(self->mem.buf + 4);

                    if (dend - klen < curpos || dend - vlen < curpos + klen)
                        fileerror(self, "read", self->fn);

                    GROWIFNEEDED( self, self->mem.key, klen, kbufsize );

                    bytes = PerlIO_read( self->fd, self->mem.key, klen );
                    if (bytes != klen) {
                        fileerror(self, "read", self->fn);
                    };
                    curpos += bytes;
                    self->mem.key[klen] = '\0';

                    if ( klen == searchklen
                        && strnEQ( self->mem.key, key, klen )
                    ) {
                        lastpos = curpos;
                        lastvlen = vlen;

                        if ( mode == DOGETALL ) {
                            MAKESV( val, vlen );
                            if ( perlio_bread( self->fd, SvPVX(val), vlen ) < 0)  {
                                fileerror(self, "read", self->fn);
                            };
                            PUSHWITHNULL( val, vlen );
                        } else {
                            PerlIO_seek(self->fd, vlen, SEEK_CUR);
                        }
                    } else {
                        PerlIO_seek(self->fd, vlen, SEEK_CUR);
                    }
                    curpos += vlen;
                };
            } else {
                fileerror(self, "read", self->fn);
            }

            if ( mode == DOGETLAST && lastpos ) {
                PerlIO_seek( self->fd, lastpos, SEEK_SET );
                MAKESV( val, lastvlen );
                if ( perlio_bread( self->fd, SvPVX(val), lastvlen ) < 0)  {
                    fileerror(self, "read", self->fn);
                };
                PUSHWITHNULL( val, lastvlen );
            }

            /* go back to original position in file */
            PerlIO_seek( self->fd, prevpos, SEEK_SET );
            if ( PerlIO_error( self->fd ) )
                fileerror(self, "set position", self->fn);
        }
        memfree( self );
    }

void
each(self)
    CDB_TinyCDB *self
    INIT:
        assert_status( self, METHOD_EACH );
    PPCODE:
    {
        unsigned int klen = 0, vlen = 0;
        unsigned int kbufsize = 2048;
        int keep_looping = 1;

        if ( self->alias & DOLOAD ) { /* load */
            if ( !( self->opts & EACH_INITIALIZED ) ) {
                self->curpos = 0;
                cdb_seqinit( &self->curpos, &self->cdb );
                self->opts |= EACH_INITIALIZED;
            }
            while ( keep_looping-- ) {
                if ( cdb_seqnext(&self->curpos, &self->cdb) > 0 ) {
                    klen = cdb_keylen( &self->cdb );
                    vlen = cdb_datalen( &self->cdb );

                    if ( klen ) {
                        MAKESV( key, klen );
                        cdb_read( &self->cdb, SvPVX(key), klen, cdb_keypos(&self->cdb) );
                        PUSHWITHNULL( key, klen );

                        MAKESV( val, vlen );
                        cdb_read( &self->cdb, SvPVX(val), vlen, cdb_datapos(&self->cdb) );
                        PUSHWITHNULL( val, vlen );
                    } else {
                        keep_looping++;
                    }
                } else {
                    self->opts &= ~EACH_INITIALIZED;
                }
            }
        } else { /* open */
            unsigned int bytes;
            unsigned int klen, vlen;
            Newx(self->mem.buf, kbufsize + 1, unsigned char); /* allocate memory */

            if ( !( self->opts & EACH_INITIALIZED ) ) {
                self->curpos = 0;
                PerlIO_rewind( self->fd );
                self->opts |= EACH_INITIALIZED;
                bytes = PerlIO_read( self->fd, self->mem.buf, 2048 );
                if ( bytes == 2048 ) {
                    self->dend = cdb_unpack(self->mem.buf);
                } else {
                    fileerror(self, "read", self->fn);
                }
                self->curpos += bytes;
            }

            while ( keep_looping-- ) {
                if ( self->curpos < self->dend - 8) {
                    bytes = PerlIO_read( self->fd, self->mem.buf, 8 );
                    if ( bytes != 8 ) {
                        fileerror(self, "read", self->fn);
                    }
                    self->curpos += bytes;

                    klen = cdb_unpack(self->mem.buf);
                    vlen = cdb_unpack(self->mem.buf + 4);

                    if (self->dend - klen < self->curpos || self->dend - vlen < self->curpos + klen)
                        fileerror(self, "read", self->fn);

                    if ( klen ) {
                        MAKESV( key, klen );
                        if ( perlio_bread( self->fd, SvPVX(key), klen ) < 0)  {
                            fileerror(self, "read", self->fn);
                        };
                        self->curpos += klen;

                        PUSHWITHNULL( key, klen );

                        MAKESV( val, vlen );
                        if ( perlio_bread( self->fd, SvPVX(val), vlen ) < 0)  {
                            fileerror(self, "read", self->fn);
                        };
                        self->curpos += vlen;

                        PUSHWITHNULL( val, vlen );
                    } else {
                        /* skip nulled out records (from replace0) */
                        self->curpos += klen + vlen;
                        PerlIO_seek(self->fd, klen + vlen, SEEK_CUR);
                        keep_looping++;
                    }
                } else {
                    self->opts &= ~EACH_INITIALIZED;
                };
            }
            if ( PerlIO_error( self->fd ) )
                fileerror(self, "close", self->fn);
        }
        memfree( self );
    }



void
keys(self)
    CDB_TinyCDB *self
    INIT:
        assert_status( self, METHOD_KEYS );
    PPCODE:
    {
        unsigned int curpos = 0;
        unsigned int klen = 0, kbufsize = 2048;

        if ( self->alias & DOLOAD ) { /* load */

            cdb_seqinit( &curpos, &self->cdb );
            while ( cdb_seqnext(&curpos, &self->cdb) > 0 ) {
                klen = cdb_keylen( &self->cdb );

                if ( ! klen ) continue;

                MAKESV( key, klen );
                cdb_read( &self->cdb, SvPVX(key), klen, cdb_keypos(&self->cdb) );
                PUSHWITHNULL( key, klen );
            }
        } else { /* open */
            unsigned int bytes, dend;
            unsigned int klen, vlen;
            Newx(self->mem.buf, kbufsize + 1, unsigned char); /* allocate memory */

            Off_t prevpos = PerlIO_tell( self->fd );
            PerlIO_rewind( self->fd );
            bytes = PerlIO_read( self->fd, self->mem.buf, 2048 );

            if ( bytes == 2048 ) {
                dend = cdb_unpack(self->mem.buf);

                curpos += bytes;

                while ( curpos < dend - 8) {
                    bytes = PerlIO_read( self->fd, self->mem.buf, 8 );
                    if ( bytes != 8 )
                        fileerror(self, "read", self->fn);
                    curpos += bytes;

                    klen = cdb_unpack(self->mem.buf);
                    vlen = cdb_unpack(self->mem.buf + 4);

                    if (dend - klen < curpos || dend - vlen < curpos + klen)
                        fileerror(self, "read", self->fn);

                    if ( klen > 0 ) {
                        MAKESV( key, klen );
                        if ( perlio_bread( self->fd, SvPVX(key), klen ) < 0 )  {
                            fileerror(self, "read", self->fn);
                        };
                        curpos += klen;

                        PUSHWITHNULL( key, klen );
                    }
                    curpos += vlen;
                    PerlIO_seek(self->fd, vlen, SEEK_CUR);
                };
            } else {
                fileerror(self, "read", self->fn);
            }
            /* go back to original position in file */
            PerlIO_seek( self->fd, prevpos, SEEK_SET );
            if ( PerlIO_error( self->fd ) )
                fileerror(self, "set position", self->fn);
        }
        memfree( self );
    }

int
put_add(self, ...)
    CDB_TinyCDB *self
    ALIAS:
        put_replace  = CDB_PUT_REPLACE
        put_replace0 = CDB_PUT_REPLACE0
        put_warn     = CDB_PUT_WARN
    INIT:
        assert_status( self, METHOD_ADD );
    CODE:
    {
        char *key, *val;
        STRLEN klen, vlen;
        int mode, result, i;

        mode = ix ? ix : CDB_PUT_ADD;
        RETVAL = 0;

        for ( i = 1; i < items; i += 2 ) {
            key = SvPV( ST(i), klen );
            val = SvPV( ST(i+1), vlen );

            result = cdb_make_put(&self->cdbm, key, klen, val, vlen, mode);
            if ( result < 0 ) {
                fileerror(self, "update", self->fntemp);
            } else if ( result > 0 && mode == CDB_PUT_WARN) {
                warn("Key %s already exists - added anyway", key);
            }
            if ( mode == CDB_PUT_ADD || mode == CDB_PUT_WARN) {
                RETVAL++;
            } else {
                RETVAL += result;
            };
        };
    }
    OUTPUT:
        RETVAL

int
put_insert(self, key, val)
    CDB_TinyCDB *self
    char *key
    char *val
    INIT:
        assert_status( self, METHOD_INSERT );
    CODE:
    {
        RETVAL = cdb_make_put(&self->cdbm, key, strlen(key), val, strlen(val), CDB_PUT_INSERT);
        if ( RETVAL < 0 ) {
            fileerror(self, "update", self->fntemp);
        } else if ( RETVAL > 0) {
            croak("Unable to insert new record - key exists");
        } else {
            RETVAL++;
        }
    }
    OUTPUT:
        RETVAL



void
finish( self, ... )
    CDB_TinyCDB *self
    INIT:
        assert_status( self, METHOD_FINISH );
    PPCODE:
    {
        int save_changes = 1;
        int reopen       = 1;
        char *key;
        STRLEN klen;
        int i;

        for ( i = 1; i < items; i += 2 ) {
            key = SvPVx( ST(i), klen);
            if ( strEQ(key, "save_changes") ) {
                save_changes = SvTRUE(ST(i+1)) ? 1 : 0;
            } else if ( strEQ(key, "reopen") ) {
                reopen = SvTRUE(ST(i+1)) ? 1 : 0;
            } else {
                croak("Invalid option %s", key);
            }
        }
        commit( self, save_changes, reopen );
    }

void
DESTROY(self)
    CDB_TinyCDB *self
    PPCODE:
    {
        commit( self, /* save_changes */ 0, /* reopen */ 0 );
        memfree( self );
        Safefree( self->fn );
        if ( self->fntemp ) {
            Safefree( self->fntemp );
        }
        Safefree( self );
    }

