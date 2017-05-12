/* GPL clean */

#include <ctype.h>
#include <stdlib.h>
#include <signal.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/stat.h>
#ifdef WIN32
#include <time.h>
#else
#include <sys/time.h>
#endif

#include <fcntl.h>

#ifdef READ_MMAP
#include <sys/mman.h>
#ifndef MAP_FAILED
#define MAP_FAILED ( (void *) -1 )
#endif
#endif

#include "mpg123.h"
#include "genre.h"
#include "common.h"

int tabsel_123[2][3][16] = {
   { {0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,},
     {0,32,48,56, 64, 80, 96,112,128,160,192,224,256,320,384,},
     {0,32,40,48, 56, 64, 80, 96,112,128,160,192,224,256,320,} },

   { {0,32,48,56,64,80,96,112,128,144,160,176,192,224,256,},
     {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,},
     {0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,} }
};

long freqs[9] = { 44100, 48000, 32000, 22050, 24000, 16000 , 11025 , 12000 , 8000 };

struct bitstream_info bsi;

static int bsbufend[2]= { 0,0 };
static int bsbufold_end;
static unsigned char bsspace[2][MAXFRAMESIZE+512]; /* MAXFRAMESIZE */
static unsigned char *bsbuf=bsspace[1],*bsbufold;
static int bsnum=0;

static int skip_riff(struct reader *);
static int skip_new_id3(struct reader *);

unsigned char *pcm_sample;
int pcm_point = 0;
int audiobufsize = AUDIOBUFSIZE;

static int decode_header(struct frame *fr,unsigned long newhead);

static struct vbrHeader head;
static int vbr = 0;

void safewrite(int fd, const void *buf, size_t count) {
       int donesofar = 0;
       while(donesofar < count) {
               int retval;
               retval = write(fd,(buf+donesofar),(count-donesofar));
               if(retval == -1) {
                       if((errno != EINTR) && (errno != EAGAIN))
                               exit(fprintf(stderr,"exception on output!\n"));
               } else
                       donesofar += retval;
       }
}

void audio_flush(int outmode, struct audio_info_struct *ai)
{
    if (pcm_point) {
	switch (outmode) {
	case DECODE_FILE:
	    safewrite (OutputDescriptor, pcm_sample, pcm_point);
	    break;
	case DECODE_AUDIO:
	    audio_play_samples (ai, pcm_sample, pcm_point);
	    break;
	case DECODE_BUFFER:
	    safewrite (buffer_fd[1], pcm_sample, pcm_point);
	    break;
	case DECODE_WAV:
	case DECODE_CDR:
	case DECODE_AU:
	    wav_write(pcm_sample, pcm_point);
	    break;
	}
	pcm_point = 0;
    }
}

#if !defined(WIN32) && !defined(GENERIC)
void (*catchsignal(int signum, void(*handler)()))()
{
    struct sigaction new_sa;
    struct sigaction old_sa;

#ifdef DONT_CATCH_SIGNALS
    printf ("Not catching any signals.\n");
    return ((void (*)()) -1);
#endif

    new_sa.sa_handler = handler;
    sigemptyset(&new_sa.sa_mask);
    new_sa.sa_flags = 0;
    if (sigaction(signum, &new_sa, &old_sa) == -1)
	return ((void (*)()) -1);
    return (old_sa.sa_handler);
}
#endif

void read_frame_init (struct frame *fr)
{
    fr->firsthead = 0;
    fr->thishead = 0;
    fr->freeformatsize = 0;
}

int head_check(unsigned long head)
{
    if( (head & 0xffe00000) != 0xffe00000)
	return FALSE;
    if(!((head>>17)&3))
	return FALSE;
    if( ((head>>12)&0xf) == 0xf)
	return FALSE;
    if( ((head>>10)&0x3) == 0x3 )
	return FALSE;

    return TRUE;
}

/*
 * return 0: EOF or other stream error
 *       -1: giving up
 *        1: synched
 */
#define MAX_INPUT_FRAMESIZE 1920
#define SYNC_HEAD_MASK    0xffff0000
#define SYNC_HEAD_MASK_FF 0x0000f000
#define LOOK_AHEAD_NUM 3
#define SCAN_LENGTH 16384

