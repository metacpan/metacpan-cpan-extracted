#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <dvdread/dvd_reader.h>
#include <dvdread/ifo_read.h>

#define FIRST_AC3_AID 128
#define FIRST_DTS_AID 136
#define FIRST_MPG_AID 0
#define FIRST_PCM_AID 160

#define CROAK_NOT_VGM "This DVD::Read::Dvd::Ifo does contain VMGI, not from title 0 ?"
#define CROAK_NOT_VTS "This DVD::Read::Dvd::Ifo does contain VTSI, from title 0 ?"

typedef struct {
    SV * sv_ifo_handle;
    pgc_t * pgc;
    int pgcid;
} sv_pgc_t;

typedef struct {
    SV * sv_ifo_handle;
    int cellid;
    cell_playback_t * cell;
} sv_cell_playback_t;
