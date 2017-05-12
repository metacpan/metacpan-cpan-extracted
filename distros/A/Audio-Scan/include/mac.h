#ifndef _mac_h_
#define _mac_h_

#define APE_HEADER_LEN              32
#define MAC_397_HEADER_LEN          24
#define MAC_398_HEADER_LEN          70

/* 1000 base. */
const char *mac_profile_names[] = {
  "",
  "Fast (poor)",
  "Normal (good)",
  "High (very good)",
  "Extra high (best)",
  "Insane",
  "BrainDead"
};

typedef struct mac_streaminfo {
  const char* compression;
  uint32_t file_size;
  uint32_t audio_start_offset;
  uint32_t blocks_per_frame;
  uint32_t final_frame;
  uint32_t total_frames;
  uint32_t bits;
  uint32_t channels;
  uint32_t sample_rate;
  uint32_t bitrate;
  uint32_t version;
} mac_streaminfo;

static int get_macfileinfo(PerlIO *infile, char *file, HV *info);

#endif
