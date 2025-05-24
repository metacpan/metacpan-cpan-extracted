#ifndef CRYPT_SECRETBUFFER_H

typedef struct {
   char *data;
   size_t len, capacity;
   SV *stringify_sv;
} secret_buffer;

/* Create a new Crypt::SecretBuffer object with a mortal ref and return its secret_buffer
 * struct pointer.
 * If ref_out is NULL then the mortal ref remains mortal, and as your function exits the next
 * FREETMPS destroys the ref which destroys the object which destroys the magic which destroys
 * the secret_buffer struct which also clears it.
 * If you supply a pointer to receive ref_out, you can then increment the refcount or copy the
 * ref to a new SV if you want to keep the object.
 * Always returns a secret_buffer, or croaks on failure.
 */
extern secret_buffer* secret_buffer_new(size_t capacity, SV **ref_out);

/* Given a SV which you expect to be a reference to a blessed object with SecretBuffer
 * magic, return the secret_buffer struct pointer.
 * With no flags, this returns NULL if any of the above assumption are not correct.
 * Specify AUTOCREATE to create a new secret_buffer (and attach with magic) if it is a blessed
 * object and doesn't have the magic yet.
 * Specify OR_DIE if you want an exception instead of NULL return value.
 * Specify UNDEF_OK if you want input C<undef> to translate to C<NULL> even when OR_DIE is
 * requested.  i.e. undef becomes NULL but something which is not a SecretBuffer dies.
 */
#define SECRET_BUFFER_MAGIC_AUTOCREATE 1
#define SECRET_BUFFER_MAGIC_OR_DIE     2
#define SECRET_BUFFER_MAGIC_UNDEF_OK   4
extern secret_buffer* secret_buffer_from_magic(SV *ref, int flags);

/* Reallocate (or free) the buffer of secret_buffer, fully erasing it before deallocation.
 * If capacity is zero, the buffer will be freed and 'data' pointer set to NULL.
 * Any other size will allocate exactly that number of bytes, copy any previous bytes,
 * wipe the old buffer, and free it.
 */
extern void secret_buffer_realloc(secret_buffer *buf, size_t new_capacity);

/* Reallocate the buffer to have at least this many bytes.  This is a request for minimum total
 * capacity, not additional capacity.  If the buffer is already large enough, this does nothing.
 */
extern void secret_buffer_alloc_at_least(secret_buffer *buf, size_t min_capacity);

/* Set the length of defined data within the buffer.
 * If it shrinks, the bytes beyond the end get zeroed.
 * If it grows, the new bytes are zeroes (by virtue of having already cleared the allocation)
 */
extern void secret_buffer_set_len(secret_buffer *buf, size_t new_len);

/* Append N bytes of cryptographic quality random bytes to the end of the buffer.
 * This may block if your entropy pool is low.
 * If you request the flag 'NONBLOCK' it performs a non-blocking read.  Note that
 * only some systems block on lack of entropy in the first place; the flag is not
 * relevant on Windows.
 */
#define SECRET_BUFFER_NONBLOCK  1
extern IV secret_buffer_append_random(secret_buffer *buf, size_t n, unsigned flags);

/* Same semantics as sysread, but append all bytes received onto the end of the buffer.
 */
extern IV secret_buffer_append_sysread(secret_buffer *buf, PerlIO *fh, size_t count);

/* This first checks whether the perl I/O buffer has data in it, and uses that for as much of
 * the read as possible (and attempts to wipe that buffer).  If Perl does not have anything in
 * its I/O buffer, this performs a sysread.
 */
extern IV secret_buffer_append_read(secret_buffer *buf, PerlIO *fh, size_t count);

/* Append one line of text from a stream, stopping at the first CR or LF (or both).
 * The line terminator is not appended to the buffer.
 * If the stream is a TTY or Windows Console, this also disables echo while reading.
 *
 * The return value is 1 when a line is read to completion.  Otherwise it is the same result
 * as _append_sysread (0 for EOF, -1 for an OS error)
 */
#define SECRET_BUFFER_GOTLINE     1
#define SECRET_BUFFER_EOF         0
#define SECRET_BUFFER_INCOMPLETE -1
extern int secret_buffer_append_console_line(secret_buffer *buf, PerlIO *fh);

/* Same semantics as syswrite, but from a range of this buffer.
 */
extern IV secret_buffer_syswrite(secret_buffer *buf, PerlIO *fh, IV offset, IV count);

/* Write the entire (range of the) buffer into the file handle, using a thread if needed.
 * This first attempts a non-blocking write into the handle (such as a pipe) and then if it
 * would block, it creates a background thread that pumps data into the handle until complete
 * or until a fatal error.  The return value is just like syswrite except that if it returns
 * zero, the thread has been created.  If you want to be able to check for completion of the
 * write, pass a pointer reference to ref_out to receive the completion "promise" object.
 * The reference to the completion promise is mortal, and if it goes out of scope you won't
 * be able to check the status of the write anymore.
 */
extern IV secret_buffer_write_async(secret_buffer *buf, PerlIO *fh, IV offset, IV count,
   SV **ref_out);

/* Check the result of secret_buffer_write_async.  If it is still running, this returns false.
 * If true, then the operation is complete, and you can find out how many bytes it wrote and
 * whether an error occurred by passing references to be filled.
 */
extern bool secret_buffer_result_check(SV *promise_ref, int timeout_msec, IV *wrote, IV *os_err);

/* Requests that the write operation be stopped.  The write operation will stop anyway when it
 * gets a pipe error, but this is just in case you want to interrupt it before completion.
 *
X extern void secret_buffer_result_cancel(SV *promise_ref); */

/* Return a magical SV which exposes the secret buffer.
 * This should be used sparingly, if at all, for interoperating with perl code that isn't
 * aware of SecretBuffer and can't be fed the secret any other way.  Beware that the secret
 * may "get loose" unintentionally when allowing Perl to read the value as an SV.
 */
extern SV* secret_buffer_get_stringify_sv(secret_buffer *buf);

/* This is just exposing the wipe function of this library for general use.
 * It will be one of `explicit_bzero`, `SecureZeroMemory`, or just `bzero` which should
 * be fine since it's in an extern function.
 */
extern void secret_buffer_wipe(char *buf, size_t len);

#include "SecretBufferManualLinkage.h"

#endif /* CRYPT_SECRETBUFFER_H */
