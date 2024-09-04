#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "libmemcached/memcached.h"

#define MIN_THREAD 1

typedef struct arcus_st {
  memcached_st *proxy;
  memcached_st *global;
  memcached_pool_st *pool;
  int max_thread;
  int cur_thread;
  bool main_proxy;
} Arcus_API;

enum arcus_op {
  ARCUS_SET,
  ARCUS_CAS,
  ARCUS_ADD,
  ARCUS_REPLACE,
  ARCUS_APPEND,
  ARCUS_PREPEND,
  ARCUS_INCR,
  ARCUS_DECR,
  ARCUS_GET,
  ARCUS_GETS
};

const char *ARCUS_OP_NAME[] = {
  "set",
  "cas",
  "add",
  "replace",
  "append",
  "prepend",
  "increment",
  "decrement",
  "get",
  "gets"
};

static inline SV *safe_sv(pTHX_ SV *sv)
{
  SvGETMAGIC(sv);
  if (SvOK(sv)) {
    return sv;
  }
  return NULL;
}

static inline SV **safe_av_fetch(pTHX_ AV *av, SSize_t key, I32 lval)
{
  SV **v = av_fetch(av, key, lval);
  if (v && SvOK(*v)) {
    return v;
  }
  return NULL;
}

static inline void destroy_arcus_api(Arcus_API *arcus)
{
  if (arcus->pool) {
    arcus_pool_close(arcus->pool);
    memcached_pool_destroy(arcus->pool);
    arcus->pool = NULL;
  }
  if (arcus->global) {
    memcached_free(arcus->global);
    arcus->global = NULL;
  }
  if (arcus->main_proxy && arcus->proxy) {
    arcus_proxy_close(arcus->proxy);
    memcached_free(arcus->proxy);
    arcus->proxy = NULL;
  }
}

