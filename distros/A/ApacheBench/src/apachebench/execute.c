#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>

#include "types.h"
#include "execute.h"

/* ------------------------------------------------------- */

void
initialize(struct global * registry) {
    int i,j;

#ifdef AB_DEBUG
    printf("AB_DEBUG: start of initialize()\n");
#endif

    registry->cookie = malloc(registry->number_of_runs * sizeof(char *));
    registry->buffersize = malloc(registry->number_of_runs * sizeof(int));
    registry->auto_cookies = (char ***) calloc(registry->number_of_runs, sizeof(char **)); // must be zeroed for the calloc code in http_util.c

    registry->which_thread = malloc(registry->number_of_urls * sizeof(int *));
    registry->arranged = malloc(registry->number_of_urls * sizeof(int));

    for (i = 0; i < registry->number_of_urls; i++)
        registry->arranged[i] = 0;
    for (i = 0; i < registry->number_of_runs; i++) {
        for (j = registry->position[i]; j < registry->position[i+1]; j++)
            registry->which_thread[j] = malloc(registry->repeats[i] * sizeof(int));
        for (j = 0; j < registry->repeats[i]; j++)
            registry->which_thread[registry->position[i]][j] = j;
        registry->need_to_be_done += registry->repeats[i] * (registry->position[i+1] - registry->position[i]);
    }
    registry->ready_to_run_queue = malloc(registry->need_to_be_done * sizeof(struct threadval));
    for (i = 0; i < registry->number_of_runs; i++) {
        if (registry->order[i] == DEPTH_FIRST) {
            if ((registry->priority == EQUAL_OPPORTUNITY) || (registry->tail < registry->concurrency)) {
                registry->arranged[registry->position[i]] = 1;
                registry->ready_to_run_queue[registry->tail].run = i;
                registry->ready_to_run_queue[registry->tail].url = registry->position[i];
                registry->ready_to_run_queue[registry->tail++].thread = 0;
            }
        } else for (j = 0; j < registry->repeats[i]; j++)
            if ((registry->priority == EQUAL_OPPORTUNITY) || (registry->tail < registry->concurrency)) {
                registry->arranged[registry->position[i]] += 1;
                registry->ready_to_run_queue[registry->tail].run = i;
                registry->ready_to_run_queue[registry->tail].thread = j;
                registry->ready_to_run_queue[registry->tail++].url = registry->position[i];
            }
    }
    registry->hostname = malloc(registry->number_of_urls * sizeof(char *));
    registry->path = malloc(registry->number_of_urls * sizeof(char *));
    registry->port = malloc(registry->number_of_urls * sizeof(int));
    registry->ctypes = malloc(registry->number_of_urls * sizeof(char *));
    registry->req_headers = malloc(registry->number_of_urls * sizeof(char *));
    registry->keepalive = malloc(registry->number_of_urls * sizeof(bool));
    registry->url_tlimit = malloc(registry->number_of_urls * sizeof(double));
    registry->started = malloc(registry->number_of_urls * sizeof(int));
    registry->finished = malloc(registry->number_of_urls * sizeof(int));
    registry->failed = malloc(registry->number_of_urls * sizeof(int));
    registry->good = malloc(registry->number_of_urls * sizeof(int));
    registry->postdata = malloc(registry->number_of_urls * sizeof(char *));
    registry->postsubs = malloc(registry->number_of_urls * sizeof(SV *));
    registry->postlen = malloc(registry->number_of_urls * sizeof(int));
    registry->posting = malloc(registry->number_of_urls * sizeof(int));
    registry->totalposted = malloc(registry->number_of_urls * sizeof(int));
    for (i = 0; i < registry->number_of_urls; i++) {
        registry->totalposted[i] = 0;
        registry->port[i] = 80;        /* default port number */
        registry->started[i] = 0;
        registry->finished[i] = 0;
        registry->failed[i] = 0;
        registry->good[i] = 0;
    }
#ifdef AB_DEBUG
    printf("AB_DEBUG: end of initialize()\n");
#endif
}

/* --------------------------------------------------------- */

/* run the tests */

