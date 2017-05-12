#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "perl_math_int64_types.h"
#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

#include <archive.h>
#include <archive_entry.h>

#if ARCHIVE_VERSION_NUMBER < 3000000
# if !defined(__LA_INT64_T)
#  if defined(_WIN32) && !defined(__CYGWIN__)
#   define __LA_INT64_T    __int64
#  else
#   if defined(_SCO_DS)
#    define __LA_INT64_T    long long
#   else
#    define __LA_INT64_T    int64_t
#   endif
#  endif
# endif
#endif

#define ARCHIVE_AR_UNDEF   0
#define ARCHIVE_AR_COMMON  1
#define ARCHIVE_AR_BSD     2
#define ARCHIVE_AR_GNU     3

#if ARCHIVE_VERSION_NUMBER < 3000000
#define archive_write_free(archive) archive_write_finish(archive)
#endif

#define _error(ar, message) {                                                   \
        if(ar->opt_warn)                                                        \
          warn("%s", message);                                                  \
        if(ar->error != NULL)                                                   \
          SvREFCNT_dec(ar->error);                                              \
        if(ar->longmess != NULL)                                                \
          SvREFCNT_dec(ar->longmess);                                           \
        ar->error = ar->longmess = SvREFCNT_inc(newSVpv(message,0));            \
      }

struct ar_entry;

struct ar {
  struct ar_entry *first;
  SV *callback;

  unsigned int opt_warn       : 2;
  unsigned int opt_chmod      : 1;
  unsigned int opt_same_perms : 1;
  unsigned int opt_chown      : 1;
  unsigned int opt_type       : 2;
 
  SV *error;
  SV *longmess;
  SV *opt_symbols;
};

struct ar_entry {
  struct archive_entry *entry;
  const char *data;
  size_t data_size;
  struct ar_entry *next;
  
  unsigned int is_symbol_table : 1;
};

static int ar_disk_options(struct ar *ar)
{
  int flags = ARCHIVE_EXTRACT_TIME;
  if(ar->opt_chown)
    flags |= ARCHIVE_EXTRACT_OWNER;
  if(ar->opt_same_perms)
    flags |= ARCHIVE_EXTRACT_PERM;
  return flags;
}

static void
ar_free_entry(struct ar_entry *entry)
{
  archive_entry_free(entry->entry);
  if(entry->data != NULL)
    Safefree(entry->data);
}

static void
ar_reset(struct ar *ar)
{
  struct ar_entry *entry, *old;

  if(ar->error != NULL)
    SvREFCNT_dec(ar->error);
  if(ar->longmess != NULL)
    SvREFCNT_dec(ar->longmess);

  ar->error    = NULL;
  ar->longmess = NULL;

  entry = ar->first;
  while(entry != NULL)
  {
    ar_free_entry(entry);
    old = entry;
    entry = entry->next;
    Safefree(old);
  }
  
  ar->first = NULL;
  
  ar->opt_type       = ARCHIVE_AR_UNDEF;
}

static struct ar_entry*
ar_find_by_name(struct ar *ar, const char *filename)
{
  struct ar_entry *entry;
  
  entry = ar->first;
  
  while(entry != NULL)
  {
    if(!strcmp(archive_entry_pathname(entry->entry), filename))
      return entry;
    entry = entry->next;
  }
  
  return NULL;
}

static int
ar_entry_extract(struct ar *ar, struct ar_entry *entry, struct archive *disk)
{
  int r;
  
  r = archive_write_header(disk, entry->entry);
  if(r != ARCHIVE_OK)
  {
    _error(ar,archive_error_string(disk));
  }
  else if(archive_entry_size(entry->entry) > 0)
  {
    r = archive_write_data_block(disk, entry->data, entry->data_size, 0);
    if(r != ARCHIVE_OK)
      _error(ar, archive_error_string(disk));
    if(r < ARCHIVE_WARN)
      return 0;
  }
      
  r = archive_write_finish_entry(disk);
  if(r != ARCHIVE_OK)
    _error(ar, archive_error_string(disk));

  if(r < ARCHIVE_WARN)
    return 0;
  else
    return 1;
}

