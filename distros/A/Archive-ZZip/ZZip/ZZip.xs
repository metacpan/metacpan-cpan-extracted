#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <zzip/lib.h>
#ifdef __cplusplus
}
#endif

#define MAKE_STRING(buf, len)                                               \
    if (buf == &PL_sv_undef) {                                              \
      /*The buffer was undefined, allocate a new scalar value*/             \
      buf = NEWSV(0, len);                                                  \
      SvPOK_only(buf);                                                      \
    }                                                                       \
    else if (SvPOK(buf)) {                                                  \
      /*A string scalar was passed, grow the buffer if needed*/             \
      SvGROW(buf, len+1);                                                   \
    }                                                                       \
    else {                                                                  \
      /*A nonstring scalar was passed, make it a string scalar, and grow*/  \
      SvUPGRADE(buf, SVt_PV);                                               \
      SvPOK_only(buf);                                                      \
      SvGROW(buf, len+1);                                                   \
    }

#define HV_WITH_DIRENT(info, dirent)                                                \
    info = newHV();                                                               \
                                                                                  \
    /*Populate the hash. The 3rd parameter is the length of the key. */           \
    hv_store(info, "name", 4, newSVpv(dirent.d_name, strlen(dirent.d_name)), 0);  \
    hv_store(info, "compression_method", 19, newSViv(dirent.d_compr), 0);         \
    hv_store(info, "compressed_size", 15, newSViv(dirent.d_csize), 0);            \
    hv_store(info, "decompressed_size", 17, newSViv(dirent.st_size), 0);          

typedef ZZIP_DIR * Archive_ZZip;
typedef ZZIP_FILE * Archive_ZZip_File;

MODULE = Archive::ZZip     PACKAGE = Archive::ZZip

Archive_ZZip 
new(class, filename)
    SV *class
    char *filename
  INIT:
    zzip_error_t err;
  CODE:
    RETVAL = zzip_dir_open(filename, &err);
    if (err != 0) {
      SV* sv = perl_get_sv("!", TRUE);
      sv_setpvf(sv, zzip_strerror(err), filename);
    }
  OUTPUT:
    RETVAL

Archive_ZZip 
newWithFd(fd)
    int fd
  INIT:
    zzip_error_t err;
  CODE:
    RETVAL = zzip_dir_fdopen(fd, &err);
    if (err != 0) {
      SV* sv = perl_get_sv("!", TRUE);
      sv_setpv(sv, zzip_strerror(err));
    }
  OUTPUT:
    RETVAL

Archive_ZZip_File 
openFile(dir, name, mode = O_RDONLY)
    Archive_ZZip dir
    char *name
    int mode
  CODE:
    RETVAL = zzip_file_open(dir, name, mode);
    if (dir->errcode != 0) {
      SV* sv = perl_get_sv("!", TRUE);
      sv_setpvf(sv, zzip_strerror(dir->errcode), name);
    }
  OUTPUT:
    RETVAL


int
fd(dir)
    Archive_ZZip dir
  CODE:
    RETVAL = zzip_dirfd(dir);
  OUTPUT:
    RETVAL
   

void
rewind(dir)
    Archive_ZZip dir
  CODE:
    zzip_rewinddir(dir);
    
int
tell(dir)
    Archive_ZZip dir
  CODE:
    RETVAL = zzip_telldir(dir);
  OUTPUT:
    RETVAL

void
seek(dir, offset)
    Archive_ZZip dir
    int offset
  CODE:
    zzip_seekdir(dir, offset);


HV *
read(dir)
    Archive_ZZip dir
  INIT:
    int err;
    ZZIP_DIRENT dirent;
    HV *info;
  CODE:
    err = zzip_dir_read(dir, &dirent);
    if (err != 0) {
      HV_WITH_DIRENT(info, dirent);
    }
    else {
      XSRETURN_UNDEF;
    }
    
    RETVAL = info;
    
  OUTPUT:
    RETVAL

HV *
stat(dir, name, flags)
    Archive_ZZip dir
    char *name
    int flags
  INIT:
    int err;
    ZZIP_DIRENT dirent;
    HV *info;
  CODE:
    err = zzip_dir_stat(dir, name, &dirent, flags);
    if (err == 0) {
      HV_WITH_DIRENT(info, dirent);
    }
    else {
      XSRETURN_UNDEF;
    }
    
    RETVAL = info;
    
  OUTPUT:
    RETVAL


void
DESTROY(dir)
    Archive_ZZip dir
  CODE:
    zzip_dir_close(dir);
    

MODULE = Archive::ZZip     PACKAGE = Archive::ZZip::File



SV *
read(fp, buf=&PL_sv_undef, len=16384)
    Archive_ZZip_File fp
    SV *buf;
    int len
  INIT:
    int reallen;
  CODE:
    MAKE_STRING(buf, len);
    
    //Pass scalar's character buffer to zzip_file_read
    reallen = zzip_file_read(fp, SvPVX(buf), len);
    if (reallen == 0) {
      buf = &PL_sv_undef;
      XSRETURN_UNDEF;
    }
      
    //Set the length of the string as returned by zzlib
    SvCUR_set(buf, reallen);
    
    //Also return the buffer
    RETVAL = buf;

    //Now the buffer is referenced twice because of the retval.
    SvREFCNT_inc(buf);
  OUTPUT:
    RETVAL
    buf
  
   
int
rewind(fp)
    Archive_ZZip_File fp
  CODE:
    RETVAL = zzip_rewind(fp);
  OUTPUT:
    RETVAL
    
int
seek(fp, offset, whence)
    Archive_ZZip_File fp
    int offset
    int whence
  CODE:
    RETVAL = zzip_seek(fp, offset, whence);
  OUTPUT:
    RETVAL

int
tell(fp)
    Archive_ZZip_File fp
  CODE:
    RETVAL = zzip_tell(fp);
  OUTPUT:
    RETVAL

void
DESTROY(fd)
    Archive_ZZip_File fd
  CODE:
    zzip_file_close(fd);
  

