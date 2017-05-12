#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "perl_math_int64_types.h"
#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"
#include "func.h"

#include <string.h>
#include <archive.h>
#include <archive_entry.h>

#include "perl_archive.h"

typedef const char *string_or_null;

static int
myopen(struct archive *archive, void *client_data)
{
  int count;
  int status;
  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  PUTBACK;
  
  count = call_pv("Archive::Libarchive::XS::_myopen", G_SCALAR);
  
  SPAGAIN;
  
  status = POPi;
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return status;
}

static __LA_INT64_T
myread(struct archive *archive, void *client_data, const void **buffer)
{
  int count;
  __LA_INT64_T status;
  STRLEN len;
  SV *sv_buffer;
  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  PUTBACK;
  
  count = call_pv("Archive::Libarchive::XS::_myread", G_ARRAY);

  SPAGAIN;
  
  sv_buffer = SvRV(POPs);
  status = SvI64(POPs);
  if(status == ARCHIVE_OK)
  {
    *buffer = (void*) SvPV(sv_buffer, len);
  }
  
  PUTBACK;
  FREETMPS;
  LEAVE;

  if(status == ARCHIVE_OK)
    return len == 1 ? 0 : len;
  else
    return status;
}

static __LA_INT64_T
myskip(struct archive *archive, void *client_data, __LA_INT64_T request)
{
  int count;
  __LA_INT64_T status;
  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  XPUSHs(sv_2mortal(newSVi64(request)));
  PUTBACK;
  
  count = call_pv("Archive::Libarchive::XS::_myskip", G_SCALAR);
  
  SPAGAIN;
  
  status = SvI64(POPs);
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return status;
}

static int
myclose(struct archive *archive, void *client_data)
{
  int count;
  int status;
  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  PUTBACK;
  
  count = call_pv("Archive::Libarchive::XS::_myclose", G_SCALAR);
  
  SPAGAIN;
  
  status = POPi;
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return status;
}

static __LA_INT64_T
myseek(struct archive *archive, void *client_data, __LA_INT64_T offset, int whence)
{
  int count;
  __LA_INT64_T status;
  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  XPUSHs(sv_2mortal(newSVi64(offset)));
  XPUSHs(sv_2mortal(newSViv(whence)));
  PUTBACK;
  
  count = call_pv("Archive::Libarchive::XS::_myskip", G_SCALAR);
  
  SPAGAIN;
  
  status = SvI64(POPs);
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return status;
}

static __LA_INT64_T
mywrite(struct archive *archive, void *client_data, const void *buffer, size_t length)
{
  int count;
  __LA_INT64_T status;
  
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  XPUSHs(sv_2mortal(newSVpvn(buffer, length)));
  PUTBACK;
  
  count = call_pv("Archive::Libarchive::XS::_mywrite", G_SCALAR);
  
  SPAGAIN;
  
  status = SvI64(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return status;
}

struct lookup_callback_data {
  SV *perl_data, *lookup_callback, *cleanup_callback;
  char *value;
};

static int64_t
mylookup_write_lookup(void *d, const char *name, int64_t id)
{
  int count;
  __LA_INT64_T value = id;
  struct lookup_callback_data *data = (struct lookup_callback_data *)d;

  if(data->lookup_callback != NULL)
  {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if(data->perl_data == NULL)
      XPUSHs(&PL_sv_undef);
    else
      XPUSHs(data->perl_data);
    XPUSHs(sv_2mortal(newSVpv(name, 0)));
    XPUSHs(sv_2mortal(newSVi64(id)));
    PUTBACK;

    count = call_sv(data->lookup_callback, G_SCALAR);
    
    SPAGAIN;
    
    if(count >= 1)
      value = SvI64(POPs);
    
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return value;
  }
  else
  {
    return id;
  }
}

static const char *
mylookup_read_lookup(void *d, int64_t id)
{
  int count;
  STRLEN len;
  SV *sv;
  const char *tmp;
  struct lookup_callback_data *data = (struct lookup_callback_data *)d;

  if(data->lookup_callback != NULL)
  {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if(data->perl_data == NULL)
      XPUSHs(&PL_sv_undef);
    else
      XPUSHs(data->perl_data);
    XPUSHs(sv_2mortal(newSVi64(id)));
    PUTBACK;
    
    count = call_sv(data->lookup_callback, G_SCALAR);
    
    SPAGAIN;
    
    if(count >= 1)
    {
      sv = POPs;
      if(SvOK(sv))
      {
        tmp = SvPV(sv, len);
        Renew(data->value, len+1, char);
        memcpy(data->value, tmp, len);
        data->value[len] = 0;
      }
      else
      {
        count = 0;
      }
    }
    
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    if(count >= 1)
      return data->value;
  }

  return NULL;
}

static void
mylookup_cleanup(void *d)
{
  struct lookup_callback_data *data = (struct lookup_callback_data *)d;
  
  if(data->cleanup_callback != NULL)
  {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if(data->perl_data == NULL)
      XPUSHs(&PL_sv_undef);
    else
      XPUSHs(data->perl_data);
    PUTBACK;
  
    call_sv(data->cleanup_callback, G_DISCARD|G_VOID);
  }
  
  if(data->perl_data != NULL)
    SvREFCNT_dec(data->perl_data);
  if(data->lookup_callback != NULL)
    SvREFCNT_dec(data->lookup_callback);
  if(data->cleanup_callback != NULL)
    SvREFCNT_dec(data->cleanup_callback);
  if(data->value != NULL)
    Safefree(data->value);
  
  Safefree(data);
}

static struct lookup_callback_data *
new_lookup_callback(SV *data, SV *lookup_callback, SV* cleanup_callback)
{
  struct lookup_callback_data *c_data = NULL;
  Newx(c_data, 1, struct lookup_callback_data);
  c_data->perl_data        = SvOK(data) ? SvREFCNT_inc(data) : NULL;
  c_data->lookup_callback  = SvOK(lookup_callback) ? SvREFCNT_inc(lookup_callback) : NULL;
  c_data->cleanup_callback = SvOK(cleanup_callback) ? SvREFCNT_inc(cleanup_callback) : NULL;
  c_data->value            = NULL;
  return c_data;
}

MODULE = Archive::Libarchive::XS   PACKAGE = Archive::Libarchive::XS

BOOT:
     PERL_MATH_INT64_LOAD_OR_CROAK;

=head2 archive_read_data_into_fh

 my $status = archive_read_data_into_fh($archive, $fh);

A convenience function that repeatedly calls L<#archive_read_data_block> to copy the entire entry to the provided file handle.

=head2 archive_write_disk_set_group_lookup

 my $status = archive_write_disk_set_group_lookup($archive, $data, $lookup_callback, $cleanup_callback);

Register a callback for the lookup of group names from group id numbers.  In order to deregister
call C<archive_write_disk_set_group_lookup> with both callback functions set to C<undef>.

See L<Archive::Libarchive::XS::Callback> for calling conventions for the lookup and cleanup callbacks.

=cut

#if HAS_archive_write_disk_set_group_lookup

int
archive_write_disk_set_group_lookup(archive, data, lookup_callback, cleanup_callback)
    struct archive *archive
    SV *data
    SV *lookup_callback
    SV *cleanup_callback
  CODE:
    if(SvOK(cleanup_callback) || SvOK(lookup_callback))
      RETVAL = archive_write_disk_set_group_lookup(archive, new_lookup_callback(data,lookup_callback,cleanup_callback), &mylookup_write_lookup, &mylookup_cleanup);
    else
      RETVAL = archive_write_disk_set_group_lookup(archive, NULL, NULL, NULL);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_disk_set_gname_lookup

 my $status = archive_read_disk_set_gname_lookup($archive, $data, $lookup_callback, $cleanup_callback);

Register a callback for the lookup of GID from group names.  In order to deregister call
C<archive_read_disk_set_gname_lookup> with both callback functions set to C<undef>.

See L<Archive::Libarchive::XS::Callback> for calling conventions for the lookup and cleanup callbacks.

=cut

#if HAS_archive_read_disk_set_gname_lookup

int
archive_read_disk_set_gname_lookup(archive, data, lookup_callback, cleanup_callback)
    struct archive *archive
    SV *data
    SV *lookup_callback
    SV *cleanup_callback
  CODE:
    if(SvOK(cleanup_callback) || SvOK(lookup_callback))
      RETVAL = archive_read_disk_set_gname_lookup(archive, new_lookup_callback(data,lookup_callback,cleanup_callback), &mylookup_read_lookup, &mylookup_cleanup);
    else
      RETVAL = archive_read_disk_set_gname_lookup(archive, NULL, NULL, NULL);
  OUTPUT:
    RETVAL


#endif

=head2 archive_read_disk_set_uname_lookup

 my $status = archive_read_disk_set_uname_lookup($archive, $data, $lookup_callback, $cleanup_callback);

Register a callback for the lookup of UID from user names.  In order to deregister call
C<archive_read_disk_setugname_lookup> with both callback functions set to C<undef>.

See L<Archive::Libarchive::XS::Callback> for calling conventions for the lookup and cleanup callbacks.

=cut

#if HAS_archive_read_disk_set_uname_lookup

int
archive_read_disk_set_uname_lookup(archive, data, lookup_callback, cleanup_callback)
    struct archive *archive
    SV *data
    SV *lookup_callback
    SV *cleanup_callback
  CODE:
    if(SvOK(cleanup_callback) || SvOK(lookup_callback))
      RETVAL = archive_read_disk_set_uname_lookup(archive, new_lookup_callback(data,lookup_callback,cleanup_callback), &mylookup_read_lookup, &mylookup_cleanup);
    else 
      RETVAL = archive_read_disk_set_uname_lookup(archive, NULL, NULL, NULL);
  OUTPUT:
    RETVAL


#endif

=head2 archive_write_disk_set_user_lookup

 my $status = archive_write_disk_set_user_lookup($archive, $data, $lookup_callback, $cleanup_callback);

Register a callback for the lookup of user names from user id numbers.  In order to deregister
call C<archive_write_disk_set_user_lookup> with both callback functions set to C<undef>.

See L<Archive::Libarchive::XS::Callback> for calling conventions for the lookup and cleanup callbacks.

=cut

#if HAS_archive_write_disk_set_user_lookup

int
archive_write_disk_set_user_lookup(archive, data, lookup_callback, cleanup_callback)
    struct archive *archive
    SV *data
    SV *lookup_callback
    SV *cleanup_callback
  CODE:
    if(SvOK(cleanup_callback) || SvOK(lookup_callback))
      RETVAL = archive_write_disk_set_user_lookup(archive, new_lookup_callback(data,lookup_callback,cleanup_callback), &mylookup_write_lookup, &mylookup_cleanup);
    else
      RETVAL = archive_write_disk_set_user_lookup(archive, NULL, NULL, NULL);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_stat

 my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $atime, $mtime, $ctime) = archive_entry_stat($entry);

Converts the various fields stored in the archive entry to the format used by L<stat|perlfunc#stat>.

The fields C<$blksize>, C<$blocks> supported by L<stat|perlfunc#stat>, are not supported by this function.

=head2 archive_entry_set_stat

 my $status = archive_entry_stat($entry, $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $atime, $mtime, $ctime);

Converts the various fields in the format used by L<stat|perlfunc#stat> to the fields store in the archive entry.

The fields C<$blksize>, C<$blocks> supported by L<stat|perlfunc#stat>, are not supported by this function.

=head2 archive_entry_copy_stat

 my $status = archive_entry_stat($entry, $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $atime, $mtime, $ctime);

Converts the various fields in the format used by L<stat|perlfunc#stat> to the fields store in the archive entry.

The fields C<$blksize>, C<$blocks> supported by L<stat|perlfunc#stat>, are not supported by this function.

This is an alias for L<#archive_entry_set_stat>.

=head2 archive_read_open_fh

 my $status = archive_read_open_fh($archive, $fh, $block_size);

Like L<#archive_read_open_filename>, except that it accepts a file handle and block
size rather than a filename.  Note that the file handle will not be automatically
closed at end-of-archive.

If not specified, a block size of 10240 will be used.

There is no corresponding archive_read_open_fh in the C version of libarchive.
This is provided in the place of C<archive_read_open_FILE> and C<archive_read_open_fd>,
which are not in the Perl bindings for libarchive.

=head2 archive_write_open_fh

 my $status = archive_write_open_fh($archive, $fh);

A convenience form of archive_write_open() that accepts a file descriptor.  Note
that the file handle will not be automatically closed.

There is no corresponding archive_read_write_fh in the C version of libarchive.
This is provided in the place of C<archive_write_open_FILE> and C<archive_write_open_fd>,
which are not in the Perl bindings for libarchive.

=head2 archive_write_open_memory

 my $status = archive_write_open_memory($archive, \\$scalar);

A convenience form of L<#archive_write_open> that accepts a reference to a scalar that will receive the archive.

=head2 archive_read_new

 my $archive = archive_read_new();

Allocates and initializes a archive object suitable for reading from an archive.
Returns an opaque archive which may be a perl style object, or a C pointer
(depending on the implementation), either way, it can be passed into
any of the read functions documented here with an C<$archive> argument.

=cut

struct archive *
archive_read_new();

=head2 archive_read_close

 my $status = archive_read_close($archive);

Complete the archive and invoke the close callback.

=cut

int
archive_read_close(archive)
    struct archive *archive

=head2 archive_read_free

 my $status = archive_read_free($archive);

Invokes L<#archive_read_close> if it was not invoked manually, then
release all resources.

=cut

int
_archive_read_free(archive)
    struct archive *archive;
  CODE:
    RETVAL = archive_read_free(archive);
  OUTPUT:
    RETVAL

=head2 archive_error_string

 my $string = archive_error_string($archive);

Returns a textual error message suitable for display.  The error
message here is usually more specific than that obtained from
passing the result of C<archive_errno> to C<strerror>.
Returns C<undef> if there is not error.

=cut

string_or_null
_archive_error_string(archive)
    struct archive *archive;
  CODE:
#if ARCHIVE_VERSION_NUMBER < 3000000
    const char *str = archive_error_string(archive);
    if(strcmp(str, "(Empty error message)"))
      RETVAL = str;
    else
      RETVAL = NULL;
#else
    RETVAL = archive_error_string(archive);
#endif
  OUTPUT:
    RETVAL

=head2 archive_errno

 my $errno = archive_errno($archive);

Returns a numeric error code indicating the reason for the most
recent error return.

Return type is an errno integer value.

=cut

int
archive_errno(archive)
    struct archive *archive;

=head2 archive_clear_error

 my $status = archive_clear_error($archive);

Clears any error information left over from a previous call Not
generally used in client code.  Does not return a value.

=cut

int
archive_clear_error(archive)
    struct archive *archive;
  CODE:
    archive_clear_error(archive);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

=head2 archive_copy_error

 my $status = archive_copy_error($archive1, $archive2);

Copies error information from one archive to another.

=cut

int
archive_copy_error(archive1, archive2)
    struct archive *archive1;
    struct archive *archive2;
  CODE:
    archive_copy_error(archive1, archive2);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

=head2 archive_filter_code

 my $code = archive_filter_code($archive, $level);

Returns a numeric code identifying the indicated filter.  See L<#archive_filter_count>
for details of the level numbering.

=cut

#if HAS_archive_filter_code

int 
archive_filter_code(archive, level)
    struct archive *archive
    int level

#endif

=head2 archive_filter_bytes

 my $count = archive_filter_bytes($archive, $level);

Byte count for the given filter level.  See L<#archive_filter_count> for details of the
level numbering.

=cut

#if HAS_archive_filter_bytes

__LA_INT64_T
archive_filter_bytes(archive, level)
    struct archive *archive
    int level

#endif

=head2 archive_filter_count

 my $count = archive_filter_count($archive);

Returns the number of filters in the current pipeline. For read archive handles, these 
filters are added automatically by the automatic format detection. For write archive 
handles, these filters are added by calls to the various C<archive_write_add_filter_XXX>
functions. Filters in the resulting pipeline are numbered so that filter 0 is the filter 
closest to the format handler. As a convenience, functions that expect a filter number 
will accept -1 as a synonym for the highest-numbered filter. For example, when reading 
a uuencoded gzipped tar archive, there are three filters: filter 0 is the gunzip filter, 
filter 1 is the uudecode filter, and filter 2 is the pseudo-filter that wraps the archive 
read functions. In this case, requesting C<archive_position(a,(-1))> would be a synonym
for C<archive_position(a,(2))> which would return the number of bytes currently read from 
the archive, while C<archive_position(a,(1))> would return the number of bytes after
uudecoding, and C<archive_position(a,(0))> would return the number of bytes after decompression.

=cut

#if HAS_archive_filter_count

int 
archive_filter_count(archive);
    struct archive *archive;

#endif

=head2 archive_filter_name

 my $string = archive_filter_name($archive, $level);

Returns a textual name identifying the indicated filter.  See L<#archive_filter_count> for
details of the numbering.

=cut

#if HAS_archive_filter_name

const char * 
_archive_filter_name(archive, level)
    struct archive *archive;
    int level;
  CODE:
    RETVAL = archive_filter_name(archive, level);
  OUTPUT:
    RETVAL

#endif

=head2 archive_format

 my $code = archive_format($archive);

Returns a numeric code indicating the format of the current archive
entry.  This value is set by a successful call to
C<archive_read_next_header>.  Note that it is common for this value
to change from entry to entry.  For example, a tar archive might
have several entries that utilize GNU tar extensions and several
entries that do not.  These entries will have different format
codes.

=cut

int
archive_format(archive)
    struct archive *archive;

=head2 archive_format_name

 my $string = archive_format_name($archive);

A textual description of the format of the current entry.

=cut

const char *
_archive_format_name(archive)
    struct archive *archive
  CODE:
    RETVAL = archive_format_name(archive);
  OUTPUT:
    RETVAL

=head2 archive_read_support_filter_all

 my $status = archive_read_support_filter_all($archive);

Enable all available decompression filters.

=cut

int
archive_read_support_filter_all(archive)
    struct archive *archive;

=head2 archive_read_support_filter_program

 my $status = archive_read_support_filter_program($archive, $command);

Data is feed through the specified external program before being
dearchived.  Note that this disables automatic detection of the
compression format, so it makes no sense to specify this in
conjunction with any other decompression option.

=cut

#if HAS_archive_read_support_filter_program

int
_archive_read_support_filter_program(archive, command)
    struct archive *archive
    const char *command
  CODE:
    RETVAL = archive_read_support_filter_program(archive, command);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_append_filter_program

 my $status = archive_read_append_filter_program($archive, $command);

Data is feed through the specified external program before being
dearchived.  Note that this disables automatic detection of the
compression format, so it makes no sense to specify this in
conjunction with any other decompression option.

