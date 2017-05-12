#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// If we are on MSVC, disable some stupid MSVC warnings
#ifdef _MSC_VER
# pragma warning( disable: 4996 )
# pragma warning( disable: 4127 )
# pragma warning( disable: 4711 )
#endif

// Headers for stat support
#ifdef _MSC_VER
# include <windows.h>
#else
# include <sys/stat.h>
#endif

#include "common.c"
#include "ape.c"
#include "id3.c"

#include "aac.c"
#include "asf.c"
#include "mac.c"
#include "mp3.c"
#include "mp4.c"
#include "mpc.c"
#include "ogg.c"
#include "wav.c"
#include "flac.c"
#include "wavpack.c"
#include "dsf.c"
#include "dsdiff.c"

#include "md5.c"
#include "jenkins_hash.c"

#define FILTER_TYPE_INFO 0x01
#define FILTER_TYPE_TAGS 0x02

#define MD5_BUFFER_SIZE 4096

#define MAX_PATH_STR_LEN 1024

struct _types {
  char *type;
  char *suffix[15];
};

typedef struct {
  char*	type;
  int (*get_tags)(PerlIO *infile, char *file, HV *info, HV *tags);
  int (*get_fileinfo)(PerlIO *infile, char *file, HV *tags);
  int (*find_frame)(PerlIO *infile, char *file, int offset);
  int (*find_frame_return_info)(PerlIO *infile, char *file, int offset, HV *info);
} taghandler;

struct _types audio_types[] = {
  {"mp4", {"mp4", "m4a", "m4b", "m4p", "m4v", "m4r", "k3g", "skm", "3gp", "3g2", "mov", 0}},
  {"aac", {"aac", "adts", 0}},
  {"mp3", {"mp3", "mp2", 0}},
  {"ogg", {"ogg", "oga", 0}},
  {"mpc", {"mpc", "mp+", "mpp", 0}},
  {"ape", {"ape", "apl", 0}},
  {"flc", {"flc", "flac", "fla", 0}},
  {"asf", {"wma", "asf", "wmv", 0}},
  {"wav", {"wav", "aif", "aiff", 0}},
  {"wvp", {"wv", 0}},
  {"dsf", {"dsf", 0}},
  {"dff", {"dff", 0}},
  {0, {0, 0}}
};

static taghandler taghandlers[] = {
  { "mp4", get_mp4tags, 0, mp4_find_frame, mp4_find_frame_return_info },
  { "aac", get_aacinfo, 0, 0, 0 },
  { "mp3", get_mp3tags, get_mp3fileinfo, mp3_find_frame, 0 },
  { "ogg", get_ogg_metadata, 0, ogg_find_frame, 0 },
  { "mpc", get_ape_metadata, get_mpcfileinfo, 0, 0 },
  { "ape", get_ape_metadata, get_macfileinfo, 0, 0 },
  { "flc", get_flac_metadata, 0, flac_find_frame, 0 },
  { "asf", get_asf_metadata, 0, asf_find_frame, 0 },
  { "wav", get_wav_metadata, 0, 0, 0 },
  { "wvp", get_ape_metadata, get_wavpack_info, 0 },
  { "dsf", get_dsf_metadata, 0, 0, 0 },
  { "dff", get_dsdiff_metadata, 0, 0, 0 },
  { NULL, 0, 0, 0 }
};

