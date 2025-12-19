/**********************************************************************************************\
* SecretBuffer C API
\**********************************************************************************************/

/* Given a SV which you expect to be a reference to a blessed object with SecretBuffer
 * magic, return the secret_buffer struct pointer.
 * With no flags, this returns NULL is any of the above assumption is not correct.
 * Specify AUTOCREATE to create a new secret_buffer (and attach with magic) if it is a blessed
 * object and doesn't have the magic yet.
 * Specify OR_DIE if you want an exception instead of NULL return value.
 * Specify UNDEF_OK if you want input C<undef> to translate to C<NULL> even when OR_DIE is
 * requested.
 */
void *secret_buffer_auto_ctor(SV *owner) {
   secret_buffer *buf= NULL;
   Newxz(buf, 1, secret_buffer);
   buf->wrapper= owner;
   return buf;
}
secret_buffer* secret_buffer_from_magic(SV *obj, int flags) {
   return (secret_buffer*) secret_buffer_X_from_magic(
      obj, flags,
      &secret_buffer_magic_vtbl, "secret_buffer",
      secret_buffer_auto_ctor);
}

/* Create a new Crypt::SecretBuffer object with a mortal ref and return the secret_buffer.
 * If ref_out is NULL then the mortal ref remains mortal and the buffer is freed at the next
 * FREETMPS as your function exits.  If you supply a pointer to receive ref_out, you can then
 * increment the refcount or copy the ref if you want to keep the object.
 * Always returns a secret_buffer, or croaks on failure.
 */
secret_buffer* secret_buffer_new(size_t capacity, SV **ref_out) {
   SV *ref= sv_2mortal(newRV_noinc((SV*) newHV()));
   sv_bless(ref, gv_stashpv("Crypt::SecretBuffer", GV_ADD));
   secret_buffer *buf= secret_buffer_from_magic(ref, SECRET_BUFFER_MAGIC_AUTOCREATE);
   if (capacity) secret_buffer_alloc_at_least(buf, capacity);
   if (ref_out) *ref_out= ref;
   return buf;
}

/* Reallocate (or free) the buffer of secret_buffer, fully erasing it before deallocation.
 * If capacity is zero, the buffer will be freed and 'data' pointer set to NULL.
 * Any other size will allocate exactly that number of bytes, copy any previous bytes,
 * wipe the old buffer, and free it.
 * Note that the entire capacity is copied regardless of 'len', to prevent timing attacks from
 * deducing the exact length of the secret.
 */
void secret_buffer_realloc(secret_buffer *buf, size_t new_capacity) {
   if (buf->capacity != new_capacity) {
      if (new_capacity) {
         char *old= buf->data;
         Newxz(buf->data, new_capacity, char);
         if (old && buf->capacity) {
            memcpy(buf->data, old, new_capacity < buf->capacity? new_capacity : buf->capacity);
            secret_buffer_wipe(old, buf->capacity);
            Safefree(old);
         }
      } else { /* new capacity is zero, so free the buffer */
         if (buf->data && buf->capacity) {
            secret_buffer_wipe(buf->data, buf->capacity);
            Safefree(buf->data);
            buf->data= NULL;
         }
      }
      buf->capacity= new_capacity;
      if (buf->len > buf->capacity)
         buf->len= buf->capacity;
      
      /* If has been exposed as "stringify" sv, update that SV */
      if (buf->stringify_sv) {
         SvPVX(buf->stringify_sv)= buf->data;
         SvCUR(buf->stringify_sv)= buf->len;
      }
   }
}

/* Reallocate the buffer to have at least this many bytes.  This is a request for minimum total
 * capacity, not additional capacity.  If the buffer is already large enough, this does nothing.
 */
void secret_buffer_alloc_at_least(secret_buffer *buf, size_t min_capacity) {
   if (buf->capacity < min_capacity) {
      /* round up to a multiple of 64 */
      secret_buffer_realloc(buf, (min_capacity + 63) & ~(size_t)63);
   }
}

/* Set the length of defined data within the buffer.
 * If it shrinks, the bytes beyond the end get zeroed.
 * If it grows, the new bytes are zeroes (by virtue of having already cleared the allocation)
 */
void secret_buffer_set_len(secret_buffer *buf, size_t new_len) {
   if (new_len > buf->capacity)
      secret_buffer_alloc_at_least(buf, new_len);
   /* if it shrinks, need to wipe those bytes.  If it grows, the extra is already zeroed */
   if (new_len < buf->len)
      secret_buffer_wipe(buf->data + new_len, buf->capacity - new_len);
   buf->len= new_len;
   /* If the stringify scalar has been exposed to perl, update its length */
   if (buf->stringify_sv)
      SvCUR(buf->stringify_sv)= new_len;
}

/* Return a pointer to some data and the length of that data, using SvPVbyte or equivalent
 * for SecretBuffer or SecretBuffer::Span objects.
 */
