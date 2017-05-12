#include <stdarg.h>
#include <stdio.h>
#include <sqltypes.h>
#include "agent.h"

#define MAXINTLEN       24
#define MAXSMINTLEN     12
#define MAXINTERVALLEN  26
#define MAXDTIMELEN     26
#define MAXMONEYLEN     34
#define MAXDATELEN      11
#define MAXSERIALLEN    MAXINTLEN
#define MAXDECIMALLEN   34
#define MAXSMFLOATLEN   MAXDECIMALLEN
#define MAXFLOATLEN     MAXDECIMALLEN
#define MAXNULLLEN      1

struct {
	int opened,descou;
	int tcolen,colen[MAXCOLUMN];
} curs[MAX_CURSOR];


static char prgname[]="pagent";

int errlen;
char errmsg[256];

void error(char *fmt,...)
{
	va_list args;
	char aa[256];
#if	0
	va_start(args, fmt);
	fprintf(stderr,"%s:", prgname);
	vfprintf(stderr, fmt, args);
	va_end(args);
	fprintf(stderr,"\n");
#else
	va_start(args, fmt);
	vsprintf(aa,fmt,args);
	va_end(args);
	sprintf(errmsg,"%s: %s", prgname, aa);
	errlen=strlen(errmsg)+1;
	fprintf(stderr, "%s\n", errmsg);
#endif
}

static char *sqlerr()
{
static char msg[256];
char tt[128];
int num=rgetmsg(SQLCODE,tt,sizeof(tt));

if (!num) sprintf(msg,"%d : %s",SQLCODE,tt);
else sprintf(msg,"unknown SQL err code : %d",SQLCODE);

return msg;
}

alloc_cursor()
{
int i;
for(i=0;i<MAX_CURSOR;i++)
if (!curs[i].opened) {
	bzero(&curs[i],sizeof(curs[0]));
	return i;
}
sqlca.sqlcode=SQLCODE = -276;
error("Max allowed concurrent %d", MAX_CURSOR);
return -1;
}

connect_db(char *dbname)
{
_iqdbase(dbname,0);
if (SQLCODE < 0) {
	error("connect db %s err %s", dbname, sqlerr());
	return 0;
}
return 1;
}


