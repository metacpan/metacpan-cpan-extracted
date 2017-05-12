#include "speedyb.h"
#include <stdio.h>
#include <strings.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#define MAGIC 0x1818

//#define DEBUG(M, ...) fprintf(stderr, "%s %s  %5d:    ", __FILE__, __FUNCTION__, __LINE__); fprintf(stderr, M, __VA_ARGS__); fprintf(stderr, "\n");
#define DEBUG(M, ...)
//#define ERETURN(X) DEBUG("ERROR returning '%s'=%d\n", #X, (X)); return(X);
#define ERETURN(X) return X;
#define ASSERT_OPEN if(!r->store) { ERETURN(SPEEDYB_ENOPEN); }

typedef speedyb_reader_t dbh_t;

speedyb_rc_t speedyb_open(dbh_t *dbh, char *fn) {
    void *db;
    struct stat statbuf;
    speedyb_header_t *header;

    bzero(dbh, sizeof(dbh_t));
    if((dbh->fd = open(fn, O_RDONLY)) < 0) {
        ERETURN(SPEEDYB_EOPEN);
    }
    if(stat(fn, &statbuf)) {
        ERETURN(SPEEDYB_EOPEN);
    }
    if(MAP_FAILED == (db = mmap(NULL, statbuf.st_size, PROT_READ, MAP_SHARED, dbh->fd, 0))) {
        ERETURN(SPEEDYB_EOPEN);
    }
    header = (speedyb_header_t*) db;
    if(header->magic != MAGIC) {
        ERETURN(SPEEDYB_EMAGIC);
    }
    if(header->proto_ver != 1) {
        ERETURN(SPEEDYB_EVER);
    }
    dbh->g = (int*)(db + sizeof(speedyb_header_t));
    dbh->v = dbh->g + header->nkeys;
    dbh->nkeys = header->nkeys;
    dbh->store = (char*)(dbh->v + header->nkeys);
    dbh->store_len = statbuf.st_size - sizeof(speedyb_header_t) - 2 * dbh->nkeys * sizeof(int);
    dbh->munmap_ptr = db;
    dbh->munmap_len = statbuf.st_size;
    DEBUG("header: %x %d\n", header->magic, header->nkeys);
    return SPEEDYB_OK;
}

speedyb_rc_t speedyb_close(dbh_t *dbh) {
    if(!dbh->store) {
        ERETURN(SPEEDYB_ENOPEN);
    }
    if(munmap(dbh->munmap_ptr, dbh->munmap_len)) {
        ERETURN(SPEEDYB_EIO);
    }
    if(close(dbh->fd)) {
        ERETURN(SPEEDYB_EIO);
    }
    return SPEEDYB_OK;
}

/* d is 64-bit for compat with python.  when we assign the result to 32-bit,
   the upper bits are discarded */
static uint hash(uint64_t d, unsigned char *v, int vlen) {
    int i;
    //int od = d;

    if(d == 0) {
        d = 0x01000193;
    }
    // Use the FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/ 
    for(i=0; i<vlen; i++) {
        d = ( (d * 0x01000193) ^ v[i] ) & 0xffffffff;
    }
    DEBUG("hash(%d, '%*.*s') = %ld", od, vlen, vlen, v, d);
    return d;
}

/* Given a key, return offset into store of possible kv pair */
static int raw_hash_lookup(dbh_t *dbh, char *key, int keylen) {
    uint hc, hcm;
    int d; // negative = onceler

    hc = hash(0, (unsigned char*)key, keylen);
    hcm = hc % dbh->nkeys;
    d = dbh->g[hcm];
    DEBUG("key='%*.*s' hc=%u hcm=%u d=%d", keylen, keylen, key, hc, hcm, d);
    if(d < 0) { // onceler
        return dbh->v[-d-1];
    }
    // shared bucket:
    return dbh->v[hash(d, (unsigned char*)key, keylen) % dbh->nkeys];
}

static void align4(char **p) {
    int n = ((long long)*p) % 4;
    if(!n) {
        return;
    }
    *p += (4-n);
}

speedyb_rc_t speedyb_get(dbh_t *dbh, char *key, uint keylen, char **val, uint *vallen) {
    int pos;
    int *rkeylen;
    char *p;

    *val = 0;
    *vallen = 0;

    if(!dbh->store) {
        ERETURN(SPEEDYB_ENOPEN);
    }
    if(keylen == 0) {
        return SPEEDYB_ENXKEY;
    }

    pos = raw_hash_lookup(dbh, key, keylen);
    DEBUG("offset=rhl()=%d", pos);
    p = dbh->store + pos;
    rkeylen = (int*)p;
    if(keylen != *rkeylen) {
        DEBUG("uneq len '%s': %d != %d\n", key, keylen, *rkeylen);
        return SPEEDYB_ENXKEY;
    }
    p += sizeof(int);
    if(memcmp(key, p, keylen)) {
        DEBUG("uneq memcmp '%s'\n", key);
        return SPEEDYB_ENXKEY;
    }
    p += keylen;
    align4(&p);
    *vallen = *((int*)p);
    p += sizeof(int);
    *val = p;
    return SPEEDYB_OK;
}

speedyb_rc_t speedyb_iterate_init(speedyb_reader_t *r) {
    ASSERT_OPEN
    r->ip = r->store;
    r->it_rem = r->nkeys;
    return SPEEDYB_OK;
}

speedyb_rc_t speedyb_iterate_next(speedyb_reader_t *r, char **key, uint *keylen, char **val, uint *vallen) {
    ASSERT_OPEN
    if(!(r->it_rem)) {
        return SPEEDYB_DONE;
    }
    r->it_rem--;
    align4(&(r->ip));
    *keylen = *(uint*)(r->ip);
    r->ip += sizeof(uint);
    *key = r->ip;
    r->ip += *keylen;
    align4(&(r->ip));

    *vallen = *(uint*)(r->ip);
    r->ip += sizeof(uint);
    *val = r->ip;
    r->ip += *vallen;
    return SPEEDYB_OK;
}

speedyb_rc_t speedyb_get_num_keys(speedyb_reader_t *r, uint *nkeys) {
    ASSERT_OPEN
    *nkeys = r->nkeys;
    return SPEEDYB_OK;
}

