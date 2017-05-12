#define REMOTE_SCOREBOARD_TYPE "application/x-httpd-scoreboard"
#define HANDLER_NAME "scoreboard-send-handler"

#ifndef Move
#define Move(s,d,n,t) (void)memmove((char*)(d),(char*)(s), (n) * sizeof(t)) 
#endif
#ifndef Copy
#define Copy(s,d,n,t) (void)memcpy((char*)(d),(char*)(s), (n) * sizeof(t))
#endif

/* use this macro when using with objects created by the pool, can't
 * mix memmove with pool allocation */
#define Copy_pool(p, s, n, t) apr_pmemdup(p, s, (n) * sizeof(t))

#define SIZE16 2

static void pack16(unsigned char *s, int p)
{
    short ashort = htons(p);
    Move(&ashort, s, SIZE16, unsigned char);
}

static unsigned short unpack16(unsigned char *s)
{
    unsigned short ashort;
    Copy(s, &ashort, SIZE16, char);
    return ntohs(ashort);
}

#define WRITE_BUFF(buf, size, r)                                \
    if (ap_rwrite(buf, size, r) < 0) { return APR_EGENERAL; }

static int scoreboard_send(request_rec *r)
{
    int psize, ssize, tsize;
    char buf[SIZE16*4];
    char *ptr = buf;
    int server_limit, thread_limit;

    /* In httpd-2.x, each content handler is invoked, and is responsible for
       checking wether it's enabled or not for a given url. That's different
       from how 1.3 used to do it.
    */
    if (strcmp(r->handler, HANDLER_NAME)) {
        return DECLINED;
    }

    ap_mpm_query(AP_MPMQ_HARD_LIMIT_THREADS, &thread_limit);
    ap_mpm_query(AP_MPMQ_HARD_LIMIT_DAEMONS, &server_limit);

    psize = sizeof(process_score) * server_limit;
    ssize = sizeof(worker_score)  * server_limit * thread_limit;
    tsize = psize + ssize + sizeof(global_score) + sizeof(buf);

    pack16(ptr, psize);
    ptr += SIZE16;
    pack16(ptr, ssize);
    ptr += SIZE16;
    pack16(ptr, server_limit);
    ptr += SIZE16;
    pack16(ptr, thread_limit);

#if 0
    ap_log_error(APLOG_MARK, APLOG_ERR, 0, modperl_global_get_server_rec(),
                 "send: sizes server_limit=%d, thread_num=%d, psize=%d, "
                 "ssize=%d, %d, %d, %d\n",
                 server_limit, thread_limit, psize, ssize,
                 sizeof(global_score), sizeof(buf), tsize);
#endif

#if 0
{
    int i, j;
    for (i = 0; i < server_limit; i++) {
        for (j = 0; j < thread_limit; j++) {
            worker_score *ws = &ap_scoreboard_image->servers[i][j];
            if (ws->access_count) {
                ap_log_error(APLOG_MARK, APLOG_ERR, 0, modperl_global_get_server_rec(),
                             "snd %02d-%02d: stat: %c cnt: %d\n", i, j,
                             status_flags[ws->status],
                             (int)ws->access_count);
            }
        }
    }
} 
#endif 
    
    ap_set_content_length(r, tsize);
    r->content_type = REMOTE_SCOREBOARD_TYPE;
    
    if (!r->header_only) {
        WRITE_BUFF(&buf[0],                         sizeof(buf),          r);
        WRITE_BUFF(&ap_scoreboard_image->parent[0], psize,                r);
        WRITE_BUFF(ap_scoreboard_image->servers[0], ssize,                r);
        WRITE_BUFF(ap_scoreboard_image->global,     sizeof(global_score), r);
    }

    return APR_SUCCESS;
}


