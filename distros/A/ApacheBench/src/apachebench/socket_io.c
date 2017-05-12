#include <sys/ioctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netdb.h>
#include <errno.h>
#include <string.h>

#include "types.h"
#include "socket_io.h"
#include "http_util.h"
#include "xs_util.h"
#include "regression_data.h"

/* --------------------------------------------------------- */

/* make an fd non blocking */

static void
nonblock(int fd) {
    int i = 1;
#ifdef BEOS
    setsockopt(fd, SOL_SOCKET, SO_NONBLOCK, &i, sizeof(i));
#else
    ioctl(fd, FIONBIO, &i);
#endif
}

/* --------------------------------------------------------- */

/* start asnchronous non-blocking connection */

static void
start_connect(struct global * registry, struct connection * c) {
    c->read = 0;
    c->bread = 0;
    c->keepalive = 0;
    c->cbx = 0;
    c->gotheader = 0;
    c->fd = socket(AF_INET, SOCK_STREAM, 0);

#ifdef AB_DEBUG
    printf("AB_DEBUG: start of start_connect()\n");
#endif

    if (c->fd < 0) {
        myerr(registry->warn_and_error, "socket error");
        registry->failed[c->url]++;
        close_connection(registry, c);
        return;
    }
    nonblock(c->fd);

#ifdef AB_DEBUG
    printf("AB_DEBUG: start_connect() - stage 1\n");
#endif

    c->connect_time.tv_sec = 0;
    c->connect_time.tv_usec = 0;
    c->sent_request_time.tv_sec = 0;
    c->sent_request_time.tv_usec = 0;
    gettimeofday(&c->start_time, 0);

    {
        /* get server information */
        struct hostent *he;
#ifdef AB_DEBUG
        printf("AB_DEBUG: start_connect() - stage 2, c->url: '%d'\n", c->url);
#endif
        he = gethostbyname(registry->hostname[c->url]);
#ifdef AB_DEBUG
        printf("AB_DEBUG: start_connect() - stage 3\n");
#endif
        if (!he) {
            char * warn = malloc(256 * sizeof(char));
            sprintf(warn, "Bad hostname: %s, the information stored for it could be wrong!", registry->hostname[c->url]);
            myerr(registry->warn_and_error, warn);
            free(warn);
            /* bad hostname, yields the resource */
            registry->failed[c->url]++;
            close_connection(registry, c);
            return;
        }
#ifdef AB_DEBUG
        printf("AB_DEBUG: start_connect() - stage 4\n");
#endif
        registry->server.sin_family = he->h_addrtype;
        registry->server.sin_port = htons(registry->port[c->url]);
        registry->server.sin_addr.s_addr = ((unsigned long *) (he->h_addr_list[0]))[0]; 
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: start_connect() - stage 5\n");
#endif

    if (connect(c->fd, (struct sockaddr *) & registry->server, sizeof(registry->server)) < 0) {
        if (errno == EINPROGRESS) {
            FD_SET(c->fd, &registry->writebits);
            registry->started[c->url]++;
            return;
        } else {
            ab_close(c->fd);
            /* retry the same request 10 times if it fails to connect */
            if (registry->failed[c->url]++ > 10) {
                myerr(registry->warn_and_error,
                      "Test aborted after 10 failures");
                /* yields the resource */
                close_connection(registry, c);
                return;
            }
            start_connect(registry, c);
            return;
        }
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: start_connect() - stage 6\n");
#endif

    /* connected first time */
    registry->started[c->url]++;
    FD_SET(c->fd, &registry->writebits);
}

/* --------------------------------------------------------- */

/* read data from connection */

static void
read_connection(struct global * registry, struct connection * c) {
    int r;

#ifdef AB_DEBUG
    printf("AB_DEBUG: start of read_connection(), postdata[%d] = %s\n", c->url, registry->postdata[c->url]);
#endif

    r = ab_read(c->fd, registry->buffer, sizeof(registry->buffer));
    if (r == 0 || (r < 0 && errno != EAGAIN)) {
        if (errno == EINPROGRESS)
            registry->good[c->url]++;
        close_connection(registry, c);
        return;
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: read_connection() - stage 1\n");
#endif

    if (r < 0 && errno == EAGAIN)
        return;
    c->read += r;
    if (c->read < registry->buffersize[c->run]-1 &&
        registry->memory[c->run] >= 3)
        strncat(c->response, registry->buffer, r);

#ifdef AB_DEBUG
    printf("AB_DEBUG: read_connection() - stage 2\n");
#endif

    if (!c->gotheader) {
        char *s;
        int wslen = 4;
        int space = CBUFFSIZE - c->cbx - 1;        /* -1 to allow for 0
                                                 * terminator */
        int tocopy = (space < r) ? space : r;
#ifndef CHARSET_EBCDIC
        memcpy(c->cbuff + c->cbx, registry->buffer, tocopy);
#else                                /* CHARSET_EBCDIC */
        ascii2ebcdic(c->cbuff + c->cbx, registry->buffer, tocopy);
#endif                                /* CHARSET_EBCDIC */
        c->cbx += tocopy;
        space -= tocopy;
        c->cbuff[c->cbx] = 0;        /* terminate for benefit of strstr */
        s = strstr(c->cbuff, "\r\n\r\n");
        /*
         * this next line is so that we talk to NCSA 1.5 which blatantly
         * breaks the http specification
         */
        if (!s) {
            s = strstr(c->cbuff, "\n\n");
            wslen = 2;
        }
        if (!s) {
            /* read rest next time */
            if (registry->memory[c->run] >= 2)
                c->response_headers = "";
            if (space)
                return;
            else {
                /*
                 * header is in invalid or too big - close connection
                 */
                ab_close(c->fd);
                FD_CLR(c->fd, &registry->writebits);
                start_connect(registry, c);
            }
        } else {
            /* have full header */

            /*
             * XXX: this parsing isn't even remotely HTTP compliant... but in
             * the interest of speed it doesn't totally have to be, it just
             * needs to be extended to handle whatever servers folks want to
             * test against. -djg
             */

            c->gotheader = 1;
            *s = 0;                /* terminate at end of header */
            if (registry->memory[c->run] >= 2) {
                c->response_headers = malloc(CBUFFSIZE * sizeof(char));
                strcpy(c->response_headers, c->cbuff);
            }
            if (registry->keepalive[c->url] &&
                (strstr(c->cbuff, "Keep-Alive") ||
                 strstr(c->cbuff, "keep-alive"))) { /* for benefit of MSIIS */
                char *cl;
                cl = strstr(c->cbuff, "Content-Length:");
                /* handle NCSA, which sends Content-length: */
                if (!cl)
                    cl = strstr(c->cbuff, "Content-length:");
                if (cl) {
                    c->keepalive = 1;
                    c->length = atoi(cl + 16);
                }
            }
            c->bread += c->cbx - (s + wslen - c->cbuff) + r - tocopy;
        }
    } else {
        /* outside header, everything we have read is entity body */
        c->bread += r;
    }

    /*
     * cater for the case where we're using keepalives and doing HEAD
     * requests
     */
    if (c->keepalive &&
        ((c->bread >= c->length) || (registry->posting[c->url] < 0))) {
        /* save current url for checking for hostname/port changes */
        int prev = c->url;

        /* finished a keep-alive connection */
        registry->good[c->url]++;
        registry->finished[c->url]++;

        store_regression_data(registry, c);

        if (++registry->done >= registry->need_to_be_done)
            return;

        if (!schedule_next_request(registry, c))
            return;

        c->length = 0;
        c->gotheader = 0;
        c->cbx = 0;
        c->read = c->bread = 0;
        c->keepalive = 0;

        /* if new hostname/port is different from last hostname/port, or new
           url is *not* keepalive, then we need to close connection and start
           a new connection */
        if (registry->keepalive[c->url] &&
            strcmp(registry->hostname[c->url], registry->hostname[prev]) == 0
            && registry->port[c->url] == registry->port[prev]) {
            write_request(registry, c);
            registry->started[c->url]++;
            c->start_time = c->connect_time;        /* zero connect time with keep-alive */
        } else {
            ab_close(c->fd);
            FD_CLR(c->fd, &registry->readbits);
            FD_CLR(c->fd, &registry->writebits);
            start_connect(registry, c);
        }
    }
}

/* --------------------------------------------------------- */

/* close down connection and save stats */

static void
close_connection(struct global * registry, struct connection * c) {
#ifdef AB_DEBUG
    printf("AB_DEBUG: start of close_connection(), postdata[%d] = %s\n", c->url, registry->postdata[c->url]);
#endif

    if (registry->use_auto_cookies[c->run])
        extract_cookies_from_response(registry, c);
    store_regression_data(registry, c);
    registry->finished[c->url]++;

#ifdef AB_DEBUG
    printf("AB_DEBUG: close_connection() - stage 1\n");
#endif

    ab_close(c->fd);
    FD_CLR(c->fd, &registry->readbits);
    FD_CLR(c->fd, &registry->writebits);

#ifdef AB_DEBUG
    printf("AB_DEBUG: close_connection() - stage 2\n");
#endif

    /* finish if last response has been received */
    if (++registry->done >= registry->need_to_be_done)
        return;

#ifdef AB_DEBUG
    printf("AB_DEBUG: close_connection() - stage 3\n");
#endif

    /* else continue with requests in run queues */
    if (schedule_next_request(registry, c))
        start_connect(registry, c);
}


/* --------------------------------------------------------- */

/* write out request to a connection - assumes we can write
   (small) request out in one go into our new socket buffer  */

static void
write_request(struct global * registry, struct connection * c) {

#ifndef NO_WRITEV
    struct iovec out[2];
    int outcnt = 1;
#endif
    int bytes_sent;
    STRLEN len;
    SV *res;
    char *post_body;

#ifdef AB_DEBUG
    printf("AB_DEBUG: write_request() - stage 1, registry->done = %d\n", registry->done);
#endif
    gettimeofday(&c->before_postdata_time, 0);

    /* the url in this run has dynamicly-generated postdata */
    if (registry->posting[c->url] == 2) {
        res = call_perl_function__one_arg(registry->postsubs[c->url],
                                          newSVpv(c->url > 0 ? registry->stats[c->url - 1][c->thread].response : "", 0));

        if (SvPOK(res)) {
            post_body = SvPV(res, len);
#ifdef AB_DEBUG
            printf("AB_DEBUG: write_request() - stage 1-postsub.2, postsub res %s, length %d\n", post_body, (int)len);
#endif
            registry->postdata[c->url] = post_body;
            registry->postlen[c->url] = (int) len;
        } else {
            registry->postdata[c->url] = "";
            registry->postlen[c->url] = 0;
            registry->posting[c->url] = 0; // change back to a GET request
        }
    }

    gettimeofday(&c->connect_time, 0); // start timer

    reset_request(registry, c); // this generates the request headers; must call the above first to determine POST content

#ifdef AB_DEBUG
    printf("AB_DEBUG: write_request() - stage 2, registry->done = %d\n", registry->done);
#endif

#ifndef NO_WRITEV
    out[0].iov_base = c->request;
    out[0].iov_len = c->reqlen;

#ifdef AB_DEBUG
    printf("AB_DEBUG: write_request() - stage 2a.1, registry->done = %d, postdata[%d] = %s\n", registry->done, c->url, registry->postdata[c->url]);
#endif
    if (registry->posting[c->url] > 0) {
        out[1].iov_base = registry->postdata[c->url];
        out[1].iov_len = registry->postlen[c->url];
        outcnt = 2;
        registry->totalposted[c->url] = (c->reqlen + registry->postlen[c->url]);
    }
#ifdef AB_DEBUG
    printf("AB_DEBUG: write_request() - stage 2a.2, registry->done = %d\n", registry->done);
#endif
    bytes_sent = writev(c->fd, out, outcnt);

#else /* NO_WRITEV */

#ifdef AB_DEBUG
    printf("AB_DEBUG: write_request() - stage 2b.1, registry->done = %d, postdata[%d] = %s\n", registry->done, c->url, registry->postdata[c->url]);
#endif
    ab_write(c->fd, c->request, c->reqlen);
    if (registry->posting[c->url] > 0)
        bytes_sent = ab_write(c->fd, registry->postdata[c->url], registry->postlen[c->url]);
#endif /* NO_WRITEV */

#ifdef AB_DEBUG
    printf("AB_DEBUG: write_request() - stage 3, registry->done = %d, postdata[%d] = %s\n", registry->done, c->url, registry->postdata[c->url]);
#endif

    FD_SET(c->fd, &registry->readbits);
    FD_CLR(c->fd, &registry->writebits);
    gettimeofday(&c->sent_request_time, 0);

    if (registry->memory[c->run] >= 3)
        c->response = calloc(1, registry->buffersize[c->run]);
}

/* --------------------------------------------------------- */

/* setup or reset request */
static int
reset_request(struct global * registry, struct connection * c) {
    int i = c->url;

    char * ctype = calloc(40, sizeof(char));
    strcpy(ctype, "application/x-www-form-urlencoded");

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 0.1\n");
#endif
    if (registry->ctypes[i]) {
#ifdef AB_DEBUG
        printf("AB_DEBUG: reset_request() - stage 0.1.1\n");
#endif
        free(ctype);

#ifdef AB_DEBUG
        printf("AB_DEBUG: reset_request() - stage 0.1.2\n");
#endif
        ctype = registry->ctypes[i];
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 1\n");
#endif

    c->request = calloc(registry->buffersize[c->run], sizeof(char));
    c->request_headers = calloc(registry->buffersize[c->run], sizeof(char));

    if (registry->posting[i] <= 0) {
#ifdef AB_DEBUG
        printf("AB_DEBUG: reset_request() - stage 1.1 (GET)\n");
#endif
        sprintf(c->request_headers, "%s %s HTTP/1.0\r\n"
                "User-Agent: ApacheBench-Perl/%s\r\n"
                "Host: %s\r\n"
                "Accept: */*\r\n",
                (registry->posting[i] == 0) ? "GET" : "HEAD",
                registry->path[i],
                registry->version,
                registry->hostname[i]);
    } else {
#ifdef AB_DEBUG
        printf("AB_DEBUG: reset_request() - stage 1.1 (POST)\n");
#endif
        sprintf(c->request_headers, "POST %s HTTP/1.0\r\n"
                "User-Agent: ApacheBench-Perl/%s\r\n"
                "Host: %s\r\n"
                "Accept: */*\r\n"
                "Content-length: %d\r\n"
                "Content-type: %s\r\n",
                registry->path[i],
                registry->version,
                registry->hostname[i],
                registry->postlen[i],
                ctype);
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 2\n");
#endif

    if (registry->keepalive[i])
        strcat(c->request_headers, "Connection: Keep-Alive\r\n");
    if (registry->cookie[c->run]) {
        strcat(c->request_headers, "Cookie: ");
        strcat(c->request_headers, registry->cookie[c->run]);
        strcat(c->request_headers, "\r\n");
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 2.1: c->run %d; c->thread %d\n", c->run, c->thread);
#endif

    allocate_auto_cookie_memory(registry, c);

    if (registry->use_auto_cookies[c->run] && registry->auto_cookies[c->run] != NULL && registry->auto_cookies[c->run][c->thread] != NULL) {

#ifdef AB_DEBUG
        printf("AB_DEBUG: reset_request() - stage 2.2a: request_headers %s\n", c->request_headers);
        printf("AB_DEBUG: reset_request() - stage 2.2b: auto_cookies %s\n", registry->auto_cookies[c->run][c->thread]);
#endif

        strcat(c->request_headers, registry->auto_cookies[c->run][c->thread]);
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 2.3: c->run %d; c->thread %d\n", c->run, c->thread);
#endif

    if (registry->req_headers[i]) {
        strcat(c->request_headers, registry->req_headers[i]);
        strcat(c->request_headers, "\r\n");
    }

    strcat(c->request_headers, "\r\n");

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 2.4: c->run %d; c->thread %d\n", c->run, c->thread);
#endif

    strcpy(c->request, c->request_headers);
    c->reqlen = strlen(c->request);

#ifdef AB_DEBUG
    printf("AB_DEBUG: reset_request() - stage 3\n");
#endif

#ifdef CHARSET_EBCDIC
    ebcdic2ascii(c->request, c->request, c->reqlen);
#endif                                /* CHARSET_EBCDIC */

    return 0;
}

/* --------------------------------------------------------- */

/* setup the next request in the sequence / repetition / run to be sent
   returns 1 if the next request is ready to be sent,
   returns 0 if this connection is done,
   sets the connection values: c->run, c->url, c->thread, and c->state,
   as well as helper structures: registry->which_thread[][],
     registry->ready_to_run_queue[], and registry->arranged[]
*/

static int
schedule_next_request(struct global * registry, struct connection * c) {

    if (registry->priority == RUN_PRIORITY) {
        /* if the last url in this run has repeated enough, go to next run */
        if (registry->started[registry->position[c->run + 1] - 1] >= registry->repeats[c->run])
            return schedule_request_in_next_run(registry, c);

        /* possible more resources needed in this group */
        /* started[position[c->run + 1] - 1] < repeats[c->run] */
        if (registry->order[c->run] == DEPTH_FIRST) {
            /* for depth_first, connect the next one and restart the
               sequence if we're at the last url in the run */
            if (++c->url == registry->position[c->run + 1]) {
                c->url = registry->position[c->run];
                c->thread = registry->started[c->url];
            }
            return 1;
        } else { /* breadth_first */
            if (c->url < (registry->position[c->run + 1] - 1))
                /* TODO: check if (registry->finished[c->url] > 0) ??? */
                registry->which_thread[c->url+1][registry->finished[c->url] - 1] = c->thread;
            if (registry->started[c->url] == registry->repeats[c->run])
                /* go to next url in sequence if we repeated this one enough */
                c->url++;
            if (c->url == registry->position[c->run]) {
                /* this is the first url in the sequence: set its repetition
                   number to the initial incremental value (0, 1, 2, 3, ...) */
                c->thread = registry->which_thread[c->url][registry->started[c->url]];
                return 1;
            }
            /* only start another request from this run if more requests of the
               previous url in the sequence have finished(in-order execution)*/
            if (registry->started[c->url] < registry->finished[c->url - 1]) {
                c->thread = registry->started[c->url];
                return 1;
            } else {
                return schedule_request_in_next_run(registry, c);
            }
        }

    } else { /* equal_opportunity */
        /* we use a FIFO to queue up requests to be sent */
        if (c->url < registry->position[c->run + 1]-1) {
            /* if url is before the end of the url sequence,
               add it to the tail of the request queue */
            registry->ready_to_run_queue[registry->tail].url = c->url + 1;
            registry->ready_to_run_queue[registry->tail].thread = c->thread;
            registry->ready_to_run_queue[registry->tail++].run = c->run;
            registry->arranged[c->url + 1]++;
        } else if (registry->order[c->run] == DEPTH_FIRST
                   && registry->arranged[registry->position[c->run]] < registry->repeats[c->run]) {
            /* end of the url sequence in depth_first with more repetitions
               necessary: start from the beginning of the url sequence */
            registry->ready_to_run_queue[registry->tail].url = registry->position[c->run];
            registry->ready_to_run_queue[registry->tail].thread = registry->arranged[registry->position[c->run]]++;
            registry->ready_to_run_queue[registry->tail++].run = c->run;
        }

        if (registry->head >= registry->tail) {
            c->state = STATE_DONE;
            return 0;
        }
        c->thread = registry->ready_to_run_queue[registry->head].thread;
        c->url = registry->ready_to_run_queue[registry->head].url;
        c->run = registry->ready_to_run_queue[registry->head++].run;
        return 1;
    }
}

/* --------------------------------------------------------- */

/* move connection to the next run, because the current run either doesn't need
   or cannot use any more connection slots (resources)
   returns 1 if the next request is ready to be sent,
   returns 0 if this connection is done */

static int
schedule_request_in_next_run(struct global * registry, struct connection * c) {
    c->run++;
    while (c->run < registry->number_of_runs) {
        if (registry->started[registry->position[c->run + 1] - 1] >= registry->repeats[c->run]
            || (registry->order[c->run] == DEPTH_FIRST
                && registry->started[registry->position[c->run]] > 0)) {
            /* this run has finished all repetitions of url requests
               or is a depth_first run which only requires one slot,
               so doesn't need this resource anymore */
            c->run++;
            continue;
        }
        /* start at first url in the run */
        c->url = registry->position[c->run];
        if (registry->started[c->url] < registry->repeats[c->run]) {
            /* for breadth_first, start one more connect to 1st url if possible
               for depth_first, get started here */
            c->thread = registry->which_thread[c->url][registry->started[c->url]];
            return 1;
        }
        /* look at each url in the sequence until we find one which needs
           to be repeated more */
        while (++c->url < registry->position[c->run + 1]
               && registry->started[c->url] >= registry->repeats[c->run]);
        /* only start another request from this run if more requests of the
           previous url in the sequence have finished (in-order execution) */
        if (registry->started[c->url] < registry->finished[c->url - 1]) {
            c->thread = registry->which_thread[c->url][registry->started[c->url]];
            return 1;
        } else
            /* this run doesn't need any more resources */
            c->run++;
    }
    /* no one needs any more resources */
    c->state = STATE_DONE;
    return 0;
}

