/*
    Portions of this code are from libketama, which is licensed
    under GPLv2. Namely, the following functions are based on libketama:
        PerlKetama_md5_digest,
        PerlKetama_create_continuum, 
        PerlKetama_hash_string,
        PerlKetama_hash

    All the rest are by Daisuke Maki.
    Portions of the code made by Daisuke Maki are licensed under
    Artistic License v2 (which includes the pure-Perl contents).

    You should also note that MD5 code is based on another person's code,
    too. However, that file does not carry a GPL license
*/
/*
    For all libketama based code (as noted by above)
    Copyright (C) 2007 by                                          
       Christian Muehlhaeuser <chris@last.fm>
       Richard Jones <rj@last.fm>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; version 2 only.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "Ketama.h"
#include "KetamaMD5.h"

#define PERL_KETAMA_TRACE_LEVEL 0
#if (PERL_KETAMA_TRACE_LEVEL > 0)
#define PERL_KETAMA_TRACE(x) warn(x)
#else
#define PERL_KETAMA_TRACE(x)
#endif

static void
PerlKetama_md5_digest( char* in, STRLEN len, unsigned char md5pword[16] )
{
    md5_state_t md5state;

    md5_init( &md5state );
    md5_append( &md5state, (unsigned char *) in, len);
    md5_finish( &md5state, md5pword );
}

// forward declaration
static char *
PerlKetama_hash_internal1( PerlKetama *, char *, STRLEN, unsigned int *);
static char *
PerlKetama_hash_internal2( PerlKetama *, char *, STRLEN, unsigned int *);

static PerlKetama *
PerlKetama_create(SV *class_sv, int hashfunc)
{
    PerlKetama *ketama;

    PERL_UNUSED_VAR(class_sv);

    Newxz( ketama, 1, PerlKetama );
    ketama->numbuckets = 0;
    ketama->numpoints = 0;

    ketama->buckets = NULL;
    ketama->continuum = NULL;

    switch (hashfunc) {
    case 2:
        PERL_KETAMA_TRACE("Using hash_internal2");
        ketama->hashfunc = PerlKetama_hash_internal2;
        break;
    default:
        PERL_KETAMA_TRACE("Using hash_internal1");
        ketama->hashfunc = PerlKetama_hash_internal1;
    }

    return ketama;
}

static MAGIC*
PerlKetama_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("Ketama: Invalid Ketama object was passed");
    return NULL; /* not reached */
}


static void
PerlKetama_clear_continuum(PerlKetama *ketama)
{
    if (ketama->numpoints > 0) {
        Safefree(ketama->continuum);
        ketama->numpoints = 0;
    }
}

static int
PerlKetama_mg_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlKetama* const ketama = (PerlKetama*) mg->mg_ptr;

    PerlKetama_clear_continuum(ketama);

    if (ketama->numbuckets > 0) {
        unsigned int i;
        for(i = 0; i < ketama->numbuckets; i++) {
            Safefree(ketama->buckets[i].label);
        }
        Safefree(ketama->buckets);
    }
    Safefree(ketama);
    PERL_UNUSED_ARG(sv);

    return 0;
}

static void
PerlKetama_add_bucket(PerlKetama *p, char *server, int weight)
{
    int len;
    p->numbuckets++;
    p->totalweight += weight;

    if (p->numbuckets == 1) {
        Newxz( p->buckets, p->numbuckets, PerlKetama_Bucket );
    } else {
        Renew( p->buckets, p->numbuckets, PerlKetama_Bucket );
    }

    len = strlen(server);
    Newxz( p->buckets[p->numbuckets - 1].label, len + 1, char );
    Copy(server, p->buckets[p->numbuckets - 1].label, len + 1, char);

    p->buckets[p->numbuckets - 1].weight = weight;

    PerlKetama_clear_continuum( p );
}