sql_prepare(stmt, cursor_n, desc_n)
$char *stmt;
int *cursor_n, *desc_n;
{
char *tt;
char cmd[16];
int i,cursor_num;
$int desc_cou;

i=0;
tt=stmt;
while (isspace(*tt)) tt++;
while (*tt && isalpha(*tt)) cmd[i++]=tolower(*tt++);
cmd[i]=0;
if (strstr("insert delete update create drop alter set begin commit",cmd)) {
	$prepare tsql from $stmt;
	if (SQLCODE < 0) {
		error("sql_prepare1: statement error: %s %s",
					stmt, sqlerr());
		return 0;
	}
	$execute tsql;
	if (SQLCODE < 0) {
		error("sql execute error: %s %s", stmt, sqlerr());
		return 0;
	}
	*desc_n=0;
	return 1;
}
if (strcmp(cmd,"select")) {
	error("unknow sql command : %s", cmd);
	return 0;
}

if ((cursor_num=alloc_cursor())<0) return -1;
switch (cursor_num) {
	case 0:
#if	0
		error("sql stmt cursor %d %s\n", cursor_num, stmt);
#endif
		$prepare prep0 from $stmt;
		if (SQLCODE < 0) {
			error("cursor%d prepare %s",cursor_num,sqlerr());
			return 0;
		}
		$declare cur0 cursor for prep0;
		if (SQLCODE < 0) {
			error("cursor%d declare %s", cursor_num, sqlerr());
			return 0;
		}
		$allocate descriptor 'desc0' with max 128;
		if (SQLCODE < 0) {
			error("cursor%d allocate %s", cursor_num, sqlerr());
			return 0;
		}
		$open cur0;
		if (SQLCODE < 0) {
			error("cursor%d open %s", cursor_num, sqlerr());
			return 0;
		}
		$describe prep0 using sql descriptor 'desc0';
		if (SQLCODE < 0) {
			error("cursor%d open %s", cursor_num, sqlerr());
			return 0;
		}
		$get descriptor 'desc0' $desc_cou = count;
		if (SQLCODE < 0) {
			error("prepare cursor%d get desc %s", cursor_num, sqlerr());
			return 0;
		}
		break;
	case 1:
		$prepare prep1 from $stmt;
		if (SQLCODE < 0) {
			error("cursor%d prepare %s",cursor_num,sqlerr());
			return 0;
		}
		$declare cur1 cursor for prep1;
		if (SQLCODE < 0) {
			error("cursor%d declare %s", cursor_num, sqlerr());
			return 0;
		}
		$allocate descriptor 'desc1' with max 128;
		if (SQLCODE < 0) {
			error("cursor%d allocate %s", cursor_num, sqlerr());
			return 0;
		}
		$open cur1;
		if (SQLCODE < 0) {
			error("cursor%d open %s", cursor_num, sqlerr());
			return 0;
		}
		$describe prep1 using sql descriptor 'desc1';
		if (SQLCODE < 0) {
			error("cursor%d open %s", cursor_num, sqlerr());
			return 0;
		}
		$get descriptor 'desc1' $desc_cou = count;
		if (SQLCODE < 0) {
			error("prepare cursor%d get desc %s", cursor_num, sqlerr());
			return 0;
		}
		break;
	case 2:
		$prepare prep2 from $stmt;
		if (SQLCODE < 0) {
			error("cursor%d prepare %s",cursor_num,sqlerr());
			return 0;
		}
		$declare cur2 cursor for prep2;
		if (SQLCODE < 0) {
			error("cursor%d declare %s", cursor_num, sqlerr());
			return 0;
		}
		$allocate descriptor 'desc2' with max 128;
		if (SQLCODE < 0) {
			error("cursor%d allocate %s", cursor_num, sqlerr());
			return 0;
		}
		$open cur2;
		if (SQLCODE < 0) {
			error("cursor%d open %s", cursor_num, sqlerr());
			return 0;
		}
		$describe prep2 using sql descriptor 'desc2';
		if (SQLCODE < 0) {
			error("cursor%d open %s", cursor_num, sqlerr());
			return 0;
		}
		$get descriptor 'desc2' $desc_cou = count;
		if (SQLCODE < 0) {
			error("prepare cursor%d get desc %s", cursor_num, sqlerr());
			return 0;
		}
}
*cursor_n=cursor_num;
curs[cursor_num].descou = *desc_n= desc_cou;
curs[cursor_num].opened=1;
return 1;
}


