/*

  Upload/download/management utility for the RaveMP portable MP3 player.

  TO DO:

	Improve recovery if block write/read fails - at present a single failure
    seems to cause the retries to fail as well. As there is an internal
    player timeout, a temporary solution is to sleep between retries.

	Test for Device presence on startup (e.g. read/check first page of FAT)

    Add automatic power up (allows upload/download even if device appears to be "off")

	Add "summary" command to display usage, capacity etc

	Make all XP's XPV() inside read/functions

    Tidy up command structure (common routine to send commands)

    Add support for ECP (requires EPP at present)

    Add configuration for port address

    Add support for different memory configurations

    Twiddle for clean compile at max. warnings

 History
 -------

  25-Dec-99 Version 0.0.1:	Initial version by hazeii (of the Snowblind
	Alliance),for basic upload and download testings and exploration of
	player device memory structure.


  30-Dec-99: Version 0.0.2:	Improved timing, made upload and download rather
	more friendly, implemented file deletion. 

  Jan-00: modified for Perl interface by dougm

*/

#include "ravemp.h"
#include "font_8x16.c"

static int read_page(unsigned block,unsigned page,struct page *pp);
static int read_block(unsigned block,unsigned char *buff);
static int read_numbers(unsigned char *p,unsigned count,...);
static int read_page_attempt(unsigned block,unsigned page,struct page *pp);
static int write_block_attempt(unsigned block,unsigned char *blkbuff);
static int read_block_attempt(unsigned block,unsigned char *blkbuff);
static void hexdump_line(unsigned char *p);
static int show_info(unsigned firstblock,unsigned char *baseblk,unsigned char *datablk);
static void iodelay(void);
static int status_wait(unsigned pattern,unsigned *rc);
static int dump_tags(unsigned value);
static int write_tests(void);
static void XPV(int level,char *fmt,...);

static int widescr=0;	/* Option flag - indicates wide image display wanted */

static ravemp_show_status = 0;

void ravemp_set_show_status(int status)
{
    ravemp_show_status = status;
}

#define ravemp_status_dot() \
if (ravemp_show_status) printf(".")

#if 0
/********************** interact **************************/
interact()
{
    int i,j;
    unsigned page,block;
    char c,*p,*s,line[512];

    XP("\nInteractive Mode (? for help)\n");

    while (1) {

	XP(">");

	if (fgets(line,sizeof(line),stdin)==NULL)
	    return;

	p = &line[0];

	while (*p==' ' || *p=='\t')	/* Skip leading white space */
	    p++;

	if (*p=='\n' || strlen(p)==0)
	    continue;

	c = *p++;	/* Get command character */

	while (*p==' ' || *p=='\t') /* Skip to next field */
	    p++;

	switch (tolower(c)) {

	  case 'z':
	    dump_page(0,0);
	    break;

	  case '!':	/* Used for development and test code */
	    i = j = 0;
	    read_numbers(p,2,&i,&j);
	    /*				tag_dump(i); /* Show tag data */
	    write_tests(); /**/
	    /*				show_blocktags(i); /**/
	    /*				grab_blocks(i,j==0?1:j);	/**/
	    break;

	  case 'b':
	    if ((i=read_numbers(p,1,&block)) < 1)
		XP("Specify Block number in decimal (ddd) or hex (0xnnn), e.g. B 0x2f\n");
	    else
		dump_block(block);
	    break;

	  case 'd':
	    if (read_numbers(p,1,&j) < 1)
		XP("Specify starting slot number, e.g. D 6\n");
	    else
		download(j);
	    break;

	  case 'i':
	    if (read_numbers(p,1,&j) < 1)
		XP("Specify starting slot number, e.g. I 7\n");
	    else
		info(j);
	    break;

	  case 'l':
	    list_contents(*p=='*');
	    break;

	  case 'p':
	    if ((i=read_numbers(p,2,&block,&page)) < 2)
		XP("Specify Block and Page number in decimal (ddd) or hex (0xnnn), e.g. P 6 0\n");
	    else
		dump_page(block,page);
	    break;

	  case 'r':
	    if (read_numbers(p,1,&j) < 1)
		XP("Specify starting slot number, e.g. R 12\n");
	    else
		remove_file(j);
	    break;


	  case 's':
	    if ((i=read_numbers(p,1,&block)) < 1)
		XP("Specify Block number in decimal (ddd) or hex (0xnnn), e.g. S 0x2f\n");
	    else
		dump_image(block,widescr);
	    break;


	  case 't':
	    if (read_numbers(p,1,&j) > 0)
		lpt_test(j);	/* Test specified port */
	    else
		lpt_test(port); /* Test default port */
	    break;

	  case 'u':
	    s = p;
	    while (*s>=' ')
		s++;
	    *s='\0';	/* Trim filename at first control character */

	    if (strlen(p)==0)
		XP("No file specified for upload\n");
	    else
		upload_file(p);
	    break;

	  case 'q':
	  case 'x':
	    return;

	  case '?':
	  case 'h':
	    XP("B <b>      Block Dump\n");
	    XP("D <slot>   Download file from player\n");
	    XP("H          Help (this message)\n");
	    XP("I <slot>   Information on file\n");
	    XP("L [*]      List MP3 files (* = All Files)\n");
	    XP("P <b> <p>  Page dump\n");
	    XP("Q          Quit (same as Exit)\n");
	    XP("R <slot>   Remove (delete) file\n");
	    XP("S <slot>   Show display image\n");
	    XP("T [addr]   Test port hardware\n");
	    XP("U <file>   Upload file to player\n");
	    XP("X          Exit (same as Quit)\n");
	    break;

	  default:
	    XP("Unknown command (? for list)\n");
	    break;
	}
    }
}
#endif

/********************** read_page ******************************/

static int read_page(unsigned block,unsigned page,struct page *pp)
{
    int tries;

    for (tries=0;tries<READ_RETRY_COUNT;tries++) {
	if (read_page_attempt(block,page,pp))
	    return 1;
    }

    return 0;
}

/**************** read_page_attempt *******************/