#define CHECK_FOR_RIFF   0x0001
#define CHECK_FOR_ID3_V1 0x0002
#define CHECK_FOR_ID3_V2 0x0004

int sync_stream(struct reader *rds,struct frame *fr,int flags,int *skipped)
{
   int i,j,l,ret;
   unsigned long firsthead,nexthead;
   struct frame frameInfo,nextInfo;
   unsigned char dummybuf[MAX_INPUT_FRAMESIZE];
   int found=0;
   int freeformatsize=0;

   for(i=0;i<SCAN_LENGTH;i++) {

     readers_mark_pos(rds);  /* store our current position */

     if(!rds->head_read(rds,&firsthead))
        return 0;

     /* first a few simple checks */ 
     if( !head_check(firsthead) || !decode_header(&frameInfo,firsthead) ) {

       /* Check for RIFF Headers */
       if( (flags & CHECK_FOR_RIFF) && firsthead == ('R'<<24)+('I'<<16)+('F'<<8)+'F') {
         fprintf(stderr,"Found RIFF Header\n");
         ret = skip_riff(rds);
         if(ret > 0) { /* RIFF was OK continue with next byte */
           *skipped += ret+4;
           continue;
         }
         if(ret == 0)
            return 0;
       }
  
       /* Check for old ID3 Header (or better Footer ;) */
       if( (flags & CHECK_FOR_ID3_V1) && (firsthead>>8) == ('T'<<16)+('A'<<8)+'G') {
         fprintf(stderr,"Found old ID3 Header\n");
       }

       /* Check for new ID3 header */
       if(  (flags & CHECK_FOR_ID3_V2) && (firsthead>>8) == ('I'<<16)+('D'<<8)+'3') {
         if( (firsthead & 0xff) != 0xff) {
           fprintf(stderr,"Found new ID3 Header\n"); 
           ret = skip_new_id3(rds);
           if(!ret)
              return 0;
           if(ret > 0) {
              *skipped += ret+4;
              continue;
           }
         }
       }

       readers_goto_mark(rds); /* reset to old mark and continue */
       if(!rds->read_frame_body(rds,dummybuf,1))
         return 0;

       (*skipped)++;
       continue;
     }

     found = 0;
     freeformatsize = 0;

     /*
      * At the first free format paket we do not know the size
      */
     if(frameInfo.bitrate_index == 0) {
        int maxframesize = MAX_INPUT_FRAMESIZE; /* FIXME depends on layer and sampling freq */

fprintf(stderr,"Searching for next FF header\n");

        if(!rds->head_read(rds,&nexthead))
           return 0;

        for(j=0;j<maxframesize;j++) {
           if(head_check(nexthead) && (nexthead & (SYNC_HEAD_MASK|SYNC_HEAD_MASK_FF) ) == (firsthead & (SYNC_HEAD_MASK|SYNC_HEAD_MASK_FF)) &&
             decode_header(&nextInfo,nexthead) ) {

/* fprintf(stderr,"j: %d %d %d\n",j,frameInfo.padsize,nextInfo.padsize); */

               freeformatsize = j - frameInfo.padsize;
               found = 1;
               break;
           }
           if(!rds->head_shift(rds,&nexthead))
             return 0;
        }
     }
     else {
        if(!rds->read_frame_body(rds,dummybuf,frameInfo.framesize))
           return 0;
            
        if(!rds->head_read(rds,&nexthead))
           return 0;

/*
fprintf(stderr,"S: %08lx %08lx %d %d %d %d\n",firsthead,nexthead, head_check(nexthead),(nexthead & SYNC_HEAD_MASK) == firsthead,(nexthead & SYNC_HEAD_MASK_FF) != 0x0,decode_header(&nextInfo,nexthead));
*/

        if( head_check(nexthead) && (nexthead & SYNC_HEAD_MASK) == (firsthead & SYNC_HEAD_MASK) && 
            (nexthead & SYNC_HEAD_MASK_FF) != 0x0 && decode_header(&nextInfo,nexthead))  {
              found = 1;
        }
     }

     if(!found) {
       readers_goto_mark(rds); /* reset to old mark and continue */
       if(!rds->read_frame_body(rds,dummybuf,1))
         return 0;
       (*skipped)++;
       continue;
     }

/*
fprintf(stderr,"s: %08lx %08lx %d %d %d\n",firsthead,nexthead,frameInfo.framesize,nextInfo.framesize,freeformatsize);
*/

     /* check some more frames */
     for(l=0;l<LOOK_AHEAD_NUM;l++) {
        int size;
        
        if( freeformatsize > 0 ) {
          size = freeformatsize + nextInfo.padsize;
        }
        else
          size = nextInfo.framesize;

        /* step over data */
        if(!rds->read_frame_body(rds,dummybuf,size))
          return 0;

        if(!rds->head_read(rds,&nexthead))
           return 0;

        if(!head_check(nexthead) || 
           (nexthead & SYNC_HEAD_MASK) != (firsthead & SYNC_HEAD_MASK) ||
           !decode_header(&nextInfo,nexthead) )  {
           found = 0;
           break;
        }
        if( freeformatsize > 0) {
          if( ( nexthead & SYNC_HEAD_MASK_FF ) != 0x0) {
            found = 0;
            break;
          }
        }
        else {
          if( (nexthead & SYNC_HEAD_MASK_FF) == 0x0) {
            found = 0;
            break;
          } 
        }
     }
    
     if(found)
         break; 

     readers_goto_mark(rds); /* reset to old mark and continue */
     if(!rds->read_frame_body(rds,dummybuf,1)) /* skip first byte */
       return 0;
     (*skipped)++;

   }

   if(i == SCAN_LENGTH)
     return -1;

   readers_goto_mark(rds);
   fr->freeformatsize = freeformatsize;
   fr->firsthead = firsthead;

   return 1;

}

