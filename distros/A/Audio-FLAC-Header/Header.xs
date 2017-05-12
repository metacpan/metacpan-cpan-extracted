/* $Id: Header.xs 360 2005-11-26 08:02:13Z dsully $ */

/* This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * Chunks of this code have been borrowed and influenced from the FLAC source.
 *
 */

#ifdef __cplusplus
"C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <FLAC/all.h>

/* for PRIu64 */
#include <inttypes.h>

#define FLACHEADERFLAG "fLaC"
#define ID3HEADERFLAG  "ID3"

#ifdef _MSC_VER
# define stat _stat
#endif

/* strlen the length automatically */
#define my_hv_store(a,b,c)   (void)hv_store(a,b,strlen(b),c,0)
#define my_hv_store_ent(a,b,c) (void)hv_store_ent(a,b,c,0)
#define my_hv_fetch(a,b)     hv_fetch(a,b,strlen(b),0)

void _cuesheet_frame_to_msf(unsigned frame, unsigned *minutes, unsigned *seconds, unsigned *frames) {

  *frames = frame % 75;
  frame /= 75;
  *seconds = frame % 60;
  frame /= 60;
  *minutes = frame;
}

void _read_metadata(HV *self, char *path, FLAC__StreamMetadata *block, unsigned block_number) {

  unsigned i;
  int storePicture = 0;

  HV *pictureContainer = newHV();
  AV *allpicturesContainer = NULL;

  switch (block->type) {

    case FLAC__METADATA_TYPE_STREAMINFO:
    {
      HV *info = newHV();
      float totalSeconds;

      my_hv_store(info, "MINIMUMBLOCKSIZE", newSVuv(block->data.stream_info.min_blocksize));
      my_hv_store(info, "MAXIMUMBLOCKSIZE", newSVuv(block->data.stream_info.max_blocksize));

      my_hv_store(info, "MINIMUMFRAMESIZE", newSVuv(block->data.stream_info.min_framesize));
      my_hv_store(info, "MAXIMUMFRAMESIZE", newSVuv(block->data.stream_info.max_framesize));

      my_hv_store(info, "SAMPLERATE", newSVuv(block->data.stream_info.sample_rate));
      my_hv_store(info, "NUMCHANNELS", newSVuv(block->data.stream_info.channels));
      my_hv_store(info, "BITSPERSAMPLE", newSVuv(block->data.stream_info.bits_per_sample));
      my_hv_store(info, "TOTALSAMPLES", newSVnv(block->data.stream_info.total_samples));

      if (block->data.stream_info.md5sum != NULL) {

        /* Initialize an SV with the first element,
           and then append to it. If we don't do it this way, we get a "use of
           uninitialized element" in subroutine warning. */
        SV *md5 = newSVpvf("%02x", (unsigned)block->data.stream_info.md5sum[0]);

        for (i = 1; i < 16; i++) {
          sv_catpvf(md5, "%02x", (unsigned)block->data.stream_info.md5sum[i]);
        }

        my_hv_store(info, "MD5CHECKSUM", md5);
      }

      my_hv_store(self, "info", newRV_noinc((SV*) info));

      /* Store some other metadata for backwards compatability with the original Audio::FLAC */
      /* needs to be higher resolution */
      totalSeconds = block->data.stream_info.total_samples / (float)block->data.stream_info.sample_rate;

      if (totalSeconds <= 0) {
        warn("File: %s - %s\n%s\n",
          path,
          "totalSeconds is 0 - we couldn't find either TOTALSAMPLES or SAMPLERATE!",
          "setting totalSeconds to 1 to avoid divide by zero error!"
        );

        totalSeconds = 1;
      }

      my_hv_store(self, "trackTotalLengthSeconds", newSVnv(totalSeconds));

      my_hv_store(self, "trackLengthMinutes", newSVnv((int)totalSeconds / 60));
      my_hv_store(self, "trackLengthSeconds", newSVnv((int)totalSeconds % 60));
      my_hv_store(self, "trackLengthFrames", newSVnv((totalSeconds - (int)totalSeconds) * 75));

      break;
    }

    case FLAC__METADATA_TYPE_PADDING:
    case FLAC__METADATA_TYPE_SEEKTABLE:
      /* Don't handle these yet. */
      break;

    case FLAC__METADATA_TYPE_APPLICATION:
    {
      if (block->data.application.id[0]) {

        HV *app   = newHV();
        SV *tmpId = newSVpvf("%02x", (unsigned)block->data.application.id[0]);
        SV *appId;

        for (i = 1; i < 4; i++) {
          sv_catpvf(tmpId, "%02x", (unsigned)block->data.application.id[i]);
        }

        /* Be compatible with the pure perl version */
        appId = newSVpvf("%ld", strtol(SvPV_nolen(tmpId), NULL, 16));

        if (block->data.application.data != 0) {
          my_hv_store_ent(app, appId, newSVpvn((char*)block->data.application.data, block->length));
        }

        my_hv_store(self, "application",  newRV_noinc((SV*) app));

        SvREFCNT_dec(tmpId);
        SvREFCNT_dec(appId);
      }

      break;
    }

    case FLAC__METADATA_TYPE_VORBIS_COMMENT:
    {
      AV *rawTagArray = newAV();
      HV *tags = newHV();
      SV **tag = NULL;
      SV **separator = NULL;

      if (block->data.vorbis_comment.vendor_string.entry) {
        my_hv_store(tags, "VENDOR", newSVpv((char*)block->data.vorbis_comment.vendor_string.entry, 0));
      }

      for (i = 0; i < block->data.vorbis_comment.num_comments; i++) {

        if (!block->data.vorbis_comment.comments[i].entry || !block->data.vorbis_comment.comments[i].length) {
          warn("Empty comment, skipping...\n");
          continue;
        }

        /* store the pointer location of the '=', poor man's split() */
        char *entry = (char*)block->data.vorbis_comment.comments[i].entry;
        char *half  = strchr(entry, '=');

        /* store the raw tags */
        av_push(rawTagArray, newSVpv(entry, 0));

        if (half == NULL) {
          warn("Comment \"%s\" missing \'=\', skipping...\n", entry);
          continue;
        }

        if (hv_exists(tags, entry, half - entry)) {
          /* fetch the existing entry */
          tag = hv_fetch(tags, entry, half - entry, 0);

          /* fetch the multi-value separator or default and append to the entry */
          if (hv_exists(self, "separator", 9)) {
            separator = hv_fetch(self, "separator", 9, 0);
            sv_catsv(*tag, *separator);
          } else {
            sv_catpv(*tag, "/");
          }

          /* concatenate with the new entry */
          sv_catpv(*tag, half + 1);
        } else {
          (void)hv_store(tags, entry, half - entry, newSVpv(half + 1, 0), 0);
        }
      }

      my_hv_store(self, "tags", newRV_noinc((SV*) tags));
      my_hv_store(self, "rawTags", newRV_noinc((SV*) rawTagArray));

      break;
    }

    case FLAC__METADATA_TYPE_CUESHEET:
    {
      AV *cueArray = newAV();

      /*
       * buffer for decimal representations of uint64_t values
       *
       * newSVpvf() and sv_catpvf() can't handle 64-bit values
       * in some cases, so we need to do the conversion "manually"
       * with sprintf() and the PRIu64 format macro for portability
       *
       * see http://bugs.debian.org/462249
       *
       * maximum string length: ceil(log10(2**64)) == 20 (+trailing \0)
       */
      char decimal[21];

      /* A lot of this comes from flac/src/share/grabbag/cuesheet.c */
      const FLAC__StreamMetadata_CueSheet *cs;
      unsigned track_num, index_num;

      cs = &block->data.cue_sheet;

      if (*(cs->media_catalog_number)) {
        av_push(cueArray, newSVpvf("CATALOG %s\n", cs->media_catalog_number));
      }

      av_push(cueArray, newSVpvf("FILE \"%s\" FLAC\n", path));

      for (track_num = 0; track_num < cs->num_tracks-1; track_num++) {

        const FLAC__StreamMetadata_CueSheet_Track *track = cs->tracks + track_num;

        av_push(cueArray, newSVpvf("  TRACK %02u %s\n",
          (unsigned)track->number, track->type == 0? "AUDIO" : "DATA"
        ));

        if (track->pre_emphasis) {
          av_push(cueArray, newSVpv("    FLAGS PRE\n", 0));
        }

        if (*(track->isrc)) {
          av_push(cueArray, newSVpvf("    ISRC %s\n", track->isrc));
        }

        for (index_num = 0; index_num < track->num_indices; index_num++) {

          const FLAC__StreamMetadata_CueSheet_Index *index = track->indices + index_num;

          SV *indexSV = newSVpvf("    INDEX %02u ", (unsigned)index->number);

          if (cs->is_cd) {

            unsigned logical_frame = (unsigned)((track->offset + index->offset) / (44100 / 75));
            unsigned m, s, f;

            _cuesheet_frame_to_msf(logical_frame, &m, &s, &f);

            sv_catpvf(indexSV, "%02u:%02u:%02u\n", m, s, f);

          } else {
            sprintf(decimal, "%"PRIu64, track->offset + index->offset);
            sv_catpvf(indexSV, "%s\n", decimal);
          }


          av_push(cueArray, indexSV);
        }
      }

      sprintf(decimal, "%"PRIu64, cs->lead_in);
      av_push(cueArray, newSVpvf("REM FLAC__lead-in %s\n", decimal));
      sprintf(decimal, "%"PRIu64, cs->tracks[track_num].offset);
      av_push(cueArray, newSVpvf("REM FLAC__lead-out %u %s\n",
        (unsigned)cs->tracks[track_num].number, decimal)
      );

      my_hv_store(self, "cuesheet",  newRV_noinc((SV*) cueArray));

      break;
    }

/* The PICTURE metadata block came about in FLAC 1.1.3 */
#ifdef FLAC_API_VERSION_CURRENT
    case FLAC__METADATA_TYPE_PICTURE:
    {
      HV *picture = newHV();
      SV *type;

      my_hv_store(picture, "mimeType", newSVpv(block->data.picture.mime_type, 0));
      my_hv_store(picture, "description", newSVpv((const char*)block->data.picture.description, 0));
      my_hv_store(picture, "width", newSViv(block->data.picture.width));
      my_hv_store(picture, "height", newSViv(block->data.picture.height));
      my_hv_store(picture, "depth", newSViv(block->data.picture.depth));
      my_hv_store(picture, "colorIndex", newSViv(block->data.picture.colors));
      my_hv_store(picture, "imageData", newSVpv((const char*)block->data.picture.data, block->data.picture.data_length));
      my_hv_store(picture, "pictureType", newSViv(block->data.picture.type));

      type = newSViv(block->data.picture.type);

      my_hv_store_ent(pictureContainer, type, newRV_noinc((SV*) picture));

      SvREFCNT_dec(type);

      storePicture = 1;

      /* update allpictures */
      if (hv_exists(self, "allpictures", 11)) {
        allpicturesContainer = (AV *) SvRV(*my_hv_fetch(self, "allpictures"));
      } else {
        allpicturesContainer = newAV();

        /* store the 'allpictures' array */
        my_hv_store(self, "allpictures", newRV_noinc((SV*) allpicturesContainer));
      }

      av_push(allpicturesContainer, (SV*) newRV((SV*) picture));

      break;
    }
#endif

    /* XXX- Just ignore for now */
    default:
      break;
  }

  /* store the 'picture' hash */
  if (storePicture && hv_scalar(pictureContainer)) {
    my_hv_store(self, "picture", newRV_noinc((SV*) pictureContainer));
  } else {
    SvREFCNT_dec((SV*) pictureContainer);
  }
}

