/*
@(#)File:            $RCSfile: esqllib.h,v $
@(#)Version:         $Revision: 1.10 $
@(#)Last changed:    $Date: 1997/06/02 16:24:26 $
@(#)Purpose:         ESQL/C Library Function Prototypes
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1992-93,1995-97
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

/*TABSTOP=4*/

#ifndef ESQLLIB_H
#define ESQLLIB_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqllib_h[] = "@(#)$Id: esqllib.h,v 1.10 1997/06/02 16:24:26 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* DATE */
extern int      rdayofweek(long jdate);
extern int      rdefmtdate(long *jdate, char *fmt, char *inp);
extern int      rfmtdate(long jdate, char *fmt, char *res);
extern int      rjulmdy(long jdate, short mdy[3]);
extern int      rleapyear(int year);
extern int      rmdyjul(short mdy[3], long *jdate);
extern int      rstrdate(char *str, long *jdate);
extern int      rdatestr(long jdate, char *str);
extern void     rtoday(long *today);

/* DECIMAL */
extern int      decadd(dec_t *op1, dec_t *op2, dec_t *res);
extern int      deccmp(dec_t *op1, dec_t *op2);
extern int      deccpy(dec_t *op1, dec_t *op2);
extern int      deccvasc(char *cp, int len, dec_t *np);
extern int      deccvdbl(double i, dec_t *np);
extern int      deccvint(int i, dec_t *np);
extern int      deccvlong(long i, dec_t *np);
extern int      decdiv(dec_t *op1, dec_t *op2, dec_t *res);
extern char    *dececvt(dec_t *np, int ndigit, int *decpt, int *sign);
extern char    *decfcvt(dec_t *np, int ndigit, int *decpt, int *sign);
extern int      decmul(dec_t *op1, dec_t *op2, dec_t *res);
extern int      decround(dec_t *np, int n);
extern int      decsub(dec_t *op1, dec_t *op2, dec_t *res);
extern int      dectoasc(dec_t *np, char *cp, int len, int right);
extern int      dectodbl(dec_t *np, double *ip);
extern int      dectoint(dec_t *np, int *ip);
extern int      dectolong(dec_t *np, long *ip);
extern int      dectrunc(dec_t *np, int n);

/* FORMAT USING */
extern int      rfmtdec(dec_t *np, char *fmt, char *outbuf);
extern int      rfmtdouble(double np, char *fmt, char *outbuf);
extern int      rfmtlong(long np, char *fmt, char *outbuf);

/* DATETIME/INTERVAL */
extern int      dtcvasc(char *str, dtime_t *dt);
extern int      dtcvfmtasc(char *str, char *fmt, dtime_t *dt);
extern int      dtextend(dtime_t *id, dtime_t *od);
extern int      dttoasc(dtime_t *dt, char *str);
extern int      incvasc(char *str, intrvl_t *dt);
extern int      incvfmtasc(char *str, char *fmt, intrvl_t *dt);
extern int      intoasc(intrvl_t *dt, char *str);
extern void     dtcurrent(dtime_t *dt);

/* LIBRARY */
extern char    *rtypname(int sqltype);
extern int      bycmpr(char *b1, char *b2, int len);
extern int      byleng(char *fr, int len);
extern int      rgetmsg(short msgnum, char *msgstr, short msglen);
extern int      risnull(int type, char *ptrvar);
extern int      rsetnull(int type, char *ptrvar);
extern int      rstod(char *str, double *val);
extern int      rstoi(char *str, int *val);
extern int      rstol(char *str, long *val);
extern int      rtypalign(int pos, int type);
extern int      rtypmsize(int sqltype, int sqllen);
extern int      rtypwidth(int sqltype, int sqllen);
extern int      stcmpr(char *s1, char *s2);
extern int      stcopy(char *fr, char *to);
extern int      stleng(char *s);
extern void     bycopy(char *fr, char *to, int len);
extern void     byfill(char *to, int len, char ch);
extern void     ldchar(char *fr, int len, char *to);
extern void     rdownshift(char *s);
extern void     rupshift(char *s);
extern void     stcat(char *s, char *dest);
extern void     stchar(char *fr, char *to, int cnt);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif	/* ESQLLIB_H */
