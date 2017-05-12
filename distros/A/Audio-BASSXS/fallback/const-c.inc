#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_TAG_ICY BASS_TAG_ID3 BASS_TAG_OGG BASS_UNICODE */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case '3':
    if (memEQ(name, "BASS_TAG_ID", 11)) {
    /*                          3      */
#ifdef BASS_TAG_ID3
      *iv_return = BASS_TAG_ID3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_UNICOD", 11)) {
    /*                          E      */
#ifdef BASS_UNICODE
      *iv_return = BASS_UNICODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "BASS_TAG_OG", 11)) {
    /*                          G      */
#ifdef BASS_TAG_OGG
      *iv_return = BASS_TAG_OGG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "BASS_TAG_IC", 11)) {
    /*                          Y      */
#ifdef BASS_TAG_ICY
      *iv_return = BASS_TAG_ICY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_ERROR_DX BASS_FILE_LEN BASS_INPUT_ON BASS_MUSIC_3D BASS_MUSIC_FX
     BASS_SYNC_END BASS_SYNC_POS BASS_TAG_HTTP BASS_TAG_META */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case '3':
    if (memEQ(name, "BASS_MUSIC_3D", 13)) {
    /*                          ^        */
#ifdef BASS_MUSIC_3D
      *iv_return = BASS_MUSIC_3D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_ERROR_DX", 13)) {
    /*                          ^        */
#ifdef BASS_ERROR_DX
      *iv_return = BASS_ERROR_DX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_FILE_LEN", 13)) {
    /*                          ^        */
#ifdef BASS_FILE_LEN
      *iv_return = BASS_FILE_LEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "BASS_MUSIC_FX", 13)) {
    /*                          ^        */
#ifdef BASS_MUSIC_FX
      *iv_return = BASS_MUSIC_FX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_SYNC_END", 13)) {
    /*                          ^        */
#ifdef BASS_SYNC_END
      *iv_return = BASS_SYNC_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "BASS_INPUT_ON", 13)) {
    /*                          ^        */
#ifdef BASS_INPUT_ON
      *iv_return = BASS_INPUT_ON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SYNC_POS", 13)) {
    /*                          ^        */
#ifdef BASS_SYNC_POS
      *iv_return = BASS_SYNC_POS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BASS_TAG_HTTP", 13)) {
    /*                          ^        */
#ifdef BASS_TAG_HTTP
      *iv_return = BASS_TAG_HTTP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_TAG_META", 13)) {
    /*                          ^        */
#ifdef BASS_TAG_META
      *iv_return = BASS_TAG_META;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_3DALG_OFF BASS_DEVICE_3D BASS_ERROR_MEM BASS_FILE_READ BASS_FILE_SEEK
     BASS_INPUT_OFF BASS_OBJECT_DS BASS_SAMPLE_3D BASS_SAMPLE_FX BASS_SLIDE_PAN
     BASS_SLIDE_VOL BASS_SYNC_META BASS_TAG_ID3V2 */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "BASS_3DALG_OFF", 14)) {
    /*                      ^             */
#ifdef BASS_3DALG_OFF
      *iv_return = BASS_3DALG_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "BASS_TAG_ID3V2", 14)) {
    /*                      ^             */
#ifdef BASS_TAG_ID3V2
      *iv_return = BASS_TAG_ID3V2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BASS_SLIDE_PAN", 14)) {
    /*                      ^             */
#ifdef BASS_SLIDE_PAN
      *iv_return = BASS_SLIDE_PAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SLIDE_VOL", 14)) {
    /*                      ^             */
#ifdef BASS_SLIDE_VOL
      *iv_return = BASS_SLIDE_VOL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "BASS_OBJECT_DS", 14)) {
    /*                      ^             */
#ifdef BASS_OBJECT_DS
      *iv_return = BASS_OBJECT_DS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_FILE_READ", 14)) {
    /*                      ^             */
#ifdef BASS_FILE_READ
      *iv_return = BASS_FILE_READ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_FILE_SEEK", 14)) {
    /*                      ^             */
#ifdef BASS_FILE_SEEK
      *iv_return = BASS_FILE_SEEK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BASS_SAMPLE_3D", 14)) {
    /*                      ^             */
#ifdef BASS_SAMPLE_3D
      *iv_return = BASS_SAMPLE_3D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SAMPLE_FX", 14)) {
    /*                      ^             */
#ifdef BASS_SAMPLE_FX
      *iv_return = BASS_SAMPLE_FX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_SYNC_META", 14)) {
    /*                      ^             */
#ifdef BASS_SYNC_META
      *iv_return = BASS_SYNC_META;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BASS_INPUT_OFF", 14)) {
    /*                      ^             */
#ifdef BASS_INPUT_OFF
      *iv_return = BASS_INPUT_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "BASS_ERROR_MEM", 14)) {
    /*                      ^             */
#ifdef BASS_ERROR_MEM
      *iv_return = BASS_ERROR_MEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "BASS_DEVICE_3D", 14)) {
    /*                      ^             */
#ifdef BASS_DEVICE_3D
      *iv_return = BASS_DEVICE_3D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_3DALG_FULL BASS_3DMODE_OFF BASS_ERROR_FREQ BASS_ERROR_INIT
     BASS_ERROR_NO3D BASS_ERROR_NOFX BASS_ERROR_NOHW BASS_FILE_CLOSE
     BASS_FILE_QUERY BASS_MP3_SETPOS BASS_MUSIC_LOOP BASS_MUSIC_MONO
     BASS_MUSIC_RAMP BASS_SAMPLE_VAM BASS_SLIDE_FREQ BASS_SYNC_SLIDE
     BASS_SYNC_STALL EAX_PRESET_CAVE EAX_PRESET_CITY EAX_PRESET_ROOM */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '3':
    if (memEQ(name, "BASS_ERROR_NO3D", 15)) {
    /*                            ^        */
#ifdef BASS_ERROR_NO3D
      *iv_return = BASS_ERROR_NO3D;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "BASS_SAMPLE_VAM", 15)) {
    /*                            ^        */
#ifdef BASS_SAMPLE_VAM
      *iv_return = BASS_SAMPLE_VAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_SYNC_SLIDE", 15)) {
    /*                            ^        */
#ifdef BASS_SYNC_SLIDE
      *iv_return = BASS_SYNC_SLIDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_ERROR_FREQ", 15)) {
    /*                            ^        */
#ifdef BASS_ERROR_FREQ
      *iv_return = BASS_ERROR_FREQ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SLIDE_FREQ", 15)) {
    /*                            ^        */
#ifdef BASS_SLIDE_FREQ
      *iv_return = BASS_SLIDE_FREQ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "BASS_3DMODE_OFF", 15)) {
    /*                            ^        */
#ifdef BASS_3DMODE_OFF
      *iv_return = BASS_3DMODE_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_NOFX", 15)) {
    /*                            ^        */
#ifdef BASS_ERROR_NOFX
      *iv_return = BASS_ERROR_NOFX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "BASS_ERROR_NOHW", 15)) {
    /*                            ^        */
#ifdef BASS_ERROR_NOHW
      *iv_return = BASS_ERROR_NOHW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BASS_ERROR_INIT", 15)) {
    /*                            ^        */
#ifdef BASS_ERROR_INIT
      *iv_return = BASS_ERROR_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_3DALG_FULL", 15)) {
    /*                            ^        */
#ifdef BASS_3DALG_FULL
      *iv_return = BASS_3DALG_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SYNC_STALL", 15)) {
    /*                            ^        */
#ifdef BASS_SYNC_STALL
      *iv_return = BASS_SYNC_STALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BASS_MUSIC_RAMP", 15)) {
    /*                            ^        */
#ifdef BASS_MUSIC_RAMP
      *iv_return = BASS_MUSIC_RAMP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_MUSIC_MONO", 15)) {
    /*                            ^        */
#ifdef BASS_MUSIC_MONO
      *iv_return = BASS_MUSIC_MONO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "BASS_MP3_SETPOS", 15)) {
    /*                            ^        */
#ifdef BASS_MP3_SETPOS
      *iv_return = BASS_MP3_SETPOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_LOOP", 15)) {
    /*                            ^        */
#ifdef BASS_MUSIC_LOOP
      *iv_return = BASS_MUSIC_LOOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_ROOM", 15)) {
    /*                            ^        */
#ifdef EAX_PRESET_ROOM
      *iv_return = EAX_PRESET_ROOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "BASS_FILE_QUERY", 15)) {
    /*                            ^        */
#ifdef BASS_FILE_QUERY
      *iv_return = BASS_FILE_QUERY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_FILE_CLOSE", 15)) {
    /*                            ^        */
#ifdef BASS_FILE_CLOSE
      *iv_return = BASS_FILE_CLOSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EAX_PRESET_CITY", 15)) {
    /*                            ^        */
#ifdef EAX_PRESET_CITY
      *iv_return = EAX_PRESET_CITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "EAX_PRESET_CAVE", 15)) {
    /*                            ^        */
#ifdef EAX_PRESET_CAVE
      *iv_return = EAX_PRESET_CAVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_3DALG_LIGHT BASS_DATA_FFT512 BASS_DEVICE_MONO BASS_ERROR_EMPTY
     BASS_ERROR_NOEAX BASS_ERROR_NONET BASS_ERROR_START BASS_FILEPOS_END
     BASS_FX_PHASE_90 BASS_INPUT_LEVEL BASS_MUSIC_FLOAT BASS_MUSIC_RAMPS
     BASS_SAMPLE_LOOP BASS_SAMPLE_MONO BASS_SPEAKER_LFE BASS_STREAM_META
     DSCAPS_CERTIFIED EAX_PRESET_ALLEY EAX_PRESET_ARENA EAX_PRESET_DIZZY
     EAX_PRESET_PLAIN WAVE_FORMAT_1M08 WAVE_FORMAT_1M16 WAVE_FORMAT_1S08
     WAVE_FORMAT_1S16 WAVE_FORMAT_2M08 WAVE_FORMAT_2M16 WAVE_FORMAT_2S08
     WAVE_FORMAT_2S16 WAVE_FORMAT_4M08 WAVE_FORMAT_4M16 WAVE_FORMAT_4S08
     WAVE_FORMAT_4S16 */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case '0':
    if (memEQ(name, "BASS_FX_PHASE_9", 15)) {
    /*                              0      */
#ifdef BASS_FX_PHASE_90
      *iv_return = BASS_FX_PHASE_90;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "BASS_DATA_FFT51", 15)) {
    /*                              2      */
#ifdef BASS_DATA_FFT512
      *iv_return = BASS_DATA_FFT512;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "WAVE_FORMAT_1M1", 15)) {
    /*                              6      */
#ifdef WAVE_FORMAT_1M16
      *iv_return = WAVE_FORMAT_1M16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_1S1", 15)) {
    /*                              6      */
#ifdef WAVE_FORMAT_1S16
      *iv_return = WAVE_FORMAT_1S16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_2M1", 15)) {
    /*                              6      */
#ifdef WAVE_FORMAT_2M16
      *iv_return = WAVE_FORMAT_2M16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_2S1", 15)) {
    /*                              6      */
#ifdef WAVE_FORMAT_2S16
      *iv_return = WAVE_FORMAT_2S16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_4M1", 15)) {
    /*                              6      */
#ifdef WAVE_FORMAT_4M16
      *iv_return = WAVE_FORMAT_4M16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_4S1", 15)) {
    /*                              6      */
#ifdef WAVE_FORMAT_4S16
      *iv_return = WAVE_FORMAT_4S16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "WAVE_FORMAT_1M0", 15)) {
    /*                              8      */
#ifdef WAVE_FORMAT_1M08
      *iv_return = WAVE_FORMAT_1M08;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_1S0", 15)) {
    /*                              8      */
#ifdef WAVE_FORMAT_1S08
      *iv_return = WAVE_FORMAT_1S08;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_2M0", 15)) {
    /*                              8      */
#ifdef WAVE_FORMAT_2M08
      *iv_return = WAVE_FORMAT_2M08;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_2S0", 15)) {
    /*                              8      */
#ifdef WAVE_FORMAT_2S08
      *iv_return = WAVE_FORMAT_2S08;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_4M0", 15)) {
    /*                              8      */
#ifdef WAVE_FORMAT_4M08
      *iv_return = WAVE_FORMAT_4M08;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "WAVE_FORMAT_4S0", 15)) {
    /*                              8      */
#ifdef WAVE_FORMAT_4S08
      *iv_return = WAVE_FORMAT_4S08;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "BASS_STREAM_MET", 15)) {
    /*                              A      */
#ifdef BASS_STREAM_META
      *iv_return = BASS_STREAM_META;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_AREN", 15)) {
    /*                              A      */
#ifdef EAX_PRESET_ARENA
      *iv_return = EAX_PRESET_ARENA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_FILEPOS_EN", 15)) {
    /*                              D      */
#ifdef BASS_FILEPOS_END
      *iv_return = BASS_FILEPOS_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DSCAPS_CERTIFIE", 15)) {
    /*                              D      */
#ifdef DSCAPS_CERTIFIED
      *iv_return = DSCAPS_CERTIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_SPEAKER_LF", 15)) {
    /*                              E      */
#ifdef BASS_SPEAKER_LFE
      *iv_return = BASS_SPEAKER_LFE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_INPUT_LEVE", 15)) {
    /*                              L      */
#ifdef BASS_INPUT_LEVEL
      *iv_return = BASS_INPUT_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EAX_PRESET_PLAI", 15)) {
    /*                              N      */
#ifdef EAX_PRESET_PLAIN
      *iv_return = EAX_PRESET_PLAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "BASS_DEVICE_MON", 15)) {
    /*                              O      */
#ifdef BASS_DEVICE_MONO
      *iv_return = BASS_DEVICE_MONO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SAMPLE_MON", 15)) {
    /*                              O      */
#ifdef BASS_SAMPLE_MONO
      *iv_return = BASS_SAMPLE_MONO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BASS_SAMPLE_LOO", 15)) {
    /*                              P      */
#ifdef BASS_SAMPLE_LOOP
      *iv_return = BASS_SAMPLE_LOOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_MUSIC_RAMP", 15)) {
    /*                              S      */
#ifdef BASS_MUSIC_RAMPS
      *iv_return = BASS_MUSIC_RAMPS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BASS_3DALG_LIGH", 15)) {
    /*                              T      */
#ifdef BASS_3DALG_LIGHT
      *iv_return = BASS_3DALG_LIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_NONE", 15)) {
    /*                              T      */
#ifdef BASS_ERROR_NONET
      *iv_return = BASS_ERROR_NONET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_STAR", 15)) {
    /*                              T      */
#ifdef BASS_ERROR_START
      *iv_return = BASS_ERROR_START;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_FLOA", 15)) {
    /*                              T      */
#ifdef BASS_MUSIC_FLOAT
      *iv_return = BASS_MUSIC_FLOAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "BASS_ERROR_NOEA", 15)) {
    /*                              X      */
#ifdef BASS_ERROR_NOEAX
      *iv_return = BASS_ERROR_NOEAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "BASS_ERROR_EMPT", 15)) {
    /*                              Y      */
#ifdef BASS_ERROR_EMPTY
      *iv_return = BASS_ERROR_EMPTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_ALLE", 15)) {
    /*                              Y      */
#ifdef EAX_PRESET_ALLEY
      *iv_return = EAX_PRESET_ALLEY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_DIZZ", 15)) {
    /*                              Y      */
#ifdef EAX_PRESET_DIZZY
      *iv_return = EAX_PRESET_DIZZY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_CTYPE_RECORD BASS_CTYPE_SAMPLE BASS_CTYPE_STREAM BASS_DATA_FFT1024
     BASS_DATA_FFT2048 BASS_DATA_FFT4096 BASS_DEVICE_8BITS BASS_ERROR_CREATE
     BASS_ERROR_DECODE BASS_ERROR_DEVICE BASS_ERROR_DRIVER BASS_ERROR_FORMAT
     BASS_ERROR_HANDLE BASS_ERROR_NOCHAN BASS_ERROR_NOPLAY BASS_FX_PHASE_180
     BASS_MUSIC_DECODE BASS_MUSIC_FT2MOD BASS_MUSIC_PT1MOD BASS_OBJECT_DS3DL
     BASS_RECORD_PAUSE BASS_SAMPLE_8BITS BASS_SAMPLE_FLOAT BASS_SPEAKER_LEFT
     BASS_SPEAKER_REAR BASS_STREAM_BLOCK BASS_SYNC_MESSAGE BASS_SYNC_MIXTIME
     BASS_SYNC_MUSICFX BASS_SYNC_ONETIME BASS_VAM_HARDWARE BASS_VAM_SOFTWARE
     DSCAPS_EMULDRIVER DSCCAPS_CERTIFIED EAX_PRESET_FOREST EAX_PRESET_HANGAR
     EAX_PRESET_QUARRY */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '1':
    if (memEQ(name, "BASS_DATA_FFT1024", 17)) {
    /*                            ^          */
#ifdef BASS_DATA_FFT1024
      *iv_return = BASS_DATA_FFT1024;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_PT1MOD", 17)) {
    /*                            ^          */
#ifdef BASS_MUSIC_PT1MOD
      *iv_return = BASS_MUSIC_PT1MOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "BASS_DATA_FFT2048", 17)) {
    /*                            ^          */
#ifdef BASS_DATA_FFT2048
      *iv_return = BASS_DATA_FFT2048;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_FT2MOD", 17)) {
    /*                            ^          */
#ifdef BASS_MUSIC_FT2MOD
      *iv_return = BASS_MUSIC_FT2MOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "BASS_DATA_FFT4096", 17)) {
    /*                            ^          */
#ifdef BASS_DATA_FFT4096
      *iv_return = BASS_DATA_FFT4096;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "BASS_RECORD_PAUSE", 17)) {
    /*                            ^          */
#ifdef BASS_RECORD_PAUSE
      *iv_return = BASS_RECORD_PAUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_QUARRY", 17)) {
    /*                            ^          */
#ifdef EAX_PRESET_QUARRY
      *iv_return = EAX_PRESET_QUARRY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "BASS_DEVICE_8BITS", 17)) {
    /*                            ^          */
#ifdef BASS_DEVICE_8BITS
      *iv_return = BASS_DEVICE_8BITS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SAMPLE_8BITS", 17)) {
    /*                            ^          */
#ifdef BASS_SAMPLE_8BITS
      *iv_return = BASS_SAMPLE_8BITS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "BASS_CTYPE_RECORD", 17)) {
    /*                            ^          */
#ifdef BASS_CTYPE_RECORD
      *iv_return = BASS_CTYPE_RECORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_DECODE", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_DECODE
      *iv_return = BASS_ERROR_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_NOCHAN", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_NOCHAN
      *iv_return = BASS_ERROR_NOCHAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_DECODE", 17)) {
    /*                            ^          */
#ifdef BASS_MUSIC_DECODE
      *iv_return = BASS_MUSIC_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_ERROR_CREATE", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_CREATE
      *iv_return = BASS_ERROR_CREATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "DSCCAPS_CERTIFIED", 17)) {
    /*                            ^          */
#ifdef DSCCAPS_CERTIFIED
      *iv_return = DSCCAPS_CERTIFIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BASS_ERROR_DRIVER", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_DRIVER
      *iv_return = BASS_ERROR_DRIVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SYNC_MUSICFX", 17)) {
    /*                            ^          */
#ifdef BASS_SYNC_MUSICFX
      *iv_return = BASS_SYNC_MUSICFX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DSCAPS_EMULDRIVER", 17)) {
    /*                            ^          */
#ifdef DSCAPS_EMULDRIVER
      *iv_return = DSCAPS_EMULDRIVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_SAMPLE_FLOAT", 17)) {
    /*                            ^          */
#ifdef BASS_SAMPLE_FLOAT
      *iv_return = BASS_SAMPLE_FLOAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_LEFT", 17)) {
    /*                            ^          */
#ifdef BASS_SPEAKER_LEFT
      *iv_return = BASS_SPEAKER_LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_STREAM_BLOCK", 17)) {
    /*                            ^          */
#ifdef BASS_STREAM_BLOCK
      *iv_return = BASS_STREAM_BLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BASS_CTYPE_SAMPLE", 17)) {
    /*                            ^          */
#ifdef BASS_CTYPE_SAMPLE
      *iv_return = BASS_CTYPE_SAMPLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_ERROR_HANDLE", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_HANDLE
      *iv_return = BASS_ERROR_HANDLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_HANGAR", 17)) {
    /*                            ^          */
#ifdef EAX_PRESET_HANGAR
      *iv_return = EAX_PRESET_HANGAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BASS_ERROR_NOPLAY", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_NOPLAY
      *iv_return = BASS_ERROR_NOPLAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "BASS_CTYPE_STREAM", 17)) {
    /*                            ^          */
#ifdef BASS_CTYPE_STREAM
      *iv_return = BASS_CTYPE_STREAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_FORMAT", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_FORMAT
      *iv_return = BASS_ERROR_FORMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_REAR", 17)) {
    /*                            ^          */
#ifdef BASS_SPEAKER_REAR
      *iv_return = BASS_SPEAKER_REAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_FOREST", 17)) {
    /*                            ^          */
#ifdef EAX_PRESET_FOREST
      *iv_return = EAX_PRESET_FOREST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_OBJECT_DS3DL", 17)) {
    /*                            ^          */
#ifdef BASS_OBJECT_DS3DL
      *iv_return = BASS_OBJECT_DS3DL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SYNC_MESSAGE", 17)) {
    /*                            ^          */
#ifdef BASS_SYNC_MESSAGE
      *iv_return = BASS_SYNC_MESSAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BASS_SYNC_MIXTIME", 17)) {
    /*                            ^          */
#ifdef BASS_SYNC_MIXTIME
      *iv_return = BASS_SYNC_MIXTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SYNC_ONETIME", 17)) {
    /*                            ^          */
#ifdef BASS_SYNC_ONETIME
      *iv_return = BASS_SYNC_ONETIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "BASS_ERROR_DEVICE", 17)) {
    /*                            ^          */
#ifdef BASS_ERROR_DEVICE
      *iv_return = BASS_ERROR_DEVICE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "BASS_VAM_HARDWARE", 17)) {
    /*                            ^          */
#ifdef BASS_VAM_HARDWARE
      *iv_return = BASS_VAM_HARDWARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_VAM_SOFTWARE", 17)) {
    /*                            ^          */
#ifdef BASS_VAM_SOFTWARE
      *iv_return = BASS_VAM_SOFTWARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "BASS_FX_PHASE_180", 17)) {
    /*                            ^          */
#ifdef BASS_FX_PHASE_180
      *iv_return = BASS_FX_PHASE_180;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_3DALG_DEFAULT BASS_3DMODE_NORMAL BASS_ACTIVE_PAUSED
     BASS_CONFIG_BUFFER BASS_CONFIG_MAXVOL BASS_ERROR_ALREADY
     BASS_ERROR_BUFLOST BASS_ERROR_ILLTYPE BASS_ERROR_NOPAUSE
     BASS_ERROR_NOTFILE BASS_ERROR_PLAYING BASS_ERROR_SPEAKER
     BASS_ERROR_TIMEOUT BASS_ERROR_UNKNOWN BASS_FX_PHASE_ZERO
     BASS_INPUT_TYPE_CD BASS_MUSIC_CALCLEN BASS_SPEAKER_FRONT
     BASS_SPEAKER_REAR2 BASS_SPEAKER_RIGHT BASS_STREAM_DECODE
     BASS_SYNC_DOWNLOAD BASS_SYNC_MUSICPOS BASS_VAM_TERM_DIST
     BASS_VAM_TERM_PRIO BASS_VAM_TERM_TIME DSCCAPS_EMULDRIVER
     EAX_PRESET_DRUGGED EAX_PRESET_GENERIC EAX_PRESET_HALLWAY */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'A':
    if (memEQ(name, "BASS_MUSIC_CALCLEN", 18)) {
    /*                           ^            */
#ifdef BASS_MUSIC_CALCLEN
      *iv_return = BASS_MUSIC_CALCLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_HALLWAY", 18)) {
    /*                           ^            */
#ifdef EAX_PRESET_HALLWAY
      *iv_return = EAX_PRESET_HALLWAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "BASS_CONFIG_BUFFER", 18)) {
    /*                           ^            */
#ifdef BASS_CONFIG_BUFFER
      *iv_return = BASS_CONFIG_BUFFER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_STREAM_DECODE", 18)) {
    /*                           ^            */
#ifdef BASS_STREAM_DECODE
      *iv_return = BASS_STREAM_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DSCCAPS_EMULDRIVER", 18)) {
    /*                           ^            */
#ifdef DSCCAPS_EMULDRIVER
      *iv_return = DSCCAPS_EMULDRIVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_3DALG_DEFAULT", 18)) {
    /*                           ^            */
#ifdef BASS_3DALG_DEFAULT
      *iv_return = BASS_3DALG_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_FX_PHASE_ZERO", 18)) {
    /*                           ^            */
#ifdef BASS_FX_PHASE_ZERO
      *iv_return = BASS_FX_PHASE_ZERO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_GENERIC", 18)) {
    /*                           ^            */
#ifdef EAX_PRESET_GENERIC
      *iv_return = EAX_PRESET_GENERIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BASS_ERROR_TIMEOUT", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_TIMEOUT
      *iv_return = BASS_ERROR_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_ERROR_ALREADY", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_ALREADY
      *iv_return = BASS_ERROR_ALREADY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_ILLTYPE", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_ILLTYPE
      *iv_return = BASS_ERROR_ILLTYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_PLAYING", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_PLAYING
      *iv_return = BASS_ERROR_PLAYING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BASS_CONFIG_MAXVOL", 18)) {
    /*                           ^            */
#ifdef BASS_CONFIG_MAXVOL
      *iv_return = BASS_CONFIG_MAXVOL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_VAM_TERM_DIST", 18)) {
    /*                           ^            */
#ifdef BASS_VAM_TERM_DIST
      *iv_return = BASS_VAM_TERM_DIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_VAM_TERM_PRIO", 18)) {
    /*                           ^            */
#ifdef BASS_VAM_TERM_PRIO
      *iv_return = BASS_VAM_TERM_PRIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_VAM_TERM_TIME", 18)) {
    /*                           ^            */
#ifdef BASS_VAM_TERM_TIME
      *iv_return = BASS_VAM_TERM_TIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_3DMODE_NORMAL", 18)) {
    /*                           ^            */
#ifdef BASS_3DMODE_NORMAL
      *iv_return = BASS_3DMODE_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_UNKNOWN", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_UNKNOWN
      *iv_return = BASS_ERROR_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "BASS_ERROR_NOPAUSE", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_NOPAUSE
      *iv_return = BASS_ERROR_NOPAUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_NOTFILE", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_NOTFILE
      *iv_return = BASS_ERROR_NOTFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BASS_ACTIVE_PAUSED", 18)) {
    /*                           ^            */
#ifdef BASS_ACTIVE_PAUSED
      *iv_return = BASS_ACTIVE_PAUSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_SPEAKER", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_SPEAKER
      *iv_return = BASS_ERROR_SPEAKER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EAX_PRESET_DRUGGED", 18)) {
    /*                           ^            */
#ifdef EAX_PRESET_DRUGGED
      *iv_return = EAX_PRESET_DRUGGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_SYNC_MUSICPOS", 18)) {
    /*                           ^            */
#ifdef BASS_SYNC_MUSICPOS
      *iv_return = BASS_SYNC_MUSICPOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "BASS_ERROR_BUFLOST", 18)) {
    /*                           ^            */
#ifdef BASS_ERROR_BUFLOST
      *iv_return = BASS_ERROR_BUFLOST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "BASS_SYNC_DOWNLOAD", 18)) {
    /*                           ^            */
#ifdef BASS_SYNC_DOWNLOAD
      *iv_return = BASS_SYNC_DOWNLOAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "BASS_INPUT_TYPE_CD", 18)) {
    /*                           ^            */
#ifdef BASS_INPUT_TYPE_CD
      *iv_return = BASS_INPUT_TYPE_CD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "BASS_SPEAKER_FRONT", 18)) {
    /*                           ^            */
#ifdef BASS_SPEAKER_FRONT
      *iv_return = BASS_SPEAKER_FRONT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_REAR2", 18)) {
    /*                           ^            */
#ifdef BASS_SPEAKER_REAR2
      *iv_return = BASS_SPEAKER_REAR2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_RIGHT", 18)) {
    /*                           ^            */
#ifdef BASS_SPEAKER_RIGHT
      *iv_return = BASS_SPEAKER_RIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_ACTIVE_PLAYING BASS_ACTIVE_STALLED BASS_ACTIVE_STOPPED
     BASS_CTYPE_MUSIC_IT BASS_CTYPE_MUSIC_XM BASS_DATA_AVAILABLE
     BASS_DEVICE_LATENCY BASS_ERROR_FILEFORM BASS_ERROR_FILEOPEN
     BASS_ERROR_ILLPARAM BASS_ERROR_NOTAVAIL BASS_ERROR_POSITION
     BASS_FILEPOS_DECODE BASS_INPUT_TYPE_AUX BASS_INPUT_TYPE_MIC
     BASS_MUSIC_AUTOFREE BASS_MUSIC_NONINTER BASS_MUSIC_NOSAMPLE
     BASS_MUSIC_POSRESET BASS_MUSIC_STOPBACK BASS_MUSIC_SURROUND
     BASS_SAMPLE_MUTEMAX BASS_SPEAKER_CENLFE BASS_SPEAKER_CENTER
     BASS_STREAMPROC_END BASS_SYNC_MUSICINST EAX_PRESET_BATHROOM */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'A':
    if (memEQ(name, "BASS_DATA_AVAILABLE", 19)) {
    /*                              ^          */
#ifdef BASS_DATA_AVAILABLE
      *iv_return = BASS_DATA_AVAILABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_ERROR_ILLPARAM", 19)) {
    /*                              ^          */
#ifdef BASS_ERROR_ILLPARAM
      *iv_return = BASS_ERROR_ILLPARAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "BASS_MUSIC_STOPBACK", 19)) {
    /*                              ^          */
#ifdef BASS_MUSIC_STOPBACK
      *iv_return = BASS_MUSIC_STOPBACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "BASS_CTYPE_MUSIC_IT", 19)) {
    /*                              ^          */
#ifdef BASS_CTYPE_MUSIC_IT
      *iv_return = BASS_CTYPE_MUSIC_IT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_CTYPE_MUSIC_XM", 19)) {
    /*                              ^          */
#ifdef BASS_CTYPE_MUSIC_XM
      *iv_return = BASS_CTYPE_MUSIC_XM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_FILEPOS_DECODE", 19)) {
    /*                              ^          */
#ifdef BASS_FILEPOS_DECODE
      *iv_return = BASS_FILEPOS_DECODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_DEVICE_LATENCY", 19)) {
    /*                              ^          */
#ifdef BASS_DEVICE_LATENCY
      *iv_return = BASS_DEVICE_LATENCY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_POSRESET", 19)) {
    /*                              ^          */
#ifdef BASS_MUSIC_POSRESET
      *iv_return = BASS_MUSIC_POSRESET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SAMPLE_MUTEMAX", 19)) {
    /*                              ^          */
#ifdef BASS_SAMPLE_MUTEMAX
      *iv_return = BASS_SAMPLE_MUTEMAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "BASS_ERROR_FILEFORM", 19)) {
    /*                              ^          */
#ifdef BASS_ERROR_FILEFORM
      *iv_return = BASS_ERROR_FILEFORM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_AUTOFREE", 19)) {
    /*                              ^          */
#ifdef BASS_MUSIC_AUTOFREE
      *iv_return = BASS_MUSIC_AUTOFREE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BASS_SYNC_MUSICINST", 19)) {
    /*                              ^          */
#ifdef BASS_SYNC_MUSICINST
      *iv_return = BASS_SYNC_MUSICINST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_ACTIVE_STALLED", 19)) {
    /*                              ^          */
#ifdef BASS_ACTIVE_STALLED
      *iv_return = BASS_ACTIVE_STALLED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BASS_MUSIC_NOSAMPLE", 19)) {
    /*                              ^          */
#ifdef BASS_MUSIC_NOSAMPLE
      *iv_return = BASS_MUSIC_NOSAMPLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_MUSIC_NONINTER", 19)) {
    /*                              ^          */
#ifdef BASS_MUSIC_NONINTER
      *iv_return = BASS_MUSIC_NONINTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_CENLFE", 19)) {
    /*                              ^          */
#ifdef BASS_SPEAKER_CENLFE
      *iv_return = BASS_SPEAKER_CENLFE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_CENTER", 19)) {
    /*                              ^          */
#ifdef BASS_SPEAKER_CENTER
      *iv_return = BASS_SPEAKER_CENTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "BASS_ERROR_FILEOPEN", 19)) {
    /*                              ^          */
#ifdef BASS_ERROR_FILEOPEN
      *iv_return = BASS_ERROR_FILEOPEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_MUSIC_SURROUND", 19)) {
    /*                              ^          */
#ifdef BASS_MUSIC_SURROUND
      *iv_return = BASS_MUSIC_SURROUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BASS_ACTIVE_STOPPED", 19)) {
    /*                              ^          */
#ifdef BASS_ACTIVE_STOPPED
      *iv_return = BASS_ACTIVE_STOPPED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EAX_PRESET_BATHROOM", 19)) {
    /*                              ^          */
#ifdef EAX_PRESET_BATHROOM
      *iv_return = EAX_PRESET_BATHROOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BASS_ERROR_POSITION", 19)) {
    /*                              ^          */
#ifdef BASS_ERROR_POSITION
      *iv_return = BASS_ERROR_POSITION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "BASS_ERROR_NOTAVAIL", 19)) {
    /*                              ^          */
#ifdef BASS_ERROR_NOTAVAIL
      *iv_return = BASS_ERROR_NOTAVAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "BASS_ACTIVE_PLAYING", 19)) {
    /*                              ^          */
#ifdef BASS_ACTIVE_PLAYING
      *iv_return = BASS_ACTIVE_PLAYING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "BASS_INPUT_TYPE_AUX", 19)) {
    /*                              ^          */
#ifdef BASS_INPUT_TYPE_AUX
      *iv_return = BASS_INPUT_TYPE_AUX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_INPUT_TYPE_MIC", 19)) {
    /*                              ^          */
#ifdef BASS_INPUT_TYPE_MIC
      *iv_return = BASS_INPUT_TYPE_MIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_STREAMPROC_END", 19)) {
    /*                              ^          */
#ifdef BASS_STREAMPROC_END
      *iv_return = BASS_STREAMPROC_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_3DMODE_RELATIVE BASS_CONFIG_FLOATDSP BASS_CTYPE_MUSIC_MO3
     BASS_CTYPE_MUSIC_MOD BASS_CTYPE_MUSIC_MTM BASS_CTYPE_MUSIC_S3M
     BASS_DEVICE_SPEAKERS BASS_FX_PHASE_NEG_90 BASS_INPUT_TYPE_LINE
     BASS_INPUT_TYPE_MASK BASS_INPUT_TYPE_WAVE BASS_MUSIC_SURROUND2
     BASS_SAMPLE_OVER_POS BASS_SAMPLE_OVER_VOL BASS_SAMPLE_SOFTWARE
     BASS_STREAM_AUTOFREE BASS_STREAM_RESTRATE DSCAPS_SECONDARY8BIT
     DSCAPS_SECONDARYMONO EAX_PRESET_MOUNTAINS EAX_PRESET_PSYCHOTIC
     EAX_PRESET_SEWERPIPE EAX_PRESET_STONEROOM */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'A':
    if (memEQ(name, "BASS_INPUT_TYPE_MASK", 20)) {
    /*                                ^         */
#ifdef BASS_INPUT_TYPE_MASK
      *iv_return = BASS_INPUT_TYPE_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_INPUT_TYPE_WAVE", 20)) {
    /*                                ^         */
#ifdef BASS_INPUT_TYPE_WAVE
      *iv_return = BASS_INPUT_TYPE_WAVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SAMPLE_SOFTWARE", 20)) {
    /*                                ^         */
#ifdef BASS_SAMPLE_SOFTWARE
      *iv_return = BASS_SAMPLE_SOFTWARE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_STREAM_RESTRATE", 20)) {
    /*                                ^         */
#ifdef BASS_STREAM_RESTRATE
      *iv_return = BASS_STREAM_RESTRATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DSCAPS_SECONDARY8BIT", 20)) {
    /*                                ^         */
#ifdef DSCAPS_SECONDARY8BIT
      *iv_return = DSCAPS_SECONDARY8BIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_CONFIG_FLOATDSP", 20)) {
    /*                                ^         */
#ifdef BASS_CONFIG_FLOATDSP
      *iv_return = BASS_CONFIG_FLOATDSP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_DEVICE_SPEAKERS", 20)) {
    /*                                ^         */
#ifdef BASS_DEVICE_SPEAKERS
      *iv_return = BASS_DEVICE_SPEAKERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BASS_3DMODE_RELATIVE", 20)) {
    /*                                ^         */
#ifdef BASS_3DMODE_RELATIVE
      *iv_return = BASS_3DMODE_RELATIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_INPUT_TYPE_LINE", 20)) {
    /*                                ^         */
#ifdef BASS_INPUT_TYPE_LINE
      *iv_return = BASS_INPUT_TYPE_LINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_MOUNTAINS", 20)) {
    /*                                ^         */
#ifdef EAX_PRESET_MOUNTAINS
      *iv_return = EAX_PRESET_MOUNTAINS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_SEWERPIPE", 20)) {
    /*                                ^         */
#ifdef EAX_PRESET_SEWERPIPE
      *iv_return = EAX_PRESET_SEWERPIPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BASS_CTYPE_MUSIC_MO3", 20)) {
    /*                                ^         */
#ifdef BASS_CTYPE_MUSIC_MO3
      *iv_return = BASS_CTYPE_MUSIC_MO3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_CTYPE_MUSIC_MOD", 20)) {
    /*                                ^         */
#ifdef BASS_CTYPE_MUSIC_MOD
      *iv_return = BASS_CTYPE_MUSIC_MOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_CTYPE_MUSIC_MTM", 20)) {
    /*                                ^         */
#ifdef BASS_CTYPE_MUSIC_MTM
      *iv_return = BASS_CTYPE_MUSIC_MTM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_MUSIC_SURROUND2", 20)) {
    /*                                ^         */
#ifdef BASS_MUSIC_SURROUND2
      *iv_return = BASS_MUSIC_SURROUND2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DSCAPS_SECONDARYMONO", 20)) {
    /*                                ^         */
#ifdef DSCAPS_SECONDARYMONO
      *iv_return = DSCAPS_SECONDARYMONO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_STONEROOM", 20)) {
    /*                                ^         */
#ifdef EAX_PRESET_STONEROOM
      *iv_return = EAX_PRESET_STONEROOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BASS_SAMPLE_OVER_POS", 20)) {
    /*                                ^         */
#ifdef BASS_SAMPLE_OVER_POS
      *iv_return = BASS_SAMPLE_OVER_POS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "BASS_STREAM_AUTOFREE", 20)) {
    /*                                ^         */
#ifdef BASS_STREAM_AUTOFREE
      *iv_return = BASS_STREAM_AUTOFREE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_CTYPE_MUSIC_S3M", 20)) {
    /*                                ^         */
#ifdef BASS_CTYPE_MUSIC_S3M
      *iv_return = BASS_CTYPE_MUSIC_S3M;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EAX_PRESET_PSYCHOTIC", 20)) {
    /*                                ^         */
#ifdef EAX_PRESET_PSYCHOTIC
      *iv_return = EAX_PRESET_PSYCHOTIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "BASS_SAMPLE_OVER_VOL", 20)) {
    /*                                ^         */
#ifdef BASS_SAMPLE_OVER_VOL
      *iv_return = BASS_SAMPLE_OVER_VOL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "BASS_FX_PHASE_NEG_90", 20)) {
    /*                                ^         */
#ifdef BASS_FX_PHASE_NEG_90
      *iv_return = BASS_FX_PHASE_NEG_90;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_CONFIG_CURVE_PAN BASS_CONFIG_CURVE_VOL BASS_CTYPE_STREAM_MP1
     BASS_CTYPE_STREAM_MP2 BASS_CTYPE_STREAM_MP3 BASS_CTYPE_STREAM_OGG
     BASS_CTYPE_STREAM_WAV BASS_FILEPOS_DOWNLOAD BASS_FX_PHASE_NEG_180
     BASS_INPUT_TYPE_PHONE BASS_INPUT_TYPE_SYNTH BASS_INPUT_TYPE_UNDEF
     BASS_SAMPLE_OVER_DIST BASS_SPEAKER_REARLEFT DSCAPS_CONTINUOUSRATE
     DSCAPS_SECONDARY16BIT EAX_PRESET_AUDITORIUM EAX_PRESET_LIVINGROOM
     EAX_PRESET_PADDEDCELL EAX_PRESET_PARKINGLOT EAX_PRESET_UNDERWATER */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case '0':
    if (memEQ(name, "BASS_FX_PHASE_NEG_18", 20)) {
    /*                                   0      */
#ifdef BASS_FX_PHASE_NEG_180
      *iv_return = BASS_FX_PHASE_NEG_180;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "BASS_CTYPE_STREAM_MP", 20)) {
    /*                                   1      */
#ifdef BASS_CTYPE_STREAM_MP1
      *iv_return = BASS_CTYPE_STREAM_MP1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "BASS_CTYPE_STREAM_MP", 20)) {
    /*                                   2      */
#ifdef BASS_CTYPE_STREAM_MP2
      *iv_return = BASS_CTYPE_STREAM_MP2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "BASS_CTYPE_STREAM_MP", 20)) {
    /*                                   3      */
#ifdef BASS_CTYPE_STREAM_MP3
      *iv_return = BASS_CTYPE_STREAM_MP3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_FILEPOS_DOWNLOA", 20)) {
    /*                                   D      */
#ifdef BASS_FILEPOS_DOWNLOAD
      *iv_return = BASS_FILEPOS_DOWNLOAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_INPUT_TYPE_PHON", 20)) {
    /*                                   E      */
#ifdef BASS_INPUT_TYPE_PHONE
      *iv_return = BASS_INPUT_TYPE_PHONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DSCAPS_CONTINUOUSRAT", 20)) {
    /*                                   E      */
#ifdef DSCAPS_CONTINUOUSRATE
      *iv_return = DSCAPS_CONTINUOUSRATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "BASS_INPUT_TYPE_UNDE", 20)) {
    /*                                   F      */
#ifdef BASS_INPUT_TYPE_UNDEF
      *iv_return = BASS_INPUT_TYPE_UNDEF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "BASS_CTYPE_STREAM_OG", 20)) {
    /*                                   G      */
#ifdef BASS_CTYPE_STREAM_OGG
      *iv_return = BASS_CTYPE_STREAM_OGG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "BASS_INPUT_TYPE_SYNT", 20)) {
    /*                                   H      */
#ifdef BASS_INPUT_TYPE_SYNTH
      *iv_return = BASS_INPUT_TYPE_SYNTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_CONFIG_CURVE_VO", 20)) {
    /*                                   L      */
#ifdef BASS_CONFIG_CURVE_VOL
      *iv_return = BASS_CONFIG_CURVE_VOL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_PADDEDCEL", 20)) {
    /*                                   L      */
#ifdef EAX_PRESET_PADDEDCELL
      *iv_return = EAX_PRESET_PADDEDCELL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "EAX_PRESET_AUDITORIU", 20)) {
    /*                                   M      */
#ifdef EAX_PRESET_AUDITORIUM
      *iv_return = EAX_PRESET_AUDITORIUM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_LIVINGROO", 20)) {
    /*                                   M      */
#ifdef EAX_PRESET_LIVINGROOM
      *iv_return = EAX_PRESET_LIVINGROOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_CONFIG_CURVE_PA", 20)) {
    /*                                   N      */
#ifdef BASS_CONFIG_CURVE_PAN
      *iv_return = BASS_CONFIG_CURVE_PAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EAX_PRESET_UNDERWATE", 20)) {
    /*                                   R      */
#ifdef EAX_PRESET_UNDERWATER
      *iv_return = EAX_PRESET_UNDERWATER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BASS_SAMPLE_OVER_DIS", 20)) {
    /*                                   T      */
#ifdef BASS_SAMPLE_OVER_DIST
      *iv_return = BASS_SAMPLE_OVER_DIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_REARLEF", 20)) {
    /*                                   T      */
#ifdef BASS_SPEAKER_REARLEFT
      *iv_return = BASS_SPEAKER_REARLEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DSCAPS_SECONDARY16BI", 20)) {
    /*                                   T      */
#ifdef DSCAPS_SECONDARY16BIT
      *iv_return = DSCAPS_SECONDARY16BIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EAX_PRESET_PARKINGLO", 20)) {
    /*                                   T      */
#ifdef EAX_PRESET_PARKINGLOT
      *iv_return = EAX_PRESET_PARKINGLOT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "BASS_CTYPE_STREAM_WA", 20)) {
    /*                                   V      */
#ifdef BASS_CTYPE_STREAM_WAV
      *iv_return = BASS_CTYPE_STREAM_WAV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_CONFIG_GVOL_MUSIC BASS_CONFIG_NET_BUFFER BASS_DATA_FFT_NOWINDOW
     BASS_INPUT_TYPE_ANALOG BASS_SPEAKER_FRONTLEFT BASS_SPEAKER_REAR2LEFT
     BASS_SPEAKER_REARRIGHT DSCAPS_SECONDARYSTEREO EAX_PRESET_CONCERTHALL */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'A':
    if (memEQ(name, "EAX_PRESET_CONCERTHALL", 22)) {
    /*                                  ^         */
#ifdef EAX_PRESET_CONCERTHALL
      *iv_return = EAX_PRESET_CONCERTHALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BASS_DATA_FFT_NOWINDOW", 22)) {
    /*                                  ^         */
#ifdef BASS_DATA_FFT_NOWINDOW
      *iv_return = BASS_DATA_FFT_NOWINDOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BASS_SPEAKER_FRONTLEFT", 22)) {
    /*                                  ^         */
#ifdef BASS_SPEAKER_FRONTLEFT
      *iv_return = BASS_SPEAKER_FRONTLEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_SPEAKER_REAR2LEFT", 22)) {
    /*                                  ^         */
#ifdef BASS_SPEAKER_REAR2LEFT
      *iv_return = BASS_SPEAKER_REAR2LEFT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "BASS_CONFIG_NET_BUFFER", 22)) {
    /*                                  ^         */
#ifdef BASS_CONFIG_NET_BUFFER
      *iv_return = BASS_CONFIG_NET_BUFFER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "BASS_SPEAKER_REARRIGHT", 22)) {
    /*                                  ^         */
#ifdef BASS_SPEAKER_REARRIGHT
      *iv_return = BASS_SPEAKER_REARRIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BASS_INPUT_TYPE_ANALOG", 22)) {
    /*                                  ^         */
#ifdef BASS_INPUT_TYPE_ANALOG
      *iv_return = BASS_INPUT_TYPE_ANALOG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DSCAPS_SECONDARYSTEREO", 22)) {
    /*                                  ^         */
#ifdef DSCAPS_SECONDARYSTEREO
      *iv_return = DSCAPS_SECONDARYSTEREO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_CONFIG_GVOL_MUSIC", 22)) {
    /*                                  ^         */
#ifdef BASS_CONFIG_GVOL_MUSIC
      *iv_return = BASS_CONFIG_GVOL_MUSIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_CONFIG_3DALGORITHM BASS_CONFIG_GVOL_SAMPLE BASS_CONFIG_GVOL_STREAM
     BASS_CONFIG_NET_TIMEOUT BASS_INPUT_TYPE_DIGITAL BASS_INPUT_TYPE_SPEAKER
     BASS_SPEAKER_FRONTRIGHT BASS_SPEAKER_REAR2RIGHT */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'D':
    if (memEQ(name, "BASS_INPUT_TYPE_DIGITAL", 23)) {
    /*                               ^             */
#ifdef BASS_INPUT_TYPE_DIGITAL
      *iv_return = BASS_INPUT_TYPE_DIGITAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "BASS_CONFIG_3DALGORITHM", 23)) {
    /*                               ^             */
#ifdef BASS_CONFIG_3DALGORITHM
      *iv_return = BASS_CONFIG_3DALGORITHM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BASS_SPEAKER_FRONTRIGHT", 23)) {
    /*                               ^             */
#ifdef BASS_SPEAKER_FRONTRIGHT
      *iv_return = BASS_SPEAKER_FRONTRIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "BASS_SPEAKER_REAR2RIGHT", 23)) {
    /*                               ^             */
#ifdef BASS_SPEAKER_REAR2RIGHT
      *iv_return = BASS_SPEAKER_REAR2RIGHT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASS_INPUT_TYPE_SPEAKER", 23)) {
    /*                               ^             */
#ifdef BASS_INPUT_TYPE_SPEAKER
      *iv_return = BASS_INPUT_TYPE_SPEAKER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BASS_CONFIG_NET_TIMEOUT", 23)) {
    /*                               ^             */
#ifdef BASS_CONFIG_NET_TIMEOUT
      *iv_return = BASS_CONFIG_NET_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "BASS_CONFIG_GVOL_SAMPLE", 23)) {
    /*                               ^             */
#ifdef BASS_CONFIG_GVOL_SAMPLE
      *iv_return = BASS_CONFIG_GVOL_SAMPLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BASS_CONFIG_GVOL_STREAM", 23)) {
    /*                               ^             */
#ifdef BASS_CONFIG_GVOL_STREAM
      *iv_return = BASS_CONFIG_GVOL_STREAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASS_CONFIG_UPDATEPERIOD BASS_DATA_FFT_INDIVIDUAL EAX_PRESET_STONECORRIDOR
     */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "BASS_DATA_FFT_INDIVIDUAL", 24)) {
    /*                       ^                      */
#ifdef BASS_DATA_FFT_INDIVIDUAL
      *iv_return = BASS_DATA_FFT_INDIVIDUAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EAX_PRESET_STONECORRIDOR", 24)) {
    /*                       ^                      */
#ifdef EAX_PRESET_STONECORRIDOR
      *iv_return = EAX_PRESET_STONECORRIDOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "BASS_CONFIG_UPDATEPERIOD", 24)) {
    /*                       ^                      */
#ifdef BASS_CONFIG_UPDATEPERIOD
      *iv_return = BASS_CONFIG_UPDATEPERIOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!C:\Perl\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(BASS_3DALG_DEFAULT BASS_3DALG_FULL BASS_3DALG_LIGHT
	       BASS_3DALG_OFF BASS_3DMODE_NORMAL BASS_3DMODE_OFF
	       BASS_3DMODE_RELATIVE BASS_ACTIVE_PAUSED BASS_ACTIVE_PLAYING
	       BASS_ACTIVE_STALLED BASS_ACTIVE_STOPPED BASS_CONFIG_3DALGORITHM
	       BASS_CONFIG_BUFFER BASS_CONFIG_CURVE_PAN BASS_CONFIG_CURVE_VOL
	       BASS_CONFIG_FLOATDSP BASS_CONFIG_GVOL_MUSIC
	       BASS_CONFIG_GVOL_SAMPLE BASS_CONFIG_GVOL_STREAM
	       BASS_CONFIG_MAXVOL BASS_CONFIG_NET_BUFFER
	       BASS_CONFIG_NET_TIMEOUT BASS_CONFIG_UPDATEPERIOD
	       BASS_CTYPE_MUSIC_IT BASS_CTYPE_MUSIC_MO3 BASS_CTYPE_MUSIC_MOD
	       BASS_CTYPE_MUSIC_MTM BASS_CTYPE_MUSIC_S3M BASS_CTYPE_MUSIC_XM
	       BASS_CTYPE_RECORD BASS_CTYPE_SAMPLE BASS_CTYPE_STREAM
	       BASS_CTYPE_STREAM_MP1 BASS_CTYPE_STREAM_MP2
	       BASS_CTYPE_STREAM_MP3 BASS_CTYPE_STREAM_OGG
	       BASS_CTYPE_STREAM_WAV BASS_DATA_AVAILABLE BASS_DATA_FFT1024
	       BASS_DATA_FFT2048 BASS_DATA_FFT4096 BASS_DATA_FFT512
	       BASS_DATA_FFT_INDIVIDUAL BASS_DATA_FFT_NOWINDOW BASS_DEVICE_3D
	       BASS_DEVICE_8BITS BASS_DEVICE_LATENCY BASS_DEVICE_MONO
	       BASS_DEVICE_SPEAKERS BASS_ERROR_ALREADY BASS_ERROR_BUFLOST
	       BASS_ERROR_CREATE BASS_ERROR_DECODE BASS_ERROR_DEVICE
	       BASS_ERROR_DRIVER BASS_ERROR_DX BASS_ERROR_EMPTY
	       BASS_ERROR_FILEFORM BASS_ERROR_FILEOPEN BASS_ERROR_FORMAT
	       BASS_ERROR_FREQ BASS_ERROR_HANDLE BASS_ERROR_ILLPARAM
	       BASS_ERROR_ILLTYPE BASS_ERROR_INIT BASS_ERROR_MEM
	       BASS_ERROR_NO3D BASS_ERROR_NOCHAN BASS_ERROR_NOEAX
	       BASS_ERROR_NOFX BASS_ERROR_NOHW BASS_ERROR_NONET
	       BASS_ERROR_NOPAUSE BASS_ERROR_NOPLAY BASS_ERROR_NOTAVAIL
	       BASS_ERROR_NOTFILE BASS_ERROR_PLAYING BASS_ERROR_POSITION
	       BASS_ERROR_SPEAKER BASS_ERROR_START BASS_ERROR_TIMEOUT
	       BASS_ERROR_UNKNOWN BASS_FILEPOS_DECODE BASS_FILEPOS_DOWNLOAD
	       BASS_FILEPOS_END BASS_FILE_CLOSE BASS_FILE_LEN BASS_FILE_QUERY
	       BASS_FILE_READ BASS_FILE_SEEK BASS_FX_PHASE_180 BASS_FX_PHASE_90
	       BASS_FX_PHASE_NEG_180 BASS_FX_PHASE_NEG_90 BASS_FX_PHASE_ZERO
	       BASS_INPUT_LEVEL BASS_INPUT_OFF BASS_INPUT_ON
	       BASS_INPUT_TYPE_ANALOG BASS_INPUT_TYPE_AUX BASS_INPUT_TYPE_CD
	       BASS_INPUT_TYPE_DIGITAL BASS_INPUT_TYPE_LINE
	       BASS_INPUT_TYPE_MASK BASS_INPUT_TYPE_MIC BASS_INPUT_TYPE_PHONE
	       BASS_INPUT_TYPE_SPEAKER BASS_INPUT_TYPE_SYNTH
	       BASS_INPUT_TYPE_UNDEF BASS_INPUT_TYPE_WAVE BASS_MP3_SETPOS
	       BASS_MUSIC_3D BASS_MUSIC_AUTOFREE BASS_MUSIC_CALCLEN
	       BASS_MUSIC_DECODE BASS_MUSIC_FLOAT BASS_MUSIC_FT2MOD
	       BASS_MUSIC_FX BASS_MUSIC_LOOP BASS_MUSIC_MONO
	       BASS_MUSIC_NONINTER BASS_MUSIC_NOSAMPLE BASS_MUSIC_POSRESET
	       BASS_MUSIC_PT1MOD BASS_MUSIC_RAMP BASS_MUSIC_RAMPS
	       BASS_MUSIC_STOPBACK BASS_MUSIC_SURROUND BASS_MUSIC_SURROUND2
	       BASS_OBJECT_DS BASS_OBJECT_DS3DL BASS_OK BASS_RECORD_PAUSE
	       BASS_SAMPLE_3D BASS_SAMPLE_8BITS BASS_SAMPLE_FLOAT
	       BASS_SAMPLE_FX BASS_SAMPLE_LOOP BASS_SAMPLE_MONO
	       BASS_SAMPLE_MUTEMAX BASS_SAMPLE_OVER_DIST BASS_SAMPLE_OVER_POS
	       BASS_SAMPLE_OVER_VOL BASS_SAMPLE_SOFTWARE BASS_SAMPLE_VAM
	       BASS_SLIDE_FREQ BASS_SLIDE_PAN BASS_SLIDE_VOL
	       BASS_SPEAKER_CENLFE BASS_SPEAKER_CENTER BASS_SPEAKER_FRONT
	       BASS_SPEAKER_FRONTLEFT BASS_SPEAKER_FRONTRIGHT BASS_SPEAKER_LEFT
	       BASS_SPEAKER_LFE BASS_SPEAKER_REAR BASS_SPEAKER_REAR2
	       BASS_SPEAKER_REAR2LEFT BASS_SPEAKER_REAR2RIGHT
	       BASS_SPEAKER_REARLEFT BASS_SPEAKER_REARRIGHT BASS_SPEAKER_RIGHT
	       BASS_STREAMPROC_END BASS_STREAM_AUTOFREE BASS_STREAM_BLOCK
	       BASS_STREAM_DECODE BASS_STREAM_META BASS_STREAM_RESTRATE
	       BASS_SYNC_DOWNLOAD BASS_SYNC_END BASS_SYNC_MESSAGE
	       BASS_SYNC_META BASS_SYNC_MIXTIME BASS_SYNC_MUSICFX
	       BASS_SYNC_MUSICINST BASS_SYNC_MUSICPOS BASS_SYNC_ONETIME
	       BASS_SYNC_POS BASS_SYNC_SLIDE BASS_SYNC_STALL BASS_TAG_HTTP
	       BASS_TAG_ICY BASS_TAG_ID3 BASS_TAG_ID3V2 BASS_TAG_META
	       BASS_TAG_OGG BASS_UNICODE BASS_VAM_HARDWARE BASS_VAM_SOFTWARE
	       BASS_VAM_TERM_DIST BASS_VAM_TERM_PRIO BASS_VAM_TERM_TIME
	       DSCAPS_CERTIFIED DSCAPS_CONTINUOUSRATE DSCAPS_EMULDRIVER
	       DSCAPS_SECONDARY16BIT DSCAPS_SECONDARY8BIT DSCAPS_SECONDARYMONO
	       DSCAPS_SECONDARYSTEREO DSCCAPS_CERTIFIED DSCCAPS_EMULDRIVER
	       EAX_PRESET_ALLEY EAX_PRESET_ARENA EAX_PRESET_AUDITORIUM
	       EAX_PRESET_BATHROOM EAX_PRESET_CARPETEDHALLWAY EAX_PRESET_CAVE
	       EAX_PRESET_CITY EAX_PRESET_CONCERTHALL EAX_PRESET_DIZZY
	       EAX_PRESET_DRUGGED EAX_PRESET_FOREST EAX_PRESET_GENERIC
	       EAX_PRESET_HALLWAY EAX_PRESET_HANGAR EAX_PRESET_LIVINGROOM
	       EAX_PRESET_MOUNTAINS EAX_PRESET_PADDEDCELL EAX_PRESET_PARKINGLOT
	       EAX_PRESET_PLAIN EAX_PRESET_PSYCHOTIC EAX_PRESET_QUARRY
	       EAX_PRESET_ROOM EAX_PRESET_SEWERPIPE EAX_PRESET_STONECORRIDOR
	       EAX_PRESET_STONEROOM EAX_PRESET_UNDERWATER WAVE_FORMAT_1M08
	       WAVE_FORMAT_1M16 WAVE_FORMAT_1S08 WAVE_FORMAT_1S16
	       WAVE_FORMAT_2M08 WAVE_FORMAT_2M16 WAVE_FORMAT_2S08
	       WAVE_FORMAT_2S16 WAVE_FORMAT_4M08 WAVE_FORMAT_4M16
	       WAVE_FORMAT_4S08 WAVE_FORMAT_4S16));

print constant_types(); # macro defs
foreach (C_constant ("Audio::BASSXS", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Audio::BASSXS", $types);
__END__
   */

  switch (len) {
  case 7:
    if (memEQ(name, "BASS_OK", 7)) {
#ifdef BASS_OK
      *iv_return = BASS_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 26:
    if (memEQ(name, "EAX_PRESET_CARPETEDHALLWAY", 26)) {
#ifdef EAX_PRESET_CARPETEDHALLWAY
      *iv_return = EAX_PRESET_CARPETEDHALLWAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

