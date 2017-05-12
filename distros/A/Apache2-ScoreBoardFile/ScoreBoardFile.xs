#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

# include <sys/mman.h>
# include <sys/types.h>
# include <sys/stat.h>
# include <fcntl.h>
# include <unistd.h>

# include <httpd.h>
# include <http_config.h>
# include <http_protocol.h>
# include <ap_config.h>
# include <scoreboard.h>

struct sb {
  union {
    char dummy[APR_ALIGN_DEFAULT(sizeof(apr_size_t))];
    apr_size_t sz;
  } prefix;
  global_score gscore;
  process_score pscore[0];
};
typedef struct sb* Apache2__ScoreBoardFile;
typedef process_score* Apache2__ScoreBoardFile__Process;
typedef worker_score* Apache2__ScoreBoardFile__Worker;

static char ws_status_letters[]=".S_RWKLDCGIP";

# define STAT_NUM_REQ -2
# define STAT_NUM_BYTE -3
# define STAT_BUSY_WORKER -4
# define STAT_IDLE_WORKER -5
# define STAT_CURR_WORKER -6
# define MAX_STAT_RESULTS 17	/* number of letters in ws_status_letters
				 * plus number of STAT_* constants */

struct summary {
  int what;
  apr_off_t count;
};

static inline int
status_char_to_status(char *s) {
  if(!s[0]) return -1;		/* empty string */
  if(!(s[1]==0 || s[2]==0))	/* strlen must be 1 or 2 */
    return -1;
  if( s[1]==0 ) {		/* 1-letter code */
    switch(s[0]) {
    case '.': return SERVER_DEAD;
    case '_': return SERVER_READY;
    case 'S': return SERVER_STARTING;
    case 'R': return SERVER_BUSY_READ;
    case 'W': return SERVER_BUSY_WRITE;
    case 'K': return SERVER_BUSY_KEEPALIVE;
    case 'L': return SERVER_BUSY_LOG;
    case 'D': return SERVER_BUSY_DNS;
    case 'C': return SERVER_CLOSING;
    case 'G': return SERVER_GRACEFUL;
    case 'I': return SERVER_IDLE_KILL;
    case 'P':
# ifdef SERVER_WAIT_INTERP
      return SERVER_WAIT_INTERP;
# else
      return -1;
# endif
    }
  } else {			/* 2-letter code */
    switch(s[1]) {
    case 'w':
      switch(s[0]) {
      case 'b': return STAT_BUSY_WORKER;  /* bw */
      case 'i': return STAT_IDLE_WORKER;  /* iw */
      case 'c': return STAT_CURR_WORKER;  /* cw */
      }
      break;
    case 'r':
      switch(s[0]) {
      case 'n': return STAT_NUM_REQ;      /* nr */
      }
      break;
    case 'b':
      switch(s[0]) {
      case 'n': return STAT_NUM_BYTE;     /* nb */
      }
      break;
    }
  }
  return -1;
}

static inline void
collect_summary(Apache2__ScoreBoardFile obj, struct summary *result, int len) {
  int i, j, k, plim, tlim;
  worker_score *ws;
  process_score *ps;

  plim=obj->gscore.server_limit;
  tlim=obj->gscore.thread_limit;
  for(i=0; i<plim; i++) {
    ps=&(obj->pscore[i]);
    for(j=0; j<tlim; j++) {
      ws=&(((worker_score*)(&(obj->pscore[plim])))[tlim*i+j]);
      /*warn("i: %d, j=%d, pid: %d, status: %c\n",
	i, j, (ws->pid ? ws->pid : ps->pid),
	(ws->status<sizeof(ws_status_letters)-1 ? ws_status_letters[ws->status] : '?'));*/
      for(k=0; k<len; k++) {
	if( result[k].what<0 ) {
	  switch(result[k].what) {
	  case STAT_NUM_REQ:
	    if( ws->access_count!=0 ||
		(ws->status!=SERVER_READY &&
		 ws->status!=SERVER_DEAD) )
	      result[k].count+=ws->access_count;
	    break;
	  case STAT_NUM_BYTE:
	    if( ws->access_count!=0 ||
		(ws->status!=SERVER_READY &&
		 ws->status!=SERVER_DEAD) )
	      result[k].count+=ws->bytes_served;
	    break;
	  case STAT_BUSY_WORKER:
	    if( !ps->quiescing && ps->pid ) {
	      switch(ws->status) {
	      case SERVER_DEAD:
	      case SERVER_STARTING:
	      case SERVER_IDLE_KILL:
	      case SERVER_READY:
		break;
	      default:
		result[k].count++;
		break;
	      }
	    }
	    break;
	  case STAT_IDLE_WORKER:
	    if( !ps->quiescing && ps->pid ) {
	      switch(ws->status) {
	      case SERVER_READY:
		result[k].count++;
		break;
	      }
	    }
	    break;
	  case STAT_CURR_WORKER:
	    if( !ps->quiescing && ps->pid ) {
	      switch(ws->status) {
	      case SERVER_DEAD:
	      case SERVER_STARTING:
	      case SERVER_IDLE_KILL:
		break;
	      default:
		result[k].count++;
		break;
	      }
	    }
	    break;
	  }
	} else if(result[k].what==ws->status) {
	  result[k].count++;
	}
      }
    }
  }
}

