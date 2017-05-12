#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/soundcard.h>

#define AUDIO_FILE_BUFFER_SIZE 4096

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
        if (strEQ(name, "AFMT_A_LAW"))
#ifdef AFMT_A_LAW
            return AFMT_A_LAW;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_IMA_ADPCM"))
#ifdef AFMT_IMA_ADPCM
            return AFMT_IMA_ADPCM;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_MPEG"))
#ifdef AFMT_MPEG
            return AFMT_MPEG;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_MU_LAW"))
#ifdef AFMT_MU_LAW
            return AFMT_MU_LAW;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_QUERY"))
#ifdef AFMT_QUERY
            return AFMT_QUERY;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_S16_BE"))
#ifdef AFMT_S16_BE
            return AFMT_S16_BE;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_S16_LE"))
#ifdef AFMT_S16_LE
            return AFMT_S16_LE;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_S16_NE"))
#ifdef AFMT_S16_NE
            return AFMT_S16_NE;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_S8"))
#ifdef AFMT_S8
            return AFMT_S8;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_U16_BE"))
#ifdef AFMT_U16_BE
            return AFMT_U16_BE;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_U16_LE"))
#ifdef AFMT_U16_LE
            return AFMT_U16_LE;
#else
            goto not_there;
#endif
        if (strEQ(name, "AFMT_U8"))
#ifdef AFMT_U8
            return AFMT_U8;
#else
            goto not_there;
#endif
        break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

int _audioformat (SV* fmt) {
    char* val;

    /* format specified as integer */
    if (SvIOK(fmt))
        return (SvIV(fmt));

    /* constants are recognized as
     * floating-point numbers
     */
    else if (SvNOK(fmt))
        return (int)SvNV(fmt);

    /* format specified as string - DEPRECATED */
    else if (SvPOK(fmt)) {
        val = SvPVX(fmt);

        if (strEQ(val, "AFMT_QUERY"))
            return(AFMT_QUERY);
        else if (strEQ(val, "AFMT_MU_LAW"))
            return(AFMT_MU_LAW);
        else if (strEQ(val, "AFMT_A_LAW"))
            return(AFMT_A_LAW);
        else if (strEQ(val, "AFMT_IMA_ADPCM"))
            return(AFMT_IMA_ADPCM);
        else if (strEQ(val, "AFMT_U8"))
            return(AFMT_U8);
        else if (strEQ(val, "AFMT_S16_LE"))
            return(AFMT_S16_LE);
        else if (strEQ(val, "AFMT_S16_BE"))
            return(AFMT_S16_BE);
        else if (strEQ(val, "AFMT_S8"))
            return(AFMT_S8);
        else if (strEQ(val, "AFMT_U16_LE"))
            return(AFMT_U16_LE); 
        else if (strEQ(val, "AFMT_U16_BE"))
            return(AFMT_U16_BE);
        else if (strEQ(val, "AFMT_MPEG"))
            return(AFMT_MPEG);
        else {
            return(-1);
        }
    } else {
           return(-1);
   }
}

int _modeflag (SV* flag) {
    int   mode;
    char* val;

    /* mode specified as integer */
    if (SvIOK(flag))
        mode = SvIV(flag);

    /* Fcntl.pm-exported constants are recognized as
     * floating-point numbers
     */
    else if (SvNOK(flag))
        return (int)SvNV(flag);

    /* mode specified as string - DEPRECATED */
    else if (SvPOK(flag)) {
        val = SvPVX(flag);
        if (strEQ(val, "O_RDONLY"))
            mode = O_RDONLY;
        else if (strEQ(val, "O_WRONLY"))
            mode = O_WRONLY;
        else if (strEQ(val, "O_RDWR"))
            mode = O_RDWR;
        else
            mode = -1;

    } else {
        mode = -1;
    }
    return(mode);
}

MODULE = Audio::DSP		PACKAGE = Audio::DSP		

PROTOTYPES: ENABLED

double
constant(name,arg)
        char *          name
        int             arg

#############################################
################ Constructor ################

