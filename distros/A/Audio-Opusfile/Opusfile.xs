#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* op_free is both Perl_op_free and a function in opusfile */
#undef op_free
#include <opus/opusfile.h>

#include "const-c.inc"

typedef OggOpusFile*    Audio__Opusfile;
typedef const OpusHead* Audio__Opusfile__Head;
typedef const OpusTags* Audio__Opusfile__Tags;
typedef const OpusPictureTag* Audio__Opusfile__PictureTag;

MODULE = Audio::Opusfile		PACKAGE = Audio::Opusfile		PREFIX = op_

PROTOTYPES: ENABLE
INCLUDE: const-xs.inc

Audio::Opusfile
op_open_file(path)
	const char *path;
PREINIT:
	int err;
C_ARGS:
	path, &err
POSTCALL:
	if(err)
		croak("op_open_file returned error %d\n", err);

Audio::Opusfile
op_open_memory(const char *data, size_t length(data))
PREINIT:
	int err;
C_ARGS:
	data, XSauto_length_of_data, &err
POSTCALL:
	if(err)
		croak("op_open_memory returned error %d\n", err);

bool
op_test(const char *data, size_t length(data))
PROTOTYPE: $
PREINIT:
	int ret;
CODE:
	ret = op_test (NULL, data, XSauto_length_of_data);
	if(ret < 0 && ret != OP_ENOTFORMAT && ret != OP_EBADHEADER)
		croak("op_test returned error %d\n", RETVAL);
	RETVAL = !ret;
OUTPUT:
	RETVAL


void
DESTROY(of)
	Audio::Opusfile of;
CODE:
	op_free(of);

bool
op_seekable(of)
	Audio::Opusfile of;

int
op_link_count(of)
	Audio::Opusfile of;

int
op_serialno(of, li = -1)
	Audio::Opusfile of;
	int li;

# op_channel_count is not exported; it can be obtained via op_head

long
op_raw_total(of, li = -1)
	Audio::Opusfile of;
	int li;
POSTCALL:
	if(RETVAL < 0)
		croak("op_current_link returned error %ld\n", RETVAL);

long
op_pcm_total(of, li = -1)
	Audio::Opusfile of;
	int li;
POSTCALL:
	if(RETVAL < 0)
		croak("op_current_link returned error %ld\n", RETVAL);

Audio::Opusfile::Head
op_head(of, li = -1)
	Audio::Opusfile of;
	int li;

Audio::Opusfile::Tags
op_tags(of, li = -1)
	Audio::Opusfile of;
	int li;

int
op_current_link(of)
	Audio::Opusfile of;
POSTCALL:
	if(RETVAL < 0)
		croak("op_current_link returned error %ld\n", RETVAL);

int
op_bitrate(of, li = -1)
	Audio::Opusfile of;
	int li;
POSTCALL:
	if(RETVAL < 0)
		croak("op_bitrate returned error %ld\n", RETVAL);

long
op_bitrate_instant(of)
	Audio::Opusfile of;
POSTCALL:
	if(RETVAL < 0)
		croak("op_bitrate_instant returned error %ld\n", RETVAL);

long
op_raw_tell(of)
	Audio::Opusfile of;
POSTCALL:
	if(RETVAL < 0)
		croak("op_raw_tell returned error %ld\n", RETVAL);

long
op_pcm_tell(of)
	Audio::Opusfile of;
POSTCALL:
	if(RETVAL < 0)
		croak("op_pcm_tell returned error %ld\n", RETVAL);

NO_OUTPUT int
op_raw_seek(of, offset)
	Audio::Opusfile of;
	long offset;
POSTCALL:
	if(RETVAL)
		croak("op_raw_seek returned error %d\n", RETVAL);

NO_OUTPUT int
op_pcm_seek(of, offset)
	Audio::Opusfile of;
	long offset;
POSTCALL:
	if(RETVAL)
		croak("op_pcm_seek returned error %d\n", RETVAL);

NO_OUTPUT int
op_set_gain_offset(of, gain_type, gain_offset_q8)
	Audio::Opusfile of;
	int gain_type;
	int gain_offset_q8;
POSTCALL:
	if(RETVAL)
		croak("op_set_gain_offset returned error %d\n", RETVAL);

void
op_set_dither_enabled(of, enabled)
	Audio::Opusfile of;
	int enabled;


void
op_read(of, bufsize = 1024 * 1024)
	Audio::Opusfile of;
	int bufsize;
PREINIT:
	opus_int16* buf;
	int li, ret, chans, i;
PPCODE:
	Newx(buf, bufsize, opus_int16);
	ret = op_read(of, buf, bufsize, &li);
	if(ret < 0)
		croak("op_read returned error %d\n", ret);
	chans = op_channel_count(of, li);
	EXTEND(SP, chans * ret + 1);
	PUSHs(sv_2mortal(newSViv(li)));
	for(i = 0 ; i < chans * ret ; i++)
		PUSHs(sv_2mortal(newSViv(buf[i])));