/*
 * skips the RIFF header at the beginning
 *
 * returns:  0    = read-error
 *          -1/-2 = illegal RIFF header (= -2 backstep not valid)
 *           1    = skipping succeeded
 */
static int skip_riff(struct reader *rds)
{
   unsigned long length;
   unsigned char buf[16];
   
   if(!rds->read_frame_body(rds,buf,16))       /* read header information */
     return 0;

   if( strncmp("WAVEfmt ",(char *)buf+4,8) )         /* check 2. signature */
     return -1;

   length = (unsigned long) buf[12] +         /* decode the header length */
            (((unsigned long) buf[13])<<8) +
            (((unsigned long) buf[14])<<16) +
            (((unsigned long) buf[15])<<24);

   if(!rds->skip_bytes(rds,length)) /* will not store data in backbuff! */
     return 0;

   if(!rds->read_frame_body(rds,buf,8))  /* skip "data" plus length */
     return 0;

   if(strncmp("data",(char *)buf,4))
     return -2;

   return length+8+16;
}

/*
 * skips the ID3 header at the beginning
 *
 * returns:  0 = read-error
 *          -1 = illegal ID3 header
 *           1 = skipping succeeded
 */
static int skip_new_id3(struct reader *rds)
{
   unsigned long length;
   unsigned char buf[6];

   if(!rds->read_frame_body(rds,buf,6))       /* read more header information */
     return 0;

   if(buf[0] == 0xff)
     return -1;

   if( (buf[2]|buf[3]|buf[4]|buf[5]) & 0x80)
     return -1;

   length  = (unsigned long) buf[2] & 0x7f;
   length <<= 7;
   length += (unsigned long) buf[3] & 0x7f;
   length <<= 7;
   length += (unsigned long) buf[4] & 0x7f;
   length <<= 7;
   length += (unsigned long) buf[5] & 0x7f;

   if(!rds->skip_bytes(rds,length)) /* will not store data in backbuff! */
     return 0;

   return length+6;

}





/*****************************************************************
 * read next frame
 */