void
new (...)
    PPCODE:
    {
        HV* construct      = newHV();
        HV* thistash       = newHV();

        SV* buff           = newSViv(4096);    /* read/write buffer size */
        SV* chan           = newSViv(1);       /* mono(1) or stereo(2) */
        SV* data           = newSVpv("",0);    /* stored audio data */
        SV* device         = newSVpv("/dev/dsp",8);
        SV* errstr         = newSVpvf("",0);
        SV* file_indicator = newSViv(0);       /* file descriptor */
        SV* format         = newSViv(AFMT_U8); /* 8 bit unsigned is default */
        SV* mark           = newSViv(0);       /* play position */
        SV* rate           = newSViv(8192);    /* sampling rate */
        SV* self;

        char  audio_buff[AUDIO_FILE_BUFFER_SIZE];
        char* audio_file; /* if "file" param exists */
        char* key;        /* param name */

        int audio_fd;
        int status;
        int stidx;    /* stack index */

        /******** get parameters ********/
        for (stidx = items % 2; stidx < items; stidx += 2) {
            key = SvPVX(ST(stidx));

            if (strEQ(key, "device"))
                sv_setpv(device, SvPVX(ST(stidx + 1)));

            else if (strEQ(key, "buffer"))
                sv_setiv(buff, SvIV(ST(stidx + 1)));

            else if (strEQ(key, "rate"))
                sv_setiv(rate, SvIV(ST(stidx + 1)));

            else if (strEQ(key, "format")) {
                sv_setiv(format, _audioformat(ST(stidx + 1)));
                if (SvIV(format) < 0)
                    croak("error determining audio format");
            }

            else if (strEQ(key, "channels"))
                sv_setiv(chan, SvIV(ST(stidx + 1)));

            /**** store data from existing audio file ****/
            else if (strEQ(key, "file")) {
                audio_file = SvPVX(ST(stidx + 1));
                audio_fd   = open(audio_file, O_RDONLY);
                if (audio_fd < 0)
                    croak("failed to open %s", audio_file);
                for (;;) {
                    status = read(audio_fd, audio_buff, AUDIO_FILE_BUFFER_SIZE);                    if (status == 0)
                        break;
                    else
                        sv_catpvn(data, audio_buff, status);
                }
                if (close(audio_fd) < 0)
                    croak("problem closing audio file %s", audio_file);
            }
        }

        /******** assign settings to new object ********/
        hv_store(construct, "buffer", 6, buff, 0);
        hv_store(construct, "channels", 8, chan, 0);
        hv_store(construct, "data", 4, data, 0);
        hv_store(construct, "device", 6, device, 0);
        hv_store(construct, "errstr", 6, errstr, 0);
        hv_store(construct, "file_indicator", 14, file_indicator, 0);
        hv_store(construct, "format", 6, format, 0);
        hv_store(construct, "mark", 4, mark, 0);
        hv_store(construct, "rate", 4, rate, 0);

        self = newRV_inc((SV*)construct); /* make a reference */
        thistash = gv_stashpv("Audio::DSP", 0);
        sv_bless(self, thistash);         /* bless it */
        XPUSHs(self);                     /* push it */
    }

#################################################################
############## Methods for opening / closing device #############