static void initialize_arcus_api(pTHX_ Arcus_API *arcus, HV *conf)
{
  char *zk_address = NULL;
  char *service_code = NULL;
  int max_thread = -1;

  SV **ps = hv_fetchs(conf, "zk_address", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    if (!SvROK(*ps) || SvTYPE(SvRV(*ps)) != SVt_PVAV) {
      croak("zk_address argument is not array reference.");
    }

    AV *av = (AV *) SvRV(*ps);
    SV *zk = newSVpvn("", 0);
    int i, size = av_count(av);

    for (i = 0; i < size; i++) {
      SV **elem = av_fetch(av, i, 0);
      if (elem && SvOK(*elem)) {
        if (i > 0) {
          sv_catpv(zk, ",");
        }
        sv_catpv(zk, SvPV_nolen(*elem));
      }
    }

    zk_address = SvPV_nolen(zk);
  }
  if (zk_address == NULL) {
    memcached_free(arcus->proxy);
    memcached_free(arcus->global);
    croak("zk_address argument is invalid.");
  }

  ps = hv_fetchs(conf, "service_code", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    service_code = SvPV_nolen(*ps);
  }
  if (service_code == NULL) {
    memcached_free(arcus->proxy);
    memcached_free(arcus->global);
    croak("service_code argument is invalid.");
  }

  ps = hv_fetchs(conf, "max_thread", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    if (SvIOK(*ps)) {
      max_thread = SvIV(*ps);
    }
  }
  if (max_thread < MIN_THREAD) {
    croak("max_thread argument is invalid. it should be greater than or equal to %d.", MIN_THREAD);
  }
  arcus->max_thread = max_thread;

  arcus_return_t ret = arcus_proxy_create(arcus->proxy, zk_address, service_code);
  if (ret != ARCUS_SUCCESS) {
    memcached_free(arcus->proxy);
    memcached_free(arcus->global);
    croak("failed to create the arcus proxy object: %d (%s)", ret, arcus_strerror(ret));
  }

  ps = hv_fetchs(conf, "connect_timeout", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    if (SvIOK(*ps) || SvNOK(*ps)) {
      memcached_behavior_set(arcus->global, MEMCACHED_BEHAVIOR_CONNECT_TIMEOUT, SvNV(*ps) * 1000);
    } else {
      warn("connect_timeout argument is invalid. it is ignored.");
    }
  }

  ps = hv_fetchs(conf, "io_timeout", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    if (SvIOK(*ps) || SvNOK(*ps)) {
      memcached_behavior_set(arcus->global, MEMCACHED_BEHAVIOR_POLL_TIMEOUT, (uint64_t) (SvNV(*ps) * 1000));
    } else {
      warn("io_timeout argument is invalid. it is ignored.");
    }
  }

  ps = hv_fetchs(conf, "nowait", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    memcached_behavior_set(arcus->global, MEMCACHED_BEHAVIOR_NOREPLY, SvTRUE(*ps));
  }

  ps = hv_fetchs(conf, "hash_namespace", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    memcached_behavior_set(arcus->global, MEMCACHED_BEHAVIOR_HASH_WITH_PREFIX_KEY, SvTRUE(*ps));
  }

  ps = hv_fetchs(conf, "namespace", 0);
  if (ps) {
    SvGETMAGIC(*ps);
  }
  if (ps && SvOK(*ps)) {
    STRLEN name_len;
    char *namespace = SvPV(*ps, name_len);

    if (namespace && name_len > 0) {
      memcached_set_namespace(arcus->global, namespace, name_len);
    } else if (!namespace && name_len == 0) {
      warn("namespace argument is invalid. it is ignored.");
    }
  }

  arcus->pool = memcached_pool_create(arcus->global, MIN_THREAD, arcus->max_thread);
  if (arcus->pool == NULL) {
    arcus_proxy_close(arcus->proxy);
    memcached_free(arcus->proxy);
    memcached_free(arcus->global);
    croak("failed to create the memcached pool object.");
  }

  ret = arcus_proxy_connect(arcus->global, arcus->pool, arcus->proxy);
  if (ret != ARCUS_SUCCESS) {
    arcus_pool_close(arcus->pool);
    memcached_pool_destroy(arcus->pool);
    arcus_proxy_close(arcus->proxy);
    memcached_free(arcus->proxy);
    memcached_free(arcus->global);
    croak("failed to connect to the proxy: %d (%s)", ret, arcus_strerror(ret));
  }
}

MODULE = Arcus::Base		PACKAGE = Arcus::Base

void
new(class, self)
  char *class
  SV *self
  PPCODE:
  Arcus_API *arcus = NULL;
  if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV) {
    EXTEND(SP, 1);
    Newx(arcus, 1, Arcus_API);
    arcus->global = memcached_create(NULL);
    if (arcus->global == NULL) {
      croak("Failed to create the global memcached object");
    }
    arcus->proxy = memcached_create(NULL);
    if (arcus->proxy == NULL) {
      croak("Failed to create the proxy memcached object");
    }
    arcus->global = memcached_create(NULL);
    arcus->cur_thread = 0;
    arcus->main_proxy = true;
    initialize_arcus_api(aTHX_ arcus, (HV *) SvRV(self));
    SV* sv = newSV(0);
    sv_setref_pv(sv, class, (void*)arcus);
    mXPUSHs(sv);
  } else {
    arcus = (Arcus_API *)SvUV(self);
  }
  arcus->cur_thread++;

void
DESTROY(arcus)
  Arcus_API *arcus
  CODE:
  arcus->cur_thread--;
  if (!arcus->cur_thread) {
    destroy_arcus_api(arcus);
  }

void
connect_proxy(arcus)
  Arcus_API *arcus
  CODE:
  arcus->cur_thread = 1;
  arcus->main_proxy = false;
  arcus->global = memcached_clone(NULL, arcus->global);
  if (arcus->global == NULL) {
    croak("Failed to create the global memcached object");
  }
  arcus->pool = memcached_pool_create(arcus->global, MIN_THREAD, arcus->max_thread);
  if (arcus->pool == NULL) {
    memcached_free(arcus->global);
    arcus->global = NULL;
    croak("Failed to create the memcached pool object");
  }
  arcus_return_t arcus_ret = arcus_proxy_connect(arcus->global, arcus->pool, arcus->proxy);
  if (arcus_ret != ARCUS_SUCCESS) {
    arcus->proxy = NULL;
    destroy_arcus_api(arcus);
    croak("Failed to connect : %d (%s)", arcus_ret, arcus_strerror(arcus_ret));
  }