/* From src/metaflac/operations.c */
void print_error_with_chain_status(FLAC__Metadata_Chain *chain, const char *format, ...) {

  const FLAC__Metadata_ChainStatus status = FLAC__metadata_chain_status(chain);
  va_list args;

  FLAC__ASSERT(0 != format);

  va_start(args, format);
  (void) vfprintf(stderr, format, args);
  va_end(args);

  warn("status = \"%s\"\n", FLAC__Metadata_ChainStatusString[status]);

  if (status == FLAC__METADATA_CHAIN_STATUS_ERROR_OPENING_FILE) {

    warn("The FLAC file could not be opened. Most likely the file does not exist or is not readable.");

  } else if (status == FLAC__METADATA_CHAIN_STATUS_NOT_A_FLAC_FILE) {

    warn("The file does not appear to be a FLAC file.");

  } else if (status == FLAC__METADATA_CHAIN_STATUS_NOT_WRITABLE) {

    warn("The FLAC file does not have write permissions.");

  } else if (status == FLAC__METADATA_CHAIN_STATUS_BAD_METADATA) {

    warn("The metadata to be writted does not conform to the FLAC metadata specifications.");

  } else if (status == FLAC__METADATA_CHAIN_STATUS_READ_ERROR) {

    warn("There was an error while reading the FLAC file.");

  } else if (status == FLAC__METADATA_CHAIN_STATUS_WRITE_ERROR) {

    warn("There was an error while writing FLAC file; most probably the disk is full.");

  } else if (status == FLAC__METADATA_CHAIN_STATUS_UNLINK_ERROR) {

    warn("There was an error removing the temporary FLAC file.");
  }
}