int read_frame(struct reader *rds,struct frame *fr)
{
    unsigned long newhead,oldhead;
    static unsigned char ssave[34];

    oldhead = fr->thishead;

    if (param.halfspeed) {
	static int halfphase = 0;
	if (halfphase--) {
	    bsi.bitindex = 0;
	    bsi.wordpointer = (unsigned char *) bsbuf;
	    if (fr->lay == 3)
		memcpy (bsbuf, ssave, fr->sideInfoSize);
	    return 1;
	}
	else
	    halfphase = param.halfspeed - 1;
    }

    while(1) {

        if(!rds->head_read(rds,&newhead))
	    return FALSE;

/*
        fprintf(stderr,"n %08lx",newhead);
*/

	if( !head_check(newhead) || !decode_header(fr,newhead) ) {
	    if (!param.quiet)
		fprintf(stderr,"Illegal Audio-MPEG-Header 0x%08lx at offset 0x%lx.\n",
			newhead,rds->tell(rds)-4);

	    if(param.tryresync) {
		int try = 0;
                readers_pushback_header(rds,newhead);
		if(sync_stream(rds,fr,0xffff,&try) <= 0)
                   return 0;
		if(!param.quiet)
		   fprintf (stderr, "Skipped %d bytes in input.\n", try);
	    }
	    else
		return (0);
	}
        else 
          break;
    }

/*
    fprintf(stderr,"N %08lx",newhead);
*/

    fr->header_change = 2;
    if(oldhead) {
         if((oldhead & 0xc00) == (fr->thishead & 0xc00)) {
              if( (oldhead & 0xc0) == 0 && (fr->thishead & 0xc0) == 0)
                  fr->header_change = 1;
              else if( (oldhead & 0xc0) > 0 && (fr->thishead & 0xc0) > 0)
                  fr->header_change = 1;
          }
    }
 
 
    if(!fr->bitrate_index) { 
       fr->framesize = fr->freeformatsize + fr->padsize;
    }

/*
fprintf(stderr,"Reading %d\n",fr->framesize);
*/

    /* flip/init buffer for Layer 3 */
    /* FIXME for reentrance */
    bsbufold = bsbuf;
    bsbufold_end = bsbufend[bsnum];
    bsbuf = bsspace[bsnum]+512;
    bsnum = (bsnum + 1) & 1;
    bsbufend[bsnum] = fr->framesize;

    /* read main data into memory */
    if(!rds->read_frame_body(rds,bsbuf,fr->framesize))
	return 0;

    /* Test */
    if(!vbr) {
        vbr = getVBRHeader(&head,bsbuf,fr);
    }

    bsi.bitindex = 0;
    bsi.wordpointer = (unsigned char *) bsbuf;

    if (param.halfspeed && fr->lay == 3)
	memcpy (ssave, bsbuf, fr->sideInfoSize);

    return 1;
}

/*
 * decode a header and write the information
 * into the frame structure
 */
static int decode_header(struct frame *fr,unsigned long newhead)
{
    if(!head_check(newhead)) {
        fprintf(stderr,"Oopps header is wrong %08lx\n",newhead);
	return 0;
    }

    if( newhead & (1<<20) ) {
	fr->lsf = (newhead & (1<<19)) ? 0x0 : 0x1;
	fr->mpeg25 = 0;
    }
    else {
	fr->lsf = 1;
	fr->mpeg25 = 1;
    }

    /* 
     * CHECKME: should be add more consistency checks here ?  
     * changed layer, changed CRC bit, changed sampling frequency 
     */
    {
	fr->lay = 4-((newhead>>17)&3);
	if( ((newhead>>10)&0x3) == 0x3) {
	    fprintf(stderr,"Stream error\n");
	    return 0;
	}
	if(fr->mpeg25) {
	    fr->sampling_frequency = 6 + ((newhead>>10)&0x3);
	}
	else
	    fr->sampling_frequency = ((newhead>>10)&0x3) + (fr->lsf*3);
	fr->error_protection = ((newhead>>16)&0x1)^0x1;
    }

    fr->bitrate_index = ((newhead>>12)&0xf);
    fr->padding   = ((newhead>>9)&0x1);
    fr->extension = ((newhead>>8)&0x1);
    fr->mode      = ((newhead>>6)&0x3);
    fr->mode_ext  = ((newhead>>4)&0x3);
    fr->copyright = ((newhead>>3)&0x1);
    fr->original  = ((newhead>>2)&0x1);
    fr->emphasis  = newhead & 0x3;

    fr->stereo    = (fr->mode == MPG_MD_MONO) ? 1 : 2;

    switch(fr->lay) {
    case 1:
        fr->framesize  = (long) tabsel_123[fr->lsf][0][fr->bitrate_index] * 12000;
        fr->framesize /= freqs[fr->sampling_frequency];
        fr->framesize  = ((fr->framesize+fr->padding)<<2)-4;
        fr->sideInfoSize = 0;
        fr->padsize = fr->padding << 2;
        break;
    case 2:
        fr->framesize = (long) tabsel_123[fr->lsf][1][fr->bitrate_index] * 144000;
        fr->framesize /= freqs[fr->sampling_frequency];
        fr->framesize += fr->padding - 4;
        fr->sideInfoSize = 0;
        fr->padsize = fr->padding;
        break;
    case 3:
        if(fr->lsf)
	    fr->sideInfoSize = (fr->stereo == 1) ? 9 : 17;
        else
	    fr->sideInfoSize = (fr->stereo == 1) ? 17 : 32;
        if(fr->error_protection)
	    fr->sideInfoSize += 2;
        fr->framesize  = (long) tabsel_123[fr->lsf][2][fr->bitrate_index] * 144000;
        fr->framesize /= freqs[fr->sampling_frequency]<<(fr->lsf);
        fr->framesize = fr->framesize + fr->padding - 4;
        fr->padsize = fr->padding;
        break; 
    default:
        fprintf(stderr,"Sorry, unknown layer type.\n"); 
        return (0);
    }

    if(!fr->bitrate_index) {
        /* fprintf(stderr,"Warning, Free format not heavily tested: (head %08lx)\n",newhead); */
        fr->framesize = 0;
    }
    fr->thishead = newhead;

    return 1;
}