The C<_append_> form is to manually set the format and filters to be used. This is useful
to bypass the bidding process when the format and filters to use is known in advance.

=cut

#if HAS_archive_read_append_filter_program

int
_archive_read_append_filter_program(archive, command)
    struct archive *archive
    const char *command
  CODE:
    RETVAL = archive_read_append_filter_program(archive, command);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_support_filter_program_signature

 my $status = archive_read_support_filter_program_signature($archive, $command, $signature);

Data is feed through the specified external program before being
dearchived, if the signature matches.

=cut

#if HAS_archive_read_support_filter_program_signature

int
_archive_read_support_filter_program_signature(archive, command, signature)
    struct archive *archive
    const char *command
    SV *signature
  CODE:
    void *ptr;
    STRLEN size;
    ptr = SvPV(signature, size);
    RETVAL = archive_read_support_filter_program_signature(archive, command, ptr, size);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_append_filter_program_signature

 my $status = archive_read_append_filter_program_signature($archive, $command, $signature);

Data is feed through the specified external program before being dearchived, if the signature
matches.

The C<_append_> form is to manually set the format and filters to be used. This is useful
to bypass the bidding process when the format and filters to use is known in advance.

=cut

#if HAS_archive_read_append_filter_program_signature

int
_archive_read_append_filter_program_signature(archive, command, signature)
    struct archive *archive
    const char *command
    SV *signature
  CODE:
    void *ptr;
    STRLEN size;
    ptr = SvPV(signature, size);
    RETVAL = archive_read_append_filter_program_signature(archive, command, ptr, size);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_append_filter

 my $status = archive_read_append_filter($archive, $code)

Add the given filter by its code.

The C<_append_> form is to manually set the format and filters to be used. This is useful
to bypass the bidding process when the format and filters to use is known in advance.

=cut

#if HAS_archive_read_append_filter

int
archive_read_append_filter(archive, code)
    struct archive *archive
    int code

#endif

=head2 archive_read_support_format_all

 my $status = archive_read_support_format_all($archive);

Enable all available archive formats.

=cut

int
archive_read_support_format_all(archive)
    struct archive *archive;

=head2 archive_read_support_format_by_code

 my $status = archive_read_support_format_by_code($archive, $code);

Enables a single format specified by the format code.

=cut

#if HAS_archive_read_support_format_by_code

int
archive_read_support_format_by_code(archive, code)
    struct archive *archive;
    int code;

#endif

=head2 archive_read_open_filename

 my $status = archive_read_open_filename($archive, $filename, $block_size);

Like C<archive_read_open>, except that it accepts a simple filename
and a block size.  This function is safe for use with tape drives
or other blocked devices.

If you pass in C<undef> as the C<$filename>, libarchive will use
standard in as the input archive.

=cut

int
_archive_read_open_filename(archive, filename, block_size)
    struct archive *archive;
    string_or_null filename;
    size_t block_size;
  CODE:
    RETVAL = archive_read_open_filename(archive, filename, block_size);
  OUTPUT:
    RETVAL

=head2 archive_read_open_memory

 my $status = archive_read_open_memory($archive, $buffer);

Like C<archive_read_open>, except that it uses a Perl scalar that holds the 
content of the archive.  This function does not make a copy of the data stored 
in C<$buffer>, so you should not modify the buffer until you have free the 
archive using C<archive_read_free>.

Bad things will happen if the buffer falls out of scope and is deallocated
before you free the archive, so make sure that there is a reference to the
buffer somewhere in your programmer until C<archive_read_free> is called.

=cut

int
archive_read_open_memory(archive, input)
    struct archive *archive;
    SV *input;
  CODE:
    void *buff = NULL;
    size_t size = 0;
    buff = SvPV(input, size);
    RETVAL = archive_read_open_memory(archive, buff, size);
  OUTPUT:
    RETVAL


=head2 archive_read_next_header

 my $status = archive_read_next_header($archive, $entry);

Read the header for the next entry and return an entry object
Returns an opaque archive which may be a perl style object, or a C pointer
(depending on the implementation), either way, it can be passed into
any of the functions documented here with an <$entry> argument.

=cut

int
archive_read_next_header(archive, output)
    struct archive *archive;
    SV *output;
  CODE:
    struct archive_entry *entry;
    RETVAL = archive_read_next_header(archive, &entry);
    sv_setiv(output, PTR2IV((void*)entry));
  OUTPUT:
    RETVAL
    output

=head2 archive_read_data_skip

 my $status = archive_read_data_skip($archive);

A convenience function that repeatedly calls C<archive_read_data> to skip
all of the data for this archive entry.

=cut

int
archive_read_data_skip(archive)
    struct archive *archive;

=head2 archive_file_count

 my $count = archive_file_count($archive);

Returns a count of the number of files processed by this archive object.  The count
is incremented by calls to C<archive_write_header> or C<archive_read_next_header>.

=cut

int
archive_file_count(archive)
    struct archive *archive;

=head2 archive_version_string

 my $string = archive_version_string();

Return the libarchive as a version.

Returns a string value.

=cut

const char *
_archive_version_string()
  CODE:
    RETVAL = archive_version_string();
  OUTPUT:
    RETVAL

=head2 archive_version_number

 my $version = archive_version_number();

Return the libarchive version as an integer.

=cut

int
archive_version_number();

=head2 archive_read_data

 my $count_or_status = archive_read_data($archive, $buffer, $max_size);

Read data associated with the header just read.  Internally, this is a
convenience function that calls C<archive_read_data_block> and fills
any gaps with nulls so that callers see a single continuous stream of
data.  Returns the actual number of bytes read, 0 on end of data and
a negative value on error.

=cut

int
archive_read_data(archive, buffer, max_size)
    struct archive *archive;
    SV *buffer;
    size_t max_size;
  CODE:
    if(!SvPOKp(buffer))
      sv_setpv(buffer, "");
    SvGROW(buffer, max_size);
    void *ptr = SvPV_nolen(buffer);
    int size = archive_read_data(archive, ptr, max_size);
    SvCUR_set(buffer, size);
    RETVAL = size;
  OUTPUT:
    RETVAL
    buffer

=head2 archive_read_data_block

 my $count_or_status = archive_read_data_block($archive, $buffer, $offset);

Return the next available block of data for this entry.  Unlike
C<archive_read_data>, this function allows you to correctly
handle sparse files, as supported by some archive formats.  The
library guarantees that offsets will increase and that blocks
will not overlap.  Note that the blocks returned from this
function can be much larger than the block size read from disk,
due to compression and internal buffer optimizations.

=cut

int
archive_read_data_block(archive, sv_buff, sv_offset)
    struct archive *archive
    SV *sv_buff
    SV *sv_offset
  CODE:
    SV *tmp;
    const void *buff = NULL;
    size_t size = 0;
    __LA_INT64_T offset = 0;
    int r = archive_read_data_block(archive, &buff, &size, &offset);
    sv_setpvn(sv_buff, buff, size);
    tmp = sv_2mortal(newSVi64(offset));
    sv_setsv(sv_offset, tmp);
    RETVAL = r;
  OUTPUT:
    sv_buff
    sv_offset
    RETVAL

=head2 archive_write_data_block

 my $count_or_status = archive_write_data_block($archive, $buffer, $offset);

Writes the buffer to the current entry in the given archive
starting at the given offset.

=cut

size_t
archive_write_data_block(archive, sv_buff, offset)
    struct archive *archive
    SV *sv_buff
    __LA_INT64_T offset
  CODE:
    void *buff = NULL;
    size_t size;
    buff = SvPV(sv_buff, size);
    RETVAL = archive_write_data_block(archive, buff, size, offset);
  OUTPUT:
    RETVAL

=head2 archive_write_disk_new

 my $archive = archive_write_disk_new();

Allocates and initializes a struct archive object suitable for
writing objects to disk.

Returns an opaque archive which may be a perl style object, or a C pointer
(Depending on the implementation), either way, it can be passed into
any of the write functions documented here with an C<$archive> argument.

=cut

struct archive *
archive_write_disk_new()

=head2 archive_write_new

 my $archive = archive_write_new();

Allocates and initializes a archive object suitable for writing an new archive.
Returns an opaque archive which may be a perl style object, or a C pointer
(depending on the implementation), either way, it can be passed into
any of the write functions documented here with an C<$archive> argument.

=cut

struct archive *
archive_write_new()

=head2 archive_write_free

 my $status = archive_write_free($archive);

Invokes C<archive_write_close> if it was not invoked manually, then
release all resources.

=cut

int
_archive_write_free(archive)
    struct archive *archive
  CODE:
    RETVAL = archive_write_free(archive);
  OUTPUT:
    RETVAL

=head2 archive_write_add_filter

 my $status = archive_write_add_filter($archive, $code);

A convenience function to set the filter based on the code.

=cut

#if HAS_archive_write_add_filter

int
archive_write_add_filter(archive, code)
    struct archive *archive
    int code

#endif

=head2 archive_write_add_filter_by_name

 my $status = archive_write_add_filter_by_name($archive, $name);

A convenience function to set the filter based on the name.

=cut

#if HAS_archive_write_add_filter_by_name

int
_archive_write_add_filter_by_name(archive, name)
    struct archive *archive
    const char *name
  CODE:
    RETVAL = archive_write_add_filter_by_name(archive, name);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_add_filter_program

 my $status = archive_write_add_filter_program($archive, $cmd);

The archive will be fed into the specified compression program. 
The output of that program is blocked and written to the client
write callbacks.

=cut

#if HAS_archive_write_add_filter_program

int
_archive_write_add_filter_program(archive, cmd)
    struct archive *archive
    const char *cmd
  CODE:
    RETVAL = archive_write_add_filter_program(archive, cmd);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_set_format

 my $status = archive_write_set_format($archive, $code);

A convenience function to set the format based on the code.

=cut

int
archive_write_set_format(archive, code)
    struct archive *archive
    int code

=head2 archive_write_set_format_by_name

 my $status = archive_write_set_format_by_name($archive, $name);

A convenience function to set the format based on the name.

=cut

int
_archive_write_set_format_by_name(archive, name)
    struct archive *archive
    const char *name
  CODE:
    RETVAL = archive_write_set_format_by_name(archive, name);
  OUTPUT:
    RETVAL

=head2 archive_write_open_filename

 my $status = archive_write_open_filename($archive, $filename);

A convenience form of C<archive_write_open> that accepts a filename.  If you have 
not invoked C<archive_write_set_bytes_in_last_block>, then 
C<archive_write_open_filename> will adjust the last-block padding depending on the 
file: it will enable padding when writing to standard output or to a character or 
block device node, it will disable padding otherwise.  You can override this by 
manually invoking C<archive_write_set_bytes_in_last_block> before C<calling 
archive_write_open>.  The C<archive_write_open_filename> function is safe for use 
with tape drives or other block-oriented devices.

If you pass in C<undef> as the C<$filename>, libarchive will write the
archive to standard out.

=cut

int
_archive_write_open_filename(archive, filename)
    struct archive *archive
    string_or_null filename;
  CODE:
    RETVAL = archive_write_open_filename(archive, filename);
  OUTPUT:
    RETVAL

=head2 archive_entry_clear

 my $status = archive_entry_clear($entry);

Erases the object, resetting all internal fields to the same state as a newly-created object.  This is provided
to allow you to quickly recycle objects without thrashing the heap.

=cut