const char *secret_buffer_SvPVbyte(SV *thing, STRLEN *len_out) {
   secret_buffer *src_buf;
   secret_buffer_span *span;
   // The string is not NUL-terminated, so the user must use this value
   if (!len_out)
      croak("len_out is required");
   // if it is a ref to something that isn't an object (like a scalar-ref)
   // then load from that instead.
   if (thing && SvROK(thing) && !sv_isobject(thing))
      thing= SvRV(thing);
   // NULL or undef represent an empty string
   if (!thing || !SvOK(thing)) {
      *len_out= 0;
      return "";
   }
   else if ((src_buf= secret_buffer_from_magic(thing, 0))) {
      *len_out= src_buf->len;
      return src_buf->data? src_buf->data : "";
   }
   else if ((span= secret_buffer_span_from_magic(thing, 0))) {
      SV **buf_field= hv_fetchs(((HV*)SvRV(thing)), "buf", 0);
      if (!buf_field || !*buf_field || !(src_buf= secret_buffer_from_magic(*buf_field, 0)))
         croak("Span lacks reference to source buffer");
      if (span->lim > src_buf->len || span->pos > span->lim)
         croak("Span references invalid range of source buffer");
      *len_out= span->lim - span->pos;
      return src_buf->data? (src_buf->data + span->pos) : "";
   }
   else {
      return SvPVbyte(thing, *len_out);
   }
}

/* Overwrite the span of the buffer with the contents of the SV, taking into account
 * whether it might be a scalar-ref, SecretBuffer, or SecretBuffer::Span.
 */
void secret_buffer_splice(secret_buffer *buf, size_t ofs, size_t len,
      const char *replacement, size_t replacement_len
) {
   IV tail_len;
   const char *splice_pos;

   if (ofs > buf->len)
      croak("Attempt to splice beyond end of buffer");
   if (ofs + len > buf->len)
      len= buf->len - ofs;

   tail_len= buf->len - (ofs + len);
   if (replacement_len > len) /* buffer is growing */
      secret_buffer_set_len(buf, buf->len + (replacement_len - len));
   splice_pos= buf->data + ofs;
   //warn("splice: buf->data=%p buf->len=%d buf->capacity=%d ofs=%d len=%d replacement=%p replacement_len=%d splice_pos=%p tail_len=%d",
   //   buf->data, (int)buf->len, (int)buf->capacity, (int)ofs, (int)len, replacement, (int)replacement_len, splice_pos, (int)tail_len);
   /* copy anything beyond the splice to its new location */
   if (tail_len)
      Move(splice_pos + len, splice_pos + replacement_len, tail_len, unsigned char);
   /* copy new data */
   if (replacement_len)
      Copy(replacement, splice_pos, replacement_len, unsigned char);
   if (replacement_len < len) /* buffer shrank, wipe remainder */
      secret_buffer_set_len(buf, buf->len - len + replacement_len);
}

void secret_buffer_splice_sv(secret_buffer *buf, size_t ofs, size_t len, SV *replacement) {
   STRLEN repl_len;
   const char *repl_str= secret_buffer_SvPVbyte(replacement, &repl_len);
   secret_buffer_splice(buf, ofs, len, repl_str, repl_len);
}

/* This is just exposing the wipe function of this library for general use.
 * It will be OPENSSL_cleanse if openssl (and headers) were available when this package was
 * compiled, or a simple 'explicit_bzero' or 'Zero' otherwise.
 */
void secret_buffer_wipe(char *buf, size_t len) {
#if defined WIN32
   SecureZeroMemory(buf, len);
#elif defined(HAVE_EXPLICIT_BZERO)
   explicit_bzero(buf, len);
#else
   /* this ought to be sufficient anyway because its within an extern function */
   Zero(buf, len, char);
#endif
}

IV secret_buffer_append_random(secret_buffer *buf, size_t n, unsigned flags) {
   size_t orig_len= buf->len;

   if (!n)
      return 0;
   if (buf->capacity < buf->len + n)
      secret_buffer_alloc_at_least(buf, buf->len + n);

#ifdef WIN32
   {
      HCRYPTPROV hProv;

      if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT))
         croak_with_syserror("CryptAcquireContext failed", GetLastError());

      if (!CryptGenRandom(hProv, n, buf->data + buf->len)) {
         DWORD err_id= GetLastError();
         CryptReleaseContext(hProv, 0);
         croak_with_syserror("CryptGenRandom failed", err_id);
      }
      secret_buffer_set_len(buf, buf->len + n);

      CryptReleaseContext(hProv, 0);
   }