#ifdef MPG123_REMOTE
void print_rheader(struct frame *fr)
{
    static char *modes[4] = { "Stereo", "Joint-Stereo", "Dual-Channel", "Single-Channel" };
    static char *layers[4] = { "Unknown" , "I", "II", "III" };
    static char *mpeg_type[2] = { "1.0" , "2.0" };

    /* version, layer, freq, mode, channels, bitrate, BPF */
    fprintf(stderr,"@I %s %s %ld %s %d %d %d\n",
	    mpeg_type[fr->lsf],layers[fr->lay],freqs[fr->sampling_frequency],
	    modes[fr->mode],fr->stereo,
	    tabsel_123[fr->lsf][fr->lay-1][fr->bitrate_index],
	    fr->framesize+4);
}
#endif

void print_header(struct frame *fr)
{
    static char *modes[4] = { "Stereo", "Joint-Stereo", "Dual-Channel", "Single-Channel" };
    static char *layers[4] = { "Unknown" , "I", "II", "III" };

    fprintf(stderr,"MPEG %s, Layer: %s, Freq: %ld, mode: %s, modext: %d, BPF : %d\n", 
	    fr->mpeg25 ? "2.5" : (fr->lsf ? "2.0" : "1.0"),
	    layers[fr->lay],freqs[fr->sampling_frequency],
	    modes[fr->mode],fr->mode_ext,fr->framesize+4);
    fprintf(stderr,"Channels: %d, copyright: %s, original: %s, CRC: %s, emphasis: %d.\n",
	    fr->stereo,fr->copyright?"Yes":"No",
	    fr->original?"Yes":"No",fr->error_protection?"Yes":"No",
	    fr->emphasis);
#if 0
    fprintf(stderr,"Bitrate: %d Kbits/s, Extension value: %d\n",
	    tabsel_123[fr->lsf][fr->lay-1][fr->bitrate_index],fr->extension);
#endif
    fprintf(stderr,"%sBitrate: %d Kbits/s, Extension value: %d\n",
	    vbr ? "Average " : "",
	    vbr ? 
	    (int) (head.bytes * 8 / (compute_tpf(fr) * head.frames * 1000)):
	    (tabsel_123[fr->lsf][fr->lay-1][fr->bitrate_index]),
	    fr->extension);

}