int
archive_entry_clear(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_clear(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

=head2 archive_entry_clone

 my $entry1 = archive_entry_clone($entry2);

A deep copy operation; all text fields are duplicated.

=cut

struct archive_entry *
archive_entry_clone(archive_entry)
    struct archive_entry *archive_entry

=head2 archive_entry_free

 my $status = archive_entry_free($entry);

Releases the struct archive_entry object.

=cut

int
archive_entry_free(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_free(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

=head2 archive_entry_new

 my $entry = archive_entry_new();

Allocate and return a blank struct archive_entry object.

=cut

struct archive_entry *
archive_entry_new()

=head2 archive_entry_new2

 my $entry = archive_entry_new2($archive)

This form of C<archive_entry_new2> will pull character-set
conversion information from the specified archive handle.  The
older C<archive_entry_new> form will result in the use of an internal
default character-set conversion.

=cut

#if HAS_archive_entry_new2

struct archive_entry *
archive_entry_new2(archive)
    struct archive *archive

#endif

=head2 archive_entry_size($entry)

 my $size = archive_entry_size($entry);

Returns the size of the entry in bytes.

=cut

__LA_INT64_T
archive_entry_size(entry)
    struct archive_entry *entry

=head2 archive_entry_set_size

 my $status = archive_entry_set_size($entry, $size);

Sets the size property for the archive entry.

=cut

int
archive_entry_set_size(entry, size)
    struct archive_entry *entry
    __LA_INT64_T size
  CODE:
    archive_entry_set_size(entry, size);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

=head2 archive_entry_unset_size

 my $status = archive_entry_unset_size($entry);

Unsets the size property for the archive entry.

=cut

#if HAS_archive_entry_unset_size

int
archive_entry_unset_size(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_unset_size(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_size_is_set

 my $bool = archive_entry_size_is_set($entry)

Returns true if the size property for the archive entry has been set.

=cut

#if HAS_archive_entry_size_is_set

int
archive_entry_size_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_filetype

 my $status = archive_entry_set_filetype($entry, $code);

Sets the filetype of the archive entry.  Code should be one of

=over 4

=item AE_IFMT

=item AE_IFREG

=item AE_IFLNK

=item AE_IFSOCK

=item AE_IFCHR

=item AE_IFBLK

=item AE_IFDIR

=item AE_IFIFO

=back

=cut

int
archive_entry_set_filetype(entry, code)
    struct archive_entry *entry
    unsigned int code
  CODE:
    archive_entry_set_filetype(entry, code);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

=head2 archive_entry_filetype

 my $code = archive_entry_filetype($entry);

Gets the filetype of the archive entry.  Code should be one of

=over 4

=item AE_IFMT

=item AE_IFREG

=item AE_IFLNK

=item AE_IFSOCK

=item AE_IFCHR

=item AE_IFBLK

=item AE_IFDIR

=item AE_IFIFO

=back

=cut

#if HAS_archive_entry_filetype

unsigned int
archive_entry_filetype(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_perm

 my $status = archive_entry_set_perm($entry, $perm);

Set the permission bits for the entry.  This is the usual UNIX octal permission thing.

=cut

#if HAS_archive_entry_set_perm

int
archive_entry_set_perm(entry, perm)
    struct archive_entry *entry
    int perm
  CODE:
    archive_entry_set_perm(entry, perm);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_perm

 my $perm = archive_entry_perm($entry);

Get the permission bits for the entry.  This is the usual UNIX octal permission thing.

=cut

#if HAS_archive_entry_perm

int
archive_entry_perm(entry)
    struct archive_entry *entry

#endif

=head2 archive_write_header

 my $status = archive_write_header($archive, $entry);

Build and write a header using the data in the provided struct archive_entry structure.
You can use C<archive_entry_new> to create an C<$entry> object and populate it with
C<archive_entry_set*> functions.

=cut

int
archive_write_header(archive, entry)
    struct archive *archive
    struct archive_entry *entry

=head2 archive_write_data

 my $status = archive_write_data($archive, $buffer);

Write data corresponding to the header just written.

This function returns the number of bytes actually written, or -1 on error.

=cut

int
archive_write_data(archive, input)
    struct archive *archive
    SV *input
  CODE:
    void *buff = NULL;
    size_t size = 0;
    buff = SvPV(input, size);
    RETVAL = archive_write_data(archive, buff, size);
  OUTPUT:
    RETVAL

=head2 archive_write_close

 my $status = archive_write_close($archive)

Complete the archive and invoke the close callback.

=cut

int
archive_write_close(archive)
    struct archive *archive

=head2 archive_write_disk_set_options

 my $status = archive_write_disk_set_options($archive, $flags);

The options field consists of a bitwise OR of one or more of the 
following values:

=over 4

=item ARCHIVE_EXTRACT_OWNER

=item ARCHIVE_EXTRACT_PERM

=item ARCHIVE_EXTRACT_TIME

=item ARCHIVE_EXTRACT_NO_OVERWRITE

=item ARCHIVE_EXTRACT_UNLINK

=item ARCHIVE_EXTRACT_ACL

=item ARCHIVE_EXTRACT_FFLAGS

=item ARCHIVE_EXTRACT_XATTR

=item ARCHIVE_EXTRACT_SECURE_SYMLINKS

=item ARCHIVE_EXTRACT_SECURE_NODOTDOT

=item ARCHIVE_EXTRACT_SPARSE

=back

=cut

int
archive_write_disk_set_options(archive, flags)
    struct archive *archive
    int flags

=head2 archive_entry_set_mtime

 my $status = archive_entry_set_mtime($entry, $sec, $nanosec);

Set the mtime (modify time) for the entry object.

=cut

#if HAS_archive_entry_set_mtime

int
archive_entry_set_mtime(entry, sec, nanosec)
    struct archive_entry *entry
    time_t sec
    long nanosec
  CODE:
    archive_entry_set_mtime(entry, sec, nanosec);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_unset_mtime

 my $status = archive_entry_unset_mtime($entry);

Unset the mtime (modify time) for the entry object.

=cut

#if HAS_archive_entry_unset_mtime

int
archive_entry_unset_mtime(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_unset_mtime(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_finish_entry

 my $status = archive_write_finish_entry($archive)

Close out the entry just written.  Ordinarily, 
clients never need to call this, as it is called 
automatically by C<archive_write_next_header> and 
C<archive_write_close> as needed.  However, some
file attributes are written to disk only after 
the file is closed, so this can be necessary 
if you need to work with the file on disk right away.

=cut

int
archive_write_finish_entry(archive)
    struct archive *archive

=head2 archive_write_disk_set_standard_lookup

 my $status = archive_write_disk_set_standard_lookup($archive);

This convenience function installs a standard set of user and
group lookup functions.  These functions use C<getpwnam> and
C<getgrnam> to convert names to ids, defaulting to the ids
if the names cannot be looked up.  These functions also implement
a simple memory cache to reduce the number of calls to 
C<getpwnam> and C<getgrnam>.

=cut

#if HAS_archive_write_disk_set_standard_lookup

int
archive_write_disk_set_standard_lookup(archive)
    struct archive *archive

#endif

=head2 archive_write_zip_set_compression_store

 my $status = archive_write_zip_set_compression_store($archive);

Set the compression method for the zip archive to store.

=cut

#if HAS_archive_write_zip_set_compression_store

int
archive_write_zip_set_compression_store(archive)
    struct archive *archive

#endif

=head2 archive_write_zip_set_compression_deflate

 my $status = archive_write_zip_set_compression_deflate($archive);

Set the compression method for the zip archive to deflate.

=cut

#if HAS_archive_write_zip_set_compression_deflate

int
archive_write_zip_set_compression_deflate(archive)
    struct archive *archive

#endif

=head2 archive_write_set_skip_file

 my $status = archive_write_set_skip_file($archive, $dev, $ino);

The dev/ino of a file that won't be archived.  This is used
to avoid recursively adding an archive to itself.

=cut

#if HAS_archive_write_set_skip_file

int
archive_write_set_skip_file(archive, dev, ino)
    struct archive *archive
    __LA_INT64_T dev
    __LA_INT64_T ino

#endif

=head2 archive_write_set_format_option

 my $status = archive_write_set_format_option($archive, $module, $option, $value);

Specifies an option that will be passed to currently-registered format 
readers.

If option and value are both C<undef>, these functions will do nothing 
and C<ARCHIVE_OK> will be returned.  If option is C<undef> but value
is not, these functions will do nothing and C<ARCHIVE_FAILED> will
be returned.

If module is not C<undef>, option and value will be provided to the
filter or reader named module.  The return value will be that of
the module.  If there is no such module, C<ARCHIVE_FAILED> will be
returned.

If module is C<undef>, option and value will be provided to every
registered module.  If any module returns C<ARCHIVE_FATAL>, this
value will be returned immediately.  Otherwise, C<ARCHIVE_OK> will
be returned if any module accepts the option, and C<ARCHIVE_FAILED>
in all other cases.

=cut

#if HAS_archive_write_set_format_option

int
_archive_write_set_format_option(archive, module, option, value)
    struct archive *archive
    string_or_null module
    string_or_null option
    string_or_null value
  CODE:
    RETVAL = archive_write_set_format_option(archive, module, option, value);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_set_filter_option($archive, $module, $option, $value)

 my $status = archive_write_set_filter_option($archive, $module, $option, $value);

Specifies an option that will be passed to currently-registered filters
(including decompression filters).

If option and value are both C<undef>, these functions will do nothing 
and C<ARCHIVE_OK> will be returned.  If option is C<undef> but value
is not, these functions will do nothing and C<ARCHIVE_FAILED> will
be returned.

If module is not C<undef>, option and value will be provided to the
filter or reader named module.  The return value will be that of
the module.  If there is no such module, C<ARCHIVE_FAILED> will be
returned.

If module is C<undef>, option and value will be provided to every
registered module.  If any module returns C<ARCHIVE_FATAL>, this
value will be returned immediately.  Otherwise, C<ARCHIVE_OK> will
be returned if any module accepts the option, and C<ARCHIVE_FAILED>
in all other cases.

=cut

#if HAS_archive_write_set_filter_option

int
_archive_write_set_filter_option(archive, module, option, value)
    struct archive *archive
    string_or_null module
    string_or_null option
    string_or_null value
  CODE:
    RETVAL = archive_write_set_filter_option(archive, module, option, value);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_set_option

 my $status = archive_write_set_option($archive, $module, $option, $value);

Calls C<archive_write_set_format_option>, then 
C<archive_write_set_filter_option>. If either function returns 
C<ARCHIVE_FATAL>, C<ARCHIVE_FATAL> will be returned immediately.  
Otherwise, greater of the two values will be returned.

=cut

#if HAS_archive_write_set_option

int
_archive_write_set_option(archive, module, option, value)
    struct archive *archive
    string_or_null module
    string_or_null option
    string_or_null value
  CODE:
    RETVAL = archive_write_set_option(archive, module, option, value);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_set_options

 my $status = archive_write_set_options($archive, $options);

options is a comma-separated list of options.  If options is C<undef> or 
empty, C<ARCHIVE_OK> will be returned immediately.

Individual options have one of the following forms:

=over 4

=item option=value

The option/value pair will be provided to every module.  Modules that do 
not accept an option with this name will ignore it.

=item option

The option will be provided to every module with a value of "1".

=item !option

The option will be provided to every module with a NULL value.

=item module:option=value, module:option, module:!option

As above, but the corresponding option and value will be provided only 
to modules whose name matches module.

=back

=cut

#if HAS_archive_write_set_options

int
_archive_write_set_options(archive, options)
    struct archive *archive
    string_or_null options
  CODE:
    RETVAL = archive_write_set_options(archive, options);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_set_bytes_per_block

 my $status = archive_write_set_bytes_per_block($archive, $bytes_per_block);

Sets the block size used for writing the archive data.  Every call to 
the write callback function, except possibly the last one, will use this 
value for the length.  The default is to use a block size of 10240 
bytes.  Note that a block size of zero will suppress internal blocking 
and cause writes to be sent directly to the write callback as they 
occur.

=cut

#if HAS_archive_write_set_bytes_per_block

int
archive_write_set_bytes_per_block(archive, bpb)
    struct archive *archive
    int bpb

#endif

=head2 archive_write_set_bytes_in_last_block

 my $status = archive_write_set_bytes_in_last_block($archive, $bytes_in_last_block);

Sets the block size used for writing the last block.  If this value is 
zero, the last block will be padded to the same size as the other 
blocks.  Otherwise, the final block will be padded to a multiple of this 
size.  In particular, setting it to 1 will cause the final block to not 
be padded.  For compressed output, any padding generated by this option 
is applied only after the compression.  The uncompressed data is always 
unpadded.  The default is to pad the last block to the full block size 
(note that C<archive_write_open_filename> will set this based on the file 
type).  Unlike the other "set" functions, this function can be called 
after the archive is opened.

=cut

#if HAS_archive_write_set_bytes_in_last_block

int
archive_write_set_bytes_in_last_block(archive, bpb)
    struct archive *archive
    int bpb

#endif

=head2 archive_write_get_bytes_per_block

 my $count = archive_write_get_bytes_per_block($archive);

Retrieve the block size to be used for writing.  A value of -1 here 
indicates that the library should use default values.  A value of zero 
indicates that internal blocking is suppressed.

=cut

#if HAS_archive_write_get_bytes_per_block

int
archive_write_get_bytes_per_block(archive)
    struct archive *archive

#endif

=head2 archive_write_get_bytes_in_last_block

 my $count = archive_write_get_bytes_per_block($archive);

Retrieve the currently-set value for last block size.  A value of -1 
here indicates that the library should use default values.

=cut

#if HAS_archive_write_get_bytes_in_last_block

int
archive_write_get_bytes_in_last_block(archive)
    struct archive *archive

#endif

=head2 archive_write_fail

 my $status = archive_write_fail($archive);

Marks the archive as FATAL so that a subsequent C<free> operation
won't try to C<close> cleanly.  Provides a fast abort capability
when the client discovers that things have gone wrong.

=cut

#if HAS_archive_write_fail

int
archive_write_fail(archive)
    struct archive *archive

#endif

=head2 archive_write_disk_uid

 my $int64 = archive_write_disk_uid($archive, $string, $int64);

Undocumented libarchive function.

=cut

#if HAS_archive_write_disk_uid

__LA_INT64_T
_archive_write_disk_uid(archive, a2, a3)
    struct archive *archive
    const char *a2
    __LA_INT64_T a3
  CODE:
    RETVAL = archive_write_disk_uid(archive, a2, a3);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_disk_gid

 my $int64 = archive_write_disk_gid($archive, $string, $int64);

Undocumented libarchive function.

=cut

#if HAS_archive_write_disk_gid

__LA_INT64_T
_archive_write_disk_gid(archive, a2, a3)
    struct archive *archive
    const char *a2
    __LA_INT64_T a3
  CODE:
    RETVAL = archive_write_disk_gid(archive, a2, a3);
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_disk_set_skip_file

 my $status = archive_write_disk_set_skip_file($archive, $device, $inode);

Records the device and inode numbers of a file that should not be 
overwritten.  This is typically used to ensure that an extraction 
process does not overwrite the archive from which objects are being 
read.  This capability is technically unnecessary but can be a 
significant performance optimization in practice.

=cut

#if HAS_archive_write_disk_set_skip_file

int
archive_write_disk_set_skip_file(archive, device, inode)
    struct archive *archive
    __LA_INT64_T device
    __LA_INT64_T inode

#endif

=head2 archive_seek_data

 my $count_or_status = archive_seek_data($archive, $offset, $whence);

Seek within the body of an entry.  Similar to C<lseek>.

=cut

#if HAS_archive_seek_data

__LA_INT64_T
archive_seek_data(archive, offset, whence)
    struct archive *archive
    __LA_INT64_T offset
    int whence

#endif

=head2 archive_read_set_format_option

 my $status = archive_read_set_format_option($archive, $module, $option, $value);

Specifies an option that will be passed to currently-registered format 
readers.

If option and value are both C<undef>, these functions will do nothing 
and C<ARCHIVE_OK> will be returned.  If option is C<undef> but value is 
not, these functions will do nothing and C<ARCHIVE_FAILED> will be 
returned.

If module is not C<undef>, option and value will be provided to the filter 
or reader named module.  The return value will be that of the module.  
If there is no such module, C<ARCHIVE_FAILED> will be returned.

If module is C<NULL>, option and value will be provided to every registered 
module.  If any module returns C<ARCHIVE_FATAL>, this value will be 
returned immediately.  Otherwise, C<ARCHIVE_OK> will be returned if any 
module accepts the option, and C<ARCHIVE_FAILED> in all other cases.

=cut

#if HAS_archive_read_set_format_option

int
_archive_read_set_format_option(archive, module, options, value)
    struct archive *archive
    string_or_null module
    string_or_null options
    string_or_null value
  CODE:
    RETVAL = archive_read_set_format_option(archive, module, options, value);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_filter_option

 my $status = archive_read_set_filter_option($archive, $module, $option, $value);

Specifies an option that will be passed to currently-registered filters 
(including decompression filters).

If option and value are both C<undef>, these functions will do nothing 
and C<ARCHIVE_OK> will be returned.  If option is C<undef> but value is 
not, these functions will do nothing and C<ARCHIVE_FAILED> will be 
returned.

If module is not C<undef>, option and value will be provided to the filter 
or reader named module.  The return value will be that of the module.  
If there is no such module, C<ARCHIVE_FAILED> will be returned.

If module is C<NULL>, option and value will be provided to every registered 
module.  If any module returns C<ARCHIVE_FATAL>, this value will be 
returned immediately.  Otherwise, C<ARCHIVE_OK> will be returned if any 
module accepts the option, and C<ARCHIVE_FAILED> in all other cases.

=cut

#if HAS_archive_read_set_filter_option

int
_archive_read_set_filter_option(archive, module, option, value)
    struct archive *archive
    string_or_null module
    string_or_null option
    string_or_null value
  CODE:
    RETVAL = archive_read_set_filter_option(archive, module, option, value);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_option

 my $status = archive_read_set_option($archive, $module, $option, $value);

Calls C<archive_read_set_format_option> then 
C<archive_read_set_filter_option>.  If either function returns 
C<ARCHIVE_FATAL>, C<ARCHIVE_FATAL> will be returned immediately.  
Otherwise, greater of the two values will be returned.

=cut

#if HAS_archive_read_set_option

int
_archive_read_set_option(archive, module, option, value)
    struct archive *archive
    string_or_null module
    string_or_null option
    string_or_null value
  CODE:
    RETVAL = archive_read_set_option(archive, module, option, value);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_options

 my $status = archive_read_set_options($archive, $options);

options is a comma-separated list of options.  If options is C<undef> or 
empty, C<ARCHIVE_OK> will be returned immediately.

Calls C<archive_read_set_option> with each option in turn.  If any 
C<archive_read_set_option> call returns C<ARCHIVE_FATAL>, 
C<ARCHIVE_FATAL> will be returned immediately.

=over 4

=item option=value

The option/value pair will be provided to every module.  Modules that do 
not accept an option with this name will ignore it.

=item option

The option will be provided to every module with a value of "1".

=item !option

The option will be provided to every module with an C<undef> value.

=item module:option=value, module:option, module:!option

As above, but the corresponding option and value will be provided only 
to modules whose name matches module.

=back

=cut

#if HAS_archive_read_set_options

int
_archive_read_set_options(archive, options)
    struct archive *archive
    string_or_null options
  CODE:
    RETVAL = archive_read_set_options(archive, options);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_format

 my $status = archive_read_set_format($archive, $format);

Undocumented libarchive function.

=cut

#if HAS_archive_read_set_format

int
_archive_read_set_format(archive, format)
    struct archive *archive
    int format
  CODE:
    RETVAL = archive_read_set_format(archive, format);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_header_position

 my $offset = archive_read_header_position($archive);

Retrieve the byte offset in UNCOMPRESSED data where last-read
header started.

=cut

#if HAS_archive_read_header_position

__LA_INT64_T
archive_read_header_position(archive)
    struct archive *archive

#endif

=head2 archive_read_open

 my $status = archive_read_open($archive, $data, $open_cb, $read_cb, $close_cb);

The same as C<archive_read_open2>, except that the skip callback is assumed to be C<undef>.

=cut

#if HAS_archive_read_open

int
_archive_read_open(archive, data, open_cb, read_cb, close_cb)
    struct archive *archive
    SV *data
    SV *open_cb
    SV *read_cb
    SV *close_cb
  CODE:
    RETVAL = archive_read_open(
      archive,
      NULL,
      SvOK(open_cb)  ? myopen : NULL,
      SvOK(read_cb)  ? myread : NULL,
      SvOK(close_cb) ? myclose : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_write_open

 my $status = archive_write_open($archive, $data, $open_cb, $read_cb, $close_cb);

Freeze the settings, open the archive, and prepare for writing entries.  This is the most
generic form of this function, which accepts pointers to three callback functions which will
be invoked by the compression layer to write the constructed archive.

=cut

#if HAS_archive_write_open

int
_archive_write_open(archive, data, open_cb, write_cb, close_cb)
    struct archive *archive
    SV *data
    SV *open_cb
    SV *write_cb
    SV *close_cb
  CODE:
    RETVAL = archive_write_open(
      archive,
      NULL,
      SvOK(open_cb)  ? myopen : NULL,
      SvOK(write_cb) ? mywrite : NULL,
      SvOK(close_cb) ? myclose : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_open2

 my $status = archive_read_open2($archive, $data, $open_cb, $read_cb, $skip_cb, $close_cb);

Freeze the settings, open the archive, and prepare for reading entries.  This is the most
generic version of this call, which accepts four callback functions.  Most clients will
want to use C<archive_read_open_filename>, C<archive_read_open_FILE>, C<archive_read_open_fd>,
or C<archive_read_open_memory> instead.  The library invokes the client-provided functions to 
obtain raw bytes from the archive.

=cut

#if HAS_archive_read_open2

int
_archive_read_open2(archive, data, open_cb, read_cb, skip_cb, close_cb)
    struct archive *archive
    SV *data
    SV *open_cb
    SV *read_cb
    SV *skip_cb
    SV *close_cb
  CODE:
    RETVAL = archive_read_open2(
      archive,
      NULL,
      SvOK(open_cb)  ? myopen : NULL,
      SvOK(read_cb)  ? myread : NULL,
      SvOK(skip_cb)  ? myskip : NULL,
      SvOK(close_cb) ? myclose : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_open_callback($archive, $callback)

 my $status = archive_read_set_open_callback($archive, $callback);

Set the open callback for the archive object.

=cut

#if HAS_archive_read_set_open_callback

int
_archive_read_set_open_callback(archive, callback)
    struct archive *archive
    SV *callback
  CODE:
    RETVAL = archive_read_set_open_callback(
      archive,
      SvOK(callback) ? myopen : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_read_callback

 my $status = archive_read_set_read_callback($archive, $callback);

Set the read callback for the archive object.

=cut

#if HAS_archive_read_set_read_callback

int
_archive_read_set_read_callback(archive, callback)
    struct archive *archive
    SV *callback
  CODE:
    RETVAL = archive_read_set_read_callback(
      archive,
      SvOK(callback) ? myread : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_skip_callback

 my $status = archive_read_set_skip_callback($archive, $callback);

Set the skip callback for the archive object.

=cut

#if HAS_archive_read_set_skip_callback

int
_archive_read_set_skip_callback(archive, callback)
    struct archive *archive
    SV *callback
  CODE:
    RETVAL = archive_read_set_skip_callback(
      archive,
      SvOK(callback) ? myskip : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_close_callback

 my $status = archive_read_set_close_callback($archive, $callback);

Set the close callback for the archive object.

=cut

#if HAS_archive_read_set_close_callback

int
_archive_read_set_close_callback(archive, callback)
    struct archive *archive
    SV *callback
  CODE:
    RETVAL = archive_read_set_close_callback(
      archive,
      SvOK(callback) ? myclose : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_seek_callback

 my $status = archive_read_set_seek_callback($archive, $callback);

Set the seek callback for the archive object.

=cut

#if HAS_archive_read_set_seek_callback

int
_archive_read_set_seek_callback(archive, callback)
    struct archive *archive
    SV *callback
  CODE:
    RETVAL = archive_read_set_seek_callback(
      archive,
      SvOK(callback) ? myseek : NULL
    );
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_set_callback_data

 my $status = archive_read_set_callback_data($archive, $data);

Set the client data for callbacks.

=cut

#if HAS_archive_read_set_callback_data

int
_archive_read_set_callback_data(archive, data)
    struct archive *archive
    void *data
  CODE:
    /*
     * note: this isn't actually used as it is implemented
     * at the Perl level
     */
    RETVAL = archive_read_set_callback_data(archive, data);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_open1

 my $status = archive_read_open1($archive);

Opening freezes the callbacks.

=cut

#if HAS_archive_read_open1

int
archive_read_open1(archive)
    struct archive *archive

#endif

=head2 archive_read_next_header2

 my $status = archive_read_next_header2($archive, $entry);

Read the header for the next entry and populate the provided entry object.

=cut

#if HAS_archive_read_next_header2

int
archive_read_next_header2(archive, entry)
    struct archive *archive
    struct archive_entry *entry

#endif

=head2 archive_entry_atime_is_set

 my $bool = archive_entry_atime_is_set($entry);

Returns true if the access time property has been set on the archive entry.

=cut

#if HAS_archive_entry_atime_is_set

int
archive_entry_atime_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_mtime_is_set

 my $bool = archive_entry_mtime_is_set($entry);

Returns true if the mtime (modify time) property has been set on the archive entry.

=cut

#if HAS_archive_entry_mtime_is_set

int
archive_entry_mtime_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_unset_atime

 my $status = archive_entry_unset_atime($entry);

Removes the value for the atime property on the archive.

=cut

#if HAS_archive_entry_unset_atime

int
archive_entry_unset_atime(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_unset_atime(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_atime

 my $atime = archive_entry_atime($entry);

Returns the access time property for the archive entry.

=cut

#if HAS_archive_entry_atime

time_t
archive_entry_atime(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_atime

 my $status = archive_entry_set_atime($entry, $atime, $nsec);

Sets the access time property for the archive entry.

=cut

#if HAS_archive_entry_set_atime

int
archive_entry_set_atime(entry, atime, nsec)
    struct archive_entry *entry
    time_t atime
    long nsec
  CODE:
    archive_entry_set_atime(entry, atime, nsec);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_birthtime

 my $status = archive_entry_set_birthtime($entry, $birthtime, $nsec);

Sets the birthtime (creation time) for the archive entry.

=cut

#if HAS_archive_entry_set_birthtime

int
archive_entry_set_birthtime(entry, birthtime, nsec)
    struct archive_entry *entry
    time_t birthtime
    long nsec
  CODE:
    archive_entry_set_birthtime(entry, birthtime, nsec);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_atime_nsec

 my $atime = archive_entry_atime_nsec($entry);

Returns the access time (nanoseconds).

=cut

#if HAS_archive_entry_atime_nsec

long
archive_entry_atime_nsec(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_birthtime_is_set

 my $bool = archive_entry_birthtime_is_set($entry);

Returns true if the birthtime (creation time) property has been set on the archive entry.

=cut

#if HAS_archive_entry_birthtime_is_set

int
archive_entry_birthtime_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_unset_birthtime

 my $status = archive_entry_unset_birthtime($entry);

Unset the birthtime (creation time) property for the archive entry.

=cut

#if HAS_archive_entry_unset_birthtime

int
archive_entry_unset_birthtime(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_unset_birthtime(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_birthtime

 my $birthtime = archive_entry_birthtime($entry);

Returns the birthtime (creation time) for the archive entry.

=cut

#if HAS_archive_entry_birthtime

time_t
archive_entry_birthtime(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_birthtime_nsec

 my $birthtime = archive_entry_birthtime_nsec($entry);

Returns the birthtime (creation time) for the archive entry.

=cut

#if HAS_archive_entry_birthtime_nsec

long
archive_entry_birthtime_nsec(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_ctime_is_set

 my $bool = archive_entry_ctime_is_set($entry);

Returns true if the ctime (last time an inode property was changed) property has been set
on the archive entry.

=cut

#if HAS_archive_entry_ctime_is_set

int
archive_entry_ctime_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_ctime

 my $ctime = archive_entry_ctime($entry);

Returns the ctime (last time an inode property was changed) property for the archive entry.

=cut

#if HAS_archive_entry_ctime

time_t
archive_entry_ctime(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_ctime

 my $status = archive_entry_set_ctime($entry, $ctime, $nsec);

Sets the ctime (last time an inode property was changed) property for the archive entry.

=cut

#if HAS_archive_entry_set_ctime

int
archive_entry_set_ctime(entry, ctime, nsec)
    struct archive_entry *entry
    time_t ctime
    long nsec
  CODE:
    archive_entry_set_ctime(entry, ctime, nsec);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_unset_ctime

 my $status = archive_entry_set_ctime($entry);

Unsets the ctime (last time an inode property was changed) property for the archive entry.

=cut

#if HAS_archive_entry_unset_ctime

int
archive_entry_unset_ctime(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_unset_ctime(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_mtime

 my $mtime = archive_entry_mtime($entry);

Gets the mtime (modify time) property for the archive entry.

=cut

#if HAS_archive_entry_mtime

time_t
archive_entry_mtime(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_mtime_nsec

 my $mtime = archive_entry_mtime_nsec($entry);

Gets the mtime property (modify time) property for the archive entry (nanoseconds).

=cut

#if HAS_archive_entry_mtime_nsec

long
archive_entry_mtime_nsec(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_ctime_nsec

 my $ctime = archive_entry_ctime_nsec($entry);

Returns the ctime (last time an inode property was changed) property (nanoseconds).

=cut

#if HAS_archive_entry_ctime_nsec

long
archive_entry_ctime_nsec(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_dev_is_set

 my $bool = archive_entry_dev_is_set($entry);

Returns true if the device property on the archive entry is set.

The device property is an integer identifying the device, and is used by
C<archive_entry_linkify> (along with the ino64 property) to find hardlinks.

=cut

#if HAS_archive_entry_dev_is_set

int
archive_entry_dev_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_fflags

 my $status = archive_entry_fflags($entry, $set, $clear);

Gets the file flag properties for the archive entry.  The
C<$set> and C<$clear> arguments are updated to return their
values.

=cut

#if HAS_archive_entry_fflags

int
archive_entry_fflags(entry, sv_set, sv_clear)
    struct archive_entry *entry 
    SV *sv_set
    SV *sv_clear
  CODE:
    SV *tmp;
    unsigned long set;
    unsigned long clear;
    archive_entry_fflags(entry, &set, &clear);
    tmp = sv_2mortal(newSVuv(set));
    sv_setsv(sv_set, tmp);
    tmp = sv_2mortal(newSVuv(clear));
    sv_setsv(sv_clear, tmp);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    sv_set
    sv_clear
    RETVAL

#endif

=head2 archive_entry_set_fflags

 my $status = archive_entry_set_fflags($entry, $set, $clear);

Sets the file flag properties for the archive entry.

=cut

#if HAS_archive_entry_set_fflags

int
archive_entry_set_fflags(entry, set, clear)
    struct archive_entry *entry
    unsigned long set
    unsigned long clear
  CODE:
    archive_entry_set_fflags(entry, set, clear);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_dev

 my $device = archive_entry_dev($entry);

Returns the device property for the archive entry.

The device property is an integer identifying the device, and is used by
C<archive_entry_linkify> (along with the ino64 property) to find hardlinks.

=cut

#if HAS_archive_entry_dev

dev_t
archive_entry_dev(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_devmajor

 my $device_major = archive_entry_devmajor($entry);

Returns the device major property for the archive entry.

=cut

#if HAS_archive_entry_devmajor

dev_t
archive_entry_devmajor(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_devminor

 my $device_minor = archive_entry_devminor($entry);

Returns the device minor property for the archive entry.

=cut

#if HAS_archive_entry_devminor

dev_t
archive_entry_devminor(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_fflags_text($entry)

 my $string = archive_entry_fflags_text($entry);

Returns the file flags property as a string.

=cut

#if HAS_archive_entry_fflags_text

const char *
_archive_entry_fflags_text(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_fflags_text(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_copy_fflags_text

 my $status = archive_entry_copy_fflags_text($entry, $string);

Sets the fflags_text property for the archive entry object.

This is an alias for L<#archive_entry_set_fflags_text>.

=head2 archive_entry_set_fflags_text

 my $status = archive_entry_set_fflags_text($entry, $string);

Sets the fflags_text property for the archive entry object.

=cut

#if HAS_archive_entry_copy_fflags_text

int
_archive_entry_set_fflags_text(entry, string)
    struct archive_entry *entry
    string_or_null string
  CODE:
    archive_entry_copy_fflags_text(entry, string);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_gid

 my $gid = archive_entry_gid($entry);

Returns the group id property for the archive entry.

=cut

#if HAS_archive_entry_gid

__LA_INT64_T
archive_entry_gid(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_gid

 my $status = archive_entry_set_gid($gid).

Sets the group id property for the archive entry.

=cut

#if HAS_archive_entry_set_gid

int
archive_entry_set_gid(entry, gid)
    struct archive_entry *entry
    __LA_INT64_T gid
  CODE:
    archive_entry_set_gid(entry, gid);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_disk_descend

 my $status = archive_read_disk_descend($archive);

Request that current entry be visited.  If you invoke it on every
directory, you'll get a physical traversal.  This is ignored if the
current entry isn't a directory or a link to a directory.  So, if
you invoke this on every returned path, you'll get a full logical
traversal.

=cut

#if HAS_archive_read_disk_descend

int
archive_read_disk_descend(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_can_descend

 my $bool = archive_read_disk_can_descend($archive);

Undocumented libarchive function.

=cut

#if HAS_archive_read_disk_can_descend

int
archive_read_disk_can_descend(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_current_filesystem

 my $status = archive_read_disk_current_filesystem($archive);

Undocumented libarchive function.

=cut

#if HAS_archive_read_disk_current_filesystem

int
archive_read_disk_current_filesystem(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_current_filesystem_is_synthetic

 my $status = archive_read_disk_current_filesystem_is_synthetic($archive);

Undocumented libarchive function.

=cut

#if HAS_archive_read_disk_current_filesystem_is_synthetic

int
archive_read_disk_current_filesystem_is_synthetic(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_current_filesystem_is_remote

 my $status = archive_read_disk_current_filesystem_is_remote($archive);

Undocumented libarchive function.

=cut

#if HAS_archive_read_disk_current_filesystem_is_remote

int
archive_read_disk_current_filesystem_is_remote(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_set_atime_restored

 my $status = archive_read_disk_set_atime_restored($archive);

Request that the access time of the entry visited by traversal be restored.

=cut

#if HAS_archive_read_disk_set_atime_restored

int
archive_read_disk_set_atime_restored(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_open

 my $status = archive_read_disk_open($archive, $string)

Allocates and initializes an archive object suitable for reading objects from disk.

=cut

#if HAS_archive_read_disk_open

int
_archive_read_disk_open(archive, name)
    struct archive *archive
    const char *name
  CODE:
    RETVAL = archive_read_disk_open(archive, name);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_disk_gname

 my $string = archive_read_disk_gname($archive, $gid);

Returns a group name given a gid value.  By default always
returns C<undef>.

=cut

#if HAS_archive_read_disk_gname

string_or_null
_archive_read_disk_gname(archive, gid)
    struct archive *archive
    __LA_INT64_T gid
  CODE:
    RETVAL = archive_read_disk_gname(archive, gid);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_disk_uname

 my $string = archive_read_disk_uname($archive, $gid);

Returns a user name given a uid value.  By default always
returns C<undef>.

=cut

#if HAS_archive_read_disk_uname

string_or_null
_archive_read_disk_uname(archive, gid)
    struct archive *archive
    __LA_INT64_T gid
  CODE:
    RETVAL = archive_read_disk_uname(archive, gid);
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_disk_new

 my $archive = archive_read_disk_new();

Allocates and initializes an archive object suitable for reading object information
from disk.

=cut

#if HAS_archive_read_disk_new

struct archive *
archive_read_disk_new()

#endif

=head2 archive_read_disk_set_behavior

 my $status = archive_read_disk_set_behavior($archive, $flags);
 
Undocumented libarchive function.

=cut

#if HAS_archive_read_disk_set_behavior

int
archive_read_disk_set_behavior(archive, flags)
    struct archive *archive
    int flags

#endif

=head2 archive_read_disk_set_standard_lookup

 my $status = archive_read_disk_set_standard_lookup($archive);

This convenience function installs a standard set of user and group name lookup functions.
These functions use C<getpwuid> and C<getgrgid> to convert ids to names, defaulting to C<undef>.
if the names cannot be looked up.  These functions also implement a simple memory cache to
reduce the number of calls to C<getpwuid> and C<getgrgid>.

=cut

#if HAS_archive_read_disk_set_standard_lookup

int
archive_read_disk_set_standard_lookup(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_set_symlink_hybrid

 my $status = archive_read_disk_set_symlink_hybrid($archive);

This sets the mode used for handling symbolic links.  The "hybrid" mode currently
behaves identically to the "logical" mode.

=cut

#if HAS_archive_read_disk_set_symlink_hybrid

int
archive_read_disk_set_symlink_hybrid(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_set_symlink_logical

 my $status = archive_read_disk_set_symlink_logical($archive);

This sets the mode used for handling symbolic links.  The "logical" mode follows
all symbolic links.

=cut

#if HAS_archive_read_disk_set_symlink_logical

int
archive_read_disk_set_symlink_logical(archive)
    struct archive *archive

#endif

=head2 archive_read_disk_set_symlink_physical

 my $status = archive_read_disk_set_symlink_physical($archive);

This sets the mode used for handling symbolic links.  The "physical" mode does not
follow any symbolic links.

=cut

#if HAS_archive_read_disk_set_symlink_physical

int
archive_read_disk_set_symlink_physical(archive)
    struct archive *archive

#endif

=head2 archive_match_new

 my $archive = archive_match_new();

Allocates and initializes a archive object suitable for reading and matching with an archive.

=cut

#if HAS_archive_match_new

struct archive *
archive_match_new()

#endif

=head2 archive_match_free

 my $status = archive_match_free($archive);

Free the resources previously allocated with L<#archive_match_new>.

=cut

#if HAS_archive_match_free

int
archive_match_free(archive)
    struct archive *archive

#endif

=head2 archive_match_excluded

 my $bool = archive_match_excluded($archive, $entry);

Test if archive_entry is excluded. This is a convenience function. This is the
same as calling all L<#archive_match_path_excluded>, L<#archive_match_time_excluded>
and L<#archive_match_owner_excluded>.

=cut

#if HAS_archive_match_excluded

int
archive_match_excluded(archive, entry)
    struct archive *archive
    struct archive_entry *entry

#endif

=head2 archive_match_path_excluded

 my $bool = archive_match_path_excluded($archive, $entry);

Test if pathname is excluded.

=cut

#if HAS_archive_match_path_excluded

int
archive_match_path_excluded(archive, entry)
    struct archive *archive
    struct archive_entry *entry

#endif

=head2 archive_match_time_excluded

 my $bool = archive_match_time_excluded($archive, $entry);

Test if a file is excluded by its time stamp.

=cut

#if HAS_archive_match_time_excluded

int
archive_match_time_excluded(archive, entry)
    struct archive *archive
    struct archive_entry *entry

#endif

=head2 archive_match_owner_excluded

 my $bool = archive_match_owner_excluded($archive, $entry);

Test if a file is excluded by its uid, gid, user name or group name.

=cut

#if HAS_archive_match_owner_excluded

int
archive_match_owner_excluded(archive, entry)
    struct archive *archive
    struct archive_entry *entry

#endif

=head2 archive_perl_codeset

 my $string = archive_perl_codeset();

Returns the name of the "codeset" (character encoding, example: "UTF-8" for
UTF-8 or "ANSI_X3.4-1968" for ASCII) of the currently configured locale.

=cut

#if HAS_archive_perl_codeset

string_or_null
archive_perl_codeset()

#endif

=head2 archive_perl_utf8_mode

 my $bool = archive_perl_utf8_mode();

Returns true if the internal "codeset" used by libarchive is UTF-8.

=cut

#if HAS_archive_perl_utf8_mode

int
archive_perl_utf8_mode()

#endif

=head2 archive_entry_acl

 my $acl = archive_entry_acl($entry);

Return an opaque ACL object.

There's not yet anything you can actually do with this...

=cut

#if HAS_archive_entry_acl

struct archive_acl *
archive_entry_acl(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_acl_clear

 my $status = archive_entry_acl_clear($entry);

removes all ACL entries and resets the enumeration pointer.

=cut

#if HAS_archive_entry_acl_clear

int
archive_entry_acl_clear(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_acl_clear(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_acl_add_entry

 my $status = archive_entry_acl_add_entry($entry, $type, $permset, $tag, $qual, $name);

Adds a single ACL entry.  For the access ACL and non-extended principals, the classic
UNIX permissions are updated.

=cut

#if HAS_archive_entry_acl_add_entry

int
_archive_entry_acl_add_entry(entry, type, permset, tag, qual, name)
    struct archive_entry *entry
    int type
    int permset
    int tag
    int qual
    const char *name
  CODE:
    RETVAL = archive_entry_acl_add_entry(entry, type, permset, tag, qual, name);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_acl_reset

 my $status = archive_entry_acl_reset($entry, $want_type);

prepare reading the list of ACL entries with
L<#archive_entry_acl_next> or L<#archive_entry_acl_next_w>.  The function returns
either 0, if no non-extended ACLs are found.  In this case, the access permissions
should be obtained by L<#archive_entry_mode> or set using L<chmod|perlfunc#chmod>.
Otherwise, the function returns the same value as L<#archive_entry_acl_count>.

=cut

#if HAS_archive_entry_acl_reset

int
archive_entry_acl_reset(entry, want_type)
    struct archive_entry *entry
    int want_type

#endif

=head2 archive_entry_acl_next

 my $status = archive_entry_acl_next($entry, $want_type, $type, $permset, $tag, $qual, $name);

return the next entry of the ACL list.  This functions may only be called after L<#archive_entry_acl_reset>
has indicated the presence of extended ACL entries.

=cut

#if HAS_archive_entry_acl_next

int
archive_entry_acl_next(entry, want_type, type, permset, tag, qual, name)
    struct archive_entry *entry 
    int want_type
    SV *type
    SV *permset
    SV *tag
    SV *qual
    SV *name
  CODE:
    int a_type, a_permset, a_tag, a_qual;
    const char *a_name;
    RETVAL = archive_entry_acl_next(entry, want_type, &a_type, &a_permset, &a_tag, &a_qual, &a_name);
    sv_setiv(type, a_type);
    sv_setiv(permset, a_permset);
    sv_setiv(tag, a_tag);
    sv_setiv(qual, a_qual);
    sv_setpv(name, a_name);
  OUTPUT:
    type
    permset
    tag
    qual
    name

#endif

=head2 archive_entry_acl_text

 my $string = archive_entry_acl_text($entry, $flags);

converts the ACL entries for the given type mask into a string.  In addition to the normal type flags,
C<ARCHIVE_ENTRY_ACL_STYLE_EXTRA_ID> and C<ARCHIVE_ENTRY_ACL_STYLE_MARK_DEFAULT> can be specified
to further customize the result.  The returned long string is valid until the next call to 
L<#archive_entry_acl_clear>, L<#archive_entry_acl_add_entry>, L<#archive_entry_acl_text>.

=cut

#if HAS_archive_entry_acl_text

string_or_null
_archive_entry_acl_text(entry, flags)
    struct archive_entry *entry
    int flags
  CODE:
    RETVAL = archive_entry_acl_text(entry, flags);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_acl_count

 my $count = archive_entry_acl_count($entry, $want_type);

counts the ACL entries that have the given type mask.
$type can be the bitwise-or of C<ARCHIVE_ENTRY_ACL_TYPE_ACCESS> and
C<ARCHIVE_ENTRY_ACL_TYPE_DEFAULT>.  If C<ARCHIVE_ENTRY_ACL_TYPE_ACCESS>
is included and at least one extended ACL entry is found, the three
non-extended ACLs are added.

=cut

#if HAS_archive_entry_acl_count

int
archive_entry_acl_count(entry, want_type)
    struct archive_entry *entry
    int want_type

#endif

=head2 archive_entry_rdev

 my $device = archive_entry_rdev($entry);

Returns the rdev property for the archive entry.

=cut

#if HAS_archive_entry_rdev

dev_t
archive_entry_rdev(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_rdevmajor

 my $device_major = archive_entry_rdevmajor($entry);

Returns the major component of the rdev property for the archive entry.

=cut

#if HAS_archive_entry_rdevmajor

dev_t
archive_entry_rdevmajor(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_rdevminor

 my $device_minor = archive_entry_rdevminor($entry);

Returns the minor component of the rdev property for the archive entry.

=cut

#if HAS_archive_entry_rdevminor

dev_t
archive_entry_rdevminor(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_rdev

 my $status = archive_entry_set_rdev($entry, $device);

Set the rdev property for the archive entry.

=cut

#if HAS_archive_entry_set_rdev

int
archive_entry_set_rdev(entry, device)
    struct archive_entry *entry
    dev_t device
  CODE:
    archive_entry_set_rdev(entry, device);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_rdevmajor

 my $status = archive_entry_set_rdevmajor($entry, $major);

Set the major component of the rdev property for the archive entry.

=cut

#if HAS_archive_entry_set_rdevmajor

int
archive_entry_set_rdevmajor(entry, major)
    struct archive_entry *entry
    dev_t major
  CODE:
    archive_entry_set_rdevmajor(entry, major);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_rdevminor

 my $status = archive_entry_set_rdevminor($entry, $minor);

Sets the minor component of the rdev property for the archive entry.

=cut

#if HAS_archive_entry_set_rdevminor

int
archive_entry_set_rdevminor(entry, minor)
    struct archive_entry *entry
    dev_t minor
  CODE:
    archive_entry_set_rdevminor(entry, minor);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_mac_metadata

 my $status = archive_entry_set_mac_metadata($entry, $buffer);

The mac_metadata property is Storage for Mac OS-specific 
AppleDouble metadata information.  Apple-format tar files 
store a separate binary blob containing encoded metadata 
with ACL, extended attributes, etc. This provides a place 
to store that blob.

This method sets the blob.  The C name for this function is
C<archive_entry_copy_mac_metadata>.

=head2 archive_entry_copy_mac_metadata

An Alias for L<#archive_entry_set_mac_metadata>.

=cut

#if HAS_archive_entry_copy_mac_metadata

int
archive_entry_set_mac_metadata(entry, buffer)
    struct archive_entry *entry
    SV *buffer
  CODE:
    STRLEN len;
    const void *ptr = SvPV(buffer, len);
    archive_entry_copy_mac_metadata(entry, ptr, len);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_mac_metadata

 my $buffer = archive_entry_mac_metadata($entry);

The mac_metadata property is Storage for Mac OS-specific
AppleDouble metadata information.  Apple-format tar files
store a separate binary blob containing encoded metadata
with ACL, extended attributes, etc. This provides a place
to store that blob.

This method gets the blob.  The C name for this function is
C<archive_entry_copy_mac_metadata>.

=cut

#if HAS_archive_entry_mac_metadata

SV *
archive_entry_mac_metadata(entry)
    struct archive_entry *entry
  CODE:
    size_t size;
    const void *ptr = archive_entry_mac_metadata(entry, &size);
    if(ptr == NULL)
      XSRETURN_EMPTY;
    else
      RETVAL = newSVpv(ptr, size);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_mode

 my $mode = archive_entry_mode($entry);

Get a combination of file type and permission and provide the equivalent of st_mode.
use of L<#archive_entry_filetype> and L<#archive_entry_perm> for getting and
L<#archive_entry_set_filetype> and L<#archive_entry_set_perm> for setting is
recommended.

=cut

#if HAS_archive_entry_mode

int
archive_entry_mode(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_mode

 my $status = archive_entry_set_mode($entry, $mode);

Set a combination of file type and permission and provide the equivalent of st_mode.
use of L<#archive_entry_filetype> and L<#archive_entry_perm> for getting and
L<#archive_entry_set_filetype> and L<#archive_entry_set_perm> for setting is
recommended.

=cut

#if HAS_archive_entry_set_mode

int
archive_entry_set_mode(entry, mode)
    struct archive_entry *entry
    int mode
  CODE:
    archive_entry_set_mode(entry, mode);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_open_filenames

 my $status = archive_read_open_filenames($archive, \\@filenames, $block_size);

Use this for reading multivolume files by filenames.

=cut

#if HAS_archive_read_open_filenames

int
archive_read_open_filenames(archive, filenames, block_size)
    struct archive *archive
    SV *filenames
    size_t block_size
  CODE:
    const char **c_filenames;
    int num, i;
    if(!SvROK(filenames) || SvTYPE(SvRV(filenames)) != SVt_PVAV)
    {
      Perl_croak(aTHX_ "archive_read_open_filename: second argument must be an array reference");
    }
    else
    {
      num = av_len((AV*)SvRV(filenames))+1; /* av_top_index in newer Perls */
      Newx(c_filenames, num+1, const char *);
      for(i=0; i<num; i++)
      {
        AV *av = (AV*) SvRV(filenames);
        SV *filename = *av_fetch(av, i, 0);
        c_filenames[i] = SvPV_nolen(filename);
        /* printf(" i = %d s = %s\n", i, c_filenames[i]); */
      }
      c_filenames[num] = NULL;
      /* printf(" i = %d s = NULL\n", num); */
      RETVAL = archive_read_open_filenames(archive, c_filenames, block_size);
      Safefree(c_filenames);
    }
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_linkresolver_new

 my $linkresolver = archive_entry_linkresolver_new();

Allocate a new link resolver.  

=cut

#if HAS_archive_entry_linkresolver_new

struct archive_entry_linkresolver *
archive_entry_linkresolver_new()

#endif

=head2 archive_entry_linkresolver_free

 my $status = archive_entry_linkresolver_free($linkresolver);

Deallocates a link resolver instance.
All deferred entries are flushed and the internal storage is freed.

=cut

#if HAS_archive_entry_linkresolver_free

int
archive_entry_linkresolver_free(linkresolver)
    struct archive_entry_linkresolver* linkresolver
  CODE:
    archive_entry_linkresolver_free(linkresolver);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_linkresolver_set_strategy

 my $status = archive_entry_linkresolver_set_strategy($linkresolver, $format);

Set the link resolver strategy.  $format should be an archive format constant
(a constant with ARCHIVE_FORMAT_ prefix see L<Archive::Libarchive::XS::Constant>.

=cut

#if HAS_archive_entry_linkresolver_set_strategy

int
archive_entry_linkresolver_set_strategy(linkresolver, format)
    struct archive_entry_linkresolver* linkresolver
    int format
  CODE:
    archive_entry_linkresolver_set_strategy(linkresolver, format);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_ino

 my $status = archive_entry_set_ino($entry, $ino);

Set the inode property for the entry.

The inode property is an integer identifying the file within a filesystem
and is used by C<archive_entry_linkify> (along with the dev property) to
find hardlinks.

This actually uses the libarchive C<archive_entry_set_ino64> function
(in libarchive C<archive_entry_set_ino> is a legacy interface).

=cut

#if HAS_archive_entry_set_ino

int
archive_entry_set_ino(entry, ino)
    struct archive_entry *entry
    __LA_INT64_T ino
  CODE:
    archive_entry_set_ino64(entry, ino);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_ino

 my $ino = archive_entry_ino($entry);

Get the inode property for the entry.

The inode property is an integer identifying the file within a filesystem
and is used by C<archive_entry_linkify> (along with the dev property) to
find hardlinks.

This actually uses the libarchive C<archive_entry_set_ino64> function
(in libarchive C<archive_entry_set_ino> is a legacy interface).

=cut

#if HAS_archive_entry_ino

__LA_INT64_T
archive_entry_ino(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_ino64(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_ino_is_set

 my $bool = archive_entry_ino_is_set($entry);

Returns true if the inode property for the entry has been set.

=cut

#if HAS_archive_entry_ino_is_set

int
archive_entry_ino_is_set(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_dev

 my $status = archive_entry_set_dev($entry, $device);

Sets the device property for the archive entry.

The device property is an integer identifying the device, and is used by
C<archive_entry_linkify> (along with the ino64 property) to find hardlinks.

=cut

#if HAS_archive_entry_set_dev

int
archive_entry_set_dev(entry, device)
    struct archive_entry *entry
    dev_t device
  CODE:
    archive_entry_set_dev(entry, device);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_devmajor

 my $status = archive_entry_set_devmajor($entry, $devmajor);

Sets the device major property for the archive entry.

The device property is an integer identifying the device, and is used by
C<archive_entry_linkify> (along with the ino64 property) to find hardlinks.

=cut

#ifdef HAS_archive_entry_set_devmajor

int
archive_entry_set_devmajor(entry, device)
    struct archive_entry *entry
    dev_t device
  CODE:
    archive_entry_set_devmajor(entry, device);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_devminor

 my $status = archive_entry_set_devminor($entry, $devminor);

Sets the device minor property for the archive entry.

The device property is an integer identifying the device, and is used by
C<archive_entry_linkify> (along with the ino64 property) to find hardlinks.

=cut

#ifdef HAS_archive_entry_set_devminor

int
archive_entry_set_devminor(entry, device)
    struct archive_entry *entry
    dev_t device
  CODE:
    archive_entry_set_devminor(entry, device);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_nlink

 my $status = archive_entry_set_nlink($entry, $nlink);

Sets the number of hardlinks for the entry.

=cut

#if HAS_archive_entry_set_nlink

int
archive_entry_set_nlink(entry, nlink)
    struct archive_entry *entry
    unsigned int nlink
  CODE:
    archive_entry_set_nlink(entry, nlink);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_nlink

 my $nlink = archive_entry_nlink($entry);

Gets the number of hardlinks for the entry.

=cut

#if HAS_archive_entry_nlink

unsigned int
archive_entry_nlink(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_linkify

 my $status = archive_entry_linkify($linkresolver, $entry1, $entry2)

Behavior depends on the link resolver strategy 
(L<#archive_entry_linkresolver_set_strategy>).  See libarchive documentation
(C<archive_entry_linkify(3)>) for details.

Note that $entry1 and $entry2 are passed by value and may be changed or
set to undef after this function is called.

=cut

#if HAS_archive_entry_linkify

int
archive_entry_linkify(linkresolver, entry1, entry2)
    struct archive_entry_linkresolver *linkresolver
    SV *entry1
    SV *entry2
  CODE:
    struct archive_entry *e1=NULL,*e2=NULL;
    
    /* INPUT */
    if(SvOK(entry1))
      e1 = INT2PTR(struct archive_entry *, SvIV(entry1));
    if(SvOK(entry2))
      e2 = INT2PTR(struct archive_entry *, SvIV(entry2));

    /* CALL */
    archive_entry_linkify(linkresolver, &e1, &e2);

    /* OUTPUT */
    if(e1 == NULL)
      sv_setsv(entry1, &PL_sv_undef);
    else
      sv_setiv(entry1, PTR2IV(e1));
    if(e2 == NULL)
      sv_setsv(entry2, &PL_sv_undef);
    else
      sv_setiv(entry2, PTR2IV(e2));
    RETVAL = ARCHIVE_OK;
    
  OUTPUT:
    RETVAL
    entry1
    entry2

#endif

=head2 archive_entry_uid

 my $uid = archive_entry_uid($entry);

Get the UID (user id) property for the archive entry.

=cut

#if HAS_archive_entry_uid

__LA_INT64_T
archive_entry_uid(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_set_uid

 my $status = archive_entry_set_uid($entry, $uid);

Set the UID (user id) property for the archive entry.

=cut

#if HAS_archive_entry_set_uid

int
archive_entry_set_uid(entry, uid)
    struct archive_entry *entry
    __LA_INT64_T uid
  CODE:
    archive_entry_set_uid(entry, uid);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_set_error

 my $status = archive_set_error($archive, $errno, $format, @args);

Sets the numeric error code and error description that will be returned by
L<#archive_errno> and L<#archive_error_string>.  This function should be
used within I/O callbacks to set system-specific error codes and error
descriptions.  This function accepts a printf-like format string and
arguments (via perl's L<sprintf|perlfunc#sprintf>.

=cut

#if HAS_archive_set_error

int
_archive_set_error(archive, status, string)
    struct archive *archive
    int status
    const char *string
  CODE:
    archive_set_error(archive, status, "%s", string);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_strmode

 my $strmode = archive_entry_strmode($entry);

Returns a string representation of the archive entry's permission mode,
a la the Unix C<ls> command (example: a mode of C<0644> should come back
as C<-rw-r--r-->.

=cut

#if HAS_archive_entry_strmode

string_or_null
archive_entry_strmode(entry)
    struct archive_entry *entry

#endif

=head2 archive_read_extract_set_skip_file

 my $status = archive_read_extract_set_skip_file($archive, $dev, $ino);

Record the dev/ino of a file that will not be written.  This is
generally set to the dev/ino of the archive being read.

=cut

#if HAS_archive_read_extract_set_skip_file

int
archive_read_extract_set_skip_file(archive, dev, ino)
    struct archive *archive
    __LA_INT64_T dev
    __LA_INT64_T ino
  CODE:
    archive_read_extract_set_skip_file(archive, dev, ino);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_read_extract

 my $status = archive_read_extract($archive, $entry, $flags);

A convenience function that wraps the corresponding archive_write_disk interfaces.  The first call to L<#archive_read_extract> creates a restore object using L<#archive_write_disk_new> and
L<#archive_write_disk_set_standard_lookup>, then transparently invokes L<#archive_write_disk_set_options>, L<#archive_write_header>, L<#archive_write_data>, and L<#archive_write_finish_entry> to
create the entry on disk and copy data into it.  The flags argument is passed unmodified to L<#archive_write_disk_set_options>.

=cut

#if HAS_archive_read_extract

int
archive_read_extract(archive, entry, flags)
    struct archive *archive
    struct archive_entry *entry
    int flags

#endif

=head2 archive_read_extract2

 my $status = archive_read_extract2($archive1, $entry, $archive2);

This is another version of archive_read_extract() that allows you to provide your own restore object.  In particular, this allows you to override the standard lookup functions using
L<#archive_write_disk_set_group_lookup>, and L<#archive_write_disk_set_user_lookup>.  Note that L<#archive_read_extract2> does not accept a flags argument; you should use
L<#archive_write_disk_set_options> to set the restore options yourself.

=cut

#if HAS_archive_read_extract2

int
archive_read_extract2(archive1, entry, archive2)
    struct archive *archive1
    struct archive_entry *entry
    struct archive *archive2

#endif

=head2 archive_read_disk_entry_from_file

 my $status = archive_read_disk_entry_from_file($archive, $entry, $fh, undef);
 my $status = archive_read_disk_entry_from_file($archive, $entry, $fh, \\@stat);
 my $status = archive_read_disk_entry_from_file($archive, $entry, undef, \\@stat);

Populates a struct archive_entry object with information about a particular file.  The archive_entry object must have already been created with L<#archive_entry_new> and at least one of the
source path or path fields must already be set.  (If both are set, the source path will be used.)

Information is read from disk using the path name from the struct archive_entry object.  If a file handle ($fh) is provided, some information will be obtained using that file handle, on
platforms that support the appropriate system calls.

Note: The C API supports passing in a stat structure for some performance benefits.  Currently this is unsupported in the Perl version, and you must pass undef in as the forth argument,
for possible future compatibility.

Where necessary, user and group ids are converted to user and group names using the currently registered lookup functions above.  This affects the file ownership fields and ACL values in the
struct archive_entry object.

=cut

#if HAS_archive_read_disk_entry_from_file

int
_archive_read_disk_entry_from_file(archive, entry, fd, stat)
    struct archive *archive
    struct archive_entry *entry
    int fd
    SV *stat
  CODE:
    if(SvOK(stat))
      croak("stat field currently not supported");
    RETVAL = archive_read_disk_entry_from_file(archive, entry, fd, NULL);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_include_uid

 my $status = archive_match_include_uid($archive, $uid);

The match object $archive should match entries with the given $uid

=cut

#if HAS_archive_match_include_uid

int
archive_match_include_uid(archive, uid)
    struct archive *archive
    __LA_INT64_T uid

#endif

=head2 archive_match_include_gid

 my $status = archive_match_include_gid($archive, $gid);

The match object $archive should match entries with the given $gid

=cut

#if HAS_archive_match_include_gid

int
archive_match_include_gid(archive, gid)
    struct archive *archive
    __LA_INT64_T gid

#endif

=head2 archive_match_include_uname

 my $status = archive_match_include_uname($archive, $uname);

The match object $archive should match entries with the given user name

=cut

#if HAS_archive_match_include_uname

int
_archive_match_include_uname(archive, uname)
    struct archive *archive
    string_or_null uname
  CODE:
    RETVAL = archive_match_include_uname(archive, uname);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_include_gname

 my $status = archive_match_include_gname($archive, $gname);

The match object $archive should match entries with the given group name

=cut

#if HAS_archive_match_include_gname

int
_archive_match_include_gname(archive, gname)
    struct archive *archive
    string_or_null gname
  CODE:
    RETVAL = archive_match_include_gname(archive, gname);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_copy_sourcepath

 my $status = archive_entry_set_sourcepath($entry, $sourcepath);

Sets the sourcepath property for the archive entry object.

This is an alias for archive_entry_set_sourcepath.

=head2 archive_entry_set_sourcepath

 my $status = archive_entry_set_sourcepath($entry, $sourcepath);

Sets the sourcepath property for the archive entry object.

=cut

#if HAS_archive_entry_copy_sourcepath

int
_archive_entry_set_sourcepath(entry, sourcepath)
    struct archive_entry *entry
    const char *sourcepath
  CODE:
    archive_entry_copy_sourcepath(entry, sourcepath);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_sourcepath

 my $sourcepath = archive_entry_sourcepath($entry);

Gets the sourcepath property for the archive entry object.

=cut

#if HAS_archive_entry_sourcepath

const char *
_archive_entry_sourcepath(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_sourcepath(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_link

 my $status = archive_entry_set_link($entry, $string);

Set symlink if symlink is already set, else set hardlink.

=cut

#if HAS_archive_entry_set_link

int
_archive_entry_set_link(entry, string)
    struct archive_entry *entry
    string_or_null string
  CODE:
    archive_entry_set_link(entry, string);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_xattr_add_entry

 my $status = archive_entry_xattr_add_entry($entry, $name, $buffer);

Add an extended attribute (xattr) to the archive entry.

=cut

#if HAS_archive_entry_xattr_add_entry

int
archive_entry_xattr_add_entry(entry, name, buffer)
    struct archive_entry *entry
    const char *name
    SV *buffer
  CODE:
    const void *ptr;
    STRLEN size;
    ptr = SvPV(buffer, size);
    archive_entry_xattr_add_entry(entry, name, ptr, size);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_xattr_clear

 my $status = archive_entry_xattr_clear($entry);

Remove all extended attributes (xattr) to the archive entry.

=cut

#if HAS_archive_entry_xattr_clear

int
archive_entry_xattr_clear(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_xattr_clear(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_xattr_count

 my $count = archive_entry_xattr_count($entry);

Returns the number of extended attributes (xattr) for the archive entry.

=cut

#if HAS_archive_entry_xattr_count

int
archive_entry_xattr_count(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_xattr_reset

 my $status = archive_entry_xattr_reset($entry);

Reset the internal extended attributes (xattr) cursor for the archive entry.

=cut

#if HAS_archive_entry_xattr_reset

int
archive_entry_xattr_reset(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_xattr_next

 my $status = archive_entry_xattr_next($entry, $name, $buffer);

Retrieve the extended attribute (xattr) at the extended attributes (xattr) cursor, and
increment the cursor.  If the cursor is already at the end, it will return ARCHIVE_WARN,
$name and $buffer will be undef.  Here is an example which loops through all extended
attributes (xattr) for an archive entry:

 archive_entry_xattr_reset($entry);
 while(my $r = archive_entry_xattr_next($entry, my $name, my $value))
 {
   last if $r == ARCHIVE_WARN;
   die archive_error_string($a) if $r < ARCHIVE_OK;
   
   # do something with $name and $value
 }

=cut

#if HAS_archive_entry_xattr_next

int
archive_entry_xattr_next(entry, name, buffer)
    struct archive_entry *entry
    SV *name
    SV *buffer
  CODE:
    const char *name_ptr;
    const void *value_ptr;
    size_t size;
    RETVAL = archive_entry_xattr_next(entry, &name_ptr, &value_ptr, &size);
    sv_setpv(name, name_ptr);
    sv_setpvn(buffer, value_ptr, size);
  OUTPUT:
    RETVAL
    name
    buffer

#endif

=head2 archive_entry_sparse_clear

 my $status = archive_entry_sparse_clear($entry)

Remove all sparse region from the archive entry.

=cut

#if HAS_archive_entry_sparse_clear

int
archive_entry_sparse_clear(entry)
    struct archive_entry *entry
  CODE:
    archive_entry_sparse_clear(entry);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_sparse_add_entry

 my $status = archive_entry_sparse_add_entry($entry, $offset, $length)

Add a sparse region to the entry.

=cut

#if HAS_archive_entry_sparse_add_entry

int
archive_entry_sparse_add_entry(entry, offset, length)
    struct archive_entry *entry
    __LA_INT64_T offset
    __LA_INT64_T length
  CODE:
    archive_entry_sparse_add_entry(entry, offset, length);
    RETVAL = ARCHIVE_OK;
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_sparse_count

 my $count = archive_entry_sparse_count($entry);

Return the number of sparse entries in the entry.

=cut

#if HAS_archive_entry_sparse_count

int
archive_entry_sparse_count(entry)
   struct archive_entry *entry

#endif

=head2 archive_entry_sparse_reset

 my $count = archive_entry_sparse_reset($entry);

Reset the internal sparse region iterator for the entry (see L<#archive_entry_sparse_next> for an example).

=cut

#if HAS_archive_entry_sparse_reset

int
archive_entry_sparse_reset(entry)
    struct archive_entry *entry

#endif

=head2 archive_entry_sparse_next

 my $status = archive_entry_sparse_next($entry, $offset, $length);

Return the next sparse region for the entry.  Example:

 archive_entry_sparse_reset($entry);
 while(my $r = archive_entry_sparse_next($entry, $offset, $length))
 {
   last if $r == ARCHIVE_WARN;
   die archive_error_string($a) if $r < ARCHIVE_OK;
   
   # do something with $name and $value
 }

=cut

#ifdef HAS_archive_entry_sparse_next

int
archive_entry_sparse_next(entry, offset, length)
    struct archive_entry *entry
    SV *offset
    SV *length
  CODE:
    __LA_INT64_T o, l;
    SV *otmp, *ltmp;
    RETVAL = archive_entry_sparse_next(entry, &o, &l);
    otmp = sv_2mortal(newSVi64(o));
    sv_setsv(offset, otmp);
    ltmp = sv_2mortal(newSVi64(l));
    sv_setsv(length, ltmp);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_exclude_entry

 my $status = archive_match_exclude_entry($archive, $flag, $entry);

Add exclusion entry

=cut

#ifdef HAS_archive_match_exclude_entry

int
archive_match_exclude_entry(archive, flag, entry)
    struct archive *archive
    int flag
    struct archive_entry *entry

#endif

=head2 archive_match_exclude_pattern

 my $status = archive_match_exclude_pattern($archive, $pattern);

Add exclusion pathname pattern.

=cut

#ifdef HAS_archive_match_exclude_pattern

int
_archive_match_exclude_pattern(archive, pattern)
    struct archive *archive
    const char *pattern
  CODE:
    RETVAL = archive_match_exclude_pattern(archive, pattern);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_exclude_pattern_from_file

 my $status = archive_match_exclude_pattern_from_file($archive, $filename, $null_separator);

Add exclusion pathname pattern from file.

=cut

#ifdef HAS_archive_match_exclude_pattern_from_file

int
_archive_match_exclude_pattern_from_file(archive, filename, null_separator)
    struct archive *archive
    const char *filename
    int null_separator 
  CODE:
    RETVAL = archive_match_exclude_pattern_from_file(archive, filename, null_separator);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_include_date

 my $status = archive_match_include_date($archive, $flag, $date_string);

Set inclusion time by a date string

=cut

#ifdef HAS_archive_match_include_date

int
archive_match_include_date(archive, flag, date_string)
    struct archive *archive
    int flag
    const char *date_string

#endif

=head2 archive_match_include_file_time

 my $status = archive_match_include_file_time($archive, $flag, $pathname);

Set inclusion time by a particular file

=cut

#ifdef HAS_archive_match_include_file_time

int
_archive_match_include_file_time(archive, flag, pathname)
    struct archive *archive
    int flag
    const char *pathname
  CODE:
    RETVAL = archive_match_include_file_time(archive, flag, pathname);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_include_pattern

 my $status = archive_match_include_pattern_from_file($archive, $pattern);

Add inclusion pathname pattern

=cut

#ifdef HAS_archive_match_include_pattern

int
_archive_match_include_pattern(archive, pattern)
    struct archive *archive
    const char *pattern
  CODE:
    RETVAL = archive_match_include_pattern(archive, pattern);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_include_pattern_from_file

 my $status = archive_match_include_pattern_from_file($archive, $filename, $null_separator);

Add inclusion pathname pattern from file

=cut

#ifdef HAS_archive_match_include_pattern_from_file

int
_archive_match_include_pattern_from_file(archive, filename, null_separator)
    struct archive *archive
    const char *filename
    int null_separator 
  CODE:
    RETVAL = archive_match_include_pattern_from_file(archive, filename, null_separator);
  OUTPUT:
    RETVAL

#endif

=head2 archive_match_include_time

 my $status = archive_match_include_time($archive, $flag, $sec, $nsec);

Set inclusion time

=cut

#ifdef HAS_archive_match_include_time

int
archive_match_include_time(archive, flag, sec, nsec)
    struct archive *archive
    int flag
    time_t sec
    long nsec

#endif

=head2 archive_match_path_unmatched_inclusions

 my $count = archive_match_path_unmatched_inclusions($archive);

Return the amount number of unmatched inclusion patterns

=cut

#ifdef HAS_archive_match_path_unmatched_inclusions

int
archive_match_path_unmatched_inclusions(archive)
    struct archive *archive

#endif

=head2 archive_match_path_unmatched_inclusions_next

 my $status = archive_match_path_unmatched_inclusions_next($archive, $pattern);

Fetch the next unmatched pattern.

=cut

#ifdef HAS_archive_match_path_unmatched_inclusions_next

int
archive_match_path_unmatched_inclusions_next(archive, pattern)
    struct archive *archive
    SV *pattern
  CODE:
    const char *tmp;
    RETVAL = archive_match_path_unmatched_inclusions_next(archive, &tmp);
    sv_setpv(pattern, tmp);
  OUTPUT:
    RETVAL

#endif

int
_constant(name)
        char *name
    CODE:
        if(!strcmp(name, "ARCHIVE_OK"))
          RETVAL = ARCHIVE_OK;
        /* CONSTANT AUTOGEN BEGIN */
#ifdef AE_IFBLK
        else if(!strcmp(name, "AE_IFBLK"))
          RETVAL = AE_IFBLK;
#endif
#ifdef AE_IFCHR
        else if(!strcmp(name, "AE_IFCHR"))
          RETVAL = AE_IFCHR;
#endif
#ifdef AE_IFDIR
        else if(!strcmp(name, "AE_IFDIR"))
          RETVAL = AE_IFDIR;
#endif
#ifdef AE_IFIFO
        else if(!strcmp(name, "AE_IFIFO"))
          RETVAL = AE_IFIFO;
#endif
#ifdef AE_IFLNK
        else if(!strcmp(name, "AE_IFLNK"))
          RETVAL = AE_IFLNK;
#endif
#ifdef AE_IFMT
        else if(!strcmp(name, "AE_IFMT"))
          RETVAL = AE_IFMT;
#endif
#ifdef AE_IFREG
        else if(!strcmp(name, "AE_IFREG"))
          RETVAL = AE_IFREG;
#endif
#ifdef AE_IFSOCK
        else if(!strcmp(name, "AE_IFSOCK"))
          RETVAL = AE_IFSOCK;
#endif
#ifdef ARCHIVE_API_FEATURE
        else if(!strcmp(name, "ARCHIVE_API_FEATURE"))
          RETVAL = ARCHIVE_API_FEATURE;
#endif
#ifdef ARCHIVE_API_VERSION
        else if(!strcmp(name, "ARCHIVE_API_VERSION"))
          RETVAL = ARCHIVE_API_VERSION;
#endif
#ifdef ARCHIVE_BYTES_PER_RECORD
        else if(!strcmp(name, "ARCHIVE_BYTES_PER_RECORD"))
          RETVAL = ARCHIVE_BYTES_PER_RECORD;
#endif
#ifdef ARCHIVE_COMPRESSION_BZIP2
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_BZIP2"))
          RETVAL = ARCHIVE_COMPRESSION_BZIP2;
#endif
#ifdef ARCHIVE_COMPRESSION_COMPRESS
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_COMPRESS"))
          RETVAL = ARCHIVE_COMPRESSION_COMPRESS;
#endif
#ifdef ARCHIVE_COMPRESSION_GZIP
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_GZIP"))
          RETVAL = ARCHIVE_COMPRESSION_GZIP;
#endif
#ifdef ARCHIVE_COMPRESSION_LRZIP
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_LRZIP"))
          RETVAL = ARCHIVE_COMPRESSION_LRZIP;
#endif
#ifdef ARCHIVE_COMPRESSION_LZIP
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_LZIP"))
          RETVAL = ARCHIVE_COMPRESSION_LZIP;
#endif
#ifdef ARCHIVE_COMPRESSION_LZMA
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_LZMA"))
          RETVAL = ARCHIVE_COMPRESSION_LZMA;
#endif
#ifdef ARCHIVE_COMPRESSION_NONE
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_NONE"))
          RETVAL = ARCHIVE_COMPRESSION_NONE;
#endif
#ifdef ARCHIVE_COMPRESSION_PROGRAM
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_PROGRAM"))
          RETVAL = ARCHIVE_COMPRESSION_PROGRAM;
#endif
#ifdef ARCHIVE_COMPRESSION_RPM
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_RPM"))
          RETVAL = ARCHIVE_COMPRESSION_RPM;
#endif
#ifdef ARCHIVE_COMPRESSION_UU
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_UU"))
          RETVAL = ARCHIVE_COMPRESSION_UU;
#endif
#ifdef ARCHIVE_COMPRESSION_XZ
        else if(!strcmp(name, "ARCHIVE_COMPRESSION_XZ"))
          RETVAL = ARCHIVE_COMPRESSION_XZ;
#endif
#ifdef ARCHIVE_DEFAULT_BYTES_PER_BLOCK
        else if(!strcmp(name, "ARCHIVE_DEFAULT_BYTES_PER_BLOCK"))
          RETVAL = ARCHIVE_DEFAULT_BYTES_PER_BLOCK;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ADD_FILE
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ADD_FILE"))
          RETVAL = ARCHIVE_ENTRY_ACL_ADD_FILE;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ADD_SUBDIRECTORY
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ADD_SUBDIRECTORY"))
          RETVAL = ARCHIVE_ENTRY_ACL_ADD_SUBDIRECTORY;
#endif
#ifdef ARCHIVE_ENTRY_ACL_APPEND_DATA
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_APPEND_DATA"))
          RETVAL = ARCHIVE_ENTRY_ACL_APPEND_DATA;
#endif
#ifdef ARCHIVE_ENTRY_ACL_DELETE
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_DELETE"))
          RETVAL = ARCHIVE_ENTRY_ACL_DELETE;
#endif
#ifdef ARCHIVE_ENTRY_ACL_DELETE_CHILD
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_DELETE_CHILD"))
          RETVAL = ARCHIVE_ENTRY_ACL_DELETE_CHILD;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ENTRY_DIRECTORY_INHERIT
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ENTRY_DIRECTORY_INHERIT"))
          RETVAL = ARCHIVE_ENTRY_ACL_ENTRY_DIRECTORY_INHERIT;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ENTRY_FAILED_ACCESS
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ENTRY_FAILED_ACCESS"))
          RETVAL = ARCHIVE_ENTRY_ACL_ENTRY_FAILED_ACCESS;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ENTRY_FILE_INHERIT
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ENTRY_FILE_INHERIT"))
          RETVAL = ARCHIVE_ENTRY_ACL_ENTRY_FILE_INHERIT;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ENTRY_INHERIT_ONLY
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ENTRY_INHERIT_ONLY"))
          RETVAL = ARCHIVE_ENTRY_ACL_ENTRY_INHERIT_ONLY;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ENTRY_NO_PROPAGATE_INHERIT
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ENTRY_NO_PROPAGATE_INHERIT"))
          RETVAL = ARCHIVE_ENTRY_ACL_ENTRY_NO_PROPAGATE_INHERIT;
#endif
#ifdef ARCHIVE_ENTRY_ACL_ENTRY_SUCCESSFUL_ACCESS
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_ENTRY_SUCCESSFUL_ACCESS"))
          RETVAL = ARCHIVE_ENTRY_ACL_ENTRY_SUCCESSFUL_ACCESS;
#endif
#ifdef ARCHIVE_ENTRY_ACL_EVERYONE
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_EVERYONE"))
          RETVAL = ARCHIVE_ENTRY_ACL_EVERYONE;
#endif
#ifdef ARCHIVE_ENTRY_ACL_EXECUTE
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_EXECUTE"))
          RETVAL = ARCHIVE_ENTRY_ACL_EXECUTE;
#endif
#ifdef ARCHIVE_ENTRY_ACL_GROUP
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_GROUP"))
          RETVAL = ARCHIVE_ENTRY_ACL_GROUP;
#endif
#ifdef ARCHIVE_ENTRY_ACL_GROUP_OBJ
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_GROUP_OBJ"))
          RETVAL = ARCHIVE_ENTRY_ACL_GROUP_OBJ;
#endif
#ifdef ARCHIVE_ENTRY_ACL_INHERITANCE_NFS4
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_INHERITANCE_NFS4"))
          RETVAL = ARCHIVE_ENTRY_ACL_INHERITANCE_NFS4;
#endif
#ifdef ARCHIVE_ENTRY_ACL_LIST_DIRECTORY
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_LIST_DIRECTORY"))
          RETVAL = ARCHIVE_ENTRY_ACL_LIST_DIRECTORY;
#endif
#ifdef ARCHIVE_ENTRY_ACL_MASK
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_MASK"))
          RETVAL = ARCHIVE_ENTRY_ACL_MASK;
#endif
#ifdef ARCHIVE_ENTRY_ACL_OTHER
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_OTHER"))
          RETVAL = ARCHIVE_ENTRY_ACL_OTHER;
#endif
#ifdef ARCHIVE_ENTRY_ACL_PERMS_NFS4
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_PERMS_NFS4"))
          RETVAL = ARCHIVE_ENTRY_ACL_PERMS_NFS4;
#endif
#ifdef ARCHIVE_ENTRY_ACL_PERMS_POSIX1E
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_PERMS_POSIX1E"))
          RETVAL = ARCHIVE_ENTRY_ACL_PERMS_POSIX1E;
#endif
#ifdef ARCHIVE_ENTRY_ACL_READ
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_READ"))
          RETVAL = ARCHIVE_ENTRY_ACL_READ;
#endif
#ifdef ARCHIVE_ENTRY_ACL_READ_ACL
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_READ_ACL"))
          RETVAL = ARCHIVE_ENTRY_ACL_READ_ACL;
#endif
#ifdef ARCHIVE_ENTRY_ACL_READ_ATTRIBUTES
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_READ_ATTRIBUTES"))
          RETVAL = ARCHIVE_ENTRY_ACL_READ_ATTRIBUTES;
#endif
#ifdef ARCHIVE_ENTRY_ACL_READ_DATA
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_READ_DATA"))
          RETVAL = ARCHIVE_ENTRY_ACL_READ_DATA;
#endif
#ifdef ARCHIVE_ENTRY_ACL_READ_NAMED_ATTRS
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_READ_NAMED_ATTRS"))
          RETVAL = ARCHIVE_ENTRY_ACL_READ_NAMED_ATTRS;
#endif
#ifdef ARCHIVE_ENTRY_ACL_STYLE_EXTRA_ID
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_STYLE_EXTRA_ID"))
          RETVAL = ARCHIVE_ENTRY_ACL_STYLE_EXTRA_ID;
#endif
#ifdef ARCHIVE_ENTRY_ACL_STYLE_MARK_DEFAULT
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_STYLE_MARK_DEFAULT"))
          RETVAL = ARCHIVE_ENTRY_ACL_STYLE_MARK_DEFAULT;
#endif
#ifdef ARCHIVE_ENTRY_ACL_SYNCHRONIZE
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_SYNCHRONIZE"))
          RETVAL = ARCHIVE_ENTRY_ACL_SYNCHRONIZE;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_ACCESS
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_ACCESS"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_ACCESS;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_ALARM
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_ALARM"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_ALARM;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_ALLOW
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_ALLOW"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_ALLOW;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_AUDIT
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_AUDIT"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_AUDIT;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_DEFAULT
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_DEFAULT"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_DEFAULT;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_DENY
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_DENY"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_DENY;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_NFS4
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_NFS4"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_NFS4;
#endif
#ifdef ARCHIVE_ENTRY_ACL_TYPE_POSIX1E
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_TYPE_POSIX1E"))
          RETVAL = ARCHIVE_ENTRY_ACL_TYPE_POSIX1E;
#endif
#ifdef ARCHIVE_ENTRY_ACL_USER
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_USER"))
          RETVAL = ARCHIVE_ENTRY_ACL_USER;
#endif
#ifdef ARCHIVE_ENTRY_ACL_USER_OBJ
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_USER_OBJ"))
          RETVAL = ARCHIVE_ENTRY_ACL_USER_OBJ;
#endif
#ifdef ARCHIVE_ENTRY_ACL_WRITE
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_WRITE"))
          RETVAL = ARCHIVE_ENTRY_ACL_WRITE;
#endif
#ifdef ARCHIVE_ENTRY_ACL_WRITE_ACL
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_WRITE_ACL"))
          RETVAL = ARCHIVE_ENTRY_ACL_WRITE_ACL;
#endif
#ifdef ARCHIVE_ENTRY_ACL_WRITE_ATTRIBUTES
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_WRITE_ATTRIBUTES"))
          RETVAL = ARCHIVE_ENTRY_ACL_WRITE_ATTRIBUTES;
#endif
#ifdef ARCHIVE_ENTRY_ACL_WRITE_DATA
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_WRITE_DATA"))
          RETVAL = ARCHIVE_ENTRY_ACL_WRITE_DATA;
#endif
#ifdef ARCHIVE_ENTRY_ACL_WRITE_NAMED_ATTRS
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_WRITE_NAMED_ATTRS"))
          RETVAL = ARCHIVE_ENTRY_ACL_WRITE_NAMED_ATTRS;
#endif
#ifdef ARCHIVE_ENTRY_ACL_WRITE_OWNER
        else if(!strcmp(name, "ARCHIVE_ENTRY_ACL_WRITE_OWNER"))
          RETVAL = ARCHIVE_ENTRY_ACL_WRITE_OWNER;
#endif
#ifdef ARCHIVE_EOF
        else if(!strcmp(name, "ARCHIVE_EOF"))
          RETVAL = ARCHIVE_EOF;
#endif
#ifdef ARCHIVE_EXTRACT_ACL
        else if(!strcmp(name, "ARCHIVE_EXTRACT_ACL"))
          RETVAL = ARCHIVE_EXTRACT_ACL;
#endif
#ifdef ARCHIVE_EXTRACT_FFLAGS
        else if(!strcmp(name, "ARCHIVE_EXTRACT_FFLAGS"))
          RETVAL = ARCHIVE_EXTRACT_FFLAGS;
#endif
#ifdef ARCHIVE_EXTRACT_HFS_COMPRESSION_FORCED
        else if(!strcmp(name, "ARCHIVE_EXTRACT_HFS_COMPRESSION_FORCED"))
          RETVAL = ARCHIVE_EXTRACT_HFS_COMPRESSION_FORCED;
#endif
#ifdef ARCHIVE_EXTRACT_MAC_METADATA
        else if(!strcmp(name, "ARCHIVE_EXTRACT_MAC_METADATA"))
          RETVAL = ARCHIVE_EXTRACT_MAC_METADATA;
#endif
#ifdef ARCHIVE_EXTRACT_NO_AUTODIR
        else if(!strcmp(name, "ARCHIVE_EXTRACT_NO_AUTODIR"))
          RETVAL = ARCHIVE_EXTRACT_NO_AUTODIR;
#endif
#ifdef ARCHIVE_EXTRACT_NO_HFS_COMPRESSION
        else if(!strcmp(name, "ARCHIVE_EXTRACT_NO_HFS_COMPRESSION"))
          RETVAL = ARCHIVE_EXTRACT_NO_HFS_COMPRESSION;
#endif
#ifdef ARCHIVE_EXTRACT_NO_OVERWRITE
        else if(!strcmp(name, "ARCHIVE_EXTRACT_NO_OVERWRITE"))
          RETVAL = ARCHIVE_EXTRACT_NO_OVERWRITE;
#endif
#ifdef ARCHIVE_EXTRACT_NO_OVERWRITE_NEWER
        else if(!strcmp(name, "ARCHIVE_EXTRACT_NO_OVERWRITE_NEWER"))
          RETVAL = ARCHIVE_EXTRACT_NO_OVERWRITE_NEWER;
#endif
#ifdef ARCHIVE_EXTRACT_OWNER
        else if(!strcmp(name, "ARCHIVE_EXTRACT_OWNER"))
          RETVAL = ARCHIVE_EXTRACT_OWNER;
#endif
#ifdef ARCHIVE_EXTRACT_PERM
        else if(!strcmp(name, "ARCHIVE_EXTRACT_PERM"))
          RETVAL = ARCHIVE_EXTRACT_PERM;
#endif
#ifdef ARCHIVE_EXTRACT_SECURE_NOABSOLUTEPATHS
        else if(!strcmp(name, "ARCHIVE_EXTRACT_SECURE_NOABSOLUTEPATHS"))
          RETVAL = ARCHIVE_EXTRACT_SECURE_NOABSOLUTEPATHS;
#endif
#ifdef ARCHIVE_EXTRACT_SECURE_NODOTDOT
        else if(!strcmp(name, "ARCHIVE_EXTRACT_SECURE_NODOTDOT"))
          RETVAL = ARCHIVE_EXTRACT_SECURE_NODOTDOT;
#endif
#ifdef ARCHIVE_EXTRACT_SECURE_SYMLINKS
        else if(!strcmp(name, "ARCHIVE_EXTRACT_SECURE_SYMLINKS"))
          RETVAL = ARCHIVE_EXTRACT_SECURE_SYMLINKS;
#endif
#ifdef ARCHIVE_EXTRACT_SPARSE
        else if(!strcmp(name, "ARCHIVE_EXTRACT_SPARSE"))
          RETVAL = ARCHIVE_EXTRACT_SPARSE;
#endif
#ifdef ARCHIVE_EXTRACT_TIME
        else if(!strcmp(name, "ARCHIVE_EXTRACT_TIME"))
          RETVAL = ARCHIVE_EXTRACT_TIME;
#endif
#ifdef ARCHIVE_EXTRACT_UNLINK
        else if(!strcmp(name, "ARCHIVE_EXTRACT_UNLINK"))
          RETVAL = ARCHIVE_EXTRACT_UNLINK;
#endif
#ifdef ARCHIVE_EXTRACT_XATTR
        else if(!strcmp(name, "ARCHIVE_EXTRACT_XATTR"))
          RETVAL = ARCHIVE_EXTRACT_XATTR;
#endif
#ifdef ARCHIVE_FAILED
        else if(!strcmp(name, "ARCHIVE_FAILED"))
          RETVAL = ARCHIVE_FAILED;
#endif
#ifdef ARCHIVE_FATAL
        else if(!strcmp(name, "ARCHIVE_FATAL"))
          RETVAL = ARCHIVE_FATAL;
#endif
#ifdef ARCHIVE_FILTER_BZIP2
        else if(!strcmp(name, "ARCHIVE_FILTER_BZIP2"))
          RETVAL = ARCHIVE_FILTER_BZIP2;
#endif
#ifdef ARCHIVE_FILTER_COMPRESS
        else if(!strcmp(name, "ARCHIVE_FILTER_COMPRESS"))
          RETVAL = ARCHIVE_FILTER_COMPRESS;
#endif
#ifdef ARCHIVE_FILTER_GRZIP
        else if(!strcmp(name, "ARCHIVE_FILTER_GRZIP"))
          RETVAL = ARCHIVE_FILTER_GRZIP;
#endif
#ifdef ARCHIVE_FILTER_GZIP
        else if(!strcmp(name, "ARCHIVE_FILTER_GZIP"))
          RETVAL = ARCHIVE_FILTER_GZIP;
#endif
#ifdef ARCHIVE_FILTER_LRZIP
        else if(!strcmp(name, "ARCHIVE_FILTER_LRZIP"))
          RETVAL = ARCHIVE_FILTER_LRZIP;
#endif
#ifdef ARCHIVE_FILTER_LZIP
        else if(!strcmp(name, "ARCHIVE_FILTER_LZIP"))
          RETVAL = ARCHIVE_FILTER_LZIP;
#endif
#ifdef ARCHIVE_FILTER_LZMA
        else if(!strcmp(name, "ARCHIVE_FILTER_LZMA"))
          RETVAL = ARCHIVE_FILTER_LZMA;
#endif
#ifdef ARCHIVE_FILTER_LZOP
        else if(!strcmp(name, "ARCHIVE_FILTER_LZOP"))
          RETVAL = ARCHIVE_FILTER_LZOP;
#endif
#ifdef ARCHIVE_FILTER_NONE
        else if(!strcmp(name, "ARCHIVE_FILTER_NONE"))
          RETVAL = ARCHIVE_FILTER_NONE;
#endif
#ifdef ARCHIVE_FILTER_PROGRAM
        else if(!strcmp(name, "ARCHIVE_FILTER_PROGRAM"))
          RETVAL = ARCHIVE_FILTER_PROGRAM;
#endif
#ifdef ARCHIVE_FILTER_RPM
        else if(!strcmp(name, "ARCHIVE_FILTER_RPM"))
          RETVAL = ARCHIVE_FILTER_RPM;
#endif
#ifdef ARCHIVE_FILTER_UU
        else if(!strcmp(name, "ARCHIVE_FILTER_UU"))
          RETVAL = ARCHIVE_FILTER_UU;
#endif
#ifdef ARCHIVE_FILTER_XZ
        else if(!strcmp(name, "ARCHIVE_FILTER_XZ"))
          RETVAL = ARCHIVE_FILTER_XZ;
#endif
#ifdef ARCHIVE_FORMAT_7ZIP
        else if(!strcmp(name, "ARCHIVE_FORMAT_7ZIP"))
          RETVAL = ARCHIVE_FORMAT_7ZIP;
#endif
#ifdef ARCHIVE_FORMAT_AR
        else if(!strcmp(name, "ARCHIVE_FORMAT_AR"))
          RETVAL = ARCHIVE_FORMAT_AR;
#endif
#ifdef ARCHIVE_FORMAT_AR_BSD
        else if(!strcmp(name, "ARCHIVE_FORMAT_AR_BSD"))
          RETVAL = ARCHIVE_FORMAT_AR_BSD;
#endif
#ifdef ARCHIVE_FORMAT_AR_GNU
        else if(!strcmp(name, "ARCHIVE_FORMAT_AR_GNU"))
          RETVAL = ARCHIVE_FORMAT_AR_GNU;
#endif
#ifdef ARCHIVE_FORMAT_BASE_MASK
        else if(!strcmp(name, "ARCHIVE_FORMAT_BASE_MASK"))
          RETVAL = ARCHIVE_FORMAT_BASE_MASK;
#endif
#ifdef ARCHIVE_FORMAT_CAB
        else if(!strcmp(name, "ARCHIVE_FORMAT_CAB"))
          RETVAL = ARCHIVE_FORMAT_CAB;
#endif
#ifdef ARCHIVE_FORMAT_CPIO
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO"))
          RETVAL = ARCHIVE_FORMAT_CPIO;
#endif
#ifdef ARCHIVE_FORMAT_CPIO_AFIO_LARGE
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO_AFIO_LARGE"))
          RETVAL = ARCHIVE_FORMAT_CPIO_AFIO_LARGE;
#endif
#ifdef ARCHIVE_FORMAT_CPIO_BIN_BE
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO_BIN_BE"))
          RETVAL = ARCHIVE_FORMAT_CPIO_BIN_BE;
#endif
#ifdef ARCHIVE_FORMAT_CPIO_BIN_LE
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO_BIN_LE"))
          RETVAL = ARCHIVE_FORMAT_CPIO_BIN_LE;
#endif
#ifdef ARCHIVE_FORMAT_CPIO_POSIX
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO_POSIX"))
          RETVAL = ARCHIVE_FORMAT_CPIO_POSIX;
#endif
#ifdef ARCHIVE_FORMAT_CPIO_SVR4_CRC
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO_SVR4_CRC"))
          RETVAL = ARCHIVE_FORMAT_CPIO_SVR4_CRC;
#endif
#ifdef ARCHIVE_FORMAT_CPIO_SVR4_NOCRC
        else if(!strcmp(name, "ARCHIVE_FORMAT_CPIO_SVR4_NOCRC"))
          RETVAL = ARCHIVE_FORMAT_CPIO_SVR4_NOCRC;
#endif
#ifdef ARCHIVE_FORMAT_EMPTY
        else if(!strcmp(name, "ARCHIVE_FORMAT_EMPTY"))
          RETVAL = ARCHIVE_FORMAT_EMPTY;
#endif
#ifdef ARCHIVE_FORMAT_ISO9660
        else if(!strcmp(name, "ARCHIVE_FORMAT_ISO9660"))
          RETVAL = ARCHIVE_FORMAT_ISO9660;
#endif
#ifdef ARCHIVE_FORMAT_ISO9660_ROCKRIDGE
        else if(!strcmp(name, "ARCHIVE_FORMAT_ISO9660_ROCKRIDGE"))
          RETVAL = ARCHIVE_FORMAT_ISO9660_ROCKRIDGE;
#endif
#ifdef ARCHIVE_FORMAT_LHA
        else if(!strcmp(name, "ARCHIVE_FORMAT_LHA"))
          RETVAL = ARCHIVE_FORMAT_LHA;
#endif
#ifdef ARCHIVE_FORMAT_MTREE
        else if(!strcmp(name, "ARCHIVE_FORMAT_MTREE"))
          RETVAL = ARCHIVE_FORMAT_MTREE;
#endif
#ifdef ARCHIVE_FORMAT_RAR
        else if(!strcmp(name, "ARCHIVE_FORMAT_RAR"))
          RETVAL = ARCHIVE_FORMAT_RAR;
#endif
#ifdef ARCHIVE_FORMAT_RAW
        else if(!strcmp(name, "ARCHIVE_FORMAT_RAW"))
          RETVAL = ARCHIVE_FORMAT_RAW;
#endif
#ifdef ARCHIVE_FORMAT_SHAR
        else if(!strcmp(name, "ARCHIVE_FORMAT_SHAR"))
          RETVAL = ARCHIVE_FORMAT_SHAR;
#endif
#ifdef ARCHIVE_FORMAT_SHAR_BASE
        else if(!strcmp(name, "ARCHIVE_FORMAT_SHAR_BASE"))
          RETVAL = ARCHIVE_FORMAT_SHAR_BASE;
#endif
#ifdef ARCHIVE_FORMAT_SHAR_DUMP
        else if(!strcmp(name, "ARCHIVE_FORMAT_SHAR_DUMP"))
          RETVAL = ARCHIVE_FORMAT_SHAR_DUMP;
#endif
#ifdef ARCHIVE_FORMAT_TAR
        else if(!strcmp(name, "ARCHIVE_FORMAT_TAR"))
          RETVAL = ARCHIVE_FORMAT_TAR;
#endif
#ifdef ARCHIVE_FORMAT_TAR_GNUTAR
        else if(!strcmp(name, "ARCHIVE_FORMAT_TAR_GNUTAR"))
          RETVAL = ARCHIVE_FORMAT_TAR_GNUTAR;
#endif
#ifdef ARCHIVE_FORMAT_TAR_PAX_INTERCHANGE
        else if(!strcmp(name, "ARCHIVE_FORMAT_TAR_PAX_INTERCHANGE"))
          RETVAL = ARCHIVE_FORMAT_TAR_PAX_INTERCHANGE;
#endif
#ifdef ARCHIVE_FORMAT_TAR_PAX_RESTRICTED
        else if(!strcmp(name, "ARCHIVE_FORMAT_TAR_PAX_RESTRICTED"))
          RETVAL = ARCHIVE_FORMAT_TAR_PAX_RESTRICTED;
#endif
#ifdef ARCHIVE_FORMAT_TAR_USTAR
        else if(!strcmp(name, "ARCHIVE_FORMAT_TAR_USTAR"))
          RETVAL = ARCHIVE_FORMAT_TAR_USTAR;
#endif
#ifdef ARCHIVE_FORMAT_XAR
        else if(!strcmp(name, "ARCHIVE_FORMAT_XAR"))
          RETVAL = ARCHIVE_FORMAT_XAR;
#endif
#ifdef ARCHIVE_FORMAT_ZIP
        else if(!strcmp(name, "ARCHIVE_FORMAT_ZIP"))
          RETVAL = ARCHIVE_FORMAT_ZIP;
#endif
#ifdef ARCHIVE_LIBRARY_VERSION
        else if(!strcmp(name, "ARCHIVE_LIBRARY_VERSION"))
          RETVAL = ARCHIVE_LIBRARY_VERSION;
#endif
#ifdef ARCHIVE_MATCH_CTIME
        else if(!strcmp(name, "ARCHIVE_MATCH_CTIME"))
          RETVAL = ARCHIVE_MATCH_CTIME;
#endif
#ifdef ARCHIVE_MATCH_EQUAL
        else if(!strcmp(name, "ARCHIVE_MATCH_EQUAL"))
          RETVAL = ARCHIVE_MATCH_EQUAL;
#endif
#ifdef ARCHIVE_MATCH_MTIME
        else if(!strcmp(name, "ARCHIVE_MATCH_MTIME"))
          RETVAL = ARCHIVE_MATCH_MTIME;
#endif
#ifdef ARCHIVE_MATCH_NEWER
        else if(!strcmp(name, "ARCHIVE_MATCH_NEWER"))
          RETVAL = ARCHIVE_MATCH_NEWER;
#endif
#ifdef ARCHIVE_MATCH_OLDER
        else if(!strcmp(name, "ARCHIVE_MATCH_OLDER"))
          RETVAL = ARCHIVE_MATCH_OLDER;
#endif
#ifdef ARCHIVE_READDISK_HONOR_NODUMP
        else if(!strcmp(name, "ARCHIVE_READDISK_HONOR_NODUMP"))
          RETVAL = ARCHIVE_READDISK_HONOR_NODUMP;
#endif
#ifdef ARCHIVE_READDISK_MAC_COPYFILE
        else if(!strcmp(name, "ARCHIVE_READDISK_MAC_COPYFILE"))
          RETVAL = ARCHIVE_READDISK_MAC_COPYFILE;
#endif
#ifdef ARCHIVE_READDISK_NO_TRAVERSE_MOUNTS
        else if(!strcmp(name, "ARCHIVE_READDISK_NO_TRAVERSE_MOUNTS"))
          RETVAL = ARCHIVE_READDISK_NO_TRAVERSE_MOUNTS;
#endif
#ifdef ARCHIVE_READDISK_RESTORE_ATIME
        else if(!strcmp(name, "ARCHIVE_READDISK_RESTORE_ATIME"))
          RETVAL = ARCHIVE_READDISK_RESTORE_ATIME;
#endif
#ifdef ARCHIVE_RETRY
        else if(!strcmp(name, "ARCHIVE_RETRY"))
          RETVAL = ARCHIVE_RETRY;
#endif
#ifdef ARCHIVE_VERSION_NUMBER
        else if(!strcmp(name, "ARCHIVE_VERSION_NUMBER"))
          RETVAL = ARCHIVE_VERSION_NUMBER;
#endif
#ifdef ARCHIVE_VERSION_STAMP
        else if(!strcmp(name, "ARCHIVE_VERSION_STAMP"))
          RETVAL = ARCHIVE_VERSION_STAMP;
#endif
#ifdef ARCHIVE_WARN
        else if(!strcmp(name, "ARCHIVE_WARN"))
          RETVAL = ARCHIVE_WARN;
#endif
        /* CONSTANT AUTOGEN END */
        else
          Perl_croak(aTHX_ "No such constant");
    OUTPUT:
        RETVAL


/* PURE AUTOGEN BEGIN */
/* Do not edit anything below this line as it is autogenerated
and will be lost the next time you run dzil build */

=head2 archive_read_support_filter_bzip2

 my $status = archive_read_support_filter_bzip2($archive);

Enable bzip2 decompression filter.

=cut

#if HAS_archive_read_support_filter_bzip2

int
archive_read_support_filter_bzip2(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_compress

 my $status = archive_read_support_filter_compress($archive);

Enable compress decompression filter.

=cut

#if HAS_archive_read_support_filter_compress

int
archive_read_support_filter_compress(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_grzip

 my $status = archive_read_support_filter_grzip($archive);

Enable grzip decompression filter.

=cut

#if HAS_archive_read_support_filter_grzip

int
archive_read_support_filter_grzip(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_gzip

 my $status = archive_read_support_filter_gzip($archive);

Enable gzip decompression filter.

=cut

#if HAS_archive_read_support_filter_gzip

int
archive_read_support_filter_gzip(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_lrzip

 my $status = archive_read_support_filter_lrzip($archive);

Enable lrzip decompression filter.

=cut

#if HAS_archive_read_support_filter_lrzip

int
archive_read_support_filter_lrzip(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_lzip

 my $status = archive_read_support_filter_lzip($archive);

Enable lzip decompression filter.

=cut

#if HAS_archive_read_support_filter_lzip

int
archive_read_support_filter_lzip(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_lzma

 my $status = archive_read_support_filter_lzma($archive);

Enable lzma decompression filter.

=cut

#if HAS_archive_read_support_filter_lzma

int
archive_read_support_filter_lzma(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_lzop

 my $status = archive_read_support_filter_lzop($archive);

Enable lzop decompression filter.

=cut

#if HAS_archive_read_support_filter_lzop

int
archive_read_support_filter_lzop(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_none

 my $status = archive_read_support_filter_none($archive);

Enable none decompression filter.

=cut

#if HAS_archive_read_support_filter_none

int
archive_read_support_filter_none(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_rpm

 my $status = archive_read_support_filter_rpm($archive);

Enable rpm decompression filter.

=cut

#if HAS_archive_read_support_filter_rpm

int
archive_read_support_filter_rpm(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_uu

 my $status = archive_read_support_filter_uu($archive);

Enable uu decompression filter.

=cut

#if HAS_archive_read_support_filter_uu

int
archive_read_support_filter_uu(archive)
    struct archive *archive

#endif

=head2 archive_read_support_filter_xz

 my $status = archive_read_support_filter_xz($archive);

Enable xz decompression filter.

=cut

#if HAS_archive_read_support_filter_xz

int
archive_read_support_filter_xz(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_7zip

 my $status = archive_read_support_format_7zip($archive);

Enable 7zip archive format.

=cut

#if HAS_archive_read_support_format_7zip

int
archive_read_support_format_7zip(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_ar

 my $status = archive_read_support_format_ar($archive);

Enable ar archive format.

=cut

#if HAS_archive_read_support_format_ar

int
archive_read_support_format_ar(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_cab

 my $status = archive_read_support_format_cab($archive);

Enable cab archive format.

=cut

#if HAS_archive_read_support_format_cab

int
archive_read_support_format_cab(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_cpio

 my $status = archive_read_support_format_cpio($archive);

Enable cpio archive format.

=cut

#if HAS_archive_read_support_format_cpio

int
archive_read_support_format_cpio(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_empty

 my $status = archive_read_support_format_empty($archive);

Enable empty archive format.

=cut

#if HAS_archive_read_support_format_empty

int
archive_read_support_format_empty(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_gnutar

 my $status = archive_read_support_format_gnutar($archive);

Enable gnutar archive format.

=cut

#if HAS_archive_read_support_format_gnutar

int
archive_read_support_format_gnutar(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_iso9660

 my $status = archive_read_support_format_iso9660($archive);

Enable iso9660 archive format.

=cut

#if HAS_archive_read_support_format_iso9660

int
archive_read_support_format_iso9660(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_lha

 my $status = archive_read_support_format_lha($archive);

Enable lha archive format.

=cut

#if HAS_archive_read_support_format_lha

int
archive_read_support_format_lha(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_mtree

 my $status = archive_read_support_format_mtree($archive);

Enable mtree archive format.

=cut

#if HAS_archive_read_support_format_mtree

int
archive_read_support_format_mtree(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_rar

 my $status = archive_read_support_format_rar($archive);

Enable rar archive format.

=cut

#if HAS_archive_read_support_format_rar

int
archive_read_support_format_rar(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_raw

 my $status = archive_read_support_format_raw($archive);

Enable raw archive format.

=cut

#if HAS_archive_read_support_format_raw

int
archive_read_support_format_raw(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_tar

 my $status = archive_read_support_format_tar($archive);

Enable tar archive format.

=cut

#if HAS_archive_read_support_format_tar

int
archive_read_support_format_tar(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_xar

 my $status = archive_read_support_format_xar($archive);

Enable xar archive format.

=cut

#if HAS_archive_read_support_format_xar

int
archive_read_support_format_xar(archive)
    struct archive *archive

#endif

=head2 archive_read_support_format_zip

 my $status = archive_read_support_format_zip($archive);

Enable zip archive format.

=cut

#if HAS_archive_read_support_format_zip

int
archive_read_support_format_zip(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_b64encode

 my $status = archive_write_add_filter_b64encode($archive);

Add b64encode filter

=cut

#if HAS_archive_write_add_filter_b64encode

int
archive_write_add_filter_b64encode(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_bzip2

 my $status = archive_write_add_filter_bzip2($archive);

Add bzip2 filter

=cut

#if HAS_archive_write_add_filter_bzip2

int
archive_write_add_filter_bzip2(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_compress

 my $status = archive_write_add_filter_compress($archive);

Add compress filter

=cut

#if HAS_archive_write_add_filter_compress

int
archive_write_add_filter_compress(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_grzip

 my $status = archive_write_add_filter_grzip($archive);

Add grzip filter

=cut

#if HAS_archive_write_add_filter_grzip

int
archive_write_add_filter_grzip(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_gzip

 my $status = archive_write_add_filter_gzip($archive);

Add gzip filter

=cut

#if HAS_archive_write_add_filter_gzip

int
archive_write_add_filter_gzip(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_lrzip

 my $status = archive_write_add_filter_lrzip($archive);

Add lrzip filter

=cut

#if HAS_archive_write_add_filter_lrzip

int
archive_write_add_filter_lrzip(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_lzip

 my $status = archive_write_add_filter_lzip($archive);

Add lzip filter

=cut

#if HAS_archive_write_add_filter_lzip

int
archive_write_add_filter_lzip(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_lzma

 my $status = archive_write_add_filter_lzma($archive);

Add lzma filter

=cut

#if HAS_archive_write_add_filter_lzma

int
archive_write_add_filter_lzma(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_lzop

 my $status = archive_write_add_filter_lzop($archive);

Add lzop filter

=cut

#if HAS_archive_write_add_filter_lzop

int
archive_write_add_filter_lzop(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_none

 my $status = archive_write_add_filter_none($archive);

Add none filter

=cut

#if HAS_archive_write_add_filter_none

int
archive_write_add_filter_none(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_uuencode

 my $status = archive_write_add_filter_uuencode($archive);

Add uuencode filter

=cut

#if HAS_archive_write_add_filter_uuencode

int
archive_write_add_filter_uuencode(archive)
    struct archive *archive

#endif

=head2 archive_write_add_filter_xz

 my $status = archive_write_add_filter_xz($archive);

Add xz filter

=cut

#if HAS_archive_write_add_filter_xz

int
archive_write_add_filter_xz(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_7zip($archive)

 my $status = archive_write_set_format_7zip($archive);

Set the archive format to 7zip

=cut

#if HAS_archive_write_set_format_7zip

int
archive_write_set_format_7zip(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_ar_bsd($archive)

 my $status = archive_write_set_format_ar_bsd($archive);

Set the archive format to ar_bsd

=cut

#if HAS_archive_write_set_format_ar_bsd

int
archive_write_set_format_ar_bsd(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_ar_svr4($archive)

 my $status = archive_write_set_format_ar_svr4($archive);

Set the archive format to ar_svr4

=cut

#if HAS_archive_write_set_format_ar_svr4

int
archive_write_set_format_ar_svr4(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_cpio($archive)

 my $status = archive_write_set_format_cpio($archive);

Set the archive format to cpio

=cut

#if HAS_archive_write_set_format_cpio

int
archive_write_set_format_cpio(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_cpio_newc($archive)

 my $status = archive_write_set_format_cpio_newc($archive);

Set the archive format to cpio_newc

=cut

#if HAS_archive_write_set_format_cpio_newc

int
archive_write_set_format_cpio_newc(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_gnutar($archive)

 my $status = archive_write_set_format_gnutar($archive);

Set the archive format to gnutar

=cut

#if HAS_archive_write_set_format_gnutar

int
archive_write_set_format_gnutar(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_iso9660($archive)

 my $status = archive_write_set_format_iso9660($archive);

Set the archive format to iso9660

=cut

#if HAS_archive_write_set_format_iso9660

int
archive_write_set_format_iso9660(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_mtree($archive)

 my $status = archive_write_set_format_mtree($archive);

Set the archive format to mtree

=cut

#if HAS_archive_write_set_format_mtree

int
archive_write_set_format_mtree(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_mtree_classic($archive)

 my $status = archive_write_set_format_mtree_classic($archive);

Set the archive format to mtree_classic

=cut

#if HAS_archive_write_set_format_mtree_classic

int
archive_write_set_format_mtree_classic(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_old_tar($archive)

 my $status = archive_write_set_format_old_tar($archive);

Set the archive format to old_tar

=cut

#if HAS_archive_write_set_format_old_tar

int
archive_write_set_format_old_tar(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_pax($archive)

 my $status = archive_write_set_format_pax($archive);

Set the archive format to pax

=cut

#if HAS_archive_write_set_format_pax

int
archive_write_set_format_pax(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_pax_restricted($archive)

 my $status = archive_write_set_format_pax_restricted($archive);

Set the archive format to pax_restricted

=cut

#if HAS_archive_write_set_format_pax_restricted

int
archive_write_set_format_pax_restricted(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_shar($archive)

 my $status = archive_write_set_format_shar($archive);

Set the archive format to shar

=cut

#if HAS_archive_write_set_format_shar

int
archive_write_set_format_shar(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_shar_dump($archive)

 my $status = archive_write_set_format_shar_dump($archive);

Set the archive format to shar_dump

=cut

#if HAS_archive_write_set_format_shar_dump

int
archive_write_set_format_shar_dump(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_ustar($archive)

 my $status = archive_write_set_format_ustar($archive);

Set the archive format to ustar

=cut

#if HAS_archive_write_set_format_ustar

int
archive_write_set_format_ustar(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_v7tar($archive)

 my $status = archive_write_set_format_v7tar($archive);

Set the archive format to v7tar

=cut

#if HAS_archive_write_set_format_v7tar

int
archive_write_set_format_v7tar(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_xar($archive)

 my $status = archive_write_set_format_xar($archive);

Set the archive format to xar

=cut

#if HAS_archive_write_set_format_xar

int
archive_write_set_format_xar(archive)
    struct archive *archive

#endif

=head2 archive_write_set_format_zip($archive)

 my $status = archive_write_set_format_zip($archive);

Set the archive format to zip

=cut

#if HAS_archive_write_set_format_zip

int
archive_write_set_format_zip(archive)
    struct archive *archive

#endif


=head2 archive_entry_set_gname

 my $status = archive_entry_set_gname($entry, $string)

Sets the gname for the archive entry object.

=cut

#ifdef HAS_archive_entry_copy_gname

int
archive_entry_set_gname(entry, gname)
    struct archive_entry *entry
    SV *gname
  CODE:
    if(SvOK(gname))
    {
#ifdef HAS_archive_entry_update_gname_utf8
      if(DO_UTF8(gname))
      {
        RETVAL = archive_entry_update_gname_utf8(entry, SvPV_nolen(gname));
        if(RETVAL > 0)
          RETVAL = ARCHIVE_OK;
      }
      else
      {
#endif
        archive_entry_copy_gname(entry, SvPV_nolen(gname));
        RETVAL = ARCHIVE_OK;
#ifdef HAS_archive_entry_update_gname_utf8
      }
    }
    else
    {
      archive_entry_copy_gname(entry, NULL);
      RETVAL = ARCHIVE_OK;
    }
#endif
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_gname

 my $string = archive_entry_gname($entry);

Retrieve the gname for the archive entry object.

=cut

#ifdef HAS_archive_entry_gname

string_or_null
_archive_entry_gname(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_gname(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_hardlink

 my $status = archive_entry_set_hardlink($entry, $string)

Sets the hardlink for the archive entry object.

=cut

#ifdef HAS_archive_entry_copy_hardlink

int
archive_entry_set_hardlink(entry, hardlink)
    struct archive_entry *entry
    SV *hardlink
  CODE:
    if(SvOK(hardlink))
    {
#ifdef HAS_archive_entry_update_hardlink_utf8
      if(DO_UTF8(hardlink))
      {
        RETVAL = archive_entry_update_hardlink_utf8(entry, SvPV_nolen(hardlink));
        if(RETVAL > 0)
          RETVAL = ARCHIVE_OK;
      }
      else
      {
#endif
        archive_entry_copy_hardlink(entry, SvPV_nolen(hardlink));
        RETVAL = ARCHIVE_OK;
#ifdef HAS_archive_entry_update_hardlink_utf8
      }
    }
    else
    {
      archive_entry_copy_hardlink(entry, NULL);
      RETVAL = ARCHIVE_OK;
    }
#endif
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_hardlink

 my $string = archive_entry_hardlink($entry);

Retrieve the hardlink for the archive entry object.

=cut

#ifdef HAS_archive_entry_hardlink

string_or_null
_archive_entry_hardlink(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_hardlink(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_pathname

 my $status = archive_entry_set_pathname($entry, $string)

Sets the pathname for the archive entry object.

=cut

#ifdef HAS_archive_entry_copy_pathname

int
archive_entry_set_pathname(entry, pathname)
    struct archive_entry *entry
    SV *pathname
  CODE:
    if(SvOK(pathname))
    {
#ifdef HAS_archive_entry_update_pathname_utf8
      if(DO_UTF8(pathname))
      {
        RETVAL = archive_entry_update_pathname_utf8(entry, SvPV_nolen(pathname));
        if(RETVAL > 0)
          RETVAL = ARCHIVE_OK;
      }
      else
      {
#endif
        archive_entry_copy_pathname(entry, SvPV_nolen(pathname));
        RETVAL = ARCHIVE_OK;
#ifdef HAS_archive_entry_update_pathname_utf8
      }
    }
    else
    {
      archive_entry_copy_pathname(entry, NULL);
      RETVAL = ARCHIVE_OK;
    }
#endif
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_pathname

 my $string = archive_entry_pathname($entry);

Retrieve the pathname for the archive entry object.

=cut

#ifdef HAS_archive_entry_pathname

string_or_null
_archive_entry_pathname(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_pathname(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_symlink

 my $status = archive_entry_set_symlink($entry, $string)

Sets the symlink for the archive entry object.

=cut

#ifdef HAS_archive_entry_copy_symlink

int
archive_entry_set_symlink(entry, symlink)
    struct archive_entry *entry
    SV *symlink
  CODE:
    if(SvOK(symlink))
    {
#ifdef HAS_archive_entry_update_symlink_utf8
      if(DO_UTF8(symlink))
      {
        RETVAL = archive_entry_update_symlink_utf8(entry, SvPV_nolen(symlink));
        if(RETVAL > 0)
          RETVAL = ARCHIVE_OK;
      }
      else
      {
#endif
        archive_entry_copy_symlink(entry, SvPV_nolen(symlink));
        RETVAL = ARCHIVE_OK;
#ifdef HAS_archive_entry_update_symlink_utf8
      }
    }
    else
    {
      archive_entry_copy_symlink(entry, NULL);
      RETVAL = ARCHIVE_OK;
    }
#endif
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_symlink

 my $string = archive_entry_symlink($entry);

Retrieve the symlink for the archive entry object.

=cut

#ifdef HAS_archive_entry_symlink

string_or_null
_archive_entry_symlink(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_symlink(entry);
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_set_uname

 my $status = archive_entry_set_uname($entry, $string)

Sets the uname for the archive entry object.

=cut

#ifdef HAS_archive_entry_copy_uname

int
archive_entry_set_uname(entry, uname)
    struct archive_entry *entry
    SV *uname
  CODE:
    if(SvOK(uname))
    {
#ifdef HAS_archive_entry_update_uname_utf8
      if(DO_UTF8(uname))
      {
        RETVAL = archive_entry_update_uname_utf8(entry, SvPV_nolen(uname));
        if(RETVAL > 0)
          RETVAL = ARCHIVE_OK;
      }
      else
      {
#endif
        archive_entry_copy_uname(entry, SvPV_nolen(uname));
        RETVAL = ARCHIVE_OK;
#ifdef HAS_archive_entry_update_uname_utf8
      }
    }
    else
    {
      archive_entry_copy_uname(entry, NULL);
      RETVAL = ARCHIVE_OK;
    }
#endif
  OUTPUT:
    RETVAL

#endif

=head2 archive_entry_uname

 my $string = archive_entry_uname($entry);

Retrieve the uname for the archive entry object.

=cut

#ifdef HAS_archive_entry_uname

string_or_null
_archive_entry_uname(entry)
    struct archive_entry *entry
  CODE:
    RETVAL = archive_entry_uname(entry);
  OUTPUT:
    RETVAL

#endif
