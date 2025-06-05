#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#define NEED_newSVpvn_share
#include "ppport.h"

#ifndef HAVE_NATIVE_BOOL
   #ifdef HAVE_STDBOOL
      #include <stdbool.h>
   #else
      #define bool int
      #define true 1
      #define false 0
   #endif
#endif

#include "SecretBuffer.h"

/**********************************************************************************************\
* XS Utils
\**********************************************************************************************/

/* Common perl idioms for negative offset or negative count */
static inline IV normalize_offset(IV ofs, IV len) {
   if (ofs < 0) {
      ofs += len;
      if (ofs < 0)
         ofs= 0;
   }
   else if (ofs > len)
      ofs= len;
   return ofs;
}

/* For exported constant dualvars */
#define EXPORT_ENUM(x) newCONSTSUB(stash, #x, new_enum_dualvar(aTHX_ x, newSVpvs_share(#x)))
static SV * new_enum_dualvar(pTHX_ IV ival, SV *name) {
   SvUPGRADE(name, SVt_PVNV);
   SvIV_set(name, ival);
   SvIOK_on(name);
   SvREADONLY_on(name);
   return name;
}

/**********************************************************************************************\
* Platform compatibility stuff
\**********************************************************************************************/

#ifdef WIN32
#include <wincrypt.h>

static size_t get_page_size() {
   SYSTEM_INFO sysInfo;
   GetSystemInfo(&sysInfo);
   return sysInfo.dwPageSize;
}

typedef DWORD syserror_type;
#define GET_SYSERROR(x) ((x)= GetLastError())
#define SET_SYSERROR(x) SetLastError(x)

static void croak_with_syserror(const char *prefix, DWORD error_code) {
   char message_buffer[512];
   DWORD length;

   length = FormatMessageA(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL,
      error_code,
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      message_buffer,
      sizeof(message_buffer),
      NULL
   );

   if (length)
      croak("%s: %s (%lu)", prefix, message_buffer, error_code);
   else
      croak("%s: %lu", prefix, error_code);
}

typedef DWORD console_state;

static bool disable_console_echo(int fd, console_state *prev_state) {\
   DWORD new_mode= 0;
   HANDLE hConsole= fd >= 0? (HANDLE)_get_osfhandle(fd) : INVALID_HANDLE_VALUE;
   if (hConsole == INVALID_HANDLE_VALUE || GetFileType(hConsole) != FILE_TYPE_CHAR)
      return false;
   /* Capture current state */
   if (!GetConsoleMode(hConsole, prev_state))
      return false;
   new_mode = *prev_state & ~ENABLE_ECHO_INPUT;
   return SetConsoleMode(hConsole, new_mode);
}

static bool restore_console_state(int fd, console_state *prev_state) {
   HANDLE hConsole= fd >= 0? (HANDLE)_get_osfhandle(fd) : INVALID_HANDLE_VALUE;
   if (hConsole == INVALID_HANDLE_VALUE || GetFileType(hConsole) != FILE_TYPE_CHAR)
      return false;
   return SetConsoleMode(hConsole, *prev_state);
}

#else /* not WIN32 */
#include <pthread.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

static size_t get_page_size() {
   long pagesize = sysconf(_SC_PAGESIZE);
   return (pagesize < 0)? 4096 : pagesize;
}

#define GET_SYSERROR(x) ((x)= errno)
#define SET_SYSERROR(x) (errno= (x))
typedef int syserror_type;

#define croak_with_syserror(msg, err) croak("%s: %s", msg, strerror(err))

typedef struct termios console_state;

static bool disable_console_echo(int fd, console_state *prev_state) {
   struct termios new_state;
   /* Check if stream is a TTY */
   if (fd < 0 || !isatty(fd))
      return false;
   if (tcgetattr(fd, prev_state) != 0)
      return false;
   new_state= *prev_state;
   new_state.c_lflag &= ~ECHO;
   return tcsetattr(fd, TCSAFLUSH, &new_state) == 0;
}

static bool restore_console_state(int fd, console_state *prev_state) {
   return tcsetattr(fd, TCSAFLUSH, prev_state) == 0;
}

#endif

#if HAVE_GETRANDOM
#include <sys/random.h>
#endif

/* Shim for systems that lack memmem */
#ifndef HAVE_MEMMEM
static void* memmem(
   const void *haystack, size_t haystacklen,
   const void *needle, size_t needlelen
) {
   const char *p= (const char*) haystack;
   const char *lim= p + haystacklen - needlelen;
   char first_ch= *(char*)needle;
   while (p < lim) {
      if (*p == first_ch) {
         if (memcmp(p, needle, needlelen) == 0)
            return (void*)p;
      }
      ++p;
   }
   return NULL;
}
#endif /* HAVE_MEMMEM */

/**********************************************************************************************\
* MAGIC vtables
\**********************************************************************************************/

#ifdef USE_ITHREADS
static int secret_buffer_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param);
static int secret_buffer_stringify_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *params);
static int secret_buffer_async_result_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *params);
#else
#define secret_buffer_magic_dup 0
#define secret_buffer_stringify_magic_dup 0
#define secret_buffer_async_result_magic_dup 0
#endif