static __LA_SSIZE_T
ar_read_callback(struct archive *archive, void *cd, const void **buffer)
{
  struct ar *ar = (struct ar *)cd;
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
  
  count = call_sv(ar->callback, G_ARRAY);
  
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
ar_write_callback(struct archive *archive, void *cd, const void *buffer, size_t length)
{
  struct ar *ar = (struct ar *)cd;
  int count;
  __LA_INT64_T status;

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(PTR2IV((void*)archive))));
  XPUSHs(sv_2mortal(newSVpvn(buffer, length)));
  PUTBACK;
  
  call_sv(ar->callback, G_SCALAR);
  
  SPAGAIN;
  
  status = SvI64(POPs);
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return status;
}

static int
ar_close_callback(struct archive *archive, void *client_data)
{
  return ARCHIVE_OK;
}

static __LA_INT64_T
ar_write_archive(struct archive *archive, struct ar *ar)
{
  int r;
  struct ar_entry *entry;
  int count;

  if(ar->opt_type == ARCHIVE_AR_GNU)
  {
    int size=0;
    
    /* calculate the size of the string table */
    for(entry = ar->first; entry != NULL; entry = entry->next)
    {
      if(entry->is_symbol_table)
        continue;
      int len = strlen(archive_entry_pathname(entry->entry));
      if(len > 15)
        size += len + 2;
    }
    
    /* if string table size is zero then we don't need  *
     * one.  Otherwise create the string table since    *
     * libarchive does not do that for us.              */
    if(size > 0)
    {
      struct archive_entry *table = archive_entry_new();
      archive_entry_set_pathname(table, "//");
      archive_entry_set_size(table, size);
      char buffer[size];
      int offset = 0;

      /* write the string table header */
      r = archive_write_header(archive, table);
      if(r < ARCHIVE_OK)
      {
        _error(ar, archive_error_string(archive));
        if(r != ARCHIVE_WARN)
        {
          archive_entry_free(table);
          return 0;
        }
      }

      /* construct the data section of the string table */    
      for(entry = ar->first; entry != NULL; entry = entry->next)
      {
        const char *name;
        int len;
        name = archive_entry_pathname(entry->entry);
        len = strlen(name);
        
        if(len > 15)
        {
          memcpy(&buffer[offset], name, len);
          memcpy(&buffer[offset+len], "/\n", 2);
          offset += len+2;
        }
      }
      
      /* write the string table to the archive */
      r = archive_write_data(archive, buffer, size);
      archive_entry_free(table);
      
      if(r < ARCHIVE_OK)
      {
        _error(ar, archive_error_string(archive));
        if(r != ARCHIVE_WARN)
          return 0;
      }
    }
  }

  /* write each entry out one at a time */
  for(entry = ar->first; entry != NULL; entry = entry->next)
  {
    struct archive_entry *short_entry = NULL;
    
    if(entry->is_symbol_table)
    {
      short_entry = archive_entry_clone(entry->entry);
      archive_entry_copy_pathname(short_entry, "/");
    }
    
    if(ar->opt_type == ARCHIVE_AR_COMMON)
    {
      const char *name = archive_entry_pathname(entry->entry);
      int len = strlen(name);
      if(len > 15)
      {
        char buffer[16];
        short_entry = archive_entry_clone(entry->entry);
        strncpy(buffer, name, 15);
        buffer[15] = '\0';
        archive_entry_copy_pathname(short_entry, buffer);
      }
    }
  
    r = archive_write_header(archive, short_entry != NULL ? short_entry : entry->entry);
    if(r < ARCHIVE_OK)
    {
      _error(ar,archive_error_string(archive));
      if(r != ARCHIVE_WARN)
        return 0;
    }
    r = archive_write_data(archive, entry->data, entry->data_size);
    if(r < ARCHIVE_OK)
    {
      _error(ar,archive_error_string(archive));
      if(r != ARCHIVE_WARN)
        return 0;
    }
    
    if(short_entry != NULL)
      archive_entry_free(short_entry);
  }

#if ARCHIVE_VERSION_NUMBER < 3000000
  return archive_position_uncompressed(archive);
#else
  return archive_filter_bytes(archive, 0);
#endif
}

