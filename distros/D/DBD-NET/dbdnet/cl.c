#include <stdio.h>
#include <stdarg.h>
#include <sys/types.h>
#include <netinet/in_systm.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <signal.h>
#include <string.h>
#include <ctype.h>
#include <malloc.h>
#include "proto.h"
#include <errno.h>
#include <sys/time.h>

char *prgname="client";

#define MAX_OPEN_CURSOR (6)

static struct fet {
	int nrow;
	int row_i;
	int descn;
	int netfd,r_cursor;
	int colen[256],tcolen;
	char *bufptr, *buf;
	int bufsize;
} fetchbuf[MAX_OPEN_CURSOR];

void p_err(char *fmt,...)
{
	va_list args;

	va_start(args, fmt);
	fprintf(stderr,"%s:", prgname);
	vfprintf(stderr, fmt, args);
	va_end(args);
	fprintf(stderr,"\n");
	exit(1);
}

netwrite(int fd, void *s, int n)
{
int wn,i=0;

while (n) {
	fd_set fdvar;
	FD_ZERO(&fdvar);
	FD_SET(fd, &fdvar);
	select (fd+1, NULL, &fdvar,NULL ,NULL);
	if ((wn=write(fd,(char *)s+i,n))<= 0) {
		exit(-1);
	}
	i+=wn;
	n-=wn;
}
}

netread(int fd, void *s, int n)
{
int rn,i=0;
fd_set fdvar;

while (n) {
	FD_ZERO(&fdvar);
	FD_SET(fd, &fdvar);
	select(fd+1, &fdvar, NULL, NULL,NULL);
	if ((rn=read(fd,(char *)s+i,n))< 0) {
		exit(-1);
	} else
	if (!rn) {
		sleep(1);
	}
	i+=rn;
	n-=rn;
}
}

char NETerrmsg[4096];
char *neterr(int netfd)
{
int errlen;
netread(netfd,&errlen,4);
errlen=ntohl(errlen);
netread(netfd,NETerrmsg,errlen);
fprintf(stderr,"%s\n", NETerrmsg);
return NETerrmsg;
}