static int secret_buffer_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_magic_vtbl = {
   NULL, NULL, NULL, NULL,
   secret_buffer_magic_free,
   NULL,
   secret_buffer_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

static int secret_buffer_stringify_magic_get(pTHX_ SV *sv, MAGIC *mg);
static int secret_buffer_stringify_magic_set(pTHX_ SV *sv, MAGIC *mg);
static int secret_buffer_stringify_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_stringify_magic_vtbl = {
   secret_buffer_stringify_magic_get,
   secret_buffer_stringify_magic_set,
   NULL, NULL,
   secret_buffer_stringify_magic_free,
   NULL,
   secret_buffer_stringify_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

static int secret_buffer_async_result_magic_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL secret_buffer_async_result_magic_vtbl = {
   NULL, NULL, NULL, NULL,
   secret_buffer_async_result_magic_free,
   NULL,
   secret_buffer_async_result_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

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
secret_buffer* secret_buffer_from_magic(SV *obj, int flags) {
   SV *sv;
   MAGIC *magic;
   secret_buffer *buf;

   if ((!obj || !SvOK(obj)) && (flags & SECRET_BUFFER_MAGIC_UNDEF_OK))
      return NULL;

   if (!sv_isobject(obj)) {
      if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
         croak("Not an object");
      return NULL;
   }
   sv = SvRV(obj);
   if (SvMAGICAL(sv) && (magic = mg_findext(sv, PERL_MAGIC_ext, &secret_buffer_magic_vtbl)))
      return (secret_buffer*) magic->mg_ptr;

   if (flags & SECRET_BUFFER_MAGIC_AUTOCREATE) {
      Newxz(buf, 1, secret_buffer);
      magic = sv_magicext(sv, NULL, PERL_MAGIC_ext, &secret_buffer_magic_vtbl, (const char*) buf, 0);
#ifdef USE_ITHREADS
      magic->mg_flags |= MGf_DUP;
#endif
      return buf;
   }
   if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
      croak("Object lacks 'secret_buffer' magic");
   return NULL;
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
         if (got < 0 && errno == EAGAIN)
            continue; /* keep trying */
         if ((flags & SECRET_BUFFER_NONBLOCK) && (got == 0 || errno == EWOULDBLOCK || errno == EINTR))
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

/* returns number of bytes on success, 0 for EOF (or count==0) even if some bytes appended,
 * or -1 for temporary error. croaks on fatal error.
 */
int secret_buffer_append_console_line(secret_buffer *buf, PerlIO *stream) {
   /* PerlIO may or may not be backed by a real OS file descriptor */
   int stream_fd= PerlIO_fileno(stream);
   /* Disable echo, if possible */
   console_state prev_state;
   bool console_changed= disable_console_echo(stream_fd, &prev_state);
   /* Read one character at a time, because once we find "\n" the rest needs to stay in the OS buffer.
    * This is inefficient, but passwords are relatively short so it hardly matters.
    */
   int got= 0;
   while (1) {
      got= secret_buffer_append_read(buf, stream, 1);
      if (got <= 0)
         break;
      if (buf->data[buf->len - 1] == '\r' || buf->data[buf->len - 1] == '\n') {
         char *eol= buf->data + buf->len - 1;
         --buf->len; /* back up one char */
         /* in the event of reading a text file, try to consume the "\n" that follows a "\r".
          * If we get anything else, push it back into Perl's buffer.
          */
         if (*eol == '\r') {
            if (secret_buffer_append_read(buf, stream, 1) > 0) {
               --buf->len;
               if (*eol != '\n') {
                  if (PerlIO_ungetc(stream, *eol) == EOF)
                     warn("BUG: lost a character of the input stream");
               }
            }
         }
         *eol= 0;
         break;
      }
   }
   /* Restore echo if we disabled it */
   if (console_changed)
      restore_console_state(stream_fd, &prev_state);
   
   /* Any EOF is returned as an EOF even if some data appended */
   return got;
}

/**********************************************************************************************\
* Async write implementation
\**********************************************************************************************/

typedef struct {
   int refcount;
#ifdef WIN32
   CRITICAL_SECTION cs;
   HANDLE startEvent, readyEvent, threadHandle, fd;
   #define ASYNC_RESULT_MUTEX_LOCK(x)      EnterCriticalSection(&((x)->cs))
   #define ASYNC_RESULT_MUTEX_UNLOCK(x)    LeaveCriticalSection(&((x)->cs))
   #define ASYNC_RESULT_IS_THREAD_ALIVE(x) ((x)->threadHandle != INVALID_HANDLE_VALUE && WaitForSingleObject((x)->threadHandle, 0) == WAIT_TIMEOUT)
   #define ASYNC_RESULT_NOTIFY_STARTED(x)  SetEvent((x)->readyEvent)
   #define ASYNC_RESULT_NOTIFY_COMPLETE(x) SetEvent((x)->startEvent)
#else
   pthread_mutex_t mutex;
   pthread_cond_t cond;
   pthread_t threadHandle;
   int fd;
   #define ASYNC_RESULT_MUTEX_LOCK(x)      pthread_mutex_lock(&((x)->mutex))
   #define ASYNC_RESULT_MUTEX_UNLOCK(x)    pthread_mutex_unlock(&((x)->mutex))
   #define ASYNC_RESULT_IS_THREAD_ALIVE(x) ((x)->threadHandle > 0 && pthread_kill((x)->threadHandle, 0) == 0)
   #define ASYNC_RESULT_NOTIFY_STARTED(x)  pthread_cond_signal(&((x)->cond))
   #define ASYNC_RESULT_NOTIFY_COMPLETE(x) pthread_cond_signal(&((x)->cond))
#endif
   bool started, ready;
   IV os_err;
   IV total_written;
   IV secret_len;
   char secret[];
} secret_buffer_async_result;

SV *secret_buffer_async_result_wrap_with_object(secret_buffer_async_result *result) {
   SV *ref= sv_2mortal(newRV_noinc(newSV(0)));
   MAGIC *mg= sv_magicext(SvRV(ref), NULL, PERL_MAGIC_ext, &secret_buffer_async_result_magic_vtbl, (const char *)result, 0);
#ifdef USE_ITHREADS
   mg->mg_flags |= MGf_DUP;
#endif
   return sv_bless(ref, gv_stashpv("Crypt::SecretBuffer::AsyncResult", GV_ADD));
}

secret_buffer_async_result* secret_buffer_async_result_from_magic(SV *obj, int flags) {
   SV *sv;
   MAGIC *magic;

   if ((!obj || !SvOK(obj)) && (flags & SECRET_BUFFER_MAGIC_UNDEF_OK))
      return NULL;

   if (!sv_isobject(obj)) {
      if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
         croak("Not an object");
      return NULL;
   }
   sv = SvRV(obj);
   if (SvMAGICAL(sv) && (magic = mg_findext(sv, PERL_MAGIC_ext, &secret_buffer_magic_vtbl)))
      return (secret_buffer_async_result*) magic->mg_ptr;
   if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
      croak("Object lacks 'secret_buffer_async_result' magic");
   return NULL;
}

secret_buffer_async_result *secret_buffer_async_result_new(int fd, secret_buffer *buf, size_t ofs, size_t count) {
   secret_buffer_async_result *result= (secret_buffer_async_result *)
      malloc(sizeof(secret_buffer_async_result) + count);
   Zero(((char*)result), sizeof(secret_buffer_async_result) + count, char);
#ifdef WIN32
   InitializeCriticalSection(&result->cs);
   /* Duplicate the file handle for the thread */
   if (fd >= 0) {
      if (!DuplicateHandle(GetCurrentProcess(), (HANDLE)_get_osfhandle(fd), GetCurrentProcess(), &result->fd, 
            0, FALSE, DUPLICATE_SAME_ACCESS)
      ) {
         free(result);
         croak_with_syserror("DuplicateHandle", GetLastError());
      }
   } else {
      result->fd= INVALID_HANDLE_VALUE;
   }
   result->readyEvent= CreateEvent(NULL, TRUE, FALSE, NULL);
   result->startEvent= CreateEvent(NULL, TRUE, FALSE, NULL);
   if (result->readyEvent == NULL || result->startEvent == NULL) {
      if (result->readyEvent) CloseHandle(result->readyEvent);
      CloseHandle(result->fd);
      free(result);
      croak_with_syserror("CreateEvent", GetLastError());
   }
#else /* POSIX */
   result->fd= fd >= 0? dup(fd) : -1;
   if (result->fd < 0) {
      free(result);
      croak_with_syserror("dup", errno);
   }
   pthread_mutex_init(&result->mutex, NULL);
   pthread_cond_init(&result->cond, NULL);
#endif
   result->ready= result->started= false;
   if (count)
      memcpy(buf->data + ofs, result->secret, count);
   result->secret_len= count;
   result->refcount= 1;
   return result;
}

/* One refcount is held by the main thread, and one by the worker thread */
void secret_buffer_async_result_release(secret_buffer_async_result *result, bool from_thread) {
   bool destroy= false, cleanup_thread_half= false, cleanup_perl_half= false;
   ASYNC_RESULT_MUTEX_LOCK(result);
   if (from_thread) {
      cleanup_thread_half= true;
      destroy= --result->refcount == 0;
   } else {
      /* check whether thread exited without cleaning up, and dec refcount if so */
      if (!result->ready && !ASYNC_RESULT_IS_THREAD_ALIVE(result)) {
         warn("writer thread died without cleaning up");
         cleanup_thread_half= true;
         result->ready= true;
         --result->refcount;
      }
      destroy= --result->refcount == 0;
      cleanup_perl_half= destroy || (!result->ready && result->refcount == 1);
   }
   if (cleanup_thread_half) {
      result->ready= true;
      secret_buffer_wipe(result->secret, result->secret_len);
      #ifdef WIN32
      if (result->fd != INVALID_HANDLE_VALUE)
         CloseHandle(result->fd);
      result->fd= INVALID_HANDLE_VALUE;
      #else
      if (result->fd >= 0)
         close(result->fd);
      result->fd= -1;
      #endif
   }
   if (cleanup_perl_half) {
      /* Detach so resources are freed on exit */
      #ifdef WIN32
      CloseHandle(result->threadHandle);
      #else /* POSIX */
      pthread_detach(result->threadHandle); /* Parent continues without waiting for child */
      #endif
   }
   ASYNC_RESULT_MUTEX_UNLOCK(result);
   /* can't destroy mutexes while locked */
   if (destroy) {
#ifdef WIN32
      DeleteCriticalSection(&result->cs);
      CloseHandle(result->startEvent);
      CloseHandle(result->readyEvent);
      if (result->fd != INVALID_HANDLE_VALUE)
         CloseHandle(result->fd);
#else
      pthread_mutex_destroy(&result->mutex);
      pthread_cond_destroy(&result->cond);
#endif
      free(result);
   }
}

void secret_buffer_async_result_acquire(secret_buffer_async_result *result) {
   ASYNC_RESULT_MUTEX_LOCK(result);
   ++result->refcount;
   ASYNC_RESULT_MUTEX_UNLOCK(result);
}

int secret_buffer_async_result_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   secret_buffer_async_result_release((secret_buffer_async_result *) mg->mg_ptr, false);
   return 0;
}
#ifdef USE_ITHREADS
int secret_buffer_async_result_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *p) {
   secret_buffer_async_result_acquire((secret_buffer_async_result *) mg->mg_ptr);
   return 0;
}
#endif

void secret_buffer_async_result_send(secret_buffer_async_result *result, IV os_err) {
   ASYNC_RESULT_MUTEX_LOCK(result);
   result->os_err= os_err;
   result->ready= true;
#ifdef WIN32
   SetEvent(result->readyEvent);
#else
   pthread_cond_signal(&result->cond);
#endif
   ASYNC_RESULT_MUTEX_UNLOCK(result);
}

bool secret_buffer_async_result_recv(secret_buffer_async_result *result, IV timeout_msec, IV *total_written, IV *os_err) {
   bool ready= false;
#ifdef WIN32
   DWORD ret = WaitForSingleObject(result->readyEvent, timeout_msec < 0? INFINITE : timeout_msec);
   if (ret == WAIT_TIMEOUT)
      return false;
   if (ret != WAIT_OBJECT_0)
      croak_with_syserror("WaitForSingleObject", GetLastError());
   ready= true;
   ASYNC_RESULT_MUTEX_LOCK(result);
#else
   struct timespec ts;
   /* timedwait operates on absolute wallclock time
    * This is sort of dangerous since wallclock time can change... but the only
    * alternative I see would be to play with the alarm signal.
    */
   if (timeout_msec >= 0) {
      clock_gettime(CLOCK_REALTIME, &ts);
      ts.tv_sec += timeout_msec / 1000;
      ts.tv_nsec += (timeout_msec % 1000) * 1000000;
      if (ts.tv_nsec >= 1000000000) {
         ts.tv_sec += 1;
         ts.tv_nsec -= 1000000000;
      }
   }
   ASYNC_RESULT_MUTEX_LOCK(result);
   /* Wait until data is ready or timeout occurs */
   while (!result->ready) {
      int rc = timeout_msec < 0? pthread_cond_wait(&result->cond, &result->mutex)
         : pthread_cond_timedwait(&result->cond, &result->mutex, &ts);
      if (rc == ETIMEDOUT)
         break;
      ready= result->ready;
   }
#endif
   /* If we got the data successfully, read it and reset the ready flag */
   if (ready) {
      if (total_written) *total_written= result->total_written;
      if (os_err) *os_err= result->os_err;
   }
   ASYNC_RESULT_MUTEX_UNLOCK(result);
   return ready;
}

bool secret_buffer_result_check(SV *promise_ref, int timeout_msec, IV *wrote, IV *os_err) {
   return secret_buffer_async_result_recv(
      secret_buffer_async_result_from_magic(promise_ref, SECRET_BUFFER_MAGIC_OR_DIE),
      timeout_msec, wrote, os_err);
}


/* Worker thread for background writing.
 * This thread receives a copy of the secret in the secret_buffer_async_result
 * (along with a duplicated file handle) and it uses blocking writes to push the
 * data through the handle,  It updates the async_result fields as it goes,
 * then uses a condvar/event to flag the main thread when it is done.
 * The thread is responsible for erasing the secret, but the main thread can
 * also erase the secret if it sees that the worker thread died.
 */
#ifdef WIN32
DWORD WINAPI secret_buffer_async_writer(LPVOID arg) {
#else
void *secret_buffer_async_writer(void *arg) {
#endif
   secret_buffer_async_result *result = (secret_buffer_async_result *) arg;
   ASYNC_RESULT_MUTEX_LOCK(result);
   ++result->refcount;
   result->started= true;
   ASYNC_RESULT_MUTEX_UNLOCK(result);
   /* no need to lock mutex for the written/secret/fd fields since the receiver isn't
    * allowed to use them until this thread sets 'ready' or thread dies */
#ifdef WIN32
   while (result->total_written < result->secret_len) {
      DWORD wrote;
      if (WriteFile((HANDLE) result->fd, result->secret + result->total_written,
         (DWORD)(result->secret_len - result->total_written), &wrote, NULL)
      ) {
         if (wrote == 0) {
            secret_buffer_async_result_send(result, 0);
            break;
         }
         result->total_written += wrote;
      }
      else {
         secret_buffer_async_result_send(result, GetLastError());
      }
   }
#else /* POSIX */
   /* Blocking mode assumed */
   while (result->total_written < result->secret_len) {
      ssize_t wrote= write(result->fd, result->secret + result->total_written,
                     result->secret_len - result->total_written);
      if (wrote <= 0) {
         if (wrote < 0 && errno == EINTR)
            continue;
         else if (wrote < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            /* it's a nonblocking handle. use select() to wait for it to become writable */
            fd_set writeable;
            FD_ZERO(&writeable);
            FD_SET(result->fd, &writeable);
            if (select(result->fd + 1, NULL, &writeable, NULL, NULL) > 0 || errno == EINTR)
               /* next write attempt should make progress */
               continue;
            /* something went wrong, bail out */
         }
         secret_buffer_async_result_send(result, wrote == 0? 0 : errno);
         break;
      }
      result->total_written += wrote;
   }
#endif /* POSIX */
   secret_buffer_async_result_release(result, true);
   return 0;
}

IV secret_buffer_write_async(secret_buffer *buf, PerlIO *fh, IV offset, IV count, SV **ref_out) {
   IV total_written= 0;
   secret_buffer_async_result *result= NULL;
   int fd;
   /* translate negative offset or negative count, in the manner of substr */
   offset= normalize_offset(offset, buf->len);
   count= normalize_offset(count, buf->len - offset);
   /* flush any buffered data already on the handle */
   PerlIO_flush(fh);

   if (count == 0)
      return 0;

   fd= PerlIO_fileno(fh);
   if (fd < 0)
      croak("Invalid file descriptor");
#ifdef WIN32
   /* On Windows, there is no universal way to attempt a nonblocking write.  So, check if its a
      pipe, and then use nonblocking pipe write, and otherwise always create the worker thread.
      The intent for this module is to write small secrets on pipes, so in most cases the
      thread won't be created anyway.
    */
   {
      HANDLE hFile = (HANDLE)_get_osfhandle(fd);
      DWORD ret;
      if (GetFileType(hFile) == FILE_TYPE_PIPE) {
         DWORD origPipeMode = 0;
         DWORD bytesWritten, lastError;
         BOOL success;

         if (!GetNamedPipeHandleState(hFile, &origPipeMode, NULL, NULL, NULL, NULL, 0))
            croak_with_syserror("GetNamedPipeHandleState", GetLastError());
         if (!(origPipeMode & PIPE_NOWAIT)) {
            /* Set pipe to non-blocking mode temporarily */
            DWORD nonBlockMode = PIPE_NOWAIT;
            if (!SetNamedPipeHandleState(hFile, &nonBlockMode, NULL, NULL))
               croak_with_syserror("SetNamedPipeHandleState", GetLastError());
         }

         /* Try nonblocking write */
         success= WriteFile(hFile, buf->data + offset, count, &bytesWritten, NULL);
         lastError = GetLastError();

         /* Restore original pipe state */
         if (!(origPipeMode & PIPE_NOWAIT)) {
            SetNamedPipeHandleState(hFile, &origPipeMode, NULL, NULL);
            SetLastError(lastError);
         }
        
         if (success && bytesWritten == count)
            return count; /* Write completed immediately */
         else if (!success && lastError != ERROR_NO_DATA)
            /* an actual error */
            return -1;
         total_written= (IV) bytesWritten;
      }
      /* Launch thread */
      result= secret_buffer_async_result_new(fd, buf, offset, count);
      result->total_written= total_written;
      result->threadHandle= CreateThread(
         NULL,                   /* default security attributes */
         0,                      /* default stack size */
         (LPTHREAD_START_ROUTINE)secret_buffer_async_writer,
         result,                 /* thread parameter */
         0,                      /* default creation flags */
         NULL);                  /* receive thread identifier */
      if (result->threadHandle == NULL) {
         secret_buffer_async_result_release(result, false);
         croak_with_syserror("Failed to create thread", GetLastError());
      }
      /* make sure thread starts and takes ownership of its refcount */
      WaitForSingleObject(result->startEvent, INFINITE);
   }
#else /* POSIX */
   {
      pthread_t thread;
      /* Set non-blocking mode if needed */
      int old_flags = fcntl(fd, F_GETFL);
      if (!(old_flags & O_NONBLOCK))
         if (fcntl(fd, F_SETFL, old_flags | O_NONBLOCK) < 0)
            croak_with_syserror("Failed to set nonblocking mode on handle", errno);

      /* First write attempt */
      total_written = write(fd, buf->data + offset, count);

      /* Restore blocking mode if we changed it */
      if (!(old_flags & O_NONBLOCK)) {
         int save_errno= errno;
         fcntl(fd, F_SETFL, old_flags);
         errno= save_errno;
      }

      if (total_written == count)
         return count; /* Write completed immediately */
      else if (total_written < 0 && errno != EAGAIN && errno != EWOULDBLOCK)
         return -1; /* actual error */
      if (total_written < 0)
         total_written= 0;
      /* launch thread */
      result= secret_buffer_async_result_new(fd, buf, offset, count);
      result->total_written= total_written;
      if (pthread_create(&thread, NULL, secret_buffer_async_writer, result) != 0) {
         secret_buffer_async_result_release(result, false);
         croak_with_syserror("Failed to create thread", errno);
      }
      /* make sure thread starts and takes ownership of its refcount */
      ASYNC_RESULT_MUTEX_LOCK(result);
      if (!result->started)
         pthread_cond_wait(&result->cond, &result->mutex);
      ASYNC_RESULT_MUTEX_UNLOCK(result);
   } /* POSIX */
#endif
   if (ref_out)
      /* Caller requests a reference to the result */
      *ref_out= secret_buffer_async_result_wrap_with_object(result);
   else
      /* nobody cares, so release our reference to the result.  The thread will carry on silently */
      secret_buffer_async_result_release(result, false);
   return 0;
}

/**********************************************************************************************\
* SecretBuffer stringify magic
\**********************************************************************************************/

int secret_buffer_stringify_magic_get(pTHX_ SV *sv, MAGIC *mg) {
   secret_buffer *buf= (secret_buffer *)mg->mg_ptr;
   assert(buf->stringify_sv == sv);
   SvPVX(sv)= buf->data? buf->data : "";
   SvCUR(sv)= buf->data? buf->len  : 0;
   SvPOK_on(sv);
   SvUTF8_off(sv);
   SvREADONLY_on(sv);
   return 0;
}

int secret_buffer_stringify_magic_set(pTHX_ SV *sv, MAGIC *mg) {
   warn("Attempt to assign stringify scalar");
   return 0;
}

int secret_buffer_stringify_magic_free(pTHX_ SV *sv, MAGIC *mg) {
/*   warn("Freeing stringify scalar"); */
   return 0;
}

#ifdef USE_ITHREADS
int secret_buffer_stringify_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   croak("Can't dup stringify_sv");
}
#endif

SV* secret_buffer_get_stringify_sv(secret_buffer *buf) {
   SV *sv= buf->stringify_sv;
   if (!sv) {
      sv= buf->stringify_sv= newSV(0);
      sv_magicext(sv, NULL, PERL_MAGIC_ext, &secret_buffer_stringify_magic_vtbl, (const char *)buf, 0);
#ifdef USE_ITHREADS
      /* magic->mg_flags |= MGf_DUP; it doesn't support duplication, so does the flag need set? */
#endif
      SvPOK_on(sv);
      SvUTF8_off(sv);
      SvREADONLY_on(sv);
   }
   SvPVX(sv)= buf->data? buf->data : "";
   SvCUR(sv)= buf->data? buf->len  : 0;
   return sv;
}

/*
 * SecretBuffer Magic
 */

int secret_buffer_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   secret_buffer *buf= (secret_buffer*) mg->mg_ptr;
   if (buf) {
      secret_buffer_realloc(buf, 0);
      if (buf->stringify_sv)
         sv_2mortal(buf->stringify_sv);
      Safefree(mg->mg_ptr);
      mg->mg_ptr = NULL;
   }
   return 0;
}

#ifdef USE_ITHREADS
int secret_buffer_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   secret_buffer *clone, *orig = (secret_buffer *)mg->mg_ptr;
   PERL_UNUSED_VAR(param);
   Newxz(clone, 1, secret_buffer);
   mg->mg_ptr = (char *)clone;
   secret_buffer_set_len(clone, orig->len);
   if (orig->len)
      memcpy(clone->data, orig->data, orig->capacity < clone->capacity? orig->capacity : clone->capacity);
   return 0;
}
#endif

