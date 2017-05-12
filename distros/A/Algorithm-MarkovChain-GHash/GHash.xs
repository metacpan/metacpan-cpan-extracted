#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <glib.h>

typedef struct {
    int longest;
    GHashTable* dictionary;
    GHashTable* chains;
} IM;

typedef struct {
    int count;
    GHashTable* states;
} chain_t;

static inline SV* phash_value(SV *phash, char *key) {
    SV* hash  = *av_fetch((AV*) phash, 0, 0);
    IV  index = SvIV( *hv_fetch((HV*) SvRV(hash), key, strlen(key), 0) );
    return *av_fetch((AV*) phash, index, 0);
}

static void free_key (gpointer key, gpointer value, gpointer user_data) {
    g_free(key);
}

static void free_chain  (gpointer key, gpointer value, gpointer user_data) {
    chain_t *chain = value;
    g_free(key);
    g_hash_table_destroy(chain->states);
    g_free(value);
}


/* this is pretty fun but hacky 

   In order to be re-entrant and only pass one variable around we put
   the number of keys in the first array element, then decrement it
   and put the next key into the array at that index.  

   The last copy blats over the counter, but it's zero at that point
   anyway.

*/
static void get_keys (gpointer key, gpointer value, gpointer user_data) {
    char **keys = user_data;
    int i = (int) --keys[0];
    keys[i] = key;
}


MODULE = Algorithm::MarkovChain::GHash PACKAGE = Algorithm::MarkovChain::GHash

PROTOTYPES: ENABLE

SV* 
_new_cstuff()
  CODE:
    IM*  im = g_malloc(sizeof(IM));
    SV* obj = newSViv((IV)im);

    im->longest = 0;
    im->dictionary = g_hash_table_new(g_str_hash, g_str_equal);
    im->chains     = g_hash_table_new(g_str_hash, g_str_equal);

    SvREADONLY_on(obj);
    RETVAL = obj;
  OUTPUT:
    RETVAL


void 
_c_destroy (obj)
   SV *obj
  CODE:
{
   IM* im = (IM*) SvIV(phash_value(SvRV(obj), "_cstuff"));

   g_hash_table_foreach(im->dictionary, free_key, NULL);
   g_hash_table_foreach(im->chains, free_chain, NULL);
   g_hash_table_destroy(im->dictionary);
   g_hash_table_destroy(im->chains);
   g_free(im);
}


void 
increment_seen(obj, stub, original_next)
    SV* obj;
    char *stub;
    char *original_next;
  CODE:
{
    IM* im       = (IM*) SvIV(phash_value(SvRV(obj), "_cstuff"));
    chain_t* stubs = g_hash_table_lookup(im->chains, stub);
    int count;

    char* next = g_hash_table_lookup(im->dictionary, original_next);

    /* printf("increment_seen: '%s' '%s'\n", stub, original_next); */

    if (!next) {
        next = g_strdup(original_next);
        g_hash_table_insert(im->dictionary, next, next);
    }

    if (!stubs) {
        char* sep = SvPV_nolen(phash_value(SvRV(obj), "seperator"));
        char* s;
        int len = 1;

        for (s = stub; s = strstr(s, sep); s += strlen(sep)) len++;
        if (len > im->longest) {
            im->longest = len;
        }

        stubs = g_malloc(sizeof(chain_t));
	stubs->states = g_hash_table_new(g_str_hash, g_str_equal);
	stubs->count  = 0;
        g_hash_table_insert(im->chains, g_strdup(stub), stubs);
    }

    stubs->count++;
    count = (int) g_hash_table_lookup(stubs->states, next);
    count++;
    g_hash_table_insert(stubs->states, next, (void *) count);
}

void 
get_options (obj, stub)
    SV *obj;
    char *stub;
  PPCODE:
{
    IM* im = (IM*) SvIV(phash_value(SvRV(obj), "_cstuff"));
    chain_t* stubs = g_hash_table_lookup(im->chains, stub);
    char **keys = NULL;
    int nkeys, i;

    if ( (!stubs) || (!(nkeys = g_hash_table_size(stubs->states))) ) {
        return;
    }

    keys = g_malloc(nkeys * sizeof(char *));
    keys[0] = (char*) nkeys;

    g_hash_table_foreach(stubs->states, get_keys, keys);

    for (i = 0; i < nkeys; i++) {
	int count = (int) g_hash_table_lookup(stubs->states, keys[i]);
        XPUSHs(sv_2mortal(newSVpv(keys[i], 0)));
        XPUSHs(sv_2mortal(newSVnv(count / stubs->count)));
    }
    g_free(keys);
}

int 
longest_sequence (obj)
    SV* obj;
  CODE:
    IM* im = (IM*) SvIV(phash_value(SvRV(obj), "_cstuff"));

    RETVAL = im->longest;
  OUTPUT:
    RETVAL


int
sequence_known (obj, stub)
   SV* obj;
   char *stub;
  CODE:
    IM* im = (IM*) SvIV(phash_value(SvRV(obj), "_cstuff"));
    RETVAL = (int) g_hash_table_lookup(im->chains, stub);
  OUTPUT:
    RETVAL


char* 
random_sequence (obj)
    SV *obj;
  CODE:
    IM* im = (IM*) SvIV(phash_value(SvRV(obj), "_cstuff"));
    int nkeys = g_hash_table_size(im->chains);
    char **keys = g_malloc(nkeys * sizeof(char *));

    keys[0] = (char*) nkeys;
    g_hash_table_foreach(im->chains, get_keys, keys);
    nkeys = (1.0 * nkeys * rand()) / (1.0*RAND_MAX);

    RETVAL = keys[nkeys];
    g_free(keys);
  OUTPUT:
    RETVAL