static __LA_INT64_T
ar_read_archive(struct archive *archive, struct ar *ar)
{
  struct archive_entry *entry;
  struct ar_entry *e=NULL, *next;
  int r;
  size_t size;
  off_t  offset;
  const char *name;
  int is_symbol_table;

  ar->opt_type = ARCHIVE_AR_COMMON;

  while(1)
  {
#if HAS_has_archive_read_next_header2
    entry = archive_entry_new();
    r = archive_read_next_header2(archive, entry);
#else
    struct archive_entry *tmp;
    r = archive_read_next_header(archive, &tmp);
    entry = archive_entry_clone(tmp);
#endif
    is_symbol_table = 0;


    if(r == ARCHIVE_OK || r == ARCHIVE_WARN)
    {
      name = archive_entry_pathname(entry);
      /* Filename of // means it has a GNU style string *
       * table                                          */
      if(!strcmp(name, "//"))
      {
        ar->opt_type = ARCHIVE_AR_GNU;
        continue;
      }
      
      if(!strcmp(name, "/"))
      {
        if(ar->opt_symbols == NULL)
          continue;
        archive_entry_copy_pathname(entry, SvPV_nolen(ar->opt_symbols));
        is_symbol_table = 1;
      }

      /* Otherwise rely on libarchive to determine *
       * archive type                              */
      if(ar->opt_type == ARCHIVE_AR_COMMON)
      {
        switch(archive_format(archive))
        {
          case ARCHIVE_FORMAT_AR_BSD:
            ar->opt_type = ARCHIVE_AR_BSD;
            break;
        }
      }
      if(r == ARCHIVE_WARN)
      {
        _error(ar,archive_error_string(archive));
      }
    }
    else if(r == ARCHIVE_EOF)
    {
#if ARCHIVE_VERSION_NUMBER < 3000000
      return archive_position_uncompressed(archive);
#else
      return archive_filter_bytes(archive, 0);
#endif
    }
    else
    {
      archive_entry_free(entry);
      _error(ar,archive_error_string(archive));
      ar_reset(ar);
      return 0;
    }

    Newx(next, 1, struct ar_entry);
    next->data_size = archive_entry_size(entry);
    Newx(next->data, next->data_size, char);

    r = archive_read_data(archive, (void*)next->data, next->data_size);
    next->is_symbol_table = is_symbol_table;

    if(r == ARCHIVE_WARN)
    {
      _error(ar,archive_error_string(archive));
    }
    else if(r < ARCHIVE_OK && r != ARCHIVE_EOF)
    {
      archive_entry_free(entry);
      _error(ar,archive_error_string(archive));
      Safefree(next->data);
      Safefree(next);
      return 0;
    }
    
    next->entry         = entry;
    next->next          = NULL;
      
    if(ar->first == NULL)
      ar->first = next;
    else
      e->next = next;      
    e = next;
  }
}

MODULE = Archive::Ar::Libarchive   PACKAGE = Archive::Ar::Libarchive

BOOT:
     PERL_MATH_INT64_LOAD_OR_CROAK;