/* Aliases for typemap */
typedef secret_buffer  *auto_secret_buffer;
typedef secret_buffer  *maybe_secret_buffer;

/* flag for capacity */
#define SECRET_BUFFER_AT_LEAST 1

/* Convenience to convert string parameters to the corresponding integer so that Perl-side
 * doesn't always need to import the flag constants.
 */
IV parse_io_flags(SV *sv) {
   if (!sv || !SvOK(sv))
      return 0;
   if (SvIOK(sv))
      return SvIV(sv);
   if (SvPOK(sv)) {
      const char *str= SvPV_nolen(sv);
      if (!str[0]) return 0;
      if (strcmp(str, "NONBLOCK") == 0)  return SECRET_BUFFER_NONBLOCK;
   }
   croak("Unknown flag %s", SvPV_nolen(sv));
}

IV parse_alloc_flags(SV *sv) {
   if (!sv || !SvOK(sv))
      return 0;
   if (SvIOK(sv))
      return SvIV(sv);
   if (SvPOK(sv)) {
      const char *str= SvPV_nolen(sv);
      if (!str[0]) return 0;
      if (strcmp(str, "AT_LEAST") == 0)  return SECRET_BUFFER_AT_LEAST;
   }
   croak("Unknown flag %s", SvPV_nolen(sv));
}