void print_header_compact(struct frame *fr)
{
    static char *modes[4] = { "stereo", "joint-stereo", "dual-channel", "mono" };
    static char *layers[4] = { "Unknown" , "I", "II", "III" };
 
    fprintf(stderr,"MPEG %s layer %s, %d kbit/s, %ld Hz %s\n",
	    fr->mpeg25 ? "2.5" : (fr->lsf ? "2.0" : "1.0"),
	    layers[fr->lay],
	    tabsel_123[fr->lsf][fr->lay-1][fr->bitrate_index],
	    freqs[fr->sampling_frequency], modes[fr->mode]);
}

void print_id3_tag(unsigned char *buf)
{
    struct id3tag {
	char tag[3];
	char title[30];
	char artist[30];
	char album[30];
	char year[4];
	char comment[30];
	unsigned char genre;
    };
    struct id3tag *tag = (struct id3tag *) buf;
    char title[31]={0,};
    char artist[31]={0,};
    char album[31]={0,};
    char year[5]={0,};
    char comment[31]={0,};
    char genre[31]={0,};

    if(param.quiet)
	return;

    strncpy(title,tag->title,30);
    strncpy(artist,tag->artist,30);
    strncpy(album,tag->album,30);
    strncpy(year,tag->year,4);
    strncpy(comment,tag->comment,30);

    if ( tag->genre < sizeof(genre_table)/sizeof(*genre_table) ) {
	strncpy(genre, genre_table[tag->genre], 30);
    } else {
	strncpy(genre,"Unknown",30);
    }
	
    fprintf(stderr,"Title  : %-30s  Artist: %s\n",title,artist);
    fprintf(stderr,"Album  : %-30s  Year  : %4s\n",album,year);
    fprintf(stderr,"Comment: %-30s  Genre : %s\n",comment,genre);
}

#if 0
/* removed the strndup for better portability */
/*
 *   Allocate space for a new string containing the first
 *   "num" characters of "src".  The resulting string is
 *   always zero-terminated.  Returns NULL if malloc fails.
 */
char *strndup (const char *src, int num)
{
    char *dst;

    if (!(dst = (char *) malloc(num+1)))
	return (NULL);
    dst[num] = '\0';
    return (strncpy(dst, src, num));
}
#endif

/*
 *   Split "path" into directory and filename components.
 *
 *   Return value is 0 if no directory was specified (i.e.
 *   "path" does not contain a '/'), OR if the directory
 *   is the same as on the previous call to this function.
 *
 *   Return value is 1 if a directory was specified AND it
 *   is different from the previous one (if any).
 */

int split_dir_file (const char *path, char **dname, char **fname)
{
    static char *lastdir = NULL;
    char *slashpos;

    if ((slashpos = strrchr(path, '/'))) {
	*fname = slashpos + 1;
	*dname = strdup(path); /* , 1 + slashpos - path); */
	if(!(*dname)) {
	    perror("memory");
	    exit(1);
	}
	(*dname)[1 + slashpos - path] = 0;
	if (lastdir && !strcmp(lastdir, *dname)) {
	    /***   same as previous directory   ***/
	    free (*dname);
	    *dname = lastdir;
	    return 0;
	}
	else {
	    /***   different directory   ***/
	    if (lastdir)
		free (lastdir);
	    lastdir = *dname;
	    return 1;
	}
    }
    else {
	/***   no directory specified   ***/
	if (lastdir) {
	    free (lastdir);
	    lastdir = NULL;
	};
	*dname = NULL;
	*fname = (char *)path;
	return 0;
    }
}

void set_pointer(int ssize,long backstep)
{
    bsi.wordpointer = bsbuf + ssize - backstep;
    if (backstep)
	memcpy(bsi.wordpointer,bsbufold+bsbufold_end-backstep,backstep);
    bsi.bitindex = 0; 
}

/********************************/

double compute_bpf(struct frame *fr)
{
    double bpf;

    if(!fr->bitrate_index) {
	return fr->freeformatsize + 4;
    }

    switch(fr->lay) {
    case 1:
	bpf = tabsel_123[fr->lsf][0][fr->bitrate_index];
	bpf *= 12000.0 * 4.0;
	bpf /= freqs[fr->sampling_frequency] <<(fr->lsf);
	break;
    case 2:
    case 3:
	bpf = tabsel_123[fr->lsf][fr->lay-1][fr->bitrate_index];
        bpf *= 144000;
	bpf /= freqs[fr->sampling_frequency] << (fr->lsf);
	break;
    default:
	bpf = 1.0;
    }

    return bpf;
}

