#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cdaudio.h"
#include "cddb_lookup.h"

typedef struct disc_info   * Audio__CD__Info;
typedef struct track_info  * Audio__CD__Info__Track;
typedef struct disc_data   * Audio__CD__Data;
typedef struct track_data  * Audio__CD__Track;
typedef struct disc_volume * Audio__CD__Volume;
typedef struct __volume    * Audio__CD__VolumeRL;

typedef int Audio__CD;
typedef int Audio__CDDB;

#define CD_Info_present(info) info->disc_present
#define CD_Info_mode(info) info->disc_mode
#define CD_Info_current_frame(info) info->disc_current_frame
#define CD_Info_current_track(info) info->disc_current_track
#define CD_Info_first_track(info) info->disc_first_track
#define CD_Info_total_tracks(info) info->disc_total_tracks
#define CD_Info_timeval(timeval) \
SP -= items; \
XPUSHs(sv_2mortal(newSViv(timeval.minutes))); \
XPUSHs(sv_2mortal(newSViv(timeval.seconds))); \
PUTBACK; return

#define CD_Info_track_time(info) \
CD_Info_timeval(info->disc_track_time)
#define CD_Info_time(info) \
CD_Info_timeval(info->disc_time)
#define CD_Info_length(info) \
CD_Info_timeval(info->disc_length)

#define CD_Info_Track_length(tinfo)     CD_Info_timeval(tinfo->track_length)
#define CD_Info_Track_pos(tinfo)        CD_Info_timeval(tinfo->track_pos)
#define CD_Info_Track_type(tinfo)       tinfo->track_type
#define CD_Info_Track_is_audio(tinfo) \
(tinfo->track_type == CDAUDIO_TRACK_AUDIO)
#define CD_Info_Track_is_data(tinfo) \
(tinfo->track_type == CDAUDIO_TRACK_DATA)

#define CD_Data_title(data) data->data_title
#define CD_Data_artist(data) data->data_artist
#define CD_Data_extended(data) data->data_extended
#define CD_Data_genre(data) cddb_genre(data->data_genre)

#define CD_Track_name(track) track->track_name
#define CD_Track_artist(track) track->track_artist
#define CD_Track_extended(track) track->track_extended

#define CD_Volume_front(vol) &vol->vol_front
#define CD_Volume_back(vol) &vol->vol_back
#define CD_VolumeRL_right(volrl, val) \
(val >= 0 ? volrl->right = val : volrl->right)
#define CD_VolumeRL_left(volrl, val) \
(val >= 0 ? volrl->left = val : volrl->left)

static Audio__CD cd_init(SV *sv_class, char *device)
{
    int id = cd_init_device(device);
    if (id < 0) {
	return 0;
    }
    return id;
}

static SV *CD_Data_track_new(struct track_data *td)
{
    SV *sv = newSV(0);
#if 0
    struct track_data *new_td = (struct track_data *)safemalloc(sizeof(*new_td));
    Copy(td, new_td, 1, struct track_data);
#endif
    sv_setref_pv(sv, "Audio::CD::Track", (void*)td);
    return sv;
}


static SV *CD_Info_track_new(struct track_info *ti)
{
    SV *sv = newSV(0);
    sv_setref_pv(sv, "Audio::CD::Info::Track", (void*)ti);
    return sv;
}


static void boot_Audio__CD_constants(void)
{
    HV *stash = gv_stashpv("Audio::CD", TRUE);
    newCONSTSUB(stash, "PLAYING", newSViv(CDAUDIO_PLAYING));
    newCONSTSUB(stash, "PAUSED", newSViv(CDAUDIO_PAUSED));
    newCONSTSUB(stash, "COMPLETED", newSViv(CDAUDIO_COMPLETED));
    newCONSTSUB(stash, "NOSTATUS", newSViv(CDAUDIO_NOSTATUS));
    newCONSTSUB(stash, "TRACK_AUDIO", newSViv(CDAUDIO_TRACK_AUDIO));
    newCONSTSUB(stash, "TRACK_DATA", newSViv(CDAUDIO_TRACK_DATA));
}

/* XXX */
static int inexact_select_func(void)
{
    return 1;
}

MODULE = Audio::CD   PACKAGE = Audio::CD   PREFIX = cd_

BOOT:
    boot_Audio__CD_constants();
    cddb_inexact_selection_set(inexact_select_func);

Audio::CD
cd_init(sv_class, device="/dev/cdrom")
    SV *sv_class
    char *device

void
DESTROY(cd_desc)
    Audio::CD cd_desc

    CODE:
    close(cd_desc);

Audio::CDDB
cddb(cd_desc)
    Audio::CD cd_desc

    CODE:
    RETVAL = cd_desc;

    OUTPUT:
    RETVAL

int
cd_play(cd_desc, track=1)
    Audio::CD cd_desc
    int track

int
cd_stop(cd_desc)
    Audio::CD cd_desc

int
cd_pause(cd_desc)
    Audio::CD cd_desc

int
cd_resume(cd_desc)
    Audio::CD cd_desc

int
cd_eject(cd_desc)
    Audio::CD cd_desc

int
cd_close(cd_desc)
    Audio::CD cd_desc

Audio::CD::Info
cd_stat(cd_desc)
    Audio::CD cd_desc

    CODE:
    RETVAL = (Audio__CD__Info)safemalloc(sizeof(*RETVAL));
    cd_stat(cd_desc, RETVAL);

    OUTPUT:
    RETVAL

int
cd_play_frames(cd_desc, startframe, endframe)
    Audio::CD cd_desc
    int startframe
    int endframe