/* for typemap to automatically convert flags */
typedef int secret_buffer_io_flags;
typedef int secret_buffer_alloc_flags;

/**********************************************************************************************\
 * Debug helpers
\**********************************************************************************************/

/* Helper function to check if a memory page is accessible (committed and readable) */
#if defined(WIN32)
   #define CAN_SCAN_MEMORY 1
   static bool is_page_accessible(uintptr_t addr) {
      MEMORY_BASIC_INFORMATION memInfo;
      if (VirtualQuery((LPCVOID)addr, &memInfo, sizeof(memInfo)) == 0)
         return FALSE;
      return (memInfo.State == MEM_COMMIT) && 
            (memInfo.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE));
   }
#elif defined(HAVE_MINCORE)
   #define CAN_SCAN_MEMORY 1
   #include <sys/mman.h>
   static bool is_page_accessible(uintptr_t addr) {
      unsigned char vec;
      return mincore((void*)addr, 1, &vec) == 0;
   }
#else
   #define CAN_SCAN_MEMORY 0
#endif

/* The rest only works if we have is_page_accessible */
#if CAN_SCAN_MEMORY
IV scan_mapped_memory_in_range(uintptr_t p, uintptr_t lim, const char *needle, size_t needle_len) {
   size_t pagesize= get_page_size();
   size_t count= 0;
   void *at;
   uintptr_t run_start = p, run_lim;
   p = (p & ~(pagesize - 1)); /* round to nearest page, from here out */
   while (p < lim) {
      /* Skip pages that aren't mapped */
      while (p < lim && !is_page_accessible(p)) {
         p += pagesize;
         run_start= p;
      }
      /* This page is mapped.  Find the end of this mapped range, if it comes before lim */
      while (p < lim && is_page_accessible(p)) {
         p += pagesize;
      }
      run_lim= p < lim? p : lim;
      /* Scan memory from run_start to run_lim */
      while (run_start < run_lim && (at= memmem((void*)run_start, run_lim - run_start, needle, needle_len))) {
         ++count;
         run_start= ((intptr_t)at) + needle_len;
      }
   }
   return count;
}
#else
IV scan_mapped_memory_in_range(uintptr_t p, uintptr_t lim, const char *needle, size_t needle_len) {
   return -1;
}
#endif