static void
PerlKetama_remove_bucket(PerlKetama *p, char *server)
{
    unsigned int i;

    for( i = 0; i < p->numbuckets; i++ ) {
        if ( strEQ(p->buckets[i].label, server) ) {
            Safefree(p->buckets[i].label);
            p->totalweight -= p->buckets[i].weight;
            for( i += 1; i < p->numbuckets; i++) {
                StructCopy(&(p->buckets[i]), &(p->buckets[i - 1]), PerlKetama_Bucket);
            }
            p->numbuckets--;
            Renew(p->buckets, p->numbuckets, PerlKetama_Bucket);
            i = p->numbuckets;
        }
    }

    PerlKetama_clear_continuum( p );
}

static int
PerlKetama_buckets(PerlKetama *p)
{
    unsigned int i;
    SV *sv;
    dSP;
    PerlKetama_Bucket s;
    SP -= 1; /* must offset for object */

    for(i = 0; i < p->numbuckets; i++) {
        {
            s = p->buckets[i];
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            mXPUSHp( "Algorithm::ConsistentHash::Ketama::Bucket", 41 );
            mXPUSHp( "label", 5 );
            mXPUSHp( s.label, strlen(s.label) );
            mXPUSHp( "weight", 6 );
            mXPUSHi( s.weight );
            PUTBACK;

            call_method("new", G_SCALAR);

            SPAGAIN;
    
            sv = POPs;
            SvREFCNT_inc(sv);

            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        XPUSHs( sv );
    }
    return p->numbuckets;
}

static int
PerlKetama_continuum_compare( PerlKetama_Continuum_Point *a, PerlKetama_Continuum_Point *b )
{
    if (a->point < b->point) return -1;
    if (a->point > b->point) return 1;
    return 0;
}

#define MAX_SS_BUF 8192
static void
PerlKetama_create_continuum( PerlKetama *ketama )
{
    unsigned int i, k, h;
    char ss[MAX_SS_BUF];
    unsigned char digest[16];
    unsigned int continuum_idx;
    PerlKetama_Continuum_Point *continuum;

    continuum_idx = 0;
    Newxz(continuum, ketama->numbuckets * 160, PerlKetama_Continuum_Point);

    for ( i = 0; i < ketama->numbuckets; i++ ) {
        PerlKetama_Bucket *b = ketama->buckets + i;
        float pct = b->weight / (float) ketama->totalweight;
        unsigned int k_limit = floorf(pct * 40.0 * ketama->numbuckets);

        for ( k = 0; k < k_limit; k++ ) {
            /* 40 hashes, 4 numbers per hash = 160 points per bucket */
            if (snprintf(ss, MAX_SS_BUF, "%s-%d", b->label, k) >= MAX_SS_BUF) {
                croak("snprintf() overflow detected for key '%s-%d'. Please use shorter labels", b->label, k);
            }
            PerlKetama_md5_digest(ss, strlen(ss), digest);

            for( h = 0; h < 4; h++ ) {
                continuum[ continuum_idx ].point = ( digest[3 + h * 4] << 24 )
                                           | ( digest[2 + h * 4] << 16 )
                                           | ( digest[1 + h * 4] <<  8 )
                                           | ( digest[h * 4] )
                ;
                continuum[ continuum_idx ].bucket = b;
                continuum_idx++;
            }
        }
    }

    Renew( continuum, continuum_idx, PerlKetama_Continuum_Point );
    qsort( (void *) continuum, continuum_idx, sizeof(PerlKetama_Continuum_Point), (compfn) PerlKetama_continuum_compare );

    if (ketama->numpoints > 0) {
        Safefree(ketama->continuum);
    }

    ketama->numpoints = continuum_idx;
    Newxz(ketama->continuum, continuum_idx, PerlKetama_Continuum_Point);
    for (i = 0; i < continuum_idx; i++) {
        ketama->continuum[i].bucket = continuum[i].bucket;
        ketama->continuum[i].point = continuum[i].point; 
    }
    Safefree(continuum);
}

unsigned int
PerlKetama_hash_string( char* in, STRLEN len)
{
    unsigned char digest[16];
    unsigned int ret;

    PerlKetama_md5_digest( in, len, digest );
    ret = ( digest[3] << 24 )
        | ( digest[2] << 16 )
        | ( digest[1] <<  8 )
        |   digest[0];

    return ret;
}

static char *
PerlKetama_hash_internal2( PerlKetama *ketama, char *thing, STRLEN len, unsigned int *thehash )
{
    unsigned int h;
    unsigned int highp;
    unsigned int lowp;
    unsigned int midp;

    if (ketama->numpoints == 0 && ketama->numbuckets > 0) {
        PERL_KETAMA_TRACE("Generating continuum");
        PerlKetama_create_continuum(ketama);
    }

    if (ketama->numpoints == 0) {
        PERL_KETAMA_TRACE("no continuum available");
        return NULL;
    }

    /* Accept either string OR hash number as input */
    if (thing != NULL) {
        h = PerlKetama_hash_string(thing, len);
        *thehash = h;
    }
    else {
        h = *thehash;
    }

    lowp = 0;
    highp = ketama->numpoints;

    while (lowp < highp) {
        midp = lowp + (highp - lowp) / 2;
        if (ketama->continuum[midp].point > h) {
            highp = midp;
        } else {
            lowp = midp + 1;
        }
    }

    if (lowp >= ketama->numpoints) {
       lowp = 0;
    }

    return ketama->continuum[lowp].bucket->label;
}

// This code exist because you might need to keep backwards compatibility
// with older, but possibly broken versions
static char *
PerlKetama_hash_internal1( PerlKetama *ketama, char *thing, STRLEN len, unsigned int *thehash )
{
    unsigned int h;
    unsigned int highp;
    unsigned int maxp  = 0,
        lowp  = 0,
        midp  = 0
    ;
    unsigned int midval, midval1;

    if (ketama->numpoints == 0 && ketama->numbuckets > 0) {
        PERL_KETAMA_TRACE("Generating continuum");
        PerlKetama_create_continuum(ketama);
    }

    if (ketama->numpoints == 0) {
        PERL_KETAMA_TRACE("no continuum available");
        return NULL;
    }

    highp = ketama->numpoints;
    maxp  = highp;

    /* Accept either string OR hash number as input */
    if (thing != NULL) {
        h = PerlKetama_hash_string(thing, len);
        *thehash = h;
    }
    else {
        h = *thehash;
    }

    while ( 1 ) {
        midp = (int)( ( lowp+highp ) / 2 );
        if ( midp >= maxp ) {
            if ( midp == ketama->numpoints ) {
                midp = 1;
            } else {
                midp = maxp;
            }

            return ketama->continuum[midp - 1].bucket->label;
        }
        midval = ketama->continuum[midp].point;
        midval1 = midp == 0 ? 0 : ketama->continuum[midp - 1].point;

        if ( h <= midval && h > midval1 ) {
            return ketama->continuum[midp].bucket->label;
        }

        if ( midval < h )
            lowp = midp + 1;
        else
            highp = midp - 1;

        if ( lowp > highp ) {
            return ketama->continuum[0].bucket->label;
        }
    }
}

char *
PerlKetama_hash( PerlKetama *ketama, SV *thing )
{
    unsigned int hash;
    STRLEN len;
    char *ptr;

    ptr = SvPV(thing, len);

    return ketama->hashfunc(ketama, ptr, len, &hash);
}


#define PerlKetama_xs_create PerlKetama_create

static PerlKetama *
PerlKetama_clone(PerlKetama * const ketama)
{
    PerlKetama_Bucket * const buckets = ketama->buckets;
    PerlKetama_Continuum_Point * const continuum = ketama->continuum;
    unsigned int i, j;
    PerlKetama *newketama = PerlKetama_create(NULL, 1);

    newketama->hashfunc = ketama->hashfunc;
    newketama->totalweight = ketama->totalweight;

    if (ketama->numpoints <= 0) {
        newketama->continuum = NULL;
        newketama->numpoints = 0;
    } else {
        Newxz(newketama->continuum, ketama->numpoints, PerlKetama_Continuum_Point);
        for (i = 0; i < ketama->numpoints; i++) {
            StructCopy(&(continuum[i]), &(newketama->continuum[i]), PerlKetama_Continuum_Point);
        }
        newketama->numpoints = ketama->numpoints;
    }

    if (ketama->numbuckets <= 0) {
        newketama->buckets = NULL;
        newketama->numbuckets = 0;
    } else {
        Newxz(newketama->buckets, ketama->numbuckets, PerlKetama_Bucket);
        for (i = 0; i < ketama->numbuckets; i++ ) {
            StructCopy(&(buckets[i]), &(newketama->buckets[i]), PerlKetama_Bucket);
            Newxz(newketama->buckets[i].label, strlen(buckets[i].label) + 1, char);
            Copy(buckets[i].label, newketama->buckets[i].label, strlen(buckets[i].label) + 1, char);
            if ( ketama->numpoints > 0) {
                int found = 0;
                for (j = 0; j < ketama->numpoints; j++) {
                    if ( strEQ( buckets[i].label, continuum[j].bucket->label ) ) {
                        newketama->continuum[j].bucket = newketama->buckets + i;
                        found = 1;
                        j = ketama->numpoints;
                    }
                }
                if (! found) {
                    croak("SANITY CHECK FAILED: Should not get here");
                }
            }
        }
        newketama->numbuckets = ketama->numbuckets;
    }
    return newketama;
}

static int
PerlKetama_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    PERL_UNUSED_VAR(param);
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    PerlKetama* const ketama = (PerlKetama*)mg->mg_ptr;
    mg->mg_ptr = (char *) PerlKetama_clone(ketama);
#else
    PERL_UNUSED_VAR(mg);
#endif
    return 0;
}