static taghandler *
_get_taghandler(char *suffix)
{
  int typeindex = -1;
  int i, j;
  taghandler *hdl = NULL;
  
  for (i=0; typeindex==-1 && audio_types[i].type; i++) {
    for (j=0; typeindex==-1 && audio_types[i].suffix[j]; j++) {
#ifdef _MSC_VER
      if (!stricmp(audio_types[i].suffix[j], suffix)) {
#else
      if (!strcasecmp(audio_types[i].suffix[j], suffix)) {
#endif
        typeindex = i;
        break;
      }
    }
  }
    
  if (typeindex > -1) {
    for (hdl = taghandlers; hdl->type; ++hdl)
      if (!strcmp(hdl->type, audio_types[typeindex].type))
        break;
  }
  
  return hdl;
}

static void
_generate_md5(PerlIO *infile, const char *file, int size, int start_offset, HV *info)
{
  md5_state_t md5;
  md5_byte_t digest[16];
  char hexdigest[33];
  Buffer buf;
  int audio_offset, audio_size, di;
  
  buffer_init(&buf, MD5_BUFFER_SIZE);
  md5_init(&md5);
  
  audio_offset = SvIV(*(my_hv_fetch(info, "audio_offset")));
  audio_size = SvIV(*(my_hv_fetch(info, "audio_size")));
  
  if (!start_offset) {
    // Read bytes from middle of file to reduce chance of silence generating false matches
    start_offset = audio_offset;
    start_offset += (audio_size / 2) - (size / 2);
    if (start_offset < audio_offset)
      start_offset = audio_offset;
  }
  
  if (size >= audio_size) {
    size = audio_size;
  }
  
  DEBUG_TRACE("Using %d bytes for audio MD5, starting at %d\n", size, start_offset);
  
  if (PerlIO_seek(infile, start_offset, SEEK_SET) < 0) {
    warn("Audio::Scan unable to determine MD5 for %s\n", file);
    goto out;
  }
  
  while (size > 0) {
    if ( !_check_buf(infile, &buf, 1, MIN(size, MD5_BUFFER_SIZE)) ) {
      warn("Audio::Scan unable to determine MD5 for %s\n", file);
      goto out;
    }
    
    md5_append(&md5, buffer_ptr(&buf), buffer_len(&buf));
    
    size -= buffer_len(&buf);
    buffer_consume(&buf, buffer_len(&buf));
    DEBUG_TRACE("%d bytes left\n", size);
  }
  
  md5_finish(&md5, digest);
  
  for (di = 0; di < 16; ++di)
    sprintf(hexdigest + di * 2, "%02x", digest[di]);
  
  my_hv_store(info, "audio_md5", newSVpvn(hexdigest, 32));
  
out:
  buffer_free(&buf);
}

static uint32_t
_generate_hash(const char *file)
{
  char hashstr[MAX_PATH_STR_LEN];
  int mtime = 0;
  uint64_t size = 0;
  uint32_t hash;

#ifdef _MSC_VER
  BOOL fOk;
  WIN32_FILE_ATTRIBUTE_DATA fileInfo;

  fOk = GetFileAttributesEx(file, GetFileExInfoStandard, (void *)&fileInfo);
  mtime = fileInfo.ftLastWriteTime.dwLowDateTime;
  size = (uint64_t)fileInfo.nFileSizeLow;
#else
  struct stat buf;

  if (stat(file, &buf) != -1) {
    mtime = (int)buf.st_mtime;
    size = (uint64_t)buf.st_size;
  }
#endif

  memset(hashstr, 0, sizeof(hashstr));
  snprintf(hashstr, sizeof(hashstr) - 1, "%s%d%llu", file, mtime, size);
  hash = hashlittle(hashstr, strlen(hashstr), 0);
  
  return hash;
}

MODULE = Audio::Scan		PACKAGE = Audio::Scan

HV *
_scan( char *, char *suffix, PerlIO *infile, SV *path, int filter, int md5_size, int md5_offset )
CODE:
{
  taghandler *hdl;
  RETVAL = newHV();
  
  // don't leak
  sv_2mortal( (SV*)RETVAL );
  
  hdl = _get_taghandler(suffix);
  
  if (hdl) {
    HV *info = newHV();

    // Ignore filter if a file type has only one function (FLAC/Ogg)
    if ( !hdl->get_fileinfo ) {
      filter = FILTER_TYPE_INFO | FILTER_TYPE_TAGS;
    }

    if ( hdl->get_fileinfo && (filter & FILTER_TYPE_INFO) ) {
      hdl->get_fileinfo(infile, SvPVX(path), info);
    }

    if ( hdl->get_tags && (filter & FILTER_TYPE_TAGS) ) {
      HV *tags = newHV();
      hdl->get_tags(infile, SvPVX(path), info, tags);
      hv_store( RETVAL, "tags", 4, newRV_noinc( (SV *)tags ), 0 );
    }
    
    // Generate audio MD5 value
    if ( md5_size > 0
      && my_hv_exists(info, "audio_offset")
      && my_hv_exists(info, "audio_size")
      && !my_hv_exists(info, "audio_md5")
    ) {
      _generate_md5(infile, SvPVX(path), md5_size, md5_offset, info);
    }
    
    // Generate hash value
    my_hv_store(info, "jenkins_hash", newSVuv( _generate_hash(SvPVX(path)) ));

    // Info may be used in tag function, i.e. to find tag version
    hv_store( RETVAL, "info", 4, newRV_noinc( (SV *)info ), 0 );
  }
  else {
    croak("Audio::Scan unsupported file type: %s (%s)", suffix, SvPVX(path));
  }
}
OUTPUT:
  RETVAL
  
int
_find_frame( char *, char *suffix, PerlIO *infile, SV *path, int offset )
CODE:
{
  taghandler *hdl;
  
  RETVAL = -1;
  hdl = _get_taghandler(suffix);
  
  if (hdl && hdl->find_frame) {
    RETVAL = hdl->find_frame(infile, SvPVX(path), offset);
  }
}
OUTPUT:
  RETVAL

HV *
_find_frame_return_info( char *, char *suffix, PerlIO *infile, SV *path, int offset )
CODE:
{
  taghandler *hdl = _get_taghandler(suffix);
  RETVAL = newHV();
  sv_2mortal((SV*)RETVAL);
  
  if (hdl && hdl->find_frame_return_info) {
    hdl->find_frame_return_info(infile, SvPVX(path), offset, RETVAL);
  }
}
OUTPUT:
  RETVAL

int
has_flac(void)
CODE:
{
  RETVAL = 1;
}
OUTPUT:
  RETVAL

int
is_supported(char *, SV *path)
CODE:
{
  char *suffix = strrchr( SvPVX(path), '.' );

  if (suffix != NULL && *suffix == '.' && _get_taghandler(suffix + 1)) {
    RETVAL = 1;
  }
  else {
    RETVAL = 0;
  }
}
OUTPUT:
  RETVAL

SV *
type_for(char *, SV *suffix)
CODE:
{
  taghandler *hdl = NULL;
  char *suff = SvPVX(suffix);

  if (suff == NULL || *suff == '\0') {
    RETVAL = newSV(0);
  }
  else {
    hdl = _get_taghandler(suff);
    if (hdl == NULL) {
      RETVAL = newSV(0);
    }
    else {
      RETVAL = newSVpv(hdl->type, 0);
    }
  }
}
OUTPUT:
  RETVAL

AV *
get_types(void)
CODE:
{
  int i;

  RETVAL = newAV();
  sv_2mortal((SV*)RETVAL);
  for (i = 0; audio_types[i].type; i++) {
    av_push(RETVAL, newSVpv(audio_types[i].type, 0));
  }
}
OUTPUT:
  RETVAL

AV *
extensions_for(char *, SV *type)
CODE:
{
  int i, j;
  char *t = SvPVX(type);

  RETVAL = newAV();
  sv_2mortal((SV*)RETVAL);
  for (i = 0; audio_types[i].type; i++) {
#ifdef _MSC_VER
    if (!stricmp(audio_types[i].type, t)) {
#else
    if (!strcasecmp(audio_types[i].type, t)) {
#endif

      for (j = 0; audio_types[i].suffix[j]; j++) {
        av_push(RETVAL, newSVpv(audio_types[i].suffix[j], 0));
      }
      break;

    }
  }
}
OUTPUT:
  RETVAL