sql_fetch(
int cursor, char *res, int colen[], int *tcolength, int *rtcol, int *descn)
{
$int i;
$int desc_count;
$int loop;
$int type;
$int len;
$char name[40];
int tlen=0;
$char bf[65536];
$short indicator;
int tcolen=0;

*descn=curs[cursor].descou;
if (!curs[cursor].tcolen) {
for ( i = 1 ; i <= curs[cursor].descou ; i++ ) {
switch (cursor) {
	case 0:
	$get descriptor 'desc0' value $i $type = type, $len = length, $name = name;
	break;
	case 1:
	$get descriptor 'desc1' value $i $type = type, $len = length, $name = name;
	break;
	case 2:
	$get descriptor 'desc2' value $i $type = type, $len = length, $name = name;
	break;
	default:
		break;
}
if (SQLCODE < 0) {
	error("sql_fetch: aa cursor%d get desc %s", cursor, sqlerr());
	return 0;
}
switch (type) {
	case SQLCHAR:
	/* leave len alone if char */
	break;
	case SQLINT:
	len = MAXINTLEN;
	break;
	case SQLSMINT:
	len = MAXSMINTLEN;
	break;
	case SQLINTERVAL:
	len = MAXINTERVALLEN;
	break;
	case SQLDTIME:
	len = MAXDTIMELEN;
	break;
	case SQLMONEY:
	len = MAXMONEYLEN;
	break;
	case SQLDATE:
	len = MAXDATELEN;
	break;
	case SQLSERIAL:
	len = MAXSERIALLEN;
	break;
	case SQLDECIMAL:
#if	0
	  printf("name:%s len:%d\n",name, len);
#endif
	len = MAXDECIMALLEN;
	break;
	case SQLSMFLOAT:
	len = MAXSMFLOATLEN;
	break;
	case SQLFLOAT:
	len = MAXFLOATLEN;
	break;
}
colen[i-1]=len;
tcolen+=len;
} /* for */
curs[cursor].tcolen=tcolen;
memcpy(curs[cursor].colen,colen,sizeof(colen));
}
else {
	memcpy(colen,curs[cursor].colen,sizeof(colen));
	tcolen=curs[cursor].tcolen;
}

switch (cursor) {
	case 0:
		$fetch cur0 using sql descriptor 'desc0';
		break;
	case 1:
		$fetch cur1 using sql descriptor 'desc1';
		break;
	case 2:
		$fetch cur2 using sql descriptor 'desc2';
		break;
}

if (SQLCODE) {
	if (SQLCODE<0)
	  error("fetch xx cursor%d get desc %d %s", cursor, SQLCODE, sqlerr());
	return 0;
}

tlen=0;
#if	0
error("total desc:%d", curs[0].descou);
#endif
for(i = 1 ; i <= curs[cursor].descou ; i++ ) {
	switch (cursor) {
	case 0:
		$get descriptor 'desc0' value $i $bf = data, $type = type, $indicator=indicator;
	    break;
	case 1:
		$get descriptor 'desc1' value $i $bf = data, $type = type, $indicator=indicator;
	    break;
	case 2:
		$get descriptor 'desc2' value $i $bf = data, $type = type, $indicator=indicator;
	    break;
	}
	if (SQLCODE < 0) {
		error("sql_fetch -- data cursor%d get %d desc %s",
			cursor, i, sqlerr());
		return 0;
	}
#if	0
	printf("%s &", bf);
#endif
	strcpy(res+tlen, bf);
	tlen+=strlen(bf)+1;
}
*tcolength=tcolen;
*rtcol=tlen;
return 1;
}


close_cursor(int cur)
{
switch (cur) {
	case 0:
		$ close cur0;
		curs[0].opened=0;
		break;
	case 1:
		$ close cur1;
		curs[1].opened=0;
		break;
	case 2:
		$ close cur2;
		curs[2].opened=0;
		break;
	default:
		error("close_cursor: bad cursor no %d\n", cur);
}
if (SQLCODE < 0) {
	error("close cursor%d %s", cur, sqlerr());
	return 0;
}
return 1;
}

free_cursor(int cursor)
{
switch (cursor) {
	case 0:
	    $ free prep0;
	    $ free desc0;
	    $ deallocate descriptor 'desc0';
		curs[0].opened=0;
	    break;
	case 1:
	    $ free prep1;
	    $ free desc1;
	    $ deallocate descriptor 'desc1';
		curs[1].opened=0;
	    break;
	case 2:
	    $ free prep2;
	    $ free desc2;
	    $ deallocate descriptor 'desc2';
		curs[2].opened=0;
	    break;

}
return 1;
}

getdbs(char *dbsna, int *ndbs)
{
#define MAXDBS 100
#define FASIZE ( MAXDBS * 19 )
int sqlcode;
char *dbsname[MAXDBS + 1];
char dbsarea[FASIZE];
int ofs,i;

if (sqlcode = sqgetdbs(ndbs, dbsname, MAXDBS, dbsarea, FASIZE )) {
	error("getdbs: %s", sqlerr());
	return 0;
}
for(ofs=i=0;i< *ndbs;i++) {
	strcpy(dbsna+ofs, dbsname[i]);
	ofs+=strlen(dbsname[i])+1;
}
return 1;
}