/**********************************************************************************************\
* Crypt::SecretBuffer API
\**********************************************************************************************/
MODULE = Crypt::SecretBuffer                     PACKAGE = Crypt::SecretBuffer
PROTOTYPES: DISABLE

void
assign(buf, source= NULL)
   auto_secret_buffer buf
   SV *source;
   INIT:
      const char *str;
      STRLEN len;
   PPCODE:
      /* re-initializing? throw away previous value */
      if (buf->data)
         secret_buffer_realloc(buf, 0);
      if (source) {
         secret_buffer *src_buf= secret_buffer_from_magic(source, 0);
         if (src_buf) {
            secret_buffer_set_len(buf, src_buf->len);
            if (src_buf->len)
               memcpy(buf->data, src_buf->data, src_buf->capacity < buf->capacity? src_buf->capacity : buf->capacity);
         }
         else if (!SvROK(source)) {
            str= SvPVbyte(source, len);
            if (len) {
               secret_buffer_set_len(buf, len);
               memcpy(buf->data, str, len);
            }
         }
         else {
            croak("Don't know how to copy data from %s", SvPV_nolen(source));
         }
      }
      XSRETURN(1); /* return self for chaining */

void
length(buf, val=NULL)
   auto_secret_buffer buf
   SV *val
   PPCODE:
      if (val) { /* writing */
         IV ival= SvIV(val);
         if (ival < 0) ival= 0;
         secret_buffer_set_len(buf, ival);
         /* return self, for chaining */
      }
      else /* reading */
         ST(0)= sv_2mortal(newSViv(buf->len));
      XSRETURN(1);

