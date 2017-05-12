#include <stdio.h>
#include <stdarg.h>
#include <sys/types.h>
#include <netinet/in_systm.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include "proto.h"
#include "a.h"
#include <errno.h>

char *prgname="client";

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

int sockfd;

netwrite(void *s, int n)
{
int wn,i=0;

while (n) {
	if ((wn=write(sockfd,(char *)s+i,n))< 0) exit(-1);
	i+=wn;
	n-=wn;
}
}

netread(void *s, int n)
{
int rn,i=0;
while (n) {
	if ((rn=read(sockfd,(char *)s+i,n))<0) exit(-1);
	i+=rn;
	n-=rn;
}
}

char *neterr()
{
static char tt[4096];
int errlen;
netread(&errlen,4);
netread(tt,errlen);
return tt;
}


int init_tcp()
{
struct sockaddr_in serv_addr;

bzero((char *)&serv_addr, sizeof(serv_addr));
serv_addr.sin_family = AF_INET;
serv_addr.sin_addr.s_addr=inet_addr("167.170.27.6");
serv_addr.sin_port = htons(9001);
if ((sockfd=socket(AF_INET, SOCK_STREAM, 0)) < 0)
	p_err("Cannot open socket : %s",strerror(errno));
if (connect(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
	p_err("Cannot connect : %s",strerror(errno));
}

select_db(char *s)
{
REQ rq;
RES res;

init_tcp();
rq.req=htonl(NET_CONNECTDB);
rq.len=htonl(strlen(s)+1);
netwrite(&rq,sizeof(rq));
netwrite(s,strlen(s)+1);
netread(&res,sizeof(res));
res.res=ntohl(res.res);
if (!res.res) printf("error:%s %s\n", neterr());
return res.res;
}

sql_prepare(char *s, int *cursorn, int *descn)
{
REQ rq;
RES res;
PREPARE_REP rep;
int len=strlen(s)+1;

rq.req=htonl(NET_PREPARE);
rq.len=htonl(len);
netwrite(&rq,sizeof(rq));
netwrite(s,strlen(s)+1);
netread(&res,sizeof(res));
res.res=ntohl(res.res);
if (!res.res) printf("prepare error %s", neterr());
netread(&rep,sizeof(rep));
*cursorn=ntohl(rep.cursorn);
*descn=ntohl(rep.descn);
}

sql_fetch(int cursorn, char *bf, int colen[], int *tcolen, int *descn)
{
REQ rq;
FETCH_REQ frq;
RES res;
FETCH_REP rep;
int rn,i;

rq.req=htonl(NET_FETCH);
rq.len=htonl(sizeof(FETCH_REQ));
netwrite(&rq,sizeof(rq));
frq.cursorn=htonl(cursorn);
netwrite(&frq,sizeof(frq));
netread(&res,sizeof(res));
res.res=ntohl(res.res);
if (!res.res)	{
	printf("fetch error %d %s\n", res.res, neterr());
	return res.res;
}
netread(&rep,sizeof(rep));
*descn=rep.descn=ntohl(rep.descn);
*tcolen=rep.tcolen=ntohl(rep.tcolen);
netread(colen,sizeof(int)*rep.descn);
for(i=0;i<rep.descn;i++)
	colen[i]=ntohl(colen[i]);
rn=netread(bf,rep.tcolen);
}

sql_close(int cursor)
{
REQ rq;
CLOSE_REQ req;

rq.req=htonl(NET_CLOSE);
rq.len=sizeof(req);
req.cursorn=cursor;
netwrite(&rq,sizeof(rq));
netwrite(&req,sizeof(req));
}

sql_getdbs(char *dbs, int *ndbs)
{
}

