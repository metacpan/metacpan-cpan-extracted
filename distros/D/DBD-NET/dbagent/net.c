#include <stdio.h>
#include <stdarg.h>
#include <sys/types.h>
#include <netinet/in_systm.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <signal.h>
#include <netinet/tcp.h>
#include <errno.h>
#include <pwd.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include <fcntl.h>
#include "agent.h"
#include "proto.h"


extern int errlen;
extern char errmsg[];
short m_port=9001;

char *prgname="agent";

ptime()
{
static int mark=0;
static struct timeval tp0, tp;
struct timezone tzp;
int sec, usec;

if (!mark) {
gettimeofday(&tp0, &tzp);
mark=1;
} else {
gettimeofday(&tp, &tzp);
sec=tp.tv_sec-tp0.tv_sec;
usec=tp.tv_usec-tp0.tv_usec;
if (usec<0) {
		sec--;
		usec+=1000000;
}
printf("%d.%06d\n",sec, usec);
mark=0;
}
}

ttime()
{
static int mark=0;
static struct timeval tp;
struct timezone tzp;
int sec, usec;

gettimeofday(&tp, &tzp);
sec=tp.tv_sec;
usec=tp.tv_usec;
printf("%d.%06d\n",sec, usec);
mark=0;
}

void p_err(char *fmt,...)
{
  va_list args;

  va_start(args, fmt);
  fprintf(stderr,"%s:", prgname);
  vfprintf(stderr, fmt, args);
  va_end(args);
  fprintf(stderr,"\n");
  puts("p_err");
  exit(1);
}

void p_error(char *fmt,...)
{
  va_list args;

  va_start(args, fmt);
  fprintf(stderr,"%s:", prgname);
  vfprintf(stderr, fmt, args);
  va_end(args);
  fprintf(stderr,"\n");
}

static int netfd;

netwrite(void *s, int n)
{
int wn,i=0;

while (n) {
#ifdef HPUX
        int fdvar = 1<<netfd;
#else
	fd_set fdvar;
	FD_ZERO(&fdvar);
	FD_SET(netfd, &fdvar);
#endif
	select(netfd+1, 0, &fdvar, 0, 0);
	if ((wn=write(netfd,(char *)s+i,n))<=0) {
		exit(-1);
	}
	i+=wn;
	n-=wn;
}
}


netread(void *s, int n)
{
int rn,i=0;
fd_set fdvar;

while (n) {
#ifdef HPUX
        int fdvar = 1<<netfd;
#else
	fd_set fdvar;
	FD_ZERO(&fdvar);
	FD_SET(netfd, &fdvar);
#endif
	select(netfd+1, &fdvar,0,0,0);
	if ((rn=read(netfd,(char *)s+i,n))<=0) {
		exit(-1);
	}
	i+=rn;
	n-=rn;
}
}

void puterr()
{
RES res;
int errl;
res.res=0;
errlen=strlen(errmsg)+1;
errl=htonl(errlen);
netwrite(&res,sizeof(RES));
netwrite(&errl,sizeof(errl));
netwrite(errmsg,errlen);
}

void reterr(char *fmt,...)
{
  va_list args;

  va_start(args, fmt);
  vsprintf(errmsg, fmt, args);
  va_end(args);
  puts(errmsg);
  puterr();
}

void close_exit()
{
close(netfd);
puts("close_exit");
exit(1);
}