void
capacity(buf, val=NULL, flags= 0)
   auto_secret_buffer buf
   SV *val
   secret_buffer_alloc_flags flags
   PPCODE:
      if (val) { /* wiritng */
         IV ival= SvIV(val);
         if (ival < 0) ival= 0;
         if (flags & SECRET_BUFFER_AT_LEAST)
            secret_buffer_alloc_at_least(buf, ival);
         else
            secret_buffer_realloc(buf, ival);
         /* return self, for chaining */
      }
      else /* reading */
         ST(0)= sv_2mortal(newSViv(buf->capacity));
      XSRETURN(1);

void
clear(buf)
   auto_secret_buffer buf
   PPCODE:
      secret_buffer_realloc(buf, 0);
      XSRETURN(1); /* self, for chaining */

IV
index(buf, substr, ofs= 0)
   auto_secret_buffer buf
   SV *substr
   IV ofs
   INIT:
      char *found;
      STRLEN len;
      const char *str= SvPV(substr, len);
   CODE:
      /* normalize negative offset, and clamp to valid range */
      ofs= normalize_offset(ofs, buf->len);
      found= (char*) memmem(buf->data + ofs, buf->len - ofs, str, len);
      RETVAL= found? found - buf->data : -1;
      /* documented bug from glibc 2.0 */
      if (RETVAL >= buf->len) RETVAL= -1;
   OUTPUT:
      RETVAL

