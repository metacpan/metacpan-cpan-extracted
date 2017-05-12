/* Relentlessly copied from DBD-Oracle (one has to start somewhere ...) */

#include "ppport.h"

#if defined(get_no_modify) && !defined(PL_no_modify)
# define PL_no_modify PL_no_modify
# endif

/* I really like this one in perl ... */
#define	unless(e)	if (!(e))

/* ====== Include Unify Header Files ====== */

#include <fdesc.h>
#include <rhli.h>
#include <rhlierr.h>

typedef	unsigned char	byte;

/* Unify API calls used */

char *atold (char *buf, UTP_HDTE *ldate);/* returns null on error or pointer
					 * to location just past last character */

int   ldtoa (UTP_HDTE ldate, char *buf);	/* returns zero on success */

char *atotime (char *buf, short *time);	/* returns null on error or pointer
					 * to location just past last character */

char *timetoa (short time);		/* returns pointer to static buf;
					 * silently converts bad times to
					 * strings, e.g., 2910 -> 29:10 */

char *ufchmsg (USTATUS errnum,    USTATUS *status);
int   uinimsg (char *programname, USTATUS *status); /* assigns program name
						     * to logging system */

USTATUS	SQLCODE;

/* ====== define data types ====== */

typedef struct imp_fld_st imp_fld_t;

#ifndef UEXTERN
#  define UEXTERN
#  define UINIT0
#  endif
UEXTERN	short	n_dbh UINIT0;

struct imp_drh_st {
    dbih_drc_t	com;		/* MUST be first element in structure	*/
    };

/* Define dbh implementor data structure */
struct imp_dbh_st {
    dbih_dbc_t	com;		/* MUST be first element in structure	*/

    short	id;		/* DB Handle ID for dynamic naming	*/
    int		unicode;	/* Decode unicode on fetch		*/
    int		nchildren;
    imp_sth_t	**children;	/* Keep track of prepared statements	*/
    };

#define ST_STAT_ALLOCP	0x01
#define ST_STAT_ALLOCC	0x02
#define ST_STAT_ALLOCI	0x04
#define ST_STAT_ALLOCO	0x08
#define ST_STAT_OPEN	0x10
/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t	com;		/* MUST be first element in structure	*/

    short	id;		/* Statement ID, for dynamic naming	*/
    short	stat;		/* Cursor open/closed			*/
    char	*statement;	/* Statement text			*/

    imp_fld_t	*fld;		/* Add knowledge about the fields	*/
    imp_fld_t	*prm;		/* Add knowledge about the positionals	*/

    int		dbd_verbose;	/* statement level verbosity		*/
    int		unicode;	/* Decode unicode on fetch		*/
    };

struct imp_fld_st {
    char	fnm[48];	/* Name		*/
    int		ftp;		/* Type		*/
    int		fln;		/* Length	*/
    int		fpr;		/* Precision	*/
    int		fic;		/* Indicator	*/
    int		fsc;		/* Scale	*/
    int		fnl;		/* NULL		*/
    SV		*val;		/* parameter	*/
    };

/* These defines avoid name clashes for multiple statically linked DBD's	*/

#define dbd_init            uni_init
#define dbd_db_login        uni_db_login
#define dbd_db_do           uni_db_do
#define dbd_db_commit       uni_db_commit
#define dbd_db_rollback     uni_db_rollback
#define dbd_db_disconnect   uni_db_disconnect
#define dbd_db_destroy      uni_db_destroy
#define dbd_db_STORE_attrib uni_db_STORE_attrib
#define dbd_db_FETCH_attrib uni_db_FETCH_attrib
#define dbd_st_prepare      uni_st_prepare
#define dbd_st_rows         uni_st_rows
#define dbd_st_execute      uni_st_execute
#define dbd_st_fetch        uni_st_fetch
#define dbd_st_finish       uni_st_finish
#define dbd_st_destroy      uni_st_destroy
#define dbd_st_blob_read    uni_st_blob_read
#define dbd_st_STORE_attrib uni_st_STORE_attrib
#define dbd_st_FETCH_attrib uni_st_FETCH_attrib
#define dbd_describe        uni_describe
#define dbd_bind_ph         uni_bind_ph

/* end */