static MGVTBL PerlKetama_vtbl = { /* for identity */
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    PerlKetama_mg_free, /* free */
    NULL, /* copy */
    PerlKetama_mg_dup, /* dup */
    NULL,  /* local */
};

MODULE = Algorithm::ConsistentHash::Ketama   PACKAGE = Algorithm::ConsistentHash::Ketama  PREFIX=PerlKetama_

PROTOTYPES: DISABLE

PerlKetama *
PerlKetama_xs_create(class_sv, hashfunc)
        SV *class_sv;
        int hashfunc;

void
PerlKetama_add_bucket(ketama, label, weight)
        PerlKetama *ketama;
        char *label;
        int weight;

void
PerlKetama_remove_bucket(ketama, label)
        PerlKetama *ketama;
        char *label;

void
PerlKetama_buckets(ketama)
        PerlKetama *ketama;
    PPCODE:
        /* since PerlKetama_buckets may push an unknown number of items
           into the Perl stash, this is required */
        XSRETURN( PerlKetama_buckets(ketama) );

char *
PerlKetama_hash(ketama, thing)
        PerlKetama* ketama;
        SV *thing;

void
PerlKetama_hash_with_hashnum(ketama, thing)
        PerlKetama* ketama;
        SV *thing;
    PREINIT:
        unsigned int hash;
        char *ptr;
        STRLEN len;
        char *label;
    PPCODE:
        ptr = SvPV(thing, len);
        label = ketama->hashfunc(ketama, ptr, len, &hash);
        mXPUSHp(label, strlen(label));
        mXPUSHu(hash);
        XSRETURN(2);

void
PerlKetama_label_from_hashnum(ketama, thing)
        PerlKetama* ketama;
        unsigned int thing;
    PREINIT:
        char *label;
    PPCODE:
        label = ketama->hashfunc(ketama, NULL, 0, &thing);
        XPUSHs(sv_2mortal(newSVpv(label, strlen(label))));
        XSRETURN(1);

PerlKetama *
PerlKetama_clone(ketama)
        PerlKetama *ketama;
    PREINIT:
        SV *class_sv = ST(0);

