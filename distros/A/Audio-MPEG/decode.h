#ifndef AUDIO_MPEG_DECODE_H
#define AUDIO_MPEG_DECODE_H

#include <math.h>
#include <mad.h>
#include "resample.h"

struct audio_mpeg_decode {
	struct mad_stream		*stream;
	struct mad_frame		*frame;
	struct mad_synth		*synth;
	unsigned char			*data_in;
	size_t					data_in_len;
	unsigned int			current_frame;
	unsigned long			accum_bitrate;
	mad_timer_t				total_duration;
};
typedef struct audio_mpeg_decode * Audio_MPEG_Decode;

/* samples that are blank */
#define MP3_DECODE_DELAY		578

void decode_new(Audio_MPEG_Decode);
void decode_DESTROY(Audio_MPEG_Decode);
char const *decode_error_str(enum mad_error);
int decode_buffer(Audio_MPEG_Decode, unsigned char *, size_t);

#endif