int
cd_play_track_pos(cd_desc, starttrack, endtrack, startpos)
    Audio::CD cd_desc
    int starttrack
    int endtrack
    int startpos

int
cd_play_track(cd_desc, starttrack, endtrack)
    Audio::CD cd_desc
    int starttrack
    int endtrack

int
cd_play_pos(cd_desc, track, startpos)
    Audio::CD cd_desc
    int track
    int startpos

int
cd_track_advance(cd_desc, endtrack, minutes, seconds=0)
    Audio::CD cd_desc
    int endtrack
    int minutes
    int seconds

    PREINIT:
    struct disc_timeval time;

    CODE:
    time.minutes = minutes;
    time.seconds = seconds;
    RETVAL = cd_track_advance(cd_desc, endtrack, time);

    OUTPUT:
    RETVAL

int
cd_advance(cd_desc, minutes, seconds=0)
    Audio::CD cd_desc
    int minutes
    int seconds

    PREINIT:
    struct disc_timeval time;

    CODE:
    time.minutes = minutes;
    time.seconds = seconds;
    RETVAL = cd_advance(cd_desc, time);

    OUTPUT:
    RETVAL

Audio::CD::Volume
cd_get_volume(cd_desc)
    Audio::CD cd_desc

    CODE:
    RETVAL = (struct disc_volume *)safemalloc(sizeof(*RETVAL));
    cd_get_volume(cd_desc, RETVAL);

    OUTPUT:
    RETVAL

int
cd_set_volume(cd_desc, vol)
    Audio::CD cd_desc
    Audio::CD::Volume vol

    CODE:
    RETVAL = cd_set_volume(cd_desc, *vol);

    OUTPUT:
    RETVAL
    
MODULE = Audio::CD   PACKAGE = Audio::CD::Info   PREFIX = CD_Info_

int
CD_Info_present(info)
   Audio::CD::Info info
 
int
CD_Info_mode(info)
   Audio::CD::Info info

int
CD_Info_total_tracks(info)
   Audio::CD::Info info

void
CD_Info_track_time(info)
   Audio::CD::Info info

void
CD_Info_time(info)
   Audio::CD::Info info

void
CD_Info_length(info)
   Audio::CD::Info info

AV *
CD_Info_tracks(info)
   Audio::CD::Info info

   PREINIT:
   int track;

   CODE:
   RETVAL = newAV();
   for(track = 0; track < info->disc_total_tracks; track++) {
       av_push(RETVAL, CD_Info_track_new(&info->disc_track[track]));
   }

   OUTPUT:
   RETVAL

void
DESTROY(info)
   Audio::CD::Info info

   CODE:
   safefree(info);

MODULE = Audio::CD   PACKAGE = Audio::CD::Info::Track   PREFIX = CD_Info_Track_

void
CD_Info_Track_length(tinfo)
   Audio::CD::Info::Track tinfo

void
CD_Info_Track_pos(tinfo)
   Audio::CD::Info::Track tinfo

int
CD_Info_Track_type(tinfo)
   Audio::CD::Info::Track tinfo

int
CD_Info_Track_is_audio(tinfo)
   Audio::CD::Info::Track tinfo

int
CD_Info_Track_is_data(tinfo)
   Audio::CD::Info::Track tinfo


MODULE = Audio::CD   PACKAGE = Audio::CD::Data   PREFIX = CD_Data_

char *
CD_Data_title(data)
   Audio::CD::Data data

char *
CD_Data_artist(data)
   Audio::CD::Data data

char *
CD_Data_extended(data)
   Audio::CD::Data data

char *
CD_Data_genre(data)
   Audio::CD::Data data

AV *
CD_Data_tracks(data, disc)
   Audio::CD::Data data
   Audio::CD::Info disc

   PREINIT:
   int track;

   CODE:
   RETVAL = newAV();
   for(track = 0; track < disc->disc_total_tracks; track++) {
       av_push(RETVAL, CD_Data_track_new(&data->data_track[track]));
   }

   OUTPUT:
   RETVAL

void
DESTROY(data)
   Audio::CD::Data data

   CODE:
   safefree(data);

MODULE = Audio::CD   PACKAGE = Audio::CD::Track   PREFIX = CD_Track_

char *
CD_Track_name(track)
    Audio::CD::Track track

char *
CD_Track_artist(track)
    Audio::CD::Track track

char *
CD_Track_extended(track)
    Audio::CD::Track track

MODULE = Audio::CD   PACKAGE = Audio::CDDB   PREFIX = cddb_

PROTOTYPES: disable

void
cddb_verbose(sv, flag)
    SV *sv
    int flag

unsigned long
cddb_discid(h)
    Audio::CDDB h

Audio::CD::Data
cddb_lookup(cd_desc)
    Audio::CDDB cd_desc

    CODE:
    RETVAL = (Audio__CD__Data)safemalloc(sizeof(*RETVAL));
    cddb_lookup(cd_desc, RETVAL);

    OUTPUT:
    RETVAL

MODULE = Audio::CD   PACKAGE = Audio::CD::Volume   PREFIX = CD_Volume_

void
DESTROY(vol)
   Audio::CD::Volume vol

   CODE:
   safefree(vol);

Audio::CD::VolumeRL
CD_Volume_front(vol)
   Audio::CD::Volume vol

Audio::CD::VolumeRL
CD_Volume_back(vol)
   Audio::CD::Volume vol

MODULE = Audio::CD   PACKAGE = Audio::CD::VolumeRL   PREFIX = CD_VolumeRL_

int
CD_VolumeRL_left(volrl, val=-1)
   Audio::CD::VolumeRL volrl
   int val

int
CD_VolumeRL_right(volrl, val=-1)
   Audio::CD::VolumeRL volrl
   int val
