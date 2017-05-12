#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <dvdread/dvd_reader.h>
#include <dvdread/ifo_read.h>

#include "Read.h"

int   audio_id[7]     = {0x80, 0, 0xC0, 0xC0, 0xA0, 0, 0x88};

MODULE = DVD::Read		PACKAGE = DVD::Read::Dvd

ssize_t
BLOCK_SIZE()
    CODE:
    RETVAL=DVD_VIDEO_LB_LEN;
    OUTPUT:
    RETVAL

void
_new(class, device)
    char * class
    char * device
    PREINIT:
    dvd_reader_t * dvd;
    PPCODE:
    if ((dvd = DVDOpen(device)) != NULL)
       XPUSHs(sv_2mortal(sv_setref_pv(newSVpv("", 0), class, (void *)dvd)));
    else
        XSRETURN_UNDEF; 

char *
volid(dvd)
    dvd_reader_t * dvd
    PREINIT:
        char * volid = malloc(sizeof(char) * 33);
    PPCODE:
        if (DVDUDFVolumeInfo(dvd, volid, sizeof(volid), NULL, 0) >= 0 ||
            DVDISOVolumeInfo(dvd, volid, sizeof(volid), NULL, 0) >= 0)
            XPUSHs(sv_2mortal(newSVpv(volid, 0)));
        free(volid);
        
void
DESTROY(dvd)
    dvd_reader_t * dvd
    CODE:
    DVDClose(dvd);

MODULE = DVD::Read      PACKAGE = DVD::Read::Dvd::File

ssize_t
BLOCK_SIZE()
    CODE:
    RETVAL=DVD_VIDEO_LB_LEN;
    OUTPUT:
    RETVAL

void
new(class, dvd, num, type)
    char * class
    dvd_reader_t * dvd
    unsigned int num
    char * type
    PREINIT:
    dvd_read_domain_t domain = -1;
    dvd_file_t * dvd_file;
    char * ttype[] = { "IFO", "BUP", "MENU", "VOB", NULL };
    int i;
    PPCODE:
    for (i=0; ttype[i] != NULL; i++)
        if (!strcmp(type, ttype[i]))
            domain = i;

    if (domain < 0)
        croak("Wrong file type");
        
    if ((dvd_file = DVDOpenFile(dvd, num, domain)) != NULL) {
        XPUSHs(sv_2mortal(sv_setref_pv(newSVpv("", 0), class, (void *)dvd_file)));
    } else {
        XSRETURN_UNDEF;
    }

void
DESTROY(dvd_file)
    dvd_file_t * dvd_file
    CODE:
    DVDCloseFile(dvd_file);

ssize_t
size(dvd_file)
    dvd_file_t * dvd_file
    CODE:
    RETVAL=DVDFileSize(dvd_file);
    OUTPUT:
    RETVAL

void
readblock(dvd_file, offset, size)
    dvd_file_t * dvd_file
    int offset
    ssize_t size
    PREINIT:
    ssize_t res;
    unsigned char * data;
    PPCODE:
    data = malloc(DVD_VIDEO_LB_LEN * size);
    if ((res = DVDReadBlocks(dvd_file, offset, size, data)) >= 0) {
        if (GIMME_V == G_ARRAY) /* in array context,
                               * return the nb of block read */
        XPUSHs(sv_2mortal(newSViv(res)));
        XPUSHs(sv_2mortal(newSVpv(data, DVD_VIDEO_LB_LEN * res)));
    }
    if(data) free(data); data=NULL;

MODULE = DVD::Read		PACKAGE = DVD::Read::Dvd::Ifo

void
new(class, dvd, titleno)
    char * class
    dvd_reader_t * dvd
    int titleno
    PREINIT:
    ifo_handle_t * ifo;
    PPCODE:
    if ((ifo = ifoOpen(dvd, titleno)))
        XPUSHs(sv_2mortal(sv_setref_pv(newSVpv("", 0), class, (void *)ifo)));
    else
        XSRETURN_UNDEF;

void
DESTROY(ifo)
    ifo_handle_t * ifo
    CODE:
    ifoClose(ifo);

MODULE = DVD::Read		PACKAGE = DVD::Read::Dvd::Ifo::Vmg

void
vmg_identifier(ifo)
    ifo_handle_t * ifo
    PPCODE:
    if (ifo->vmgi_mat) {
        XPUSHs(sv_2mortal(newSVpv(ifo->vmgi_mat->vmg_identifier, 12)));
    } else
        croak(CROAK_NOT_VGM);

