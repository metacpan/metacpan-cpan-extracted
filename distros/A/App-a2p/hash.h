/*    hash.h
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1999, 2000, 2005
 *    by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#define FILLPCT 60		/* don't make greater than 99 */

typedef struct hentry HENT;

struct hentry {
    HENT	*hent_next;
    char	*hent_key;
    STR		*hent_val;
    int		hent_hash;
};

struct htbl {
    HENT	**tbl_array;
    int		tbl_max;
    int		tbl_fill;
    int		tbl_riter;	/* current root of iterator */
    HENT	*tbl_eiter;	/* current entry of iterator */
};

STR * hfetch ( HASH *tb, char *key );
int hiterinit ( HASH *tb );
HASH * hnew ( void );
void hsplit ( HASH *tb );
bool hstore ( HASH *tb, char *key, STR *val );