static void
test(struct global * registry) {
    struct timeval timeout, now;
    fd_set sel_read, sel_except, sel_write;
    int i;

    registry->con = calloc(registry->concurrency, sizeof(struct connection));
    memset(registry->con, 0, registry->concurrency * sizeof(struct connection));

#ifdef AB_DEBUG
    printf("AB_DEBUG: start of test()\n");
#endif

    for (i = 0; i < registry->concurrency; i++) {
        registry->con[i].url = registry->ready_to_run_queue[i].url;
        registry->con[i].run = registry->ready_to_run_queue[i].run;
        registry->con[i].state = STATE_READY;
        registry->con[i].thread = registry->ready_to_run_queue[i].thread;
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: test() - stage 1\n");
#endif

    registry->stats = calloc(registry->number_of_urls, sizeof(struct data *));
    for (i = 0; i < registry->number_of_runs; i++) {
        int j;
        for (j = registry->position[i]; j < registry->position[i+1]; j++)
            registry->stats[j] = calloc(registry->repeats[i], sizeof(struct data));
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: test() - stage 2\n");
#endif

    FD_ZERO(&registry->readbits);
    FD_ZERO(&registry->writebits);

#ifdef AB_DEBUG
    printf("AB_DEBUG: test() - stage 3\n");
#endif

    /* ok - lets start */
    gettimeofday(&registry->starttime, 0);

#ifdef AB_DEBUG
    printf("AB_DEBUG: test() - stage 4\n");
#endif

    /* initialise lots of requests */

    registry->head = registry->concurrency;
    for (i = 0; i < registry->concurrency; i++)
        start_connect(registry, &registry->con[i]);

#ifdef AB_DEBUG
    printf("AB_DEBUG: test() - stage 5\n");
#endif

    while (registry->done < registry->need_to_be_done) {
        int n;

#ifdef AB_DEBUG
        printf("AB_DEBUG: test() - stage 5.1, registry->done = %d\n", registry->done);
#endif

        /* setup bit arrays */
        memcpy(&sel_except, &registry->readbits, sizeof(registry->readbits));
        memcpy(&sel_read, &registry->readbits, sizeof(registry->readbits));
        memcpy(&sel_write, &registry->writebits, sizeof(registry->writebits));

#ifdef AB_DEBUG
        printf("AB_DEBUG: test() - stage 5.2, registry->done = %d\n", registry->done);
#endif

        /* Timeout of 30 seconds, or minimum time limit specified by config. */
        timeout.tv_sec = registry->min_tlimit.tv_sec;
        timeout.tv_usec = registry->min_tlimit.tv_usec;
        n = select(FD_SETSIZE, &sel_read, &sel_write, &sel_except, &timeout);
#ifdef AB_DEBUG
        printf("AB_DEBUG: test() - stage 5.3, registry->done = %d\n", registry->done);
#endif
        if (!n)
            myerr(registry->warn_and_error, "Server timed out");
        if (n < 1)
            myerr(registry->warn_and_error, "Select error.");
#ifdef AB_DEBUG
        printf("AB_DEBUG: test() - stage 5.4, registry->done = %d\n", registry->done);
#endif
        /* check for time limit expiry */
        gettimeofday(&now, 0);
        if (registry->tlimit &&
            timedif(now, registry->starttime) > (registry->tlimit * 1000)) {
            char *warn = malloc(256 * sizeof(char));
            sprintf(warn, "Global time limit reached (%.2f sec), premature exit", registry->tlimit);
            myerr(registry->warn_and_error, warn);
            free(warn);
            registry->need_to_be_done = registry->done;        /* break out of loop */
        }

        for (i = 0; i < registry->concurrency; i++) {
            int s = registry->con[i].fd;
#ifdef AB_DEBUG
            printf("AB_DEBUG: test() - stage 5.5, registry->done = %d, i = %d\n", registry->done, i);
#endif
            if (registry->started[registry->con[i].url]
                > registry->finished[registry->con[i].url]) {
                struct connection * c = &registry->con[i];
                struct timeval url_now;

                /* check for per-url time limit expiry */
                gettimeofday(&url_now, 0);

#ifdef AB_DEBUG
                printf("AB_DEBUG: test() - stage 5.5.4, Time taken for current request = %d ms; Per-url time limit = %.4f sec; for run %d, url %d\n", timedif(url_now, c->start_time), registry->url_tlimit[c->url], c->run, c->url - registry->position[c->run]);
                printf("AB_DEBUG: test() - stage 5.5.5, registry->done = %d, i = %d\n", registry->done, i);
#endif
                if (registry->url_tlimit[c->url] &&
                    timedif(url_now, c->start_time) > (registry->url_tlimit[c->url] * 1000)) {
                    char *warn = malloc(256 * sizeof(char));
#ifdef AB_DEBUG
                    printf("AB_DEBUG: test() - stage 5.5.5.3, registry->done = %d, i = %d\n", registry->done, i);
#endif
                    sprintf(warn, "Per-url time limit reached (%.3f sec) for run %d, url %d, iteration %d; connection closed prematurely", registry->url_tlimit[c->url], c->run, c->url - registry->position[c->run], c->thread);
                    myerr(registry->warn_and_error, warn);
                    free(warn);

                    registry->failed[c->url]++;
                    close_connection(registry, c);
                    continue;
                }
            }

            if (registry->con[i].state == STATE_DONE)
                continue;
#ifdef AB_DEBUG
            printf("AB_DEBUG: test() - stage 5.6, registry->done = %d, i = %d\n", registry->done, i);
#endif
            if (FD_ISSET(s, &sel_except)) {
                registry->failed[registry->con[i].url]++;
                start_connect(registry, &registry->con[i]);
                continue;
            }
#ifdef AB_DEBUG
            printf("AB_DEBUG: test() - stage 5.7, registry->done = %d, i = %d\n", registry->done, i);
#endif
            if (FD_ISSET(s, &sel_read)) {
                read_connection(registry, &registry->con[i]);
                continue;
            }
#ifdef AB_DEBUG
            printf("AB_DEBUG: test() - stage 5.8, registry->done = %d, i = %d\n", registry->done, i);
#endif
            if (FD_ISSET(s, &sel_write))
                write_request(registry, &registry->con[i]);        
#ifdef AB_DEBUG
            printf("AB_DEBUG: test() - stage 5.9, registry->done = %d, i = %d\n", registry->done, i);
#endif
        }
    }

#ifdef AB_DEBUG
    printf("AB_DEBUG: test() - stage 6\n");
#endif

    gettimeofday(&registry->endtime, 0);
    if (strlen(registry->warn_and_error) == 28)
        myerr(registry->warn_and_error, "None.\n");
    else myerr(registry->warn_and_error, "Done.\n");
}
