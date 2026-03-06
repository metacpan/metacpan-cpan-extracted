/*
 * SecretBuffer Span Magic
 */

void *secret_buffer_span_auto_ctor(pTHX_ SV *owner) {
   secret_buffer_span *span= NULL;
   Newxz(span, 1, secret_buffer_span);
   return span;
}
secret_buffer_span* secret_buffer_span_from_magic(SV *objref, int flags) {
   dTHX;
   return (secret_buffer_span*) secret_buffer_X_from_magic(aTHX_
      objref, flags,
      &secret_buffer_span_magic_vtbl, "secret_buffer_span",
      secret_buffer_span_auto_ctor);
}

int secret_buffer_span_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   if (mg->mg_ptr) {
      Safefree(mg->mg_ptr);
      mg->mg_ptr = NULL;
   }
   return 0;
}

#ifdef USE_ITHREADS
int secret_buffer_span_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   secret_buffer_span *clone= NULL;
   PERL_UNUSED_VAR(param);
   if (mg->mg_ptr) {
      Newx(clone, 1, secret_buffer_span);
      memcpy(clone, mg->mg_ptr, sizeof(secret_buffer_span));
      mg->mg_ptr = (char *)clone;
   }
   return 0;
}
#endif

static SV *new_mortal_span_obj(pTHX_ secret_buffer *buf, UV pos, UV lim, int encoding) {
   HV *hv= newHV();
   SV *ref= sv_2mortal(newRV_noinc((SV*) hv));
   sv_bless(ref, gv_stashpv("Crypt::SecretBuffer::Span", GV_ADD));

   secret_buffer_span *span= secret_buffer_span_from_magic(ref, SECRET_BUFFER_MAGIC_AUTOCREATE);
   hv_stores(hv, "buf", newRV_inc(buf->wrapper));
   span->pos= pos;
   span->lim= lim;
   span->encoding= encoding;
   return ref;
}

/* Public API: Return a mortal ref to a new SecretBuffer::Span */
extern SV *secret_buffer_span_new_obj(secret_buffer *buf, size_t pos, size_t lim, int encoding) {
   dTHX;
   return new_mortal_span_obj(aTHX_ buf, pos, lim, encoding);
}

/* Public API: Return a mortal ref to a new SecretBuffer::Span using fields of a parse */
extern SV *secret_buffer_span_new_obj_from_parse(secret_buffer_parse *src) {
   dTHX;
   U8 *sbuf_start, *sbuf_lim;
   if (!src->sbuf)
      croak("parse struct lacks secret_buffer reference");
   /* sanity check on pos and lim since this is about to subtract pointers */
   sbuf_start= (U8*) src->sbuf->data;
   sbuf_lim= sbuf_start + src->sbuf->len;
   if (src->pos < sbuf_start || src->pos > sbuf_lim)
      croak("parse->pos out of bounds");
   if (src->pos_bit)
      croak("parse->pos is not on a byte boundary");
   if (src->lim < src->pos || src->lim > sbuf_lim)
      croak("parse->lim out of bounds");
   if (src->lim_bit)
      croak("parse->lim is not on a byte boundary");
   return new_mortal_span_obj(aTHX_ src->sbuf, src->pos - sbuf_start, src->lim - sbuf_start, src->encoding);
}