void
init (...)
    PPCODE:
    {
        SV* format;
        HV* caller = (HV*)SvRV(ST(0));
        char* dev;
        char* key;
        char* val;
        int arg;
        int fd;
        int mode = O_RDWR;  /* device open mode */
        int status;
        int stidx;

        if ((items % 2) == 0)
            croak("Odd number of elements in hash list");

        for (stidx = 1; stidx < items; stidx += 2) {
            key = SvPVX(ST(stidx));

            if (strEQ(key, "device")) {
                hv_store(caller, "device", 6, newSVsv(ST(stidx + 1)), 0);
            } else if (strEQ(key, "buffer")) {
                hv_store(caller, "buffer", 6, newSVsv(ST(stidx + 1)), 0);
            } else if (strEQ(key, "channels")) {
                hv_store(caller, "channels", 8, newSVsv(ST(stidx + 1)), 0);
            } else if (strEQ(key, "rate")) {            
                hv_store(caller, "rate", 4, newSVsv(ST(stidx + 1)), 0);
            } else if (strEQ(key, "format")) {
                hv_store(caller, "format", 6,
                         newSViv(_audioformat(ST(stidx + 1))), 0);
                if (SvIV(*hv_fetch(caller, "format", 6, 0)) < 0) {
                    hv_store(caller, "errstr", 6,
                             newSVpvf("error determining audio format"), 0);
                    XSRETURN_NO;
                }
            }

            /******** get file mode ********/
            else if (strEQ(key, "mode")) {
                mode = _modeflag(ST(stidx + 1));
                if (mode < 0) {
                    hv_store(caller, "errstr", 6,
                             newSVpvf("failed to recognize open flag"), 0);
                    XSRETURN_NO;
                }
            }
        }

        /**** device name ****/
        dev = SvPVX(*hv_fetch(caller, "device", 6, 0));

        /**** open device ****/
        fd = open(dev, mode);
        if (fd < 0) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to open device '%s'", dev), 0);
            XSRETURN_NO;
        }

        /**** set sampling format ****/
        arg = SvIV(*hv_fetch(caller, "format", 6, 0));

        if (ioctl(fd, SNDCTL_DSP_SETFMT, &arg) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_SETFMT ioctl failed"), 0);
            XSRETURN_NO;
        }
        if (arg != SvIV(*hv_fetch(caller, "format", 6, 0))) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to set sample format"), 0);
            XSRETURN_NO;
        }

        /**** set channels ****/
        arg    = SvIV(*hv_fetch(caller, "channels", 8, 0));
        if (ioctl(fd, SNDCTL_DSP_CHANNELS, &arg) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_CHANNELS ioctl failed"), 0);
            XSRETURN_NO;

        }
        if (arg != SvIV(*hv_fetch(caller, "channels", 8, 0))) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to set number of channels"), 0);
            XSRETURN_NO;
        }
         
        /**** set sampling rate ****/
        arg = SvIV(*hv_fetch(caller, "rate", 4, 0));
        if (ioctl(fd, SNDCTL_DSP_SPEED, &arg) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_SPEED ioctl failed"), 0);
            XSRETURN_NO;
        }
        if (arg != SvIV(*hv_fetch(caller, "rate", 4, 0))) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to set sampling rate"), 0);
            XSRETURN_NO;
        }
         
        /**** store file descriptor in Audio::DSP object ****/
        hv_store(caller, "file_indicator", 14, newSViv(fd), 0);

        XSRETURN_YES;
    }

void
open (...)
    PPCODE:
    {
        /* open without sending any ioctl messages */
        HV* caller = (HV*)SvRV(ST(0));
        SV* flag;
        int fd;
        int mode   = O_RDWR;
        char* dev  = SvPVX(*hv_fetch(caller, "device", 6, 0));

        if (items > 1) {
            flag = ST(1);
            mode = _modeflag(flag);
            if (mode < 0) {
                hv_store(caller, "errstr", 6,
                     newSVpvf("unrecognized open flag"), 0);
                XSRETURN_NO;
            }
        }
        fd = open(dev, mode);
        if (fd < 0) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to open audio device file"), 0);
            XSRETURN_NO;
        }
        hv_store(caller, "file_indicator", 14, newSViv(fd), 0);
        XSRETURN_YES;
    }

void
close (...)
    PPCODE:
    {
        /* fetch file descriptor and close... nothing fancy */
        int fd = SvIV(*hv_fetch((HV*)SvRV(ST(0)), "file_indicator", 14, 0));

        if (close(fd) < 0)
            XSRETURN_NO;
        else
            XSRETURN_YES;
    }

#################################################################
####################### I/O control methods #####################

void
channels (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int chan, arg;
        chan = arg = SvIV(ST(1));

        if (ioctl(fd, SNDCTL_DSP_CHANNELS, &arg) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_CHANNELS ioctl failed"), 0);
            XSRETURN_NO;
        }
        XPUSHs(newSViv(arg));
    }

void
getfmts (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int mask;

        if (ioctl(fd, SNDCTL_DSP_GETFMTS, &mask) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_GETFMTS ioctl failed"), 0);
            XSRETURN_NO;
        }
        XPUSHs(newSViv(mask));
    }

void
post (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));

        if (ioctl(fd, SNDCTL_DSP_POST, 0) == -1) {
            hv_store(caller, "errstr", 6, 
                     newSVpvf("SNDCTL_DSP_POST ioctl failed"), 0);
            XSRETURN_NO;
        }
        XSRETURN_YES;
    }