void
titles_count(ifo)
    ifo_handle_t * ifo
    PPCODE:
    if (ifo->tt_srpt)
        XPUSHs(sv_2mortal(newSViv(ifo->tt_srpt->nr_of_srpts)));
    else
        croak(CROAK_NOT_VGM);

void
title_chapters_count(ifo, titleno)
    ifo_handle_t * ifo
    int titleno
    PPCODE:
    if (ifo->tt_srpt) {
        if(titleno > 0 && titleno <= ifo->tt_srpt->nr_of_srpts)
        XPUSHs(sv_2mortal(newSViv(ifo->tt_srpt->title[titleno -1].nr_of_ptts)));
    } else
        croak(CROAK_NOT_VGM);

void
title_angles_count(ifo, titleno)
    ifo_handle_t * ifo
    int titleno
    PPCODE:
    if (ifo->tt_srpt) {
        if (titleno > 0 && titleno <= ifo->tt_srpt->nr_of_srpts)
        XPUSHs(sv_2mortal(newSViv(ifo->tt_srpt->title[titleno -1].nr_of_angles)));
    } else
        croak(CROAK_NOT_VGM);

void
title_nr(ifo, titleno)
    ifo_handle_t * ifo
    int titleno
    PPCODE:
    if (ifo->tt_srpt) {
        if (titleno > 0 && titleno <= ifo->tt_srpt->nr_of_srpts)
        XPUSHs(sv_2mortal(newSViv(ifo->tt_srpt->title[titleno -1].title_set_nr)));
    } else
        croak(CROAK_NOT_VGM);

void
title_ttn(ifo, titleno)
    ifo_handle_t * ifo
    int titleno
    PPCODE:
    if (ifo->tt_srpt) {
        if (titleno > 0 && titleno <= ifo->tt_srpt->nr_of_srpts)
        XPUSHs(sv_2mortal(newSViv(ifo->tt_srpt->title[titleno -1].vts_ttn)));
    } else
        croak(CROAK_NOT_VGM);

MODULE = DVD::Read		PACKAGE = DVD::Read::Dvd::Ifo::Vts

void
vts_ttn_count(ifo)
    ifo_handle_t * ifo
    PPCODE:
    if (ifo->vts_ptt_srpt)
        XPUSHs(sv_2mortal(newSViv(ifo->vts_ptt_srpt->nr_of_srpts)));
    else
        croak(CROAK_NOT_VTS);

void
vts_identifier(ifo)
    ifo_handle_t * ifo
    PPCODE:
    if (ifo->vtsi_mat)
        XPUSHs(sv_2mortal(newSVpv(ifo->vtsi_mat->vts_identifier, 12)));
    else
        croak(CROAK_NOT_VTS);

void
vts_video_mpeg_version(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->mpeg_version)));
    }

void
vts_video_format(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->video_format)));
    }

void
vts_video_aspect_ratio(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->display_aspect_ratio)));
    }

void
vts_video_permitted_df(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->permitted_df)));
    }

void
vts_video_line21_cc_1(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->line21_cc_1)));
    }

void
vts_video_line21_cc_2(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->line21_cc_2)));
    }

void
vts_video_letterboxed(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->letterboxed)));
    }

void
vts_video_film_mode(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        attr = &ifo->vtsi_mat->vts_video_attr;
        XPUSHs(sv_2mortal(newSViv(attr->film_mode)));
    }

void
vts_video_size(ifo)
    ifo_handle_t * ifo
    PREINIT:
    video_attr_t *attr;
    PPCODE:
    if (ifo->vtsi_mat) {
        int height = 480;
        attr = &ifo->vtsi_mat->vts_video_attr;
        if(attr->video_format != 0)
          height = 576;
        switch(attr->picture_size) {
        case 0:
          XPUSHs(sv_2mortal(newSViv(720)));
          break;
        case 1:
          XPUSHs(sv_2mortal(newSViv(704)));
          break;
        case 2:
          XPUSHs(sv_2mortal(newSViv(352)));
          break;
        case 3:
          XPUSHs(sv_2mortal(newSViv(352)));
          height =  height/2;
          break;
        default:
          break;
        }
        XPUSHs(sv_2mortal(newSViv(height)));
    }