void
substr(buf, ofs, count_sv=NULL, replacement=NULL)
   auto_secret_buffer buf
   IV ofs
   SV *count_sv
   SV *replacement
   INIT:
      unsigned char *sub_start;
      secret_buffer *sub_buf= NULL;
      SV *sub_ref= NULL;
      IV count= count_sv? SvIV(count_sv) : buf->len;
   PPCODE:
      /* normalize negative offset, and clamp to valid range */
      ofs= normalize_offset(ofs, buf->len);
      /* normalize negative count, and clamp to valid range */
      count= normalize_offset(count, buf->len - ofs);
      sub_start= (unsigned char*) buf->data + ofs;
      /* If called in non-void context, construct new secret from this range */
      if (GIMME_V != G_VOID) {
         SV **el;
         sub_buf= secret_buffer_new(count, &sub_ref);
         if (count) {
            Copy(sub_start, sub_buf->data, count, unsigned char);
            sub_buf->len= count;
         }
         /* inherit the stringify_mask */
         el= hv_fetchs((HV*) SvRV(ST(0)), "stringify_mask", 0);
         if (el && *el)
            /* we know the hv isn't tied because we just created it, so no need to check success */
            hv_stores((HV*) SvRV(sub_ref), "stringify_mask", newSVsv(*el));
      }
      /* modifying string? */
      if (replacement) {
         IV tail_len= buf->len - (ofs + count);
         IV len_diff;
         const unsigned char *repl_src;
         STRLEN repl_len;

         /* Debatable whether I should allow plain SVs here, or force the user to wrap the data
          * in a secreyt_buffer first... */
         if (SvPOK(replacement)) {
            repl_src= (const unsigned char*) SvPV(replacement, repl_len);
         } else {
            secret_buffer *peer= secret_buffer_from_magic(replacement, SECRET_BUFFER_MAGIC_OR_DIE);
            repl_src= (const unsigned char*) peer->data;
            repl_len= peer->len;
         }
         len_diff= repl_len - count;
         if (len_diff > 0) /* buffer is growing */
            secret_buffer_alloc_at_least(buf, buf->len + len_diff);
         /* copy anything beyond the insertion point to its new location */
         if (tail_len)
            Move(sub_start + count, sub_start + repl_len, tail_len, unsigned char);
         if (repl_len)
            Copy(repl_src, sub_start, repl_len, unsigned char);
         buf->len += len_diff;
      }
      /* If void context, return nothing.  Else return the substr */
      if (!sub_ref)
         XSRETURN(0);
      else {
         ST(0)= sub_ref; /* already mortal */
         XSRETURN(1);
      }

