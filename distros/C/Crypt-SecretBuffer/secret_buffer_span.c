/*
 * SecretBuffer Span Magic
 */

void *secret_buffer_span_auto_ctor(SV *owner) {
   secret_buffer_span *span= NULL;
   Newxz(span, 1, secret_buffer_span);
   return span;
}
secret_buffer_span* secret_buffer_span_from_magic(SV *objref, int flags) {
   return (secret_buffer_span*) secret_buffer_X_from_magic(
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