static inline int
init(int fd, Apache2__ScoreBoardFile *result) {
  void *map;
  struct stat statbuf;

  *result=NULL;
  if(fstat(fd, &statbuf)) return -1;

  map=mmap(NULL, statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);
  if( map==MAP_FAILED ) return -1;

  *result=map;
  return 0;
}

static inline double
time2double( apr_time_t time ) {
  return (double)apr_time_sec(time) +
         (double)apr_time_usec(time)/(double)APR_USEC_PER_SEC;
}

static inline int
destroy( Apache2__ScoreBoardFile map ) {
  return munmap(map, map->prefix.sz);
}

MODULE = Apache2::ScoreBoardFile  PACKAGE = Apache2::ScoreBoardFile

Apache2::ScoreBoardFile
new(class, stream)
	SV *class
        SV *stream
      PROTOTYPE: $$
      CODE: 
        PERL_UNUSED_VAR(class); /* -W */
	{
	  SV *sv;
	  IO* io;

	  if( SvROK(stream) &&
	      (sv=SvRV(stream)) &&
	      SvTYPE(sv)==SVt_PVGV &&
	      (io=GvIO(sv)) &&
	      IoIFP(io) ) {
	    init( PerlIO_fileno(IoIFP(io)), &RETVAL );
	  } else {
	    int fd=open(SvPV_nolen(stream), O_RDONLY);
	    if(fd<0) RETVAL=NULL;
	    else {
	      init(fd, &RETVAL);
	      close(fd);
	    }
	  }
	}
      OUTPUT:
	RETVAL

void
summary(obj, ...)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $@
      PPCODE:
        {
	  int i;
	  struct summary result[MAX_STAT_RESULTS];

	  memset(result, 0, sizeof(result));
	  items--;
	  if( items>MAX_STAT_RESULTS )
	    croak("Parameter list too long %d", items+1);
	  for( i=0; i<items; i++ ) {
	    char *p=(char*)SvPV_nolen(ST(i+1));
	    if( (result[i].what=status_char_to_status(p))==-1 ) {
	      croak("Unknown parameter %s", p);
	    }
	  }
	  collect_summary(obj,result, items);
	  for( i=0; i<items; i++ ) {
	    PUSHs(sv_2mortal(newSVnv((double)result[i].count)));
	  }
	}