UV
append_random(buf, count, flags=0)
   auto_secret_buffer buf
   UV count
   secret_buffer_io_flags flags
   CODE:
      RETVAL= secret_buffer_append_random(buf, count, flags);
   OUTPUT:
      RETVAL

void
append_sysread(buf, handle, count)
   auto_secret_buffer buf
   PerlIO *handle
   IV count
   INIT:
      IV got;
   PPCODE:
      got= secret_buffer_append_read(buf, handle, count);
      ST(0)= (got < 0)? &PL_sv_undef : sv_2mortal(newSViv(got));
      XSRETURN(1);

void
append_read(buf, handle, count)
   auto_secret_buffer buf
   PerlIO *handle
   IV count
   INIT:
      int got;
   PPCODE:
      got= secret_buffer_append_read(buf, handle, count);
      ST(0)= (got < 0)? &PL_sv_undef : sv_2mortal(newSViv(got));
      XSRETURN(1);

void
append_console_line(buf, handle)
   auto_secret_buffer buf
   PerlIO *handle
   INIT:
      int got;
   PPCODE:
      got= secret_buffer_append_console_line(buf, handle);
      ST(0)= got == SECRET_BUFFER_GOTLINE? &PL_sv_yes
         : got == SECRET_BUFFER_EOF? &PL_sv_no
         : &PL_sv_undef;
      XSRETURN(1);

void
syswrite(buf, io, count=buf->len, ofs=0)
   auto_secret_buffer buf
   PerlIO *io
   IV ofs
   IV count
   INIT:
      IV wrote;
   PPCODE:
      wrote= secret_buffer_syswrite(buf, io, ofs, count);
      ST(0)= (wrote < 0)? &PL_sv_undef : sv_2mortal(newSViv(wrote));
      XSRETURN(1);

void
write_async(buf, io, count=buf->len, ofs=0)
   auto_secret_buffer buf
   PerlIO *io
   IV ofs
   IV count
   INIT:
      IV wrote;
      SV *ref_out= NULL;
   PPCODE:
      wrote= secret_buffer_write_async(buf, io, ofs, count, GIMME_V == G_VOID? NULL : &ref_out);
      /* wrote == 0 means that it supplied a result promise object, which is already mortal.
       * but avoid creating one when called in void context. */
      ST(0)= wrote? sv_2mortal(newSViv(wrote)) : ref_out? ref_out : &PL_sv_undef;
      XSRETURN(1);

void
stringify(buf, ...)
   auto_secret_buffer buf
   INIT:
      SV **field= hv_fetch((HV*)SvRV(ST(0)), "stringify_mask", 14, 0);
   PPCODE:
      if (!field || !*field) {
         ST(0)= sv_2mortal(newSVpvn("[REDACTED]", 10));
      } else if (SvOK(*field)) {
         ST(0)= *field;
      } else {
         ST(0)= secret_buffer_get_stringify_sv(buf);
      }
      XSRETURN(1);

bool
_can_count_copies_in_process_memory()
   CODE:
      RETVAL= false;
   OUTPUT:
      RETVAL
   
IV
_count_matches_in_mem(buf, addr0, addr1)
   secret_buffer *buf
   UV addr0
   UV addr1
   CODE:
      if (!buf->len)
         croak("Empty buffer");
      RETVAL= scan_mapped_memory_in_range(addr0, addr1, buf->data, buf->len);
   OUTPUT:
      RETVAL

MODULE = Crypt::SecretBuffer                     PACKAGE = Crypt::SecretBuffer::AsyncResult

void
wait(result, timeout=-1)
   secret_buffer_async_result *result
   NV timeout
   INIT:
      IV os_err, bytes_written;
   PPCODE:
      if (secret_buffer_async_result_recv(result, (IV)(timeout*1000), &bytes_written, &os_err)) {
         EXTEND(sp, 2);
         ST(0)= sv_2mortal(newSViv(bytes_written));
         ST(1)= sv_2mortal(newSViv(os_err));
         XSRETURN(2);
      } else {
         XSRETURN(0);
      }

BOOT:
   HV *stash= gv_stashpvn("Crypt::SecretBuffer", 19, 1);
   newCONSTSUB(stash, "NONBLOCK",  new_enum_dualvar(aTHX_ SECRET_BUFFER_NONBLOCK,  newSVpvs_share("NONBLOCK")));
   newCONSTSUB(stash, "AT_LEAST",  new_enum_dualvar(aTHX_ SECRET_BUFFER_AT_LEAST,  newSVpvs_share("AT_LEAST")));
   SECRET_BUFFER_EXPORT_FUNCTION_POINTERS