double compute_tpf(struct frame *fr)
{
    static int bs[4] = { 0,384,1152,1152 };
    double tpf;

    tpf = (double) bs[fr->lay];
    tpf /= freqs[fr->sampling_frequency] << (fr->lsf);
    return tpf;
}

/*
 * Returns number of frames queued up in output buffer, i.e. 
 * offset between currently played and currently decoded frame.
 */

long compute_buffer_offset(struct frame *fr)
{
    long bufsize;
	
    /*
     * buffermem->buf[0] holds output sampling rate,
     * buffermem->buf[1] holds number of channels,
     * buffermem->buf[2] holds audio format of output.
     */
	
    if(!param.usebuffer || !(bufsize=xfermem_get_usedspace(buffermem))
       || !buffermem->buf[0] || !buffermem->buf[1])
	return 0;

    bufsize = (long)((double) bufsize / buffermem->buf[0] / 
		     buffermem->buf[1] / compute_tpf(fr));
	
    if((buffermem->buf[2] & AUDIO_FORMAT_MASK) == AUDIO_FORMAT_16)
	return bufsize/2;
    else
	return bufsize;
}

void print_stat(struct reader *rds,struct frame *fr,int no,long buffsize,struct audio_info_struct *ai)
{
    double bpf,tpf,tim1,tim2;
    double dt = 0.0;
    int sno,rno;
    char outbuf[256];

    if(!rds || !fr) 
	return;

    outbuf[0] = 0;

#ifndef GENERIC
    {
	struct timeval t;
	fd_set serr;
	int n,errfd = fileno(stderr);

	t.tv_sec=t.tv_usec=0;

	FD_ZERO(&serr);
	FD_SET(errfd,&serr);
	n = select(errfd+1,NULL,&serr,NULL,&t);
	if(n <= 0)
	    return;
    }
#endif

    /* bpf = compute_bpf(fr); */
    bpf = vbr ? (rds->filelen / head.frames) : compute_bpf(fr);
    tpf = compute_tpf(fr);

    if(buffsize > 0 && ai && ai->rate > 0 && ai->channels > 0) {
	dt = (double) buffsize / ai->rate / ai->channels;
	if( (ai->format & AUDIO_FORMAT_MASK) == AUDIO_FORMAT_16)
	    dt *= 0.5;
    }

    rno = 0;
    sno = no;
    if(rds->filelen >= 0) {
	long t = rds->tell(rds);
	rno = (int)((double)(rds->filelen-t)/bpf);
	sno = (int)((double)t/bpf);
    }

    sprintf(outbuf+strlen(outbuf),"\rFrame# %5d [%5d], ",sno,rno);

    tim1 = sno*tpf-dt;
    tim2 = rno*tpf+dt;
#if 0
    tim1 = tim1 < 0 ? 0.0 : tim1;
#endif
    tim2 = tim2 < 0 ? 0.0 : tim2;

    sprintf(outbuf+strlen(outbuf),"Time: %02u:%02u.%02u [%02u:%02u.%02u], Bitrate %3u",
	    (unsigned int)tim1/60,
	    (unsigned int)tim1%60,
	    (unsigned int)(tim1*100)%100,
	    (unsigned int)tim2/60,
	    (unsigned int)tim2%60,
	    (unsigned int)(tim2*100)%100,
	    (unsigned int)tabsel_123[fr->lsf][fr->lay-1][fr->bitrate_index]);

    if(param.usebuffer)
	sprintf(outbuf+strlen(outbuf),"[%8ld] ",(long)buffsize);
    write(fileno(stderr),outbuf,strlen(outbuf));
#if 0
    fflush(out); /* hmm not really nec. */
#endif
}

int get_songlen(struct reader *rds,struct frame *fr,int no)
{
    double tpf;
	
    if(!fr)
	return 0;
	
    if(no < 0) {
	if(!rds || rds->filelen < 0)
	    return 0;
	no = (double) rds->filelen / compute_bpf(fr);
    }

    tpf = compute_tpf(fr);
    return no*tpf;
}