SV *
cas(arcus, key, cas, value, ...)
  Arcus_API *arcus
  SV *key
  SV *cas
  SV *value
  PREINIT:
  time_t exptime = 0;
  int flags = 0;
  int arg = 4;
  CODE:
  RETVAL = NULL;
  memcached_return_t ret;
  STRLEN key_length, value_length;
  char *key_ptr = NULL;
  uint64_t cas_value = 0;
  char *value_ptr = NULL;
  SV *sv;

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  if (!SvOK(key) || (key_ptr = SvPV(key, key_length)) == NULL) {
    warn("key argument is invalid.");
    goto do_return;
  }
  if (!SvIOK(cas) || (cas_value = SvIV(cas)) == 0) {
    warn("cas argument is invalid.");
    goto do_return;
  }
  if (!SvOK(value) || (value_ptr = SvPV(value, value_length)) == NULL) {
    warn("value argument is invalid.");
    goto do_return;
  }

  if (items > arg && (sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
    if (!SvIOK(sv)) {
      warn("exptime argument is invalid.");
      goto do_return;
    }
    exptime = (time_t) SvIV(sv);
  }
  if (items > arg && (sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
    if (!SvIOK(sv)) {
      warn("flags argument is invalid.");
      goto do_return;
    }
    flags = (int) SvIV(sv);
  }

  ret = memcached_cas(mc, key_ptr, key_length, value_ptr, value_length, exptime, flags, cas_value);
  if (memcached_success(ret)) {
    RETVAL = newSViv(true);
  } else if (ret == MEMCACHED_DATA_EXISTS || ret == MEMCACHED_NOTFOUND) {
    RETVAL = newSViv(false);
  } else {
    warn("failed to memcached_cas: %d (%s)", ret, memcached_strerror(mc, ret));
  }

  do_return:
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  if (RETVAL == NULL) {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
RETVAL

SV *
set(arcus, key, value, ...)
  Arcus_API *arcus
  SV *key
  SV *value
  ALIAS:
  set     = ARCUS_SET
  add     = ARCUS_ADD
  replace = ARCUS_REPLACE
  append  = ARCUS_APPEND
  prepend = ARCUS_PREPEND
  PREINIT:
  time_t exptime = 0;
  int flags = 0;
  int arg = 3;
  CODE:
  RETVAL = NULL;
  memcached_return_t ret;
  STRLEN key_length, value_length;
  char *key_ptr = NULL;
  char *value_ptr = NULL;
  SV *sv;

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  if (!SvOK(key) || (key_ptr = SvPV(key, key_length)) == NULL) {
    warn("key argument is invalid.");
    goto do_return;
  }
  if (!SvOK(value) || (value_ptr = SvPV(value, value_length)) == NULL) {
    warn("value argument is invalid.");
    goto do_return;
  }

  if (items > arg && (sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
    if (!SvIOK(sv)) {
      warn("exptime argument is invalid.");
      goto do_return;
    }
    exptime = (time_t) SvIV(sv);
  }
  if (items > arg && (sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
    if (!SvIOK(sv)) {
      warn("flags argument is invalid.");
      goto do_return;
    }
    flags = (int) SvIV(sv);
  }

  switch (ix) {
    case ARCUS_SET:
      ret = memcached_set(mc, key_ptr, key_length, value_ptr, value_length, exptime, flags);
      break;
    case ARCUS_ADD:
      ret = memcached_add(mc, key_ptr, key_length, value_ptr, value_length, exptime, flags);
      break;
    case ARCUS_REPLACE:
      ret = memcached_replace(mc, key_ptr, key_length, value_ptr, value_length, exptime, flags);
      break;
    case ARCUS_APPEND:
      ret = memcached_append(mc, key_ptr, key_length, value_ptr, value_length, exptime, flags);
      break;
    case ARCUS_PREPEND:
      ret = memcached_prepend(mc, key_ptr, key_length, value_ptr, value_length, exptime, flags);
      break;
    default:
      ret = MEMCACHED_FAILURE;
      break;
  }
  if (memcached_success(ret)) {
    RETVAL = newSViv(true);
  } else if (ret == MEMCACHED_NOTSTORED) {
    RETVAL = newSViv(false);
  } else {
    warn("failed to memcached_%s: %d (%s)", ARCUS_OP_NAME[ix], ret, memcached_strerror(mc, ret));
  }

  do_return:
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  if (RETVAL == NULL) {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
RETVAL

void
set_multi(arcus, ...)
  Arcus_API *arcus
  ALIAS:
  set_multi     = ARCUS_SET
  add_multi     = ARCUS_ADD
  replace_multi = ARCUS_REPLACE
  append_multi  = ARCUS_APPEND
  prepend_multi = ARCUS_PREPEND
  PREINIT:
  size_t finished = 0;
  size_t arg = 1;
  PPCODE:
  memcached_return_t ret;
  memcached_storage_request_st req[MAX_KEYS_FOR_MULTI_STORE_OPERATION];
  memcached_return_t results[MAX_KEYS_FOR_MULTI_STORE_OPERATION];
  int req_index[MAX_KEYS_FOR_MULTI_STORE_OPERATION];
  SV **result_buf;

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  size_t number_of_kvs = items - arg;
  if (number_of_kvs == 0) {
    warn("kvs argument is empty.");
    goto do_return;
  }

  size_t leftover = number_of_kvs;
  Newx(result_buf, number_of_kvs, SV *);

  SV *req_sv, **req_elem;
  size_t i, consume, valid_kvs;

  while (leftover > 0) {
    valid_kvs = 0;
    consume = leftover < MAX_KEYS_FOR_MULTI_STORE_OPERATION
            ? leftover : MAX_KEYS_FOR_MULTI_STORE_OPERATION;

    for (i = 0; i < consume; i++) {
      req_index[i] = -1;
      req_sv = safe_sv(aTHX_ ST(arg++));

      if (req_sv == NULL || !SvROK(req_sv) || SvTYPE(SvRV(req_sv)) != SVt_PVAV) {
        warn("kvs[%zu] arugment is not array reference.", finished + i);
        continue;
      }

      AV *req_av = (AV *) SvRV(req_sv);
      size_t idx = 0, size = av_count(req_av);

      if (size < 2) {
        warn("kvs[%zu] arugment is not sufficient.", finished + i);
        continue;
      }

      if ((req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) == NULL ||
          (req[valid_kvs].key = SvPV(*req_elem, req[valid_kvs].key_length)) == NULL) {
        warn("key of kvs[%zu] argument is invalid.", finished + i);
        continue;
      }

      if ((req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) == NULL ||
          (req[valid_kvs].value = SvPV(*req_elem, req[valid_kvs].value_length)) == NULL) {
        warn("value of kvs[%zu] argument is invalid.", finished + i);
        continue;
      }

      if (size > idx && (req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) != NULL) {
        if (!SvIOK(*req_elem)) {
          warn("exptime of kvs[%zu] argument is invalid.", finished + i);
          continue;
        }
        req[valid_kvs].expiration = (time_t) SvIV(*req_elem);
      } else {
        req[valid_kvs].expiration = 0;
      }

      if (size > idx && (req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) != NULL) {
        if (!SvIOK(*req_elem)) {
          warn("flags of kvs[%zu] argument is invalid.", finished + i);
          continue;
        }
        req[valid_kvs].flags = (uint32_t) SvIV(*req_elem);
      } else {
        req[valid_kvs].flags = 0;
      }

      req_index[i] = valid_kvs;
      valid_kvs++;
    }

    switch (ix) {
      case ARCUS_SET:
        ret = memcached_mset(mc, req, valid_kvs, results);
        break;
      case ARCUS_ADD:
        ret = memcached_madd(mc, req, valid_kvs, results);
        break;
      case ARCUS_REPLACE:
        ret = memcached_mreplace(mc, req, valid_kvs, results);
        break;
      case ARCUS_APPEND:
        ret = memcached_mappend(mc, req, valid_kvs, results);
        break;
      case ARCUS_PREPEND:
        ret = memcached_mprepend(mc, req, valid_kvs, results);
        break;
      default:
        ret = MEMCACHED_FAILURE;
        break;
    }

    if (ret == MEMCACHED_SUCCESS) {
      for (i = 0; i < consume; i++) {
        if (req_index[i] >= 0) {
          result_buf[finished + i] = newSViv(true);
        } else {
          result_buf[finished + i] = &PL_sv_undef;
        }
      }
    } else if (ret == MEMCACHED_FAILURE) {
      for (i = 0; i < consume; i++) {
        int idx = req_index[i];
        if (idx < 0) {
          result_buf[finished + i] = &PL_sv_undef;
          continue;
        }

        if (results[idx] == MEMCACHED_NOTSTORED) {
          result_buf[finished + i] = newSViv(false);
        } else {
          result_buf[finished + i] = &PL_sv_undef;
        }
      }
    } else { /* SOME ERRORS */
      for (i = 0; i < consume; i++) {
        int idx = req_index[i];
        if (idx < 0) {
          result_buf[finished + i] = &PL_sv_undef;
          continue;
        }

        if (memcached_success(results[idx])) {
          result_buf[finished + i] = newSViv(true);
        } else if (results[idx] == MEMCACHED_NOTSTORED) {
          result_buf[finished + i] = newSViv(false);
        } else {
          result_buf[finished + i] = &PL_sv_undef;
        }
      }
    }

    finished += consume;
    leftover -= consume;
  }

  EXTEND(SP, number_of_kvs);
  for (i = 0; i < number_of_kvs; i++) {
    mXPUSHs(result_buf[i]);
  }
  Safefree(result_buf);

  do_return:
  // nothing to do
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }

void
cas_multi(arcus, ...)
  Arcus_API *arcus
  PREINIT:
  size_t finished = 0;
  size_t arg = 1;
  PPCODE:
  memcached_return_t ret;
  memcached_storage_request_st req[MAX_KEYS_FOR_MULTI_STORE_OPERATION];
  memcached_return_t results[MAX_KEYS_FOR_MULTI_STORE_OPERATION];
  int req_index[MAX_KEYS_FOR_MULTI_STORE_OPERATION];
  SV **result_buf;

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  size_t number_of_kvs = items - arg;
  if (number_of_kvs == 0) {
    warn("kvs argument is empty.");
    goto do_return;
  }

  size_t leftover = number_of_kvs;
  Newx(result_buf, number_of_kvs, SV *);

  SV *req_sv, **req_elem;
  size_t i, consume, valid_kvs;

  while (leftover > 0) {
    valid_kvs = 0;
    consume = leftover < MAX_KEYS_FOR_MULTI_STORE_OPERATION
            ? leftover : MAX_KEYS_FOR_MULTI_STORE_OPERATION;

    for (i = 0; i < consume; i++) {
      req_index[i] = -1;
      req_sv = safe_sv(aTHX_ ST(arg++));

      if (req_sv == NULL || !SvROK(req_sv) || SvTYPE(SvRV(req_sv)) != SVt_PVAV) {
        warn("kvs[%zu] arugment is not array reference.", finished + i);
        continue;
      }

      AV *req_av = (AV *) SvRV(req_sv);
      size_t idx = 0, size = av_count(req_av);

      if (size < 3) {
        warn("kvs[%zu] arugment is not sufficient.", finished + i);
        continue;
      }

      if ((req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) == NULL ||
          (req[valid_kvs].key = SvPV(*req_elem, req[valid_kvs].key_length)) == NULL) {
        warn("key of kvs[%zu] argument is invalid.", finished + i);
        continue;
      }

      if ((req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) == NULL ||
          !SvIOK(*req_elem) || (req[valid_kvs].cas = SvIV(*req_elem)) == 0) {
        warn("cas of kvs[%zu] argument is invalid.", finished + i);
        continue;
      }

      if ((req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) == NULL ||
          (req[valid_kvs].value = SvPV(*req_elem, req[valid_kvs].value_length)) == NULL) {
        warn("value of kvs[%zu] argument is invalid.", finished + i);
        continue;
      }

      if (size > idx && (req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) != NULL) {
        if (!SvIOK(*req_elem)) {
          warn("exptime of kvs[%zu] argument is invalid.", finished + i);
          continue;
        }
        req[valid_kvs].expiration = (time_t) SvIV(*req_elem);
      } else {
        req[valid_kvs].expiration = 0;
      }

      if (size > idx && (req_elem = safe_av_fetch(aTHX_ req_av, idx++, 0)) != NULL) {
        if (!SvIOK(*req_elem)) {
          warn("flags of kvs[%zu] argument is invalid.", finished + i);
          continue;
        }
        req[valid_kvs].flags = (uint32_t) SvIV(*req_elem);
      } else {
        req[valid_kvs].flags = 0;
      }

      req_index[i] = valid_kvs;
      valid_kvs++;
    }

    ret = memcached_mcas(mc, req, valid_kvs, results);
    if (ret == MEMCACHED_SUCCESS) {
      for (i = 0; i < consume; i++) {
        if (req_index[i] >= 0) {
          result_buf[finished + i] = newSViv(true);
        } else {
          result_buf[finished + i] = &PL_sv_undef;
        }
      }
    } else if (ret == MEMCACHED_FAILURE) {
      for (i = 0; i < consume; i++) {
        int idx = req_index[i];
        if (idx < 0) {
          result_buf[finished + i] = &PL_sv_undef;
          continue;
        }

        if (results[idx] == MEMCACHED_DATA_EXISTS || results[idx] == MEMCACHED_NOTFOUND) {
          result_buf[finished + i] = newSViv(false);
        } else {
          result_buf[finished + i] = &PL_sv_undef;
        }
      }
    } else { /* SOME ERRORS */
      for (i = 0; i < consume; i++) {
        int idx = req_index[i];
        if (idx < 0) {
          result_buf[finished + i] = &PL_sv_undef;
          continue;
        }

        if (memcached_success(results[idx])) {
          result_buf[finished + i] = newSViv(true);
        } else if (results[idx] == MEMCACHED_DATA_EXISTS || results[idx] == MEMCACHED_NOTFOUND) {
          result_buf[finished + i] = newSViv(false);
        } else {
          result_buf[finished + i] = &PL_sv_undef;
        }
      }
    }

    finished += consume;
    leftover -= consume;
  }

  EXTEND(SP, number_of_kvs);
  for (i = 0; i < number_of_kvs; i++) {
    mXPUSHs(result_buf[i]);
  }
  Safefree(result_buf);

  do_return:
  // nothing to do
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }

SV *
incr(arcus, key, ...)
  Arcus_API *arcus
  SV *key
  ALIAS:
  incr    = ARCUS_INCR
  decr    = ARCUS_DECR
  PROTOTYPE: $@
  PREINIT:
  int offset = 1;
  int arg = 2;
  CODE:
  RETVAL = NULL;
  memcached_return_t ret;
  char *key_ptr;
  size_t key_length;
  uint64_t value;

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  if (!SvOK(key) || (key_ptr = SvPV(key, key_length)) == NULL) {
    warn("key argument is invalid.");
    goto do_return;
  }

  SV *sv;
  if (items > arg && (sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
    if (!SvIOK(sv)) {
      warn("offset argument is invalid.");
      goto do_return;
    }
    offset = (int) SvIV(sv);
  }

  switch(ix) {
    case ARCUS_INCR:
      ret = memcached_increment(mc, key_ptr, key_length, offset, &value);
      break;
    case ARCUS_DECR:
      ret = memcached_decrement(mc, key_ptr, key_length, offset, &value);
      break;
    default:
      ret = MEMCACHED_FAILURE;
      break;
  }
  if (memcached_success(ret)) {
    if (value) {
      RETVAL = newSViv(value);
    } else {
      RETVAL = newSVpv("0E0", 0);
    }
  } else if (ret != MEMCACHED_NOTFOUND) {
    warn("failed to memcached_%s: %d (%s)", ARCUS_OP_NAME[ix], ret, memcached_strerror(mc, ret));
  }

  do_return:
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  if (RETVAL == NULL) {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
RETVAL

void
get(arcus, key)
  Arcus_API *arcus
  SV *key
  ALIAS:
  get    = ARCUS_GET
  gets   = ARCUS_GETS
  PPCODE:
  memcached_return_t ret;
  size_t key_length = 0;
  char *key_ptr = NULL;
  size_t value_length;
  char *value;
  uint32_t flags;
  bool is_gets = false;
  bool do_free_value = true;

  dSP;
  PUSHMARK(SP);

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  if (!SvOK(key) || (key_ptr = SvPV(key, key_length)) == NULL) {
    warn("key argument is invalid.");
    goto do_return;
  }

  if ((is_gets = (ix == ARCUS_GETS))) {
    memcached_behavior_set(mc, MEMCACHED_BEHAVIOR_SUPPORT_CAS, true);
  }

  value = memcached_get(mc, key_ptr, key_length, &value_length, &flags, &ret);
  if (memcached_success(ret) && value_length == 0 && value == NULL) {
    do_free_value = false;
    value = "";
  }

  if (value != NULL) {
    if (is_gets) {
      mXPUSHs(newSViv(((memcached_st *) mc)->result.item_cas));
    }
    mXPUSHs(newSVpv(value, value_length));
    mXPUSHs(newSViv(flags));

    if (do_free_value) {
      free(value);
    }
  } else if (ret != MEMCACHED_NOTFOUND) {
    warn("failed to memcached_get: %d (%s), value == NULL: %d",
         ret, memcached_strerror(mc, ret), value == NULL);
  }

  if (is_gets) {
    memcached_behavior_set(mc, MEMCACHED_BEHAVIOR_SUPPORT_CAS, false);
  }

  do_return:
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  PUTBACK;

HV *
get_multi(arcus, ...)
  Arcus_API *arcus
  ALIAS:
  get_multi    = ARCUS_GET
  gets_multi   = ARCUS_GETS
  PREINIT:
  size_t arg = 1;
  size_t i = 0;
  size_t valid_keys = 0;
  bool is_gets = false;
  CODE:
  memcached_return_t ret;
  char **keys_ptr = NULL;
  size_t *keys_length = NULL;
  SV *sv;

  RETVAL = newHV();
  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  size_t number_of_keys = items - arg;
  if (number_of_keys == 0) {
    warn("keys argument is empty.");
    goto do_return;
  }

  Newx(keys_ptr, number_of_keys, char *);
  Newx(keys_length, number_of_keys, size_t);

  for (i = 0; i < number_of_keys; i++) {
    if ((sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
      keys_ptr[valid_keys] = SvPV(sv, keys_length[valid_keys]);
    } else {
      keys_ptr[valid_keys] = NULL;
    }

    if (keys_ptr[valid_keys] == NULL || keys_length[valid_keys] == 0) {
      warn("keys[%zu] argument is invalid.", i);
    } else {
      valid_keys++;
    }
  }

  if ((is_gets = (ix == ARCUS_GETS))) {
    memcached_behavior_set(mc, MEMCACHED_BEHAVIOR_SUPPORT_CAS, true);
  }

  ret = memcached_mget(mc, (const char * const *) keys_ptr, keys_length, valid_keys);
  if (memcached_failed(ret) && ret != MEMCACHED_SOME_ERRORS) {
    warn("failed to mget: %d (%s)\n", ret, memcached_strerror(mc, ret));
    goto do_return;
  }

  while (true) {
    size_t key_len, value_len;
    char key[MEMCACHED_MAX_KEY];
    uint32_t flags = 0;
    char *value = memcached_fetch(mc, key, &key_len, &value_len, &flags, &ret);
    bool do_free_value = true;

    if (ret == MEMCACHED_END) {
      break;
    }
    if (memcached_success(ret) && value_len == 0 && value == NULL) {
      do_free_value = false;
      value = "";
    }

    if (value == NULL || memcached_failed(ret)) {
      warn("failed to fetch: %d (%s), value == NULL: %d", ret, memcached_strerror(mc, ret), value == NULL);
      break;
    }

    AV *arr = newAV();
    if (is_gets) {
      av_push(arr, newSViv(((memcached_st *) mc)->result.item_cas));
    }
    av_push(arr, newSVpv(value, value_len));
    av_push(arr, newSViv(flags));
    hv_store(RETVAL, key, key_len, newRV_noinc((SV *) arr), 0);

    if (do_free_value) {
      free(value);
    }
    value = NULL;
  }

  do_return:
  if (is_gets) {
    memcached_behavior_set(mc, MEMCACHED_BEHAVIOR_SUPPORT_CAS, false);
  }
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  if (keys_ptr != NULL) {
    Safefree(keys_ptr);
  }
  if (keys_length != NULL) {
    Safefree(keys_length);
  }
OUTPUT:
RETVAL

SV *
delete(arcus, key)
  Arcus_API *arcus
  SV *key
  CODE:
  memcached_return_t ret;
  RETVAL = NULL;
  STRLEN key_length;
  char *key_ptr = NULL;

  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  if (!SvOK(key) || (key_ptr = SvPV(key, key_length)) == NULL) {
    warn("key argument is invalid.");
    goto do_return;
  }

  ret = memcached_delete(mc, key_ptr, key_length, 0);
  RETVAL = newSViv(memcached_success(ret));

  do_return:
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  if (RETVAL == NULL) {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
RETVAL

SV *
flush_all(arcus, ...)
  Arcus_API *arcus
  PREINIT:
  time_t exptime = 0;
  int arg = 1;
  CODE:
  memcached_return_t ret;
  SV *sv = NULL;

  RETVAL = NULL;
  memcached_st *mc = memcached_pool_pop(arcus->pool, true, &ret);
  if (mc == NULL) {
    warn("Failed to create the memcached object : %d (%s)", ret, memcached_strerror(NULL, ret));
    goto do_return;
  }

  if (items > arg && (sv = safe_sv(aTHX_ ST(arg++))) != NULL) {
    if (!SvIOK(sv)) {
      warn("exptime argument is invalid.");
      goto do_return;
    }
    exptime = (time_t) SvIV(sv);
  }

  ret = memcached_flush(mc, exptime);
  RETVAL = newSViv(memcached_success(ret));

  do_return:
  if (mc != NULL) {
    memcached_pool_push(arcus->pool, mc);
  }
  if (RETVAL == NULL) {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
RETVAL

HV *
server_versions(arcus)
  Arcus_API *arcus
  CODE:
  memcached_return_t ret;
  RETVAL = newHV();
  int i;

  memcached_st *mc = arcus->global;
  if (mc == NULL) {
    warn("invalid mc.");
    goto do_return;
  }

  ret = memcached_version(mc);
  if (memcached_failed(ret)) {
    warn("failed to memcached_version: %d (%s)", ret, memcached_strerror(mc, ret));
    goto do_return;
  }

  for (i = 0; i < memcached_server_count(mc); i++) {
    memcached_server_instance_st server = memcached_server_instance_by_position(mc, i);
    SV *host = newSVpvf("%s:%d", server->hostname, server->port);
    SV *version = newSVpvf("%d.%d.%d", server->major_version,
                                       server->minor_version,
                                       server->micro_version);

    hv_store(RETVAL, SvPV_nolen(host), SvCUR(host), version, 0);
  }

  do_return:
  sv_2mortal((SV *) RETVAL);
OUTPUT:
RETVAL