void
vts_audios(ifo)
    ifo_handle_t * ifo
    PREINIT:
    pgc_t *pgc = NULL;
    int i;
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else
    for (i = 0; i < ifo->vtsi_mat->nr_of_vts_audio_streams; i++) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[i];
        if(!(  a_attr->audio_format == 0
            && a_attr->multichannel_extension == 0
            && a_attr->lang_type == 0
            && a_attr->application_mode == 0
            && a_attr->quantization == 0
            && a_attr->sample_frequency == 0
            && a_attr->channels == 0
            && a_attr->lang_extension == 0
            && a_attr->unknown1 == 0
            && a_attr->unknown1 == 0))
            XPUSHs(sv_2mortal(newSViv(i)));
    }

void
vts_audio_language(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        if(a_attr->lang_type == 1) {
            char tmp[3] = "";
            tmp[0]=a_attr->lang_code>>8;
            tmp[1]=a_attr->lang_code&0xff;
            tmp[2]=0;
            XPUSHs(sv_2mortal(newSVpv(tmp, 0)));
        }
    }

void
vts_audio_format(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->audio_format)));
    }

void
vts_audio_id(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(audio_id[a_attr->audio_format])));
    }

void
vts_audio_channel(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->channels)));
    }

void
vts_audio_appmode(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->application_mode)));
    }

void
vts_audio_quantization(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->quantization)));
    }

void
vts_audio_frequency(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->sample_frequency)));
    }

void
vts_audio_lang_extension(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->lang_extension)));
    }

void
vts_audio_multichannel_extension(ifo, audiono)
    ifo_handle_t * ifo
    int audiono
    PREINIT:
    audio_attr_t   *a_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (audiono >= 0 && audiono < ifo->vtsi_mat->nr_of_vts_audio_streams) {
        a_attr = &ifo->vtsi_mat->vts_audio_attr[audiono];
        XPUSHs(sv_2mortal(newSViv(a_attr->multichannel_extension)));
    }


void
vts_subtitles(ifo)
    ifo_handle_t * ifo
    PREINIT:
    int i;
    subp_attr_t    *s_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else
    for (i = 0; i < ifo->vtsi_mat->nr_of_vts_subp_streams; i++) {
        s_attr = &ifo->vtsi_mat->vts_subp_attr[i];
        if (!(  s_attr->type == 0
             && s_attr->zero1 == 0
             && s_attr->lang_code == 0
             && s_attr->lang_extension == 0
             && s_attr->zero2 == 0))
            XPUSHs(sv_2mortal(newSViv(i)));
    }

void
vts_subtitle_lang_extension(ifo, subtitleno)
    ifo_handle_t * ifo
    int subtitleno
    PREINIT:
    subp_attr_t    *s_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (subtitleno >= 0 && subtitleno < ifo->vtsi_mat->nr_of_vts_subp_streams) {
        s_attr = &ifo->vtsi_mat->vts_subp_attr[subtitleno];
        XPUSHs(sv_2mortal(newSViv(s_attr->lang_extension)));
    }
        
void
vts_subtitle_language(ifo, subtitleno)
    ifo_handle_t * ifo
    int subtitleno
    PREINIT:
    subp_attr_t    *s_attr;
    PPCODE:
    if (!ifo->vtsi_mat)
        croak(CROAK_NOT_VTS);
    else if (subtitleno >= 0 && subtitleno < ifo->vtsi_mat->nr_of_vts_subp_streams) {
        s_attr = &ifo->vtsi_mat->vts_subp_attr[subtitleno];
        if(s_attr->type == 1) {
            char tmp[3] = "";
            tmp[0]=s_attr->lang_code>>8;
            tmp[1]=s_attr->lang_code&0xff;
            tmp[2]=0;
            XPUSHs(sv_2mortal(newSVpv(tmp, 0)));
        }
    }

# chapter discovering, woot

void
vts_chapters_count(ifo, ttn)
    ifo_handle_t * ifo
    int ttn
    PREINIT:
    vts_ptt_srpt_t * vts_ptt_srpt;
    PPCODE:
    vts_ptt_srpt = ifo->vts_ptt_srpt;
    if (!vts_ptt_srpt)
        croak(CROAK_NOT_VTS);
    else if (ttn > 0 && ttn <= vts_ptt_srpt->nr_of_srpts)
        XPUSHs(sv_2mortal(newSViv(vts_ptt_srpt->title[ttn - 1].nr_of_ptts)));