char *whereis( addr )
struct sockaddr_in *addr;
{
struct hostent *who;
char name[128];
static char buf[1024];
struct hostent *hp;

if ( (hp = gethostbyaddr( &(addr->sin_addr.s_addr),
	sizeof(long), AF_INET)) == NULL ) {

	sprintf(buf, "%d.%d.%d.%d",
		addr->sin_addr.s_addr >> 24,
		(addr->sin_addr.s_addr >> 16) & 0xff,
		(addr->sin_addr.s_addr >> 8) & 0xff,
		addr->sin_addr.s_addr & 0xff );
	return(buf);
}
return( hp->h_name );
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


int fcnt;

void handle_req()
{
int n, cursorn, descn;
REQ rq;
RES rep;
char ttt[16*1024];
int max_rows[10];

fcnt=0;

for(;;) {
n=netread(&rq,sizeof(REQ));
rq.req=ntohl(rq.req);
rq.len=ntohl(rq.len);
#if	0
printf("len:%d\n", rq.len);
#endif
if (rq.len > 0) {
  if (rq.len + sizeof(REQ) > sizeof(REQD)) {
#if	0
	p_err("buf size is too small");
#endif
	continue;
  }
  switch (rq.req) {
  	case NET_GETDBS:
		rep.res=getdbs(ttt, &n);
		if (!rep.res)
			puterr();
		else {
			rep.res=htonl(rep.res);
			netwrite(&rep,sizeof(RES));
		}
  		continue;
	case NET_CONNECTDB:
	{
		CONNECT_REQ crq;
		struct passwd *pwp;
		char *pwd;
		struct sockaddr_in frm;
		int adrlen=sizeof(frm);
		struct timeval tp;
		struct timezone tzp;
		char buf[100];

		gettimeofday(&tp, &tzp);
		strftime(buf,sizeof(buf),"%D %T", localtime(&tp.tv_sec));

		if (getpeername(netfd,&frm, &adrlen)<0) {
			p_error("Cannot get peer name");
		}
		netread(&crq, rq.len);
		printf("%s %s %s %s\n",buf, whereis(&frm), crq.login_name, crq.dbname);
		if (!(pwp=getpwnam(crq.login_name))) {
			reterr("Invalid login name '%s'",crq.login_name);
			close_exit();
		}
		pwd=pwp->pw_passwd;
		if (strcmp(crypt(crq.passwd,pwd), pwd)) {
			reterr("Incorrect passwd");
			close_exit();
		}
		setuid(pwp->pw_uid);
		setgid(pwp->pw_gid);
		rep.res=connect_db(crq.dbname);
		if (!rep.res)
			puterr();
		else {
			rep.res=htonl(rep.res);
			netwrite(&rep,sizeof(RES));
		}
		continue;
	}
	case NET_PREPARE:
	{
		netread(ttt,rq.len);
		rep.res=sql_prepare(ttt,&cursorn,&descn);
		if (!rep.res)
			puterr();
		else {
			PREPARE_REP pp;
			pp.cursorn=htonl(cursorn);
			pp.descn=htonl(descn);
			netwrite(&rep,sizeof(rep));
			netwrite(&pp,sizeof(PREPARE_REP));
			max_rows[cursorn]=16;
		}
		continue;
	}
	case NET_FETCH:
	{
		char *tt[MAXCOLUMN];
		int i,j, tlen,ofs,nrow;
		int colen[MAXCOLUMN],tcolen;
		char bf[128*1024] ;
		FETCH_REP qq;
		RES res;
		FETCH_REQ pp;
		int rtcol,datan,max_row;

		netread(&pp,sizeof(pp));
		cursorn=ntohl(pp.cursorn);
		/* Yes, it is dangerous if a row is too large, will use malloc */
		max_row=max_rows[cursorn]=128;
		for(datan=nrow=0;nrow<max_row;nrow++) {
			if (!(res.res=sql_fetch(cursorn,bf+datan,colen,&tcolen,
					&rtcol, &descn))) {
					break;
			}
			fcnt++;
			datan+=rtcol;
		}
		if (res.res) {
			max_row=sizeof(bf)/tcolen;
			max_rows[cursorn]=max_row;
		}
		qq.descn=htonl(descn);
		qq.tcolen=htonl(tcolen);
		qq.nrow=htonl(nrow);
		qq.datan=htonl(datan);
		if (nrow==0) {
			res.res=0;
			netwrite(&res,sizeof(res));
			continue;
		}
		else res.res=htonl(1);
		netwrite(&res,sizeof(res));
		netwrite(&qq,sizeof(qq));
		for(i=0;i<descn;i++)
			colen[i]=htonl(colen[i]);
		netwrite(colen, sizeof(int)*descn);
		if (datan) netwrite(bf,datan);
#if	0
		printf("res:%d tcolen:%d\n", res.res, tcolen);
#endif
		continue;
	}
	case NET_CLOSE:
	{   CLOSE_REQ pp;
		int cursorn;
		netread(&pp,sizeof(pp));
		cursorn=ntohl(pp.cursorn);
		close_cursor(cursorn);
		printf("close %d\n", cursorn);
		exit(0);
	}
	case NET_FREE:
	{   CLOSE_REQ pp;
		int cursorn;
		cursorn=ntohl(pp.cursorn);
		free_cursor(cursorn);
		exit(0);
	}
  } /* switch */
} /* if */
} /* for */


}


int sockfd;


main(int argc, char **argv)
{
int pid, clilen;
struct sockaddr_in cli_addr, serv_addr;
char tt[256];
int ndbs;

if (argc>1)
	m_port=atoi(argv[1]);

if ((sockfd=socket(AF_INET,SOCK_STREAM, 0)) < 0)
	p_err("Cannot open socket : %s",strerror(errno));
bzero((char *) &serv_addr, sizeof(serv_addr));
serv_addr.sin_family=AF_INET;
serv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
serv_addr.sin_port = htons(m_port);
#if	1
if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
	p_err("cann't bind local address : %s", strerror(errno));
#else
bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
#endif
listen(sockfd,5);
signal(SIGCHLD, SIG_IGN);

for(;;) {
	int ti=2;
	clilen=sizeof(cli_addr);

	netfd=accept(sockfd, (struct sockaddr *) &cli_addr,&clilen);
	if ((pid=fork()) < 0)
		p_err("fork error");
	else if (!pid) {
		close(sockfd);
		handle_req();
		exit(0);
	}
	close(netfd);
}
}