static int read_page_attempt(unsigned block,unsigned page,struct page *pp)
{
    register int i;
    register unsigned char *p;
    unsigned rc;
    unsigned char cmd[]={0x5,0x45,0x0,0x0,0x0,0x4};

    /* Check/wait for idle state */

    if (!ravemp_check_idle()) {
	RMP_TRACE(fprintf(stderr, "Read Page failed: Device not ready\n"));
	return 0;
    }

    /* Send command to the player device */

    cmd[2]=(block>>8)&0xff;
    cmd[3]=block&0xff;
    cmd[4]=page;

    for (i=0;i<sizeof(cmd);i++) {

	if (!status_wait(IDLE,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Read Page Failed: Device not ready (Status 0x%x)\n",rc));
	    return 0;
	}	

	outb(cmd[i],LPTDATA);	/* Output data value */

	CONTROL(SELECT);		/* Command strobe bit */

	if (!status_wait(ACK,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Read Page Failed: No command Ack. (Status 0x%x)\n",rc));
	    return 0;
	}	

	CONTROL(0);

    }

    /* Wait for final status indicating ready to read */

    if (!(i=status_wait(BUSY,&rc))) {
	RMP_TRACE(fprintf(stderr, "Read Page Failed: Request not accepted (Status 0x%x)\n",rc));
	return 0;
    }	

    /* Set port to input mode and prepare to read */

    CONTROL(INIT|IPMODE);

    if (!status_wait(IO_READY,&rc)) {
	RMP_TRACE(fprintf(stderr, "Read Page Failed: No Data Ready Status (0x%x)\n",rc));
	return 0;
    }	

    /* Read page data */

    p = pp->data;	/* Pointer to page data buffer */

    for (i=0;i<PAGE_SIZE;i++) {

	if ((rc=(STATUS()&(ACK|BUSY))) != 0) {
	    RMP_TRACE(fprintf(stderr, "Read Page failure (Bad Status 0x%x)\n",rc));
	    return 0;
	}

	CONTROL(INIT|RD|IPMODE);	/* Assert Read signal */

	iodelay();

	*p++ = inb(LPTDATA);	/* Read data */

	CONTROL(INIT|IPMODE);	/* De-assert Read */

	iodelay();
    }

    /* Read tag data */

    p = pp->tag;	/* Pointer to page tag buffer */

    for (i=0;i<TAG_SIZE;i++) {

	CONTROL(INIT|RD|IPMODE);	/* Assert Read signal */

	iodelay();

	*p++ = inb(LPTDATA);	/* Read data */

	CONTROL(INIT|IPMODE);	/* De-assert Read */

	iodelay();

    }

    /* Return port to idle mode */

    CONTROL(0);

    return 1;	/* Exit, indicating page fetched ok */
}
/**************************** read_block ******************************/

/* Read block of data and return in passed buffer */

static int read_block(unsigned block,unsigned char *blkbuff)
{
    int tries;

    for (tries=0;tries<READ_RETRY_COUNT;tries++) {

	if (read_block_attempt(block,blkbuff))
	    return 1;

	sleep(RETRY_PAUSE);	/* Lazy: sleep to let player recover */
    }

    return 0;
}
/************************* read_block_attempt ************************/

static int read_block_attempt(unsigned block,unsigned char *blkbuff)
{
    register int i,j;
    unsigned rc,lastpage,buffsize,count;
    unsigned char *p;
    unsigned char cmd[]={0x5,0x47,0x0,0x0,0x4};

    /* Check device is idle */

    if (!ravemp_check_idle()) {
	RMP_TRACE(fprintf(stderr, "Read Page failed: Device not ready\n"));
	return 0;
    }

    /* Send command to the player device */

    cmd[2]=(block>>8)&0xff;
    cmd[3]=block&0xff;

    for (i=0;i<sizeof(cmd);i++) {

	if (!status_wait(IDLE,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Read Block Failed: Device not ready (Status 0x%x)\n",rc));
	    return 0;
	}	

	outb(cmd[i],LPTDATA);	/* Output data value */

	CONTROL(SELECT);		/* Command strobe bit */

	if (!status_wait(ACK,&rc)) {
	    RMP_TRACE(fprintf(stderr, 
			      "Read Block Failed: No command Ack. (Status 0x%x)\n",rc));
	    return 0;
	}	

	CONTROL(0);

    }

    /* Wait for final status indicating ready to read */

    if (!status_wait(BUSY,&rc)) {
	RMP_TRACE(fprintf(stderr, "Read Block Failed: Request not accepted (Status 0x%x)\n",rc));
	return 0;
    }	

    /* Read the data */

    p = blkbuff;

    for (i=0;i<PAGES_PER_BLOCK;i++) {

	/* Wait for device to indicate it's ready for read */

	CONTROL(INIT|IPMODE);

	if (!status_wait(IO_READY,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Read Block Failed: No Data Ready Status (Page %u 0x%x)\n",i,rc));
	    return 0;
	}	

	/* Read page of data */

	for (j=0;j<PAGE_SIZE+TAG_SIZE;j++) {

	    CONTROL(INIT|RD|IPMODE);	/* Assert Read signal */

	    iodelay();

	    *p++ = inb(LPTDATA);	/* Read data */

	    CONTROL(INIT|IPMODE);	/* De-assert Read */

	    iodelay();
	}

	/* After each page we need to signal the device to continue */

	CONTROL(0);	/* Tell device we've got the page */

	lastpage = i==PAGES_PER_BLOCK-1;

	if (!status_wait(lastpage?IDLE:BUSY,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Read Block Failed: Bad Status 0x%x after page read\n",rc));
	    return 0;
	}
    }

    /* Return port to idle mode and exit*/

    CONTROL(0);

    return i==PAGES_PER_BLOCK; /* True if read ok */
}
/********************** write_page ******************************/
#if 0	/* Write page command is unknown */
int write_page(unsigned block,unsigned page,struct page *pp)
{
    int tries;

    for (tries=0;tries<WRITE_RETRY_COUNT;tries++) {
	if (write_page_attempt(block,page,pp))
	    return 1;
    }
    return 0;
}
write_page_attempt(unsigned block,unsigned page,struct page *pp)
{
    RMP_TRACE(fprintf(stderr, "Wrote Block %u Page %u\n",block,page));
    return 1;
}
#endif
/**************************** write_block ******************************/

static int write_block(unsigned block,unsigned char *blkbuff)
{
    int tries;

    for (tries=0;tries<WRITE_RETRY_COUNT;tries++) {

	if (write_block_attempt(block,blkbuff))
	    return 1;

	sleep(RETRY_PAUSE);	/* Lazy: sleep to let player recover */

    }

    return 0;
}
/************************ write_block_attempt ************************/

static int write_block_attempt(unsigned block,unsigned char *blkbuff)
{
    register int i,j;
    unsigned rc,lastpage,buffsize,count;
    unsigned char *p;
    unsigned char cmd[]={0x5,0x4a,0x0,0x0,0x4};

    /* Check/wait for device idle */

    if (!ravemp_check_idle()) {
	RMP_TRACE(fprintf(stderr, "Write Block failed: Device not idle\n"));
	return 0;
    }

    /* Send command to the player device */

    cmd[2]=(block>>8)&0xff;
    cmd[3]=block&0xff;

    for (i=0;i<sizeof(cmd);i++) {

	count = 0;

	if (!status_wait(IDLE,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Write Block Failed: Device not ready (Status 0x%x)\n",rc));
	    return 0;
	}

	outb(cmd[i],LPTDATA);	/* Output data value */

	iodelay();

	CONTROL(SELECT);		/* Command strobe bit */

	if (!status_wait(ACK,&rc)) {
	    RMP_TRACE(fprintf(stderr, "Read Block Failed: No coommand Ack. (Status 0x%x)\n",rc));
	    return 0;
	}	

	CONTROL(0);

	iodelay();

    }

    /* Set up to write data */

    if (!status_wait(BUSY,&rc)) {
	RMP_TRACE(fprintf(stderr, "Write Block Failed: Bad Status 0x%x before Block Write\n",rc));
	return 0;
    }

    /* Write the data */

    p = blkbuff;

    for (i=0;i<PAGES_PER_BLOCK;i++) {

	CONTROL(INIT);

	if (!status_wait(IO_READY,&rc)) { /* Wait till ready for write */
	    RMP_TRACE(fprintf(stderr, "Write Block Failed: Bad Status B:0x%x before Page Write\n",rc));
	    CONTROL(0);
	    return 0;
	}

	for (j=0;j<(PAGE_SIZE+TAG_SIZE);j++) {

	    outb(*p,LPTDATA);	/* Write data */

	    iodelay();

	    CONTROL(INIT|WR);	/* Assert write signal */

	    iodelay();

	    CONTROL(INIT);		/* Output post-write pattern */

	    iodelay();

	    p++;
	}

	CONTROL(0);

	if (!status_wait(i==PAGES_PER_BLOCK-1?IDLE:BUSY,&rc)) { /* Wait for BUSY */
	    RMP_TRACE(fprintf(stderr, "Write Block Failed: Bad Status 0x%x after Page %u Write\n",rc,i));
	    CONTROL(0);
	    return 0;
	}
    }

    /* Return port to idle mode and exit */

    CONTROL(0);
    iodelay();

    return i==PAGES_PER_BLOCK; /* True if read ok */
}

/******************************** list_contents ******************************/

/*

 List MP3 files/all file information

 NOTE: Currently this routine only reports the first page of block zero (it
 should really check all FAT entries, i.e.MAX_BLOCKS/PAGE_SIZE).

*/

ravemp_slot *ravemp_slot_new(void)
{
    ravemp_slot *slot = (ravemp_slot *)malloc(sizeof(*slot));
    memset(slot, '\0', sizeof(*slot));
    return slot;
}

ravemp_slot **ravemp_contents(unsigned listall, int *nslots)
{
    int i, slots=0;
    unsigned char *p;
    struct page basepage,xpage;
    ravemp_slot **contents = NULL;
    ravemp_slot *slot;

    /* Read base page */

    if (!read_page(0,0,&xpage)) {
	RMP_TRACE(fprintf(stderr, "Unable to read first page\n"));
	return NULL;
    }

    p = &xpage.data[0];
    contents = (ravemp_slot **)malloc(sizeof(ravemp_slot *) * PAGE_SIZE);

    for (i=0;i<PAGE_SIZE;i++) {
	if (!listall) {
	    if (*p=='M') {	/* Header block for MP3 file? */
		slot = ravemp_slot_new();
		slot->type = 'M';
		slot->number = i;
		contents[slots++] = slot;
	    }
	}
	else {
	    switch (*p) {
	      case 'D':
	      case 'd':
	      case 'E':
	      case 'e':
	      case 'F':
	      case 'M':
	      case 'm':
	      case 'P':
	      case 'p':
	      case 'T':
	      case 't':
		slot = ravemp_slot_new();
		slot->type = *p;
		slot->number = i;
		contents[slots++] = slot;
		break;

	      case 0x00:	/* Bad */
	      case 0xcc:	/* Unused */
	      case 0xff:	/* Free */
		break;

	      default:
		break;
	    }
	}
	p++;
    }

    *nslots = slots;
    contents[slots] = NULL;

    return contents;
}

char *ravemp_get_filename(unsigned sblock)
{
    unsigned int i,block;
    unsigned char filedata[PAGES_PER_BLOCK*TAG_SIZE];
    unsigned char *blkbuff;
    struct page xpage;
    char *filename;
    int len;

    /* Read first page of file to get block list */

    if (!read_page(sblock,0,&xpage)) {
	RMP_TRACE(fprintf(stderr, "Failed to read Page 0 of header block\n"));
	return NULL;
    }

    /* Get second block number (contains file name */

    block = xpage.data[3] | (xpage.data[2]<<8);	/* 2nd block of file */

    if (block < MIN_DATA_BLOCK || block >= TOTAL_BLOCKS) {
	RMP_TRACE(fprintf(stderr, "Second block number %u invalid\n",block));
	return NULL;
    }

    /* Allocate data buffer */

    if ((blkbuff=malloc(MAX_BLOCK_SIZE)) == NULL) {
	RMP_TRACE(fprintf(stderr, "Memory Allocation failure\n"));
	return NULL;
    }

    /* Read file data */

    if (!read_block(block,blkbuff)) {
	RMP_TRACE(fprintf(stderr, "Error reading second block %u\n",block));
	free(blkbuff);
	return NULL;
    }

    /* Extract filename (max length assumed to be < (256-20) characters ) */

    memset(filedata,0,sizeof(filedata));

    for (i=0;i<256/TAG_SIZE;i++)
	memcpy(&filedata[i*TAG_SIZE],blkbuff+i*(PAGE_SIZE+TAG_SIZE)+PAGE_SIZE,TAG_SIZE);

    /* Display file information */

    len = strlen(&filedata[20]);
    filename = (char *)malloc(len+1);
    strncpy(filename, &filedata[20], len);
    *(filename + len) = '\0';
    free(blkbuff);

    return filename;
}
/**************************** dump_image ******************************/

/* Dump image data in the specified block */

static int dump_image(unsigned block,unsigned wide)
{
    unsigned i,j,bit,row;
    unsigned char c,*p,buff[80];
    struct page xpage;

    for (row=0;row < PAGES_PER_BLOCK*2*8;row++) {

	/* Pause once per display row (16 pixel rows) */

	if (row && (row&15)==0) {
	    printf("--- <Enter> for more, Q <Enter> to stop ---");
	    fgets(buff,sizeof(buff),stdin);
	    if (toupper(buff[0])=='Q')
		return 1;
	}

	/* Read new page every N rows */

	if ((row&31)==0) {
	    if (!read_page(block,row/32,&xpage)) {
		XP("Page Read failed!\n");
		return 0;
	    }
	}

	/* Dump row of data */

	p = &xpage.data[(row&31)*16];	/* Pick the row within the page */

	printf(" ");

	if (wide) { /* Needs at least 16*8+2 = 130 column screen */

	    for (j=0;j<16;j++) {

		bit = 0x80;
	
		for (i=0;i<8;i++) {
		    printf (*p&bit?"@":" ");
		    bit >>= 1;
		}
		p++;
	    }
	}
	else { /* Suitable for 80 column screens */

	    for (j=0;j<16;j++) {
		bit = *p++;
		for (i=0;i<4;i++) {
		    printf(bit&0xc0?"o":" ");
		    bit <<= 2;
		}
	    }
	}

	printf("\n");

    }
}
/**************************** dump_block ******************************/

/* Read specified block and display contents */

static int dump_block(unsigned block)
{
    register int i,rc;
    unsigned j,chunksize,buffsize;
    unsigned char *blkbuff,*p;
    unsigned char cmd[]={0x5,0x47,0x0,0x0,0x4};

    /* Determine buffer size and allocate it */

    chunksize = PAGE_SIZE+TAG_SIZE;

    buffsize = PAGES_PER_BLOCK * chunksize;

    if ((blkbuff=malloc(buffsize)) == NULL) {
	XP("Memory Allocation failure\n");
	exit();
    }

    /* Read the block */

    if (!read_block(block,blkbuff)) {
	XP("Dump failed - couldn't get block data\n");
	free(blkbuff);
	return 0;
    }

    /* Now dump the data */

    XP("Block 0x%x (%u)\n",block,block);

    p = blkbuff;
    for (j=0;j<buffsize;j+=16) {
	XP("%04x: ",j);
	hexdump_line(p);
	p+=16;
	XP("\n");
    }

    free(blkbuff);

    return 1;
}
/************************** dump_page *************************/
static int dump_page(unsigned block,unsigned page)
{
    unsigned i;
    unsigned char *p;
    struct page xpage;

    if (!read_page(block,page,&xpage)) {
	XP("Failed to read page\n");
	return 0;
    }

    /* Dump data */

    XP("Block 0x%x Page 0x%x (%u %u)\n",block,page,block,page);

    for (i=0;i<PAGE_SIZE;i+=16) {

	XP("%04x  ",i);

	p = &xpage.data[i];

	hexdump_line(p);

	XP("\n");
    }

    /* Dump tag data */

    XP("TAG:  ");

    p = &xpage.tag[0];

    hexdump_line(p);

    XP("\n");
}
/******************************* hexdump_line ****************************/
static void hexdump_line(unsigned char *p)
{
    int j;

    for (j=0;j<16;j++)
	XP("%02x ",*p++);

    XP("  ");
    p -= 16;

    for (j=0;j<16;j++,p++)
	XP("%c",*p<' '||*p>=127?'.':*p);
}
/***************************** read_numbers **************************/
static int read_numbers(unsigned char *p,unsigned count,...)
{
    int i,j,arg;
    unsigned int *ip;
    va_list ap;

    va_start(ap,count);

    for (i=0;i<count;i++) {

	if (strncasecmp(p,"0x",2)==0)
	    j = sscanf(p+2,"%x",&arg);
	else
	    j = sscanf(p,"%u",&arg);

	if (j < 1)
	    break;

	/* Get argument pointer (if any) and return decoded value */

	if ((ip=va_arg(ap,unsigned int *)) != NULL)
	    *ip = arg;

	/* Skip field just processed and white space following it */

	while (isdigit(*p)||tolower(*p)=='x'|| (tolower(*p)>='a'&&tolower(*p)<='f'))
	    p++;

	while (isblank(*p))
	    p++;
    }

    return i;	/* Return number of fields decoded */
}
/********************** XPV *****************************/
static void XPV(int level,char *fmt,...)
{
    /* To be implemented... */

#if 0
    if (level < xpv_level)
	return;
#endif

}
/************************ load_fat **********************/
static int load_fat(unsigned char *fatbuff)
{
    int i;
    struct page xpage;

    memset(fatbuff,0,TOTAL_BLOCKS);

    for (i=0;i<TOTAL_BLOCKS/PAGE_SIZE;i++) {

	if (!read_page(0,i,&xpage))
	    return 0;

	memcpy(fatbuff+(i*PAGE_SIZE),xpage.data,PAGE_SIZE);
    }

    return 1;
}
/************************ store_fat **********************/

static int store_fat(unsigned char *fatbuff)
{
    int i;
    unsigned char *blkbuff;

    /* Allocate block buffer */

    if ((blkbuff=malloc(MAX_BLOCK_SIZE)) == NULL) {
	XP("Memory Allocation failure\n");
	exit();
    }

    /* Read existing FAT data block */

    if (!read_block(0,blkbuff)) {
	XP("Update failed: Couldn't read FAT\n");
	free(blkbuff);
	return 0;
    }

    if (*blkbuff != 'F') {
	XP("Failure: Pre-write FAT validation error (0x%x should be 0xx)\n",*blkbuff,'F');
	free(blkbuff);
	return 0;
    }

    /* Copy new FAT area into block */

    for (i=0;i<TOTAL_BLOCKS/PAGE_SIZE;i++)	/* For each FAT data page... */
	memcpy(blkbuff+i*(PAGE_SIZE+TAG_SIZE),fatbuff+i*PAGE_SIZE,PAGE_SIZE);

    /* Write FAT data */

    if (!write_block(0,blkbuff)) {
	XP("FAT update error: Block write failed\n");
	free(blkbuff);
	return 0;
    }

#if 0 /* Display updated block */
    for (i=0;i<(8*(512+16))/16;i++) {
	XP("%u %04x  ",i%32,i*16);
	hexdump_line(blkbuff+i*16);
	XP("\n");
	if (i%32==31) {
	    XP("--more--\n");
	    if (getchar()=='q')
		break;
	}
    }
#endif

    free(blkbuff);

    return 1;
}

/************************ upload_file *********************/

/* Upload a file to the device */

int ravemp_upload_file(char *fname, char *dest_name)
{
    int i,j,mp3file,uploadok;
    int block,blk1no,blk2no,prvblk,nxtblk,page;
    unsigned fsize,fblocks,avail,namelen;
    unsigned char *p,*t,*firstblk,*datablk,*filebuff;
    unsigned char fat[TOTAL_BLOCKS];
    FILE *fp;
    struct stat fileinfo;

    uploadok = 0;

    /* Read device FAT */

    if (!load_fat(fat)) {
	RMP_TRACE(fprintf(stderr, "Unable to load allocation table\n"));
	return 0;
    }

    /* Count free blocks and determine header block numbers */

    avail = 0;

    blk1no = blk2no = -1;

    for (i=0;i<TOTAL_BLOCKS;i++) {

	if (fat[i]==0xff) {

	    if (blk1no == -1)
		blk1no = i;
	    else if (blk2no == -1)
		blk2no = i;

	    avail++;

	}
    }

    /* Get file information (note we simplistically determine if it's an MP3
       file or not by checking for a .mp3 extension) */

    if (stat(fname,&fileinfo) != 0) {
	RMP_TRACE(fprintf(stderr, "Unable to access file %s\n",fname));
	return 0;
    }

    fsize = fileinfo.st_size;

    fblocks = (fsize+DATA_SIZE-1)/DATA_SIZE;

    RMP_TRACE(fprintf(stderr, "File size: %u bytes [%u blocks needed, %u available]\n",fsize,fblocks,avail));

    if (fblocks+2 > avail) {	/* +2 for 2 header blocks */
	RMP_TRACE(fprintf(stderr, "Not enough space available for file\n"));
	return 0;
    }

    mp3file = ((p=strrchr(fname,'.')) != NULL && strcasecmp(p,".mp3")==0);

    /* Open file for upload */

    if ((fp=fopen(fname,"r"))==NULL) {
	RMP_TRACE(fprintf(stderr, "Unable to open file %s\n",fname));
	return 0;
    }

    /* Allocate memory for block buffers */

    if ((firstblk=malloc(MAX_BLOCK_SIZE))==NULL || 
	(datablk=malloc(MAX_BLOCK_SIZE)) == NULL ||
	(filebuff=malloc(DATA_SIZE)) == NULL) {
	RMP_TRACE(fprintf(stderr, "Unable to allocate memory for data buffers\n"));
	fclose(fp);
	return 0;
    }

    /* Build block list for file and put tag characters into FAT buffer */

    memset(firstblk,0xff,MAX_BLOCK_SIZE);	/* Set every value to "unused" */

    p = firstblk;

    *p++ = (blk1no>>8) & 0xff;
    *p++ = blk1no & 0xff;
    fat[blk1no] = mp3file?'M':'E';

    *p++ = (blk2no>>8) &0xff;
    *p++ = blk2no &0xff;
    fat[blk2no] = mp3file?'m':'e';

    for (i=TOTAL_BLOCKS-1,j=fblocks;i>=0&&j>0;i--) {

	if (fat[i]==0xff) {
	    fat[i]=mp3file?'m':'e';
	    *p++ = ((unsigned)i>>8) & 0xff;
	    *p++ = i & 0xff;
	    j--;
	}
    }

    /* Debug */
#if 0
    XP("MP3 File: %s\n",mp3file?"YES":"NO");
    p = firstblk;
    for (i=0;i<fblocks;i++) {
	printf("Block %u\n",(*p<<8) + *(p+1));
	p+=2;
    }
#endif

    /* Read file data and upload one block at a time */

    p = firstblk+4;	/* Pointer to first data block number */

    prvblk = blk1no;	/* Initialise "previous block" number for tag area */

    memset(datablk,0xff,DATA_SIZE); /* Initialise buffer (so all tag areas are 0xff) */

    for (i=0;i<fblocks;i++) {

	/* Read as much data as will fit into a single block */

	if ((j=fread(filebuff,1,DATA_SIZE,fp)) <= 0) {
	    RMP_TRACE(fprintf(stderr, "File Read failed - Upload aborted\n"));
	    goto uldone;
	}

	/* Copy file data into the pages within the block */

	for (page=0;page<PAGES_PER_BLOCK;page++)
	    memcpy(datablk+page*(PAGE_SIZE+TAG_SIZE),filebuff+(page*PAGE_SIZE),PAGE_SIZE);

	/* Set up the tag area in the first page of the block */

	block = (*p<<8) | *(p+1);	/* Get this block number */

	p+=2;						/* Update pointer for next time */

	nxtblk = (*p<<8) | *(p+1);	/* Next block we'll be writing to */

	t = datablk+PAGE_SIZE;
	memcpy(t,mp3file?"mp3\002":"ext\002",4);	/* File identifer */
	t += 4;

	*t++ = i>>8;		/* [4-5]: Block index */
	*t++ = i&0xff;

	*t++ = prvblk>>8;	/* [6-7]: Previous block number */
	*t++ = prvblk&0xff;

	*t++ = block>>8;	/* [8-9]: Current block number */
	*t++ = block&0xff;

	*t++ = nxtblk>>8;	/* [10-11]: Next block number (0xffff if none) */
	*t++ = nxtblk&0xff;

	*t++ = j>>8;		/* [12-13]: Data used within block */
	*t++ = j&0xff;

	*t++ = 0;			/* [14-15]: Zero (in data blocks) */
	*t++ = 0;

#if 0
	RMP_TRACE(fprintf(stderr, "Block %4u: ",block));
	hexdump_line(datablk+PAGE_SIZE);
	RMP_TRACE(fprintf(stderr, "\n"));
#endif

	prvblk = block;		/* Save current block as previous block for next time */

	/* Write the block out */

	/*		XP("Upload Block %u (Block index %u  Data loaded %u)\n",block,i,j); /**/

	if (!write_block(block,datablk)) {
	    RMP_TRACE(fprintf(stderr, "Upload failure: Write error (Block %u)\n",block));
	    goto uldone;
	}

	ravemp_status_dot();
	fflush(stdout);
    }

    RMP_TRACE(fprintf(stderr, "\n"));

    /* Set up the tags for the first and second blocks - note the tag layout is
       different for each of the first, second, and subsequent blocks */

    t = firstblk+PAGE_SIZE;

    *t++ = blk2no>>8;		/* [First block 0-1]: Next (second) block number */
    *t++ = blk2no&0xff;

    t += 8;

    *t++ = blk2no>>8;		/* [First block 10-11]: Next block number (0xffff if none) */
    *t++ = blk2no&0xff;		/* NOTE: This may not be correct in all cases (possibly first file is different) */

    /* Second block */

    for (i=0;i<PAGES_PER_BLOCK;i++) {		/* Clear image display area */

	t = datablk+i*(PAGE_SIZE+TAG_SIZE);	/* Pointer to page data */

	if (i < 16) {
	    memset(t,0,PAGE_SIZE);
	    memset(t+PAGE_SIZE,0xff,TAG_SIZE);
	}
	else if (i == 16) {
	    memset(t,0xff,PAGE_SIZE);
	    memset(t+PAGE_SIZE,0xff,TAG_SIZE);
	}
	else if (i==17) {
	    memset(t,0xff,PAGE_SIZE);
	    memset(t+PAGE_SIZE,0xff,8);
	    memset(t+PAGE_SIZE+8,0x0,8);
	}
	else {
	    memset(t,0xff,PAGE_SIZE);
	    memset(t+PAGE_SIZE,0x0,TAG_SIZE);
	}
    }

    /* Set up the Second block tags for Page 0 */

    t = datablk+PAGE_SIZE;	/* Point to tags area */

    memcpy(t,mp3file?"mp3\002":"ext\002",4);	/* File identifer */
    t += 4;

    *t++ = fblocks>>8;		/* [2nd block 4-5]: Highest data block index + 1 */
    *t++ = fblocks&0xff;

    *t++ = blk1no>>8;		/* [2nd block 6-7]: First block number */
    *t++ = blk1no&0xff;

    *t++ = blk2no>>8;		/* [8-9]: Current block number */
    *t++ = blk2no&0xff;

    *t++ = *(firstblk+4);	/* [10-11]: Next block number (first data block) */
    *t++ = *(firstblk+5);

    /* Following items are updated later (once we have the file name length/image size) */

    *t++ = 0;	/* [12-13]: Data used within block (pixel data in this block) */
    *t++ = 0;

    *t++ = 0;	/* [14-15]: Meaning unknown (number of screens of pixel data, 4 max?) */
    *t++ = 0;

    /* Set the second block tags for Page 1 and above */

    t = datablk+PAGE_SIZE+TAG_SIZE+PAGE_SIZE; /* Point to Page 1 tag area */

    *t++ = (fsize>>24)&0xff; /* [2nd block 16-19]: File size */
    *t++ = (fsize>>16)&0xff;
    *t++ = (fsize>>8)&0xff;
    *t++ = fsize&0xff;

    if (dest_name == NULL) {
	dest_name = fname;
    }
    if ((i=strlen(dest_name)) > 255)
	i = 255;

    if (i<TAG_SIZE-4)
	strcpy(t,dest_name);
    else {
	memcpy(t,dest_name,TAG_SIZE-4);

	i = i - (TAG_SIZE-4) + 1;	/* Characters left to copy (inc. \0) */

	p = dest_name + TAG_SIZE-4;

	for (page=2;i>0&&page<PAGES_PER_BLOCK;page++) {

	    t = datablk+page*(PAGE_SIZE+TAG_SIZE)+PAGE_SIZE; /* Tag area for this page */

	    j = i>TAG_SIZE?TAG_SIZE:i; /* Characters to copy */

	    memcpy(t,p,j);	/* Copy as much of name as possible into tag */

	    i -= j;			/* Count off characters copied */

	    p += TAG_SIZE;	/* Advance file name pointer */
	}
    }

    /*
      The second block of the file contains the image data for the devices LCD
      display. The display is pixmapped and the area used for a single row of
      characters is 128x16 pixels (8Hx16V characters with 1bpp). There are
      therefore 128*16/8 bytes per character row and 32 characters per page.
    */

    p = dest_name;	/* Text to be converted to pixmap */

    if ((namelen=strlen(p)) > 4) { /* Don't count ".mp3" at end if present */
	if (strcasecmp(".mp3",p+namelen-4) == 0)
	    namelen -= 4;
    }

    for (i=0;i<namelen;i++) {

	t = datablk + (i/32)*(PAGE_SIZE+TAG_SIZE); /* Pointer to page */

	t += (i&16)*16+(i%16);	/* Point to first byte of character cell */

	for (j=0;j<16;j++) {	/* For each row of the character...*/
	    *t = fontdata_8x16[*p*16+j];	/* Copy row of pixels */
	    t += 16;		/* Advance to next row of pixels of char. cell */
	}

	p++;
    }

    /* We now know how many characters were placed in the display data - update
       the page 0 tags for the second block. */

    t = datablk + PAGE_SIZE + 12;	/* Offset to Page 0 tags, size info */

    j = (namelen+31)/32 * (PAGE_SIZE+TAG_SIZE); /* Total pages used for image data */

    /* WARNING: These values may not be correct as the full details of how the player
       interprets them isn't know. If incorrect, the expected consequence is over or
       under display of track titles on the player display */

    /*XP("Name length %u Data usage %u Screens %u\n",namelen,j,(namelen+15)/16); /**/

    *t++ = j>>8;		/* [2nd block Page 1 12-13]: Data used in block */
    *t++ = j&0xff;

    *t++ = (namelen+15)/16;	/* [2nd block Page 1 14-15]: Display screen count? */
    *t++ = 0;

    /* Write first and second blocks out, and update FAT */

    if (!write_block(blk1no,firstblk)) {
	RMP_TRACE(fprintf(stderr, "Upload Failure: Unable to update block list [Block %u]\n",blk1no));
	goto uldone;
    }

    if (!write_block(blk2no,datablk)) {
	RMP_TRACE(fprintf(stderr, "Upload Failure: Unable to update header block [Block %u]\n",blk2no));
	goto uldone;
    }

    if (!store_fat(fat)) {
	RMP_TRACE(fprintf(stderr, "Upload failure: Unable to update directory\n"));
	goto uldone;
    }

    uploadok = 1;

    RMP_TRACE(fprintf(stderr, "File %s (size %u) uploaded.\n",fname,fsize));

    /* Exit path - clean up and return success/failure indication */

 uldone:
    free(filebuff);
    free(datablk);
    free(firstblk);
    fclose(fp);

    return uploadok;

}
/************************ download *************************/

/*

  File download (from player device to file)

  The first block of file holds the block number list

  The second block of file contains information about the file
  (including its name) in the tags area, while the data area
  contains the pixel image data for the LCD display.

  The third and subsequent blocks contain the MP3 data.

*/

int ravemp_download(unsigned firstblock, char *dest)
{
    unsigned i,j,k,dlok,page;
    unsigned chunksize,buffsize,fsize,wrsize;
    unsigned char *p,tagbuff[PAGES_PER_BLOCK*TAG_SIZE],*baseblk,*datablk;
    struct stat fileinfo;
    struct page xpage;
    FILE *fp;

    /* Determine buffer size and allocate it */

    chunksize = PAGE_SIZE+TAG_SIZE;

    buffsize = PAGES_PER_BLOCK * chunksize;

    if ((baseblk=malloc(buffsize)) == NULL || (datablk=malloc(buffsize)) == NULL) {
	RMP_TRACE(fprintf(stderr, "Memory Allocation failure\n"));
	return 0;
    }

    /* Read first block of file, which contains the list of blocks used */

    if (!read_block(firstblock,baseblk)) {
	RMP_TRACE(fprintf(stderr, "Read of First Block failed\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Read second block of file, which holds the file information */

    j = (*(baseblk+2)<<8) | *(baseblk+3);

    if (!read_block(j,datablk)) {
	RMP_TRACE(fprintf(stderr, "Read of Second Block failed\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Extract file size */

    p = datablk+PAGE_SIZE+TAG_SIZE+PAGE_SIZE; /* Point to second page tag area */

    fsize = 0;
    for (i=0;i<4;i++)
	fsize = (fsize<<8) | *p++;

    if (fsize==0 || fsize > TOTAL_BLOCKS*PAGE_SIZE*PAGES_PER_BLOCK) {
	RMP_TRACE(fprintf(stderr, "Bad file size: %u bytes reported\n",fsize));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Extract filename, which is spread across the tags, starting at offset 20 (we
       assume the name length to less than 256-20 or 226 characters) */

    for (i=0;i<256/TAG_SIZE;i++)	/* Collect all tags into buffer */
	memcpy(&tagbuff[i*TAG_SIZE],datablk+i*(PAGE_SIZE+TAG_SIZE)+PAGE_SIZE,TAG_SIZE);

    RMP_TRACE(fprintf(stderr, "File Name: %s File Size: %u\n",&tagbuff[20],fsize)); /**/

    /* Check if file already exists */

    if (stat(&tagbuff[20],&fileinfo) == 0) {
	RMP_TRACE(fprintf(stderr, "\n*** File with same name already exists - download cancelled ***\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Create file to save data in */

    if (dest == NULL) {
	dest = &tagbuff[20];
    }

    if ((fp=fopen(dest, "w"))==NULL) {
	RMP_TRACE(fprintf(stderr, "Unable to create file to download into!\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Read all file blocks in turn */

    dlok = 1;
    for (page=0;page<PAGES_PER_BLOCK&&dlok&&fsize>0;page++) {

	memcpy(&xpage,baseblk+page*chunksize,chunksize);

	p = &xpage.data[4];	/* Pointer to block list (skipping first 2 blocks) */

	for (i=0;i<PAGE_SIZE/2&&fsize;i++) {

	    j = *p++<<8;

	    j |= *p++;

	    if (j<MIN_DATA_BLOCK || j>=TOTAL_BLOCKS) {
		RMP_TRACE(fprintf(stderr, "Download Failure: Bad Block number %u [Outside Range %u-%u]\n",j,MIN_DATA_BLOCK,TOTAL_BLOCKS-1));
		dlok = 0;
		break;
	    }

	    if (!read_block(j,datablk)) {
		RMP_TRACE(fprintf(stderr, "Error reading Block %u\n",j));
		dlok = 0;
		break;
	    }

	    for (k=0;k<PAGES_PER_BLOCK&&fsize;k++) {

		wrsize = fsize>PAGE_SIZE?PAGE_SIZE:fsize;

		if (fwrite(datablk+k*(PAGE_SIZE+TAG_SIZE),1,wrsize,fp) != wrsize) {
		    RMP_TRACE(fprintf(stderr, "File Write Error!\n"));
		    dlok = 0;
		    break;
		}

		fsize -= wrsize;
	    }
	    ravemp_status_dot();
	    fflush(stdout);
	}
    }

    RMP_TRACE(fprintf(stderr, "\n"));

    free(baseblk);
    free(datablk);

    fclose(fp);

    return dlok;
}
/************************ remove_file *************************/

int ravemp_remove_file(unsigned firstblock)
{
    unsigned i,j,page,offset;
    unsigned char *p,*baseblk,*datablk;
    unsigned char ftype,fat[TOTAL_BLOCKS];

    /* Load the device FAT */

    if (!load_fat(fat)) {
	RMP_TRACE(fprintf(stderr, "Unable to read allocation table\n"));
	return 0;
    }

    /* Determine buffer size and allocate it */

    if ((baseblk=malloc(MAX_BLOCK_SIZE)) == NULL || (datablk=malloc(MAX_BLOCK_SIZE)) == NULL) {
	RMP_TRACE(fprintf(stderr, "Memory Allocation failure\n"));
	return 0;
    }

    /* Read first block of file, which contains the list of blocks used */

    if (!read_block(firstblock,baseblk)) {
	RMP_TRACE(fprintf(stderr, "Read of First Block failed\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Read second block of file, which holds the file information */

    j = (*(baseblk+2)<<8) | *(baseblk+3);

    if (!read_block(j,datablk)) {
	RMP_TRACE(fprintf(stderr, "Read of Second Block failed\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Check the block list is consistent with the FAT */

    if (!isalpha((ftype=fat[firstblock])) || !isupper(ftype)) {
	RMP_TRACE(fprintf(stderr, "Allocation Table entry doesn't indicate file start "));
	RMP_TRACE(fprintf(stderr, isprint(ftype)?"['%c']":"[0x%0x]",ftype));
	RMP_TRACE(fprintf(stderr, "\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    /* Confirm all additional blocks in fat have correct type. Note that
       the first time though this loop (the first block), the file type
       is upper case whereas it's lower case for all extra blocks */

    for (i=0;i<TOTAL_BLOCKS;i++) {

	offset = i*2;
	page = offset/PAGE_SIZE;
	offset %= PAGE_SIZE;

	p = baseblk + page*(PAGE_SIZE+TAG_SIZE) + offset;

	j = *p++<<8;
	j |= *p++;

	if (j == 0xffff)	/* End of list? */
	    break;

	if (j != 0x0 && (j<MIN_DATA_BLOCK || j >= TOTAL_BLOCKS)) {
	    RMP_TRACE(fprintf(stderr, "Bad block number in block list (0x%x)\n",j));
	    free(baseblk);
	    free(datablk);
	    return 0;
	}

	if (fat[j] != ftype) {
	    RMP_TRACE(fprintf(stderr, "Block %u: Not correct type for file (0x%x should be 0x%x)\n",j,fat[j],ftype));
	    free(baseblk);
	    free(datablk);
	    return 0;
	}

	ftype = tolower(ftype);	/* Expected file type for additional blocks */

	fat[j] = 0xff;	/* Mark block as free */
    }

    /* FAT entries have been updated - write the data out */

    if (!store_fat(fat)) {
	RMP_TRACE(fprintf(stderr, "Allocation table update failed\n"));
	free(baseblk);
	free(datablk);
	return 0;
    }

    RMP_TRACE(fprintf(stderr, "File removed.\n"));

    free(baseblk);
    free(datablk);

    return 1;
}

/************************ info ***************************/

static void info(unsigned firstblock)
{
    unsigned chunksize,buffsize;
    unsigned char *baseblk,*datablk;

    /* Determine buffer size and allocate it */

    chunksize = PAGE_SIZE+TAG_SIZE;

    buffsize = PAGES_PER_BLOCK * chunksize;

    if ((baseblk=malloc(buffsize)) == NULL || (datablk=malloc(buffsize)) == NULL) {
	XP("Memory Allocation failure\n");
	exit();
    }

    show_info(firstblock,baseblk,datablk);

    free(baseblk);
    free(datablk);
}
/******************** show_info ************************/
static int show_info(unsigned firstblock,unsigned char *baseblk,unsigned char *datablk)
{
    unsigned i,j,k,page;
    unsigned long il;
    unsigned char *p,buff[TAG_SIZE*PAGES_PER_BLOCK];
    struct page xpage;

    /* Read first block of file, which contains the list of blocks used */

    if (!read_block(firstblock,baseblk)) {
	XP("Read of First Block failed\n");
	return 0;
    }

    /* Read second block of file, which holds the file information */

    j = (*(baseblk+2)<<8) | *(baseblk+3);

    if (!read_block(j,datablk)) {
	XP("Read of Second Block failed\n");
	return 0;
    }

    p = datablk;
    for (i=0;i<PAGES_PER_BLOCK;i++)
	memcpy(&buff[i*TAG_SIZE],p+i*(PAGE_SIZE+TAG_SIZE)+PAGE_SIZE,TAG_SIZE);

    /* 0-2 contain 3-digit file type */

    XP("File Type: %c%c%c\n",buff[0],buff[1],buff[2]);

    /* Offset 3: Unknown, various values */

    /* TBI */

    /* Offset 4-5: Number of blocks (TBC) [Block Offset after 2nd block] */

    i = (buff[4]<<8) | buff[5];
    XP("Number of Blocks(?): %u (0x%x)\n",i,i);

    /* Offset 6-7: Previous block number */

    i = (buff[6]<<8) | buff[7];
    XP("Previous Block: %u (0x%x)\n",i,i);

    /* Offset 8-9: Current block number */

    i = (buff[8]<<8) | buff[9];
    XP("Current Block: %u (0x%x)\n",i,i);

    /* Offset 10-11: Next block number [0xffff for last block] */

    i = (buff[10]<<8) | buff[11];
    XP("Next Block: %u (0x%x)\n",i,i);

    /* Offset 12-13: Data present within block [2nd Block: Image size?] */

    i = (buff[12]<<8) | buff[13];
    XP("Data present: %u (0x%x)\n",i,i);

    /* Offset 14-15: Unknown  */

    XP("Unknown data [14-15]: ");

    p = &buff[14];
    for (i=0;i<2;i++)
	XP("0x%02x ",*p++);
    XP("\n");

    /* Offset 16-19: File size */

    p = &buff[16];
    il = 0L;
    for (i=0;i<4;i++)
	il = (il<<8) | *p++;
    XP("File Size: %lu\n",il);

    /* Offset 20 onwards: File name */

    XP("File Name: %.60s\n",&buff[20]);

    /* Walk and display all tags */

    XP("Tags\n----\n");

    p = baseblk;

    for (i=0;i<PAGE_SIZE/2;i++) {

	j = *p++<<8;

	j |= *p++;

	if (j>=MIN_DATA_BLOCK && j<TOTAL_BLOCKS) {

	    if (!read_page(j,0,&xpage)) {
		XP("Error reading Block %u Page %u\n",j,0);
		return 0;
	    }

	    XP("  Block 0x%03x  ",j);
	    hexdump_line(&xpage.tag[0]);
	    XP("\n");
	}
    }

    return 1;
}
/**************************** iodelay **************************/

/*
  Delay function, used to provide a short delay between hardware accesses.
  Note that some calls to iodelay() will in fact be unnecessary, but
  determining which ones requires additional effort. For example,
  during data writes it's almost certainly okay to change the port
  data and control signals without a delay - but it's necessary to
  determine which edge the write takes place on in order to do this.

  During testing, no read delays were found to be necessary on
  the development PC (ASUS P2BS M/B 400Mhz PII). No attempt was made
  to test writes without delays. To experiment, simply comment out
  this routine and '#define iodelay()' to get zero delay.

  The actual delay is created by reading the LPT status port, which
  typically takes 1 or 2 usecs irrespective of the PC speed.
*/

static void iodelay(void)
{
    int i;

    for (i=0;i<DELAY_CYCLES;i++)
	inb(port+2);
}
/**************************** status_wait **************************/
static int status_wait(unsigned pattern,unsigned *rc)
{
    int i;

    i = 1;

    while ((*rc=(STATUS()&STATUS_MASK)) != pattern) {
	if (++i > 60000)
	    return 0;
    }

    return i;	/* Return number of cycles for diagnostic purposes */
}

int ravemp_permitted(void)
{
    return (ioperm(port, 3, 1) == 0);
}

/*********************** ravemp_check_idle **************************/
int ravemp_check_idle(void)
{
    int i;

    CONTROL(0);

    iodelay();

    for (i=0;i<10;i++) {

	if ((STATUS()&STATUS_MASK) == IDLE)
	    return 1;

	usleep(100000);
    }
}

/***************************** lpt_test ****************************/
static void lpt_test(int lptport)
{
    int i,j,data,failed,diffs;

    XP("Testing Port at 0x%x...\n",lptport);

    if (ioperm(lptport,3,1) != 0) {
	XP("Unable to gain permission to access port (must be root or suid)\n");
	return;
    }

    /* Test port in output-only mode */

    XP("Checking basic output mode...");

    outb(0,lptport);	/* Make port output */

    iodelay();

    failed =0;

    for (i=0;i<20;i++) {

	j = 0xaa;
	outb(j,lptport);
	iodelay();
	if ((data=inb(lptport)) != j && !failed) {
	    XP("Fail! [Output echo 0x%x differs from 0x%x]\n",data,j);
	    failed=1;
	}

	j = 0x55;
	outb(j,lptport);
	iodelay();
	if ((data=inb(lptport)) != j && !failed) {
	    XP("Fail! [Output echo 0x%x differs from 0x%x]\n",data,j);
	    failed=1;
	}

    }

    if (!failed)
	XP("Passed.\n");
    else {
	XP("\n*** Mostly likely cause is incorrect port address ***\n");		
	return;
    }

    /* Test port in input mode (output data should not be echoed) */

    XP("Checking input mode...");

    outb(IPMODE,lptport+2);	/* Make port input */

    iodelay();

    diffs = 0;

    for (i=0;i<20;i++) {

	j = 0xaa;
	outb(j,lptport);
	iodelay();
	if (inb(lptport) != j)
	    diffs++;

	j = 0x55;
	outb(j,lptport);
	iodelay();
	if (inb(lptport) != j)
	    diffs++;
    }

    if (diffs<20) {
	if (diffs==0) {
	    XP("Fail! [Reads back output data in input mode]\n");
	    XP("\n*** Mostly likely cause is wrong BIOS mode (try options like EPP and ECP) ***\n");
	    XP("\n*** On older PC's, may be caused by output-only port hardware             ***\n");
	}
	else {
	    XP("Fail! [Input mode appears unreliable]\n");
	    XP("\n*** Possible causes: Bad hardware, cabling or BIOS mode ***\n");
	}
    }
    else
	XP("Passed.\n");

    outb(0,lptport);

    XP("Port Diagnostics complete.\n");
}

/************************ dump_tags ***************************/

/* Dump tag data for each active FAT entry */

static int dump_tags(unsigned value)
{
    unsigned i;
    unsigned char *p,buff[TAG_SIZE*PAGES_PER_BLOCK];
    struct page xpage,basepage;

    /* NOTE: Only reporting Page 0 at present! */

    if (!read_page(0,0,&basepage)) {
	XP("Error reading base page\n");
	return 0;
    }

    for (i=MIN_DATA_BLOCK;i<PAGE_SIZE;i++) {

	if (isalpha(basepage.data[i])) {

	    if (!read_page(i,0,&xpage)) {
		XP("Error reading data page\n");
		return 0;
	    }

	    XP("Page 0x%03x Type %c: ",i,basepage.data[i]);
	    hexdump_line(xpage.tag);
	    XP("\n");
	}
    }
}

/************************** write_tests **************************/

/* Pick unused block at random and perform read/write test */

static int write_tests(void)
{
    int i,errors;
    unsigned block;
    unsigned char blkdata[MAX_BLOCK_SIZE];
    unsigned char rdata[MAX_BLOCK_SIZE];
    unsigned char fat[TOTAL_BLOCKS];
    time_t tnow;

    XP("Loading FAT...\n");

    if (!load_fat(fat)) {
	XP("FAT read failed\n");
	return 0;
    }

    time(&tnow);

    while (time(NULL)==tnow)
	rand();

    XP("Searching for free block...");

    for (i=0;i<TOTAL_BLOCKS*2;i++) {

	block = rand()%TOTAL_BLOCKS;

	if (fat[block]==0xff)
	    break;
    }

    if (fat[block] != 0xff) {
	XP("Couldn't find a free block\n");
	return 0;
    }

    XP("Block %u\n",block);

    memset(blkdata,0xa5,sizeof(blkdata));

    for (i=0;i<sizeof(blkdata);i++)
	blkdata[i]=rand();

    for (i=0;i<PAGES_PER_BLOCK;i++)
	memset(&blkdata[i*(PAGE_SIZE+TAG_SIZE)+PAGE_SIZE],0xff,TAG_SIZE);

    XP("Writing test pattern to block\n");

    if (!write_block(block,blkdata)) {
	XP("Write block failed\n");
	return 0;
    }

    XP("Post-write pause....\n");

    usleep(1000000); /* Need to wait for player to finish updates */


    XP("Re-Reading block...\n");

    memset(rdata,0x0,sizeof(rdata));

    if (!read_block(block,rdata)) {
	XP("Read block failed\n");
	return 0;
    }

    XP("Checking data...\n");
    errors = 0;

    for (i=0;i<MAX_BLOCK_SIZE;i++) {
	if (rdata[i] != blkdata[i]) {
	    if (errors < 20) {
		XP("Data Error - Offset %u [Write 0x%02x  Read 0x%02x]\n",
		   i,blkdata[i],rdata[i]);
	    }
	    errors++;
	}
    }

    XP("Complete - Total Errors: %u\n",errors);

}

static int show_blocktags(unsigned block)
{
    int i,j,k,bit;
    unsigned char *p,blkdata[MAX_BLOCK_SIZE];


    if (!read_block(block,&blkdata[0])) {
	XP("Block read failed\n");
	return 0;
    }

    XP("Block %u\n",block);

    /* Hex data */

    for (i=0;i<PAGES_PER_BLOCK;i++) {
	XP("Page %02u: ",i);
	hexdump_line(&blkdata[i*(PAGE_SIZE+TAG_SIZE)+PAGE_SIZE]);
	XP("\n");
    }

    return 1;
}

static int grab_blocks(unsigned sblock,unsigned count)
{
    int i,j,k;
    unsigned char *p,buff[80],blkdata[MAX_BLOCK_SIZE];
    FILE *fp;

    sprintf(buff,"blk%u",sblock);

    if ((fp=fopen(buff,"w"))==NULL) {
	XP("Unable to create file %s\n",buff);
	return 0;
    }

    for (i=0;i<count;i++) {

	if (!read_block(sblock,&blkdata[0])) {
	    XP("Block %u: Read failed\n",sblock);
	    return 0;
	}

	XP("Block %u\n",sblock);

	k = MAX_BLOCK_SIZE;

	if (fwrite(blkdata,1,k,fp) != k) {
	    XP("File Write Error!\n");
	    break;
	}

	sblock++;
    }

    XP("Grabbed %u block(s) into file %s\n",i,buff);

    fclose(fp);

    return 1;
}