void
op_read_float(of, bufsize = 1024 * 1024)
	Audio::Opusfile of;
	int bufsize;
PREINIT:
	float* buf;
	int li, ret, chans, i;
PPCODE:
	Newx(buf, bufsize, float);
	ret = op_read_float(of, buf, bufsize, &li);
	if(ret < 0)
		croak("op_read_float returned error %d\n", ret);
	chans = op_channel_count(of, li);
	EXTEND(SP, chans * ret + 1);
	PUSHs(sv_2mortal(newSViv(li)));
	for(i = 0 ; i < chans * ret ; i++)
		PUSHs(sv_2mortal(newSVnv(buf[i])));

void
op_read_stereo(of, bufsize = 1024 * 1024)
	Audio::Opusfile of;
	int bufsize;
PREINIT:
	opus_int16* buf;
	int ret, i;
PPCODE:
	Newx(buf, bufsize, opus_int16);
	ret = op_read_stereo(of, buf, bufsize);
	if(ret < 0)
		croak("op_read_stereo returned error %d\n", ret);
	EXTEND(SP, 2 * ret);
	for(i = 0 ; i < 2 * ret ; i++)
		PUSHs(sv_2mortal(newSViv(buf[i])));

void
op_read_float_stereo(of, bufsize = 1024 * 1024)
	Audio::Opusfile of;
	int bufsize;
PREINIT:
	float* buf;
	int ret, i;
PPCODE:
	Newx(buf, bufsize, float);
	ret = op_read_float_stereo(of, buf, bufsize);
	if(ret < 0)
		croak("op_read_float_stereo returned error %d\n", ret);
	EXTEND(SP, 2 * ret);
	for(i = 0 ; i < 2 * ret ; i++)
		PUSHs(sv_2mortal(newSVnv(buf[i])));



MODULE = Audio::Opusfile		PACKAGE = Audio::Opusfile::Tags		PREFIX = opus_tags_

int
opus_tags_query_count(tags, tag)
	Audio::Opusfile::Tags tags;
	const char* tag;

const char*
opus_tags_query(tags, tag, count = 0)
	Audio::Opusfile::Tags tags;
	const char* tag;
	int count;

MODULE = Audio::Opusfile		PACKAGE = Audio::Opusfile::PictureTag		PREFIX = opus_picture_tag_

Audio::Opusfile::PictureTag
opus_picture_tag_parse(tag)
	const char *tag;
PREINIT:
	OpusPictureTag *pic;
	int err;
CODE:
	Newx(pic, 1, OpusPictureTag);
	if(err = opus_picture_tag_parse(pic, tag))
		croak("opus_picture_tag_parse returned error %d\n", err);
	RETVAL = pic;
OUTPUT:
	RETVAL

void
DESTROY(pic)
	Audio::Opusfile::PictureTag pic
CODE:
	Safefree(pic);

int
type(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->type;
OUTPUT:
	RETVAL

const char*
mime_type(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->mime_type;
OUTPUT:
	RETVAL

const char*
description(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->description;
OUTPUT:
	RETVAL

int
width(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->width;
OUTPUT:
	RETVAL

int
height(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->height;
OUTPUT:
	RETVAL

int
depth(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->depth;
OUTPUT:
	RETVAL

int
colors(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->colors;
OUTPUT:
	RETVAL

int
data_length(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->data_length;
OUTPUT:
	RETVAL

SV*
data(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = newSVpvn(pic->data, pic->data_length);
OUTPUT:
	RETVAL

int
format(pic)
	Audio::Opusfile::PictureTag pic;
CODE:
	RETVAL = pic->format;
OUTPUT:
	RETVAL

MODULE = Audio::Opusfile		PACKAGE = Audio::Opusfile::Head

int
version(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->version;
OUTPUT:
	RETVAL

int
channel_count(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->channel_count;
OUTPUT:
	RETVAL

unsigned
pre_skip(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->pre_skip;
OUTPUT:
	RETVAL

unsigned
input_sample_rate(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->input_sample_rate;
OUTPUT:
	RETVAL

int
output_gain(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->output_gain;
OUTPUT:
	RETVAL

int
mapping_family(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->mapping_family;
OUTPUT:
	RETVAL

int
stream_count(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->stream_count;
OUTPUT:
	RETVAL

int
coupled_count(head)
	Audio::Opusfile::Head head;
CODE:
	RETVAL = head->coupled_count;
OUTPUT:
	RETVAL

int
mapping(head, k)
	Audio::Opusfile::Head head;
	unsigned k;
CODE:
	if(k >= OPUS_CHANNEL_COUNT_MAX)
		croak("k must be less than %d\n", (int)OPUS_CHANNEL_COUNT_MAX);
	RETVAL = (int) head->mapping[k];
OUTPUT:
	RETVAL