void
title_length(vts, ttn)
    ifo_handle_t * vts
    int ttn
    PREINIT:
    pgc_t *cur_pgc;
    int pgc_id;
    vts_ptt_srpt_t * vts_ptt_srpt;
    dvd_time_t     *dt;
    long ms, hour, minute, second;
    double fps;
    PPCODE:
    vts_ptt_srpt = vts->vts_ptt_srpt;
    if (!vts_ptt_srpt)
        croak(CROAK_NOT_VTS);
    else if (ttn > 0 && ttn <= vts_ptt_srpt->nr_of_srpts) {
        pgc_id   = vts_ptt_srpt->title[ttn - 1].ptt[0].pgcn;
        cur_pgc  = vts->vts_pgcit->pgci_srp[pgc_id - 1].pgc;
        dt = &cur_pgc->playback_time;
        hour = ((dt->hour & 0xf0) >> 4) * 10 + (dt->hour & 0x0f);
        minute = ((dt->minute & 0xf0) >> 4) * 10 + (dt->minute & 0x0f);
        second = ((dt->second & 0xf0) >> 4) * 10 + (dt->second & 0x0f);
        if (((dt->frame_u & 0xc0) >> 6) == 1)
            fps = 25.00;
        else
            fps = 29.97;
        dt->frame_u &= 0x3f;
        dt->frame_u = ((dt->frame_u & 0xf0) >> 4) * 10 + (dt->frame_u & 0x0f);
        ms = (double)dt->frame_u * 1000.0 / fps;

        XPUSHs(sv_2mortal(newSViv(
            hour * 60 * 60 * 1000 + minute * 60 * 1000 + second * 1000 + ms
        )));
    }

void
vts_pgc_id(vts, ttn, chapter = 1)
    ifo_handle_t * vts
    int ttn
    int chapter
    PREINIT:
    int pgc_id;
    vts_ptt_srpt_t * vts_ptt_srpt;
    PPCODE:
    vts_ptt_srpt = vts->vts_ptt_srpt;
    if (!vts_ptt_srpt)
        croak(CROAK_NOT_VTS);
    else if (ttn > 0 && ttn <= vts_ptt_srpt->nr_of_srpts &&
        chapter > 0 && chapter <= vts_ptt_srpt->title[ttn - 1].nr_of_ptts) {
        pgc_id   = vts_ptt_srpt->title[ttn - 1].ptt[chapter-1].pgcn;
        XPUSHs(sv_2mortal(newSViv(pgc_id)));
    }

void
vts_pgcs_count(vts)
    ifo_handle_t * vts
    PPCODE:
    if (!vts->vts_ptt_srpt)
        croak(CROAK_NOT_VTS);
    else
    XPUSHs(sv_2mortal(newSViv(vts->vts_pgcit->nr_of_pgci_srp)));

void
vts_pgc_num(vts, ttn, chapter)
    ifo_handle_t * vts
    int ttn
    int chapter
    PREINIT:
    int pgn;
    vts_ptt_srpt_t * vts_ptt_srpt;
    PPCODE:
    vts_ptt_srpt = vts->vts_ptt_srpt;
    if (!vts_ptt_srpt)
        croak(CROAK_NOT_VTS);
    else if (ttn > 0 && ttn <= vts_ptt_srpt->nr_of_srpts &&
        chapter > 0 && chapter <= vts_ptt_srpt->title[ttn - 1].nr_of_ptts) {
        pgn = vts_ptt_srpt->title[ttn - 1].ptt[chapter -1].pgn;
        XPUSHs(sv_2mortal(newSViv(pgn)));
    }

void
vts_pgc(sv_vts, pgc_id)
    SV * sv_vts
    int pgc_id
    PREINIT:
    ifo_handle_t * vts;
    sv_pgc_t * sv_pgc;
    vts_ptt_srpt_t * vts_ptt_srpt; 
    PPCODE:
    if (sv_isobject(sv_vts) && (SvTYPE(SvRV(sv_vts)) == SVt_PVMG))
        vts = (ifo_handle_t *)SvIV((SV*)SvRV( sv_vts ));
    else {
        warn( "DVD::Read::Dvd::Ifo::Vts::vts_pgc() -- ifo is not a blessed SV reference" );
        XSRETURN_UNDEF;
    }
    vts_ptt_srpt = vts->vts_ptt_srpt;
    if (!vts_ptt_srpt)
        croak(CROAK_NOT_VTS);
    else if (pgc_id > 0 && pgc_id <= vts->vts_pgcit->nr_of_pgci_srp) {
        sv_pgc = malloc(sizeof(*sv_pgc));
        sv_pgc->sv_ifo_handle = SvREFCNT_inc(SvRV(sv_vts));
        sv_pgc->pgc = vts->vts_pgcit->pgci_srp[pgc_id - 1].pgc;
        sv_pgc->pgcid = pgc_id;
        XPUSHs(sv_2mortal(
            sv_setref_pv(
                newSVpv("", 0),
                "DVD::Read::Dvd::Ifo::Pgc",
                (void *)sv_pgc)
        ));
    }
    