void
reset (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));

        if (ioctl(fd, SNDCTL_DSP_RESET, 0) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_RESET ioctl failed"), 0);
            XSRETURN_NO;
        }
        XSRETURN_YES;
    }

void
setduplex (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));

        if (ioctl(fd, SNDCTL_DSP_SETDUPLEX) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_SETDUPLEX ioctl failed"), 0);
            XSRETURN_NO;
        }
        XSRETURN_YES;
    }

void
setfmt (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        /* SV* format = ST(1); */
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int fmt, arg;
        /* fmt = arg = _audioformat(format); */
        fmt = arg = SvIV(ST(1));

        if (ioctl(fd, SNDCTL_DSP_SETFMT, &arg) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_SETFMT ioctl failed"), 0);
            XSRETURN_NO;
        }
        XPUSHs(newSViv(arg));
    }

void
speed (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int rate, arg;
        rate = arg = SvIV(ST(1));

        if (ioctl(fd, SNDCTL_DSP_SPEED, &arg) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_SPEED ioctl failed"), 0);
            XSRETURN_NO;
        }
        XPUSHs(newSViv(arg));
    }

void
sync (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));

        if (ioctl(fd, SNDCTL_DSP_SYNC, 0) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_SYNC ioctl failed"), 0);
            XSRETURN_NO;
        }
        XSRETURN_YES;
    }

#################################################################
##################### Direct device I/O #########################

void
dread (...)
    PPCODE:
    {
        /* read data and return it */
        HV* caller = (HV*)SvRV(ST(0));
        int fd = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));

        int count;
        int status;
        char *buf;

        if (items > 1)
            count = SvIV(ST(1));
        else
            count = SvIV(*hv_fetch(caller, "buffer", 6, 0));

        buf = malloc(count);
        status = read(fd, buf, count);
        if (status != count) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to read correct number of bytes"), 0);
            XSRETURN_NO;
        }
        XPUSHs(newSVpvn(buf, status));
        free(buf);
    }

void
dwrite (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));

        int status;
        int count      = SvCUR(ST(1));
        char* diy_data = SvPVX(ST(1));

        status = write(fd, diy_data, count);
        if (status != count) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to write correct number of bytes"), 0);
            XSRETURN_NO;
        }
        XSRETURN_YES;
    }

#################################################################
##################### "data-in-memory" methods ##################

void
audiofile (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        char audio_buff[AUDIO_FILE_BUFFER_SIZE];
        char* audio_file;
        int audio_fd;
        int status;

        audio_file = SvPVX(ST(1));
        audio_fd   = open(audio_file, O_RDONLY);

        if (audio_fd < 0) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to open audio file '%s'", audio_file), 0);
            XSRETURN_NO;
        }

        for (;;) {
            status = read(audio_fd, audio_buff, AUDIO_FILE_BUFFER_SIZE);
            if (status == 0)
                break;
            else
                sv_catpvn(*hv_fetch(caller, "data", 4, 0), audio_buff, status);
        }

        if (close(audio_fd) < 0) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("problem closing audio file '%s'", audio_file), 0);
            XSRETURN_NO;
        }
        XSRETURN_YES;
    }

void
clear (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        hv_store(caller, "data", 4, newSVpv("",0), 0);
        hv_store(caller, "mark", 4, newSViv(0), 0);
    }

void
data (...)
    PPCODE:
    {
        XPUSHs(*hv_fetch((HV*)SvRV(ST(0)), "data", 4, 0));
    }

void
datacat (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int len    = SvCUR(ST(1));

        sv_catpvn(*hv_fetch(caller, "data", 4, 0), SvPVX(ST(1)), len);
        XPUSHs(sv_2mortal(newSViv(SvCUR(*hv_fetch(caller, "data", 4, 0)))));
    }

void
datalen (...)
    PPCODE:
    {
        XPUSHs(sv_2mortal(newSViv(SvCUR(*hv_fetch((HV*)SvRV(ST(0)), "data", 4, 0)))));
    }

void
read (...)
    PPCODE:
    {
        /* read one buffer length of data */
        HV* caller = (HV*)SvRV(ST(0));
        int count  = SvIV(*hv_fetch(caller, "buffer", 6, 0));
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int status;
        char buf[count];

        status = read(fd, buf, count); /* record some sound */
        if (status != count) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("failed to read correct number of bytes"), 0);
            XSRETURN_NO;
        }

        sv_catpvn(*hv_fetch(caller, "data", 4, 0), buf, status);
        XSRETURN_YES;
    }