MODULE = Audio::FLAC::Header PACKAGE = Audio::FLAC::Header

PROTOTYPES: DISABLE

SV*
_new_XS(class, path)
  char *class;
  char *path;

  CODE:

  HV *self = newHV();
  SV *obj_ref = newRV_noinc((SV*) self);

  /* Start to walk the metadata list */
  FLAC__Metadata_Chain *chain = FLAC__metadata_chain_new();

  if (chain == 0) {
    die("Out of memory allocating chain");
    XSRETURN_UNDEF;
  }

  if (!FLAC__metadata_chain_read(chain, path)) {
    print_error_with_chain_status(chain, "%s: ERROR: reading metadata", path);
    XSRETURN_UNDEF;
  }

  {
    FLAC__Metadata_Iterator *iterator = FLAC__metadata_iterator_new();
    FLAC__StreamMetadata *block = 0;
    FLAC__bool ok = true;
    unsigned block_number = 0;

    if (iterator == 0) {
      die("out of memory allocating iterator");
    }

    FLAC__metadata_iterator_init(iterator, chain);

    do {
             block = FLAC__metadata_iterator_get_block(iterator);
      ok &= (0 != block);

      if (!ok) {

        warn("%s: ERROR: couldn't get block from chain", path);

      } else {

        _read_metadata(self, path, block, block_number);
      }

      block_number++;

    } while (ok && FLAC__metadata_iterator_next(iterator));

    FLAC__metadata_iterator_delete(iterator);
  }

  FLAC__metadata_chain_delete(chain);

  /* Make sure tags is an empty HV if there were no VCs in the file */
  if (!hv_exists(self, "tags", 4)) {
    my_hv_store(self, "tags", newRV_noinc((SV*) newHV()));
  }

  /* Find the offset of the start pos for audio blocks (ie: after metadata) */
  {
    unsigned int  is_last = 0;
    unsigned char buf[4];
    long len;
    struct stat st;
    float totalSeconds;
    PerlIO *fh;

    if ((fh = PerlIO_open(path, "r")) == NULL) {
      warn("Couldn't open file [%s] for reading!\n", path);
      XSRETURN_UNDEF;
    }

    if (PerlIO_read(fh, &buf, 4) == -1) {
      warn("Couldn't read magic fLaC header!\n");
      PerlIO_close(fh);
      XSRETURN_UNDEF;
    }

    if (memcmp(buf, ID3HEADERFLAG, 3) == 0) {

      unsigned id3size = 0;
      int c = 0;

      /* How big is the ID3 header? Skip the next two bytes */
      if (PerlIO_read(fh, &buf, 2) == -1) {
        warn("Couldn't read ID3 header length!\n");
        PerlIO_close(fh);
        XSRETURN_UNDEF;
      }

      /* The size of the ID3 tag is a 'synchsafe' 4-byte uint */
      for (c = 0; c < 4; c++) {

        if (PerlIO_read(fh, &buf, 1) == -1 || buf[0] & 0x80) {
          warn("Couldn't read ID3 header length (syncsafe)!\n");
          PerlIO_close(fh);
          XSRETURN_UNDEF;
        }

        id3size <<= 7;
        id3size |= (buf[0] & 0x7f);
      }

      if (PerlIO_seek(fh, id3size, SEEK_CUR) < 0) {
        warn("Couldn't seek past ID3 header!\n");
        PerlIO_close(fh);
        XSRETURN_UNDEF;
      }

      if (PerlIO_read(fh, &buf, 4) == -1) {
        warn("Couldn't read magic fLaC header!\n");
        PerlIO_close(fh);
        XSRETURN_UNDEF;
      }
    }

    if (memcmp(buf, FLACHEADERFLAG, 4)) {
      warn("Couldn't read magic fLaC header - got gibberish instead!\n");
      PerlIO_close(fh);
      XSRETURN_UNDEF;
    }

    while (!is_last) {

      if (PerlIO_read(fh, &buf, 4) != 4) {
        warn("Couldn't read 4 bytes of the metadata block!\n");
        PerlIO_close(fh);
        XSRETURN_UNDEF;
      }

      is_last = (unsigned int)(buf[0] & 0x80);

      len = (long)((buf[1] << 16) | (buf[2] << 8) | (buf[3]));

      PerlIO_seek(fh, len, SEEK_CUR);
    }

    len = PerlIO_tell(fh);
    PerlIO_close(fh);

    my_hv_store(self, "startAudioData", newSVnv(len));

    /* Now calculate the bit rate and file size */
    totalSeconds = (float)SvIV(*(my_hv_fetch(self, "trackTotalLengthSeconds")));

    /* Find the file size */
    if (stat(path, &st) == 0) {
      my_hv_store(self, "fileSize", newSViv(st.st_size));
    } else {
      warn("Couldn't stat file: [%s], might be more problems ahead!", path);
    }

    my_hv_store(self, "bitRate", newSVnv(8.0 * (st.st_size - len) / totalSeconds));
  }

  my_hv_store(self, "filename", newSVpv(path, 0));

  /* Bless the hashref to create a class object */
  sv_bless(obj_ref, gv_stashpv(class, FALSE));

  RETVAL = obj_ref;

  OUTPUT:
  RETVAL