init_tcp(char *host)
{
struct sockaddr_in serv_addr;
struct hostent *hp;
char *po;
int size=4;
int fd;

bzero(&serv_addr, sizeof(serv_addr));
if (!(po=strchr(host,':'))) {
	serv_addr.sin_port = htons(9001);
} else {
	*po=0;
	serv_addr.sin_port = htons(atoi(po+1));
}
if (isdigit(host[0])) {
	serv_addr.sin_addr.s_addr=inet_addr(host);
} else {
	if (!(hp=gethostbyname(host))) {
		sprintf(NETerrmsg,"Unknow host name %s", host);
		return 0;
	}
	memcpy(&serv_addr.sin_addr.s_addr,hp->h_addr_list[0],4);
}
serv_addr.sin_family = AF_INET;
if ((fd=socket(AF_INET, SOCK_STREAM, 0)) < 0)
	p_err("Cannot open socket : %s",strerror(errno));
if (connect(fd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
	p_err("Cannot connect : %s",strerror(errno));
return fd;
}

connect_db(char *host, char *login_name, char *passwd, char *dbname)
{
REQ rq;
RES res;
CONNECT_REQ con;
int fd;

if (!(fd=init_tcp(host))) return 0;
rq.req=htonl(NET_CONNECTDB);
rq.len=htonl(sizeof(con));
strcpy(con.login_name, login_name);
strcpy(con.passwd, passwd);
strcpy(con.dbname, dbname);
netwrite(fd,&rq,sizeof(rq));
netwrite(fd,&con,sizeof(con));
netread(fd,&res,sizeof(res));
res.res=ntohl(res.res);
if (!res.res) {
	neterr(fd);
}
return fd;
}

sql_prepare(int netfd, char *s, int *cursorn, int *descn)
{
REQ rq;
RES res;
PREPARE_REP rep;
int len=strlen(s)+1;
int curn;
int mycur;

for(curn=0;curn<MAX_OPEN_CURSOR;curn++)
if (!fetchbuf[curn].netfd) {
	*cursorn=curn;
	break;
}
if (curn==MAX_OPEN_CURSOR)
	p_err("Exceed max open cursor %d",MAX_OPEN_CURSOR);
rq.req=htonl(NET_PREPARE);
rq.len=htonl(len);
netwrite(netfd,&rq,sizeof(rq));
netwrite(netfd,s,strlen(s)+1);
netread(netfd,&res,sizeof(res));
res.res=ntohl(res.res);
if (!res.res) {
	neterr(netfd);
	return 0;
}
netread(netfd,&rep,sizeof(rep));
*descn=ntohl(rep.descn);
if (rep.descn) {
	fetchbuf[curn].r_cursor=ntohl(rep.cursorn);
	fetchbuf[curn].netfd=netfd;
	fetchbuf[curn].row_i=fetchbuf[curn].nrow=0;
}
return 1;
}

void putss(char *s, int n)
{
int i;
for(i=0;i<n;i++) {
	printf("%s|",s);
	s+=strlen(s)+1;
}
puts("");
}

sql_fetch(int cursorn, char *bf, int colen[], int *tcolen, int *descn)
{
REQ rq;
FETCH_REQ frq;
RES res;
FETCH_REP rep;
int rn,i,j,ofs;
char *tt;
struct fet *pfet=&fetchbuf[cursorn];
char *dat;
char *p;
int netfd=pfet->netfd;

copy_it:
if (pfet->row_i < pfet->nrow) {
	*descn=pfet->descn;
	memcpy(colen, pfet->colen, sizeof(int)*(*descn));
	*tcolen=pfet->tcolen;
	p=pfet->bufptr;
	for(ofs=i=0;i<*descn;i++) {
		strcpy(bf+ofs,p+ofs);
		ofs+=strlen(p+ofs)+1;
	}
	pfet->bufptr=p+ofs;
	pfet->row_i++;
#if 0
	putss(bf,*descn);
#endif
	return 1;
}
rq.req=htonl(NET_FETCH);
rq.len=htonl(sizeof(FETCH_REQ));
netwrite(netfd,&rq,sizeof(rq));
frq.cursorn=htonl(pfet->r_cursor);
netwrite(netfd,&frq,sizeof(frq));
netread(netfd,&res,sizeof(res));
res.res=ntohl(res.res);
if (!res.res)   {
/*	neterr(netfd); */
	return 0;
}
netread(netfd,&rep,sizeof(rep));
pfet->descn=rep.descn=ntohl(rep.descn);
pfet->tcolen=rep.tcolen=ntohl(rep.tcolen);
pfet->nrow=rep.nrow=ntohl(rep.nrow);
rep.datan=ntohl(rep.datan);
#if	0
printf("cursorn:%d datan:%d\n", cursorn, rep.datan);
#endif
netread(netfd,colen,sizeof(int)*rep.descn);
for(i=0;i<rep.descn;i++) {
	pfet->colen[i]=colen[i]=ntohl(colen[i]);
}
#if 0
printf("descn:%d tcolen:%d nrow:%d datan:%d\n",
rep.descn, rep.tcolen, rep.nrow, rep.datan );
fflush(stdout);
#endif

if (pfet->buf) free(pfet->buf);
if (!(dat=malloc(rep.datan))) {
	printf("malloc err:%d\n",rep.datan);
	return 0;
}
netread(netfd,dat,rep.datan);
#if 0
p=dat;
for(i=0;i<rep.nrow;i++) {
	for(j=0;j<rep.descn;j++){
		printf("%s|",p);
		p+=strlen(p)+1;
	}
puts("");
}
#endif
pfet->bufptr=pfet->buf=dat;
pfet->row_i=0;
goto copy_it;
}

sql_close(int cursor)
{
REQ rq;
CLOSE_REQ req;
int netfd;

if (cursor<0 || cursor>=MAX_OPEN_CURSOR) {
	printf("Invalid cursor %d\n", cursor);
	return 0;
}
netfd=fetchbuf[cursor].r_cursor;
if (netfd<=0) {
	printf("Invalid cursor %d\n", cursor);
	return 0;
}
rq.req=htonl(NET_CLOSE);
rq.len=sizeof(req);
req.cursorn=fetchbuf[cursor].r_cursor;
netwrite(netfd,&rq,sizeof(rq));
netwrite(netfd,&req,sizeof(req));
close(fetchbuf[cursor].netfd);
fetchbuf[cursor].netfd=0;
}

net_disconnect(int fd)
{
int i;

for(i=0;i<MAX_OPEN_CURSOR;i++)
if (fetchbuf[i].netfd) {
	close(fetchbuf[i].netfd);
	fetchbuf[i].netfd=0;
}
}

sql_getdbs(char *dbs, int *ndbs)
{
}