struct ar*
_new()
  CODE:
    struct ar *self;
    Newx(self, 1, struct ar);
    self->first          = NULL;
    self->callback       = NULL;
    self->error          = NULL;
    self->longmess       = NULL;
    self->opt_symbols    = NULL;
    self->opt_warn       = 0;
    self->opt_chmod      = 1;  /* ignored */
    self->opt_same_perms = 1;  /* different: pp version this is true for root only */
    self->opt_chown      = 1; 
    ar_reset(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

int
set_opt(self, name, value)
    struct ar *self
    const char *name
    SV *value
  CODE:
    if(!strcmp(name, "warn"))
      RETVAL = self->opt_warn = SvIV(value);
    else if(!strcmp(name, "chmod"))
      RETVAL = self->opt_chmod = SvIV(value);
    else if(!strcmp(name, "same_perms"))
      RETVAL = self->opt_same_perms = SvIV(value);
    else if(!strcmp(name, "chown"))
      RETVAL = self->opt_chown = SvIV(value);
    else if(!strcmp(name, "type"))
      RETVAL = self->opt_type = SvIV(value);
    else if(!strcmp(name, "symbols"))
      self->opt_symbols = SvREFCNT_inc(value);  /*  TODO: make set_opt return void; maybe */
    else
      warn("unknown or unsupported option %s", name);
  OUTPUT:
    RETVAL

int
get_opt(self, name)
    struct ar *self
    const char *name
  CODE:
    if(!strcmp(name, "warn"))
      RETVAL = self->opt_warn;
    else if(!strcmp(name, "chmod"))
      RETVAL = self->opt_chmod;
    else if(!strcmp(name, "same_perms"))
      RETVAL = self->opt_same_perms;
    else if(!strcmp(name, "chown"))
      RETVAL = self->opt_chown;
    else if(!strcmp(name, "type"))
    {
      if(self->opt_type == ARCHIVE_AR_UNDEF)
        XSRETURN_EMPTY;
      else
        RETVAL = self->opt_type;
    }
    else
      warn("unknown or unsupported option %s", name);
  OUTPUT:
    RETVAL

void
_set_error(self, message, longmess)
    struct ar *self
    SV *message
    SV *longmess
  CODE:
    if(self->error != NULL)
      SvREFCNT_dec(self->error);
    if(self->longmess != NULL)
      SvREFCNT_dec(self->longmess);
    self->error = SvREFCNT_inc(message);
    self->longmess = SvREFCNT_inc(longmess);

SV *
error(self, ...)
    struct ar *self
  CODE:
    if(self->error == NULL)
      XSRETURN_EMPTY;
    if(items >= 2 && SvTRUE(ST(1)))
      RETVAL = SvREFCNT_inc(self->longmess);
    else
      RETVAL = SvREFCNT_inc(self->error);
  OUTPUT:
    RETVAL

int
_read_from_filename(self, filename)
    struct ar *self
    const char *filename
  CODE:
    struct archive *archive;
    int r;
    
    ar_reset(self);
    archive = archive_read_new();
    archive_read_support_format_ar(archive);
    
    r = archive_read_open_filename(archive, filename, 1024);
    if(r == ARCHIVE_OK || r == ARCHIVE_WARN)
    {
      if(r == ARCHIVE_WARN)
        _error(self, archive_error_string(archive));
      RETVAL = ar_read_archive(archive, self);
    }
    else
    {
      _error(self,archive_error_string(archive));
      RETVAL = 0;
    }
#if ARCHIVE_VERSION_NUMBER < 3000000
    archive_read_finish(archive);
#else
    archive_read_free(archive);
#endif
  OUTPUT:
    RETVAL

int
_read_from_callback(self, callback)
    struct ar *self
    SV *callback
  CODE:
    struct archive *archive;
    int r;
    
    ar_reset(self);    
    archive = archive_read_new();
    archive_read_support_format_ar(archive);
    
    self->callback = SvREFCNT_inc(callback);
    r = archive_read_open(archive, (void*)self, NULL, ar_read_callback, ar_close_callback);

    if(r == ARCHIVE_OK || r == ARCHIVE_WARN)
    {
      if(r == ARCHIVE_WARN)
        _error(self,archive_error_string(archive));
      RETVAL = ar_read_archive(archive, self);
    }
    else
    {
      _error(self,archive_error_string(archive));
      RETVAL = 0;
    }    
#if ARCHIVE_VERSION_NUMBER < 3000000
    archive_read_finish(archive);
#else
    archive_read_free(archive);
#endif
    SvREFCNT_dec(callback);
    self->callback = NULL;
  OUTPUT:
    RETVAL

int
_write_to_filename(self, filename)
    struct ar *self
    const char *filename
  CODE:
    struct archive *archive;
    int r;
    
    archive = archive_write_new();
    if(self->opt_type == ARCHIVE_AR_BSD)
      r = archive_write_set_format_ar_bsd(archive);
    else
      r = archive_write_set_format_ar_svr4(archive);
    if(r != ARCHIVE_OK)
      _error(self,archive_error_string(archive));
    r = archive_write_open_filename(archive, filename);
    if(r != ARCHIVE_OK)
      _error(self,archive_error_string(archive));
    if(r == ARCHIVE_OK || r == ARCHIVE_WARN)
      RETVAL = ar_write_archive(archive, self);
    else
      RETVAL = 0;    
    archive_write_free(archive);
  OUTPUT:
    RETVAL

int
_write_to_callback(self, callback)
    struct ar *self
    SV *callback
  CODE:
    struct archive *archive;
    int r;
    
    self->callback = SvREFCNT_inc(callback);

    archive = archive_write_new();
    if(self->opt_type == ARCHIVE_AR_BSD)
      r = archive_write_set_format_ar_bsd(archive);
    else
      r = archive_write_set_format_ar_svr4(archive);
    if(r != ARCHIVE_OK)
      _error(self,archive_error_string(archive));
    archive_write_set_bytes_in_last_block(archive, 1);
    r = archive_write_open(archive, (void*)self, NULL, ar_write_callback, ar_close_callback);
    if(r != ARCHIVE_OK)
      _error(self,archive_error_string(archive));
    if(r == ARCHIVE_OK || r == ARCHIVE_WARN)
      RETVAL = ar_write_archive(archive, self);
    else
      RETVAL = 0;
    archive_write_free(archive);    
    SvREFCNT_dec(callback);
    self->callback = NULL;    
  OUTPUT:
    RETVAL

int
_remove(self,pathname)
    struct ar *self
    const char *pathname
  CODE:
    struct ar_entry **entry;
    entry = &(self->first);
    
    RETVAL = 0;
    
    while(1)
    {
      if(!strcmp(archive_entry_pathname((*entry)->entry),pathname))
      {
        ar_free_entry(*entry);
        *entry = (*entry)->next;
        RETVAL = 1;
        break;
      }
      
      if((*entry)->next == NULL)
        break;
      
      entry = &((*entry)->next);
    }
    
  OUTPUT:
    RETVAL

void
_add_data(self,filename,data,uid,gid,date,mode)
    struct ar *self
    const char *filename
    SV *data
    __LA_INT64_T uid
    __LA_INT64_T gid
    time_t date
    int mode
  CODE:
    struct ar_entry **entry;
    char *buffer;
    
    entry = &(self->first);
    
    while(*entry != NULL)
    {
      entry = &((*entry)->next);
    }
    
    Newx((*entry), 1, struct ar_entry);
    
    (*entry)->entry = archive_entry_new();
    archive_entry_set_pathname((*entry)->entry, filename);
    archive_entry_set_uid((*entry)->entry, uid);
    archive_entry_set_gid((*entry)->entry, gid);
    archive_entry_set_mtime((*entry)->entry, date, date);
    archive_entry_set_mode((*entry)->entry, mode);
    
    (*entry)->next          = NULL;
    (*entry)->is_symbol_table = 0;
    if(self->opt_symbols != NULL && !strcmp(SvPV_nolen(self->opt_symbols), filename))
      (*entry)->is_symbol_table = 1;
    
    buffer = SvPV(data, (*entry)->data_size);
    archive_entry_set_size((*entry)->entry, (*entry)->data_size);
    
    Newx((*entry)->data, (*entry)->data_size, char);
    Copy(buffer, (*entry)->data, (*entry)->data_size, char);
    

SV *
_list_files(self)
    struct ar *self
  CODE:
    AV *list;
    struct ar_entry *entry;
    const char *pathname;
    
    list = newAV();
        
    for(entry = self->first; entry != NULL; entry = entry->next)
    {
      pathname = archive_entry_pathname(entry->entry);
      av_push(list, newSVpv(pathname, strlen(pathname)));
    }
    
    RETVAL = newRV_noinc((SV*)list);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    struct ar *self
  CODE:
    ar_reset(self);
    Safefree(self);

SV *
get_content(self, filename)
    struct ar *self
    const char *filename
  CODE:
    struct ar_entry *entry;
    HV *hv;
    int found;
    
    entry = ar_find_by_name(self, filename);
    
    if(entry != NULL)
    {
      hv = newHV();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
      hv_store(hv, "name", 4, newSVpv(filename, strlen(filename)),         0);
      hv_store(hv, "date", 4, newSVi64(archive_entry_mtime(entry->entry)), 0);
      hv_store(hv, "uid",  3, newSVi64(archive_entry_uid(entry->entry)),   0);
      hv_store(hv, "gid",  3, newSVi64(archive_entry_gid(entry->entry)),   0);
      hv_store(hv, "mode", 4, newSViv(archive_entry_mode(entry->entry)),   0);
      hv_store(hv, "size", 4, newSViv(entry->data_size),                   0);
      hv_store(hv, "data", 4, newSVpv(entry->data, entry->data_size),      0);
#pragma clang diagnostic pop
      RETVAL = newRV_noinc((SV*)hv);
      
    }
    else
    {
      XSRETURN_EMPTY;
    }
  OUTPUT:
    RETVAL

SV *
get_data(self, filename)
    struct ar *self
    const char *filename
  CODE:
    struct ar_entry *entry;
    entry = ar_find_by_name(self, filename);
    if(entry == NULL)
      XSRETURN_EMPTY;
    RETVAL = newSVpv(entry->data, entry->data_size);
  OUTPUT:
    RETVAL


void
rename(self, old, new)
    struct ar *self
    const char *old
    const char *new
  CODE:
    struct ar_entry *entry;
    entry = ar_find_by_name(self, old);
    if(entry != NULL)
      archive_entry_set_pathname(entry->entry, new);

int
extract(self)
    struct ar *self
  CODE:
    struct ar_entry *entry;
    struct archive *disk;
    int ok = 1;
    
    entry = self->first;
    
    disk = archive_write_disk_new();
    archive_write_disk_set_options(disk, ar_disk_options(self));
    archive_write_disk_set_standard_lookup(disk);
    
    while(entry != NULL)
    {
      if(ar_entry_extract(self, entry, disk) == 0)
      {
        ok = 0;
        break;
      }
      entry = entry->next;
    }
    
    archive_write_close(disk);
    archive_write_free(disk);
    
    if(ok)
      RETVAL = 1;
    else
      XSRETURN_EMPTY;
  OUTPUT:
    RETVAL

int
extract_file(self,filename)
    struct ar *self
    const char *filename
  CODE:
    struct ar_entry *entry;
    struct archive *disk;
    int ok;

    entry = ar_find_by_name(self, filename);
    
    if(entry == NULL)
      XSRETURN_EMPTY;
    
    disk = archive_write_disk_new();
    archive_write_disk_set_options(disk, ar_disk_options(self));
    archive_write_disk_set_standard_lookup(disk);
    
    ok = ar_entry_extract(self, entry, disk);

    archive_write_close(disk);
    archive_write_free(disk);
    
    if(ok)
      RETVAL = 1;
    else
      XSRETURN_EMPTY;
    
  OUTPUT:
    RETVAL


int
type(self)
    struct ar *self
  CODE:
    RETVAL = self->opt_type;
  OUTPUT:
    RETVAL


int
contains_file(self, filename)
    struct ar *self
    const char *filename
  CODE:
    if(ar_find_by_name(self, filename))
      RETVAL = 1;
    else
      XSRETURN_EMPTY;
  OUTPUT:
    RETVAL


void
clear(self)
    struct ar *self
  CODE:
    ar_reset(self);


int
_chmod(self, filename, mode)
    struct ar *self
    const char *filename
    int mode
  CODE:
    struct ar_entry *entry;
    entry = ar_find_by_name(self, filename);
    if(entry != NULL)
    {
      archive_entry_set_mode(entry->entry, mode);
      RETVAL = 1;
    }
    else
    {
      XSRETURN_EMPTY;
    }
  OUTPUT:
    RETVAL


int
_chown(self, filename, uid, gid)
    struct ar *self
    const char *filename
    int uid
    SV *gid
  CODE:
    struct ar_entry *entry;
    entry = ar_find_by_name(self, filename);
    if(entry != NULL)
    {
      if(uid >= 0)
        archive_entry_set_uid(entry->entry, uid);
      if(SvOK(gid) && SvIV(gid) >= 0)
      {
        archive_entry_set_gid(entry->entry, SvIV(gid));
      }
    }
    else
    {
      XSRETURN_EMPTY;
    }

const char *
_libarchive_version()
  CODE:
    RETVAL = ARCHIVE_VERSION_STRING;
  OUTPUT:
    RETVAL
