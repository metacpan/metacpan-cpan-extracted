#ifndef _APACHEBENCH_TYPES_H_
#define _APACHEBENCH_TYPES_H_

/* ------------------- DEFINITIONS -------------------------- */

#define CBUFFSIZE        4096
#define WARN_BUFFSIZE   10240
#define STATE_DONE 	  1
#define STATE_READY 	  0
#define RUN_PRIORITY	  1
#define EQUAL_OPPORTUNITY 0
#define DEPTH_FIRST	  1
#define BREADTH_FIRST	  0

/* ------------------- STRUCTS -------------------------- */

struct connection {
    int fd;
    int state;
    int url;			/* which url are we testing */
    int read;			/* amount of bytes read */
    int bread;			/* amount of body read */
    int length;			/* Content-Length value used for keep-alive */
    char cbuff[CBUFFSIZE];	/* a buffer to store server response header */
    int cbx;			/* offset in cbuffer */
    int keepalive;		/* non-zero if a keep-alive request */
    int gotheader;		/* non-zero if we have the entire header in
				 * cbuff */
    int thread;			/* Thread number */
    int run;

    struct timeval start_time, connect_time, before_postdata_time, sent_request_time, done_time;

    char *request;		/* HTTP request */
    char *request_headers;
    int reqlen;

    char *response_headers;	/* HTTP response */
    char *response;
};

struct data {
    int run;			/* which run */
    int thread; 		/* Thread number */
    int read;			/* number of bytes read */
    int bread;			/* total amount of entity body read */
    int ctime;			/* time in ms to connect */
    int rtime;			/* time in ms for http request */
    int time;			/* time in ms for full req/resp interval */

    char *request;
    char *request_headers;

    char *response_headers;
    char *response;
};

struct threadval {
    int run;			/* which run */
    int url;			/* which url are we testing */
    int thread; 		/* Thread number */
};

/* --------------------- GLOBALS ---------------------------- */

struct global {
    int concurrency;		/* Number of multiple requests to make */
    int *repeats;		/* Number of time to repeat for each run */
    int requests;		/* the max of the repeats */
    double tlimit;		/* global time limit, in seconds */
    struct timeval min_tlimit;	/* minimum of all time limits */
    int *position;		/* The position next run starts */

    char **hostname;		/* host name */
    int *port;			/* port numbers */
    char **path;		/* path name */
    char **ctypes;		/* values for Content-type: headers */
    double *url_tlimit;		/* time limit in seconds for each url */
    bool *keepalive;		/* whether to use Connection: Keep-Alive */

    int *posting;		/* GET if ==0, POST if >0, HEAD if <0 */
    char **postdata, **cookie;	/* datas for post and optional cookie line */
    SV **postsubs;		/* coderefs for post */
    char **req_headers;		/* optional arbitrary request headers to add */
    char ***auto_cookies;	/* cookies extracted from response_headers for the run, i.e. set by http server */
    bool *use_auto_cookies;	/* whether to use auto_cookie feature for the run */
    int *postlen;		/* length of data to be POSTed */
    int *totalposted;		/* total number of bytes posted, inc. headers*/

    int *good, *failed;		/* number of good and bad requests */
    int *started, *finished, *arranged;
				/* numbers of requests  started , */
				/* finished or arranged for each url*/
    int **which_thread;		/* which thread is available */
    struct threadval *ready_to_run_queue;
    int head, tail, done, need_to_be_done;

    int priority;
    int *order;
    int *buffersize;
    int *memory;
    int number_of_urls, number_of_runs;

    char version[8];		/* to store perl module version */
    char warn_and_error[WARN_BUFFSIZE];  /* warn and error message returned to perl */

    int total_bytes_received;
    struct timeval starttime, endtime;

    /* one global throw-away buffer to read stuff into */
    char buffer[8192];

    struct connection *con;	/* connection array */

    /* regression data for each request */
    struct data **stats;

    fd_set readbits, writebits;	/* bits for select */
    struct sockaddr_in server;	/* server addr structure */
};

#endif /* !_APACHEBENCH_TYPES_H_ */