#else
   int got;
   #ifndef HAVE_GETRANDOM
   int fd= open("/dev/random", O_RDONLY | (flags & SECRET_BUFFER_NONBLOCK? O_NONBLOCK : 0));
   if (fd < 0) croak("Failed opening /dev/random");
   #endif
   while (n > 0) {
      #ifdef HAVE_GETRANDOM
      got= getrandom(buf->data + buf->len, n, GRND_RANDOM | (flags & SECRET_BUFFER_NONBLOCK? GRND_NONBLOCK : 0));
      #else
      got= read(fd, buf->data + buf->len, n);
      #endif
      if (got <= 0) {
         if (got < 0 && errno == EINTR)
            continue; /* keep trying */
         if ((flags & SECRET_BUFFER_NONBLOCK) && (got == 0 || errno == EWOULDBLOCK || errno == EAGAIN))
            break; /* user requested a single try */
         #ifdef HAVE_GETRANDOM
         croak_with_syserror("getrandom", errno);
         #else
         croak_with_syserror("read /dev/random", errno);
         #endif
      }
      secret_buffer_set_len(buf, buf->len + got);
      n -= got;
   }
#endif
   return (IV)(buf->len - orig_len);
}

/* Approximate perl's sysread implementation (esp for Win32) on our secret buffer.
 * Also warn if Perl has buffered data for this handle.
 */
IV secret_buffer_append_sysread(secret_buffer *buf, PerlIO *stream, size_t count) {
   int ret;
   int stream_fd= PerlIO_fileno(stream);
   if (stream_fd < 0)
      croak("Handle has no system file descriptor (fileno)");
   if (PerlIO_get_cnt(stream))
      warn("Handle has buffered input, ignored by sysread");
   /* reserve buffer space */
   if (buf->capacity < buf->len + count)
      secret_buffer_alloc_at_least(buf, buf->len + count);
#ifdef WIN32
   {
      HANDLE hFile = (HANDLE)_get_osfhandle(stream_fd);
      DWORD bytes_read;
      if (hFile == INVALID_HANDLE_VALUE)
         croak("Handle has no system file descriptor");
      if (!ReadFile(hFile, buf->data + buf->len, (DWORD)count, &bytes_read, NULL)) {
         /* POSIX only gives EPIPE to the writer, the reader gets a 0 read to indicate EOF.
          * Win32 gives this error to the reader instead of a 0 read. */
         if (GetLastError() == ERROR_BROKEN_PIPE)
            return 0;
         return -1;
      }
      secret_buffer_set_len(buf, buf->len + bytes_read);
      return bytes_read;
   }
#else
   {
      ret= read(stream_fd, buf->data + buf->len, count);
      if (ret > 0)
         secret_buffer_set_len(buf, buf->len + ret);
      return ret;
   }
#endif
}

/* Approximate perl's syswrite implementation (esp for Win32) on our secret buffer.
 * Also flush any perl buffer, first.
 */
IV secret_buffer_syswrite(secret_buffer *buf, PerlIO *stream, IV offset, IV count) {
   int stream_fd= PerlIO_fileno(stream);
   /* translate negative offset or negative count, in the manner of substr */
   offset= normalize_offset(offset, buf->len);
   count= normalize_offset(count, buf->len - offset);
   /* flush any buffered data already on the handle */
   PerlIO_flush(stream);

   if (stream_fd < 0)
      croak("Handle has no system file descriptor (fileno)");
#ifdef WIN32
   {
      HANDLE hFile = (HANDLE)_get_osfhandle(stream_fd);
      DWORD wrote;
      if (hFile == INVALID_HANDLE_VALUE)
         croak("Handle has no system file descriptor");
      if (!WriteFile(hFile, buf->data + offset, (DWORD)count, &wrote, NULL))
         return -1;
      return wrote;
   }
#else
   return write(stream_fd, buf->data + offset, count);
#endif
}

/* Read any existing buffered data from Perl, and sysread otherwise.
 * There's not much point if the handle is virtual because the secret will be
 * elsewhere in memory, but 
 */
IV secret_buffer_append_read(secret_buffer *buf, PerlIO *stream, size_t count) {
   int stream_fd= PerlIO_fileno(stream);
   int n_buffered= PerlIO_get_cnt(stream);
   char *perlbuffer;
   /* if it's a virtual handle, or if perl has already buffered some data, then read from PerlIO */
   if (stream_fd < 0 || n_buffered > 0) {
      if (!n_buffered) {
         if (PerlIO_fill(stream) < 0)
            return -1;
         n_buffered= PerlIO_get_cnt(stream);
         if (!n_buffered)
            return 0;
      }
      /* Read from Perl's buffer, then wipe it if safe to do so */
      perlbuffer= PerlIO_get_ptr(stream);
      if (count > n_buffered)
         count= n_buffered;
      {
         size_t off = buf->len;
         secret_buffer_set_len(buf, buf->len + count);
         memcpy(buf->data + off, perlbuffer, count);
      }
      /* secret_buffer_wipe(perlbuffer, count); could be a scalar, or read-only constant, or shared string table :-(  */
      PerlIO_set_ptrcnt(stream, perlbuffer+count, n_buffered-count);
      return count;
   }
   /* Its a real descriptor with no buffer, so sysread */
   else
      return secret_buffer_append_sysread(buf, stream, count);
}