MODULE = DVD::Read PACKAGE = DVD::Read::Dvd::Ifo::Pgc

void
DESTROY(sv_pgc)
    sv_pgc_t * sv_pgc;
    PPCODE:
    SvREFCNT_dec(sv_pgc->sv_ifo_handle);
    free(sv_pgc);

int
id(sv_pgc)
    sv_pgc_t * sv_pgc;
    CODE:
    RETVAL = sv_pgc->pgcid;
    OUTPUT:
    RETVAL

void
cells_count(sv_pgc)
    sv_pgc_t * sv_pgc
    PPCODE:
    XPUSHs(sv_2mortal(newSViv(sv_pgc->pgc->nr_of_cells)));

void
cell_number(sv_pgc, pgn)
    sv_pgc_t * sv_pgc
    int pgn
    PPCODE:
    if (pgn <= sv_pgc->pgc->nr_of_programs)
        XPUSHs(sv_2mortal(newSViv(sv_pgc->pgc->program_map[pgn - 1])));

void
cell(sv_pgc, cellid)
    sv_pgc_t * sv_pgc
    int cellid
    PREINIT:
    sv_cell_playback_t * sv_cell = NULL;
    PPCODE:
    if (cellid <= sv_pgc->pgc->nr_of_cells) {
        sv_cell = malloc(sizeof(* sv_cell));
        sv_cell->cellid = cellid;
        sv_cell->cell = &sv_pgc->pgc->cell_playback[cellid -1];
        sv_cell->sv_ifo_handle = SvREFCNT_inc(sv_pgc->sv_ifo_handle);
        XPUSHs(sv_2mortal(
            sv_setref_pv(
                newSVpv("", 0),
                "DVD::Read::Dvd::Ifo::Cell",
                (void *)sv_cell)
        ));
    }

void
_programs_count(sv_pgc)
    sv_pgc_t * sv_pgc
    PPCODE:
    XPUSHs(sv_2mortal(newSViv(sv_pgc->pgc->nr_of_programs)));

MODULE = DVD::Read PACKAGE = DVD::Read::Dvd::Ifo::Cell

void
DESTROY(sv_cell)
    sv_cell_playback_t * sv_cell;
    PPCODE:
    SvREFCNT_dec(sv_cell->sv_ifo_handle);
    free(sv_cell);

int
first_sector(sv_cell)
    sv_cell_playback_t * sv_cell;
    CODE:
    RETVAL = sv_cell->cell->first_sector;
    OUTPUT:
    RETVAL

int
cellid(sv_cell)
    sv_cell_playback_t * sv_cell;
    CODE:
    RETVAL = sv_cell->cellid;
    OUTPUT:
    RETVAL

int
last_sector(sv_cell)
    sv_cell_playback_t * sv_cell;
    CODE:
    RETVAL = sv_cell->cell->last_sector;
    OUTPUT:
    RETVAL

void
time(sv_cell)
    sv_cell_playback_t * sv_cell
    PREINIT:
    double ms, fps, hour, minute, second;
    dvd_time_t * dt;
    PPCODE:
    dt = &sv_cell->cell->playback_time;
    hour = ((dt->hour & 0xf0) >> 4) * 10 + (dt->hour & 0x0f);
    minute = ((dt->minute & 0xf0) >> 4) * 10 + (dt->minute & 0x0f);
    second = ((dt->second & 0xf0) >> 4) * 10 + (dt->second & 0x0f);
    if (((dt->frame_u & 0xc0) >> 6) == 1)
        fps = 25.00;
    else
        fps = 29.97;
    dt->frame_u &= 0x3f;
    dt->frame_u = ((dt->frame_u & 0xf0) >> 4) * 10 + (dt->frame_u & 0x0f);
    ms = (double)dt->frame_u * 1000.0 / fps;
    XPUSHs(sv_2mortal(newSVnv(
    hour * 60 * 60 * 1000 + minute * 60 * 1000 + second * 1000 + ms
    )));
