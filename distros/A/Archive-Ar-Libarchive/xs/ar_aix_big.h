#ifndef AR_AIX_BIG_H
#define AR_AIX_BIG_H

/*
 * http://www-01.ibm.com/support/knowledgecenter/ssw_aix_61/com.ibm.aix.files/ar_big.htm
 * NOT USED.  but might be one day.
 */

#define AIAMAGBIG "<bigaf>\n"
#define SAIAMAGBIG 8

struct aix_big_fl_hdr
{
  char fl_magic[SAIAMAGBIG];     /* Archive magic string */
  char fl_memoff[20];            /* Offset to member table */
  char fl_gstoff[20];            /* Offset to gloal symbol table */
  char fl_gst64off[20];          /* Offset to gloal symbol table for 64-bit objects */
  char fl_fstmoff[20];           /* Offset to first archive member */
  char fl_lstmoff[20];           /* Offset to last archive member */
  char fl_freeoff[20];           /* Offset to first member on free list */
};

struct aix_big_ar_hdr
{
  char ar_size[20];              /* File member size        - decimal */
  char ar_nxtmem[20];            /* Next member offset      - decimal */
  char ar_prvmem[20];            /* Previous member offset  - decimal */
  char ar_date[12];              /* File member date        - decimal */
  char ar_uid[12];               /* File member userid      - decimal */
  char ar_gid[12];               /* File member group id    - decimal */
  char ar_mode[12];              /* File member mode        - octal   */
  char ar_namelen[4];            /* File member name length - decimal */
  union {
    char ar_name[2];             /* Start of member name */
    char ar_fmag[2];             /* "`\n" */
  } _ar_name;
};

#endif