void
setmark (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        if (items >= 2) {
            SvREFCNT_inc(ST(1));
            hv_store(caller, "mark", 4, ST(1), 0);
        }
        XPUSHs(*hv_fetch(caller, "mark", 4, 0));
    }

void
write (...)
    PPCODE:
    {
        HV* caller  = (HV*)SvRV(ST(0));
        int count   = SvIV(*hv_fetch(caller, "buffer", 6, 0));
        int dlength = SvCUR(*hv_fetch(caller, "data", 4, 0));
        int fd      = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int mark    = SvIV(*hv_fetch(caller, "mark", 4, 0));
        int status;
        char* data;

        if (mark >= dlength) /* end of data */
            XSRETURN_NO;

        data = SvPVX(*hv_fetch(caller, "data", 4, 0));

        status = write(fd, &data[mark], count);

        /*** This just causes unnecessary problems...
         * if (status != count) {
         *   hv_store(caller, "errstr", 6,
         *            newSVpvf("failed to write correct number of bytes"), 0);
         *   XSRETURN_NO;
         * }
         */

        hv_store(caller, "mark", 4, newSViv(mark + count), 0);
        XSRETURN_YES;
    }

####################################################################
######################### misc. methods ############################

void
errstr (...)
    PPCODE:
    {
        XPUSHs(*hv_fetch((HV*)SvRV(ST(0)), "errstr", 6, 0));
    }

####################################################################
################## Deprecated methods from v.0.01 ##################

void
getformat (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        SV* format = ST(1);
        int arg    = _audioformat(format);
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int mask;

        if (arg < 0) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("error determining audio format"), 0);
            XSRETURN_NO;
        }

        if (ioctl(fd, SNDCTL_DSP_GETFMTS, &mask) == -1) {
            hv_store(caller, "errstr", 6,
                     newSVpvf("SNDCTL_DSP_GETFMTS ioctl failed"), 0);
            XSRETURN_NO;
        } else if (mask & arg) /* the format is supported */
            XSRETURN_YES;
        else
            hv_store(caller, "errstr", 6,
                     newSVpvf("format not supported"), 0);
            XSRETURN_NO;
    }

void
queryformat (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        int fd     = SvIV(*hv_fetch(caller, "file_indicator", 14, 0));
        int status = ioctl(fd, SNDCTL_DSP_SETFMT, AFMT_QUERY);
        XPUSHs(newSViv(status));
    }

void
setbuffer (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        if (items >= 2) {
            SvREFCNT_inc(ST(1));
            hv_store(caller, "buffer", 6, ST(1), 0);
        }
        XPUSHs(*hv_fetch(caller, "buffer", 6, 0));
    }

void
setchannels (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        if (items >= 2) {
            SvREFCNT_inc(ST(1));
            hv_store(caller, "channels", 8, ST(1), 0);
        }
        XPUSHs(*hv_fetch(caller, "channels", 8, 0));
    }

void
setdevice (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        if (items >= 2) {
            SvREFCNT_inc(ST(1));
            hv_store(caller, "device", 6, ST(1), 0);
        }
        XPUSHs(*hv_fetch(caller, "device", 6, 0));
    }

void
setformat (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));

        if (items >= 2) {
            SvREFCNT_inc(ST(1));
            hv_store(caller, "format", 6, newSViv(_audioformat(ST(1))), 0);
            if (SvIV(*hv_fetch(caller, "format", 6, 0)) < 0) {
                hv_store(caller, "errstr", 6,
                         newSVpvf("error determining audio format"), 0);
                XSRETURN_NO;
            }
        }

        XPUSHs(*hv_fetch(caller, "format", 6, 0));
    }

void
setrate (...)
    PPCODE:
    {
        HV* caller = (HV*)SvRV(ST(0));
        if (items >= 2) {
            SvREFCNT_inc(ST(1));
            hv_store(caller, "rate", 4, ST(1), 0);
        }
        XPUSHs(*hv_fetch(caller, "rate", 4, 0));
    }
