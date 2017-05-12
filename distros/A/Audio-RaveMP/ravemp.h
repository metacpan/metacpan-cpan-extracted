#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <malloc.h>
#include <limits.h>
#include <time.h>

#if defined __linux__
#include <unistd.h>
#include <sys/perm.h>
#include <sys/stat.h>
#include <asm/io.h>
#else
#error This code is currently Linux-specific.
#endif

#if UINT_MAX/(1024L*1024L)==0
#error Expects ints to be at least 32-bit
#endif

#define XP printf	/* Just another name for printf() */

/* ------------- LPT definitions ----------- */

#define LPT1ADD 0x378

#define LPTDATA (port+0)
#define LPTSTAT (port+1)
#define LPTCTL (port+2)

/* Control port (output) bits */

#define IPMODE 0x20
#define IRQEN 0x10 /* IRQ Enable (not used here) */
#define SELECT 0x8
#undef INIT
#define INIT 0x4
#define WR 0x2
#define RD 0x1

/* Status port (input) bits */

#define BUSY 0x80
#define ACK 0x40

#define IDLE (ACK|BUSY)	/* Pattern ready when player idle */
#define IO_READY 0		/* Neither ACK not BUSY set indicates ready for data I/O */

#define STATUS_MASK (BUSY|ACK) /* These are the only valid bits in the status port */

static unsigned port=LPT1ADD;

#define CONTROL(x) (outb((x)^0x4,LPTCTL))	/* Note: Port hardware inverts all but bit 2 (0x4) */
#define STATUS() (inb(LPTSTAT)^0x80)		/* Note: Port hardware inverts bit 7 (0x80) */

/* Player device memory structures and sizes etc. Note that each
   "block" of player memory is split into a number of pages, and
   each page consists of a data area and a tag area. */

#define PAGE_SIZE 512	/* Size of data area */

#define TAG_SIZE 16		/* Size of tag area */

#define MAX_BLOCK_PAGES 32 /* Maximum pages per block (usually 16 or 32) */

#define PAGES_PER_BLOCK 32	/* Empirically determined as right value for internal RAM */

#define MAX_BLOCK_SIZE (MAX_BLOCK_PAGES*(PAGE_SIZE+TAG_SIZE)) /* Bytes per block */

#define DATA_SIZE (PAGES_PER_BLOCK*PAGE_SIZE)	/* Amount of data stored per block (i.e. exc. tags) */

#define TOTAL_BLOCKS 4096	/* Appropriate value for a 64MB Players */

/* The first 6 blocks are used for special purposes (we only need to
   bother with block 0, which containd the Allocation Table) */

#define MIN_DATA_BLOCK 6		/* Lowest block number used for data */

#define INVALID_BLOCK_NO 0xffff	/* Marker value used to indicate block number not valid */

/* Various timing and rety parameters */

#define DELAY_CYCLES 1	/* See iodelay() */

#define READ_RETRY_COUNT 4	/* Maximum retries for page/block read */

#define WRITE_RETRY_COUNT 4	/* Maximum retries for page/block write */

#define RETRY_PAUSE 3	/* Seconds to sleep after an error (not the best solution) */

/* Structure used when reading individual pages within a block */

struct page {
    unsigned char data[PAGE_SIZE];
    unsigned char tag[TAG_SIZE];
};

typedef struct {
    int number;
    char type;
} ravemp_slot;

/* Prototypes for local functions */

int ravemp_permitted(void);
int ravemp_check_idle(void);
ravemp_slot **ravemp_contents(unsigned listall, int *nslots);
char *ravemp_get_filename(unsigned sblock);
int ravemp_upload_file(char *fname, char *dest_name);
int ravemp_remove_file(unsigned firstblock);
int ravemp_download(unsigned firstblock, char *dest);
void ravemp_set_show_status(int status);

/* #define RAVEMP_DEBUG */
#ifdef RAVEMP_DEBUG
#define RMP_TRACE(a) a
#else
#define RMP_TRACE(a)
#endif
