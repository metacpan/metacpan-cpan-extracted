#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <swifty.h>

typedef struct swifty_t Swifty;

static int _swifty_err;

static void* alloc_cb(void** context, uint32_t sz)
{
  SV* sv;
  void* p;
  
  if ((sv = newSV(sz)) == NULL) {
    return NULL;
  }
  SvPOK_on(sv);
  SvCUR_set(sv, sz);
  *context = sv;
  return SvPV_nolen(sv);
}

static void free_cb(void** context, void* p)
{
  printf("free_cb %p %p\n", *context, p);
  SvREFCNT_dec(*context);
}

MODULE = Cache::Swifty		PACKAGE = Cache::Swifty		

PROTOTYPES: disable

int
swifty_err()
CODE:
  RETVAL = _swifty_err;
OUTPUT:
  RETVAL

Swifty*
swifty_new(const char* dir, unsigned int lifetime, unsigned int refresh_before, unsigned int flags)

int
swifty_free(m)
  Swifty* m;
CODE:
  RETVAL = _swifty_err = swifty_free(m);
OUTPUT:
  RETVAL

SV* swifty_get(Swifty* m, unsigned int hash, const char* key, unsigned int length(key))
CODE:
  SV* result;
  struct swifty_get_params p;
  p.hash =
    hash == (unsigned int)-1 ? swifty_adler32(key, XSauto_length_of_key) : hash;
  p.key = key;
  p.key_size = XSauto_length_of_key;
  p.value = NULL;
  p.value_size = 0;
  p.now = (uint32_t)time(NULL);
  p.refresh_before = 0;
  p.alloc = alloc_cb;
  p.free = free_cb;
  p.alloc_context = NULL;
  if ((_swifty_err = swifty_get(m, &p)) == 0) {
    RETVAL = p.alloc_context;
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL

int
swifty_set(Swifty* m, unsigned int hash, const char* key, unsigned int length(key), const char* value, unsigned int length(value), unsigned int expires)
CODE:
  RETVAL = _swifty_err = swifty_set(
    m,
    hash == (unsigned int)-1 ? swifty_adler32(key, XSauto_length_of_key) : hash,
    key,
    XSauto_length_of_key,
    value,
    XSauto_length_of_value,
    (uint32_t)time(NULL),
    expires);
OUTPUT:
  RETVAL

unsigned int swifty_get_lifetime(Swifty* m)

void swifty_set_lifetime(Swifty* m, unsigned int l)

unsigned int swifty_get_refresh_before(Swifty* m)

void swifty_set_refresh_before(Swifty* m, unsigned int rb)

int swifty_do_refresh(Swifty* m)

unsigned int swifty_adler32(const char* p,unsigned int length(p))
