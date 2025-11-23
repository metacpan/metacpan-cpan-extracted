#ifndef CRYPT_SECRETBUFFER_H

/* 'data' is an array of bytes allocated to 'capacity'.
 * 'len' is how much of the buffer is holding data.  All bytes beyond are zeros
 * 'stringify_sv' is initially NULL, but exists after the first stringify event
 * 'wrapper' is the object to which this struct is attached (via Magic)
 *   and will normally be an HV, but could potentially be other things if
 *   'secret_buffer_from_magic' was called on a non-HV ref with AUTOCREATE flag
 */
typedef struct {
   char *data;
   size_t len, capacity;
   SV *stringify_sv;
   SV *wrapper;
} secret_buffer;

struct secret_buffer_charset;
typedef struct secret_buffer_charset secret_buffer_charset;

/* Given a Regexp-ref either return a cached secret_buffer_charset from a
 * previous call, or build a new one by
 * analyzing the regexp, then cache it in MAGIC.
 * The regexp must be a single character class specification and nothing else,
 * but it may use the case-insensitive flag.  If the pattern uses anything more
 * than simple characters or ranges, the bitmap is determined by passing the
 * range of characters 0..255 through `s/$patern//g` and building the bitmap
 * from the result.
 */
extern secret_buffer_charset * secret_buffer_charset_from_regexpref(SV *ref);

/* Test whether the charset contains an 8-bit byte.
 * This relies solely on the bitmap.
 */
extern bool secret_buffer_charset_test_byte(const secret_buffer_charset *cset, U8 b);

/* Test whether the charset contains a unicode character.  This uses the perl regex
 * engine if the codepoint is higher than 0x7F, to ensure correct matching.
 */
extern bool secret_buffer_charset_test_codepoint(const secret_buffer_charset *cset, uint32_t cp);

/* encoding flags can be combined with other flags */
#define SECRET_BUFFER_ENCODING_MASK      0xFF
#define SECRET_BUFFER_ENCODING_ISO8859_1    0
#define SECRET_BUFFER_ENCODING_ASCII        1
#define SECRET_BUFFER_ENCODING_UTF8         2
#define SECRET_BUFFER_ENCODING_UTF16LE      3
#define SECRET_BUFFER_ENCODING_UTF16BE      4
#define SECRET_BUFFER_ENCODING_HEX          5
#define SECRET_BUFFER_ENCODING_MAX          5

#define SECRET_BUFFER_ENCODING_IS_UNICODE(x)  \
   (  (x) == SECRET_BUFFER_ENCODING_UTF8      \
   || (x) == SECRET_BUFFER_ENCODING_UTF16LE   \
   || (x) == SECRET_BUFFER_ENCODING_UTF16BE   \
   || (x) == SECRET_BUFFER_ENCODING_ISO8859_1 \
   )

typedef struct {
   U8 *pos, *lim;
   const char *error;
   int encoding;
} secret_buffer_parse;

/* Initialize a parse struct, and also verify that the described span is within the
 * defined length of the buffer.  If not, it returns false and sets ->error.
 */
extern bool secret_buffer_parse_init(secret_buffer_parse *parse,
   secret_buffer *buf, size_t pos, size_t lim, int encoding);

/* Scan through a SecretBuffer looking for the first (and maybe also last)
 * character belonging to a set.  The 'pos' and 'lim' of the parse struct
 * define the range that will be searched, and will be updated with the result
 * of the scan.  If pos == lim at the end, the character was not found.
 * Returns true if the scan completed (found or not) and false if it was
 * interrupted by an invalid character.
 *
 * The _NEGATE flag can be used to negate the charset without altering it.
 *
 * The _REVERSE flag can be used to search backward from [lim-1] back to [pos],
 * in which case 'lim' will be updated with the results of the scan.
 *
 * The _SPAN flag requests that after finding the first match and updating
 * 'pos' (or 'lim' if reversed), it will then begin looking for a character not
 * belonging to the charset, and then update 'lim'. (or 'pos' if reversed)
 *
 * If the parse state specifies an encoding, pos and lim must be at character
 * boundaries, and invalid characters will stop the parse and store a message
 * in ->error, also updating pos (or lim) to indicate the byte offset.
 * Note that every codepoint higher than 255 compared to a charset with the
 * maybe_unicode flag will call out to the perl regex engine and be a bit slow.
 */
#define SECRET_BUFFER_MATCH_REVERSE  0x100
#define SECRET_BUFFER_MATCH_NEGATE   0x200
#define SECRET_BUFFER_MATCH_MULTI    0x400
#define SECRET_BUFFER_MATCH_ANCHORED 0x800
extern bool secret_buffer_match(secret_buffer_parse *p, SV *pattern, int flags);
extern bool secret_buffer_match_charset(secret_buffer_parse *p, secret_buffer_charset *cset, int flags);
extern bool secret_buffer_match_bytestr(secret_buffer_parse *p, char *data, size_t datalen, int flags);

/* Count number of bytes required to transcode the source.
 * If the source contains an invalid character for its encoding, or that codepoint
 * can't be encoded as the dst_encoding, this returns -1 and sets src->error
 * and also sets src->pos pointing at the character that could not be converted.
 */
extern SSize_t secret_buffer_sizeof_transcode(secret_buffer_parse *src, int dst_encoding);
extern bool secret_buffer_transcode(secret_buffer_parse *src, secret_buffer_parse *dst);

/* Create a new Crypt::SecretBuffer object with a mortal ref and return its secret_buffer
 * struct pointer.
 * If ref_out is NULL then the mortal ref remains mortal, and as your function exits the next
 * FREETMPS destroys the ref which destroys the object which destroys the magic which destroys
 * the secret_buffer struct which also clears it.
 * If you supply a pointer to receive ref_out, you can then increment the refcount or copy the
 * ref to a new SV if you want to keep the object.
 * Always returns a secret_buffer, or croaks on failure.
 */
extern secret_buffer * secret_buffer_new(size_t capacity, SV **ref_out);

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
extern secret_buffer * secret_buffer_from_magic(SV *ref, int flags);

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

/* Overwrite a span of the buffer with the supplied bytes.  The buffer length is updated
 * to match.  Offset and length are unsigned, so they do not support the "negative from end of
 * buffer" convention common to Perl.
 */
extern void secret_buffer_splice(secret_buffer *buf, size_t ofs, size_t len,
   const char *replacement, size_t replacement_len);
/* Convenience to combine secret_buffer_SvPVbyte with secret_buffer_splice */
extern void secret_buffer_splice_sv(secret_buffer *buf, size_t ofs, size_t len, SV *replacement);

/* Given an SV, perform SvPVbyte on it, but make special cases for SecretBuffer,
 * SecretBuffer::Span, or un-blessed scalar-refs.  Note that the return value has all of the
 * caveats of SvPVbyte (like maybe returning a temporary buffer) and also all the caveats of
 * returning a pointer into a SecretBuffer, namely that if you alter that SecretBuffer
 * elsewhere the pointer is no longer valid.  It may even return a pointer to static data.
 * The string is *NOT* terminated with a NUL byte, and you must pass 'len_out'.
 */
extern const char * secret_buffer_SvPVbyte(SV *thing, STRLEN *len_out);

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
extern SV * secret_buffer_get_stringify_sv(secret_buffer *buf);

/* This is just exposing the wipe function of this library for general use.
 * It will be one of `explicit_bzero`, `SecureZeroMemory`, or just `bzero` which should
 * be fine since it's in an extern function.
 */
extern void secret_buffer_wipe(char *buf, size_t len);

#endif /* CRYPT_SECRETBUFFER_H */