SV*
_write_XS(obj)
  SV* obj

  CODE:

  FLAC__bool ok = true;

  HE *he;
  HV *self = (HV *) SvRV(obj);
  HV *tags = (HV *) SvRV(*(my_hv_fetch(self, "tags")));

  char *path = (char *) SvPV_nolen(*(my_hv_fetch(self, "filename")));

  FLAC__Metadata_Chain *chain = FLAC__metadata_chain_new();

  if (chain == 0) {
    die("Out of memory allocating chain");
    XSRETURN_UNDEF;
  }

  if (!FLAC__metadata_chain_read(chain, path)) {
    print_error_with_chain_status(chain, "%s: ERROR: reading metadata", path);
    XSRETURN_UNDEF;
  }

  FLAC__Metadata_Iterator *iterator = FLAC__metadata_iterator_new();
  FLAC__StreamMetadata *block = 0;
  FLAC__bool found_vc_block = false;

  if (iterator == 0) {
    die("out of memory allocating iterator");
  }

  FLAC__metadata_iterator_init(iterator, chain);

  do {
    block = FLAC__metadata_iterator_get_block(iterator);

    if (block->type == FLAC__METADATA_TYPE_VORBIS_COMMENT) {
      found_vc_block = true;
    }

  } while (!found_vc_block && FLAC__metadata_iterator_next(iterator));

  if (found_vc_block) {

    /* Empty out the existing block */
    if (0 != block->data.vorbis_comment.comments) {

      FLAC__ASSERT(block->data.vorbis_comment.num_comments > 0);

      if (!FLAC__metadata_object_vorbiscomment_resize_comments(block, 0)) {

        die("%s: ERROR: memory allocation failure\n", path);
      }

    } else {

      FLAC__ASSERT(block->data.vorbis_comment.num_comments == 0);
    }

  } else {

    /* create a new block if necessary */
    block = FLAC__metadata_object_new(FLAC__METADATA_TYPE_VORBIS_COMMENT);

    if (0 == block) {
      die("out of memory allocating VORBIS_COMMENT block");
    }

    while (FLAC__metadata_iterator_next(iterator));

    if (!FLAC__metadata_iterator_insert_block_after(iterator, block)) {

      print_error_with_chain_status(chain, "%s: ERROR: adding new VORBIS_COMMENT block to metadata", path);
      XSRETURN_UNDEF;
    }

    /* iterator is left pointing to new block */
    FLAC__ASSERT(FLAC__metadata_iterator_get_block(iterator) == block);
  }

  FLAC__StreamMetadata_VorbisComment_Entry entry = { 0 };
  FLAC__metadata_object_vorbiscomment_append_comment(block, entry, /*copy=*/true);

  if (hv_iterinit(tags)) {

    while ((he = hv_iternext(tags))) {

      FLAC__StreamMetadata_VorbisComment_Entry entry;

      char *key = HePV(he, PL_na);
      char *val = SvPV_nolen(HeVAL(he));
      char *ent = form("%s=%s", key, val);

      if (ent == NULL) {
        warn("Couldn't create key/value pair!\n");
        XSRETURN_UNDEF;
      }

      if (strEQ(key, "VENDOR")) {
        entry.entry = (FLAC__byte *)val;
      } else {
        entry.entry = (FLAC__byte *)ent;
      }

      entry.length = strlen((const char *)entry.entry);

      if (strEQ(key, "VENDOR")) {

        if (!FLAC__metadata_object_vorbiscomment_set_vendor_string(block, entry, /*copy=*/true)) {
          warn("%s: ERROR: memory allocation failure\n", path);
          XSRETURN_UNDEF;
        }

      } else {

        if (!FLAC__format_vorbiscomment_entry_is_legal(entry.entry, entry.length)) {

          warn("%s: ERROR: tag value for '%s' is not valid UTF-8\n", path, ent);
          XSRETURN_UNDEF;
        }

        if (!FLAC__metadata_object_vorbiscomment_append_comment(block, entry, /*copy=*/true)) {

          warn("%s: ERROR: memory allocation failure\n", path);
          XSRETURN_UNDEF;
        }
      }
    }
  }

  FLAC__metadata_iterator_delete(iterator);
  FLAC__metadata_chain_sort_padding(chain);

  ok = FLAC__metadata_chain_write(chain, /* padding */true, /*modtime*/ false);

  if (!ok) {
    print_error_with_chain_status(chain, "%s: ERROR: writing FLAC file", path);
    RETVAL = &PL_sv_no;
  } else {
    RETVAL = &PL_sv_yes;
  }

  FLAC__metadata_chain_delete(chain);

  OUTPUT:
  RETVAL
