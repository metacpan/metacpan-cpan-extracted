use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer;

# These exported functions need to be as stable as possible for other modules
# that want to depend on SecretBuffer.  The signatures, parameter names, and
# even a bit of the whitespace in the prototype need to remain the same across
# versions.
# For new functions, leave a space between the type and '*', and also leave a
# space between '*' and the function name, but no space between the '*' and the
# variable name.
is \%Crypt::SecretBuffer::C_API,
   {
      secret_buffer_charset_from_regexpref =>
         'secret_buffer_charset * secret_buffer_charset_from_regexpref(SV *ref)',
      secret_buffer_charset_test_byte =>
         'bool secret_buffer_charset_test_byte(const secret_buffer_charset *cset, U8 b)',
      secret_buffer_charset_test_codepoint =>
         'bool secret_buffer_charset_test_codepoint(const secret_buffer_charset *cset, uint32_t cp)',
      secret_buffer_parse_init =>
         'bool secret_buffer_parse_init(secret_buffer_parse *parse, secret_buffer *buf, size_t pos, size_t lim, int encoding)',
      secret_buffer_parse_init_from_sv =>
         'bool secret_buffer_parse_init_from_sv(secret_buffer_parse *parse, SV *sv)',
      secret_buffer_match =>
         'bool secret_buffer_match(secret_buffer_parse *p, SV *pattern, int flags)',
      secret_buffer_match_charset =>
         'bool secret_buffer_match_charset(secret_buffer_parse *p, secret_buffer_charset *cset, int flags)',
      secret_buffer_match_bytestr =>
         'bool secret_buffer_match_bytestr(secret_buffer_parse *p, char *data, size_t datalen, int flags)',
      secret_buffer_sizeof_transcode =>
         'SSize_t secret_buffer_sizeof_transcode(secret_buffer_parse *src, int dst_encoding)',
      secret_buffer_transcode =>
         'bool secret_buffer_transcode(secret_buffer_parse *src, secret_buffer_parse *dst)',
      secret_buffer_new =>
         'secret_buffer * secret_buffer_new(size_t capacity, SV **ref_out)',
      secret_buffer_from_magic =>
         'secret_buffer * secret_buffer_from_magic(SV *ref, int flags)',
      secret_buffer_realloc =>
         'void secret_buffer_realloc(secret_buffer *buf, size_t new_capacity)',
      secret_buffer_alloc_at_least =>
         'void secret_buffer_alloc_at_least(secret_buffer *buf, size_t min_capacity)',
      secret_buffer_set_len =>
         'void secret_buffer_set_len(secret_buffer *buf, size_t new_len)',
      secret_buffer_SvPVbyte =>
         'const char * secret_buffer_SvPVbyte(SV *thing, STRLEN *len_out)',
      secret_buffer_splice =>
         'void secret_buffer_splice(secret_buffer *buf, size_t ofs, size_t len, const char *replacement, size_t replacement_len)',
      secret_buffer_splice_sv =>
         'void secret_buffer_splice_sv(secret_buffer *buf, size_t ofs, size_t len, SV *replacement)',
      secret_buffer_append_random =>
         'IV secret_buffer_append_random(secret_buffer *buf, size_t n, unsigned flags)',
      secret_buffer_append_sysread =>
         'IV secret_buffer_append_sysread(secret_buffer *buf, PerlIO *fh, size_t count)',
      secret_buffer_append_read =>
         'IV secret_buffer_append_read(secret_buffer *buf, PerlIO *fh, size_t count)',
      secret_buffer_append_console_line =>
         'int secret_buffer_append_console_line(secret_buffer *buf, PerlIO *fh)',
      secret_buffer_syswrite =>
         'IV secret_buffer_syswrite(secret_buffer *buf, PerlIO *fh, IV offset, IV count)',
      secret_buffer_write_async =>
         'IV secret_buffer_write_async(secret_buffer *buf, PerlIO *fh, IV offset, IV count, SV **ref_out)',
      secret_buffer_result_check =>
         'bool secret_buffer_result_check(SV *promise_ref, int timeout_msec, IV *wrote, IV *os_err)',
      secret_buffer_get_stringify_sv =>
         'SV * secret_buffer_get_stringify_sv(secret_buffer *buf)',
      secret_buffer_wipe =>
         'void secret_buffer_wipe(char *buf, size_t len)'
   },
   'API';

done_testing;