unsigned int
shmsize(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->prefix.sz;
      OUTPUT:
	RETVAL

unsigned int
server_limit(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->gscore.server_limit;
      OUTPUT:
	RETVAL

unsigned int
thread_limit(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->gscore.thread_limit;
      OUTPUT:
	RETVAL

unsigned int
type(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->gscore.sb_type;
      OUTPUT:
	RETVAL

unsigned int
generation(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->gscore.running_generation;
      OUTPUT:
	RETVAL

unsigned int
lb_limit(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->gscore.lb_limit;
      OUTPUT:
	RETVAL

double
restart_time(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	RETVAL=time2double(obj->gscore.restart_time);
      OUTPUT:
	RETVAL

Apache2::ScoreBoardFile::Process
process(obj, index)
	Apache2::ScoreBoardFile obj
	unsigned int index
      PROTOTYPE: $$
      INIT:
	if( !(0<=index && index<obj->gscore.server_limit) )
	  XSRETURN_UNDEF;
      CODE: 
	RETVAL=&(obj->pscore[index]);
      OUTPUT:
	RETVAL

Apache2::ScoreBoardFile::Worker
worker(obj, pindex, tindex=-1)
	Apache2::ScoreBoardFile obj
	unsigned int pindex
	unsigned int tindex
	PROTOTYPE: $$;$
      INIT:
	int sl=obj->gscore.server_limit;
	int tl=obj->gscore.thread_limit;
	if( items>2 ) pindex=tl*pindex+tindex; /* 2 indices: procnr, threadnr */
	if( !(0<=pindex && pindex<sl*tl) ) XSRETURN_UNDEF;
      CODE: 
        /* warn("sl=%d, tl=%d, start_of_ws=%x\n", sl, tl, */
	/*    (char*)(&(obj->pscore[sl]))-(char*)obj); */
        RETVAL=&(((worker_score*)(&(obj->pscore[sl])))[pindex]);
      OUTPUT:
	RETVAL

void
DESTROY(obj)
	Apache2::ScoreBoardFile obj
      PROTOTYPE: $
      CODE: 
	destroy(obj);

MODULE = Apache2::ScoreBoardFile  PACKAGE = Apache2::ScoreBoardFile::Process

unsigned int
pid(obj)
        Apache2::ScoreBoardFile::Process obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->pid;
      OUTPUT:
	RETVAL

unsigned int
generation(obj)
        Apache2::ScoreBoardFile::Process obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->generation;
      OUTPUT:
	RETVAL

unsigned int
quiescing(obj)
        Apache2::ScoreBoardFile::Process obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->quiescing;
      OUTPUT:
	RETVAL

MODULE = Apache2::ScoreBoardFile  PACKAGE = Apache2::ScoreBoardFile::Worker

int
thread_num(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->thread_num;
      OUTPUT:
	RETVAL

unsigned int
pid(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->pid;
      OUTPUT:
	RETVAL

unsigned int
generation(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->generation;
      OUTPUT:
	RETVAL

char
status(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
        unsigned status=obj->status;
        if( status>=sizeof(ws_status_letters)-1 ) {
	  RETVAL='?';
	} else {
	  RETVAL=ws_status_letters[status];
	}
      OUTPUT:
	RETVAL

unsigned int
access_count(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->access_count;
      OUTPUT:
	RETVAL

unsigned int
bytes_served(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->bytes_served;
      OUTPUT:
	RETVAL

unsigned int
my_access_count(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->my_access_count;
      OUTPUT:
	RETVAL

unsigned int
my_bytes_served(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->my_bytes_served;
      OUTPUT:
	RETVAL

unsigned int
conn_count(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->conn_count;
      OUTPUT:
	RETVAL

unsigned int
conn_bytes(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->conn_bytes;
      OUTPUT:
	RETVAL

double
start_time(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=time2double(obj->start_time);
      OUTPUT:
	RETVAL

double
stop_time(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=time2double(obj->stop_time);
      OUTPUT:
	RETVAL

double
last_used(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=time2double(obj->last_used);
      OUTPUT:
	RETVAL

char*
client(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->client;
      OUTPUT:
	RETVAL

char*
request(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->request;
      OUTPUT:
	RETVAL

char*
vhost(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
	RETVAL=obj->vhost;
      OUTPUT:
	RETVAL

unsigned int
tid(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
#if APR_HAS_THREADS
	RETVAL=obj->tid;
#else
	RETVAL=(unsigned)-1;
#endif
      OUTPUT:
	RETVAL

unsigned int
utime(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
#if HAVE_TIMES
	RETVAL=obj->times.tms_utime;
#else
	RETVAL=(unsigned)-1;
#endif
      OUTPUT:
	RETVAL

unsigned int
stime(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
#if HAVE_TIMES
	RETVAL=obj->times.tms_stime;
#else
	RETVAL=(unsigned)-1;
#endif
      OUTPUT:
	RETVAL

unsigned int
cutime(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
#if HAVE_TIMES
	RETVAL=obj->times.tms_cutime;
#else
	RETVAL=(unsigned)-1;
#endif
      OUTPUT:
	RETVAL

unsigned int
cstime(obj)
        Apache2::ScoreBoardFile::Worker obj
      PROTOTYPE: $
      CODE: 
#if HAVE_TIMES
	RETVAL=obj->times.tms_cstime;
#else
	RETVAL=(unsigned)-1;
#endif
      OUTPUT:
	RETVAL

 # Local Variables:
 # mode: c
 # End:
