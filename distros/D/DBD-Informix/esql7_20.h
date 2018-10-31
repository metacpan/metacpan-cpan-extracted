/*
@(#)File:           $RCSfile: esql7_20.h,v $
@(#)Version:        $Revision: 2009.1 $
@(#)Last changed:   $Date: 2009/02/27 06:32:49 $
@(#)Purpose:        Function prototypes for ESQL/C Versions 7.20..7.24
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1997,1999-2000,2003-06,2008-09
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
*/

/*TABSTOP=4*/

#ifndef ESQL7_20_H
#define ESQL7_20_H

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_esql7_20_h[] = "@(#)$Id: esql7_20.h,v 2009.1 2009/02/27 06:32:49 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

/*
** JL 2009-02-26
** Reports from people using ESQL/C 7.23 indicate that some of our code
** uses ifx_sqlca_t, ifx_sqlda_t, and ifx_sqlvar_t but these were not
** typedef'd in ESQL/C 7.2x.
*/
typedef struct sqlca_s       ifx_sqlca_t;
typedef struct sqlvar_struct ifx_sqlvar_t;
typedef struct sqlda         ifx_sqlda_t;

/*
** JL 2000-06-29:
** Although struct hostvar_struct should have been declared because
** <sqlhdr.h> should have been included by now, there have been problem
** reports that encouraged a previous version of this code to write
** 'struct hostvar_struct;' inline to avoid complaints from GCC, but
** this in turn incited complaints from the HP ANSI C compiler.
*/
#include <sqlhdr.h>
#ifndef MAXADDR
#include <value.h>
#endif /* MAXADDR */

/*
** JL 1997-04-24:
** The 7.2x ESQL/C compiler can generate calls to the following functions
** but sqlhdr.h does not define prototypes for these functions.  Although
** byfill() is declared in esqllib.h, this is not normally needed by 7.x
** ESQL/C compilations (though if byfill() is missing, there is room to
** think that other functions may be missing too).
** JL 1999-06-29:
** The 7.24 ESQL/C header declares the iec_* functions, but not byfill.
** It has a conditionally defined macro for byfill which invokes memset.
*/

extern void  byfill(char *to, int len, char ch);

extern void  iec_dclcur(char *, char **, int, int, int);
extern void  iec_free(char *);
extern void  iec_hostbind(struct hostvar_struct *, int, int, int, int, char *);
extern void  iec_ibind(int, char *, int, int, char *, int);
extern void  iec_obind(int, char *, int, int, char *, int);
extern void *iec_alloc_isqlda(int);
extern void *iec_alloc_osqlda(int);

/*
** JL 2000-06-29:
** These function prototypes from sqlhdr.h for ESQL/C 7.24.UC1.
** These prototypes are not protected by __STDC__ and therefore
** should be visible to C++ compilers too.  This was a problem
** found by Lucent in June 1999.  It sometimes takes a while to
** get such fixes into this code.
*/

extern int ifx_checkAPI(int libver, int libid);

extern int bycmpr(char *st1, char *st2, int count);
extern void bycopy( char *s1, char *s2, int n);
extern int byleng( char *beg, int cnt);
extern void ldchar(char *from, int count, char *to);
extern void rdownshift(char *s);
extern void rupshift(char *s);
extern void stcat(char *src, char *dst);
extern void stchar(char *from, char *to, int count);
extern int stcmpr(char *s1, char *s2);
extern void stcopy(char *src, char *dst);
extern int stleng(char *src);

extern int rstoi(char *s, int *val);

extern int rdatestr(long jdate, char *str);
extern int rdayofweek(long date);
extern int rdefmtdate(long *pdate, char *fmtstring, char *input);
extern int rfmtdate(long date, char *fmtstring, char *result);
extern int rfmtdec(struct decimal *dec, char *format, char *outbuf);
extern int rfmtdouble(double dvalue, char *format, char *outbuf);
extern int rfmtlong(long lvalue, char *format, char *outbuf);
extern int rgetmsg(int msgnum, char *s, int maxsize);
extern int rgetlmsg(long msgnum, char *s, int maxsize, int *msg_length);
extern int risnull(int vtype, char *pcvar);
extern int rjulmdy(long jdate, short mdy[3]);
extern int rleapyear(int year);
extern int rmdyjul(short mdy[3], long *jdate);
extern int rsetnull(int vtype, char *pcvar);
extern int rstod(char *str, double *val);
extern int rstol(char *s, long *val);
extern int rstrdate(char *str, long *jdate);
extern void rtoday(long *today);
extern int rtypalign(int offset, int type);
extern int rtypmsize(int type, int len);
extern char *rtypname(int type);
extern int rtypwidth(int type, int len);

extern  int sqlbreak(void);
extern  char *ifx_getcur_conn_name(void);
extern  int sqldetach(void);
extern  int sqlexit(void);
extern  int sqlstart(void);
extern void sqlsignal(int sigvalue, void (*ldv)(void), int mode);
extern int sqlbreakcallback(long timeout, void(*)(int));

extern  int _iqalloc(char *descname, int occurrence);
extern  int _iqbeginwork(void);
extern  int _iqcdcl(struct _sqcursor *cursor,char *curname, char **cmdtxt, struct sqlda *idesc, struct sqlda *odesc, int flags);
extern  int _iqcddcl(struct _sqcursor *cursor, char *curname, struct _sqcursor *stmt, int flags);
extern  int _iqcftch(struct _sqcursor *cursor, struct sqlda *idesc, struct sqlda *odesc, char *odesc_name, _FetchSpec *fetchspec);
extern  int _iqchkbuff(struct _sqcursor *cursor, int *direction, long *valptr);
extern  int _iqsetautofree(struct _sqcursor *cursor, int status);
extern  int _iqsetdefprep(int status);
extern  int _iqclose(struct _sqcursor *cursor);
extern  int _iqcommit(void);
extern  int _iqcopen(struct _sqcursor *cursor, int icnt, struct sqlvar_struct *ibind, struct sqlda *idesc, struct value *ivalues, int useflag);
extern  int _iqcput(struct _sqcursor *cursor, struct sqlda *idesc, char *desc_name);
extern  int _iqcrproc(char *fname);
extern  int _iqdatabase(char *db_name, int exclusive, int icnt, struct sqlvar_struct *ibind);
extern  int _iqdbase(char *db_name, int exclusive);
extern  int _iqdbclose(void);
extern  int _iqdclcur(struct _sqcursor *cursor, char *curname, char **cmdtxt, int icnt, struct sqlvar_struct *ibind, int ocnt, struct sqlvar_struct *obind, int flags);
#ifndef XA_5_0
extern  int _iqdcopen(struct _sqcursor *cursor, struct sqlda *idesc, char *desc_name, struct value *ivalues, int useflag, int reoptflag);
#else /* !XA_5_0 */
extern  int _iqdcopen(struct _sqcursor *cursor, struct sqlda *idesc, char *desc_name, struct value *ivalues, int useflag);
#endif /* !XA_5_0 */
extern  int _iqddclcur(struct _sqcursor *cursor, char *curname, int flags);
extern  int _iqdealloc(char *desc_name);
extern  int _iqdescribe(struct _sqcursor *cursor, struct sqlda **descp, char *desc_name);
extern  int _iqdscribe(struct _sqcursor *cursor, struct sqlda **descp);
extern  int _iqexecute(struct _sqcursor *cursor, struct sqlda *idesc, char *idesc_name, struct value *ivalues, struct sqlda *odesc, char *odesc_name, struct value *ovalues, int chkind);
extern  int _iqeximm(char *stmt);
extern  int _iqexproc(struct _sqcursor *cursor, char **cmdtxt, int icnt, struct sqlvar_struct *ibind, int ocnt, struct sqlvar_struct *obind, int chkind, int freecursor);
extern  int _iqflush(struct _sqcursor *cursor);
extern  int _iqfree(struct _sqcursor *cursor);
extern  int _iqftch(struct _sqcursor *cursor, struct sqlda *odesc, int sysdesc, int chkind, char *odesc_name);
extern  int _iqgetdesc(char *desc_name, int sqlvar_num, struct hostvar_struct *hosttab, int xopen_flg);
extern  int _iqgetdiag(struct hostvar_struct *hosttab, int exception_num);
extern  int _iqinsput( struct _sqcursor *cursor, int icnt, struct sqlvar_struct *ibind, struct sqlda *idesc, struct value *ivalues);
extern  struct _sqcursor *_iqlocate_cursor(char *name, int type);
extern  int _iqnftch(struct _sqcursor *cursor, int ocnt, struct sqlvar_struct *obind, struct sqlda *odesc, int fetch_type, long val, int icnt, struct sqlvar_struct *ibind, struct sqlda *idesc, int chkind );
extern  struct _sqcursor *_iqnprep(char *name, char *stmt);
extern  int _iqrollback(void);
extern  int _iqsetdesc(char *desc_name, int sqlvar_num, struct hostvar_struct *hosttab, int xopen_flg);
extern  void _iqseterr(int sys_errno);
extern  int _iqsftch(struct _sqcursor *cursor, struct sqlda *idesc, struct sqlda *odesc, int sysdesc, _FetchSpec *fetchspec, char *odesc_name);
extern  int _iqslct(struct _sqcursor *cursor, char **cmdtxt, int icnt, struct sqlvar_struct *ibind, int ocnt, struct sqlvar_struct *obind, int chkind);
extern int _iqstmnt(_SQSTMT *scb, char **cmdtxt, int icnt, struct sqlvar_struct *ibind, struct value *ivalues);
extern  void _iqstop(void);
extern  int _iqxecute(struct _sqcursor *cursor, int icnt, struct sqlvar_struct *ibind, struct sqlda *idesc, struct value *ivalues);

extern void _iqconnect(int conn_kw, char *dbenv, char *conn_name, char *username, char *passwd, int concur_tx);
extern void _iqdisconnect(int conn_kw, char *conn_name, int flag, int from_reassoc);
extern void _iqsetconnect(int conn_kw, char *conn_name, int dormant);

#ifdef _REENTRANT
extern long * ifx_sqlcode(void);
extern char * ifx_sqlstate(void);
extern struct sqlca_s * ifx_sqlca(void);
#endif /* _REENTRANT */

#endif /* ESQL7_20_H */
